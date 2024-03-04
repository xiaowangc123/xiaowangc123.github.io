---
title: k8s二进制安装方法
tags:
  - kubernetes
categories: Kubernetes
cover: img/fengmian/k8s.jpeg
abbrlink: a6cffccf
date: 2022-09-18 22:29:39
---
# K8S二进制安装

**对于安装过程中的证书以及配置文件不做过多讲解**

**详情请参考：https://www.xiaowangc.com/2022/09/18/k8s-zhengshu/**

我们在翻阅kubernets官网文章时，有注意的小伙伴就会发现官方只介绍了使用kubeadm等工具进行安装，并没有介绍或者详细介绍二进制的安装方法，但是网上的却有很多介绍二进制安装，证书生成等教程。那么我曾就有这个疑问，**他们是到底怎么学会二进制的呢**？

Kubernetes是开源的容器编排工具，而底层还是容器技术；在通过Kubeadm工具安装Kubernetes集群时，每个组件还是以容器的方式运行的。容器的本质就是`对进程进行隔离`的一项技术，**容器内其实运行的也是二进制**。我们可以对adm安装的集群包括证书、二进制参数、配置文件等进行分析，大致就能明白如何通过二进制的方式对kubernetes进行安装。知道这种方式那么通过adm安装的Kubernetes集群是不是就是官方给我们的最好的例子！

预先通过adm搭建的Kubernetes集群对各个组件、证书以及容器进行分析大致就能知道二进制如何安装！此文档是根据kubeadm部署的1.23.6进行分析部署的

# 环境

## 前提准备

本次安装采用**CentOS 8.4**系统上部署**etcd高可用**方式安装k8s 1.23.6集群

**请预先配置IP以及主机名并配置集群之间免密**

不会免密的请到：https://www.xiaowangc.com/2021/05/16/ssh/

| 主机名   | IP               |             |
| -------- | ---------------- | ----------- |
| master01 | 192.168.64.31/24 | 控制平面    |
| node01   | 192.168.64.32/24 | Node/etcd01 |
| node02   | 192.168.64.33/24 | Node/etcd02 |
| node03   | 192.168.64.34/24 | Node/etcd03 |

**请确保集群中主机hosts解析配置一致**

```shell
[root@master ~]# cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
192.168.64.31   master
192.168.64.32   node01  node1   etcd01  etcd1
192.168.64.33   node02  node2   etcd02  etcd2
192.168.64.34   node03  node3   etcd03  etcd3
```

## 配置存储库(所有节点)

```shell
[root@master ~]# mkdir /etc/yum.repos.d/bak
[root@master ~]# mv /etc/yum.repos.d/* /etc/yum.repos.d/bak
[root@master ~]# curl -o /etc/yum.repos.d/a.repo https://mirrors.aliyun.com/repo/Centos-vault-8.5.2111.repo
[root@master ~]# curl -o /etc/yum.repos.d/docker-ce.repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
```

## 关闭Selinux(所有节点)

```shell
[root@master ~]# setenforce 0
[root@master ~]# sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
```

## 关闭交换分区(所有节点)

```shell
[root@master ~]# swapoff -a
[root@master ~]# sed -ri "s/.*swap.*/#&/" /etc/fstab
```

## 关闭防火墙(所有节点)

```shell
[root@master ~]# systemctl disable --now firewalld
```

## 配置网桥(所有节点)

```shell
[root@master ~]# tee > /etc/modules-load.d/k8s.conf << EOF
br_netfilter
EOF
[root@master ~]# tee > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
[root@master ~]# sysctl --system
```

## 安装配置Docker

```shell
[root@master ~]# curl https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo -O /etc/yum.repos.d/docker-ce.repo
[root@master ~]# dnf -y install docker-ce --allowerasing
[root@master ~]# systemctl enable --now docker
[root@master ~]# tee > /etc/docker/daemon.json << EOF
{
 	"exec-opts":["native.cgroupdriver=systemd"]
}
EOF
[root@master ~]# systemctl daemon-reload
[root@master ~]# systemctl restart docker
```

## 开启IPVS(所有节点)

```shell
[root@master ~]# tee  >  /etc/sysconfig/modules/ipvs.modules << EOF
#!/bin/bash
modprobe  --  ip_vs
modprobe  --  ip_vs_rr
modprobe  --  ip_vs_wrr
modprobe  --  ip_vs_sh
modprobe  --  nf_conntrack
EOF
[root@master ~]# chmod +x /etc/sysconfig/modules/ipvs.modules
[root@master ~]# /bin/bash /etc/sysconfig/modules/ipvs.modules
```



# ETCD集群

## 下载(etcd节点)

ETCD下载连接：https://github.com/etcd-io/etcd/releases/

```shell
[root@node01 ~]# wget https://github.com/etcd-io/etcd/releases/download/v3.5.5/etcd-v3.5.5-linux-amd64.tar.gz
```

**通过参考kubeadm安装生成etcd配置文件,单节点ETCD部署就只在节点配置如下即可，修改对应的IP地址和证书路径**

```shell
[root@master manifests]# ls
etcd.yaml  kube-apiserver.yaml  kube-controller-manager.yaml  kube-scheduler.yaml
[root@master manifests]# pwd
[root@master manifests]# cat etcd.yaml
/etc/kubernetes/manifests
    - etcd
    - --advertise-client-urls=https://192.168.64.11:2379
    - --cert-file=/etc/kubernetes/pki/etcd/server.crt
    - --client-cert-auth=true
    - --data-dir=/var/lib/etcd
    - --initial-advertise-peer-urls=https://192.168.64.11:2380
    - --initial-cluster=master=https://192.168.64.11:2380
    - --key-file=/etc/kubernetes/pki/etcd/server.key
    - --listen-client-urls=https://127.0.0.1:2379,https://192.168.64.11:2379
    - --listen-metrics-urls=http://127.0.0.1:2381
    - --listen-peer-urls=https://192.168.64.11:2380
    - --name=master
    - --peer-cert-file=/etc/kubernetes/pki/etcd/peer.crt
    - --peer-client-cert-auth=true
    - --peer-key-file=/etc/kubernetes/pki/etcd/peer.key
    - --peer-trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
    - --snapshot-count=10000
    - --trusted-ca-file=/etc/kubernetes/pki/etcd/ca.crt
```

通过现环境修改成适用于高可用的ETCD集群配置

## 创建etcd CA

```shell
[root@node01 ~]# mkdir /etc/etcd
[root@node01 ~]# cd /etc/etcd/
[root@node01 etcd]# vi etcd-ca.cnf
[ v3_ca ]
keyUsage = critical, keyCertSign, digitalSignature, keyEncipherment
basicConstraints = critical,CA:true
subjectKeyIdentifier = hash
subjectAltName = DNS:etcd-ca
[root@node01 etcd]# openssl req -new -newkey rsa:2048 -keyout etcd-ca.key -out etcd-ca.csr -nodes -subj '/CN=etcd-ca'
[root@node01 etcd]# openssl x509 -req -days 36500 -sha256 -extfile etcd-ca.cnf -extensions v3_ca -set_serial 0 -signkey etcd-ca.key -in etcd-ca.csr -out etcd-ca.crt
Signature ok
subject=CN = etcd-ca
Getting Private key
[root@node01 etcd]# ls
etcd-ca.cnf  etcd-ca.crt  etcd-ca.csr  etcd-ca.key
```

## 创建etcd01证书

```shell
[root@node01 etcd]# cat etcd01.cnf
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth,clientAuth
basicConstraints = critical, CA:FALSE
authorityKeyIdentifier = keyid,issuer
subjectAltName = DNS:localhost, DNS:etcd01,IP:127.0.0.1, IP:192.168.64.32		# 注意IP域名与本机一致

========================================================================================================

[root@node01 etcd]# openssl req -new -newkey rsa:2048 -keyout etcd01.key -out etcd01.csr -nodes -subj '/CN=etcd01'
[root@node01 etcd]# openssl x509 -req -sha256 -days 36500 -extfile etcd01.cnf -extensions v3_req -in etcd01.csr -CA etcd-ca.crt -CAkey etcd-ca.key -out etcd01.crt -CAcreateserial

========================================================================================================

[root@node01 etcd]# openssl req -new -newkey rsa:2048 -keyout peer.key -out peer.csr -nodes -subj '/CN=etcd01'
[root@node01 etcd]# openssl x509 -req -sha256 -days 36500 -extfile etcd01.cnf -extensions v3_req -in peer.csr -CA etcd-ca.crt -CAkey etcd-ca.key -out peer.crt -CAcreateserial
```

## 配置etcd01

