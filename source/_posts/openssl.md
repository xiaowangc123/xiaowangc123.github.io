---
title: OpenSSL
tags:
  - OpenSSL
  - 证书
categories: 安全
cover: img/fengmian/openssl.jpg
abbrlink: 2e203ce7
date: 2022-08-29 05:50:11
---
# 概念

## 加密算法

- 对称加密(使用相同的密码进行加密解密)

对称加密是指双方对约定一个相同的密码，通过这个密码对文件或信息进行加密解密

常见加密算法：DES、3DES、IDEA等

- 非对称加密(使用不相同的密码进行加密解密)

非对称加密是通过生成密钥对(公钥/私钥)，通过私钥对文件进行加密，可以使用公钥进行解密；通过使用公钥进行加密，只能使用私钥进行解密。一般私钥是私有的，公钥是公开的，一旦私钥泄露对安全的影响极大

常见加密算法：RSA、ECC等

## 摘要算法

> MD5是摘要算法,不是加密算法

消息摘要算法是指对信息、文件等数据进行计算，得到一定长度的摘要；比如我在网上下载了某个文件，我想确认文件是不是完整的，或者有没有被人修改的，只需要将文件下载到本地使用支持的相关算法进行摘要运算得出摘要信息，与发布者公示的摘要信息进行比较确认是否一致，如果一致则文件没有被修改也未损坏，如果不一样说明文件并不是原来的文件

消息摘要算法有如下几类：

- 消息摘要

  生成的消息摘要都是128位的包括：MD5、MD4、MD2，MD5相对4、2安全性最高，至今未被破解；通过MD5算法是不可逆的，无法通过加密后的信息破解出原始数据。但是MD5不足之处就是可以通过穷举进行推举出明文，因为相同的信息用MD5进行摘要运算后的信息都是一样的。在使用MD5摘要算法对密码进行加密时，应使用复杂密码

- 安全散列

  SHA1、SHA256、SHA384、SHA512

## 数字签名

数字签名的三个特征：

- 不可否认
- 报文的完整性
- 报文鉴别

数字签名是指对文件进行摘要运算得出摘要信息，通过使用私钥对摘要进行加密的过程称之为数字签名的过程，而通过加密摘要信息称之为该文件的数字签名

## 证书颁发机构

- CA机构

  CA机构全称为Certificate Authority证书认证中心，CA是否则签发证书、认证证书、管理已颁发的证书的机关。先前说的私钥公钥，每个人都可以去生成一对密钥对，而我们怎么确定这个密钥对一定是某某的呢？这时候我们就需要把我们的公钥以及相关信息发送给权威的CA机构，通过CA机构来鉴别

  而CA机构的证书在安装好操作系统时就已经被内置在系统中

  ![image-20220829020633073](openssl.png)

# 生成密钥对

