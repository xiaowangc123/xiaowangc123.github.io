---
title: mysqldump备份命令
tags:
  - mysql
cover: img/fengmian/mysql.jpg
categories:
  - mysql
abbrlink: fa9c6891
date: 2022-08-25 04:48:14
---
# MySQL备份命令

- 备份数据库表结构及数据

  ```shell
  root@xiaowangc:~# mysqldump -hlocalhost -uroot -p123456 test > /root/test.sql
  ```

- 备份其中一张数据表

  ```shell
  root@xiaowangc:~# mysqldump -hlocalhost -uroot -p123456 test t1 > /root/test_t1.sql
  ```

- 备份多张表

  ```shell
  root@xiaowangc:~# mysqldump -hlocalhost -uroot -p123456 test t1 t2 t3 > /root/test_t.sql
  ```

- 备份整个数据库包含数据库本身

  ```shell
  root@xiaowangc:~# mysqldump -hlocalhost -uroot -p123456 -B test > /root/test.sql
  ```

- 备份所有数据库

  ```shell
  root@xiaowangc:~# mysqldump -hlocalhost -uroot -p123456 --all-databases > all.sql
  ```

- 备份表结构不含数据

  ```shell
  root@xiaowangc:~# mysqldump -hlocalhost -uroot -p123456 -d test > /root/test.sql
  ```

- 备份数据包含表结构

  ```shell
  root@xiaowangc:~# mysqldump -hlocalhost -uroot -p123456 -t test > /root/test.sql
  ```

- 导入备份数据

  ```shell
  root@xiaowangc:~# ls
  test.sql
  root@xiaowangc:~# mysql -uroot -p123456
  mysql: [Warning] Using a password on the command line interface can be insecure.
  Welcome to the MySQL monitor.  Commands end with ; or \g.
  Your MySQL connection id is 2
  Server version: 5.7.39 MySQL Community Server (GPL)
  
  Copyright (c) 2000, 2022, Oracle and/or its affiliates.
  
  Oracle is a registered trademark of Oracle Corporation and/or its
  affiliates. Other names may be trademarks of their respective
  owners.
  
  Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.
  
  mysql> source test.sql
  ```

  