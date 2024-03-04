---
title: K8S证书分析
tags:
  - kubernetes
  - OpenSSL
categories: Kubernetes
cover: img/fengmian/k8s.jpeg
abbrlink: fd5f7d86
date: 2022-09-18 04:11:26
---
# K8S证书分析

## 证书

> 对证书没有基础的先去补一下，前置知识：https://www.xiaowangc.com/2022/08/29/openssl/

我们在通过kubeadm方式安装集群后可以在路径`/etc/kubernetes`目录下发现文件，他们分别是

```shell
[root@master kubernetes]# tree
.
├── admin.conf							# kubeconfig文件 暂不做说明
├── controller-manager.conf				# kubeconfig文件 暂不做说明
├── kubelet.conf						# kubeconfig文件 暂不做说明
├── manifests
│   ├── etcd.yaml						# ETCD配置文件
│   ├── kube-apiserver.yaml				# apiserver配置文件
│   ├── kube-controller-manager.yaml	# CM配置文件
│   └── kube-scheduler.yaml				# scheduler配置文件
├── pki
│   ├── apiserver.crt					# apiserver组件证书通过kubernetes进行签发
│   ├── apiserver-etcd-client.crt		# 用于apiserver连接etcd的证书(etcd客户端认证)，通过etcd-ca进行签发
│   ├── apiserver-etcd-client.key		# etcd客户端(apiserver)的私钥
│   ├── apiserver.key					# apiserver组件私钥
│   ├── apiserver-kubelet-client.crt	# 通过kubernetes根签发的用于kubelet身份验证
│   ├── apiserver-kubelet-client.key	# kubelet组件的私钥
│   ├── ca.crt										## kubernetes根证书						  `CA`
│   ├── ca.key										## kubernetes私钥
│   ├── etcd
│   │   ├── ca.crt									## etcd根证书								  `CA`
│   │   ├── ca.key									## etcd私钥
│   │   ├── healthcheck-client.crt	    # 通过Pod方式部署etcd需要用到此证书，用于对etcd服务做存活探测
│   │   ├── healthcheck-client.key		# 存活探测私钥
│   │   ├── peer.crt					# etcd集群中节点互相通信使用的证书
│   │   ├── peer.key					# 邻居私钥
│   │   ├── server.crt								# etcd服务器证书通过etcd根进行签发				
│   │   └── server.key								# etcd组件私钥
│   ├── front-proxy-ca.crt				# 代理端根证书											`CA`
│   ├── front-proxy-ca.key				# 代理端私钥
│   ├── front-proxy-client.crt			# 代理客户端证书由代理CA进行签发
│   ├── front-proxy-client.key			# 代理客户端私钥
│   ├── sa.key					# 私钥 没有关联单独生成即可
│   └── sa.pub					# 公钥 没有关联单独生成即可
└── scheduler.conf						# kubeconfig文件 暂不做说明

3 directories, 30 files
```

## 证书关系
![image-20220917193700095](zs1.png)
![image-20220917193700094](zs.png)

通过仔细分析kubeadm生成证书可以得出上图的关系，线条指向是`证书签发信任关系`，整个`红色`的方框是组件所需要的所有证书

- kubernetes根为apiserver签发证书
- front-proxy根为client签发证书
- etcd根为etcd-client签发证书
- etcd根为etcd-server签发证书
- etcd根为peer签发证书
- etcd根为healthehck-client签发证书



## kubernetes CA详细信息

**对证书结构或信息不了解的请仔细查看此小结的注释，后面不做注释(都是重复没啥必要)**

**通过命令：openssl x509 -in 证书名 -noout -text 即可查看证书详细信息**

**通过上述命令对/etc/kubernetes/pki下的证书依次进行分析并创建一致的证书**

```shell
Certificate:																					# 证书
    Data:																						# 数据
        Version: 3 (0x2)			# 版本 3
        Serial Number: 0 (0x0)		# 序号 0
        Signature Algorithm: sha256WithRSAEncryption		# 签名算法 sha256
        Issuer: CN = kubernetes			# 发行者： CN=kubernetes
        Validity						# 有效期
            Not Before: Sep 17 10:20:04 2022 GMT		# 创建时间
            Not After : Sep 14 10:20:04 2032 GMT		# 失效时间
        Subject: CN = kubernetes		# 主体：CN = kubernetes
        Subject Public Key Info:		# 主体公钥信息
            Public Key Algorithm: rsaEncryption		# 公钥算法rsa
                RSA Public-Key: (2048 bit)			# RSA公钥：2048位
                Modulus:
                    00:a4:90:11:1a:ed:40:fa:4e:ef:5e:13:7a:7c:43:
                    f5:e1:6d:c2:79:b8:41:55:e7:cf:f6:1b:3c:d2:f8:
                    35:4b:b0:7e:a0:8e:31:7e:74:6c:c3:25:6e:76:36:
                    93:38:5f:89:12:5d:22:55:3e:cf:c1:15:f9:d6:f3:
                    5f:64:f0:05:35:dd:ab:b6:4d:c7:5a:af:96:f9:59:
                    9d:df:53:72:66:30:cb:3c:89:04:40:cd:57:b7:f4:
                    a1:e6:a5:4c:80:74:d1:e4:1a:fd:bd:55:cb:e3:bf:
                    47:8e:47:9d:cb:96:3f:c2:ec:8a:95:ab:c9:2a:f9:
                    67:88:ab:cb:f5:5b:fa:7a:71:3a:55:32:cd:2f:e9:
                    9a:e5:c0:36:01:4f:7a:2f:cb:ef:52:22:2d:a9:02:
                    7b:a7:cc:0f:e2:f4:cc:5c:ca:06:d7:94:c9:99:d8:
                    7c:bf:65:ad:59:b5:c6:63:d1:e4:4b:c6:63:b7:19:
                    e7:dc:1b:92:39:a8:c5:36:b9:9f:b5:0e:e3:32:7c:
                    7f:06:e3:36:1e:2e:29:6e:e3:f3:3a:23:e5:26:36:
                    03:41:47:80:34:67:bf:de:90:a9:53:51:24:1f:a1:
                    73:e0:f4:90:b3:03:bd:d1:aa:0b:80:19:65:2d:82:
                    98:22:90:00:c1:45:40:81:47:db:6d:3e:00:5c:7f:
                    e1:cf
                Exponent: 65537 (0x10001)
        X509v3 extensions:						# x509v3 扩展
            X509v3 Key Usage: critical			# x509v3 密钥用法
                Digital Signature, Key Encipherment, Certificate Sign	# 数字签名、密钥加密、证书签名
            X509v3 Basic Constraints: critical	# 基本约束
                CA:TRUE							# 是否是CA根
            X509v3 Subject Key Identifier:		# 密钥标识符
                2B:F7:47:CB:41:4C:A9:B4:DA:93:18:30:E0:EA:10:7E:31:26:04:4A
            X509v3 Subject Alternative Name:	# 主体名称
                DNS:kubernetes					# DNS:kubernetes
    Signature Algorithm: sha256WithRSAEncryption		# 签名算法： sha256
         6c:69:8e:0a:6b:e4:d7:e5:ab:60:40:77:fa:2e:48:09:b1:5f:
         6d:95:fd:63:5b:61:dd:c2:68:fe:ae:3f:47:1a:c0:0c:15:da:
         8d:5c:ca:7a:f7:a5:53:a4:c6:8d:61:eb:34:74:39:91:a8:e0:
         18:ac:91:e6:01:24:fb:1d:ed:cc:97:a4:37:a5:c7:cb:e8:77:
         f4:7b:e7:90:fd:36:0d:3d:7b:69:58:44:08:9f:1c:e3:1e:cb:
         f9:fb:5e:80:4a:e5:c4:11:38:94:24:7d:f9:68:69:a0:03:56:
         5e:8f:b8:f4:79:ad:a4:20:b6:c1:c7:78:4d:16:fd:a3:7e:8d:
         4e:3e:a3:fb:d3:47:13:6f:b2:e2:83:11:95:9c:66:b6:e9:37:
         d0:50:7f:91:6c:3a:81:34:d9:69:d6:17:f9:d0:53:db:29:57:
         d7:e3:ad:44:81:f7:45:e3:2e:61:6d:e0:44:26:9e:b9:c8:67:
         87:35:37:a3:6b:8c:22:b7:34:c3:2d:61:bb:50:e9:4c:fa:de:
         a0:96:e2:67:dd:87:ea:84:fc:2a:de:18:ce:2e:39:12:b6:a5:
         c5:7a:d1:b4:06:f5:74:bc:50:26:30:f2:67:2e:21:09:cd:4e:
         2b:0d:32:2b:34:97:e7:73:52:e4:7f:8d:a4:58:29:0d:ad:19:
         9d:74:65:42
```

## kubernetes CA创建方法

**对参数不了解的请看**

```shell
-extensions v3_req 指定使用X.509 v3版本签发证书(其实就是cnf文件中对于配置块信息)
-extensions v3_ca 
-extfile 指定特殊的v3配置文件
-days 36500 设置证书过期时间 36500为100年   365为一年
-set_serial 0  设置序列号
-signkey 指定CA私钥
-sha256 指定为sha256算法
-in 导入文件
-out 输出文件
```

**对于cnf v3配置详细信息请参考官网：https://www.openssl.org/docs/man1.1.1/man5/x509v3_config.html**

```shell
# 创建cnf文件
[root@master pki]# cat xiaowangc.cnf
[ v3_ca ]
keyUsage = critical, keyCertSign, digitalSignature, keyEncipherment			# 指定密钥用法
basicConstraints = critical,CA:true			# 指定是否为CA根
subjectKeyIdentifier = hash					# 密钥标识符
subjectAltName = DNS:kubernetes				# 主体备用名称

[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment     # 指定密钥用法
extendedKeyUsage = serverAuth								# 扩展密钥用法：服务器验证
basicConstraints = critical, CA:FALSE						# 指定是否为CA根
authorityKeyIdentifier = keyid,issuer						# 密钥标识符
subjectAltName = DNS:kubernetes, DNS:kubernetes.default, DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.cluster.local, DNS:master, IP:127.0.0.1, IP:192.168.64.11					# 主体备用名称
===============================================================================

[root@master pki]# openssl genrsa -out ca.pem			# 生成私钥
[root@master pki]# openssl req -new -key ca.pem -out ca.csr -subj '/CN=kubernetes'		# 生成证书请求文件并设置CN为kubernetes
[root@master pki]# openssl x509 -req -days 36500 -sha256 -extfile xiaowangc.cnf -extensions v3_ca -set_serial 0 -signkey ca.pem -in ca.csr -out ca.crt
Signature ok
subject=CN = kubernetes
Getting Private key
[root@master pki]# openssl x509 -in ca.crt -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 0 (0x0)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = kubernetes
        Validity
            Not Before: Sep 17 13:40:22 2022 GMT
            Not After : Aug 24 13:40:22 2122 GMT
        Subject: CN = kubernetes
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:ca:29:5b:e0:f0:d1:cf:3e:55:a5:dd:e7:0f:e5:
                    86:05:e1:e4:e2:0b:f5:e6:0e:cf:f9:a6:75:5c:76:
                    f7:76:91:90:91:fb:3b:65:25:63:1f:24:8f:7f:43:
                    17:1a:01:24:bd:2e:3a:c2:e3:3a:2b:10:3c:07:13:
                    b8:63:7a:ac:9c:21:f4:48:d3:84:17:a9:60:b5:44:
                    00:58:18:01:34:e7:d2:35:e3:0e:fe:de:22:c1:09:
                    f3:4b:f8:5d:f4:1d:ae:7d:31:b1:19:42:00:cb:62:
                    69:29:3d:90:eb:9d:d8:3e:51:e5:3b:bb:7e:c1:04:
                    93:97:92:d9:47:62:b5:40:5f:8c:0b:82:de:f7:88:
                    23:2e:7b:75:bb:ea:a3:ec:11:7f:48:62:66:a7:33:
                    e3:16:bc:25:ea:91:89:b7:f6:fb:2f:be:a8:9b:3d:
                    a6:1e:da:01:f5:23:d5:b3:1b:40:34:cd:1a:c2:45:
                    0d:a5:a5:0f:2b:be:df:8f:e8:4b:72:05:33:ae:49:
                    36:38:84:4a:87:34:fc:1d:d8:ca:a4:b5:13:ad:54:
                    9b:52:08:16:e5:78:d4:01:a6:04:3e:83:23:77:38:
                    b4:24:66:b1:de:15:e6:56:89:18:a2:af:41:99:63:
                    ee:81:9d:a5:96:01:26:42:3c:f4:7d:37:35:64:1c:
                    be:33
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment, Certificate Sign
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Subject Key Identifier:
                CA:C2:0C:4E:A2:79:5D:1F:39:FF:09:AE:B7:9A:4F:6C:37:66:6E:A7
            X509v3 Subject Alternative Name:
                DNS:kubernetes
    Signature Algorithm: sha256WithRSAEncryption
         ba:22:cc:db:36:c4:6a:00:c1:0e:c2:69:e7:d2:4a:49:a3:df:
         2b:a3:1a:34:4e:89:de:77:fe:f6:25:2b:9c:8c:b2:78:f8:7f:
         58:28:dc:ef:92:18:30:18:2f:b1:f0:48:7b:47:64:ec:c8:bf:
         27:22:b1:b5:ae:65:44:01:47:a9:14:5a:b3:17:3b:f1:13:8a:
         d4:44:78:c9:bc:e5:ce:dd:bf:94:2e:d1:40:53:fe:0e:b7:99:
         58:aa:59:c5:3e:dc:5c:c8:7b:f0:77:ce:29:04:53:ec:dc:ba:
         14:cd:e3:65:4a:76:65:2e:fa:21:94:7a:37:cb:b1:b3:5b:b2:
         cd:1f:0f:d7:35:fe:67:c5:8b:43:f6:dc:47:c8:d2:cd:93:f8:
         d5:74:0e:f5:35:5d:a7:65:3e:ea:67:cb:51:60:22:4b:04:96:
         c4:ed:1f:65:36:6c:9d:79:78:7d:32:c6:9f:52:26:7a:ef:ba:
         da:88:80:52:84:41:88:3a:5d:84:39:14:03:75:8a:4e:86:b8:
         a5:21:67:e0:93:66:dc:b3:08:1b:f4:61:63:4a:d9:c8:7d:c3:
         24:7f:f9:cd:60:18:5e:5d:ba:6e:03:a7:31:99:a0:58:da:a6:
         68:7d:df:08:4b:10:cf:5c:16:9a:37:ba:34:74:7f:ba:15:91:
         21:36:4a:ad
```

## apiserver证书详细信息

```shell
# 参数意思大致和上面差不多
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 7046502440896354319 (0x61ca34a2d28cd80f)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = kubernetes
        Validity
            Not Before: Sep 17 10:20:04 2022 GMT
            Not After : Sep 17 10:20:04 2023 GMT
        Subject: CN = kube-apiserver
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:94:4c:68:af:91:68:bf:3d:c2:59:0e:07:57:14:
                    c2:85:38:18:ed:f7:73:19:d3:5b:18:49:a9:e7:3c:
                    19:86:af:f8:bb:23:97:03:b0:74:9c:e2:2c:76:6e:
                    59:64:dd:2d:a4:1e:ec:78:ff:7a:83:2b:44:71:3c:
                    c6:c0:50:6c:23:49:8d:64:e4:88:20:38:2b:20:d9:
                    0a:28:75:4c:7e:d2:30:1a:05:12:0b:38:8c:9b:8b:
                    ba:5a:69:e4:7d:82:91:db:46:9f:f8:2c:42:7d:71:
                    ee:60:24:cc:71:89:ce:89:7d:1c:ec:c3:9a:b5:e5:
                    bd:ad:2c:d1:ad:b1:74:1b:b1:19:04:d6:a3:64:a4:
                    2a:5b:90:d5:c7:ee:0a:9c:89:24:c7:e8:df:46:05:
                    22:38:29:a5:78:40:a2:80:09:4c:06:1c:a8:cd:c3:
                    73:13:f9:4f:a4:e9:41:61:52:e9:9a:d4:9a:d0:9b:
                    9f:a6:86:2f:8a:b6:a6:1d:de:9f:09:72:55:49:71:
                    4a:3c:64:44:ef:fd:0a:c6:21:f8:0d:cd:1f:77:95:
                    61:41:4f:49:61:8a:32:f1:88:04:26:3b:3e:53:05:
                    4d:47:6a:c6:a1:22:11:3c:d8:4d:44:87:b7:47:ee:
                    ea:1d:17:14:e8:7c:7b:14:44:42:76:a9:f8:1c:06:
                    04:43
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier:
                keyid:2B:F7:47:CB:41:4C:A9:B4:DA:93:18:30:E0:EA:10:7E:31:26:04:4A

            X509v3 Subject Alternative Name:
                DNS:kubernetes, DNS:kubernetes.default, DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.cluster.local, DNS:master, IP Address:192.12.0.1, IP Address:192.168.64.11
    Signature Algorithm: sha256WithRSAEncryption
         4f:f3:64:08:c1:6e:a8:03:c4:a2:94:d3:36:2c:06:0e:95:0d:
         dc:b6:77:ca:5b:ee:41:b9:31:d3:75:79:fc:37:b8:d2:cc:92:
         0d:18:ad:bd:e5:b4:0a:b0:2b:ba:51:94:bf:e4:d3:9d:49:e7:
         2b:b7:df:44:38:a0:4f:e5:48:4a:bd:2d:d3:8d:76:60:f1:41:
         2f:c0:6f:e2:fa:4c:79:a0:7f:ad:6d:3a:9d:0a:ac:82:d7:bc:
         23:0f:ca:66:7f:7d:95:3f:f0:f3:75:41:2b:55:a1:66:6b:98:
         58:4d:35:77:5f:3d:71:00:3a:3c:c9:00:e4:90:4b:9c:1e:42:
         0d:47:e6:25:c2:77:7e:93:65:44:03:4c:d3:7e:f1:cf:e8:eb:
         c1:72:08:35:6a:da:84:2a:f0:22:e2:57:4a:72:83:a9:c6:5c:
         9e:38:fb:21:51:21:d0:12:92:af:63:a0:9c:c9:4b:ff:01:2a:
         af:c3:ef:b5:64:ff:a3:47:44:24:75:8a:03:ed:b0:fe:54:22:
         7c:b9:8b:05:8f:b0:3f:67:48:35:40:bc:97:34:59:48:92:37:
         ba:d1:60:8a:bb:0c:00:a2:1a:15:d5:1f:17:f7:64:42:25:3c:
         09:e7:70:5c:a0:c2:a0:20:65:fb:e4:6d:ae:59:b1:4f:09:60:
         89:88:78:56
```

