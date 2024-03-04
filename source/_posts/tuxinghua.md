---
title: 解决ubuntu 16.04分辨率
abbrlink: f140992e
date: 2022-10-19 17:19:53
tags:
  - Ubuntu
  - Linux
categories: Linux
cover: img/fengmian/ubuntu.jpeg
---
ubuntu安装图形化后只有800*600分辨率
```shell
sudo vim /etc/default/grub
GRUB_GFXMODE=1920x1080
GRUB_GFXPAYLOAD_LINUX=1920x1080
sudo update-grub
```

