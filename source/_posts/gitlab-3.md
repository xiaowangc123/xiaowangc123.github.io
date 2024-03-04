---
title: Gitlab字符集错误
abbrlink: 3a601eb7
date: 2022-11-29 17:59:18
cover: img/fengmian/gitlab.jpeg
categories: Gitlab
tags:
  - Gitlab
---

`错误`：
  ================================================================================
    Error executing action `run` on resource 'execute[/opt/gitlab/embedded/bin/initdb -D /var/opt/gitlab/postgresql/data -E UTF8]'
    ================================================================================

    Mixlib::ShellOut::ShellCommandFailed
    ------------------------------------
    Expected process to exit with [0], but received '1'
    ---- Begin output of /opt/gitlab/embedded/bin/initdb -D /var/opt/gitlab/postgresql/data -E UTF8 ----
    STDOUT: The files belonging to this database system will be owned by user "gitlab-psql".
    This user must also own the server process.
    STDERR: initdb: error: invalid locale settings; check LANG and LC_* environment variables
    ---- End output of /opt/gitlab/embedded/bin/initdb -D /var/opt/gitlab/postgresql/data -E UTF8 ----
    Ran /opt/gitlab/embedded/bin/initdb -D /var/opt/gitlab/postgresql/data -E UTF8 returned 1

    Resource Declaration:
    ---------------------
    # In /opt/gitlab/embedded/cookbooks/cache/cookbooks/postgresql/recipes/enable.rb

     49: execute "/opt/gitlab/embedded/bin/initdb -D #{postgresql_data_dir} -E UTF8" do
     50:   user postgresql_username
     51:   not_if { pg_helper.bootstrapped? || pg_helper.delegated? }
     52: end


`解决方法`：
```shell
[root@xiaowangc ~]# vim /etc/profile
[root@xiaowangc ~]#export LC_CTYPE=en_US.UTF-8
[root@xiaowangc ~]# export LC_ALL=en_US.UTF-8
[root@xiaowangc ~]# source /etc/profile
[root@xiaowangc ~]# gitlab-ctl reconfigure
```