## apisever证书创建方法

```shell
[root@master pki]# cat xiaowangc.cnf
[ v3_ca ]
keyUsage = critical, keyCertSign, digitalSignature, keyEncipherment
basicConstraints = critical,CA:true
subjectKeyIdentifier = hash
subjectAltName = DNS:kubernetes

[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
basicConstraints = critical, CA:FALSE
authorityKeyIdentifier = keyid,issuer
subjectAltName = DNS:kubernetes, DNS:kubernetes.default, DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.cluster.local, DNS:master, IP:127.0.0.1, IP:192.168.64.11
==============================================

[root@master pki]# openssl req -new -newkey rsa:2048 -keyout apiserver.key -out apiserver.csr -nodes -subj '/CN=kube-apiserver'
[root@master pki]# openssl x509 -req -sha256 -days 36500 -extfile xiaowangc.cnf -extensions v3_req -in apiserver.csr -CA ca.crt -CAkey ca.pem -out apiserver.crt -CAcreateserial
[root@master pki]# openssl x509 -in apiserver.crt -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            19:39:ff:4c:dd:c2:d6:76:f3:cc:7e:f9:b8:8c:fb:4e:b5:17:5b:20
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = kubernetes
        Validity
            Not Before: Sep 17 14:33:08 2022 GMT
            Not After : Aug 24 14:33:08 2122 GMT
        Subject: CN = kube-apiserver
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:e1:08:2b:cd:46:37:e7:3e:9f:c0:99:28:e2:91:
                    d6:82:60:55:8f:69:e8:69:b2:3b:99:f0:05:77:cb:
                    a9:35:e8:b5:07:a4:bc:f2:30:07:33:f4:a3:12:b6:
                    f5:1b:8e:bd:c1:36:d8:b5:d0:fb:4c:4c:92:fb:38:
                    ac:51:52:87:28:ea:e6:c8:49:0f:38:c6:b9:68:0c:
                    79:2c:a7:aa:99:fa:f9:80:47:36:e7:0e:19:f1:96:
                    07:ea:13:c0:5d:30:3c:3e:d6:33:28:f4:49:c1:b1:
                    13:d7:4f:4f:ec:ac:c1:52:98:83:59:e6:df:5f:a1:
                    2b:b3:81:4c:7b:84:d8:2d:29:bd:b3:b6:3d:b5:3a:
                    da:2e:c1:d0:d1:f9:40:ff:e6:ff:c0:9c:e4:d5:19:
                    31:1d:6c:70:4d:1c:9c:c2:0c:9f:51:1e:8a:ba:7c:
                    b1:c4:e1:6e:f2:5b:9c:a6:f4:4c:6e:a2:d6:cf:db:
                    1a:e7:94:d7:6f:2d:b2:10:4f:6a:bb:33:5c:56:bd:
                    45:d1:1a:86:a2:34:9a:32:00:e9:39:c7:10:ce:22:
                    e3:c1:95:56:e3:50:c0:a5:cd:93:ea:f0:f1:48:ef:
                    9d:b0:29:ac:13:6b:fa:f8:73:49:44:30:5d:c4:12:
                    cc:d0:b3:b9:7e:c6:4f:7a:06:19:e5:10:6f:f7:5e:
                    eb:61
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier:
                keyid:33:AC:40:D4:C2:3E:E9:64:2B:F5:00:C7:EB:E9:78:45:62:DD:3E:15

            X509v3 Subject Alternative Name:
                DNS:kubernetes, DNS:kubernetes.default, DNS:kubernetes.default.svc, DNS:kubernetes.default.svc.cluster.local, DNS:master, IP Address:127.0.0.1, IP Address:192.168.64.11
    Signature Algorithm: sha256WithRSAEncryption
         67:5f:de:8e:7f:39:b6:55:2a:c1:20:07:fb:60:fa:0d:b9:fc:
         8b:22:ff:fb:31:8f:b8:6d:cd:2f:7a:56:cd:23:0f:94:68:a4:
         57:90:05:88:e9:b9:08:1e:fa:08:d2:02:ed:1e:87:07:e6:7f:
         40:ba:ca:90:27:19:7f:87:54:5f:1c:96:63:db:19:3a:1a:1c:
         c2:cb:9b:fc:47:39:4d:4c:a2:d4:6d:26:0b:5f:b1:4e:f1:62:
         8b:99:47:62:8f:28:6e:be:4b:94:de:02:f8:75:47:2e:08:81:
         2e:8f:ca:7b:d8:72:c3:18:81:9d:5f:47:b6:5a:c5:5a:13:7f:
         3d:a3:bb:86:2a:68:d5:45:b0:cd:dc:1b:78:d9:ec:4e:1b:d4:
         8e:25:48:0d:b8:16:c7:49:08:f7:66:bb:18:6e:03:42:d8:6c:
         e1:1a:7b:2f:de:19:07:4e:e6:60:d4:21:b5:b0:94:d0:7e:06:
         9c:72:5d:57:b7:36:19:eb:30:5e:40:ea:6a:0b:c9:40:9c:22:
         91:59:93:3e:af:40:06:77:1b:80:72:a1:e4:9d:e0:ac:a8:7d:
         86:3c:a0:9f:67:a2:69:68:30:74:ff:67:ef:8c:5d:db:31:73:
         7c:a9:8c:51:ac:25:e8:f5:bb:0f:8e:63:ba:fb:39:4d:14:bb:
         b0:b0:96:a3
```

## front-proxy CA详细信息

```shell
[root@master pki]# openssl x509 -in front-proxy-ca.crt -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 0 (0x0)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = front-proxy-ca
        Validity
            Not Before: Sep 17 10:20:05 2022 GMT
            Not After : Sep 14 10:20:05 2032 GMT
        Subject: CN = front-proxy-ca
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:ce:fc:51:d7:ab:33:de:d9:bb:e4:b7:e1:34:37:
                    af:ac:67:48:3e:7c:06:c1:35:6d:94:1d:5d:24:d4:
                    79:fc:ac:ce:7c:7a:95:f2:1b:00:51:78:bf:4d:48:
                    cb:6a:78:42:f7:3f:72:1c:60:74:64:8c:d4:01:74:
                    17:e8:1f:9e:d6:ce:7a:63:a9:81:58:cd:fa:83:56:
                    05:7e:25:6a:1a:0d:ea:e6:f9:5e:e8:92:4b:e7:19:
                    80:d9:86:f9:bd:da:7d:53:30:37:ad:fc:4e:e1:dd:
                    5c:ee:e0:50:31:9b:ba:87:cc:4a:e6:3c:c6:87:ca:
                    0c:81:fa:f4:e0:95:4b:41:e9:ea:2b:11:36:c4:26:
                    d8:e0:98:3c:f6:bb:0d:fc:70:e3:de:ba:14:ca:95:
                    56:11:4b:6c:3a:bf:56:1f:00:e0:bf:40:6b:8d:4f:
                    a0:a5:59:fb:35:d9:26:d9:b3:0d:9d:eb:f0:cf:24:
                    a1:85:db:a6:8c:05:f7:fa:de:40:1c:aa:37:4d:36:
                    8f:07:45:ff:ce:63:3f:f5:0f:8e:85:56:d5:3c:64:
                    7c:c9:3d:ef:c8:47:01:ed:97:e7:c9:9c:83:68:da:
                    6b:66:b7:01:41:4a:ab:9e:e2:f3:08:2b:38:73:c0:
                    92:f7:d1:81:7d:06:92:10:1f:47:5d:7a:87:19:09:
                    b3:0f
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment, Certificate Sign
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Subject Key Identifier:
                4A:89:5F:73:59:04:A9:CE:8C:2E:D8:C2:29:3B:99:0E:B4:ED:54:D3
            X509v3 Subject Alternative Name:
                DNS:front-proxy-ca
    Signature Algorithm: sha256WithRSAEncryption
         b2:12:96:0c:a5:7b:ac:56:60:24:c4:ab:71:34:90:ae:2e:df:
         17:44:10:52:8d:b0:92:93:dc:fd:12:d5:98:b7:03:14:6c:cc:
         4e:8d:c8:74:6d:31:58:0f:50:5d:57:00:0e:8b:82:7b:8e:3a:
         f7:7e:9a:a3:7f:3f:8e:7a:8e:55:1c:51:ab:7e:b6:3f:a6:28:
         5d:6c:17:2d:05:2c:4f:69:bb:e7:aa:95:a7:7e:51:76:fc:66:
         9e:22:21:2a:b1:19:d0:0b:2d:8e:91:9d:c6:eb:a1:86:93:9a:
         b9:a4:e3:af:4e:f5:56:5c:7d:d2:0f:03:3c:98:ad:f9:da:13:
         63:f9:15:86:03:8e:09:fd:93:34:c8:dd:ae:9b:b7:cd:29:a5:
         41:89:b3:29:21:40:e7:18:dc:16:4c:0c:ec:0a:1e:02:81:27:
         41:2d:5d:02:67:9b:a0:02:46:ad:a7:8d:c6:2d:a2:55:8c:b1:
         c3:eb:4d:46:51:29:4d:49:8b:f0:b8:24:78:dd:30:ac:40:c9:
         e4:61:65:ee:64:5f:7d:35:1d:2a:50:92:0a:d6:e7:3d:28:9c:
         45:14:69:95:f3:76:de:2e:fb:1c:57:f1:ca:6e:1d:9f:8a:3a:
         80:35:82:78:48:c5:19:8d:bf:da:21:28:2a:ad:62:d5:aa:66:
         94:e3:73:f4
```

## front-proxy CA创建方法

```shell
# front-proxy CA创建方法和kubernetes CA相同，可对比证书详细信息,变化不大

[root@master pki]# cat xiaowangc.cnf
[ v3_ca ]
keyUsage = critical, keyCertSign, digitalSignature, keyEncipherment
basicConstraints = critical,CA:true
subjectKeyIdentifier = hash
subjectAltName = DNS:front-proxy-ca

===============================================================================================
[root@master pki]# openssl req -new -newkey rsa:2048 -keyout front-proxy-ca.key -out front-proxy-ca.csr -nodes -subj '/CN=front-proxy-ca'
Generating a RSA private key
..+++++
...............................+++++
writing new private key to 'front-proxy-ca.key'
-----

[root@master pki]# openssl x509 -req -days 36500 -sha256 -extfile xiaowangc.cnf -extensions v3_ca -set_serial 0 -signkey front-proxy-ca.key -in front-proxy-ca.csr -out front-proxy-ca.crt
[root@master pki]# openssl x509 -in front-proxy-ca.crt -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 0 (0x0)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = front-proxy-ca
        Validity
            Not Before: Sep 17 18:23:03 2022 GMT
            Not After : Aug 24 18:23:03 2122 GMT
        Subject: CN = front-proxy-ca
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:b0:db:55:92:4f:f4:a7:ec:db:5a:ad:a4:97:c9:
                    84:4f:5b:10:d8:f4:28:54:a5:ec:02:62:8c:95:c4:
                    7b:90:da:ca:76:ca:49:4b:3c:cc:98:79:0e:c3:6d:
                    8f:80:b5:e1:26:dd:82:83:8d:8e:03:6e:b5:31:0e:
                    8e:55:e6:41:3a:77:11:4e:9d:ad:10:8d:4c:77:a4:
                    25:2b:02:c0:10:93:fd:18:53:d5:ab:43:70:2d:8d:
                    6b:70:a8:84:d6:3d:df:ad:5f:7d:7f:0b:b6:b0:ba:
                    bc:7c:e5:45:86:57:5b:a4:0a:2a:71:15:76:50:42:
                    eb:e0:22:3a:c3:f0:ec:12:f9:47:f6:21:33:78:8d:
                    87:fa:6d:23:8d:25:91:69:e8:99:a5:78:f9:63:c8:
                    fc:c9:48:b8:b1:0c:fd:1b:14:c3:b8:55:c9:f5:ba:
                    74:37:e4:98:17:69:3e:06:ce:80:1e:a6:e3:3d:de:
                    8f:9b:be:3a:de:c1:8c:89:b3:17:b5:14:d4:2a:37:
                    86:1c:37:71:15:5e:1f:df:02:85:16:5c:4e:3d:e6:
                    d2:35:93:ad:f7:b7:00:4e:44:27:bf:9f:ce:da:45:
                    33:57:1f:87:c5:4c:77:36:44:29:58:d6:53:00:6c:
                    16:00:53:a8:f1:17:50:19:e5:75:e9:e1:96:ad:0d:
                    e7:a5
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment, Certificate Sign
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Subject Key Identifier:
                63:70:65:AC:BF:B0:9E:D2:93:57:C3:E7:2B:55:0F:01:08:FC:16:30
            X509v3 Subject Alternative Name:
                DNS:front-proxy-ca
    Signature Algorithm: sha256WithRSAEncryption
         43:bb:c2:61:96:68:74:72:44:34:06:f2:2e:57:03:1e:73:e9:
         dd:dc:70:49:e1:04:36:1e:d1:35:29:b9:bc:cb:7b:99:0a:c9:
         95:ae:62:42:0a:10:bb:e9:01:6c:57:3b:d0:59:69:56:a3:84:
         83:90:45:fe:9f:90:78:10:38:be:f9:3b:03:c0:14:7e:17:15:
         32:d4:d2:c8:40:8d:84:fe:0b:85:6d:70:04:ea:eb:56:05:a3:
         cd:15:d2:94:fe:bc:04:7f:83:ac:bd:52:e5:f7:b5:17:cb:e4:
         cc:e1:83:62:98:4a:de:f8:6f:cf:d4:b2:57:56:e3:41:e1:37:
         d1:66:72:0b:1e:1c:5f:7d:bb:f7:eb:4e:48:b6:48:cc:3e:47:
         02:a0:69:54:bf:b8:c1:ba:32:fa:7f:89:1d:c6:0a:85:36:81:
         af:5c:74:98:3d:27:bb:ae:12:ac:4b:1b:6f:db:44:c3:66:aa:
         18:8b:c9:4d:b4:b6:31:03:92:34:ce:20:81:73:7d:5c:b9:44:
         4b:7f:ae:bd:da:77:a5:43:0d:83:04:97:30:05:8d:20:9d:42:
         c6:59:50:fe:7c:c8:ca:d4:77:8e:ba:2d:15:53:04:1f:2c:d3:
         03:ba:14:02:36:e6:02:9c:56:db:01:d9:dc:3d:66:6c:34:1c:
         a7:52:82:32
```

## front-proxy-client证书详细信息

```shell
[root@master pki]# openssl x509 -in front-proxy-client.crt -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 8717535010990851132 (0x78fae7e7af24043c)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = front-proxy-ca
        Validity
            Not Before: Sep 17 10:20:05 2022 GMT
            Not After : Sep 17 10:20:05 2023 GMT
        Subject: CN = front-proxy-client
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:e0:7c:d8:e6:03:aa:4e:d1:35:d4:9a:0f:46:a7:
                    fe:58:43:10:c2:d6:7b:84:3b:36:42:f7:dd:f0:29:
                    d7:cc:cb:83:05:d5:80:70:18:aa:bf:b1:6a:f4:44:
                    74:b2:1d:9a:2e:ac:f9:36:3f:18:ed:5e:b8:c9:53:
                    9c:71:65:c4:af:32:ab:c5:0e:d5:a3:b9:f2:55:91:
                    ef:4a:54:42:b2:26:4e:97:5a:9f:67:fd:ea:1a:c3:
                    03:01:b5:ca:9b:d0:78:99:26:5c:da:01:12:40:3b:
                    12:88:cc:25:0b:be:00:73:78:bb:d7:7e:e3:1b:07:
                    ca:f7:f5:c4:73:9e:42:23:1e:e2:b7:58:a7:e5:33:
                    71:dd:13:27:9d:44:5c:ce:b4:f9:50:19:ff:92:ed:
                    37:3e:4a:00:23:4a:a4:8f:94:92:8f:f0:e2:ad:87:
                    43:67:26:dd:d7:f3:c4:60:0e:c2:2f:ca:21:6c:dd:
                    b5:5f:b1:a2:9a:ce:5f:5f:a2:aa:99:25:32:61:bd:
                    be:1d:a4:fc:dd:91:d6:5e:60:32:f4:63:e4:69:ee:
                    90:f2:63:01:ba:5e:64:60:48:7c:42:3f:50:9a:f9:
                    b3:13:a7:e2:50:5d:bb:b2:2d:34:ee:38:8f:49:ac:
                    de:a6:a1:32:d6:2b:83:77:47:1f:5d:36:e4:fc:b4:
                    60:a1
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier:
                keyid:4A:89:5F:73:59:04:A9:CE:8C:2E:D8:C2:29:3B:99:0E:B4:ED:54:D3

    Signature Algorithm: sha256WithRSAEncryption
         49:15:87:5e:b1:7a:bd:be:83:be:0c:55:54:0f:bb:ee:79:21:
         21:03:6e:e6:d2:7b:69:74:fb:b0:a6:6b:b3:d4:d7:60:23:3b:
         5c:89:16:9d:26:7a:be:4f:40:ad:b7:c7:a2:62:3e:ec:7c:ae:
         df:30:05:d9:1f:61:44:8c:57:f7:7e:ba:dc:9c:b8:b9:09:2e:
         83:59:da:44:4d:9a:23:02:51:56:7f:95:e8:59:88:7c:ee:33:
         5f:0d:fe:93:79:1f:48:12:83:8a:2a:99:0c:f4:93:0a:c0:e6:
         c1:ea:17:05:c2:de:e5:31:50:2a:bc:8f:0e:80:57:57:38:4a:
         61:40:c4:12:de:17:53:f7:4a:72:55:4c:9b:5a:d9:48:8d:2b:
         0c:69:16:b2:c9:2a:3e:7b:75:2b:89:c4:89:14:bf:e0:d4:64:
         d0:31:9e:98:d2:5d:bc:c4:54:5f:f8:d0:0f:3e:49:c7:1a:d6:
         83:51:f2:1f:f7:a4:61:bf:8d:58:ca:a4:18:bd:60:7c:bf:d1:
         78:57:bd:2e:87:ff:c8:07:41:b2:ae:1b:36:c6:6d:c0:43:9b:
         c1:44:c6:c3:7e:64:e3:9d:e6:5f:d7:36:a0:d5:a0:c4:2c:d0:
         77:ab:5b:44:44:e8:47:3d:2a:9b:40:7d:ea:39:15:e4:81:32:
         49:9d:21:86
```

## front-proxy-client证书创建方法

