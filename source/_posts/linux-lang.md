---
title: CentOS8安装中文语言包
abbrlink: 6dcdc915
date: 2022-11-23 18:04:21
tags:
  - Linux
  - LANG
categories: Linux
cover: img/fengmian/linux.png
---
# CentOS8安装中文语言包
[root@gateway ~]# dnf -y install langpacks-zh_CN
[root@gateway ~]# vi /etc/locale.conf
LANG="zh_CN.UTF-8"
[root@gateway ~]# LANG="zh_CN.UTF-8"