```shell
[root@node01 etcd]# cd
[root@node01 ~]# tar xf etcd-v3.5.5-linux-amd64.tar.gz
[root@node01 ~]# cp etcd-v3.5.5-linux-amd64/etcd* /usr/local/sbin/
[root@node01 ~]# vi /lib/systemd/system/etcd.service
[Unit]
Description=etcd
[Service]
Type=simple
ExecStart=etcd --name etcd01 --initial-advertise-peer-urls https://192.168.64.32:2380 \
  --listen-peer-urls https://192.168.64.32:2380 \
  --listen-client-urls https://192.168.64.32:2379,https://127.0.0.1:2379 \
  --advertise-client-urls https://192.168.64.32:2379 \
  --initial-cluster-token etcd-cluster-1 \
  --initial-cluster etcd01=https://192.168.64.32:2380,etcd02=https://192.168.64.33:2380,etcd03=https://192.168.64.34:2380 \
  --initial-cluster-state new \
  --client-cert-auth \
  --trusted-ca-file=/etc/etcd/etcd-ca.crt \
  --cert-file=/etc/etcd/etcd01.crt \
  --key-file=/etc/etcd/etcd01.key \
  --peer-client-cert-auth \
  --peer-trusted-ca-file=/etc/etcd/etcd-ca.crt \
  --peer-cert-file=/etc/etcd/peer.crt \
  --peer-key-file=/etc/etcd/peer.key \
  --data-dir=/var/lib/etcd
[Install]
WantedBy=multi-user.target
[root@node01 ~]# systemctl daemon-reload
[root@node01 system]# systemctl enable --now etcd
```

## 创建etcd02证书

```shell
[root@node02 ~]# tar xf etcd-v3.5.5-linux-amd64.tar.gz
[root@node02 ~]# cp etcd-v3.5.5-linux-amd64/etcd* /usr/local/sbin/
[root@node02 ~]# mkdir /etc/etcd
[root@node02 ~]# cd /etc/etcd/
[root@node02 etcd]# scp node01:/etc/etcd/etcd-ca* .			# 拷贝etcd-ca到etcd02
etcd-ca.cnf                                                                                        100%  172   373.5KB/s   00:00
etcd-ca.crt                                                                                        100% 1090     2.4MB/s   00:00
etcd-ca.csr                                                                                        100%  887     2.7MB/s   00:00
etcd-ca.key                                                                                        100% 1708     3.6MB/s   00:00
etcd-ca.srl                                                                                        100%   41   107.5KB/s   00:00
[root@node02 etcd]# cat etcd02.cnf
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth,clientAuth
basicConstraints = critical, CA:FALSE
authorityKeyIdentifier = keyid,issuer
subjectAltName = DNS:localhost, DNS:etcd02,IP:127.0.0.1, IP:192.168.64.33			# 注意IP和主机名

===================================================================================

[root@node02 etcd]# openssl req -new -newkey rsa:2048 -keyout etcd02.key -out etcd02.csr -nodes -subj '/CN=etcd02'
[root@node02 etcd]# openssl x509 -req -sha256 -days 36500 -extfile etcd02.cnf -extensions v3_req -in etcd02.csr -CA etcd-ca.crt -CAkey etcd-ca.key -out etcd02.crt -CAcreateserial

===================================================================================

[root@node02 etcd]# openssl req -new -newkey rsa:2048 -keyout peer.key -out peer.csr -nodes -subj '/CN=etcd02'
[root@node02 etcd]# openssl x509 -req -sha256 -days 36500 -extfile etcd02.cnf -extensions v3_req -in peer.csr -CA etcd-ca.crt -CAkey etcd-ca.key -out peer.crt -CAcreateserial
```

## 配置etcd02

```shell
[root@node02 etcd]# vi /lib/systemd/system/etcd.service 
[Unit]
Description=etcd
[Service]
Type=simple
ExecStart=etcd --name etcd02 --initial-advertise-peer-urls https://192.168.64.33:2380 \
  --listen-peer-urls https://192.168.64.33:2380 \
  --listen-client-urls https://192.168.64.33:2379,https://127.0.0.1:2379 \
  --advertise-client-urls https://192.168.64.33:2379 \
  --initial-cluster-token etcd-cluster-1 \
  --initial-cluster etcd01=https://192.168.64.32:2380,etcd02=https://192.168.64.33:2380,etcd03=https://192.168.64.34:2380 \
  --initial-cluster-state new \
  --client-cert-auth \
  --trusted-ca-file=/etc/etcd/etcd-ca.crt \
  --cert-file=/etc/etcd/etcd02.crt \
  --key-file=/etc/etcd/etcd02.key \
  --peer-client-cert-auth \
  --peer-trusted-ca-file=/etc/etcd/etcd-ca.crt \
  --peer-cert-file=/etc/etcd/peer.crt \
  --peer-key-file=/etc/etcd/peer.key \
  --data-dir=/var/lib/etcd
[Install]
WantedBy=multi-user.target
[root@node02 etcd]# systemctl daemon-reload
[root@node02 etcd]# systemctl enable --now etcd
```

## 创建etcd03证书

```shell
[root@node03 ~]# tar xf etcd-v3.5.5-linux-amd64.tar.gz
[root@node03 ~]# cp etcd-v3.5.5-linux-amd64/etcd* /usr/local/sbin/
[root@node03 ~]# mkdir /etc/etcd
[root@node03 ~]# cd /etc/etcd/
[root@node03 etcd]# scp node01:/etc/etcd/etcd-ca* .
etcd-ca.cnf                                                                                  100%  172   318.4KB/s   00:00
etcd-ca.crt                                                                                  100% 1090     1.7MB/s   00:00
etcd-ca.csr                                                                                  100%  887     1.5MB/s   00:00
etcd-ca.key                                                                                  100% 1708     4.2MB/s   00:00
etcd-ca.srl                                                                                  100%   41   127.2KB/s   00:00
[root@node03 etcd]# cat etcd03.cnf
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth,clientAuth
basicConstraints = critical, CA:FALSE
authorityKeyIdentifier = keyid,issuer
subjectAltName = DNS:localhost, DNS:etcd03,IP:127.0.0.1, IP:192.168.64.34			# 注意IP和主机名

================================================================================================

[root@node03 etcd]# openssl req -new -newkey rsa:2048 -keyout etcd03.key -out etcd03.csr -nodes -subj '/CN=etcd03'
[root@node03 etcd]# openssl x509 -req -sha256 -days 36500 -extfile etcd03.cnf -extensions v3_req -in etcd03.csr -CA etcd-ca.crt -CAkey etcd-ca.key -out etcd03.crt -CAcreateserial

================================================================================================

[root@node03 etcd]# openssl req -new -newkey rsa:2048 -keyout peer.key -out peer.csr -nodes -subj '/CN=etcd03'
[root@node03 etcd]# openssl x509 -req -sha256 -days 36500 -extfile etcd03.cnf -extensions v3_req -in peer.csr -CA etcd-ca.crt -CAkey etcd-ca.key -out peer.crt -CAcreateserial
```

## 配置etcd03

```shell
[root@node03 etcd]# vi /lib/systemd/system/etcd.service
[Unit]
Description=etcd
[Service]
Type=simple
ExecStart=etcd --name etcd03 --initial-advertise-peer-urls https://192.168.64.34:2380 \
  --listen-peer-urls https://192.168.64.34:2380 \
  --listen-client-urls https://192.168.64.34:2379,https://127.0.0.1:2379 \
  --advertise-client-urls https://192.168.64.34:2379 \
  --initial-cluster-token etcd-cluster-1 \
  --initial-cluster etcd01=https://192.168.64.32:2380,etcd02=https://192.168.64.33:2380,etcd03=https://192.168.64.34:2380 \
  --initial-cluster-state new \
  --client-cert-auth \
  --trusted-ca-file=/etc/etcd/etcd-ca.crt \
  --cert-file=/etc/etcd/etcd03.crt \
  --key-file=/etc/etcd/etcd03.key \
  --peer-client-cert-auth \
  --peer-trusted-ca-file=/etc/etcd/etcd-ca.crt \
  --peer-cert-file=/etc/etcd/peer.crt \
  --peer-key-file=/etc/etcd/peer.key \
  --data-dir=/var/lib/etcd
[Install]
WantedBy=multi-user.target
[root@node03 etcd]# systemctl daemon-reload
[root@node03 etcd]# systemctl enable --now etcd
```

## 验证

```shell
[root@node02 etcd]# etcdctl --endpoints="https://etcd02:2379,https://etcd03:2379,https://etcd01:2379" --cacert=etcd-ca.crt --cert=etcd02.crt --key=etcd02.key endpoint status --write-out=table
+---------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|      ENDPOINT       |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+---------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| https://etcd02:2379 | f0e17e8a11ca95f3 |   3.5.5 |   20 kB |     false |      false |         2 |          8 |                  8 |        |
| https://etcd03:2379 | ba673fc8f108eb32 |   3.5.5 |   20 kB |     false |      false |         2 |          8 |                  8 |        |
| https://etcd01:2379 | afd02c09f31c7a3e |   3.5.5 |   20 kB |      true |      false |         2 |          8 |                  8 |        |
+---------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
```

# Kubernetes二进制下载

下载地址：https://dl.k8s.io/v1.23.6/kubernetes-server-linux-amd64.tar.gz

将server二进制包下载并上传至master节点上或直接使用wget下载亦可

# Master节点部署

## apiServer组件部署

先查看adm方式部署生成的配置参数进行参考

