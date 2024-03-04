---
title: OpenResty
tags:
  - openresty
  - nginx
categories:
  - nginx
cover: img/fengmian/openresty.png
abbrlink: da147c79
date: 2022-07-18 00:27:20
---
# OpenResty简介

OpenResty是一个基于Nginx与Lua(LuaJIT)的高性能Web平台，其内部集成了大量精良的Lua库、第三方模块以及大多数的依赖项。用于方便地搭建能够处理超高并发、扩展性极高的动态Web应用、Web访问和动态网关

OpenResty通过汇聚各种设计精良的Nginx模块(例如Nginx C Module)，从而将Nginx有效变成一个强大的通用Web应用平台。这样Web开发人员和工程师可以使用Lua语言调动Nginx支持各种C以及Lua模块，快速构造出足以胜任10k乃至1000k以上单机并发连接的高性能web应用程序

高性能服务端的要素：

- 缓存
- 异步非阻塞

互联网公司内部的技术架构基本相似，主要体现在如下几个方面：

- 数据量过大，如何定制存储
- 访问量过高，如何集群化部署，流量负载均衡
- 响应速度过慢，如何提高处理速度，引入多级缓存
- 如果机器过多，如何保证某服务器宕机，不影响业务的稳定

OpenResty通用可以充当网关，作为客户端与服务段之间的桥梁，将通用的、非业务逻辑抽离、前置到网关系统，减少重复性开发工作，是整个网站的唯一流量入口；为了提高系统的扩展性，网关通常采用组件式架构，高内聚低耦合

**常用组件功能：**

- 黑名单
- 日志
- 参数校验
- 鉴权
- 限流
- 负载均衡
- 路由转发
- 监控
- 灰度分流
- 多协议支持
- 熔断、降级、重试、数据聚合等

**OpenResty的特点**：

- 支持跨网络的gRPC请求转发，底层采用HTTP/2协议
- 支持SSL/TLS证书加密
- 支持高并发请求
- 性能开销低，延迟少



# OpenResty架构

## Nginx架构

![image-20220717220727969](20220717220727969.png)

Nginx采用Master、Worker进程模型，分工明确，职责单一，也是具备高性能的原因之一

1. master进程

   master管理进程，处理指令通过进程间通信，将管理指令发送给其他worker进程，从而实现对worker的控制

2. worker进程

   worker工作进程，不断接收客户端的连接请求，处理请求。数量通常设置为与CPU核数一致，nginx也会将每个进程与每个CPU进行绑定，充分利用其多核特性。

   多个worker进程会竞争一个共享锁，只有抢到锁的进程才能处理客户端的请求。如果请求是accept事件，则会将其添加到accept队列中；如果是read或者write事件，则会将其添加到read-write队列。

   nginx采用基于Epoll机制的事件驱动，异步非阻塞，大大提高并发处理能力

## OpenResty架构

![image-20220717221435075](20220717221435075.png)

OpenResty是一个基于Nginx的Web平台，内部嵌入LuaJIT虚拟机运行Lua脚本，使用Lua编程语言对Nginx核心以及各种Nginx C模块进行脚本编程；另外Lua支持协程，协程是用户态的操作，上下文切换不用涉及内核态，系统资源开销小；协程占用内存很小，初始2KB

- 每接到一个客户端请求，通过抢占锁，由一个worker进程来跟进处理

- worker内部会创建一个lua协程，绑定请求，也就是一个请求对应一个lua协程

- lua协程将请求通过网络发出，并添加一个event事件到nginx，然后当前协程就处于yield，让出CPU控制权

- 当服务端响应数据后，网络流程会创建一个新的event事件，将之前的协程唤醒，返回结果

  ps：不同的lua协程之间数据隔离，保证请求之间互不影响。一个worker中同一时刻，只会有一个协程在运行



# 软件安装

## 二进制安装

Openresty给常见Linux发布提供官方预编译安装包，包含Ubuntu、Debian、RHEL、Centos、Alpine等提供二进制包仓库

下面演示在RHEL8.4版本中进行安装

