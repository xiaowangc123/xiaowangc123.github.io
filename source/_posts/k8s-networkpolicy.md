---
title: Kubernetes网络策略
abbrlink: 5b1fc607
date: 2022-11-19 02:41:31
tags:
  - kubernetes
  - 安全
  - CKS
categories: Kubernetes
cover: img/fengmian/k8s.jpeg
---
# 概念

## 网络策略

在kubernetes集群中可以使用网络策略(NetworkPolicy)对Pod的IP或端口进行网络流量控制，NetworkPolicy是一种以应用为中心的结构，允许Pod与网络上的各类实体通信，**NetworkPolicies适用于一端或者两端与Pod的连接，与其他连接无关**

Pod是通过如下三个标识符的组合来辨识的：

- 被允许的Pods
- 被允许的名称空间
- IP组

## 隔离类型

Pod有两种隔离：

- 出口隔离
- 入口隔离

默认情况下，一个Pod的出口是非隔离的，所有向外的连接都是被允许的。如果有`网络策略`选择改Pod并在其`policyTypes`中包含了`Egress`，则改Pod的出口是隔离的；这样的策略适用于该Pod的出口，当Pod的出口被隔离时，则Pod的连接必须符合`NetworkPolicy`中的`egress`的策略，`egress`列表中的策略效果是相加的

Ingress同理，Pod的入口是非隔离的，所有向内的连接都是被允许的。如果有`网络策略`选择改Pod并在其`policyTypes`中包含了`Ingress`，则改Pod的入口是隔离的；这样的策略适用于该Pod的入口，当Pod的入口被隔离时，则Pod的连接必须符合`NetworkPolicy`中的`Ingress`的策略，`Ingress`列表中的策略效果是相加的

## 选择器

两种行为：

- from(源)：从哪来
- to(目的)：到哪去

四种选择器：

- **PodSelector**

  此选择器在Network的名称空间中选择特定的Pod，将其作为流量的入站目的地或出站来源

- **namespaceSelector**

  此选择器将选择特定的名称空间，将所有的Pod的流量作为入站目的地或出站来源

- **namespaceSelector和podselector**

  此选择器将特定名称空间下特定的Pod作为流量作为入站目的地或出站来源

  ```yaml
   # 这种写法from列表包含一个元素，只允许来自标有role=client的Pod且该Pod所在的名称空间标有user=alice的连接
   ...
    ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            user: alice
        podSelector:
          matchLabels:
            role: client
    ...  
    
    #######################################################################
    # 这种写法from列表包含两个元素，允许来自标有role=client的Pod的连接，或来自名称空间标有user=alice
    ...
    ingress:
    - from:
      - namespaceSelector:
          matchLabels:
            user: alice
      - podSelector:
          matchLabels:
            role: client
    ...
  ```

- **ipBlock**

  此选择器将选择特定的IP CIDR范围以作为入站流量来源或出站流量的目的地

  

## 例子

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: test-network-policy策略
  namespace: default		# 在默认名称空间创建test-network-policy策略
spec:
  podSelector:				# pod选择器用于作为流量入站或出站的目的地
    matchLabels:
      role: db					# 带有role: db标签的Pod作为流量的目的地
  policyTypes:				# 策略类型,对进站和出站进行限制
    - Ingress	
    - Egress
  ingress:					# 进站规则
    - from:						# 来源 
        - ipBlock:					# (进站流量)来源必须符合172.17.0.0/16IP段的,且不是172.17.1.0/24段的IP的流量进入默认名称空间
            cidr: 172.17.0.0/16
            except:
              - 172.17.1.0/24
        - namespaceSelector:		# (进站流量)来源必须是project: myproject名称空间的流量进入默认名称空间
            matchLabels:
              project: myproject
        - podSelector:				# (进站流量)来源必须是标签为role: frontend的Pod的流量进入默认名称空间
            matchLabels:
              role: frontend
      ports:						# (进站流量)来自符合上面条件且目的端口是6379/TCP的流量
        - protocol: TCP
          port: 6379
  egress:					# 出站规则
    - to:						# 到哪
        - ipBlock:					# (出站流量)只允许默认名称空间的流量到10.0.0.0/24网络
            cidr: 10.0.0.0/24
      ports:						# (出站流量)来自符合上面条件且目的端口是5978/TCP的流量
        - protocol: TCP
          port: 5978