```shell
    - kube-apiserver
    - --advertise-address=192.168.64.11
    - --allow-privileged=true
    - --authorization-mode=Node,RBAC
    - --client-ca-file=/etc/kubernetes/pki/ca.crt
    - --enable-admission-plugins=NodeRestriction
    - --enable-bootstrap-token-auth=true
    - --etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt
    - --etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt
    - --etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key
    - --etcd-servers=https://127.0.0.1:2379
    - --kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt
    - --kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key
    - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname                 
    - --proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt
    - --proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key
    - --requestheader-allowed-names=front-proxy-client
    - --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt
    - --requestheader-extra-headers-prefix=X-Remote-Extra-
    - --requestheader-group-headers=X-Remote-Group
    - --requestheader-username-headers=X-Remote-User
    - --secure-port=6443
    - --service-account-issuer=https://kubernetes.default.svc.cluster.local
    - --service-account-key-file=/etc/kubernetes/pki/sa.pub
    - --service-account-signing-key-file=/etc/kubernetes/pki/sa.key
    - --service-cluster-ip-range=192.12.0.0/16
    - --tls-cert-file=/etc/kubernetes/pki/apiserver.crt
    - --tls-private-key-file=/etc/kubernetes/pki/apiserver.key
```

稍微对adm的apiserver配置进行修改即可使用

### 创建Kubernetes Ca

```shell
[root@master ~]#
[root@master ~]# cd /etc/kubernetes/
[root@master kubernetes]# cat ca.cnf
[ v3_ca ]
keyUsage = critical, keyCertSign, digitalSignature, keyEncipherment
basicConstraints = critical,CA:true
subjectKeyIdentifier = hash
subjectAltName = DNS:kubernetes
[root@master kubernetes]# openssl req -new -newkey rsa:2048 -keyout ca.key -out ca.csr -nodes -subj '/CN=kubernetes'
[root@master kubernetes]# openssl x509 -req -days 36500 -sha256 -extfile ca.cnf -extensions v3_ca -set_serial 0 -signkey ca.key -in ca.csr -out ca.crt
[root@master kubernetes]# ls
ca.cnf  ca.crt  ca.csr  ca.key
```

### 创建签发apiServer组件证书

```shell
[root@master kubernetes]# vi apiserver.cnf
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
basicConstraints = critical, CA:FALSE
authorityKeyIdentifier = keyid,issuer
subjectAltName = DNS:kubernetes, DNS:kubernetes.default, DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.cluster.local, DNS:master, IP:127.0.0.1, IP:192.168.64.31
[root@master kubernetes]# openssl req -new -newkey rsa:2048 -keyout apiserver.key -out apiserver.csr -nodes -subj '/CN=kube-apiserver'
[root@master kubernetes]# openssl x509 -req -sha256 -days 36500 -extfile apiserver.cnf -extensions v3_req -in apiserver.csr -CA ca.crt -CAkey ca.key -out apiserver.crt -CAcreateserial
[root@master kubernetes]# ls api*
apiserver.cnf  apiserver.crt  apiserver.csr  apiserver.key
```

### 创建签发etcd-client证书

etcd因为部署在Node节点上，所以要把etcd-ca拷贝到master上

```shell
[root@master kubernetes]# mkdir etcd
[root@master kubernetes]# cd etcd/
[root@master etcd]# scp node01:/etc/etcd/etcd-ca* .
etcd-ca.cnf                                                   100%  172   232.1KB/s   00:00
etcd-ca.crt                                                   100% 1090     2.1MB/s   00:00
etcd-ca.csr                                                   100%  887     1.8MB/s   00:00
etcd-ca.key                                                   100% 1708     3.2MB/s   00:00
[root@master etcd]# vi apiserver-etcd-client.cnf
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
basicConstraints = critical, CA:FALSE
authorityKeyIdentifier = keyid,issuer
[root@master etcd]# openssl req -new -newkey rsa:2048 -keyout apiserver-etcd-client.key -out apiserver-etcd-client.csr -nodes -subj '/O=system:masters/CN=kube-apiserver-etcd-client'
[root@master etcd]# openssl x509 -req -sha256 -days 36500 -extfile apiserver-etcd-client.cnf -extensions v3_req -in apiserver-etcd-client.csr -CA etcd-ca.crt -CAkey etcd-ca.key -out apiserver-etcd-client.crt -CAcreateserial
[root@master etcd]# ls api*
apiserver-etcd-client.cnf  apiserver-etcd-client.crt  apiserver-etcd-client.csr  apiserver-etcd-client.key
```

### 创建签发kubelet组件证书

```shell
[root@master etcd]# cd ..
[root@master kubernetes]# vi apiserver-kubelet-client.cnf
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
basicConstraints = critical, CA:FALSE
authorityKeyIdentifier = keyid,issuer
[root@master kubernetes]# openssl req -new -newkey rsa:2048 -keyout apiserver-kubelet-client.key -out apiserver-kubelet-client.csr -nodes -subj '/O=system:masters/CN=kube-apiserver-kubelet-client'
[root@master kubernetes]# openssl x509 -req -sha256 -days 36500 -extfile apiserver-kubelet-client.cnf -extensions v3_req -in apiserver-kubelet-client.csr -CA ca.crt -CAkey ca.key -out apiserver-kubelet-client.crt -CAcreateserial
[root@master kubernetes]# ls apiserver-kubelet-client*
apiserver-kubelet-client.cnf  apiserver-kubelet-client.crt  apiserver-kubelet-client.csr  apiserver-kubelet-client.key
```

### 创建front-proxy-ca

```shell
[root@master kubernetes]# vi front-proxy-ca.cnf
[ v3_ca ]
keyUsage = critical, keyCertSign, digitalSignature, keyEncipherment
basicConstraints = critical,CA:true
subjectKeyIdentifier = hash
subjectAltName = DNS:front-proxy-ca
[root@master kubernetes]# openssl req -new -newkey rsa:2048 -keyout front-proxy-ca.key -out front-proxy-ca.csr -nodes -subj '/CN=front-proxy-ca'
[root@master kubernetes]# openssl x509 -req -days 36500 -sha256 -extfile front-proxy-ca.cnf -extensions v3_ca -set_serial 0 -signkey front-proxy-ca.key -in front-proxy-ca.csr -out front-proxy-ca.crt
```

### 创建front-proxy-client

```shell
[root@master kubernetes]# vi front-proxy-client.cnf
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
basicConstraints = critical, CA:FALSE
authorityKeyIdentifier = keyid,issuer
[root@master kubernetes]# openssl req -new -newkey rsa:2048 -keyout front-proxy-client.key -out front-proxy-client.csr -nodes -subj '/CN=front-proxy-client'
[root@master kubernetes]# openssl x509 -req -sha256 -days 36500 -extfile front-proxy-client.cnf -extensions v3_req -in front-proxy-client.csr -CA front-proxy-ca.crt -CAkey front-proxy-ca.key -out front-proxy-client.crt -CAcreateserial
```

### 创建密钥对

```shell
[root@master kubernetes]# openssl genrsa -out sa.key
[root@master kubernetes]# openssl rsa -in sa.key -pubout -out sa.pub
```

### 配置apiServer

```shell
[root@master ~]# ls
anaconda-ks.cfg  kubernetes-server-linux-amd64.tar.gz
[root@master ~]# tar xf kubernetes-server-linux-amd64.tar.gz
[root@master ~]# cp kubernetes/server/bin/kube-apiserver /usr/local/sbin/
[root@master ~]# cp kubernetes/server/bin/kubectl /usr/local/sbin/
[root@master ~]# vi /lib/systemd/system/apiserver.service
#################
# 注意注释只是需要注意的点，不要把注释写到文件中，确保\后面没有空格，否则可能会报错
#################
[Unit]
Description=apiServer
[Service]
Type=simple
ExecStart=kube-apiserver \
  --advertise-address=192.168.64.31 \
  --allow-privileged=true \
  --authorization-mode=Node,RBAC \
  --client-ca-file=/etc/kubernetes/ca.crt \
  --enable-admission-plugins=NodeRestriction \
  --enable-bootstrap-token-auth=true \
  --etcd-cafile=/etc/kubernetes/etcd/etcd-ca.crt \
  --etcd-certfile=/etc/kubernetes/etcd/apiserver-etcd-client.crt \
  --etcd-keyfile=/etc/kubernetes/etcd/apiserver-etcd-client.key \
  --etcd-servers=https://etcd01:2379,https://etcd02:2379,https://etcd03:2379 \
  --kubelet-client-certificate=/etc/kubernetes/apiserver-kubelet-client.crt \
  --kubelet-client-key=/etc/kubernetes/apiserver-kubelet-client.key \
  --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname \
  --secure-port=6443 \
  --service-account-issuer=https://kubernetes.default.svc.cluster.local \
  --service-account-key-file=/etc/kubernetes/sa.pub \
  --service-account-signing-key-file=/etc/kubernetes/sa.key \
  --service-cluster-ip-range=172.12.0.0/16 \						# Service地址
  --tls-cert-file=/etc/kubernetes/apiserver.crt \
  --tls-private-key-file=/etc/kubernetes/apiserver.key \
  --proxy-client-cert-file=/etc/kubernetes/front-proxy-client.crt \
  --proxy-client-key-file=/etc/kubernetes/front-proxy-client.key \
  --requestheader-allowed-names=front-proxy-client \
  --requestheader-client-ca-file=/etc/kubernetes/front-proxy-ca.crt \
  --requestheader-extra-headers-prefix=X-Remote-Extra- \
  --requestheader-group-headers=X-Remote-Group \
  --requestheader-username-headers=X-Remote-User
[Install]
WantedBy=multi-user.target
[root@master ~]# systemctl daemon-reload
[root@master ~]# systemctl enable --now apiserver
[root@master ~]# systemctl status apiserver
● apiserver.service - apiServer
   Loaded: loaded (/usr/lib/systemd/system/apiserver.service; enabled; vendor preset: disabled)
   Active: active (running) since Sun 2022-09-18 16:36:41 CST; 37s ago
 Main PID: 14714 (kube-apiserver)
    Tasks: 11 (limit: 23494)
   Memory: 239.9M
   CGroup: /system.slice/apiserver.service
           └─14714 /usr/local/sbin/kube-apiserver --advertise-address=192.168.64.31
[root@master ~]# ss -lntp
State                   Recv-Q                  Send-Q                                   Local Address:Port                                   Peer Address:Port                 Process
LISTEN                  0                       128                                            0.0.0.0:22                                          0.0.0.0:*                     users:(("sshd",pid=960,fd=5))
LISTEN                  0                       128                                               [::]:22                                             [::]:*                     users:(("sshd",pid=960,fd=7))
LISTEN                  0                       128                                                  *:6443                                              *:*                     users:(("kube-apiserver",pid=14714,fd=7))
```

