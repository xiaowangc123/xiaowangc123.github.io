---
title: Nginx基础
tags: nginx
cover: img/fengmian/nginx.png
categories:
  - nginx
abbrlink: a7bddb95
date: 2021-05-08 01:34:16
---


# Nginx软件包方式安装与配置

> Nginx概念请转到👉[概念](https://www.cnblogs.com/xiaowangc/p/14742769.html)；Linux安装请转发👉[安装](https://www.cnblogs.com/xiaowangc/p/14743138.html)



## Nginx安装

> 两种安装方式：1、yum安装   2、安装包安装(**此次演示本方式**)

- 准备环境

  ```shell
  #安装编译环境
  [root@localhost ~]# yum -y install gcc gcc-c++ automake autoconf libtool make wget vim
  
  #安装PCRE库
  #https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz
  #官网：https://pcre.org/
  [root@localhost ~]# wget https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz
  [root@localhost ~]# tar -zxvf pcre-8.44.tar.gz
  [root@localhost ~]#cd pcre-8.44
  [root@localhost pcre-8.44]#
  [root@localhost pcre-8.44]# ./configure
  [root@localhost pcre-8.44]#make
  [root@localhost pcre-8.44]#make install
  
  #安装zlib库
  #http://zlib.net/zlib-1.2.11.tar.gz
  #官网：http://zlib.net/
  [root@localhost ~]# wget http://zlib.net/zlib-1.2.11.tar.gz
  [root@localhost ~]#tar -zxvf zlib-1.2.11.tar.gz
  [root@localhost ~]# cd zlib-1.2.11
  [root@localhost zlib-1.2.11]#make
  [root@localhost zlib-1.2.11]#make install
  
  ```

  

- 下载👉[官网](http://nginx.org/en/download.html)

- 选择稳定版

  ![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210508031227787-1182612237.png)



- 右键复制链接地址

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210508031238524-1856243410.png)



- 下载解压编译

  ```shell
  [root@localhost ~]# wget http://nginx.org/download/nginx-1.20.0.tar.gz
  [root@localhost ~]# tar -zxvf nginx-1.20.0.tar.gz
  [root@localhost ~]# cd nginx-1.20.0
  [root@localhost nginx-1.20.0]# ./configure
  [root@localhost nginx-1.20.0]# make 
  [root@localhost nginx-1.20.0]# make install
  ```

  注意安装路径

  ![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210508031253315-859014338.png)



 
  

## 基本命令

> 可设置环境变量或者使用软连接 
>
> ln -s /usr/local/nginx/sbin/nginx /sbin/nginx
>
> 启动、停止、重载就不需要加绝对路径或者进入nginx目录
>
> 例：1、nginx 启动  2、nginx -s  stop 停止 3、nginx -s reload 重载
>
> [root@localhost ~]# whereis nginx	#可使用whereis nginx查找nginx所在的位置
> nginx: /usr/sbin/nginx /usr/local/nginx

- 启动

  ```shell
  [root@localhost ~]# /usr/local/nginx/sbin/nginx		#启动
  nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
  nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
  nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
  nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
  nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
  nginx: [emerg] still could not bind()
  [root@localhost ~]# ps -aux | grep nginx
  root       25085  0.0  0.0  32976   380 ?        Ss   00:44   0:00 nginx: master process ./nginx
  nobody     25086  0.0  0.5  66580  4484 ?        S    00:44   0:00 nginx: worker process
  root       25147  0.0  0.1  12112   976 pts/0    S+   00:51   0:00 grep --color=auto nginx
  [root@localhost ~]#
  ```

  

- 停止

  ```shell
  [root@localhost ~]# /usr/local/nginx/sbin/nginx -s stop	#停止
  [root@localhost ~]# ps -aux | grep nginx
  root       25157  0.0  0.1  12112  1080 pts/0    R+   00:51   0:00 grep --color=auto nginx
  [root@localhost ~]#
  ```

  

- 重启

  ```shell
  [root@localhost ~]# /usr/local/nginx/sbin/nginx -s reload	#重新加载
  ```

  

## Nginx配置文件详解

> Nginx配置文件结构
>
> 全局块、events块、http块、server块、location块

```shell
[root@localhost ~]# vim /usr/local/nginx/conf/nginx.conf

  1
  2 #user  nobody;
  3 worker_processes  1;	#worder进程的数量
  4
  5 #error_log  logs/error.log;		
  6 #error_log  logs/error.log  notice;
  7 #error_log  logs/error.log  info;
  8
  9 #pid        logs/nginx.pid;
 10
 11
 12 events {
 13     worker_connections  1024;	#最大连接数
 14 }
 15
 16
 17 http {
 18     include       mime.types;	#Nginx支撑的媒体类型库文件
 19     default_type  application/octet-stream;	#默认的媒体类型
 20
 21     #log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
 22     #                  '$status $body_bytes_sent "$http_referer" '
 23     #                  '"$http_user_agent" "$http_x_forwarded_for"';
 24
 25     #access_log  logs/access.log  main;
 26
 27     sendfile        on;	#高效传输
 28     #tcp_nopush     on;
 29
 30     #keepalive_timeout  0;
 31     keepalive_timeout  65;	#超时时间
 32
 33     #gzip  on;
 34
 35     server {	#第一个Server区块开始，表示一个独立的虚拟主机
 36         listen       80;	#监听端口
 37         server_name  localhost;	#监听IP或者域名
 38
 39         #charset koi8-r;
 40
 41         #access_log  logs/host.access.log  main;
 42
 43         location / {
 44             root   html;	#站点的根目录
 45             index  index.html index.htm;	#首页文件
 46         }
 47
 48         #error_page  404              /404.html;
 49
 50         # redirect server error pages to the static page /50x.html
 51         #
 52         error_page   500 502 503 504  /50x.html;
 53         location = /50x.html {
 54             root   html;
 55         }
 56
 57         # proxy the PHP scripts to Apache listening on 127.0.0.1:80
 58         #
 59         #location ~ \.php$ {
 60         #    proxy_pass   http://127.0.0.1;
 61         #}
 62
 63         # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
 64         #
 65         #location ~ \.php$ {
 66         #    root           html;
 67         #    fastcgi_pass   127.0.0.1:9000;
 68         #    fastcgi_index  index.php;
 69         #    fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
 70         #    include        fastcgi_params;
 71         #}
 72
 73         # deny access to .htaccess files, if Apache's document root
 74         # concurs with nginx's one
 75         #
 76         #location ~ /\.ht {
 77         #    deny  all;
 78         #}
 79     }
 80
 81
 82     # another virtual host using mix of IP-, name-, and port-based configuration
 83     #
 84     #server {
 85     #    listen       8000;
 86     #    listen       somename:8080;
 87     #    server_name  somename  alias  another.alias;
 88
 89     #    location / {
 90     #        root   html;
 91     #        index  index.html index.htm;
 92     #    }
 93     #}
 94
 95
 96     # HTTPS server	
 97     #
 98     #server {
 99     #    listen       443 ssl;
100     #    server_name  localhost;
101
102     #    ssl_certificate      cert.pem;
103     #    ssl_certificate_key  cert.key;
104
105     #    ssl_session_cache    shared:SSL:1m;
106     #    ssl_session_timeout  5m;
107
108     #    ssl_ciphers  HIGH:!aNULL:!MD5;
109     #    ssl_prefer_server_ciphers  on;
110
111     #    location / {
112     #        root   html;
113     #        index  index.html index.htm;
114     #    }
115     #}
116
117 }
```

```shell
全局设置

events{
	#events块
	
}

http{
	#http块
	server{
		#server块 or 虚拟机主机
	}
	
	location{
		#location块
	
	}
	
}
```



## Nginx反向代理

- 网络拓扑图

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210508031335456-997331290.png)





