---
title: Gitlab配置HTTPS
cover: img/fengmian/gitlab.jpeg
categories: Gitlab
tags:
  - Gitlab
abbrlink: 426aa12e
date: 2023-02-02 05:29:26
---
# Gitlab配置HTTPS

```shell
# 配置url
external_url "https://gitlab.xiaowangc.local"
# 关闭自动续订证书
letsencrypt['enable'] = false
# 重定向80->443
nginx['redirect_http_to_https'] = true
# 证书私钥配置
nginx['ssl_certificate'] = "/mnt/gitlab/ssl/gitlab.crt"
nginx['ssl_certificate_key'] = "/mnt/gitlab/ssl/gitlab.key"
# 开启HTTP2.0,默认开启
nginx['http2_enabled'] = true
# 开启HSTS
nginx['hsts_max_age'] = 63072000
nginx['hsts_include_subdomains'] = false
```