## CM组件部署

查看通过adm部署生成Controller-Manager配置文件

```shell
kube-controller-manager
    - --allocate-node-cidrs=true
    - --authentication-kubeconfig=/etc/kubernetes/controller-manager.conf
    - --authorization-kubeconfig=/etc/kubernetes/controller-manager.conf
    - --bind-address=127.0.0.1
    - --client-ca-file=/etc/kubernetes/pki/ca.crt
    - --cluster-cidr=192.11.0.0/16						# Pod地址
    - --cluster-name=kubernetes
    - --cluster-signing-cert-file=/etc/kubernetes/pki/ca.crt
    - --cluster-signing-key-file=/etc/kubernetes/pki/ca.key
    - --controllers=*,bootstrapsigner,tokencleaner
    - --kubeconfig=/etc/kubernetes/controller-manager.conf
    - --leader-elect=true
    - --requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt				# 可不需要
    - --root-ca-file=/etc/kubernetes/pki/ca.crt
    - --service-account-private-key-file=/etc/kubernetes/pki/sa.key
    - --service-cluster-ip-range=192.12.0.0/16
    - --use-service-account-credentials=true
```

### 创建CM证书

```shell
[root@master ~]# cd /etc/kubernetes/
[root@master kubernetes]# vi controller-manager.cnf
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
basicConstraints = critical, CA:FALSE
authorityKeyIdentifier = keyid,issuer
[root@master kubernetes]# openssl req -new -newkey rsa:2048 -keyout controller-manager.key -out controller-manager.csr -nodes -subj '/CN=system:kube-controller-manager'
[root@master kubernetes]# openssl x509 -req -sha256 -days 36500 -extfile controller-manager.cnf -extensions v3_req -in controller-manager.csr -CA ca.crt -CAkey ca.key -out controller-manager.crt -CAcreateserial
[root@master kubernetes]# ls controller-manager*
controller-manager.cnf  controller-manager.crt  controller-manager.csr  controller-manager.key
```

### 创建config文件

> kubectl config 用于设置kubeconfig并生成kubeconfig文件
>
> 此文件保存kubernetes根证书，cm证书密钥，apiserver组件地址等信息

文件格式可参考：https://www.xiaowangc.com/2022/09/18/k8s-zhengshu/ 最后一节，固定格式，需要通过命令的方式填写相关参数

