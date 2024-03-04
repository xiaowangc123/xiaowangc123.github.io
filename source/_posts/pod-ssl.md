---
title: Pod CA证书问题小记
tags:
  - OpenSSL
  - 证书
  - kubernetes
categories: Kubernetes
cover: img/fengmian/k8s.jpeg
abbrlink: c06f8bf8
date: 2023-07-06 10:08:07
---
# Pod 证书问题小记

在使用helm部署gitlab的时候，发现gitlab-gitlab-runner组件反复重启，通过查看日志发现报错

`x509: certificate signed by unknown authority`

因为使用的自建CA证书，同时只将CA更新到了宿主机的受信任区域，在Pod中还是无法信任通过我自建的CA颁发的证书。

解决方法：

基于ca证书创建configmap

```shell
# kubectl create configmap ca --from-file=TLS/ca/ca.crt -n gitlab
```

编辑deployment控制器，将configmap作为卷挂载到容器内的/etc/ssl/certs目录下

```shell
volumeMounts:
- mountPath: /etc/ssl/certs
  name: ca-cert
         
volumes:
- configMap:
  defaultMode: 420
  name: ca
name: ca-cert
```



在其他Pod中访问例如www.baidu.com的公共的web发现`certificate signed by unknown authority`

可尝试在容器内安装`ca-certificates`或重新打包镜像将其安装进去

```shell
# apt -y install ca-certificates
```