```shell
[root@master pki]# vi xiaowangc.cnf
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
basicConstraints = critical, CA:FALSE
authorityKeyIdentifier = keyid,issuer

=================================================================

[root@master pki]# openssl req -new -newkey rsa:2048 -keyout front-proxy-client.key -out front-proxy-client.csr -nodes -subj '/CN=front-proxy-client'
[root@master pki]# openssl x509 -req -sha256 -days 36500 -extfile xiaowangc.cnf -extensions v3_req -in front-proxy-client.csr -CA front-proxy-ca.crt -CAkey front-proxy-ca.key -out front-proxy-client.crt -CAcreateserial
Signature ok
subject=CN = front-proxy-client
Getting CA Private Key
[root@master pki]# openssl x509 -in front-proxy-client.crt -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            7a:ab:72:43:b0:71:af:fe:8e:63:f7:c9:5f:d3:e4:c1:1c:93:ec:56
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = front-proxy-ca
        Validity
            Not Before: Sep 17 18:32:01 2022 GMT
            Not After : Aug 24 18:32:01 2122 GMT
        Subject: CN = front-proxy-client
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:b3:f6:af:47:98:65:d7:60:b5:ab:86:75:96:9b:
                    fc:5a:16:63:62:6d:17:a0:cd:f9:2b:af:ac:5c:8b:
                    41:ed:3d:89:90:6b:c4:bf:a0:90:8b:4c:9a:48:07:
                    03:6b:1e:f7:a7:c1:64:b1:c1:c8:ac:48:c1:db:e1:
                    8f:60:73:5c:d3:4b:bc:13:8a:62:d2:7e:0e:e3:57:
                    87:ae:f1:bb:6d:0f:b8:79:57:4d:73:36:be:b2:fc:
                    3c:b3:8c:b3:ba:ea:cb:58:a9:c9:ba:89:7e:ec:c3:
                    08:eb:4f:41:7d:8d:d0:2e:db:ef:10:af:6d:5b:7c:
                    c8:ca:89:a4:58:43:e5:10:43:da:6a:65:eb:db:fe:
                    d1:cf:7e:29:9d:33:aa:a1:9f:d2:bd:e1:0a:11:15:
                    da:7d:fa:4f:a8:c2:99:ed:be:dd:55:26:01:5a:7d:
                    c4:c0:53:e4:2c:ac:9e:c1:44:aa:0e:cf:26:e3:87:
                    38:dd:47:8f:2b:40:e8:86:a7:64:48:67:86:ed:b6:
                    8b:6e:bd:1f:ea:d5:21:da:39:d7:24:61:2d:33:ff:
                    22:78:8d:4d:1e:ed:89:a4:48:ac:6a:e7:76:a2:4d:
                    72:08:c4:25:1c:13:0f:5e:11:f0:83:70:52:f1:a8:
                    ff:fc:ff:f1:03:ae:c8:d8:e3:cc:89:b5:72:4b:97:
                    71:87
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier:
                keyid:63:70:65:AC:BF:B0:9E:D2:93:57:C3:E7:2B:55:0F:01:08:FC:16:30

    Signature Algorithm: sha256WithRSAEncryption
         a7:b1:36:2f:d2:9c:8c:8a:64:c4:2a:65:57:4d:e6:6d:38:de:
         2c:60:53:3c:b0:96:17:1d:8f:c7:24:cc:03:12:9a:a6:af:98:
         5d:9b:52:9b:11:88:63:58:ab:33:8f:d4:19:f4:c5:d5:1f:3a:
         95:d2:97:a3:b9:a2:73:69:be:2c:60:42:2b:d2:de:f9:a8:2c:
         ee:d2:b8:62:fb:8e:57:44:93:b7:27:f9:ce:76:9c:d5:ad:cb:
         47:95:de:d0:62:97:46:f3:a2:d9:bf:20:b2:d4:36:a4:2e:e8:
         08:61:ea:4a:db:35:58:5e:31:20:a1:f7:4c:21:23:2f:c8:db:
         d4:2c:d7:e4:6c:e5:48:e6:8f:0d:69:78:5c:a4:23:91:e0:13:
         4c:58:4a:10:9b:8f:1b:7d:c5:f9:68:7c:de:69:85:31:74:90:
         f1:00:cb:d9:0d:23:8e:4b:5d:79:26:8b:3d:95:f7:7c:5a:f4:
         a4:7d:fd:db:f4:d3:e2:75:17:18:40:16:b1:b0:c2:73:07:2a:
         3b:b8:17:2a:c4:11:d1:a7:2e:17:e0:71:31:a7:2c:b5:d2:7a:
         db:46:94:ec:09:68:5e:00:14:2d:9a:9d:7e:68:e1:bd:cd:e0:
         48:2e:94:63:01:c3:49:2b:69:a7:db:f4:3c:96:a3:6d:5f:37:
         eb:86:f6:bf
```

## etcd CA详细信息

```shell
[root@master etcd]# openssl x509 -in ca.crt -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 0 (0x0)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = etcd-ca
        Validity
            Not Before: Sep 17 10:20:05 2022 GMT
            Not After : Sep 14 10:20:05 2032 GMT
        Subject: CN = etcd-ca
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:da:27:fa:1a:96:1a:d6:0f:e0:ab:ab:45:c0:7b:
                    33:69:fe:c2:de:78:e1:7f:e7:50:7b:aa:c3:d5:d7:
                    0f:43:c8:01:83:be:cc:8e:a5:d2:05:28:17:ed:30:
                    e2:d1:92:d5:6d:c7:52:76:76:aa:28:d2:21:4b:2a:
                    c0:6c:06:b9:a0:26:8e:80:3e:5a:dc:93:f7:61:4f:
                    fa:de:28:1a:41:df:0b:5f:13:50:2c:e3:49:b1:34:
                    42:c9:7a:f4:7c:8e:04:40:8b:ea:af:d6:85:96:6a:
                    37:d0:8b:1c:81:a6:98:17:7a:e7:ef:52:15:4e:83:
                    46:8e:1f:23:68:90:ea:65:52:46:e6:02:cf:98:90:
                    87:22:85:5e:5b:58:a7:68:90:13:b0:5b:15:57:2e:
                    7f:01:f4:7f:b7:80:10:1e:ff:75:f4:28:3b:a5:bc:
                    9c:5a:14:d0:02:e5:ea:33:79:22:99:97:7a:25:46:
                    94:91:79:bc:a6:7b:6a:0b:d7:75:2e:b7:11:cb:3a:
                    dd:0c:83:34:d8:a5:e3:2b:e2:1d:2c:82:c4:c3:e9:
                    67:41:2e:9b:53:dd:51:c2:cf:27:e8:79:5b:8c:c5:
                    33:f5:a8:87:0b:f5:f8:29:62:05:0b:2c:27:f8:c8:
                    65:ed:ba:c2:fe:30:1a:b2:8e:1a:9f:49:14:84:6d:
                    2c:73
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment, Certificate Sign
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Subject Key Identifier:
                6A:87:F2:2F:84:67:97:88:97:A3:1B:55:18:AD:1E:AB:5C:33:5B:14
            X509v3 Subject Alternative Name:
                DNS:etcd-ca
    Signature Algorithm: sha256WithRSAEncryption
         15:9a:c9:5f:d8:b7:a9:38:02:5d:5b:76:2c:b0:8d:c6:9a:74:
         89:2c:05:5c:a5:b3:d9:23:11:70:7b:91:bb:bb:4e:e7:f5:a4:
         84:11:72:42:5d:ff:78:80:f8:ef:ee:4b:e2:00:13:8d:0c:c4:
         43:53:44:d4:85:6a:d3:12:1e:e6:b0:ef:09:65:2e:d7:d3:fe:
         83:dc:c8:e3:51:c0:e8:b4:68:32:59:f2:2d:9c:c5:de:c1:78:
         fd:46:36:06:db:39:ff:65:3a:2f:3a:f6:1f:c9:4e:60:87:53:
         39:db:b4:71:d6:87:16:da:a1:6a:fc:10:33:67:6b:78:68:ff:
         ce:fe:cf:a7:62:fc:b4:ea:1d:9d:e7:14:de:79:22:69:d4:d0:
         9b:c1:59:c0:28:92:80:bc:5d:39:d9:39:09:4b:48:56:6c:f6:
         1a:54:de:31:2f:ca:ef:64:a1:6a:d5:da:e9:ff:d9:a2:52:7a:
         88:fc:5b:7a:60:92:e3:1c:5c:b1:b0:80:18:1d:fe:14:22:69:
         d8:8f:28:0c:4e:42:bc:a5:97:a1:4e:f4:db:22:b1:e4:3f:51:
         ba:f9:04:bc:94:17:43:b0:7c:58:d6:da:11:3e:52:63:41:34:
         4e:5d:c8:bc:01:b8:2a:30:ae:93:8a:92:6b:f0:e6:d3:bd:95:
         89:b1:a7:ec
```

## etcd CA创建方法

```shell
[root@master etcd]# ls
xiaowangc.cnf
[root@master etcd]# cat xiaowangc.cnf
[ v3_ca ]
keyUsage = critical, keyCertSign, digitalSignature, keyEncipherment
basicConstraints = critical,CA:true
subjectKeyIdentifier = hash
subjectAltName = DNS:etcd-ca
==============================================================
[root@master etcd]# openssl req -new -newkey rsa:2048 -keyout etcd-ca.key -out etcd-ca.csr -nodes -subj '/CN=etcd-ca'
Generating a RSA private key
.........+++++
............................................................................................+++++
writing new private key to 'etcd-ca.key'
-----
[root@master etcd]# ls
etcd-ca.csr  etcd-ca.key  xiaowangc.cnf


[root@master etcd]# openssl x509 -req -days 36500 -sha256 -extfile xiaowangc.cnf -extensions v3_ca -set_serial 0 -signkey etcd-ca.key -in etcd-ca.csr -out etcd-ca.crt
Signature ok
subject=CN = etcd-ca
Getting Private key
[root@master etcd]# openssl x509 -in etcd-ca.crt -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 0 (0x0)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = etcd-ca
        Validity
            Not Before: Sep 17 18:39:44 2022 GMT
            Not After : Aug 24 18:39:44 2122 GMT
        Subject: CN = etcd-ca
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:b9:c9:cf:21:2a:e1:4f:b3:5c:5c:cc:0c:8e:6d:
                    bc:86:18:97:0a:5c:ea:da:b8:88:9d:d4:9f:e1:d1:
                    56:48:db:a4:c6:4c:27:63:68:27:70:b6:8b:4b:e0:
                    fd:cb:60:c1:e5:a0:ce:5c:18:a0:4d:65:59:42:c4:
                    ee:32:d2:57:74:7f:b3:2a:de:88:c8:54:b9:f3:f5:
                    21:ee:79:88:11:73:f0:df:52:91:09:62:31:b1:67:
                    a9:61:47:1d:6e:25:d2:0b:7a:4b:29:ce:06:0b:42:
                    8b:e0:c5:aa:58:69:41:b3:b6:ab:ac:62:02:9b:c7:
                    ab:88:23:9e:c0:6d:e4:49:2b:cc:c3:15:71:22:db:
                    fb:14:90:60:c3:4d:6c:4a:4e:3e:53:01:ab:51:ac:
                    33:94:a4:0c:3b:5c:c3:d7:fc:64:f4:a7:f8:75:70:
                    2b:ad:32:e6:18:3d:92:78:fb:5c:bd:be:18:f8:07:
                    95:8a:e3:71:aa:0a:85:e5:ae:1c:7c:64:ec:6e:2b:
                    97:19:f5:0e:71:d0:17:78:13:92:76:8e:bc:3f:53:
                    c7:0d:2a:d6:9d:f1:82:8d:ef:d2:dd:02:2e:39:a5:
                    00:26:35:7e:99:47:93:5a:44:9a:d7:03:05:3d:df:
                    14:47:dc:03:47:9f:31:6f:a5:0a:d1:27:7d:5c:9c:
                    3b:51
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment, Certificate Sign
            X509v3 Basic Constraints: critical
                CA:TRUE
            X509v3 Subject Key Identifier:
                99:DC:10:B3:F8:63:BA:F7:DB:B2:B5:97:24:77:D2:DC:6D:F2:E1:1B
            X509v3 Subject Alternative Name:
                DNS:etcd-ca
    Signature Algorithm: sha256WithRSAEncryption
         0c:08:05:9c:0c:56:6e:52:c8:17:da:42:5a:2f:94:ee:ba:9e:
         ca:7c:b3:f0:cd:1e:55:f5:6b:2d:1c:e8:da:40:e6:b7:55:da:
         6c:7e:2e:33:3c:8e:15:1c:b0:03:ba:e2:cd:a9:51:28:f0:fa:
         c4:a9:70:74:d7:6d:82:ec:47:38:72:b8:dc:aa:61:f4:8b:7f:
         6f:ae:a1:c9:e1:86:a9:16:94:1c:5d:5e:0f:32:95:9c:40:12:
         f1:8c:df:00:91:0d:39:3f:8f:15:b1:93:aa:15:71:af:bb:bb:
         ca:b9:28:ef:6c:cd:e0:7f:65:ce:1c:ef:2f:71:cf:c0:aa:47:
         16:34:62:4a:63:ef:44:e9:c2:0c:cd:22:fb:f4:4a:21:6d:26:
         ad:cc:ac:af:ab:97:a2:14:23:97:3b:be:ec:3b:ca:ff:36:b5:
         b0:1f:00:60:c8:40:6a:61:8d:df:56:fd:c4:08:9d:f7:a6:fc:
         20:71:62:bf:34:74:4b:34:dc:d5:b6:a5:c9:5f:ee:94:5d:01:
         f3:cf:a0:48:3d:74:6b:d5:e3:e4:1a:89:d4:d7:05:84:f2:e3:
         b8:43:8b:c7:15:0c:a6:8f:d9:8f:18:9c:96:9f:c3:a2:bb:43:
         89:6f:8c:8b:51:c8:6c:50:33:d8:ff:ff:c7:4e:d8:db:0d:3b:
         f7:83:f4:aa
```

## etcd证书详细信息

```shell
[root@master etcd]# openssl x509 -in server.crt -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 1417249744485671725 (0x13ab15223a14e32d)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = etcd-ca
        Validity
            Not Before: Sep 17 10:20:05 2022 GMT
            Not After : Sep 17 10:20:05 2023 GMT
        Subject: CN = master
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:c5:6a:dc:04:22:d5:86:1d:ab:af:97:90:bc:49:
                    91:ed:3a:5b:37:f3:4b:7c:55:1f:4b:bc:9b:d2:89:
                    db:7d:aa:8d:a5:a9:b2:2c:a0:00:6d:ee:b2:cd:18:
                    22:b6:87:df:f5:6e:5b:4a:90:92:cc:51:76:af:7c:
                    8c:2a:26:9b:9c:31:c4:b6:c6:b9:28:ea:60:1e:1e:
                    93:86:40:aa:74:10:08:e9:b2:d6:ec:48:b0:54:e2:
                    a3:9e:8f:03:57:44:fd:33:83:11:c9:e1:29:8f:38:
                    4c:82:62:f4:55:f7:40:bd:f3:64:1b:be:f4:f0:3b:
                    c7:e1:b3:09:81:fe:70:44:b8:cb:5e:0e:fd:ac:6c:
                    70:78:c5:1d:5e:a8:2c:4e:8b:6c:00:11:63:d7:39:
                    6f:b8:47:bc:ef:f7:f2:de:c5:d2:24:37:ad:ae:22:
                    75:40:04:96:61:e4:d3:20:94:a6:0f:84:1c:7a:8b:
                    32:7e:54:a3:00:d9:57:8e:d5:23:cd:a6:32:fb:ae:
                    92:25:51:24:f3:39:92:9c:86:6d:94:ab:f5:bf:f7:
                    52:17:03:de:b5:ba:4f:82:6b:79:13:54:bb:2d:ca:
                    b4:7e:88:40:8a:b6:f5:b3:2d:8a:88:f8:9e:f4:77:
                    7e:d5:13:67:0e:bc:2a:a0:6e:d0:76:95:66:00:e3:
                    47:25
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier:
                keyid:6A:87:F2:2F:84:67:97:88:97:A3:1B:55:18:AD:1E:AB:5C:33:5B:14

            X509v3 Subject Alternative Name:
                DNS:localhost, DNS:master, IP Address:192.168.64.11, IP Address:127.0.0.1, IP Address:0:0:0:0:0:0:0:1
    Signature Algorithm: sha256WithRSAEncryption
         21:2b:05:67:46:e1:3b:b5:77:c5:9b:29:6b:06:70:6f:9d:09:
         44:24:40:21:79:77:06:0e:3a:c8:27:2e:89:44:67:af:9e:91:
         0e:4a:a6:4d:03:98:c7:92:36:f5:28:68:68:97:ec:fb:03:25:
         13:54:90:b3:ac:0c:14:cf:d0:6c:d5:be:13:ef:05:3a:4d:43:
         bf:03:d2:7e:c5:16:64:f2:a7:ec:a5:22:2b:3d:50:ef:6e:40:
         c1:43:5e:76:20:19:06:2f:39:cc:b0:71:cb:24:6f:e6:bf:48:
         0b:3f:14:5a:bb:f6:27:b6:a1:25:38:55:db:ea:4c:84:57:9d:
         19:74:66:e1:78:3d:be:04:ad:24:7a:af:d1:a6:fa:e9:26:39:
         bd:14:ba:bc:31:b4:a4:2a:6e:34:db:ca:0c:d9:b2:3a:11:9b:
         f2:15:67:9f:db:a2:54:30:29:d1:be:e9:f3:6f:80:79:f4:35:
         88:4e:6f:d3:6d:f7:4e:88:20:f1:50:ba:71:c3:d7:93:dc:b5:
         07:3d:44:75:4d:75:f3:65:5a:80:b8:29:7a:64:bb:23:c9:03:
         59:22:37:25:57:1f:8f:99:5c:5e:f6:ee:3b:d8:06:60:4d:0d:
         d4:9a:44:3e:79:4a:04:40:5d:6c:16:88:a7:88:d5:d4:00:f9:
         8a:31:13:73
```

## etcd证书创建方法