```shell
[root@master kubernetes]# kubectl config set-cluster kubernetes \
--certificate-authority=ca.crt \							# 指定kubernetes CA证书并
--embed-certs=true \										# 将证书导入此文件
--server=https://192.168.64.31:6443 \						# 指定apiserver组件地址
--kubeconfig=controller-manager.conf						# 将上述配置生成到controller-manager.conf文件
======================================================================================================
# 配置凭证信息  system:kube-controller-manager是依据证书中的CN字段配置的，需要保证一致
[root@master kubernetes]# kubectl config set-credentials system:kube-controller-manager \
--client-certificate=controller-manager.crt \				# 指定cm证书
--client-key=controller-manager.key \						# 指定cm私钥
--embed-certs=true \										# 将证书导入此文件
--kubeconfig=controller-manager.conf						# 将上述配置生成到controller-manager.conf文件

# 配置集群上下文
[root@master kubernetes]# kubectl config set-context system:kube-controller-manager \
--cluster=kubernetes \
--user=system:kube-controller-manager \
--kubeconfig=controller-manager.conf

# 设置默认上下文
[root@master kubernetes]# kubectl config use-context system:kube-controller-manager \
--kubeconfig=controller-manager.conf

=======================================================================================================
[root@master kubernetes]# cat controller-manager.conf
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURBRENDQWVpZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFEREFwcmRXSmwKY201bGRHVnpNQ0FYRFRJeU1Ea3hPREEzTlRBek0xb1lEekl4TWpJd09ESTFNRGMxTURNeldqQVZNUk13RVFZRApWUVFEREFwcmRXSmxjbTVsZEdWek1JSUJJakFOQmdrcWhraUc5dzBCQVFFRkFBT0NBUThBTUlJQkNnS0NBUUVBCjBPd0ZpUDNPTjFyNytQSWkxQzZmQndkNm9hR2tGRWFQU0tuU3hlMmE1VHBxUElJUU1UMUJjb0xWNFRBTG15WksKYW01VWYxN1JpbU1SUU9FekdxaTdORmU2YXlWWGcvTzFnZkJFNUcwVWcxcXlobkhGZ1p6YlhOUlozZXJPNkVZbAp6SC81U1ZMYStUeHRVa0lBZlBRQ3JVY1RmMmV1NHVleGFvcE1sY3pJSFNHMDhTVmFTT2psZks2VHJSUXVqcHduClVNcXE5MytublhrcHBwVVg3VVpSL0NkT1c0VGFzN2ZWc2thL0ZRNlltTWRPK3NXcTVlYXpIcVlxMjV3c044aXQKV011Y0JRSEpQZUdOVHFSRUJxZlpabXNab05ZNFgwM3Azb1JFS1NHM0ZoVkxBUEtaNGNFZG5LVng4eFVaNkVrVApQdDh4am9EaW9mQ1pyY3ZsdW1DRmJ3SURBUUFCbzFrd1Z6QU9CZ05WSFE4QkFmOEVCQU1DQXFRd0R3WURWUjBUCkFRSC9CQVV3QXdFQi96QWRCZ05WSFE0RUZnUVVHMGptODNaM2pneExWeVVLVnVaSVVkN3hCdkF3RlFZRFZSMFIKQkE0d0RJSUthM1ZpWlhKdVpYUmxjekFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBUUVJTkJEU0xCTkVTMkhFOApEekR4UHlRc29uNForeUtydUpsWXRXQm40aGRkK2sxY05WRTF3dDhkZnhKNjF3S2l4S0NUVTBsNmlleXBqbWFZCkMvQUNsdHFsZXQwV0dtNFhITnp1d1crYWhPa25HQlpZZ2d3czZMbktqbjYxMEFmaGtKZlo2UUJreGM5cko5NEMKV1VuUTJlUVlmdlZmVHA1MUJLRWVJU3FUVkRtcktkK0xQcXRyQ0ZydnYwZGlVYU5GZ0tVSnpwVmt4Qzhsb3BYdQpTTlJwTi8wamwyYjRLUkV6MjlGamlFaEgrbXZ5ek5GREN4d2RPQVcySWorekFOS3pva2szM2ZjTTE1cGsxb0VlCnBRRllTRUlaQ09xaDFoMmtUZlpPaFNDdGpLZVVaMlFRUStkSjZndExUcUFWVjJqZFJHTkFoTE9XWWJWeGIzak0KUTFzSDR3PT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
    server: https://192.168.64.31:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: system:kube-controller-manager
  name: system:kube-controller-manager
current-context: system:kube-controller-manager
kind: Config
preferences: {}
users:
- name: system:kube-controller-manager
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURKRENDQWd5Z0F3SUJBZ0lVRTJQV1JlRGphaVRTaS9aeENXYkRWdUd0T2w4d0RRWUpLb1pJaHZjTkFRRUwKQlFBd0ZURVRNQkVHQTFVRUF3d0thM1ZpWlhKdVpYUmxjekFnRncweU1qQTVNVGd4TURJeE5USmFHQTh5TVRJeQpNRGd5TlRFd01qRTFNbG93S1RFbk1DVUdBMVVFQXd3ZWMzbHpkR1Z0T210MVltVXRZMjl1ZEhKdmJHeGxjaTF0CllXNWhaMlZ5TUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUF6S2NYalNtNkE0RDAKUCthMUpkR0plK3Y3anczZFUzVHlSMjNOWHhHQ21xOUZ3T0hoN0xCWXcrSjNMcXlEdHZ6aCszbTRpTXZnRjFFegpSeWMwT3JCWUdFT0FPcE91NlFyc2ZoaDEvS29vek1Wa0xmc0pJT0UyTWlzdDh3YVBxS1dFVCtiY2l3QXV5MEdlCmk0QVdjTWhpYWw0ZzlyNmJWNHBCRTdSbHBFaDN6WUh1QWJ4NndyY2FuOWpGVGNGbmM1TlMzdlBidmdqQzN2QXEKTmI2L253dWZENUpnS3hwZGRHc1JiZHNFL0NZQkNqQzNMTFFvSUM5eDBMa09zVEZjdmFwbk4zZmFqaDd1bUxGcAoyMTkySHdvTmNvNGQwbitpbkJSYU8yN3QxdXVHL1hMT2ZzUmQ5ZjVMckFyQzYxbHhFZ0dsbkt4M21yRG1rUmxUCmZsN1FCc0NTclFJREFRQUJvMVl3VkRBT0JnTlZIUThCQWY4RUJBTUNCYUF3RXdZRFZSMGxCQXd3Q2dZSUt3WUIKQlFVSEF3SXdEQVlEVlIwVEFRSC9CQUl3QURBZkJnTlZIU01FR0RBV2dCUWJTT2J6ZG5lT0RFdFhKUXBXNWtoUgozdkVHOERBTkJna3Foa2lHOXcwQkFRc0ZBQU9DQVFFQWdmd2txK0JnQ0VMdDN0djgzbmFDbGE4dFVKWEdGVHNSCjZ4OVFkWWFYVnVLQkxBTU1xdm1xUDdEeE9oc1FzeEpzVXF2N2lnRmN1ZE92c0lONjlvcDhVeHFiejlEalZPTTAKSnY1c1F3RmxkMGt6WEUyelJERXZyUVlDL0VJbVZiMUFpRjhsZ1RvL3JtR3JuYkxZeDMxRURxeTJsV2Z1eVJaQgpFdTFMQkRUQkRYZEJxSDcyc0NzQmh1c1l3SkU4R2NDQWUvSkJZU0pyaXhQYUt4NDZRaGRqUVNUT3RGQ0ptcTZrCmx6RElFMXcxS0srNjdBREVKaFpWTFoyd01TYXd3R2hCOENOcGNwTDZpdFBOUEpUc1JPU1JZemZTVmg4dmlHNDQKTDJZTUYyQ0xCY0tQa2Z4SzVnaUNlT3A1cTVQTFp3WUlpNU05R1lsTGJXN0dVRWEvajQ3cnlBPT0KLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=
    client-key-data: LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JSUV2d0lCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktrd2dnU2xBZ0VBQW9JQkFRRE1weGVOS2JvRGdQUS8KNXJVbDBZbDc2L3VQRGQxVGRQSkhiYzFmRVlLYXIwWEE0ZUhzc0ZqRDRuY3VySU8yL09IN2ViaUl5K0FYVVROSApKelE2c0ZnWVE0QTZrNjdwQ3V4K0dIWDhxaWpNeFdRdCt3a2c0VFl5S3kzekJvK29wWVJQNXR5TEFDN0xRWjZMCmdCWnd5R0pxWGlEMnZwdFhpa0VUdEdXa1NIZk5nZTRCdkhyQ3R4cWYyTVZOd1dkemsxTGU4OXUrQ01MZThDbzEKdnIrZkM1OFBrbUFyR2wxMGF4RnQyd1Q4SmdFS01MY3N0Q2dnTDNIUXVRNnhNVnk5cW1jM2Q5cU9IdTZZc1duYgpYM1lmQ2cxeWpoM1NmNktjRkZvN2J1M1c2NGI5Y3M1K3hGMzEva3VzQ3NMcldYRVNBYVdjckhlYXNPYVJHVk4rClh0QUd3Skt0QWdNQkFBRUNnZ0VBUE1mRGJ1RmRwWHkvRGR0dklYUkI2TlFGT2s5YjFGVi9QMGVWSHc4TVF2U2IKT3RYYlMzaDBaSGoxL0o2djM4RHJQTXpCeVo4RFJ1bU8yU3NEa0FxZm4xVXMyRGpVVWRJMHVwNTVMRGs5Tk5QTApGUHpoa1NwUjlrUnN1U2pSc2J5MnR5UlJpOWJhRHZQR0twZzRFZmJ4ZzdYQkJJZEhpNUE4RTZZWUtkcDcra1I3CjRKL3IyOWI4d3g3cTExaSsyaU82WFVCc1NTd1M4aEVNNjZyY0RkVXlQclVOc25FTzRQY043Q1o2RUFCV3U2Zi8KajZ0am5tM2NWRk9qeHQ3dU9TV3RkUnA5cHJzc2RsNzhndkRJaUlpT3JEV09XN2lVRk1HNFYrYy9EYWdGZXZ1SwpFQlNsdExicnVWWlRrOU50VWlJZ3QxTDRGZlN5bmgxV1hIcnRWREx5NFFLQmdRRDdza3lPcGpaL3lyZzZkcGsxCmY1WnpWQmxyTHdYL28xZGRFYUZ1R3JMVXN2bmszaFVkUjBTNU82d254TjdOZEg5a2RGY3d4UGpyOHNTYlpUTlYKbVI1RXV5NUUydVJzSmcrMDUrQlJGU0F0amVxWHZFY0ZGWUEvSEdGK1RRUjgwWmRSY1RCNjlvUDdHd0hrbUloZgpjWDVYeUJ0QzQ4UVh1T0RPQy9CTHk4RjNQd0tCZ1FEUUp1Q291Sng2N0ZVUzZhRG44ZzlWS2xSNWV6bUhMVHdDCnZiMEx2MERuajczaHlxdGdJdmg3dDl3VVh3VUk2d3J0bTdSY1YrNkVKNXYxaHF0ZEFFenFlTkRjZnowMENlUjcKeXBvSkNHMFlINEdiOUt1RW42WlkzVEN5dGErbkhyRUV2VFRtK25pN0M3R3VobjRqOTZScEt4MWQxK2F5bTlNOQpxY0tyTEY0SEV3S0JnUUNKWUNXODdpZHMxSDU5R21KQSt1UnBDZ3Zkbm9yTm5wOStZck1UWDJzZ0FKZTRQU2FWCkZtTUNIdm0xc3hSUVd6ZDA0ckw4SVdZamtodVJIVWxKZlFzeVJGL2FvUVp2cU02RjFORndML0dpSzRWUlVDZ0wKTkZNTkh6WnZNeVl4NGt1TzNoS3g2bjdhdlVEcFBmK2c2RmNuSGtjUzJUSWNLSUk2cy9WeHlVSk5EUUtCZ1FDZQphR2ZpbnhRZkRFbzJLV3hWK0VZbzV4MEFrb0dXV1J0cGJxSTNGV2E4a3d6TGorUmFObUxxTEdNbGNhYXdRY2ZBClNoVzVqUVdzdDBRZVYwMkVhbDBldDdFampRV3oyNjl4Y2g5RnJvN3ZvOUtNTUdoemR0Z3VtcTZiNGw3NkRRWmsKZCtXUnZwNHdvdGFtM2gyVEc3eVllTUpSajZRMjJ4V293TSt3V3dSMzF3S0JnUUN0MnhZRGR2Ly9BNWZ2UmNXKwpQZzVJdzZPWThkbGw5Wmgra1dIaDdlMXFRU3l6OTVsa3BYWTZDTms1Vjl5WTFjaWpYanpKWENGWnRtWTBvUk1TCi9rMmkxbW10N3UrUFV4SzdrV1hrUDNBWExTMC9JU1dWNWlBTVlQZTZRd0pmT2llSmxjNC9wVWR3R1Q5aUhrL3EKN1duOEZ6SVJ2WC9wcTZ5MEh5QlVxbXg0SEE9PQotLS0tLUVORCBQUklWQVRFIEtFWS0tLS0tCg==
```

### 配置CM

```shell
[root@master kubernetes]# cd
[root@master ~]# cp kubernetes/server/bin/kube-controller-manager /usr/local/sbin/
[root@master ~]# vi /lib/systemd/system/controller-manager.service
#################
# 注意注释只是需要注意的点，不要把注释写到文件中，确保\后面没有空格，否则可能会报错
#################
[Unit]
Description=ControllerManager
[Service]
Type=simple
ExecStart=kube-controller-manager \
  --allocate-node-cidrs=true \
  --authentication-kubeconfig=/etc/kubernetes/controller-manager.conf \
  --authorization-kubeconfig=/etc/kubernetes/controller-manager.conf \
  --bind-address=127.0.0.1 \						# cm不需要外部访问
  --client-ca-file=/etc/kubernetes/ca.crt \
  --cluster-cidr=172.11.0.0/16	\					# Pod地址
  --cluster-name=kubernetes \
  --cluster-signing-cert-file=/etc/kubernetes/ca.crt \
  --cluster-signing-key-file=/etc/kubernetes/ca.key \
  --controllers=*,bootstrapsigner,tokencleaner \
  --kubeconfig=/etc/kubernetes/controller-manager.conf \
  --leader-elect=true \
  --requestheader-client-ca-file=/etc/kubernetes/front-proxy-ca.crt \
  --root-ca-file=/etc/kubernetes/ca.crt \
  --service-account-private-key-file=/etc/kubernetes/sa.key \
  --service-cluster-ip-range=172.12.0.0/16 \			# Service地址
  --use-service-account-credentials=true
[Install]
WantedBy=multi-user.target
[root@master kubernetes]# systemctl daemon-reload
[root@master kubernetes]# systemctl enable --now controller-manager.service
```

