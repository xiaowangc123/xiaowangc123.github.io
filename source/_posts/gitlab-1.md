---
title: gitlab更改分支克隆中的URL地址
abbrlink: d46e7f9b
date: 2022-10-21 18:33:31
cover: img/fengmian/gitlab.jpeg
categories: Gitlab
tags:
  - Gitlab
  - Git
---

**可在web界面配置**

```shell

[root@xiaowangc ~]# vi /opt/gitlab/embedded/service/gitlab-rails/config/gitlab.yml
...
production: &base
  #
  # 1. GitLab app settings
  # ==========================

  ## GitLab settings
  gitlab:
    ## Web server settings (note: host is the FQDN, do not include http://)
    host: gitlab.local.com
    port: 80
    https: false

[root@xiaowangc ~]# vi /etc/gitlab/gitlab.rb
external_url 'http://gitlab.local.com'

[root@xiaowangc ~]# gitlab-cli restart
...
```