```shell
[root@master etcd]# cat xiaowangc.cnf
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth,clientAuth
basicConstraints = critical, CA:FALSE
authorityKeyIdentifier = keyid,issuer
subjectAltName = DNS:localhost, DNS:master,IP:127.0.0.1, IP:192.168.64.11
================================================================================================
[root@master etcd]# openssl req -new -newkey rsa:2048 -keyout etcd.key -out etcd.csr -nodes -subj '/CN=master'
Generating a RSA private key
..........+++++
........+++++
writing new private key to 'etcd.key'
-----
[root@master etcd]# openssl x509 -req -sha256 -days 36500 -extfile xiaowangc.cnf -extensions v3_req -in etcd.csr -CA etcd-ca.crt -CAkey etcd-ca.key -out etcd.crt -CAcreateserial
Signature ok
subject=CN = master
Getting CA Private Key
[root@master etcd]# openssl x509 -in etcd.crt -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            71:0d:f4:02:36:9e:08:d4:9c:a8:40:ee:56:ca:df:79:69:ff:3e:47
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = etcd-ca
        Validity
            Not Before: Sep 17 18:49:13 2022 GMT
            Not After : Aug 24 18:49:13 2122 GMT
        Subject: CN = master
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:d8:1d:78:c3:92:84:21:e9:fb:42:5b:90:51:b3:
                    56:4b:4b:ee:a6:95:52:48:6f:c2:89:c3:30:a8:33:
                    b0:a9:9d:22:c1:2d:b6:dd:75:c8:f2:81:16:86:c4:
                    ab:cd:2e:b5:dd:6d:ce:79:9d:24:bd:4a:4f:e3:0c:
                    48:5a:05:cb:40:28:91:db:43:0d:88:66:1a:ad:fc:
                    33:69:74:49:90:96:35:01:fa:5a:2d:b1:0c:e6:e6:
                    2c:7b:90:47:95:7c:13:c9:84:3e:f4:f3:d3:c4:8d:
                    b5:18:a5:22:73:ac:71:a4:ff:31:a4:1e:a8:ac:2b:
                    ab:69:aa:5c:5d:d7:93:d1:a4:c4:dd:87:f4:c8:e2:
                    09:ab:ca:0c:06:c5:02:46:60:3a:a6:37:f9:b4:fa:
                    b3:60:9d:75:58:30:5d:82:e9:a1:62:51:61:af:cd:
                    e8:b1:4a:b2:72:26:1a:59:6a:d3:46:76:80:7b:64:
                    de:61:70:46:45:87:b5:cb:dd:bb:2e:77:f3:00:1e:
                    16:32:8d:6b:65:c8:7a:c0:ce:0e:00:46:07:54:59:
                    e7:d6:d8:63:34:d9:0f:5b:84:d8:64:75:63:37:02:
                    c9:14:4c:05:8a:01:8b:46:60:ea:a1:38:a6:6c:75:
                    1d:3d:a1:41:53:92:b0:2c:e9:58:f9:fe:9e:ea:16:
                    22:31
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier:
                keyid:99:DC:10:B3:F8:63:BA:F7:DB:B2:B5:97:24:77:D2:DC:6D:F2:E1:1B

            X509v3 Subject Alternative Name:
                DNS:localhost, DNS:master, IP Address:127.0.0.1, IP Address:192.168.64.11
    Signature Algorithm: sha256WithRSAEncryption
         1f:de:42:6b:49:8c:df:89:17:93:6c:c6:36:79:6b:87:d9:5f:
         57:9e:2e:5c:d0:91:c7:3d:f5:af:f2:92:3c:72:44:c5:1b:f4:
         d4:51:12:ca:5f:d6:88:10:fa:99:a5:b7:5b:bd:d7:51:71:0c:
         36:76:82:55:2a:49:83:e7:84:ff:b4:fd:46:29:6f:73:59:9e:
         8e:ba:29:cc:4c:37:79:a6:84:88:5d:6a:72:25:82:a2:dc:ed:
         bb:3b:81:51:94:f6:1a:7a:ce:ee:be:cc:65:c5:e2:aa:ed:93:
         59:17:15:6e:fa:6c:32:5a:64:98:6a:8d:c9:c4:2a:3d:2f:d1:
         89:61:c7:df:a9:fa:ea:bf:1e:6f:59:c0:cc:48:e6:9c:63:20:
         2e:32:f1:58:38:c6:54:de:cf:66:5d:ae:b8:c6:b0:ff:3d:25:
         82:99:d7:a1:f3:9b:cb:de:d1:ca:c8:64:68:0d:da:6a:18:c9:
         f6:23:10:84:ff:82:82:80:9e:c0:ba:e4:c8:a5:16:8b:6e:1e:
         ff:e7:e8:5d:5f:08:7a:bd:60:2a:f8:37:bd:a4:ca:11:95:ea:
         05:f9:d7:20:8a:a3:c4:34:b7:c1:2a:56:3d:2a:ef:ab:92:e4:
         3f:75:9f:80:3c:b8:d5:d5:0b:93:67:88:0a:ce:ab:0f:aa:b9:
         f3:24:be:25
```

## peer证书详细信息

```shell
# 此证书与etcd没啥差别
[root@master etcd]# openssl x509 -in peer.crt -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 5472109028630849635 (0x4bf0d62b47bfe863)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = etcd-ca
        Validity
            Not Before: Sep 17 10:20:05 2022 GMT
            Not After : Sep 17 10:20:05 2023 GMT
        Subject: CN = master
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:ca:4c:e3:cd:af:4f:f4:11:0e:8a:2b:c3:b6:6d:
                    18:03:f1:90:29:a2:28:59:4c:3e:7c:5e:ec:47:0c:
                    bd:de:0a:7c:40:ef:9a:2b:bb:30:cb:98:1a:88:47:
                    c9:c6:b7:e4:81:d4:77:e2:88:d8:af:0a:49:a7:be:
                    ae:9c:31:95:fd:65:9a:ca:b1:1e:e1:66:68:37:60:
                    45:86:47:f6:b8:bd:06:92:50:02:96:3a:80:71:51:
                    9c:5c:88:cf:6b:50:e7:f6:6d:ab:6a:94:d6:6a:0d:
                    3a:a7:92:73:90:ce:1c:3c:67:e9:e2:e0:5c:d5:f9:
                    9a:1b:0d:64:97:0c:7e:3e:42:36:7a:24:e3:33:eb:
                    4e:6c:88:76:cd:ad:12:25:a4:53:20:25:64:c4:e9:
                    61:81:fe:c0:e4:05:4d:1a:ee:35:2d:da:b1:31:96:
                    5e:a9:04:6c:a1:45:a5:03:01:60:81:6e:6c:eb:07:
                    f5:79:42:87:f0:64:88:47:bf:86:2d:e4:3a:79:ea:
                    c6:95:d6:2b:4d:5c:2c:72:0d:f7:b9:c5:f3:da:00:
                    32:a9:ac:0d:31:9f:33:27:f0:46:a1:9a:cf:c2:c4:
                    63:da:1c:7b:b9:e2:b2:b0:d2:0c:4d:14:68:4f:83:
                    ca:88:33:02:ad:fe:d6:00:80:9b:66:65:9f:45:1a:
                    f1:ff
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier:
                keyid:6A:87:F2:2F:84:67:97:88:97:A3:1B:55:18:AD:1E:AB:5C:33:5B:14

            X509v3 Subject Alternative Name:
                DNS:localhost, DNS:master, IP Address:192.168.64.11, IP Address:127.0.0.1, IP Address:0:0:0:0:0:0:0:1
    Signature Algorithm: sha256WithRSAEncryption
         31:3b:b9:eb:45:34:c9:48:e0:e2:27:f6:cf:56:48:37:2b:3d:
         10:4f:fb:d8:ea:a2:9a:d4:56:79:d1:7e:09:8e:ec:cd:62:18:
         57:31:43:05:b2:69:01:34:3a:48:ee:25:a1:8b:81:36:2b:11:
         2a:93:06:ba:73:e3:c1:d9:a2:1d:3e:28:72:9c:11:b4:92:f1:
         cc:9e:2d:4b:a2:c0:16:10:c6:e9:6c:68:99:15:53:49:bd:d5:
         3b:57:d9:37:68:98:c6:7c:90:d0:53:f8:19:34:ff:2b:30:c4:
         e2:40:32:b7:f8:f0:bd:74:c7:57:da:92:49:ed:85:f7:af:81:
         b4:e2:ad:17:5b:d4:8a:d6:ea:55:1b:86:e8:3a:c9:5f:ea:fd:
         1e:a7:ae:71:6e:89:70:08:3d:db:45:bf:94:bf:89:f2:c8:2a:
         1b:16:78:34:89:8d:65:db:18:78:46:a3:ba:cb:40:c2:fa:6d:
         bb:c1:dc:b7:e4:45:6c:a8:87:ef:bf:78:ac:c1:cd:96:d6:49:
         08:75:ec:47:38:42:c4:c6:db:a4:f9:56:2c:81:9e:44:81:91:
         c7:73:59:64:f5:79:e3:28:f8:1f:62:49:ee:2a:76:c9:e7:4a:
         f8:4f:2f:0a:65:ef:3f:f6:8b:65:77:c2:90:aa:14:93:d3:18:
         bf:f6:2f:6e
```

## peer证书创建方法

```shell
[root@master etcd]# cat xiaowangc.cnf
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth,clientAuth
basicConstraints = critical, CA:FALSE
authorityKeyIdentifier = keyid,issuer
subjectAltName = DNS:localhost, DNS:master,IP:127.0.0.1, IP:192.168.64.11
================================================================================================
[root@master etcd]# openssl req -new -newkey rsa:2048 -keyout peer.key -out peer.csr -nodes -subj '/CN=master'
[root@master etcd]# openssl x509 -req -sha256 -days 36500 -extfile xiaowangc.cnf -extensions v3_req -in peer.csr -CA etcd-ca.crt -CAkey etcd-ca.key -out peer.crt -CAcreateserial
Signature ok
subject=CN = master
Getting CA Private Key
[root@master etcd]# openssl x509 -in peer.crt -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            71:0d:f4:02:36:9e:08:d4:9c:a8:40:ee:56:ca:df:79:69:ff:3e:48
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = etcd-ca
        Validity
            Not Before: Sep 17 19:50:36 2022 GMT
            Not After : Aug 24 19:50:36 2122 GMT
        Subject: CN = master
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:e9:ef:71:77:f8:93:8e:1c:cb:d8:25:22:56:94:
                    1f:d7:55:34:63:a2:fe:42:33:7e:5d:c3:f0:d2:97:
                    b9:46:bf:03:42:83:2d:49:1e:6b:91:96:2c:22:21:
                    76:1e:0d:2f:c1:fb:c0:72:cf:ef:ae:08:fe:74:a3:
                    ee:0a:8a:c6:3a:bf:2a:aa:c7:ef:0c:9f:e4:2e:12:
                    70:6e:10:52:7c:a3:0b:d5:72:59:fd:41:7e:cf:f3:
                    ee:ed:7e:d9:87:5f:be:d3:b3:1c:d9:ed:d2:ef:8e:
                    7d:44:44:39:f7:bc:01:00:a7:ae:d7:6d:86:05:58:
                    df:9e:ed:cd:76:49:f1:63:71:2c:4e:d1:3f:e7:35:
                    e5:96:11:43:49:ba:ce:64:36:ef:81:f3:99:73:6c:
                    e2:04:0a:4d:f0:27:cf:41:e7:15:7e:8b:b2:ff:b6:
                    ae:d5:c8:f5:a5:f3:58:13:3d:97:0b:f3:63:48:ae:
                    61:1f:f7:73:82:86:64:3f:2e:36:f3:50:b8:ae:f6:
                    c2:48:cf:e0:00:0b:42:0e:09:9e:3b:c4:f1:28:e5:
                    c2:a7:51:98:a4:3b:dc:34:96:ec:9f:24:a4:71:26:
                    e0:de:c4:37:f3:1b:23:b9:c0:ed:a1:7f:8e:d5:32:
                    49:b5:b0:4e:1b:e0:66:6e:75:37:1d:e6:4d:dc:a6:
                    06:eb
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Server Authentication, TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier:
                keyid:99:DC:10:B3:F8:63:BA:F7:DB:B2:B5:97:24:77:D2:DC:6D:F2:E1:1B

            X509v3 Subject Alternative Name:
                DNS:localhost, DNS:master, IP Address:127.0.0.1, IP Address:192.168.64.11
    Signature Algorithm: sha256WithRSAEncryption
         a9:0e:22:f3:47:52:4f:61:3e:4a:3a:03:d2:51:3e:9c:f2:96:
         ed:ff:00:6b:f8:cc:68:30:da:6e:b2:50:f9:10:78:70:de:60:
         18:fc:b4:2c:7a:be:c3:48:65:b2:35:7e:79:ce:59:f1:74:bb:
         4f:3e:58:ae:d3:90:e5:63:f2:f2:17:0c:ad:61:68:77:c2:7f:
         13:37:c7:42:57:40:ce:a7:a7:b5:13:a4:56:ae:a7:14:b0:e8:
         f3:b2:67:8b:25:e5:87:2d:f6:c8:40:eb:f1:d7:79:6d:45:45:
         d9:4f:a9:a5:70:1c:78:fd:19:47:b2:6e:f5:39:7c:79:ee:c8:
         6b:d1:12:9d:4c:4c:29:9b:f7:12:4d:32:56:8d:2e:db:c3:1a:
         67:a1:00:f2:15:95:7c:c1:65:70:57:e5:99:90:8d:0d:9d:dc:
         3f:e3:42:90:9a:6a:42:5e:24:19:da:65:56:37:39:9c:c5:84:
         5e:37:21:89:f2:4a:2d:e0:8c:10:08:27:4d:ec:ea:e2:a9:4d:
         c7:a3:ff:0d:21:0d:eb:db:3c:dc:4e:83:75:d7:75:15:43:0d:
         33:74:f6:2d:b3:b2:e6:96:cb:22:19:5e:3b:34:57:4c:3f:9f:
         e3:3f:b3:06:3c:f2:15:c1:54:cd:bb:62:3a:39:17:21:da:d6:
         1d:79:5a:aa
```

## healthehck-client证书

此证书在二进制部署方式不需要，用于ETCD通过pod创建时使用


## controller-manager详细信息

**controller-manager证书是存放在/etc/kubernetes/controller-manager.conf文件中**

