---
title: Linux开启IP路由
abbrlink: ccf900ab
date: 2022-11-23 15:33:03
tags:
  - Linux
  - Route
categories: Linux
cover: img/fengmian/linux.png
---

# Linux开启IP路由

```shell
# 永久生效
[root@xiaowangc ~]# vi /etc/sysctl.conf
net.ipv4.ip_forward = 1
[root@xiaowangc ~]# sysctl -p

# 临时生效
[root@xiaowangc ~]# echo "1" > /proc/sys/net/ipv4/ip_forward

# 查看是否开启IP路由
[root@xiaowangc ~]# cat /proc/sys/net/ipv4/ip_forward

# 开启Nat
[root@xiaowangc ~]# iptables -t nat -A POSTROUTING -s $(内部网段) -j SNAT --to $(本机出口地址)
[root@xiaowangc ~]# iptables -t nat -A POSTROUTING -s 192.168.64.0/24 -j SNAT --to 172.16.1.1
```