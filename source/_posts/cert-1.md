---
title: ACME证书申请
tags:
  - 证书申请
  - ACME脚本
categories: Linux
cover: img/fengmian/linux.png
abbrlink: b562763f
date: 2023-04-03 14:56:08
---
**2023-04-06: 在对证书升级时，需要注意，现acme.sh客户端申请的证书算法是采用ECC，对于某些例如Windows XP或远古系统的用户来说可能会导致一些列的问题：**
**1.时间不正确**
**2.不信任的根证书**

# ACME证书申请脚本

这是一个用纯Shell(Unix shell)语言编写的ACME协议客户端，实现了完整的ACME协议，支持ECDSA证书、SAN和通配符证书。它简单、强大、易于使用，只需要3分钟就能学会，兼容Bash、Dash和sh。它完全用Shell编写，不依赖Python，只需要一个脚本即可自动颁发、更新和安装您的证书，而且不需要root/sudoer访问权限。此外，它还支持Docker和IPv6并提供Cron作业通知以更新或报告错误等。

## 支持的CA

- ZeroSSL.com CA
- Letsencrypt.org CA
- BuyPass.com CA
- SSL.com CA
- Google.com 公共CA
- Pebble严格模式
- 任何其他符合RFC8555标准的CA

## 支持的模式

- Webroot模式
- 独立模式
- 独立tls-alpn模式
- Apache模式
- Nginx模式
- DNS模式
- DNS别名模式
- 无状态模式

# 安装

## 在线安装

```shell
curl https://get.acmesh | sh -s email=qq780312916@gmail.com
```

Or:

```shell
wget -O - https://get.acme.sh | sh -s email=qq780312916@gmail.com
```

## Git安装

克隆这个项目并启动安装：

```shell
git clone https://github.com/acmesh-official/acme.sh.git
cd ./acme.sh
./acme.sh --install -m qq780312916@gmail.com
```

# 申请证书

## DNS API集成

通过DNS提供商提供的API访问，我们可以使用该API自动颁发证书。无需手动执行操作

DNS提供商支持列表：https://github.com/acmesh-official/acme.sh/wiki/dnsapi

本人使用的DNS提供商为Cloudflare，国内阿里云也支持使用API。在Cloudflare创建API Tokens，并写入account.conf或配置为环境变量

![image-20230403141255556](image-20230403141255556.png)

配置CF_Token，这里我将其写入account.conf

```shell
root@admin:~# vi .acme.sh/account.conf
CF_Token='xxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
```

更改acme的CA，如果使用模式ZenoSSL CA可能由于OpenSSL的原因会导致申请证书失败

```shell
root@admin:~# acme.sh --set-default-ca  --server  letsencrypt
```

申请证书，使用--dns指定dns提供商为Cloudflare(cf)，-d指定需要申请证书的域名

```shell
root@admin:~# acme.sh --issue --dns dns_cf -d mc.xiaowangc.com
...
...
...
[Mon 03 Apr 2023 06:29:34 AM UTC] Your cert is in: /root/.acme.sh/mc.xiaowangc.com_ecc/mc.xiaowangc.com.cer
[Mon 03 Apr 2023 06:29:34 AM UTC] Your cert key is in: /root/.acme.sh/mc.xiaowangc.com_ecc/mc.xiaowangc.com.key
[Mon 03 Apr 2023 06:29:34 AM UTC] The intermediate CA cert is in: /root/.acme.sh/mc.xiaowangc.com_ecc/ca.cer
[Mon 03 Apr 2023 06:29:34 AM UTC] And the full chain certs is there: /root/.acme.sh/mc.xiaowangc.com_ecc/fullchain.cer
```

## 安装证书

按照Github的介绍，证书申请成功后，不要使用~/.acme.sh/文件夹中的证书文件，它们仅供内部使用。推荐使用如下命令获取或安装证书

```shell
root@admin:~# acme.sh --install-cert -d mc.xiaowangc.com \
--cert-file      /path/to/certfile/in/apache/cert.pem  \
--key-file       /path/to/keyfile/in/apache/key.pem  \
--fullchain-file /path/to/fullchain/certfile/apache/fullchain.pem \
```

# 其他

其他包括自动验证、自动部署和到期告警等请转到：

```shell
# https://github.com/acmesh-official/acme.sh
```

