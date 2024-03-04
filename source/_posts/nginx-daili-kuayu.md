---
title: Nginx WS代理和跨域小记
tags:
  - nginx
  - 跨域
  - 代理
  - WebSocket代理
cover: img/fengmian/nginx.png
categories:
  - nginx
abbrlink: 71048e2e
date: 2023-09-28 15:59:59
---
# Nginx WS代理和跨域小记

## WS代理

默认情况下Nginx会把所有请求作为普通的HTTP请求，不会尝试升级到WebSocket协议。

在客户端发送WS(WebSocket)握手时，会携带Upgrade、Connection字段；如果没有在Nginx中配置相应的参数，那么在做代理请求时，Nginx把其当作普通HTTP请求，而不是WS请求，它可能不会保存这个两个字段或者可能修改这两个字段的值，从而导致请求到达被代理服务器时，服务器无法将连接升级为WS连接

```shell
http {
    # map根据http_upgrade的值来设置connection_upgrade的值
    # 如果http_upgrade的值为'websocket'则将connection_upgrade的值设置为upgrade,否则将设置为keep-alive
    map $http_upgrade $connection_upgrade {
        default keep-alive; # 默认为keep-alive 可以支持一般http请求
        'websocket' upgrade; # 如果为websocket 则为 upgrade 可升级的。
    }
    
    server {
        ...
        location / {
            proxy_pass http://www.xiaowangc.com;
            proxy_http_version 1.1;
            # 修改HTTP请求头的Upgrade字段，当客户端发送WS握手请求时,它会发送Upgrade头部把这个参数头部传递给被代理的服务器
            proxy_set_header Upgrade $http_upgrade; 
            # 修改HTTP请求头的Upgrade字段，当客户端发送WS握手请求时,它会发送Connection头部把这个参数头部传递给被代理的服务器
            proxy_set_header Connection $connection_upgrade;
        }
    }
}
```

## 跨域

```shell
 server {
        ...
        location / {
            proxy_pass http://www.xiaowangc.com;
            # 设置HOST的变量为www.xiaowangc.com,如果不设置该值为Nginx代理服务器的域名
            proxy_set_header Host $proxy_host;

			# 设置HTTP响应头,用于定义哪些源可以访问,假如访问其的网站为www.abc.com,则设置为www.abc.com
            add_header 'Access-Control-Allow-Origin' '*'; # 在生产环境中，你可能需要将其设置为一个特定的域名
            # 设置HTTP响应头,用于定义哪些HTTP方法可以访问
            add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS';
            # 设置HTTP响应头，用于定义哪些HTTP头可以被用在请求中
            add_header 'Access-Control-Allow-Headers' 'DNT,User-Agent,X-Requested-With,If-Modified-Since,Cache-Control,Content-Type,Range';
            # 设置HTTP响应头，用于定义是否允许请求携带证书
            add_header 'Access-Control-Allow-Credentials' 'true';

            if ($request_method = 'OPTIONS') {
               add_header 'Access-Control-Max-Age' 1728000; # 增加这个值可以减少预检请求的数量
               add_header 'Content-Type' 'text/plain charset=UTF-8';
               add_header 'Content-Length' 0;
               return 204;
            }
        }
    }
```