```

# 实验

## 实验环境

![image-20221119015610802](image-20221119015610802.png)

```shell
[root@master networkpolicy]# kubectl get pod -o wide
NAME    READY   STATUS    RESTARTS   AGE   IP               NODE     NOMINATED NODE   READINESS GATES
app01   1/1     Running   0          11m   172.11.196.133   node01   <none>           <none>
app02   1/1     Running   0          10m   172.11.196.134   node01   <none>           <none>
[root@master networkpolicy]# kubectl get pod -o wide -n app02
NAME    READY   STATUS    RESTARTS   AGE     IP               NODE     NOMINATED NODE   READINESS GATES
app01   1/1     Running   0          6m18s   172.11.196.135   node01   <none>           <none>
app02   1/1     Running   0          5m46s   172.11.196.136   node01   <none>           <none>
[root@master networkpolicy]# kubectl get pod -o wide -n app03
NAME    READY   STATUS    RESTARTS   AGE     IP               NODE     NOMINATED NODE   READINESS GATES
app01   1/1     Running   0          4m36s   172.11.140.73    node02   <none>           <none>
app02   1/1     Running   0          4m13s   172.11.196.137   node01   <none>           <none>
```

## 禁止访问Default

![image-20221119015904520](image-20221119015904520.png)

1. 测试默认情况下是否能访问

   > 下面实验结论在没有策略的情况下不同名称空间的Pod网络是互通的

   ```shell
   [root@master networkpolicy]# kubectl exec -it app01 -n app02 -- sh
   / # ping 172.11.196.133
   PING 172.11.196.133 (172.11.196.133): 56 data bytes
   64 bytes from 172.11.196.133: seq=0 ttl=63 time=0.102 ms
   64 bytes from 172.11.196.133: seq=1 ttl=63 time=0.095 ms
   ^C
   --- 172.11.196.133 ping statistics ---
   2 packets transmitted, 2 packets received, 0% packet loss
   round-trip min/avg/max = 0.095/0.098/0.102 ms
   / # ping 172.11.196.134
   PING 172.11.196.134 (172.11.196.134): 56 data bytes
   64 bytes from 172.11.196.134: seq=0 ttl=63 time=0.108 ms
   64 bytes from 172.11.196.134: seq=1 ttl=63 time=0.092 ms
   ^C
   --- 172.11.196.134 ping statistics ---
   2 packets transmitted, 2 packets received, 0% packet loss
   round-trip min/avg/max = 0.092/0.100/0.108 ms
   
   ==================================================================================================
   [root@master networkpolicy]# kubectl exec -it app02 -n app03 -- sh
   / # ping 172.11.196.133
   PING 172.11.196.133 (172.11.196.133): 56 data bytes
   64 bytes from 172.11.196.133: seq=0 ttl=63 time=0.102 ms
   ^C
   --- 172.11.196.133 ping statistics ---
   1 packets transmitted, 1 packets received, 0% packet loss
   round-trip min/avg/max = 0.102/0.102/0.102 ms
   / # ping 172.11.196.134
   PING 172.11.196.134 (172.11.196.134): 56 data bytes
   64 bytes from 172.11.196.134: seq=0 ttl=63 time=0.086 ms
   ^C
   --- 172.11.196.134 ping statistics ---
   1 packets transmitted, 1 packets received, 0% packet loss
   round-trip min/avg/max = 0.086/0.086/0.086 ms
   ```

2. 创建网络策略

   ```shell
   [root@master networkpolicy]# vi network01.yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: deny-all-in
   spec:
     podSelector: {}
     policyTypes:
     - Ingress
     
   [root@master networkpolicy]# kubectl apply -f network01.yaml
   networkpolicy.networking.k8s.io/deny-all-in created
   ```

3. 测试

   ```shell
   [root@master networkpolicy]# kubectl exec -it app01 -n app02 -- sh
   / # ping 172.11.196.133
   PING 172.11.196.133 (172.11.196.133): 56 data bytes
   
   --- 172.11.196.133 ping statistics ---
   33 packets transmitted, 0 packets received, 100% packet loss
   # 无响应
   / # ping 172.11.196.134
   PING 172.11.196.134 (172.11.196.134): 56 data bytes
   
   --- 172.11.196.134 ping statistics ---
   24 packets transmitted, 0 packets received, 100% packet loss
   # 无响应
   ```

   **注意：**

   **只是禁止了所有流量进入default名称空间，不是真的所有的流量都无法进入，default名称空间下Pod的响应流量是可以回来的**

   **禁止所有流量出站，同理将策略的Ingress改成Egress。同理，自己的请求流量无法出站，但是响应可以**

   同时拒绝进站出站流量，需要将两个一起加上即可

   

4. 清除策略

   ```shell
   [root@master networkpolicy]# kubectl delete -f network01.yaml
   networkpolicy.networking.k8s.io "deny-all-in" deleted
   ```

## 只允许app02空间访问app03名称空间的80端口

![image-20221119023505044](image-20221119023505044.png)

1. 确保之前测试的网络策略删除了

2. 查看namespace标签

   ```shell
   [root@master networkpolicy]# kubectl get ns --show-labels
   NAME              STATUS   AGE   LABELS
   app02             Active   96m   kubernetes.io/metadata.name=app02
   app03             Active   96m   kubernetes.io/metadata.name=app03
   default           Active   32d   kubernetes.io/metadata.name=default
   kube-node-lease   Active   32d   kubernetes.io/metadata.name=kube-node-lease
   kube-public       Active   32d   kubernetes.io/metadata.name=kube-public
   kube-system       Active   32d   kubernetes.io/metadata.name=kube-system
   ```

3. 创建网络策略

   ```shell
   [root@master networkpolicy]# kubectl get ns --show-labels
   NAME              STATUS   AGE   LABELS
   app02             Active   96m   kubernetes.io/metadata.name=app02
   app03             Active   96m   kubernetes.io/metadata.name=app03
   default           Active   32d   kubernetes.io/metadata.name=default
   kube-node-lease   Active   32d   kubernetes.io/metadata.name=kube-node-lease
   kube-public       Active   32d   kubernetes.io/metadata.name=kube-public
   kube-system       Active   32d   kubernetes.io/metadata.name=kube-system
   [root@master networkpolicy]# vi network02.yaml
   apiVersion: networking.k8s.io/v1
   kind: NetworkPolicy
   metadata:
     name: allow-app02-in
     namespace: app03
   spec:
     podSelector: {}
     policyTypes:
       - Ingress
     ingress:
       - from:
           - namespaceSelector:
               matchLabels:
                 kubernetes.io/metadata.name: app02
         ports:
           - protocol: TCP
             port: 80
   [root@master networkpolicy]# kubectl apply -f network02.yaml
   networkpolicy.networking.k8s.io/allow-app02-in created
   ```

4. 测试

   ```shell
   #### app02名称空间的Pod可以访问app03名称空间的Pod
   
   [root@master networkpolicy]# kubectl exec -it app01 -n app02 -- sh
   / # curl 172.11.140.73
   <!DOCTYPE html>
   <html>
   <head>
   <title>Welcome to nginx!</title>
   <style>
   html { color-scheme: light dark; }
   body { width: 35em; margin: 0 auto;
   font-family: Tahoma, Verdana, Arial, sans-serif; }
   </style>
   </head>
   <body>
   <h1>Welcome to nginx!</h1>
   <p>If you see this page, the nginx web server is successfully installed and
   working. Further configuration is required.</p>
   
   <p>For online documentation and support please refer to
   <a href="http://nginx.org/">nginx.org</a>.<br/>
   Commercial support is available at
   <a href="http://nginx.com/">nginx.com</a>.</p>
   
   <p><em>Thank you for using nginx.</em></p>
   </body>
   </html>
   
   / # curl 172.11.196.137
   <!DOCTYPE html>
   <html>
   <head>
   <title>Welcome to nginx!</title>
   <style>
   html { color-scheme: light dark; }
   body { width: 35em; margin: 0 auto;
   font-family: Tahoma, Verdana, Arial, sans-serif; }
   </style>
   </head>
   <body>
   <h1>Welcome to nginx!</h1>
   <p>If you see this page, the nginx web server is successfully installed and
   working. Further configuration is required.</p>
   
   <p>For online documentation and support please refer to
   <a href="http://nginx.org/">nginx.org</a>.<br/>
   Commercial support is available at
   <a href="http://nginx.com/">nginx.com</a>.</p>
   
   <p><em>Thank you for using nginx.</em></p>
   </body>
   </html>
   / #
   
   
   #### default名称空间的Pod不可以访问app03名称空间的Pod
   
   [root@master networkpolicy]# kubectl exec -it app01 -- sh
   / # curl 172.11.196.137
   # 卡死(超时)
   / # ping 172.11.196.137
   PING 172.11.196.137 (172.11.196.137): 56 data bytes
   ^C
   --- 172.11.196.137 ping statistics ---
   8 packets transmitted, 0 packets received, 100% packet loss
   # 同样无法ping通
   ```

   