```shell
[root@master kubernetes]# cat controller-manager.conf
apiVersion: v1
clusters:
- cluster:						# 下面是CA证书信息
    certificate-authority-data: 		LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMvakNDQWVhZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeU1Ea3hOekV3TWpBd05Gb1hEVE15TURreE5ERXdNakF3TkZvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBS1NRCkVScnRRUHBPNzE0VGVueEQ5ZUZ0d25tNFFWWG56L1liUE5MNE5VdXdmcUNPTVg1MGJNTWxiblkya3poZmlSSmQKSWxVK3o4RVYrZGJ6WDJUd0JUWGRxN1pOeDFxdmx2bFpuZDlUY21Zd3l6eUpCRUROVjdmMG9lYWxUSUIwMGVRYQovYjFWeStPL1I0NUhuY3VXUDhMc2lwV3J5U3I1WjRpcnkvVmIrbnB4T2xVeXpTL3BtdVhBTmdGUGVpL0w3MUlpCkxha0NlNmZNRCtMMHpGektCdGVVeVpuWWZMOWxyVm0xeG1QUjVFdkdZN2NaNTl3YmtqbW94VGE1bjdVTzR6SjgKZndiak5oNHVLVzdqOHpvajVTWTJBMEZIZ0RSbnY5NlFxVk5SSkIraGMrRDBrTE1EdmRHcUM0QVpaUzJDbUNLUQpBTUZGUUlGSDIyMCtBRngvNGM4Q0F3RUFBYU5aTUZjd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZDdjNSOHRCVEttMDJwTVlNT0RxRUg0eEpnUktNQlVHQTFVZEVRUU8KTUF5Q0NtdDFZbVZ5Ym1WMFpYTXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBR3hwamdwcjVOZmxxMkJBZC9vdQpTQW14WDIyVi9XTmJZZDNDYVA2dVAwY2F3QXdWMm8xY3lucjNwVk9reG8xaDZ6UjBPWkdvNEJpc2tlWUJKUHNkCjdjeVhwRGVseDh2b2QvUjc1NUQ5TmcwOWUybFlSQWlmSE9NZXkvbjdYb0JLNWNRUk9KUWtmZmxvYWFBRFZsNlAKdVBSNXJhUWd0c0hIZUUwVy9hTitqVTQrby92VFJ4TnZzdUtERVpXY1pyYnBOOUJRZjVGc09vRTAyV25XRi9uUQpVOXNwVjlmanJVU0I5MFhqTG1GdDRFUW1ucm5JWjRjMU42TnJqQ0szTk1NdFlidFE2VXo2M3FDVzRtZmRoK3FFCi9DcmVHTTR1T1JLMnBjVjYwYlFHOVhTOFVDWXc4bWN1SVFuTlRpc05NaXMwbCtkelV1Ui9qYVJZS1EydEdaMTAKWlVJPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    server: https://192.168.64.11:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: system:kube-controller-manager
  name: system:kube-controller-manager@kubernetes
current-context: system:kube-controller-manager@kubernetes
kind: Config
preferences: {}
users:
- name: system:kube-controller-manager
  user:                                 # controller-manager证书
    client-certificate-data: 		LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURGakNDQWY2Z0F3SUJBZ0lJZlVjQTJvc3RGMmd3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TWpBNU1UY3hNREl3TURSYUZ3MHlNekE1TVRjeE1ESXdNRFphTUNreApKekFsQmdOVkJBTVRIbk41YzNSbGJUcHJkV0psTFdOdmJuUnliMnhzWlhJdGJXRnVZV2RsY2pDQ0FTSXdEUVlKCktvWklodmNOQVFFQkJRQURnZ0VQQURDQ0FRb0NnZ0VCQUwyWmlNKzEwOG93cVpsNVh2UUp6TkhRVmdkREV5T1IKakFhRC9tZXFWL2ZjaXdrU0pIS1U2bS9jaFdQdVpiVFE2UlNvMWYyK0o5cmpiWFhmWmNPQUJKUHRzZ3JvZGpwSgpqY0N6dmtBNDJWOVVkbmhDSk5JOGNudGhWdTRjd3FlMlFxZDVPNjZWSVpNMTNJZjhwcU1SRU5ScWZTeGg5eFl2CnRTTzB3cWtaYnRrK2lxbk5SaHpKODBBbU5PVFB0S2FFcGo3Wk4ybTV1WC90cGZoU0NuQzdPcjNMZDNxTzBlWlMKZTBHdlB4R3VWUitBMXg4dVNUQndhdHBhN2dHdDc4NHhhY1hhMDhRSDlPcUFQZXZwZWk2V1R6R2VRNEVUTGZMUQphQVJhNm1KSW1qSkQvTjNycHloWnhTL2ZiZE5HWnIxdjhzNDBDZTBVb3RNcWh0aHMycnptSitzQ0F3RUFBYU5XCk1GUXdEZ1lEVlIwUEFRSC9CQVFEQWdXZ01CTUdBMVVkSlFRTU1Bb0dDQ3NHQVFVRkJ3TUNNQXdHQTFVZEV3RUIKL3dRQ01BQXdId1lEVlIwakJCZ3dGb0FVSy9kSHkwRk1xYlRha3hndzRPb1FmakVtQkVvd0RRWUpLb1pJaHZjTgpBUUVMQlFBRGdnRUJBSU9ZZlczQjI5S1VzNEhPdWtxeUltbzBCeU5meHJRYVlLNzdJMWh0ZnZGZ09HVVNCcWRsCkc0YUR2NnZFRndHaWV0c2Q3RGJPc3ZxUnF5TFhOa1c4dll1SnFoMTh4c3MyZTdKWXlYUUtvbXI1VnVaeUFVaXAKMUJFZUJhcEZuaHdkNUcxZTYxajdKT0tMVHl1YUgyMVY1WmJYVnZrbVRUdWMyOHFYdWY5bUx2ME50dDN5SG1naApXcit6em1hSFU2OFhOdExkZEcxVHNjdFlSbXhyRVVTZTkrTmd1dzhnUWFJRlJnRHhoNjBBWERySmZhc2lLV0lmCks5VDNjME55c3d2ZmF0K0VNaXNIaDdiS29OZWhyNndsTE9iSFNGVU0wbHF0d3NRcCtRMVZTUXJRVVh2eE9vTlYKL09sNVVJSUd6VzdhMTBTRmkrWmJxL0FQOThRTnYvSlVzTm89Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    # controller-manager私钥
    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcEFJQkFBS0NBUUVBdlptSXo3WFR5akNwbVhsZTlBbk0wZEJXQjBNVEk1R01Cb1ArWjZwWDk5eUxDUklrCmNwVHFiOXlGWSs1bHRORHBGS2pWL2I0bjJ1TnRkZDlsdzRBRWsrMnlDdWgyT2ttTndMTytRRGpaWDFSMmVFSWsKMGp4eWUyRlc3aHpDcDdaQ3AzazdycFVoa3pYY2gveW1veEVRMUdwOUxHSDNGaSsxSTdUQ3FSbHUyVDZLcWMxRwpITW56UUNZMDVNKzBwb1NtUHRrM2FibTVmKzJsK0ZJS2NMczZ2Y3QzZW83UjVsSjdRYTgvRWE1Vkg0RFhIeTVKCk1IQnEybHJ1QWEzdnpqRnB4ZHJUeEFmMDZvQTk2K2w2THBaUE1aNURnUk10OHRCb0JGcnFZa2lhTWtQODNldW4KS0ZuRkw5OXQwMFptdlcveXpqUUo3UlNpMHlxRzJHemF2T1luNndJREFRQUJBb0lCQVFDc0RQcFFlcENSQnUydwpmcW9DekMzWUs3VVZhL0dmTWtHZDNBTnRjTy9ZMVlJNW5nUURFazFYYXdhRXMxNEo0aFhRa0pGM2JDcGdnRWJoClV2TFdvSUlHOXdpOHkwd1dBbzhtMGpVUHRFYlZNaUU3YWRKZUVVcFYyZlAzcVpPZWUwOHJDR0YzUUk4eU5ndEUKUDZtN2lnMzZwQk9veGRGaGliTlhqbjJpMDVoNmU2MFE3TGUyc25PQWVHRlVHVlNYRHZCRjIzcjVkV0hDQVpZcwplV2Fjbm02MkF2b3VHNHVEYWF6c20zM1hJVkZOYXpkVHdVRGkwb2lmNi9od2ptSk05TTVJeTl0ZC9hTzlyME9OCjFPMVJUMk9ycGcrSWFYWk4zWnJJRFFnWUpSeXZOSm1wTUJud01GMHpaYU5MemNoRlV1QXA0V0xLNmhJN2NJRGgKbkxCK0wvbFpBb0dCQU9oY3VaZEh6LzFhdXdXZWZEbEMwRGMvd1hoTXEzbERwUzZzVGFCT2gvTktsRFBCQ1RXWApkNzR6YTZPQ3Y2c0Nsd3drT3c3L0dhK2UyeTA3NzA4SHcvbU50ak5uVUlxdFc1ZVdkaEZqSWlENmt4ampjSHR0CitiWGxqaE5vSzQzZnlnYUM0Q3IzRnV6ZnJCRUszRDhjTGhvTkFkN0JvUUZ0eWVMb3JlcHEvZDRuQW9HQkFORGoKSzlpb2U3QWZlS1ovYUNVL2dVZkdEYVlNUjI2N2VGemJrdVdvcXZXQlkxV2NLbVNkYzZEbDRvM0VtT2Z3K21ObgpGR01vMG93cDY3UGtDRjcrcUlTcDVYV3c3cGUrOGRMMnN5U1ZMWnM3ejF0NG5hZE82a01GQXhHWG5VSDAxQVVVCkR2UkFWYWVNR3JwNXJiVDFiZG5JMXE4WXJnanV6SjdRUW1qMEFBYWRBb0dCQUttM2NHY3FzS1FnclJHQm5NSkcKSnNiejdsL3J3Q01tWVhRaHJlRTArdCtjelhxdnVBWkl4OUZJeFluOGFmcUNQY2xFZlU2S3pUd1ZENG1PaVZCMApINVFiQ2NXcDVJNGw2UXhqZllGZG93UHJnWjFnSWp4Rksyck1iR1dJWktlUG1ZUC8rN1BtSGZ5TnNxUVFCcWFoCjhwcGNmYzB5S0dOZXlXTFBDSmg3NVVscEFvR0FIM0l6aFpoSGxvb0dWYnBVYVZjWUZVQUJpZi9MT1NaTHhsN2YKekdjSjVZK203cHBsMzJPOHBubzFFdmFIdGxNV3ZxUWo4NUdQc0w0VzE2djZmcUtEcUFVVG9CWVV0UTl2eER5VApWMnlGd3hyTDZvOUwzSVlLeWpBVStDOEU0NHNCNkFuTy9vSTQ0dEk2cTl2cGhKWjJCUlV4REljQW5DT205am1QCjVkRGx1QmtDZ1lCNDcrVUJhTkd4b3h2NFF0N3o5Z1F0d3hrR2Y1WDFHVW9lK2xDUlB6Ris0S2lmMzB2VE9ZdWIKK1RPYkNLSHFrV1drNDZiTXltaGdGcXhMdFFuY0QwaGNiYitiY0tXODdQTG9aK3VMQ1B5Smt5ZTdBZ3NCRUVSTQpGNzVRY21RVUNPZDhWMk5IaU41eHJKSWtIYWQxaXpPTDY4T0tqTDJ2YmFscm5SZHRCSDZkcnc9PQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo=
```

**controller-manager证书是通过base64加密存放与配置文件中，需要进行解密进行查看**

**将client-certificate-data的值通过base64 -d进行解密**

```shell
[root@master kubernetes]# echo LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURGakNDQWY2Z0F3SUJBZ0lJZlVjQTJvc3RGMmd3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TWpBNU1UY3hNREl3TURSYUZ3MHlNekE1TVRjeE1ESXdNRFphTUNreApKekFsQmdOVkJBTVRIbk41YzNSbGJUcHJkV0psTFdOdmJuUnliMnhzWlhJdGJXRnVZV2RsY2pDQ0FTSXdEUVlKCktvWklodmNOQVFFQkJRQURnZ0VQQURDQ0FRb0NnZ0VCQUwyWmlNKzEwOG93cVpsNVh2UUp6TkhRVmdkREV5T1IKakFhRC9tZXFWL2ZjaXdrU0pIS1U2bS9jaFdQdVpiVFE2UlNvMWYyK0o5cmpiWFhmWmNPQUJKUHRzZ3JvZGpwSgpqY0N6dmtBNDJWOVVkbmhDSk5JOGNudGhWdTRjd3FlMlFxZDVPNjZWSVpNMTNJZjhwcU1SRU5ScWZTeGg5eFl2CnRTTzB3cWtaYnRrK2lxbk5SaHpKODBBbU5PVFB0S2FFcGo3Wk4ybTV1WC90cGZoU0NuQzdPcjNMZDNxTzBlWlMKZTBHdlB4R3VWUitBMXg4dVNUQndhdHBhN2dHdDc4NHhhY1hhMDhRSDlPcUFQZXZwZWk2V1R6R2VRNEVUTGZMUQphQVJhNm1KSW1qSkQvTjNycHloWnhTL2ZiZE5HWnIxdjhzNDBDZTBVb3RNcWh0aHMycnptSitzQ0F3RUFBYU5XCk1GUXdEZ1lEVlIwUEFRSC9CQVFEQWdXZ01CTUdBMVVkSlFRTU1Bb0dDQ3NHQVFVRkJ3TUNNQXdHQTFVZEV3RUIKL3dRQ01BQXdId1lEVlIwakJCZ3dGb0FVSy9kSHkwRk1xYlRha3hndzRPb1FmakVtQkVvd0RRWUpLb1pJaHZjTgpBUUVMQlFBRGdnRUJBSU9ZZlczQjI5S1VzNEhPdWtxeUltbzBCeU5meHJRYVlLNzdJMWh0ZnZGZ09HVVNCcWRsCkc0YUR2NnZFRndHaWV0c2Q3RGJPc3ZxUnF5TFhOa1c4dll1SnFoMTh4c3MyZTdKWXlYUUtvbXI1VnVaeUFVaXAKMUJFZUJhcEZuaHdkNUcxZTYxajdKT0tMVHl1YUgyMVY1WmJYVnZrbVRUdWMyOHFYdWY5bUx2ME50dDN5SG1naApXcit6em1hSFU2OFhOdExkZEcxVHNjdFlSbXhyRVVTZTkrTmd1dzhnUWFJRlJnRHhoNjBBWERySmZhc2lLV0lmCks5VDNjME55c3d2ZmF0K0VNaXNIaDdiS29OZWhyNndsTE9iSFNGVU0wbHF0d3NRcCtRMVZTUXJRVVh2eE9vTlYKL09sNVVJSUd6VzdhMTBTRmkrWmJxL0FQOThRTnYvSlVzTm89Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K | base64 -d > cm.crt
[root@master kubernetes]# cat cm.crt
-----BEGIN CERTIFICATE-----
MIIDFjCCAf6gAwIBAgIIfUcA2ostF2gwDQYJKoZIhvcNAQELBQAwFTETMBEGA1UE
AxMKa3ViZXJuZXRlczAeFw0yMjA5MTcxMDIwMDRaFw0yMzA5MTcxMDIwMDZaMCkx
JzAlBgNVBAMTHnN5c3RlbTprdWJlLWNvbnRyb2xsZXItbWFuYWdlcjCCASIwDQYJ
KoZIhvcNAQEBBQADggEPADCCAQoCggEBAL2ZiM+108owqZl5XvQJzNHQVgdDEyOR
jAaD/meqV/fciwkSJHKU6m/chWPuZbTQ6RSo1f2+J9rjbXXfZcOABJPtsgrodjpJ
jcCzvkA42V9UdnhCJNI8cnthVu4cwqe2Qqd5O66VIZM13If8pqMRENRqfSxh9xYv
tSO0wqkZbtk+iqnNRhzJ80AmNOTPtKaEpj7ZN2m5uX/tpfhSCnC7Or3Ld3qO0eZS
e0GvPxGuVR+A1x8uSTBwatpa7gGt784xacXa08QH9OqAPevpei6WTzGeQ4ETLfLQ
aARa6mJImjJD/N3rpyhZxS/fbdNGZr1v8s40Ce0UotMqhths2rzmJ+sCAwEAAaNW
MFQwDgYDVR0PAQH/BAQDAgWgMBMGA1UdJQQMMAoGCCsGAQUFBwMCMAwGA1UdEwEB
/wQCMAAwHwYDVR0jBBgwFoAUK/dHy0FMqbTakxgw4OoQfjEmBEowDQYJKoZIhvcN
AQELBQADggEBAIOYfW3B29KUs4HOukqyImo0ByNfxrQaYK77I1htfvFgOGUSBqdl
G4aDv6vEFwGietsd7DbOsvqRqyLXNkW8vYuJqh18xss2e7JYyXQKomr5VuZyAUip
1BEeBapFnhwd5G1e61j7JOKLTyuaH21V5ZbXVvkmTTuc28qXuf9mLv0Ntt3yHmgh
Wr+zzmaHU68XNtLddG1TsctYRmxrEUSe9+Nguw8gQaIFRgDxh60AXDrJfasiKWIf
K9T3c0Nyswvfat+EMisHh7bKoNehr6wlLObHSFUM0lqtwsQp+Q1VSQrQUXvxOoNV
/Ol5UIIGzW7a10SFi+Zbq/AP98QNv/JUsNo=
-----END CERTIFICATE-----
[root@master kubernetes]# openssl x509 -in cm.crt -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 9027184916725307240 (0x7d4700da8b2d1768)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = kubernetes
        Validity
            Not Before: Sep 17 10:20:04 2022 GMT
            Not After : Sep 17 10:20:06 2023 GMT
        Subject: CN = system:kube-controller-manager
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:bd:99:88:cf:b5:d3:ca:30:a9:99:79:5e:f4:09:
                    cc:d1:d0:56:07:43:13:23:91:8c:06:83:fe:67:aa:
                    57:f7:dc:8b:09:12:24:72:94:ea:6f:dc:85:63:ee:
                    65:b4:d0:e9:14:a8:d5:fd:be:27:da:e3:6d:75:df:
                    65:c3:80:04:93:ed:b2:0a:e8:76:3a:49:8d:c0:b3:
                    be:40:38:d9:5f:54:76:78:42:24:d2:3c:72:7b:61:
                    56:ee:1c:c2:a7:b6:42:a7:79:3b:ae:95:21:93:35:
                    dc:87:fc:a6:a3:11:10:d4:6a:7d:2c:61:f7:16:2f:
                    b5:23:b4:c2:a9:19:6e:d9:3e:8a:a9:cd:46:1c:c9:
                    f3:40:26:34:e4:cf:b4:a6:84:a6:3e:d9:37:69:b9:
                    b9:7f:ed:a5:f8:52:0a:70:bb:3a:bd:cb:77:7a:8e:
                    d1:e6:52:7b:41:af:3f:11:ae:55:1f:80:d7:1f:2e:
                    49:30:70:6a:da:5a:ee:01:ad:ef:ce:31:69:c5:da:
                    d3:c4:07:f4:ea:80:3d:eb:e9:7a:2e:96:4f:31:9e:
                    43:81:13:2d:f2:d0:68:04:5a:ea:62:48:9a:32:43:
                    fc:dd:eb:a7:28:59:c5:2f:df:6d:d3:46:66:bd:6f:
                    f2:ce:34:09:ed:14:a2:d3:2a:86:d8:6c:da:bc:e6:
                    27:eb
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier:
                keyid:2B:F7:47:CB:41:4C:A9:B4:DA:93:18:30:E0:EA:10:7E:31:26:04:4A

    Signature Algorithm: sha256WithRSAEncryption
         83:98:7d:6d:c1:db:d2:94:b3:81:ce:ba:4a:b2:22:6a:34:07:
         23:5f:c6:b4:1a:60:ae:fb:23:58:6d:7e:f1:60:38:65:12:06:
         a7:65:1b:86:83:bf:ab:c4:17:01:a2:7a:db:1d:ec:36:ce:b2:
         fa:91:ab:22:d7:36:45:bc:bd:8b:89:aa:1d:7c:c6:cb:36:7b:
         b2:58:c9:74:0a:a2:6a:f9:56:e6:72:01:48:a9:d4:11:1e:05:
         aa:45:9e:1c:1d:e4:6d:5e:eb:58:fb:24:e2:8b:4f:2b:9a:1f:
         6d:55:e5:96:d7:56:f9:26:4d:3b:9c:db:ca:97:b9:ff:66:2e:
         fd:0d:b6:dd:f2:1e:68:21:5a:bf:b3:ce:66:87:53:af:17:36:
         d2:dd:74:6d:53:b1:cb:58:46:6c:6b:11:44:9e:f7:e3:60:bb:
         0f:20:41:a2:05:46:00:f1:87:ad:00:5c:3a:c9:7d:ab:22:29:
         62:1f:2b:d4:f7:73:43:72:b3:0b:df:6a:df:84:32:2b:07:87:
         b6:ca:a0:d7:a1:af:ac:25:2c:e6:c7:48:55:0c:d2:5a:ad:c2:
         c4:29:f9:0d:55:49:0a:d0:51:7b:f1:3a:83:55:fc:e9:79:50:
         82:06:cd:6e:da:d7:44:85:8b:e6:5b:ab:f0:0f:f7:c4:0d:bf:
         f2:54:b0:da
```

## controller-manager证书创建