## Scheduler组件部署

通过查看adm生成配置获得如下参数

```shell
kube-scheduler
    - --authentication-kubeconfig=/etc/kubernetes/scheduler.conf
    - --authorization-kubeconfig=/etc/kubernetes/scheduler.conf
    - --bind-address=127.0.0.1
    - --kubeconfig=/etc/kubernetes/scheduler.conf
    - --leader-elect=true
```



### 创建Scheduler证书

```shell
[root@master ~]# cd /etc/kubernetes/
[root@master kubernetes]# vi scheduler.cnf
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
basicConstraints = critical, CA:FALSE
authorityKeyIdentifier = keyid,issuer
[root@master kubernetes]# openssl req -new -newkey rsa:2048 -keyout scheduler.key -out scheduler.csr -nodes -subj '/CN=system:kube-scheduler'
[root@master kubernetes]# openssl x509 -req -sha256 -days 36500 -extfile scheduler.cnf -extensions v3_req -in scheduler.csr -CA ca.crt -CAkey ca.key -out scheduler.crt -CAcreateserial
[root@master kubernetes]# ls scheduler.*
scheduler.cnf  scheduler.crt  scheduler.csr  scheduler.key
```

### 创建config文件

> 与CM的config一致就是部分名字文件需要更改

```shell
[root@master kubernetes]# kubectl config set-cluster kubernetes \
--certificate-authority=ca.crt \
--embed-certs=true \
--server=https://192.168.64.31:6443 \
--kubeconfig=scheduler.conf
======================================================================================================
[root@master kubernetes]# kubectl config set-credentials system:kube-scheduler \
--client-certificate=scheduler.crt \
--client-key=scheduler.key \
--embed-certs=true \
--kubeconfig=scheduler.conf

# 配置集群上下文
[root@master kubernetes]# kubectl config set-context system:kube-scheduler \
--cluster=kubernetes \
--user=system:kube-scheduler \
--kubeconfig=scheduler.conf

# 设置默认上下文
[root@master kubernetes]# kubectl config use-context system:kube-scheduler \
--kubeconfig=scheduler.conf
```

### 配置Scheduler

```shell
root@master kubernetes]# vi /lib/systemd/system/scheduler.service
[Unit]
Description=Scheduler
[Service]
Type=simple
ExecStart=kube-scheduler \
  --authentication-kubeconfig=/etc/kubernetes/scheduler.conf \
  --authorization-kubeconfig=/etc/kubernetes/scheduler.conf \
  --bind-address=127.0.0.1 \
  --kubeconfig=/etc/kubernetes/scheduler.conf \
  --leader-elect=true
[Install]
WantedBy=multi-user.target
[root@master kubernetes]# cd
[root@master ~]# cp kubernetes/server/bin/kube-scheduler /usr/local/sbin/
[root@master ~]# systemctl daemon-reload
[root@master ~]# systemctl restart scheduler.service
```

## Admin文件生成

用于kubectl连接集群

### 创建admin证书

```shell
[root@master ~]# cd /etc/kubernetes/
[root@master kubernetes]# vi admin.cnf
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
basicConstraints = critical, CA:FALSE
authorityKeyIdentifier = keyid,issuer
[root@master kubernetes]# openssl req -new -newkey rsa:2048 -keyout admin.key -out admin.csr -nodes -subj '/CN=kubernetes-admin/O=system:masters'
[root@master kubernetes]# openssl x509 -req -sha256 -days 36500 -extfile admin.cnf -extensions v3_req -in admin.csr -CA ca.crt -CAkey ca.key -out admin.crt -CAcreateserial
```

### 配置config文件

```shell
[root@master kubernetes]# kubectl config set-cluster kubernetes \
--certificate-authority=ca.crt \
--embed-certs=true \
--server=https://192.168.64.31:6443 \
--kubeconfig=admin.conf
======================================================================================================
[root@master kubernetes]# kubectl config set-credentials kubernetes-admin \
--client-certificate=admin.crt \
--client-key=admin.key \
--embed-certs=true \
--kubeconfig=admin.conf

# 配置集群上下文
[root@master kubernetes]# kubectl config set-context kubernetes-admin \
--cluster=kubernetes \
--user=kubernetes-admin \
--kubeconfig=admin.conf

# 设置默认上下文
[root@master kubernetes]# kubectl config use-context kubernetes-admin \
--kubeconfig=admin.conf
```

### 测试Admin

```shell
[root@master kubernetes]# echo "export KUBECONFIG=/etc/kubernetes/admin.conf" >> /etc/profile
[root@master kubernetes]# export KUBECONFIG=/etc/kubernetes/admin.conf
[root@master kubernetes]# kubectl get node
No resources found
[root@master kubernetes]# kubectl get cs
Warning: v1 ComponentStatus is deprecated in v1.19+
NAME                 STATUS    MESSAGE                         ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-0               Healthy   {"health":"true","reason":""}
etcd-2               Healthy   {"health":"true","reason":""}
etcd-1               Healthy   {"health":"true","reason":""}
```

# Node节点部署

**Node只演示一个节点的部署**

下载地址：https://dl.k8s.io/v1.23.6/kubernetes-node-linux-amd64.tar.gz

将node二进制包下载并上传至所有node节点上或直接使用wget下载亦可

## Kubelet组件部署

查看通过adm部署的Node节点配置

adm部署的方式Node节点是采用config方式进行认证的，二进制通常使用kubelet-bootstrap进行认证

```shell
[root@node01 kubernetes]# tree
.
├── kubelet.conf		# config文件	
├── manifests
└── pki
    └── ca.crt			# kubernetesCA证书
    
[root@node01 kubernetes]# cat kubelet.conf
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMvakNDQWVhZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeU1Ea3hOekV3TWpBd05Gb1hEVE15TURreE5ERXdNakF3TkZvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBS1NRCkVScnRRUHBPNzE0VGVueEQ5ZUZ0d25tNFFWWG56L1liUE5MNE5VdXdmcUNPTVg1MGJNTWxiblkya3poZmlSSmQKSWxVK3o4RVYrZGJ6WDJUd0JUWGRxN1pOeDFxdmx2bFpuZDlUY21Zd3l6eUpCRUROVjdmMG9lYWxUSUIwMGVRYQovYjFWeStPL1I0NUhuY3VXUDhMc2lwV3J5U3I1WjRpcnkvVmIrbnB4T2xVeXpTL3BtdVhBTmdGUGVpL0w3MUlpCkxha0NlNmZNRCtMMHpGektCdGVVeVpuWWZMOWxyVm0xeG1QUjVFdkdZN2NaNTl3YmtqbW94VGE1bjdVTzR6SjgKZndiak5oNHVLVzdqOHpvajVTWTJBMEZIZ0RSbnY5NlFxVk5SSkIraGMrRDBrTE1EdmRHcUM0QVpaUzJDbUNLUQpBTUZGUUlGSDIyMCtBRngvNGM4Q0F3RUFBYU5aTUZjd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZDdjNSOHRCVEttMDJwTVlNT0RxRUg0eEpnUktNQlVHQTFVZEVRUU8KTUF5Q0NtdDFZbVZ5Ym1WMFpYTXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBR3hwamdwcjVOZmxxMkJBZC9vdQpTQW14WDIyVi9XTmJZZDNDYVA2dVAwY2F3QXdWMm8xY3lucjNwVk9reG8xaDZ6UjBPWkdvNEJpc2tlWUJKUHNkCjdjeVhwRGVseDh2b2QvUjc1NUQ5TmcwOWUybFlSQWlmSE9NZXkvbjdYb0JLNWNRUk9KUWtmZmxvYWFBRFZsNlAKdVBSNXJhUWd0c0hIZUUwVy9hTitqVTQrby92VFJ4TnZzdUtERVpXY1pyYnBOOUJRZjVGc09vRTAyV25XRi9uUQpVOXNwVjlmanJVU0I5MFhqTG1GdDRFUW1ucm5JWjRjMU42TnJqQ0szTk1NdFlidFE2VXo2M3FDVzRtZmRoK3FFCi9DcmVHTTR1T1JLMnBjVjYwYlFHOVhTOFVDWXc4bWN1SVFuTlRpc05NaXMwbCtkelV1Ui9qYVJZS1EydEdaMTAKWlVJPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    server: https://192.168.64.11:6443
  name: default-cluster
contexts:
- context:
    cluster: default-cluster
    namespace: default
    user: default-auth
  name: default-context
current-context: default-context
kind: Config
preferences: {}
users:
- name: default-auth
  user:
    client-certificate: /var/lib/kubelet/pki/kubelet-client-current.pem
    client-key: /var/lib/kubelet/pki/kubelet-client-current.pem
```

