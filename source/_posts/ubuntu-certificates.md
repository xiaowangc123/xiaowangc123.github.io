---
title: Ubuntu 22.04安装CA证书
abbrlink: 17c76bbf
date: 2022-12-06 10:07:26
tags:
  - Ubuntu
  - Certificates
categories: Linux
cover: img/fengmian/ubuntu.jpeg
---
Ubuntu安装CA证书

```shell
[root@xiaowangc ~]# apt-get install -y ca-certificates
[root@xiaowangc ~]# sudo cp xiaowang-CA.crt /usr/local/share/ca-certificates
[root@xiaowangc ~]# sudo update-ca-certificates
```