- 准备Tomcat环境

  > 快速部署Tomcat

  ```shell
  [root@Tomcat ~]# yum install java-1.8.0-openjdk vim wget
  [root@Tomcat ~]# java -version
  openjdk version "1.8.0_292"
  OpenJDK Runtime Environment (build 1.8.0_292-b10)
  OpenJDK 64-Bit Server VM (build 25.292-b10, mixed mode)
  [root@Tomcat ~]#
  [root@Tomcat ~]# wget https://mirrors.bfsu.edu.cn/apache/tomcat/tomcat-10/v10.0.5/bin/apache-tomcat-10.0.5.tar.gz
  [root@Tomcat ~]# tar -zxvf apache.tomcat-10.0.5.tar.gz
  [root@Tomcat ~]# apache-tomcat-10.0.5/bin/startup.sh
  
  #关闭防火墙、selinux
  [root@localhost sbin]# systemctl stop firewalld.service
  [root@localhost sbin]# setenforce 0
  ```

  **测试**

  ![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210508031358405-1964160705.png)



  

- 配置Nginx反向代理

  ```shell
  [root@localhost ~]# vim /usr/local/nginx/conf/nginx.conf	
  
  在location块添加如下配置
  proxy_pass http://192.168.204.131:8080;		#Tomcat服务器地址，注意端口号和；结尾
  ```

 ![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210508031417367-1294720935.png)



  ```shell
  #启动Nginx
  
  [root@localhost ~]# cd /usr/local/nginx/sbin/
  [root@localhost sbin]# ./nginx
  nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
  nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
  nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
  nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
  nginx: [emerg] bind() to 0.0.0.0:80 failed (98: Address already in use)
  nginx: [emerg] still could not bind()
  [root@localhost sbin]#
  
  #关闭防火墙和selinux
  [root@localhost sbin]# systemctl stop firewalld.service
  [root@localhost sbin]# setenforce 0
  ```

  