**启动文件**

```shell
# 结构
/lib/systemd/system/
└── kubelet.service
└── kubelet.service.d
    └── 10-kubeadm.conf
[root@node01 kubernetes]# cat /lib/systemd/system/kubelet.service
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=https://kubernetes.io/docs/
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/bin/kubelet
Restart=always
StartLimitInterval=0
RestartSec=10

[Install]
WantedBy=multi-user.target  
[root@node01 kubernetes]# cat /lib/systemd/system/kubelet.service.d/10-kubeadm.conf
# Note: This dropin only works with kubeadm and kubelet v1.11+
[Service]
Environment="KUBELET_KUBECONFIG_ARGS=--bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf --kubeconfig=/etc/kubernetes/kubelet.conf"
Environment="KUBELET_CONFIG_ARGS=--config=/var/lib/kubelet/config.yaml"
# This is a file that "kubeadm init" and "kubeadm join" generates at runtime, populating the KUBELET_KUBEADM_ARGS variable dynamically
EnvironmentFile=-/var/lib/kubelet/kubeadm-flags.env
# This is a file that the user can use for overrides of the kubelet args as a last resort. Preferably, the user should use
# the .NodeRegistration.KubeletExtraArgs object in the configuration files instead. KUBELET_EXTRA_ARGS should be sourced from this file.
EnvironmentFile=-/etc/sysconfig/kubelet			# 空，可以删掉
ExecStart=
ExecStart=/usr/bin/kubelet $KUBELET_KUBECONFIG_ARGS $KUBELET_CONFIG_ARGS $KUBELET_KUBEADM_ARGS $KUBELET_EXTRA_ARGS



[root@node01 kubernetes]# cat /var/lib/kubelet/kubeadm-flags.env
KUBELET_KUBEADM_ARGS="--network-plugin=cni --pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.6"
```

**通过分析上述等文件汇总成如下**

```shell
[Unit]
Description=kubelet
[Service]
Type=simple
ExecStart=kubelet \
  --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf 
  --kubeconfig=/etc/kubernetes/kubelet.conf
  --config=/var/lib/kubelet/config.yaml
  --network-plugin=cni 
  --pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.6
[Install]
WantedBy=multi-user.target
```

### apiServer配置

通过参考adm部署方式参考的apiServer配置文件还不支持bootstrap方式认证，需要添加如下参数

```shell
--token-auth-file=/etc/kubernetes/token.csv
--enable-bootstrap-token-auth=true
--enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,NodeRestriction,ResourceQuota
```

#### 生成token

```shell
[root@master ~]# openssl rand -hex 10
370e9b286ef7528dc199
[root@master kubernetes]# echo '370e9b286ef7528dc199,kubelet-bootstrap,10001,"system:node-bootstrapper"' > /etc/kubernetes/token.csv
[root@master kubernetes]# cat /etc/kubernetes/token.csv
370e9b286ef7528dc199,kubelet-bootstrap,10001,"system:node-bootstrapper"
```

#### 新增apiServer参数

```shell
[root@master ~]# vi /lib/systemd/system/apiserver.service
[Unit]
Description=apiServer
[Service]
Type=simple
ExecStart=kube-apiserver \
  --advertise-address=192.168.64.31 \
  --allow-privileged=true \
  --authorization-mode=Node,RBAC \
  --client-ca-file=/etc/kubernetes/ca.crt \
  --enable-admission-plugins=NodeRestriction \
  --enable-bootstrap-token-auth=true \
  --etcd-cafile=/etc/kubernetes/etcd/etcd-ca.crt \
  --etcd-certfile=/etc/kubernetes/etcd/apiserver-etcd-client.crt \
  --etcd-keyfile=/etc/kubernetes/etcd/apiserver-etcd-client.key \
  --etcd-servers=https://etcd01:2379,https://etcd02:2379,https://etcd03:2379 \
  --kubelet-client-certificate=/etc/kubernetes/apiserver-kubelet-client.crt \
  --kubelet-client-key=/etc/kubernetes/apiserver-kubelet-client.key \
  --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname \
  --secure-port=6443 \
  --service-account-issuer=https://kubernetes.default.svc.cluster.local \
  --service-account-key-file=/etc/kubernetes/sa.pub \
  --service-account-signing-key-file=/etc/kubernetes/sa.key \
  --service-cluster-ip-range=172.12.0.0/16 \
  --tls-cert-file=/etc/kubernetes/apiserver.crt \
  --tls-private-key-file=/etc/kubernetes/apiserver.key \
  --proxy-client-cert-file=/etc/kubernetes/front-proxy-client.crt \
  --proxy-client-key-file=/etc/kubernetes/front-proxy-client.key \
  --requestheader-allowed-names=front-proxy-client \
  --requestheader-client-ca-file=/etc/kubernetes/front-proxy-ca.crt \
  --requestheader-extra-headers-prefix=X-Remote-Extra- \
  --requestheader-group-headers=X-Remote-Group \
  --requestheader-username-headers=X-Remote-User \
  --token-auth-file=/etc/kubernetes/token.csv \
  --enable-bootstrap-token-auth=true \
  --enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,DefaultTolerationSeconds,NodeRestriction,ResourceQuota
[Install]
WantedBy=multi-user.target
[root@master ~]# systemctl daemon-reload
[root@master ~]# systemctl restart apiserver
[root@master ~]# systemctl restart controller-manager
[root@master ~]# systemctl restart scheduler
##########################
# 创建集群角色
[root@master ~]# kubectl create clusterrolebinding kubelet-bootstrap1 --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap
```

### 配置Kubelet

```shell
[root@node01 ~]# tar xf kubernetes-node-linux-amd64.tar.gz
[root@node01 ~]# cp kubernetes/node/bin/kubelet /usr/local/sbin/
[root@node01 ~]# mkdir /var/lib/kubelet/
[root@node01 ~]# vi /lib/systemd/system/kubelet.service
[Unit]
Description=kubelet
[Service]
Type=simple
ExecStart=kubelet \
  --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf \
  --kubeconfig=/etc/kubernetes/kubelet.conf \
  --config=/var/lib/kubelet/config.yaml \
  --network-plugin=cni \
  --pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.6
[Install]
WantedBy=multi-user.target
#####################################################
# 拷贝adm生成config.yaml文件
#####################################################
[root@node01 ~]# vi /var/lib/kubelet/config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false
  webhook:
    cacheTTL: 0s
    enabled: true
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt							# KubernetesCA证书
authorization:
  mode: Webhook
  webhook:
    cacheAuthorizedTTL: 0s
    cacheUnauthorizedTTL: 0s
cgroupDriver: systemd
clusterDNS:
- 172.12.0.10											# 需要注意此DNS地址，Service地址
clusterDomain: cluster.local
cpuManagerReconcilePeriod: 0s
evictionPressureTransitionPeriod: 0s
fileCheckFrequency: 0s
healthzBindAddress: 127.0.0.1
healthzPort: 10248
httpCheckFrequency: 0s
imageMinimumGCAge: 0s
kind: KubeletConfiguration
logging:
  flushFrequency: 0
  options:
    json:
      infoBufferSize: "0"
  verbosity: 0
memorySwap: {}
nodeStatusReportFrequency: 0s
nodeStatusUpdateFrequency: 0s
rotateCertificates: true
runtimeRequestTimeout: 0s
shutdownGracePeriod: 0s
shutdownGracePeriodCriticalPods: 0s
staticPodPath: /etc/kubernetes/manifests
streamingConnectionIdleTimeout: 0s
syncFrequency: 0s
volumeStatsAggPeriod: 0s
[root@node01 ~]# mkdir -p /etc/kubernetes/pki/
[root@node01 ~]# mkdir /etc/kubernetes/manifests
[root@node01 ~]# scp master:/etc/kubernetes/ca.crt /etc/kubernetes/pki/
ca.crt                                                       100% 1103     1.9MB/s   00:00

```

### 创建BootStap文件

```shell
[root@node01 ~]# cp kubernetes/node/bin/kubectl /usr/local/sbin/
[root@node01 ~]# cd /etc/kubernetes/pki/
[root@node01 pki]# kubectl config set-cluster kubernetes \
--certificate-authority=ca.crt \
--embed-certs=true \
--server=https://192.168.64.31:6443 \
--kubeconfig=bootstrap-kubelet.conf
======================================================================================================
[root@node01 pki]#  kubectl config set-credentials kubelet-bootstrap \
--token=370e9b286ef7528dc199 \
--kubeconfig=bootstrap-kubelet.conf

# 配置集群上下文
[root@node01 pki]# kubectl config set-context kubernetes \
--cluster=kubernetes \
--user=kubelet-bootstrap \
--kubeconfig=bootstrap-kubelet.conf

# 设置默认上下文
[root@node01 pki]# kubectl config use-context kubernetes \
--kubeconfig=bootstrap-kubelet.conf
[root@node01 pki]# mv bootstrap-kubelet.conf ../
[root@node01 pki]# cd
[root@node01 ~]#
```

### 启动测试