- 生成密钥对(公私钥)

  ```shell
  [root@xiaowangc media]# openssl genrsa -out ca-key.pem 2048	  # 生成2048位的私钥
  Generating RSA private key, 2048 bit long modulus (2 primes)
  ......................................+++++
  ....................................................................................................................+++++
  e is 65537 (0x010001)
  [root@xiaowangc media]# cat ca-key.pem
  -----BEGIN RSA PRIVATE KEY-----
  MIIEpAIBAAKCAQEA2CjcI+aU1cwHczvbMJglT/QstPJzKwwRqftmUTm4UjWJCBap
  MSjWS+9EfkoqqkwUodjy6d1KyOqlXKnsa6JuinkbL0S2iFnh0RN19EIoqne+a1Y5
  3KhrV0J765bl71ugdU87G5WxgnXrQeZcHINeEUkkMTfAL//FWnZlZdJ2JMUrc6Og
  CX+NzX4ITLNZagILWIC3IofGkxLGLRestN4Lveh4S7bLZHQekqsxLgRG0tWIGa3b
  V50gFbRdeFWYP82Z59AK6t62/fcSefSqwCRBnHOkTKkGom13umV/vIkW8rdexVZE
  tCYvZmbN4qNJ5GGSjiBWHj8qtDqnw8Bjz3zF4QIDAQABAoIBAF68kbb+UQ7ezAka
  G7fRhtDi8FEhzY35TSiVsUM6K+mD4xnzbJXKExnWtMsw0EAw9f31KomK3kLubCkP
  pDmMSCxSZbKyx9k8o3bRs6mo8U+9CWzbrqJiAiGNVuhrCz17h/jCD+LIGbNW4RPR
  1V79yFWFG+KiT4356FH8f/Y/Zl44ad6OVVGr66tgpAv2fOUNiInOcKpi+AmSl4lj
  3Us/Sc+ZqgaLkdWFWvQM+RtjFvDt9E7GHrHieh+CnTmKj9CRzHBDTut/36WdTqlS
  JnyBQsTUD4T2yTgTlr0ewhRcITXrUY2od0cm+dpr33UCE8nDMMGAWvGCL6ZD0CHr
  w4Rk9hECgYEA6/yGJBrt8TTB9RTQTaflD1YB6nF1NMwJ1M2SQz5w6uhOnfvigpIj
  lBAp3JfpgnYcjxUoXPanrSk04UwtM5llmDMj8wg66XtSmm8iT0uL4PbrZUxONjKo
  4BYud0rIWFMrZilc0EIm0nywsfK3L+lhtM+/+1uVCGgDfW8YIgT+wg0CgYEA6n3g
  zGwxAPN/wAD4i2/hc3tQ+Z9LgAcFy7MAxEzOv62Gcbge3NohHwTPTm7wuQr53TZg
  GcNV+T0UiOhKEjcSccqiq8IHsfl+dCaWJQdPSnG5XrHd2zRSYuzihVQLgiHWSkJG
  06U8BdmXN/7Yp99TX60O2ADNivSrr8rHRzw5IiUCgYEArbTvRMpx1bhhATd18YOh
  z70eoeUsQlXi8rrza/4dfjzMCeysmjJacBXJyrAj2b15XjVTxcJmQMdxPlold7L1
  nqgeUToAq3b0oesmVTol183KDoGxnKGDv5d0UqlAeguWiZfu0vmuvAe+xO4FvAXN
  vxuhlLOgK1TtJLrPB9Ond00CgYEA4xTn389eXVdxfZTzHMVKBTWEo1g6G0+xsyQ0
  N+VRypnWusXdTW8H6CwWPhR9lhUlB66ivhBGb8lQ24xoPt+KQxxDECYkoZvFc+Hy
  QQWlKaicJTIGcUNoDVjtvMQ5KNpv1RX91PQM/nVLVfS8B0XkTaEf4NpWMpzirqim
  9ztA8OkCgYBr/MLkp/6EvoeUhH1SwCal2DThXhbIuTOoVjl1lQhLqdyJlKnKPAN2
  mTcwzk779JQhIvbFS8iZ4iYu6mBJGStnMzl+ZHWhRgHohT4M960ToikTsNOwbMon
  CCg+8ntFycNc0ml0BBQ5B37AN72iX0Fwair93PdDyH46PRIuiIZ8zg==
  -----END RSA PRIVATE KEY-----
  [root@xiaowangc media]#
  ```

- 通过私钥提取出公钥

  ```shell
  [root@xiaowangc media]# openssl rsa -in ca-key.pem -pubout -out ca-pub.pem
  writing RSA key
  [root@xiaowangc media]# ls
  ca-key.pem  ca-pub.pem
  [root@xiaowangc media]# cat ca-pub.pem
  -----BEGIN PUBLIC KEY-----
  MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2CjcI+aU1cwHczvbMJgl
  T/QstPJzKwwRqftmUTm4UjWJCBapMSjWS+9EfkoqqkwUodjy6d1KyOqlXKnsa6Ju
  inkbL0S2iFnh0RN19EIoqne+a1Y53KhrV0J765bl71ugdU87G5WxgnXrQeZcHINe
  EUkkMTfAL//FWnZlZdJ2JMUrc6OgCX+NzX4ITLNZagILWIC3IofGkxLGLRestN4L
  veh4S7bLZHQekqsxLgRG0tWIGa3bV50gFbRdeFWYP82Z59AK6t62/fcSefSqwCRB
  nHOkTKkGom13umV/vIkW8rdexVZEtCYvZmbN4qNJ5GGSjiBWHj8qtDqnw8Bjz3zF
  4QIDAQAB
  -----END PUBLIC KEY-----
  ```

# 生成摘要

## 对字符串生成摘要

- MD5

  ```shell
  [root@xiaowangc media]# echo 123456 | openssl md5
  (stdin)= f447b20a7fcbf53a5d5be013ea0b15af
  [root@xiaowangc media]#
  ```

- Sha

  ```shell
  [root@xiaowangc media]# echo 123456 | openssl sha1
  (stdin)= c4f9375f9834b4e7f0a528cc65c055702bf5f24a
  [root@xiaowangc media]# echo 123456 | openssl sha256
  (stdin)= e150a1ec81e8e93e1eae2c3a77e66ec6dbd6a3b460f89c1d08aecf422ee401a0
  [root@xiaowangc media]#
  ```