```shell
[root@master etcd]# cat xiaowangc.cnf
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
basicConstraints = critical, CA:FALSE
authorityKeyIdentifier = keyid,issuer
==============================================================================================
[root@master pki]# openssl req -new -newkey rsa:2048 -keyout controller-manager.key -out controller-manager.csr -nodes -subj '/CN=system:kube-controller-manager'
Generating a RSA private key
.....................................+++++
........................+++++
writing new private key to 'controller-manager.key'
-----
[root@master pki]# openssl x509 -req -sha256 -days 36500 -extfile xiaowangc.cnf -extensions v3_req -in controller-manager.csr -CA ca.crt -CAkey ca.pem -out controller-manager.crt -CAcreateserial
Signature ok
subject=CN = system:kube-controller-manager
Getting CA Private Key
[root@master pki]# openssl x509 -in controller-manager.crt -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            19:39:ff:4c:dd:c2:d6:76:f3:cc:7e:f9:b8:8c:fb:4e:b5:17:5b:21
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = kubernetes
        Validity
            Not Before: Sep 17 21:55:00 2022 GMT
            Not After : Aug 24 21:55:00 2122 GMT
        Subject: CN = system:kube-controller-manager
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:a2:08:62:a6:6e:21:0e:1a:e2:73:1a:9b:d7:8b:
                    2c:c0:fe:72:85:77:a3:ca:62:80:5f:bf:f3:6c:14:
                    05:c2:1d:30:68:d7:c9:b0:d1:7f:cf:78:f5:41:8f:
                    a1:60:be:26:58:43:74:c4:af:45:c7:e2:1e:f8:df:
                    53:87:b4:46:20:ab:2e:d7:13:bd:35:f2:55:5b:bd:
                    3a:16:f4:d6:98:c5:a4:7a:57:56:40:ba:98:28:e0:
                    d6:78:11:bd:b5:58:18:8c:4c:ea:8a:88:3e:1b:9a:
                    8f:79:39:32:05:26:61:e1:5d:9c:f1:bb:91:49:8c:
                    39:76:e1:ac:43:a3:dd:5b:82:8b:72:ae:52:83:50:
                    12:20:10:13:3b:66:89:38:9b:de:4a:42:29:81:8a:
                    43:79:31:14:5c:cd:c7:bd:f0:ed:89:99:09:94:d0:
                    e6:43:18:3f:18:14:79:fc:be:85:f7:13:e9:a3:f8:
                    45:67:60:5a:e3:e6:a9:72:79:c4:ca:90:bb:05:89:
                    d3:52:13:f7:6d:b1:10:b7:8a:5a:3e:56:cd:d2:b3:
                    46:bd:fb:10:d3:ba:a0:05:ea:5d:22:c0:40:4e:ed:
                    95:15:7e:80:5b:9a:e7:89:bf:aa:18:1f:b6:ca:1f:
                    c1:a1:79:2c:4f:2c:c6:62:cd:5d:93:35:c7:bd:b6:
                    c8:43
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier:
                keyid:33:AC:40:D4:C2:3E:E9:64:2B:F5:00:C7:EB:E9:78:45:62:DD:3E:15

    Signature Algorithm: sha256WithRSAEncryption
         31:91:9f:f1:f1:99:6c:81:cb:65:8c:df:1f:db:0d:61:b2:b7:
         fb:34:51:7a:61:17:09:42:8e:19:a4:32:2b:de:23:d3:96:32:
         9f:8f:9f:96:0a:65:1f:ae:3b:cc:db:e6:b6:20:99:c9:5e:58:
         c6:da:ea:e3:9a:64:d2:ee:6c:37:f7:ff:66:1d:87:6e:e5:fc:
         fd:87:db:8e:e4:af:f3:2a:e0:46:db:a7:59:94:74:80:ce:07:
         1e:e6:a5:a4:72:26:c2:de:2b:e1:6d:5b:eb:c0:70:0c:3e:ca:
         39:fe:60:ad:c5:44:7c:fe:6f:ae:b9:5d:08:5b:02:05:88:29:
         d4:24:8c:1a:1b:88:fe:58:4a:d5:ee:6f:4b:37:ac:e0:77:23:
         8d:5a:71:cf:f4:f8:5d:b4:36:df:29:aa:11:42:35:0b:39:b7:
         74:e4:81:c6:f3:29:d6:8f:75:3b:50:53:59:43:1c:75:6e:14:
         5e:64:eb:36:1c:1b:f4:6b:b3:9b:c3:42:98:60:eb:2e:ea:ed:
         f3:65:3a:15:9e:7a:c6:99:99:01:aa:1e:08:73:10:3f:c9:06:
         b3:45:b0:b5:3f:db:08:18:60:bd:3d:5d:fa:29:48:ba:21:34:
         f8:16:51:b1:3e:89:2c:27:a4:55:6d:5f:a4:d1:e7:cd:2d:bd:
         74:eb:17:e7
```

## scheduler证书详细信息

**scheduler证书同controller-manager证书一样存放在文件中**

```shell
[root@master kubernetes]# cat scheduler.conf
apiVersion: v1
clusters:
- cluster:
    # CA证书
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMvakNDQWVhZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeU1Ea3hOekV3TWpBd05Gb1hEVE15TURreE5ERXdNakF3TkZvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBS1NRCkVScnRRUHBPNzE0VGVueEQ5ZUZ0d25tNFFWWG56L1liUE5MNE5VdXdmcUNPTVg1MGJNTWxiblkya3poZmlSSmQKSWxVK3o4RVYrZGJ6WDJUd0JUWGRxN1pOeDFxdmx2bFpuZDlUY21Zd3l6eUpCRUROVjdmMG9lYWxUSUIwMGVRYQovYjFWeStPL1I0NUhuY3VXUDhMc2lwV3J5U3I1WjRpcnkvVmIrbnB4T2xVeXpTL3BtdVhBTmdGUGVpL0w3MUlpCkxha0NlNmZNRCtMMHpGektCdGVVeVpuWWZMOWxyVm0xeG1QUjVFdkdZN2NaNTl3YmtqbW94VGE1bjdVTzR6SjgKZndiak5oNHVLVzdqOHpvajVTWTJBMEZIZ0RSbnY5NlFxVk5SSkIraGMrRDBrTE1EdmRHcUM0QVpaUzJDbUNLUQpBTUZGUUlGSDIyMCtBRngvNGM4Q0F3RUFBYU5aTUZjd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZDdjNSOHRCVEttMDJwTVlNT0RxRUg0eEpnUktNQlVHQTFVZEVRUU8KTUF5Q0NtdDFZbVZ5Ym1WMFpYTXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBR3hwamdwcjVOZmxxMkJBZC9vdQpTQW14WDIyVi9XTmJZZDNDYVA2dVAwY2F3QXdWMm8xY3lucjNwVk9reG8xaDZ6UjBPWkdvNEJpc2tlWUJKUHNkCjdjeVhwRGVseDh2b2QvUjc1NUQ5TmcwOWUybFlSQWlmSE9NZXkvbjdYb0JLNWNRUk9KUWtmZmxvYWFBRFZsNlAKdVBSNXJhUWd0c0hIZUUwVy9hTitqVTQrby92VFJ4TnZzdUtERVpXY1pyYnBOOUJRZjVGc09vRTAyV25XRi9uUQpVOXNwVjlmanJVU0I5MFhqTG1GdDRFUW1ucm5JWjRjMU42TnJqQ0szTk1NdFlidFE2VXo2M3FDVzRtZmRoK3FFCi9DcmVHTTR1T1JLMnBjVjYwYlFHOVhTOFVDWXc4bWN1SVFuTlRpc05NaXMwbCtkelV1Ui9qYVJZS1EydEdaMTAKWlVJPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    server: https://192.168.64.11:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: system:kube-scheduler
  name: system:kube-scheduler@kubernetes
current-context: system:kube-scheduler@kubernetes
kind: Config
preferences: {}
users:
- name: system:kube-scheduler
  user:
    # scheduler证书
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUREVENDQWZXZ0F3SUJBZ0lJUVg2RExrcWJFZGd3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TWpBNU1UY3hNREl3TURSYUZ3MHlNekE1TVRjeE1ESXdNRFphTUNBeApIakFjQmdOVkJBTVRGWE41YzNSbGJUcHJkV0psTFhOamFHVmtkV3hsY2pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCCkJRQURnZ0VQQURDQ0FRb0NnZ0VCQU5BanA2M3llTkZtRzV6YTRsWDU0dmwycXFScWdFckNPdU01TGhSL2FRS3YKS3BCV01KREZmM1J6Q2hoYk1GMVpHQ0dLYzRkT2ZCMzM3NStqaXY3eHZ4dlpxOU84Ymw4eHl3WDdSOFAyQWgwaQpxc3ZlNVNtUkFUc0ZOa29qTVlXZ0Q2RjhRL29QT3MyWkRJZTJycXJTbzRYRlVFVEtONTBUVFhzb1NqdEt4TlNkCkNKNmZtR1dQcytCSlBRekIzdXN6eFFGbTR4UFR5YytOclI2cXo2UDJucUlEMkpUUXlYUUo5ZkszUkhsMWY5Q00Kc2lVWGFiTlA3QkhIa2NYalEyclRkcll4d3Vsb2xNWSt4ZzhpMDE2MEZMV1ZRaDRSQjlXWmYwc2MxcDdQNzFuQwpKWlFLL0NHeWRhNzUya3BuSTJ4dm1hcEpUU0RxUVF5VWFoYXZVRmcwK1RrQ0F3RUFBYU5XTUZRd0RnWURWUjBQCkFRSC9CQVFEQWdXZ01CTUdBMVVkSlFRTU1Bb0dDQ3NHQVFVRkJ3TUNNQXdHQTFVZEV3RUIvd1FDTUFBd0h3WUQKVlIwakJCZ3dGb0FVSy9kSHkwRk1xYlRha3hndzRPb1FmakVtQkVvd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQgpBQ3ovaVd0eWo3VWU1elhoUDh4UHBaNGZYdHNuTGxXbzdWRUVnVFA0N2JaL2t2T1BiM2hXZ2RhL0xPc3Z1QWdoCkZHdHhFSWk5UEljYnZXWnhFWkdMOUZnV1dzSk0vK3NmRG84QnlmUGUraXFhWUdxQ2YrWTNvcGlqYVVwYndzaGcKeWVTZDkzSlZzWWVVN2Z6VElTNTJuS0tVaWdvN3dNNUhzbmx0YklOL21lOGZkWW9hWURneVF0bU1hd3BKYjdiNgpFbXM2VEFxVWtqNjV0MXdnUGNRUWtsUGxEVW5qcVhMS1kvd2V2SHpUcmJGOXRCVUlsRE1nZXA4TEZSTzBidWhsClFyeUZRYTJUTEpMdnZHOU1iVjM3ZTd0TjNlSzBDcEY0LzBFRCtUdExBVCs3MmRKRG9rYkpCbkdGbHFhZ0JxazcKd3ZxYkc3TGRESzBDcGFTdDJaSFZncDA9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    # scheduler私钥
    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFcFFJQkFBS0NBUUVBMENPbnJmSjQwV1libk5yaVZmbmkrWGFxcEdxQVNzSTY0emt1Rkg5cEFxOHFrRll3CmtNVi9kSE1LR0Zzd1hWa1lJWXB6aDA1OEhmZnZuNk9LL3ZHL0c5bXIwN3h1WHpITEJmdEh3L1lDSFNLcXk5N2wKS1pFQk93VTJTaU14aGFBUG9YeEQrZzg2elprTWg3YXVxdEtqaGNWUVJNbzNuUk5OZXloS08wckUxSjBJbnArWQpaWSt6NEVrOURNSGU2elBGQVdiakU5UEp6NDJ0SHFyUG8vYWVvZ1BZbE5ESmRBbjE4cmRFZVhWLzBJeXlKUmRwCnMwL3NFY2VSeGVORGF0TjJ0akhDNldpVXhqN0dEeUxUWHJRVXRaVkNIaEVIMVpsL1N4elducy92V2NJbGxBcjgKSWJKMXJ2bmFTbWNqYkcrWnFrbE5JT3BCREpScUZxOVFXRFQ1T1FJREFRQUJBb0lCQVFDTFhYUm5LcFh2VC9scApPNzZWWnU2dHJ1RnZtY2d4Um9CN3FNdkwrY3ZzZWpGNzE5cEk5WlR6K2h0bVY1aTR5SEU1OUNTTEV1aFVnTEU0CktSOW11YVFIRitiUHJib1JqNXVyYzZlSDlPOVJadWNKLzBOZVk3TjVPM0l3amdRWXZ5WDRNT2FyUnd0T293NGEKeVIySFQrY2lLUTRvSVdhL2pDOHpLYlVhb21QTkgrdG9XOEFkbjJoa1ZLNCtMdDZkT3F6bHB0SWRNdGRHVTRRLwpvaTF0QzVYV0lvTHN4L1Y4ZldvSXlHZk10U291NlRCa0pSMnBieEV0ZWh5aEg5K2FScEtRMlZmeERzMHBGbFJVClRYMi9rU0t4VThrd24wNUJCdklPZWtNVjhnZUFJUXg2VnJIUTEzNHg5emVSYzZ2ZkRjYTlaZjI3V0ZpZzU0cXQKaUdGMTJJOEJBb0dCQU9Cc3BTUThMUUFYQzNyWTlld1FzNEs4WHN3aC9XdWJodnhadWkvQ2VsVjRvSUdxK1ZDYgpJQ21YcmFIaHJPa3I0ZzN4dXRJdHBPMXAwUUdIK2t6SUxQZDVmdzh1N25CYy8yK1N5QWFjWHJXOWdJSDR1REMvClBrMnZ2VURSWU9EQmRUTmlvMUt5YU5ja1p3RzEzSkdueTd4MzFIekhYU016TnozUU1HQXhBbldKQW9HQkFPMXMKY3lvZlZMQjVXTGdkenU1UWNSb1Ntd3VMbHBFRlRlSVg2dldrZ1NKblFuUXhGRWhGc24yVEVDcGwzUnROMCsvegpiLzhPeFRKZExYaUdwS3NjR1JTRU5hcTMrZFR1aExHYlFHNCt0SnpPRUNPS1Rlb0ZvU1dPdjBNeHUvQThHWHo0CnZXNE1qMWJTeWNTMDBZWThld3BHS0tFUWp0VDNNbmpHSDBUcTFDb3hBb0dCQUxkSW81b3pOd0V5ME9KVVhJdWQKbkMxeVQrMWcrUW12N0E4ZDdJdml4V3dXWnVkZlRkd0J4TU9USjIvazBnVmdIRzhNODJtQmM0ZWRldDlJUVNnQgo5NDlvLzFiVUdsRlQ4aDBhQUJnK0RxOVlnNklpRWJObURLai9sSTFpTWo5OFg0NUd5V0haYVB3RHM4aFcwVHQzCmtWRnJmL01rRXJHVHUxTFZPeHprQ2NFWkFvR0FlMmlnbitkekxOdVdTdlZyaHlJVzkvZHQwZDEzb04vQjhPQi8KeDdqL1NuT2o3aU5JcUp4WnY3MytiQnRRaDQyM3VRU3ZWVU5IS3Z1VjFBMGdjTFNGTU0zYjIyWVBuU2R4bjZQVQpKTG5CUmJReVhWYlpVdWdrTUJKM3hpU0d6TU5nZUQ0T3NMSWttM3VyVnV5cDcvMWw4eHd1cURHa0hIeDFKcVBNCnd4VFF2VEVDZ1lFQXdvKzlRUGdGL0txVVF5akpIemZQS0VEbTZ2R0o3YnUxMTBlM2IvNCtsbmVqTktLc0pCT2QKOWVSKzdkU1ozVUlDaDZIUHNGbzBxMnJRQ2R5OVpZZ3EwV2VTUnZYcTRoZ2xpWlhnTGpaQjVzY3BzenkyTm9zWQp2VHFvYVFHRGFqT2pia0V3RUc5ZjQzZ2VTRTRCeDJ6eWg4YlQ2Wm1waGsxT0lsNFY2ekNmSHBNPQotLS0tLUVORCBSU0EgUFJJVkFURSBLRVktLS0tLQo=
```

对文件的证书进行解密