```shell
[root@localhost ~]# wget https://openresty.org/package/rhel/openresty.repo		# 下载存储库
--2022-07-17 11:37:51--  https://openresty.org/package/rhel/openresty.repo
Resolving openresty.org (openresty.org)... 182.92.62.145, 182.92.4.22
Connecting to openresty.org (openresty.org)|182.92.62.145|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 263 [text/plain]
Saving to: ‘openresty.repo’

openresty.repo                100%[=================================================>]     263  --.-KB/s    in 0s

2022-07-17 11:37:52 (544 MB/s) - ‘openresty.repo’ saved [263/263]

[root@localhost ~]# mv openresty.repo /etc/yum.repos.d/			# 将存储库配置文件移动至仓库目录
mv: overwrite '/etc/yum.repos.d/openresty.repo'? y			
[root@localhost ~]# dnf search openresty --show			# 可查询openresty所有版本软件包信息
Updating Subscription Management repositories.
Unable to read consumer identity

This system is not registered to Red Hat Subscription Management. You can use subscription-manager to register.

Last metadata expiration check: 0:06:38 ago on Sun 17 Jul 2022 11:33:29 AM EDT.
Module yaml error: Unexpected key in data: static_context [line 9 col 3]
Module yaml error: Unexpected key in data: static_context [line 9 col 3]
===================================================================================================== Name & Summary Matched: openresty =====================================================================================================
openresty-1.17.8.1-1.el8.x86_64 : OpenResty, scalable web platform by extending NGINX with Lua
openresty-1.17.8.2-1.el8.x86_64 : OpenResty, scalable web platform by extending NGINX with Lua
openresty-1.19.3.1-1.el8.x86_64 : OpenResty, scalable web platform by extending NGINX with Lua
openresty-1.19.3.2-1.el8.x86_64 : OpenResty, scalable web platform by extending NGINX with Lua
openresty-1.19.9.1-1.el8.x86_64 : OpenResty, scalable web platform by extending NGINX with Lua
openresty-1.21.4.1-1.el8.x86_64 : OpenResty, scalable web platform by extending NGINX with Lua
openresty-asan-1.17.8.1-1.el8.x86_64 : The clang AddressSanitizer (ASAN) version of OpenResty
openresty-asan-1.17.8.2-1.el8.x86_64 : The clang AddressSanitizer (ASAN) version of OpenResty
openresty-asan-1.19.3.1-1.el8.x86_64 : The clang AddressSanitizer (ASAN) version of OpenResty
openresty-asan-1.19.3.1-5.el8.x86_64 : The AddressSanitizer (ASAN) version of OpenResty
openresty-asan-1.19.3.2-1.el8.x86_64 : The AddressSanitizer (ASAN) version of OpenResty
openresty-asan-1.19.9.1-1.el8.x86_64 : The AddressSanitizer (ASAN) version of OpenResty
openresty-asan-1.21.4.1-1.el8.x86_64 : The AddressSanitizer (ASAN) version of OpenResty
openresty-asan-debuginfo-1.17.8.1-1.el8.x86_64 : Debug information for package openresty-asan
...
[root@localhost ~]# dnf -y install openresty		# 直接通过dnf软件包管理工具进行安装
Updating Subscription Management repositories.
Unable to read consumer identity

This system is not registered to Red Hat Subscription Management. You can use subscription-manager to register.

Last metadata expiration check: 0:08:02 ago on Sun 17 Jul 2022 11:33:29 AM EDT.
Module yaml error: Unexpected key in data: static_context [line 9 col 3]
Module yaml error: Unexpected key in data: static_context [line 9 col 3]
Dependencies resolved.
=============================================================================================================================================================================================================================================
 Package                                                          Architecture                                       Version                                                     Repository                                             Size
=============================================================================================================================================================================================================================================
Installing:
 openresty                                                        x86_64                                             1.21.4.1-1.el8                                              openresty                                             1.1 M
Installing dependencies:
 openresty-openssl111                                             x86_64                                             1.1.1n-1.el8                                                openresty                                             1.6 M
 openresty-pcre                                                   x86_64                                             8.45-1.el8                                                  openresty                                             167 k
 openresty-zlib                                                   x86_64                                             1.2.12-1.el8                                                openresty                                              59 k

Transaction Summary
=============================================================================================================================================================================================================================================
Install  4 Packages

Total download size: 2.9 M
Installed size: 8.2 M
Downloading Packages:
(1/4): openresty-pcre-8.45-1.el8.x86_64.rpm                                                                                                                                                                   94 kB/s | 167 kB     00:01
(2/4): openresty-zlib-1.2.12-1.el8.x86_64.rpm                                                                                                                                                                192 kB/s |  59 kB     00:00
(3/4): openresty-openssl111-1.1.1n-1.el8.x86_64.rpm                                                                                                                                                          560 kB/s | 1.6 MB     00:02
(4/4): openresty-1.21.4.1-1.el8.x86_64.rpm                                                                                                                                                                   223 kB/s | 1.1 MB     00:05
---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Total                                                                                                                                                                                                        578 kB/s | 2.9 MB     00:05
warning: /var/cache/dnf/openresty-d4438f2e03fc84d1/packages/openresty-1.21.4.1-1.el8.x86_64.rpm: Header V4 RSA/SHA256 Signature, key ID d5edeb74: NOKEY
Official OpenResty Open Source Repository for RHEL                                                                                                                                                           6.1 kB/s | 1.6 kB     00:00
Importing GPG key 0xD5EDEB74:
 Userid     : "OpenResty Admin <admin@openresty.com>"
 Fingerprint: E522 18E7 0878 97DC 6DEA 6D6D 97DB 7443 D5ED EB74
 From       : https://openresty.org/package/pubkey.gpg
Key imported successfully
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                                                                                                                                                                     1/1
  Installing       : openresty-zlib-1.2.12-1.el8.x86_64                                                                                                                                                                                  1/4
  Installing       : openresty-openssl111-1.1.1n-1.el8.x86_64                                                                                                                                                                            2/4
  Installing       : openresty-pcre-8.45-1.el8.x86_64                                                                                                                                                                                    3/4
  Installing       : openresty-1.21.4.1-1.el8.x86_64                                                                                                                                                                                     4/4
  Running scriptlet: openresty-1.21.4.1-1.el8.x86_64                                                                                                                                                                                     4/4
  Verifying        : openresty-1.21.4.1-1.el8.x86_64                                                                                                                                                                                     1/4
  Verifying        : openresty-openssl111-1.1.1n-1.el8.x86_64                                                                                                                                                                            2/4
  Verifying        : openresty-pcre-8.45-1.el8.x86_64                                                                                                                                                                                    3/4
  Verifying        : openresty-zlib-1.2.12-1.el8.x86_64                                                                                                                                                                                  4/4
Installed products updated.

Installed:
  openresty-1.21.4.1-1.el8.x86_64                        openresty-openssl111-1.1.1n-1.el8.x86_64                        openresty-pcre-8.45-1.el8.x86_64                        openresty-zlib-1.2.12-1.el8.x86_64

Complete!
[root@localhost ~]#
```