## 对文件生成摘要

- MD5

  > 更改文件名MD5值不变，当内容发生改变后MD5值才会产生变化

  ```shell
  [root@xiaowangc media]# echo xiaowangc > 1.txt
  [root@xiaowangc media]# openssl dgst -md5 1.txt
  MD5(1.txt)= 117d8e3d36b77fd390ee6f0304257ec1
  ```

  **验证更改文件数据后的MD5值**

  ```shell
  root@xiaowangc media]# echo 12345678 > 1.txt
  [root@xiaowangc media]# openssl dgst -md5 1.txt
  MD5(1.txt)= 23cdc18507b52418db7740cbb5543e54
  ```

- Sha256

  ```shell
  [root@xiaowangc media]# openssl dgst -sha256 1.txt
  SHA256(1.txt)= e7e213f38f47bbaec6aef3307831c1ce60a932e2c380a19e00d191927122a9f4
  ```

# 生成数字签名

通过上面的命令已经了解到了如何生成密钥对以及提取摘要信息，下面我们开始试着对文件进行数字签名

```shell
# 对文件进行摘要运算
[root@xiaowangc media]# ls
ca-key.pem  ca-pub.pem
[root@xiaowangc media]# echo xiaowangc.com > 1.txt
[root@xiaowangc media]# openssl dgst -md5 1.txt
MD5(1.txt)= b02eb36de574cd721a3dda12d1693ff3
[root@xiaowangc media]# openssl dgst -sha256 1.txt
SHA256(1.txt)= a84c0b84e7e54dcb092f289b174b506580e675682b0c79756d90947e07fe4fea
[root@xiaowangc media]# openssl dgst -sha512 1.txt
SHA512(1.txt)= cb7e7a147ed14a0479a792fb4d6f3c83d63da9627d8e5badfb2f98f4e180bec1813f211d639357af3044757a3946af35827be29bb0c2320e7cdfcf8a9de5eb9e
# 使用私钥对文件进行签名
# 通过-hex在命令行显示数字签名信息
[root@xiaowangc media]# openssl dgst -md5 -hex -sign ca-key.pem 1.txt
RSA-MD5(1.txt)= 00f943f79704d775c6b4112a1ebf7ff1c6cc314bf809f4482de2f2f159c83b297291c4159d307358d3bdb11214be8b5c6d1f2ec0c983910de0a1c2ba617de52eb609b55c140c34ef3cc5b65d29f7734e57dce29032e49ebf333d86ee2314aba65901a977e1426e17b7eb919cd9c74b87e4da025fa1428f494695c08349185a693b80a010596ce4985422766d1c38ed7328b35dbd4aa471e1b08292833038f2b2df30a8c89667c5036bf608fbb1b8f1eb2d16cd8c81ee583d2c2b3c23da744786f105643abd131a706a761f7ada75e4546c1349666d0fed88f86a529d04e83e98ddeb031500a0d8a2c678cbd56aa8d51d25a643a282bd876a39066f55a1fc9db4
# 通过将数字签名保存到文件中，保存不能使用-hex参数
[root@xiaowangc media]# openssl dgst -md5 -out 1.txt.sign -sign ca-key.pem 1.txt
# 因为是二进制所以显示乱码
[root@xiaowangc media]# cat 1.txt.sign
ºa}.*\4<Ŷ])sNW2䞿3=#YwBn둜K_BIF��IZi;YlT"vm8s(]Jqᰂ080Ȗg-͌X=,+
[root@xiaowangc media]#
#####################################
#   使用公钥来对文件进行验证数字签名
#####################################
[root@xiaowangc media]# ls
1.txt  1.txt.sign  ca-key.pem  ca-pub.pem
[root@xiaowangc media]# openssl dgst -md5 -verify ca-pub.pem -signature 1.txt.sign 1.txt
Verified OK 

# 生成数字签名的时候使用的是MD5算法，所有验证的时候也要指定相同算法
```

# 生成证书

```shell
# 创建CA
openssl req -new -newkey rsa:2048 -keyout ca.key -out ca.csr -nodes
openssl x509 -req -days 36500 -sha256  -signkey ca.key -in ca.csr -out ca.crt

# 通过CA签发node01
openssl req -new -newkey rsa:2048 -keyout node01.key -out node01.csr -nodes
openssl x509 -req -sha256 -days 36500 -in node01.csr -CA ca.crt -CAkey ca.key -out node01.crt -CAcreateserial

```