```shell
[root@master kubernetes]# echo LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUREVENDQWZXZ0F3SUJBZ0lJUVg2RExrcWJFZGd3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TWpBNU1UY3hNREl3TURSYUZ3MHlNekE1TVRjeE1ESXdNRFphTUNBeApIakFjQmdOVkJBTVRGWE41YzNSbGJUcHJkV0psTFhOamFHVmtkV3hsY2pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCCkJRQURnZ0VQQURDQ0FRb0NnZ0VCQU5BanA2M3llTkZtRzV6YTRsWDU0dmwycXFScWdFckNPdU01TGhSL2FRS3YKS3BCV01KREZmM1J6Q2hoYk1GMVpHQ0dLYzRkT2ZCMzM3NStqaXY3eHZ4dlpxOU84Ymw4eHl3WDdSOFAyQWgwaQpxc3ZlNVNtUkFUc0ZOa29qTVlXZ0Q2RjhRL29QT3MyWkRJZTJycXJTbzRYRlVFVEtONTBUVFhzb1NqdEt4TlNkCkNKNmZtR1dQcytCSlBRekIzdXN6eFFGbTR4UFR5YytOclI2cXo2UDJucUlEMkpUUXlYUUo5ZkszUkhsMWY5Q00Kc2lVWGFiTlA3QkhIa2NYalEyclRkcll4d3Vsb2xNWSt4ZzhpMDE2MEZMV1ZRaDRSQjlXWmYwc2MxcDdQNzFuQwpKWlFLL0NHeWRhNzUya3BuSTJ4dm1hcEpUU0RxUVF5VWFoYXZVRmcwK1RrQ0F3RUFBYU5XTUZRd0RnWURWUjBQCkFRSC9CQVFEQWdXZ01CTUdBMVVkSlFRTU1Bb0dDQ3NHQVFVRkJ3TUNNQXdHQTFVZEV3RUIvd1FDTUFBd0h3WUQKVlIwakJCZ3dGb0FVSy9kSHkwRk1xYlRha3hndzRPb1FmakVtQkVvd0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQgpBQ3ovaVd0eWo3VWU1elhoUDh4UHBaNGZYdHNuTGxXbzdWRUVnVFA0N2JaL2t2T1BiM2hXZ2RhL0xPc3Z1QWdoCkZHdHhFSWk5UEljYnZXWnhFWkdMOUZnV1dzSk0vK3NmRG84QnlmUGUraXFhWUdxQ2YrWTNvcGlqYVVwYndzaGcKeWVTZDkzSlZzWWVVN2Z6VElTNTJuS0tVaWdvN3dNNUhzbmx0YklOL21lOGZkWW9hWURneVF0bU1hd3BKYjdiNgpFbXM2VEFxVWtqNjV0MXdnUGNRUWtsUGxEVW5qcVhMS1kvd2V2SHpUcmJGOXRCVUlsRE1nZXA4TEZSTzBidWhsClFyeUZRYTJUTEpMdnZHOU1iVjM3ZTd0TjNlSzBDcEY0LzBFRCtUdExBVCs3MmRKRG9rYkpCbkdGbHFhZ0JxazcKd3ZxYkc3TGRESzBDcGFTdDJaSFZncDA9Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K | base64 -d > scheduler.crt
[root@master kubernetes]# cat scheduler.crt
-----BEGIN CERTIFICATE-----
MIIDDTCCAfWgAwIBAgIIQX6DLkqbEdgwDQYJKoZIhvcNAQELBQAwFTETMBEGA1UE
AxMKa3ViZXJuZXRlczAeFw0yMjA5MTcxMDIwMDRaFw0yMzA5MTcxMDIwMDZaMCAx
HjAcBgNVBAMTFXN5c3RlbTprdWJlLXNjaGVkdWxlcjCCASIwDQYJKoZIhvcNAQEB
BQADggEPADCCAQoCggEBANAjp63yeNFmG5za4lX54vl2qqRqgErCOuM5LhR/aQKv
KpBWMJDFf3RzChhbMF1ZGCGKc4dOfB3375+jiv7xvxvZq9O8bl8xywX7R8P2Ah0i
qsve5SmRATsFNkojMYWgD6F8Q/oPOs2ZDIe2rqrSo4XFUETKN50TTXsoSjtKxNSd
CJ6fmGWPs+BJPQzB3uszxQFm4xPTyc+NrR6qz6P2nqID2JTQyXQJ9fK3RHl1f9CM
siUXabNP7BHHkcXjQ2rTdrYxwulolMY+xg8i0160FLWVQh4RB9WZf0sc1p7P71nC
JZQK/CGyda752kpnI2xvmapJTSDqQQyUahavUFg0+TkCAwEAAaNWMFQwDgYDVR0P
AQH/BAQDAgWgMBMGA1UdJQQMMAoGCCsGAQUFBwMCMAwGA1UdEwEB/wQCMAAwHwYD
VR0jBBgwFoAUK/dHy0FMqbTakxgw4OoQfjEmBEowDQYJKoZIhvcNAQELBQADggEB
ACz/iWtyj7Ue5zXhP8xPpZ4fXtsnLlWo7VEEgTP47bZ/kvOPb3hWgda/LOsvuAgh
FGtxEIi9PIcbvWZxEZGL9FgWWsJM/+sfDo8ByfPe+iqaYGqCf+Y3opijaUpbwshg
yeSd93JVsYeU7fzTIS52nKKUigo7wM5HsnltbIN/me8fdYoaYDgyQtmMawpJb7b6
Ems6TAqUkj65t1wgPcQQklPlDUnjqXLKY/wevHzTrbF9tBUIlDMgep8LFRO0buhl
QryFQa2TLJLvvG9MbV37e7tN3eK0CpF4/0ED+TtLAT+72dJDokbJBnGFlqagBqk7
wvqbG7LdDK0CpaSt2ZHVgp0=
-----END CERTIFICATE-----
[root@master kubernetes]# openssl x509 -in scheduler.crt -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 4719353694374269400 (0x417e832e4a9b11d8)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = kubernetes
        Validity
            Not Before: Sep 17 10:20:04 2022 GMT
            Not After : Sep 17 10:20:06 2023 GMT
        Subject: CN = system:kube-scheduler
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:d0:23:a7:ad:f2:78:d1:66:1b:9c:da:e2:55:f9:
                    e2:f9:76:aa:a4:6a:80:4a:c2:3a:e3:39:2e:14:7f:
                    69:02:af:2a:90:56:30:90:c5:7f:74:73:0a:18:5b:
                    30:5d:59:18:21:8a:73:87:4e:7c:1d:f7:ef:9f:a3:
                    8a:fe:f1:bf:1b:d9:ab:d3:bc:6e:5f:31:cb:05:fb:
                    47:c3:f6:02:1d:22:aa:cb:de:e5:29:91:01:3b:05:
                    36:4a:23:31:85:a0:0f:a1:7c:43:fa:0f:3a:cd:99:
                    0c:87:b6:ae:aa:d2:a3:85:c5:50:44:ca:37:9d:13:
                    4d:7b:28:4a:3b:4a:c4:d4:9d:08:9e:9f:98:65:8f:
                    b3:e0:49:3d:0c:c1:de:eb:33:c5:01:66:e3:13:d3:
                    c9:cf:8d:ad:1e:aa:cf:a3:f6:9e:a2:03:d8:94:d0:
                    c9:74:09:f5:f2:b7:44:79:75:7f:d0:8c:b2:25:17:
                    69:b3:4f:ec:11:c7:91:c5:e3:43:6a:d3:76:b6:31:
                    c2:e9:68:94:c6:3e:c6:0f:22:d3:5e:b4:14:b5:95:
                    42:1e:11:07:d5:99:7f:4b:1c:d6:9e:cf:ef:59:c2:
                    25:94:0a:fc:21:b2:75:ae:f9:da:4a:67:23:6c:6f:
                    99:aa:49:4d:20:ea:41:0c:94:6a:16:af:50:58:34:
                    f9:39
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier:
                keyid:2B:F7:47:CB:41:4C:A9:B4:DA:93:18:30:E0:EA:10:7E:31:26:04:4A

    Signature Algorithm: sha256WithRSAEncryption
         2c:ff:89:6b:72:8f:b5:1e:e7:35:e1:3f:cc:4f:a5:9e:1f:5e:
         db:27:2e:55:a8:ed:51:04:81:33:f8:ed:b6:7f:92:f3:8f:6f:
         78:56:81:d6:bf:2c:eb:2f:b8:08:21:14:6b:71:10:88:bd:3c:
         87:1b:bd:66:71:11:91:8b:f4:58:16:5a:c2:4c:ff:eb:1f:0e:
         8f:01:c9:f3:de:fa:2a:9a:60:6a:82:7f:e6:37:a2:98:a3:69:
         4a:5b:c2:c8:60:c9:e4:9d:f7:72:55:b1:87:94:ed:fc:d3:21:
         2e:76:9c:a2:94:8a:0a:3b:c0:ce:47:b2:79:6d:6c:83:7f:99:
         ef:1f:75:8a:1a:60:38:32:42:d9:8c:6b:0a:49:6f:b6:fa:12:
         6b:3a:4c:0a:94:92:3e:b9:b7:5c:20:3d:c4:10:92:53:e5:0d:
         49:e3:a9:72:ca:63:fc:1e:bc:7c:d3:ad:b1:7d:b4:15:08:94:
         33:20:7a:9f:0b:15:13:b4:6e:e8:65:42:bc:85:41:ad:93:2c:
         92:ef:bc:6f:4c:6d:5d:fb:7b:bb:4d:dd:e2:b4:0a:91:78:ff:
         41:03:f9:3b:4b:01:3f:bb:d9:d2:43:a2:46:c9:06:71:85:96:
         a6:a0:06:a9:3b:c2:fa:9b:1b:b2:dd:0c:ad:02:a5:a4:ad:d9:
         91:d5:82:9d
```

## scheduler证书创建

```shell
[root@master etcd]# cat xiaowangc.cnf
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
basicConstraints = critical, CA:FALSE
authorityKeyIdentifier = keyid,issuer
================================================================
[root@master pki]# openssl req -new -newkey rsa:2048 -keyout scheduler.key -out scheduler.csr -nodes -subj '/CN=system:kube-scheduler'
Generating a RSA private key
..................+++++
......+++++
writing new private key to 'scheduler.key'
-----
[root@master pki]# openssl x509 -req -sha256 -days 36500 -extfile xiaowangc.cnf -extensions v3_req -in scheduler.csr -CA ca.crt -CAkey ca.pem -out scheduler.crt -CAcreateserial
Signature ok
subject=CN = system:kube-scheduler
Getting CA Private Key
[root@master pki]# openssl x509 -in controller-manager.crt -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            19:39:ff:4c:dd:c2:d6:76:f3:cc:7e:f9:b8:8c:fb:4e:b5:17:5b:21
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = kubernetes
        Validity
            Not Before: Sep 17 21:55:00 2022 GMT
            Not After : Aug 24 21:55:00 2122 GMT
        Subject: CN = system:kube-controller-manager
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:a2:08:62:a6:6e:21:0e:1a:e2:73:1a:9b:d7:8b:
                    2c:c0:fe:72:85:77:a3:ca:62:80:5f:bf:f3:6c:14:
                    05:c2:1d:30:68:d7:c9:b0:d1:7f:cf:78:f5:41:8f:
                    a1:60:be:26:58:43:74:c4:af:45:c7:e2:1e:f8:df:
                    53:87:b4:46:20:ab:2e:d7:13:bd:35:f2:55:5b:bd:
                    3a:16:f4:d6:98:c5:a4:7a:57:56:40:ba:98:28:e0:
                    d6:78:11:bd:b5:58:18:8c:4c:ea:8a:88:3e:1b:9a:
                    8f:79:39:32:05:26:61:e1:5d:9c:f1:bb:91:49:8c:
                    39:76:e1:ac:43:a3:dd:5b:82:8b:72:ae:52:83:50:
                    12:20:10:13:3b:66:89:38:9b:de:4a:42:29:81:8a:
                    43:79:31:14:5c:cd:c7:bd:f0:ed:89:99:09:94:d0:
                    e6:43:18:3f:18:14:79:fc:be:85:f7:13:e9:a3:f8:
                    45:67:60:5a:e3:e6:a9:72:79:c4:ca:90:bb:05:89:
                    d3:52:13:f7:6d:b1:10:b7:8a:5a:3e:56:cd:d2:b3:
                    46:bd:fb:10:d3:ba:a0:05:ea:5d:22:c0:40:4e:ed:
                    95:15:7e:80:5b:9a:e7:89:bf:aa:18:1f:b6:ca:1f:
                    c1:a1:79:2c:4f:2c:c6:62:cd:5d:93:35:c7:bd:b6:
                    c8:43
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier:
                keyid:33:AC:40:D4:C2:3E:E9:64:2B:F5:00:C7:EB:E9:78:45:62:DD:3E:15

    Signature Algorithm: sha256WithRSAEncryption
         31:91:9f:f1:f1:99:6c:81:cb:65:8c:df:1f:db:0d:61:b2:b7:
         fb:34:51:7a:61:17:09:42:8e:19:a4:32:2b:de:23:d3:96:32:
         9f:8f:9f:96:0a:65:1f:ae:3b:cc:db:e6:b6:20:99:c9:5e:58:
         c6:da:ea:e3:9a:64:d2:ee:6c:37:f7:ff:66:1d:87:6e:e5:fc:
         fd:87:db:8e:e4:af:f3:2a:e0:46:db:a7:59:94:74:80:ce:07:
         1e:e6:a5:a4:72:26:c2:de:2b:e1:6d:5b:eb:c0:70:0c:3e:ca:
         39:fe:60:ad:c5:44:7c:fe:6f:ae:b9:5d:08:5b:02:05:88:29:
         d4:24:8c:1a:1b:88:fe:58:4a:d5:ee:6f:4b:37:ac:e0:77:23:
         8d:5a:71:cf:f4:f8:5d:b4:36:df:29:aa:11:42:35:0b:39:b7:
         74:e4:81:c6:f3:29:d6:8f:75:3b:50:53:59:43:1c:75:6e:14:
         5e:64:eb:36:1c:1b:f4:6b:b3:9b:c3:42:98:60:eb:2e:ea:ed:
         f3:65:3a:15:9e:7a:c6:99:99:01:aa:1e:08:73:10:3f:c9:06:
         b3:45:b0:b5:3f:db:08:18:60:bd:3d:5d:fa:29:48:ba:21:34:
         f8:16:51:b1:3e:89:2c:27:a4:55:6d:5f:a4:d1:e7:cd:2d:bd:
         74:eb:17:e7
```

## admin证书详细信息

通常当我们通过kubeadm初始化集群成功之后会得到提示信息，也就是为KUBECONFIG配置环境变量，而这个环境变量指向的文件即是admin.conf，此文件通常用于连接kubernetes集群，里面包含集群地址，CA证书，client证书，client私钥等信息

```shell
[root@master kubernetes]# cat admin.conf
apiVersion: v1
clusters:
- cluster:
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUMvakNDQWVhZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeU1Ea3hOekV3TWpBd05Gb1hEVE15TURreE5ERXdNakF3TkZvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBS1NRCkVScnRRUHBPNzE0VGVueEQ5ZUZ0d25tNFFWWG56L1liUE5MNE5VdXdmcUNPTVg1MGJNTWxiblkya3poZmlSSmQKSWxVK3o4RVYrZGJ6WDJUd0JUWGRxN1pOeDFxdmx2bFpuZDlUY21Zd3l6eUpCRUROVjdmMG9lYWxUSUIwMGVRYQovYjFWeStPL1I0NUhuY3VXUDhMc2lwV3J5U3I1WjRpcnkvVmIrbnB4T2xVeXpTL3BtdVhBTmdGUGVpL0w3MUlpCkxha0NlNmZNRCtMMHpGektCdGVVeVpuWWZMOWxyVm0xeG1QUjVFdkdZN2NaNTl3YmtqbW94VGE1bjdVTzR6SjgKZndiak5oNHVLVzdqOHpvajVTWTJBMEZIZ0RSbnY5NlFxVk5SSkIraGMrRDBrTE1EdmRHcUM0QVpaUzJDbUNLUQpBTUZGUUlGSDIyMCtBRngvNGM4Q0F3RUFBYU5aTUZjd0RnWURWUjBQQVFIL0JBUURBZ0trTUE4R0ExVWRFd0VCCi93UUZNQU1CQWY4d0hRWURWUjBPQkJZRUZDdjNSOHRCVEttMDJwTVlNT0RxRUg0eEpnUktNQlVHQTFVZEVRUU8KTUF5Q0NtdDFZbVZ5Ym1WMFpYTXdEUVlKS29aSWh2Y05BUUVMQlFBRGdnRUJBR3hwamdwcjVOZmxxMkJBZC9vdQpTQW14WDIyVi9XTmJZZDNDYVA2dVAwY2F3QXdWMm8xY3lucjNwVk9reG8xaDZ6UjBPWkdvNEJpc2tlWUJKUHNkCjdjeVhwRGVseDh2b2QvUjc1NUQ5TmcwOWUybFlSQWlmSE9NZXkvbjdYb0JLNWNRUk9KUWtmZmxvYWFBRFZsNlAKdVBSNXJhUWd0c0hIZUUwVy9hTitqVTQrby92VFJ4TnZzdUtERVpXY1pyYnBOOUJRZjVGc09vRTAyV25XRi9uUQpVOXNwVjlmanJVU0I5MFhqTG1GdDRFUW1ucm5JWjRjMU42TnJqQ0szTk1NdFlidFE2VXo2M3FDVzRtZmRoK3FFCi9DcmVHTTR1T1JLMnBjVjYwYlFHOVhTOFVDWXc4bWN1SVFuTlRpc05NaXMwbCtkelV1Ui9qYVJZS1EydEdaMTAKWlVJPQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    server: https://192.168.64.11:6443
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURJVENDQWdtZ0F3SUJBZ0lJS2NpSGVBWHNnNHd3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TWpBNU1UY3hNREl3TURSYUZ3MHlNekE1TVRjeE1ESXdNRFZhTURReApGekFWQmdOVkJBb1REbk41YzNSbGJUcHRZWE4wWlhKek1Sa3dGd1lEVlFRREV4QnJkV0psY201bGRHVnpMV0ZrCmJXbHVNSUlCSWpBTkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQTNmV0NHbFo2cWc1bEtOWXYKMXdyb0FpZWgwbXFiMFpibGc0eVVEOXJQQ3FSd3Z4Q29oUkJvWnkxZFdCL2NLZ0IwR1pxQjUvZzhPNE8rMG5XKwpaVTZjU0U2S0txVi9zYW1sMGhiaktPZno3R2FrYldvK2dzVFMvSzlCbk8zMVlvRUYwNTZGcUF3T3FlV2RWb3loCllPZWRQV1JVZWdtVU5GVkxYMWJhWkdsblZCYkNFelRLV081b3VyeWxUbEpqcHFrZHJkZDdtcTNzRU45M2VyZ1IKR1l4YnZSOXdRNk1PQjY5MWt0ZWw2WmowU202UDNNK0Jxb3RxNWZFbGdwd29TWHAwNms3Rzd4SElPayt0K3VlYwp2eHR0Qlp3TExqTzZDUmNSeS9UREE0U1NyWERDdjB6UGpWOEJxeUhOY29SYkVDNVFVNm9COFdOYmhQN0ZnRWdrCnBWdWtSUUlEQVFBQm8xWXdWREFPQmdOVkhROEJBZjhFQkFNQ0JhQXdFd1lEVlIwbEJBd3dDZ1lJS3dZQkJRVUgKQXdJd0RBWURWUjBUQVFIL0JBSXdBREFmQmdOVkhTTUVHREFXZ0JRcjkwZkxRVXlwdE5xVEdERGc2aEIrTVNZRQpTakFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBSWVqM1VLMzhpNlBtME5HeXRQRUNqMTc4bnRMaTFnQ3BTOVlsCkJRL29jUmtWSnpwVUFoVUxtV3NVRzNTSU1JeVEzUUpmQytnUXdnS1A0SWhGSksweFg0T3RNNld5aE55MWZFRmEKM3l3aXRHQ3pqN2NwL1BNc3U2NUJnTm9pRVB5Mkhjc3dGODJna2xaVXJidVdrYm9yYXNrVHV0TkptbkgwSEpzZwp3UDJYaVhOaVYwRVFXVHErZVJPdWIyaUl6L3Rlb1NHYStPUHFrWTMwN2JpTk9xTm1DeldlWGczV0VYaG9IZ2NQCmJ3L1hPcHoyZmlUWHV2NVM1c0MzRjZNR1RGcmM0d0RZK0szdTlBZVpleXpySUVvdXRCMitPS3ROZkFSb0dtNncKeTZIQ2pIazBVSjgzclVwYXVXMlBwVHFQYjZDT2xLcW1JZXJmNWhrcFVHWjEzNHBHSlE9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg==
    client-key-data: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFb3dJQkFBS0NBUUVBM2ZXQ0dsWjZxZzVsS05ZdjF3cm9BaWVoMG1xYjBaYmxnNHlVRDlyUENxUnd2eENvCmhSQm9aeTFkV0IvY0tnQjBHWnFCNS9nOE80TyswblcrWlU2Y1NFNktLcVYvc2FtbDBoYmpLT2Z6N0dha2JXbysKZ3NUUy9LOUJuTzMxWW9FRjA1NkZxQXdPcWVXZFZveWhZT2VkUFdSVWVnbVVORlZMWDFiYVpHbG5WQmJDRXpUSwpXTzVvdXJ5bFRsSmpwcWtkcmRkN21xM3NFTjkzZXJnUkdZeGJ2Ujl3UTZNT0I2OTFrdGVsNlpqMFNtNlAzTStCCnFvdHE1ZkVsZ3B3b1NYcDA2azdHN3hISU9rK3QrdWVjdnh0dEJad0xMak82Q1JjUnkvVERBNFNTclhEQ3YwelAKalY4QnF5SE5jb1JiRUM1UVU2b0I4V05iaFA3RmdFZ2twVnVrUlFJREFRQUJBb0lCQUdHdGpsRGE1K1o0cVVuOApZRmRKWkdxMldEK0tUUUpDWHNTeWsrSWFUKzBHQ3R2Nmo3N25ScHJKV3YvU0hZaWFaSDEwQW1FOFcvMXc4QVFjCmJ1cVVXckJ6WjloMnRxaFAyVHFJZWZWaGhuWHRnY1RvOFpPSTNMVDR4MjR4UmtEUU9PazFKT3FjUzhPMjJiUGgKOVk3NHZyanFzMFoxZXJSQktRZE82Sk14MDVnc0RjNkEvdlJwdll4YjhCajlBZmtsT1FmL050NmRDT21jcCt3OQphRGUvaU9PYTEwdW5qYUxUQkR6L0g5N0FHYmtwakhQRmtQUlZzeGR5S1lEMStoMlNJQjhMTmRId2dpb1NZQVJZCnppakE0NHM5K01GODNrVDJkRlo5ay9jdDcvYUErOXdJYUpYNUY1MGpObm0wTVdnZFd2ZnE5WkdVK2RQcGhNQnMKcmFYeVFrRUNnWUVBNVpsY05rSlZjNXVySU9ONlFWUkl4MTdQYmhsTUpmcm51YWQ5RFFxWFEySVdUSlRxK25legpDbmhGR3gvVXFIUW9KVzRGZkNYblRMQmVVQkd6dEhIcnFITzIxU0J6UUtkWDZuOXRiNUVxSWFTN0h3bWRjSTJOClQ0WkxYN0ZtQ2x0WmswTFFXNlA5R0Q3SkdHV3Z1MzIvSDY5Um9vbSt2aTk1RUNLUmFyZ3JURkVDZ1lFQTkzdEEKRGNLanhPVlM5M2pWRW5Wa01sM241M2FiWk12ZEhldWNWTDMvMGlTcGhETE8wdHd1enUwUGg2TmdrNEtxejBGWgorRjFKYnpadzhkWElTTWRKRmx0SFFyakJEcXBlcGIvVnVMNmtqbjJZK3YwaXJRN1F1eENwalhWZ2FTaytGajMzCjQ2dE9DRjBpVi9jeGRZWEFsYUl3WFBOQXRXOGdrUWs4RXRXYS83VUNnWUJPa080Ryt5ZjJpWHhEb3RQQTZ6Q0UKV0tNdWo2V0pFWlNkNlB4WHJCb2F5c1BLck9MRGxwWkRyT2dvNGZtSk0wWlJtSlp6NXh5QkY1RU9ZU0JYVE94UgpGbGVvRXBTZHVTWFNib3hxTXdoeHZzYnhWZjd6OXR3MkxFUTZtSi9NUjNvZGRDMk1UazliTHBEdHNrNHlJRk40CmFpdkxMTXVDbFFnZVIxWHZhTm9ZSVFLQmdRQ0JjOFlBcktTUHRNa2VTK1ZnbjJsRzgxbi8rRW0yZ3ZEcDJybk8KbGdnLyt3OTA2RUxKaDRVd2xrNCtUQmFUY3BFNGtsMm1qZDJBd0FCNmI3SXhaNVR5amRLTHN5ckJLaHNTSm5OOApETFQxRi91eXBrRENOM0sxdHpTSm16RlFNTk9hUE5YekVFTmtHcHVCV2Z0VUZ4K3k1Y0RZamlGMkJtZ0psY1FICnNoWSsxUUtCZ0Y0bFYydERUYUtDcEtIS2hXQTRKZm82WVkzL0k3MGgwdFFDTW8rOEZpZmlRdk9tdkV1MVNzOEUKQldPa2FmQmJvUll2akVCV3FuTllINlVIN3BwdTNMTk9HRjdISUZWZXBNNFdSejNyQW9Ybzk0VjIyUjF1K3MxYwo1aGFwZkRuOW1kTEZyaVpQYXlRVmVndW1TWGo3OHpXRDZOKzhhQVFqSDZJREFCaGUwT3BRCi0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg==
```