```shell
[root@node01 ~]# systemctl daemon-reload
[root@node01 ~]# systemctl enable --now kubelet
[root@node01 ~]# systemctl status kubelet
● kubelet.service - kubelet
   Loaded: loaded (/usr/lib/systemd/system/kubelet.service; enabled; vendor preset: disabled)
   Active: active (running) since Sun 2022-09-18 21:03:30 CST; 19s ago
 Main PID: 16226 (kubelet)
    Tasks: 13 (limit: 23494)
   Memory: 29.0M
   CGroup: /system.slice/kubelet.service
```

### 颁发证书

```shell
[root@master ~]# kubectl get csr
NAME        AGE     SIGNERNAME                                    REQUESTOR           REQUESTEDDURATION   CONDITION
csr-4qhgh   53s     kubernetes.io/kube-apiserver-client-kubelet   kubelet-bootstrap   <none>              Pending
[root@master ~]# kubectl certificate approve csr-4qhgh
certificatesigningrequest.certificates.k8s.io/csr-4qhgh approved
[root@master ~]# kubectl get node
NAME     STATUS     ROLES    AGE     VERSION
node01   NotReady   <none>   11m     v1.23.6

# 其他节点一样操作，没地方需要改的
```

## KubePorxy组件部署

KubePorxy在adm方式安装下，文件夹中不存在配置文件等信息，可以通过查看容器获取

**通过查询adm部署的Node中docker容器找到相应的参数**

```shell
[root@node01 ~]# docker ps
CONTAINER ID   IMAGE                                                           COMMAND                  CREATED        STATUS        PORTS     NAMES
fa420f27a34f   4c0375452406                                                    "/usr/local/bin/kube…"   27 hours ago   Up 27 hours             k8s_kube-proxy_kube-proxy-45hb8_kube-system_70fb18c0-3dd8-4f6c-ac31-7e437189db51_0
ee76bafc7838   registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.6   "/pause"                 27 hours ago   Up 27 hours             k8s_POD_kube-proxy-45hb8_kube-system_70fb18c0-3dd8-4f6c-ac31-7e437189db
[root@node01 ~]# docker inspect fa420
[
    {
        "Id": "fa420f27a34f2487d242ae06502e969d6b245be2721b016337829b90c89d5d80",
        "Created": "2022-09-17T10:32:02.250879493Z",
        "Path": "/usr/local/bin/kube-proxy",
        "Args": [
            "--config=/var/lib/kube-proxy/config.conf",
            "--hostname-override=node01"
...
[root@node01 ~]# docker cp fa:/var/lib/kube-proxy/..data/config.conf .
apiVersion: kubeproxy.config.k8s.io/v1alpha1
bindAddress: 0.0.0.0
bindAddressHardFail: false
clientConnection:
  acceptContentTypes: ""
  burst: 0
  contentType: ""
  kubeconfig: /var/lib/kube-proxy/kubeconfig.conf		# 还有一个文件也考出来看看
  qps: 0
clusterCIDR: 192.11.0.0/16						# Pod地址
configSyncPeriod: 0s
conntrack:
  maxPerCore: null
  min: null
  tcpCloseWaitTimeout: null
  tcpEstablishedTimeout: null
detectLocalMode: ""
enableProfiling: false
healthzBindAddress: ""
hostnameOverride: ""
iptables:
  masqueradeAll: false
  masqueradeBit: null
  minSyncPeriod: 0s
  syncPeriod: 0s
ipvs:
  excludeCIDRs: null
  minSyncPeriod: 0s
  scheduler: ""
  strictARP: false
  syncPeriod: 0s
  tcpFinTimeout: 0s
  tcpTimeout: 0s
  udpTimeout: 0s
kind: KubeProxyConfiguration
metricsBindAddress: ""
mode: ""
nodePortAddresses: null
oomScoreAdj: null
portRange: ""
showHiddenMetricsForVersion: ""
udpIdleTimeout: 0s
winkernel:
  enableDSR: false
  networkName: ""
  sourceVip: ""
[root@node01 ~]# docker cp fa:/var/lib/kube-proxy/..data/kubeconfig.conf .  
[root@node01 ~]# cat kubeconfig.conf
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt			# Kubernets Ca证书
    server: https://192.168.64.11:6443
  name: default
contexts:
- context:
    cluster: default
    namespace: default
    user: default
  name: default
current-context: default
users:
- name: default
  user:
    tokenFile: /var/run/secrets/kubernetes.io/serviceaccount/token

```

通过上述信息了解到，KubeProxy有一个配置文件和一个Config文件，Config文件是使用Pod中的SA进行认证的，这里我们二进制方式部署通过证书进行认证

### 创建KubeProxy组件证书

```shell
[root@node01 ~]# cd /etc/kubernetes/pki/
[root@node01 pki]# ls
ca.crt
# 之前Copy了Ca的证书用于kubelet，颁发证书还需要私钥
[root@node01 pki]# scp master:/etc/kubernetes/ca.key .
ca.key                                                             100% 1704     3.0MB/s   00:00
[root@node01 pki]# ls
ca.crt  ca.key
[root@node01 pki]# vi kube-proxy.cnf
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
basicConstraints = critical, CA:FALSE
authorityKeyIdentifier = keyid,issuer
[root@node01 pki]# openssl req -new -newkey rsa:2048 -keyout kube-proxy.key -out kube-proxy.csr -nodes -subj '/CN=system:kube-proxy'
Gen
[root@node01 pki]# openssl x509 -req -sha256 -days 36500 -extfile kube-proxy.cnf -extensions v3_req -in kube-proxy.csr -CA ca.crt -CAkey ca.key -out kube-proxy.crt -CAcreateserial
[root@node01 pki]# ls kube-proxy.*
kube-proxy.cnf  kube-proxy.crt  kube-proxy.csr  kube-proxy.key
```

### 配置config文件

```shell
[root@node01 pki]# kubectl config set-cluster kubernetes \
--certificate-authority=ca.crt \
--embed-certs=true \
--server=https://192.168.64.31:6443 \
--kubeconfig=kubeconfig.conf
======================================================================================================
[root@node01 pki]# kubectl config set-credentials system:kube-proxy \
--client-certificate=kube-proxy.crt \
--client-key=kube-proxy.key \
--embed-certs=true \
--kubeconfig=kubeconfig.conf

# 配置集群上下文
[root@node01 pki]# kubectl config set-context system:kube-proxy \
--cluster=kubernetes \
--user=system:kube-proxy \
--kubeconfig=kubeconfig.conf

# 设置默认上下文
[root@node01 pki]# kubectl config use-context system:kube-proxy \
--kubeconfig=kubeconfig.conf
```

### 配置KubeProxy

```shell
[root@node01 pki]# cd
[root@node01 ~]# mkdir /etc/cni/net.d -p
[root@node01 ~]# cp kubernetes/node/bin/kube-proxy /usr/local/sbin/
[root@node01 ~]# vi /lib/systemd/system/kube-proxy.service
[Unit]
Description=Kube-Proxy
[Service]
Type=simple
ExecStart=kube-proxy \
  --config=/etc/kubernetes/config.conf \
  --hostname-override=node01
[Install]
WantedBy=multi-user.target

[root@node01 ~]# vi /etc/kubernetes/config.conf
apiVersion: kubeproxy.config.k8s.io/v1alpha1
bindAddress: 0.0.0.0
bindAddressHardFail: false
clientConnection:
  acceptContentTypes: ""
  burst: 0
  contentType: ""
  kubeconfig: /etc/kubernetes/pki/kubeconfig.conf
  qps: 0
clusterCIDR: 172.11.0.0/16
configSyncPeriod: 0s
conntrack:
  maxPerCore: null
  min: null
  tcpCloseWaitTimeout: null
  tcpEstablishedTimeout: null
detectLocalMode: ""
enableProfiling: false
healthzBindAddress: ""
hostnameOverride: ""
iptables:
  masqueradeAll: false
  masqueradeBit: null
  minSyncPeriod: 0s
  syncPeriod: 0s
ipvs:
  excludeCIDRs: null
  minSyncPeriod: 0s
  scheduler: ""
  strictARP: false
  syncPeriod: 0s
  tcpFinTimeout: 0s
  tcpTimeout: 0s
  udpTimeout: 0s
kind: KubeProxyConfiguration
metricsBindAddress: ""
mode: ""
nodePortAddresses: null
oomScoreAdj: null
portRange: ""
showHiddenMetricsForVersion: ""
udpIdleTimeout: 0s
winkernel:
  enableDSR: false
  networkName: ""
  sourceVip: ""
[root@node01 ~]# systemctl daemon-reload
[root@node01 ~]# systemctl enable --now kube-proxy
[root@node01 ~]# systemctl status kube-proxy.service
● kube-proxy.service - Kube-Proxy
   Loaded: loaded (/usr/lib/systemd/system/kube-proxy.service; enabled; vendor preset: disabled)
   Active: active (running) since Sun 2022-09-18 22:26:45 CST; 1min 6s ago
 Main PID: 26824 (kube-proxy)
    Tasks: 5 (limit: 23494)
   Memory: 10.6M
   CGroup: /system.slice/kube-proxy.service
```

**其他节点的Kube-Proxy直接拷贝Node01所有Kube-Proxy文件即可**