- 访问测试

  > 我们Nginx的IP地址为192.168.204.135，Tomcat的IP地址为192.168.204.131，从上面Tomcat测试即可看出。

  通过访问Nginx服务器地址能够打开Tomcat页面则反向代理成功

  ![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210508031432454-745109270.png)



  

## 负载均衡

- 网络拓扑图

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210508031445059-119842436.png)





- 搭建Tomcat服务器

  > 需要搭建两台Tomcat服务器

  - Tomcat01

  ```shell
  [root@Tomcat01 ~]# yum install java-1.8.0-openjdk wget vim
  [root@Tomcat01 ~]# java -version
  openjdk version "1.8.0_292"
  OpenJDK Runtime Environment (build 1.8.0_292-b10)
  OpenJDK 64-Bit Server VM (build 25.292-b10, mixed mode)
  [root@Tomcat01 ~]#
  [root@Tomcat01 ~]# wget https://mirrors.bfsu.edu.cn/apache/tomcat/tomcat-10/v10.0.5/bin/apache-tomcat-10.0.5.tar.gz
  [root@Tomcat01 ~]# tar -zxvf apache.tomcat-10.0.5.tar.gz
  [root@Tomcat01 ~]# apache-tomcat-10.0.5/bin/startup.sh
  
  #关闭防火墙、selinux
  [root@Tomcat01 ~]# systemctl stop firewalld.service
  [root@Tomcat01 ~]# setenforce 0
  
  #修改主页方便区分
  [root@Tomcat01 ~]# vim apache-tomcat-10.0.5/webapps/ROOT/index.jsp
  ```

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210508031501672-8203707.png)



![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210508031510179-637395018.png)



  

  - Tomcat02

  ```shell
  [root@Tomcat02 ~]# yum install java-1.8.0-openjdk wget vim
  [root@Tomcat02 ~]# java -version
  openjdk version "1.8.0_292"
  OpenJDK Runtime Environment (build 1.8.0_292-b10)
  OpenJDK 64-Bit Server VM (build 25.292-b10, mixed mode)
  [root@Tomcat02 ~]#
  [root@Tomcat02 ~]# wget https://mirrors.bfsu.edu.cn/apache/tomcat/tomcat-10/v10.0.5/bin/apache-tomcat-10.0.5.tar.gz
  [root@Tomcat02 ~]# tar -zxvf apache.tomcat-10.0.5.tar.gz
  [root@Tomcat02 ~]#apache-tomcat-10.0.5/bin/startup.sh
  
  #关闭防火墙、selinux
  [root@Tomcat02 ~]# systemctl stop firewalld.service
  [root@Tomcat02 ~]# setenforce 0
  [root@Tomcat02 ~]# vim apache-tomcat-10.0.5/webapps/ROOT/index.jsp
  ```

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210508031527365-1203091669.png)



  

- 测试Tomcat01和02服务器

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210508031536096-75766892.png)



![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210508031546910-1903805597.png)





- 配置Nginx负载均衡

  安装请参考`一、Nginx安装`

  配置Nginx文件

  ```shell
  [root@Nginx ~]# vim /usr/local/nginx/conf/nginx.conf
  
  upstream 192.168.204.135 {  #可更改为域名和proxy_pass对应
          server 192.168.204.131:8080;	# Tomcat01服务器IP地址：端口；
          server 192.168.204.132:8080;	# Tomcat02服务器IP地址：端口
      }
   server {
          listen       80;
          server_name  localhost;
  
          #charset koi8-r;
  
          #access_log  logs/host.access.log  main;
  
          location / {
             root   html;
             index  index.html index.htm;
             proxy_pass http://192.168.204.135;	#本机IP地址：可更改为域名
          }    
  ```

  ![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210508031627328-1440815567.png)



  

- 重启

  ```shell
  [root@Nginx ~]# /usr/local/nginx/sbin/nginx	#启动或重载 -s reload
  ```

  

- 测试，访问Nginx服务器

  ![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210508031642786-29743126.png)



- 刷新

 ![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210508031652444-156414122.png)





## 权重轮询

> 假如我们两台服务器Tomcat01的性能优于Toncat02我们可以通过配置权重，让大部分请求交给Tomcat01处理

```shell
upstream 192.168.204.135 {
        server 192.168.204.131:8080 weigth=8;	#权重为8
        server 192.168.204.132:8080 weigth=2;	#权重为2	默认为1
		#每个10个请求，有8个转发给192.168.204.131
		#2个转发给192.168.204.132
    }

    #gzip  on;

    server {
        listen       80;
        server_name  localhost;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        location / {
           root   html;
           index  index.html index.htm;
           proxy_pass http://192.168.204.135;
        }
```

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210508031702290-1811097978.png)