**对证书部分进行解密**

```shell
[root@master kubernetes]# echo LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURJVENDQWdtZ0F3SUJBZ0lJS2NpSGVBWHNnNHd3RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TWpBNU1UY3hNREl3TURSYUZ3MHlNekE1TVRjeE1ESXdNRFZhTURReApGekFWQmdOVkJBb1REbk41YzNSbGJUcHRZWE4wWlhKek1Sa3dGd1lEVlFRREV4QnJkV0psY201bGRHVnpMV0ZrCmJXbHVNSUlCSWpBTkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQTNmV0NHbFo2cWc1bEtOWXYKMXdyb0FpZWgwbXFiMFpibGc0eVVEOXJQQ3FSd3Z4Q29oUkJvWnkxZFdCL2NLZ0IwR1pxQjUvZzhPNE8rMG5XKwpaVTZjU0U2S0txVi9zYW1sMGhiaktPZno3R2FrYldvK2dzVFMvSzlCbk8zMVlvRUYwNTZGcUF3T3FlV2RWb3loCllPZWRQV1JVZWdtVU5GVkxYMWJhWkdsblZCYkNFelRLV081b3VyeWxUbEpqcHFrZHJkZDdtcTNzRU45M2VyZ1IKR1l4YnZSOXdRNk1PQjY5MWt0ZWw2WmowU202UDNNK0Jxb3RxNWZFbGdwd29TWHAwNms3Rzd4SElPayt0K3VlYwp2eHR0Qlp3TExqTzZDUmNSeS9UREE0U1NyWERDdjB6UGpWOEJxeUhOY29SYkVDNVFVNm9COFdOYmhQN0ZnRWdrCnBWdWtSUUlEQVFBQm8xWXdWREFPQmdOVkhROEJBZjhFQkFNQ0JhQXdFd1lEVlIwbEJBd3dDZ1lJS3dZQkJRVUgKQXdJd0RBWURWUjBUQVFIL0JBSXdBREFmQmdOVkhTTUVHREFXZ0JRcjkwZkxRVXlwdE5xVEdERGc2aEIrTVNZRQpTakFOQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBSWVqM1VLMzhpNlBtME5HeXRQRUNqMTc4bnRMaTFnQ3BTOVlsCkJRL29jUmtWSnpwVUFoVUxtV3NVRzNTSU1JeVEzUUpmQytnUXdnS1A0SWhGSksweFg0T3RNNld5aE55MWZFRmEKM3l3aXRHQ3pqN2NwL1BNc3U2NUJnTm9pRVB5Mkhjc3dGODJna2xaVXJidVdrYm9yYXNrVHV0TkptbkgwSEpzZwp3UDJYaVhOaVYwRVFXVHErZVJPdWIyaUl6L3Rlb1NHYStPUHFrWTMwN2JpTk9xTm1DeldlWGczV0VYaG9IZ2NQCmJ3L1hPcHoyZmlUWHV2NVM1c0MzRjZNR1RGcmM0d0RZK0szdTlBZVpleXpySUVvdXRCMitPS3ROZkFSb0dtNncKeTZIQ2pIazBVSjgzclVwYXVXMlBwVHFQYjZDT2xLcW1JZXJmNWhrcFVHWjEzNHBHSlE9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCg== | base64 -d > admin.crt
[root@master kubernetes]# cat admin.crt
-----BEGIN CERTIFICATE-----
MIIDITCCAgmgAwIBAgIIKciHeAXsg4wwDQYJKoZIhvcNAQELBQAwFTETMBEGA1UE
AxMKa3ViZXJuZXRlczAeFw0yMjA5MTcxMDIwMDRaFw0yMzA5MTcxMDIwMDVaMDQx
FzAVBgNVBAoTDnN5c3RlbTptYXN0ZXJzMRkwFwYDVQQDExBrdWJlcm5ldGVzLWFk
bWluMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3fWCGlZ6qg5lKNYv
1wroAieh0mqb0Zblg4yUD9rPCqRwvxCohRBoZy1dWB/cKgB0GZqB5/g8O4O+0nW+
ZU6cSE6KKqV/saml0hbjKOfz7GakbWo+gsTS/K9BnO31YoEF056FqAwOqeWdVoyh
YOedPWRUegmUNFVLX1baZGlnVBbCEzTKWO5ourylTlJjpqkdrdd7mq3sEN93ergR
GYxbvR9wQ6MOB691ktel6Zj0Sm6P3M+Bqotq5fElgpwoSXp06k7G7xHIOk+t+uec
vxttBZwLLjO6CRcRy/TDA4SSrXDCv0zPjV8BqyHNcoRbEC5QU6oB8WNbhP7FgEgk
pVukRQIDAQABo1YwVDAOBgNVHQ8BAf8EBAMCBaAwEwYDVR0lBAwwCgYIKwYBBQUH
AwIwDAYDVR0TAQH/BAIwADAfBgNVHSMEGDAWgBQr90fLQUyptNqTGDDg6hB+MSYE
SjANBgkqhkiG9w0BAQsFAAOCAQEAIej3UK38i6Pm0NGytPECj178ntLi1gCpS9Yl
BQ/ocRkVJzpUAhULmWsUG3SIMIyQ3QJfC+gQwgKP4IhFJK0xX4OtM6WyhNy1fEFa
3ywitGCzj7cp/PMsu65BgNoiEPy2HcswF82gklZUrbuWkboraskTutNJmnH0HJsg
wP2XiXNiV0EQWTq+eROub2iIz/teoSGa+OPqkY307biNOqNmCzWeXg3WEXhoHgcP
bw/XOpz2fiTXuv5S5sC3F6MGTFrc4wDY+K3u9AeZeyzrIEoutB2+OKtNfARoGm6w
y6HCjHk0UJ83rUpauW2PpTqPb6COlKqmIerf5hkpUGZ134pGJQ==
-----END CERTIFICATE-----
[root@master kubernetes]# openssl x509 -in admin.crt -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 3010805300462388108 (0x29c8877805ec838c)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = kubernetes
        Validity
            Not Before: Sep 17 10:20:04 2022 GMT
            Not After : Sep 17 10:20:05 2023 GMT
        Subject: O = system:masters, CN = kubernetes-admin
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:dd:f5:82:1a:56:7a:aa:0e:65:28:d6:2f:d7:0a:
                    e8:02:27:a1:d2:6a:9b:d1:96:e5:83:8c:94:0f:da:
                    cf:0a:a4:70:bf:10:a8:85:10:68:67:2d:5d:58:1f:
                    dc:2a:00:74:19:9a:81:e7:f8:3c:3b:83:be:d2:75:
                    be:65:4e:9c:48:4e:8a:2a:a5:7f:b1:a9:a5:d2:16:
                    e3:28:e7:f3:ec:66:a4:6d:6a:3e:82:c4:d2:fc:af:
                    41:9c:ed:f5:62:81:05:d3:9e:85:a8:0c:0e:a9:e5:
                    9d:56:8c:a1:60:e7:9d:3d:64:54:7a:09:94:34:55:
                    4b:5f:56:da:64:69:67:54:16:c2:13:34:ca:58:ee:
                    68:ba:bc:a5:4e:52:63:a6:a9:1d:ad:d7:7b:9a:ad:
                    ec:10:df:77:7a:b8:11:19:8c:5b:bd:1f:70:43:a3:
                    0e:07:af:75:92:d7:a5:e9:98:f4:4a:6e:8f:dc:cf:
                    81:aa:8b:6a:e5:f1:25:82:9c:28:49:7a:74:ea:4e:
                    c6:ef:11:c8:3a:4f:ad:fa:e7:9c:bf:1b:6d:05:9c:
                    0b:2e:33:ba:09:17:11:cb:f4:c3:03:84:92:ad:70:
                    c2:bf:4c:cf:8d:5f:01:ab:21:cd:72:84:5b:10:2e:
                    50:53:aa:01:f1:63:5b:84:fe:c5:80:48:24:a5:5b:
                    a4:45
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier:
                keyid:2B:F7:47:CB:41:4C:A9:B4:DA:93:18:30:E0:EA:10:7E:31:26:04:4A

    Signature Algorithm: sha256WithRSAEncryption
         21:e8:f7:50:ad:fc:8b:a3:e6:d0:d1:b2:b4:f1:02:8f:5e:fc:
         9e:d2:e2:d6:00:a9:4b:d6:25:05:0f:e8:71:19:15:27:3a:54:
         02:15:0b:99:6b:14:1b:74:88:30:8c:90:dd:02:5f:0b:e8:10:
         c2:02:8f:e0:88:45:24:ad:31:5f:83:ad:33:a5:b2:84:dc:b5:
         7c:41:5a:df:2c:22:b4:60:b3:8f:b7:29:fc:f3:2c:bb:ae:41:
         80:da:22:10:fc:b6:1d:cb:30:17:cd:a0:92:56:54:ad:bb:96:
         91:ba:2b:6a:c9:13:ba:d3:49:9a:71:f4:1c:9b:20:c0:fd:97:
         89:73:62:57:41:10:59:3a:be:79:13:ae:6f:68:88:cf:fb:5e:
         a1:21:9a:f8:e3:ea:91:8d:f4:ed:b8:8d:3a:a3:66:0b:35:9e:
         5e:0d:d6:11:78:68:1e:07:0f:6f:0f:d7:3a:9c:f6:7e:24:d7:
         ba:fe:52:e6:c0:b7:17:a3:06:4c:5a:dc:e3:00:d8:f8:ad:ee:
         f4:07:99:7b:2c:eb:20:4a:2e:b4:1d:be:38:ab:4d:7c:04:68:
         1a:6e:b0:cb:a1:c2:8c:79:34:50:9f:37:ad:4a:5a:b9:6d:8f:
         a5:3a:8f:6f:a0:8e:94:aa:a6:21:ea:df:e6:19:29:50:66:75:
         df:8a:46:25
```

## admin证书创建

```shell
[root@master etcd]# cat xiaowangc.cnf
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = clientAuth
basicConstraints = critical, CA:FALSE
authorityKeyIdentifier = keyid,issuer
================================================================
[root@master pki]# openssl req -new -newkey rsa:2048 -keyout admin.key -out admin.csr -nodes -subj '/CN=kubernetes-admin/O=system:masters'
[root@master pki]# openssl x509 -req -sha256 -days 36500 -extfile xiaowangc.cnf -extensions v3_req -in admin.csr -CA ca.crt -CAkey ca.pem -out admin.crt -CAcreateserial
Signature ok
subject=CN = kubernetes-admin, O = system:masters
Getting CA Private Key
[root@master pki]# openssl x509 -in admin.crt -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number:
            19:39:ff:4c:dd:c2:d6:76:f3:cc:7e:f9:b8:8c:fb:4e:b5:17:5b:23
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: CN = kubernetes
        Validity
            Not Before: Sep 17 22:28:12 2022 GMT
            Not After : Aug 24 22:28:12 2122 GMT
        Subject: CN = kubernetes-admin, O = system:masters
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:b7:de:2f:2b:1c:be:e3:7f:dd:e5:04:b3:18:8a:
                    e1:d6:7c:b8:4f:ed:87:c2:21:ca:12:bd:7e:35:ef:
                    69:75:6e:38:69:07:18:9e:e6:c4:12:99:03:72:4d:
                    20:96:ab:d4:ac:8e:4d:b0:2b:3a:69:36:aa:82:a2:
                    a3:04:fb:1a:60:b7:5e:26:26:08:5b:c1:b5:58:b2:
                    55:4b:ed:a1:fc:6b:8f:84:d0:04:4f:d6:47:3e:b1:
                    99:eb:ed:91:f0:f0:f4:d8:9f:5c:af:13:36:68:3b:
                    f8:a3:31:fd:de:b6:c2:81:98:65:ca:db:a1:46:80:
                    b7:18:bd:5c:02:de:21:a1:3f:19:cc:da:a7:c2:09:
                    6b:dd:a7:40:95:2f:7f:b7:ff:ba:89:43:03:02:46:
                    6e:12:95:51:37:f4:4c:4c:ac:b0:50:65:59:1d:e5:
                    31:a1:ce:f8:6b:08:74:91:2e:89:5e:5f:b6:db:b8:
                    60:07:b2:c9:00:8e:bb:04:cd:6c:a0:e8:9c:e7:21:
                    5d:6a:45:04:cb:47:70:95:30:a7:ba:da:13:b1:2b:
                    5f:cd:5e:d4:39:4d:37:63:ad:45:87:46:57:4e:3a:
                    df:8a:c1:83:e3:b1:88:b5:9b:f9:68:fb:ef:b1:47:
                    32:06:9a:9e:41:35:0a:cf:1c:57:51:1d:15:f1:f6:
                    10:3d
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: critical
                Digital Signature, Key Encipherment
            X509v3 Extended Key Usage:
                TLS Web Client Authentication
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Authority Key Identifier:
                keyid:33:AC:40:D4:C2:3E:E9:64:2B:F5:00:C7:EB:E9:78:45:62:DD:3E:15

    Signature Algorithm: sha256WithRSAEncryption
         82:7b:b4:e6:22:a1:bb:3c:79:4d:8c:7c:5d:2f:b2:9e:d2:ac:
         e4:67:15:91:03:b3:66:47:6c:ec:82:fa:6b:6e:29:3a:60:0d:
         3b:3d:82:7a:df:11:a7:3a:a5:44:66:1f:a6:21:d6:7d:22:32:
         8b:5c:69:cb:3d:2e:9f:4e:ba:bb:7b:b0:ea:29:c7:32:5b:35:
         7c:9c:e2:b5:69:c5:50:ab:6c:1b:99:2b:4d:1d:1f:b7:0c:1f:
         39:e3:fd:ee:a8:8b:b6:38:9f:af:c2:cd:16:f5:d2:be:8e:c3:
         97:59:7e:0e:d8:9f:ca:22:2b:02:c0:06:fa:e1:96:1d:90:55:
         55:3c:c4:90:b3:22:32:89:8c:22:59:77:9d:87:31:4a:c6:5a:
         57:35:c6:c3:5a:f4:6a:2f:60:b3:3b:60:06:35:c7:e4:5f:80:
         3d:9e:58:28:6b:8e:3a:1b:a9:0e:ac:79:09:8f:c5:fd:ff:4f:
         22:78:db:ad:36:69:15:94:86:f1:e4:3f:84:ec:99:93:4a:95:
         dc:3e:ea:9d:94:e6:11:73:24:9a:88:12:2d:73:28:97:15:00:
         31:5d:ed:11:42:80:00:20:b5:6c:ce:32:14:57:dc:c6:aa:5d:
         90:cb:12:8b:5b:fa:14:3f:48:34:35:0d:5f:a8:84:f5:db:5b:
         a8:22:0e:12
```



# kubeconfig文件

```shell
[root@master kubernetes]# tree
.
├── admin.conf							# 用于kubectl与apiserver进行认证/控制集群
├── controller-manager.conf				# 用于cm组件与apiserver进行认证
├── kubelet.conf						# 用于kubelet组件与apiserver进行认证
└── scheduler.conf						# 用于scheduler与apiserver进行认证
```

**kubeconfig文件格式**

```shell
apiVersion: v1
kind: Config
clusters:				# 集群配置
- cluster:
    certificate-authority: */ca.crt			# ca证书信息
    server: https://******					# 集群地址
  name: demo								# 集群名称
contexts:
- context:
    cluster: demo				# 集群名称
    user: demo					# 对应证书CN值
  name: demo
current-context: demo
preferences: {}
users:
- name: demo					# 对应证书CN值
  user:
    client-certificate: */client.crt			# 客户端证书
    client-key: */client.key					# 客户端私钥
```

