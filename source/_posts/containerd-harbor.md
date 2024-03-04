---
title: 关于Kubernetes配置私有镜像仓库
abbrlink: e3278faf
date: 2023-01-21 17:19:38
tags:
  - Kubernetes
  - Containerd
  - Harbor
categories: Kubernetes
cover: img/fengmian/k8s.jpeg
---
# 关于Kubernetes配置私有镜像仓库

转用Containerd作为CRI，在正常使用公有镜像时并未发现有什么问题，但是在接入Harbor时发现Kubernetes拉取镜像的方式始总采用https方式拉取，将Harbor开启https之后又会出现`x509: certificate signed by unknown authority`证书验证失败

**本人环境：**

- Kubernetes 1.25
- Containerd 1.6.15
- Ubuntu 22.04

**解决方法：**

1. 关于kubernetes拉取采用http的方式可参考：

   https://blog.csdn.net/qq_35925862/article/details/128641810

   https://blog.csdn.net/lhf2112/article/details/117195731

2. 继续使用https方式提高安全等级，并通过kubernetes中的Secret提供Harbor用户认证

# 配置

> 很显然本人采用的第二种方法，图方便的同时也要考虑安全性，第二种方法无需更改Containerd

## 生成证书

```shell
#####################生成CA证书及私钥################
[root@master ~]# vi ca.cnf
[ v3_ca ]
keyUsage = critical, keyCertSign, digitalSignature, keyEncipherment
basicConstraints = critical,CA:true
subjectKeyIdentifier = hash
subjectAltName = DNS:ca

[root@master ~]# openssl req -new -newkey rsa:2048 -keyout ca.key -out ca.csr -nodes -subj '/CN=ca'
[root@master ~]# openssl x509 -req -days 36500 -sha256 -extfile ca.cnf -extensions v3_ca -set_serial 0 -signkey ca.key -in ca.csr -out ca.crt

#####################签发Harbor证书################

[root@master ~]# vi harbor.cnf
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth,clientAuth
basicConstraints = critical, CA:FALSE
authorityKeyIdentifier = keyid,issuer
subjectAltName = DNS:harbor.xiaowangc.local,IP:192.168.10.101  # 配置成自己的harbor的域名和IP
[root@master ~]# openssl req -new -newkey rsa:2048 -keyout harbor.key -out harbor.csr -nodes -subj '/CN=harbor.xiaowangc.local'
[root@master ~]# openssl x509 -req -sha256 -days 36500 -extfile harbor.cnf -extensions v3_req -in harbor.csr -CA ca.crt -CAkey ca.key -out harbor.crt -CAcreateserial
```

## 配置Harbor

**请将生成的harbor证书copy到harbor服务器上并放置到相应的目录中**

```shell
root@harbor:~/harbor# vi harbor.yml
# Configuration file of Harbor

# The IP address or hostname to access admin UI and registry service.
# DO NOT use localhost or 127.0.0.1, because Harbor needs to be accessed by external clients.
hostname: harbor.xiaowangc.local

# http related config
#http:
  # port for http, default is 80. If https enabled, this port will redirect to https port
  #port: 80

# https related config
https:
  # https port for harbor, default is 443
  port: 443
  # The path of cert and key files for nginx
  certificate: /root/harbor/tls/harbor.crt
  private_key: /root/harbor/tls/harbor.key
...
...
```

**加载Harbor配置**

```shell
# 注意：使用重启的方式本人未能加载https的配置而是采用如下重新安装的方式
# 使用重新安装的方法之前的镜像虽然还在，但是生产环境还是要慎用
root@harbor:~/harbor# ls
common     docker-compose.yml    harbor.yml       install.sh  prepare
common.sh  harbor.v2.7.0.tar.gz  harbor.yml.tmpl  LICENSE     tls
root@harbor:~/harbor# ./install.sh
```

![image-20230121170336333](image-20230121170336333.png)

## 信任CA

**虽然Harbor配置https但是由于每台服务器未安装CA证书，所以还是不可信的**

**请在所有Kubernetes节点执行如下操作**

```shell
root@master:~# cp ca.crt /usr/local/share/ca-certificates/
root@master:~# update-ca-certificates
Updating certificates in /etc/ssl/certs...
1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
```

**重启Containerd**

```shell
root@master:~# systemctl restart containerd
```

## 创建Secret

通过Secret保存Harbor的认证信息，如果是**公开私有仓库可略过**

```shell
kubectl create secret docker-registry regcred \
  --docker-server=harbor.xiaowangc.local \
  --docker-username=admin \
  --docker-password=Harbor12345 \
  --docker-email=780312916@qq.com 
```

**创建Pod**

```shell
root@master:~# vi app.yaml
```

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: harbor.xiaowangc.local/app/nginx:v1.0
  imagePullSecrets:
  - name: regcred		# 使用secret的认证信息，注意与Pod的名称空间一致
```

```shell
root@master:~# kubectl apply -f app.yaml
root@master:~# kubectl describe pod nginx
Name:             nginx
Namespace:        default
Priority:         0
Service Account:  default
Node:             node2.xiaowangc.local/192.168.10.12
Start Time:       Sat, 21 Jan 2023 08:28:08 +0000
...
...
...
  kube-api-access-gjv4w:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  45m   default-scheduler  Successfully assigned default/nginx to node2.xiaowangc.local
  Normal  Pulling    45m   kubelet            Pulling image "harbor.xiaowangc.local/app/nginx:v1.0"
  Normal  Pulled     45m   kubelet            Successfully pulled image "harbor.xiaowangc.local/app/nginx:v1.0" in 43.28536ms (43.305668ms including waiting)
  Normal  Created    45m   kubelet            Created container nginx
  Normal  Started    45m   kubelet            Started container nginx
```



