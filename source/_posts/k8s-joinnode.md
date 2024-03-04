---
title: Kubeadmin集群生成token加入新节点
tags:
  - kubernetes
categories: Kubernetes
cover: img/fengmian/k8s.jpeg
abbrlink: '43937223'
date: 2022-09-21 14:00:16
---
# Kubeadmin生成token加入新节点

# 添加Node节点

## 方法一

- 创建Token

  ```shell
  [root@master ~]# kubeadm token create --print-join-command
  kubeadm join 192.168.64.11:6443 --token w1s3w2.mkvsfgygelphy48q --discovery-token-ca-cert-hash sha256:58304b3b4aedd0d995d7a8b61b0e42b25bbfaa0fa947bfa3b3090cd8da8fefd2
  ```

  **Token默认过期时间是24h，可通过指定参数--ttl=0使Token永久有效**

  **--print-join-command 不只是打印令牌，而是打印使用令牌加入集群所需的完整“kubeadm-join”标志。**

- 查看Token

  ```shell
  [root@master ~]# kubeadm token list
  TOKEN                     TTL         EXPIRES                USAGES                   DESCRIPTION                                                EXTRA GROUPS
  w1s3w2.mkvsfgygelphy48q   23h         2022-09-22T05:33:27Z   authentication,signing   <none>                                                     system:bootstrappers:kubeadm:default-node-token
  ```

- WorkNode加入节点

  ```shell
  [root@node02 ~]# kubeadm join 192.168.64.11:6443 --token w1s3w2.mkvsfgygelphy48q --discovery-token-ca-cert-hash sha256:58304b3b4aedd0d995d7a8b61b0e42b25bbfaa0fa947bfa3b3090cd8da8fefd2
  ```

## 方法二

```shell
[root@master pki]# kubeadm token create
lzh5ym.5angzdhj3cowkplo
# 生成token

[root@master pki]# openssl x509 -pubkey -in ca.crt | openssl rsa -pubin -outform der| openssl dgst -sha256 -hex
writing RSA key
(stdin)= 58304b3b4aedd0d995d7a8b61b0e42b25bbfaa0fa947bfa3b3090cd8da8fefd2
# 提取Ca证书token-ca-cert-hash

# 组合
kubeadm join 192.168.64.11:6443 --token lzh5ym.5angzdhj3cowkplo --discoverty-token-ca-cert-hash sha256:58304b3b4aedd0d995d7a8b61b0e42b25bbfaa0fa947bfa3b3090cd8da8fefd2
```





