---
title: kube-prometheus无法监控kube-schduler和kube-controller-manager
tags:
  - kubernetes
  - kube-Prometheus
  - Prometheus
  - 监控
categories: Kubernetes
cover: img/fengmian/k8s.jpeg
abbrlink: cb52faf8
date: 2024-12-18 11:09:41
---
# kube-prometheus无法监控kube-schduler和kube-controller-manager

在部署好kube-prometheus之后kube-schduler和kube-controller-manager无法监控（ERROR），这个我们直接看`kubernetesControlPlane-serviceMonitorKubeScheduler.yaml`和`kubernetesControlPlane-serviceMonitorKubeControllerManager.yaml`这两个文件

**这里我拿其中一个yaml作为说明**

```yaml
root@master:~/kube-prometheus/manifests# cat kubernetesControlPlane-serviceMonitorKubeScheduler.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor			# 服务监控
metadata:
  labels:
    app.kubernetes.io/name: kube-scheduler
    app.kubernetes.io/part-of: kube-prometheus
  name: kube-scheduler
  namespace: monitoring
spec:
  endpoints:
  - bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    interval: 30s
    port: https-metrics
    scheme: https
    tlsConfig:
      insecureSkipVerify: true
  - bearerTokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token
    interval: 5s
    metricRelabelings:
    - action: drop
      regex: process_start_time_seconds
      sourceLabels:
      - __name__
    path: /metrics/slis
    port: https-metrics							# kube-scheudler端口
    scheme: https
    tlsConfig:
      insecureSkipVerify: true
  jobLabel: app.kubernetes.io/name
  namespaceSelector:
    matchNames:
    - kube-system								# kube-schduler所在的名称空间
  selector:
    matchLabels:
      app.kubernetes.io/name: kube-scheduler    # 匹配绑定kube-scheduler
```

在kube-prometheus安装成功之后已经对它俩进行了监控，但是为什么是`ERROR`状态，这是因为这两服务没有对外开放，同时这两个服务也没有创建service，导致prometheus无法监控到(无法获取到地址)。kubernetes从安全的角度考虑scheduler和ControllerManager只监听127.0.0.1。

解决步骤：

1. 修改scheduler和controllermanager的配置文件，将127.0.0.1改为0.0.0.0

   ```shell
   root@master:/etc/kubernetes/manifests# ls
   etcd.yaml  kube-apiserver.yaml  kube-controller-manager.yaml  kube-scheduler.yaml
   root@master:/etc/kubernetes/manifests# vi kube-scheduler.yaml 
   ```

   ```yaml
   spec:
     containers:
     - command:
       - kube-scheduler
       - --authentication-kubeconfig=/etc/kubernetes/scheduler.conf
       - --authorization-kubeconfig=/etc/kubernetes/scheduler.conf
       - --bind-address=0.0.0.0		# 原先是127.0.0.1 现在修改为0.0.0.0
       - --kubeconfig=/etc/kubernetes/scheduler.conf
       - --leader-elect=true
       image: registry.k8s.io/kube-scheduler:v1.31.4
       imagePullPolicy: IfNotPresent
       livenessProbe:
         failureThreshold: 8
         httpGet:
           host: 127.0.0.1
           path: /healthz
           port: 10259
           scheme: HTTPS
         initialDelaySeconds: 10
   ```

   **controllermanager同理这里略过**

2. 为这两个服务创建service资源

   ```yaml
   apiVersion: v1
   kind: Service
   metadata:
     name: kube-scheduler
     namespace: kube-system
     labels:
       app.kubernetes.io/name: kube-scheduler				# 这里的标签要和上面ServiceMonitor的一致才能匹配上
   spec:
     selector:
       component: kube-scheduler							# 这里是scheduler容器的标签
     ports:
       - name: https-metrics								# 这里的端口名称也要和ServiceMonitor的一致才能匹配上
         protocol: TCP
         port: 10259
         targetPort: 10259
   ---
   apiVersion: v1
   kind: Service
   metadata:
     name: kube-controller-manager
     namespace: kube-system
     labels:
       app.kubernetes.io/name: kube-controller-manager
   spec:
     selector:
       component: kube-controller-manager
     ports:
       - name: https-metrics
         protocol: TCP
         port: 10257
         targetPort: 10257
   ```

3. 应用上面的service正常情况这个问题就解决了

   ```shell
   root@master:~# kubectl get svc -n kube-system 
   NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                        AGE
   cilium-envoy              ClusterIP   None             <none>        9964/TCP                       5d23h
   hubble-peer               ClusterIP   10.102.240.168   <none>        443/TCP                        5d23h
   hubble-relay              ClusterIP   10.98.161.138    <none>        80/TCP                         17h
   hubble-ui                 ClusterIP   10.104.108.46    <none>        80/TCP                         17h
   kube-controller-manager   ClusterIP   10.103.25.82     <none>        10257/TCP                      18h
   kube-dns                  ClusterIP   10.96.0.10       <none>        53/UDP,53/TCP,9153/TCP         5d23h
   kube-scheduler            ClusterIP   10.103.174.243   <none>        10259/TCP                      18h
   kubelet                   ClusterIP   None             <none>        10250/TCP,10255/TCP,4194/TCP   3d6h
   metrics-server            ClusterIP   10.105.75.139    <none>        443/TCP                        3d6h
   ```

   ![53b51491-f000-49e1-8871-6e340743cda9](53b51491-f000-49e1-8871-6e340743cda9.png)