## 源码安装

源码安装本文就不举例子了，大致流程可安装官方提供的文件进行安装即可，需要注意的就是请确认自己的系统版本，以及需要提前安装的依赖，否则编译时会出现ERROR导致不能正常安装

文档：http://openresty.org/cn/installation.html

- 安装依赖
- 下载源码
- 安装gcc编译套件
- 正常编译流程



# 配置文件

RHEL通过DNF包管理进行安装，配置目录处于/usr/local/openresty下

```shell
[root@localhost openresty]# pwd
/usr/local/openresty
[root@localhost openresty]# tree -L 2
.
├── bin
│   └── openresty -> /usr/local/openresty/nginx/sbin/nginx
├── COPYRIGHT
├── luajit
│   ├── bin
│   ├── include
│   ├── lib
│   └── share
├── lualib
│   ├── cjson.so
│   ├── librestysignal.so
│   ├── ngx
│   ├── redis
│   ├── resty
│   └── tablepool.lua
├── nginx
│   ├── conf
│   ├── html
│   ├── logs
│   └── sbin
├── openssl111
│   ├── bin
│   └── lib
├── pcre
│   └── lib
├── site
│   └── lualib
└── zlib
    └── lib

24 directories, 5 files
[root@localhost openresty]#
```

如果有Nginx的基础，那么学习其应该是非常容易的

配置文件在conf/nginx.conf下

```shell
[root@localhost conf]# cat nginx.conf | grep -v "#"
worker_processes  1;		# 工作进程数

events {
    worker_connections  1024;	# 工作进程连接数
}

http {							# http配置块
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;

    keepalive_timeout  65;

    server {					# server配置块
        listen       80;
        server_name  localhost;

        location / {
            root   html;
            index  index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }
}
```

# 启动Openresty

```shell
[root@localhost conf]# systemctl enable --now openresty			# 启动并设置开机启动
Created symlink /etc/systemd/system/multi-user.target.wants/openresty.service → /usr/lib/systemd/system/openresty.service.
[root@localhost conf]# curl localhost			# 访问测试
<!DOCTYPE html>
<html>
<head>
<meta content="text/html;charset=utf-8" http-equiv="Content-Type">
<meta content="utf-8" http-equiv="encoding">
<title>Welcome to OpenResty!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to OpenResty!</h1>
<p>If you see this page, the OpenResty web platform is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to our
<a href="https://openresty.org/">openresty.org</a> site<br/>
Commercial support is available at
<a href="https://openresty.com/">openresty.com</a>.</p>
<p>We have articles on troubleshooting issues like <a href="https://blog.openresty.com/en/lua-cpu-flame-graph/?src=wb">high CPU usage</a> and
<a href="https://blog.openresty.com/en/how-or-alloc-mem/">large memory usage</a> on <a href="https://blog.openresty.com/">our official blog site</a>.
<p><em>Thank you for flying <a href="https://openresty.org/">OpenResty</a>.</em></p>
</body>
</html>
[root@localhost conf]#
```

