---
title: mysql备份、恢复及二进制日志
tags:
  - mysql
cover: img/fengmian/mysql.jpg
categories:
  - mysql
abbrlink: 6e89b25
date: 2022-10-13 02:21:12
---
# 备份和恢复类型

## 物理备份与逻辑备份

物理备份由存储数据库内容的目录和文件的原始副本组成。这种类型的备份适用于在出现问题时需要快速恢复的大型重要数据库

逻辑备份保存表示为逻辑数据库结构(创建数据库、创建表语句)和内容(INSERT语句或分割文本文件)的信息。这种类型的备份适用于较小的数据量，您可以在其中编辑数据值或表结构，或者在不同的计算机体系结构上重新创建数据。

**物理备份方法具有以下特征**：

- 备份有数据库目录和文件的精确副本组成。通常这是MySQL数据目录的全部或部分副本
- 物理备份方法比逻辑备份方法快，因为它们只涉及文件复制而不进行转换
- 输出比逻辑备份更紧凑
- 备份和还原粒度的范围从整个数据目录的级别到单个文件的级别。这可能提供也可能不提供表级粒度，具体取决于存储引擎
- 除了数据库之外，备份还可以包括任何相关文件，如日志或配置文件
- 以这种方式备份表中数据很棘手，因为它们的内容不存储在磁盘上
- 备份只能移植到相同或类似硬件特征的其他计算机
- 可以在MySQL服务器未运行时执行备份。如果服务器正在运行，则必须执行适当的锁定，以便服务器在备份期间不会更改数据库内容
- 物理备份工具包括MySQL企业备份或任何其它表的MySQL备份，或表的文件系统级命令如：cp、scp、tar、rsync
- 对于恢复
  - ndb_restore还原NDB表
  - 可以使用文件系统命令将文件系统级别复制的文件复制回其原始位置

**逻辑备份方法具有以下特征**：

- 备份是通过查询MySQL服务器以获得数据库结构和内容信息来完成的
- 备份速度比物理方法慢，因为服务器必须访问数据库信息并将其转换为逻辑格式。如果输出写入客户端，则服务器还必须将其发送到备份程序
- 输出大于物理备份，尤其是在以文本格式保持时
- 备份和还原粒度在服务器级别(所有数据库)、数据库级别(特定数据库中的所有表)或表级别可用。无论存储引擎如何，都是如此
- 备份不包括日志或配置文件，或者不属于数据库的其他与数据库相关的文件
- 以逻辑格式存储的备份与机器无关，并且具有高度的可移植性
- 要还原逻辑备份，可以使用MySQL客户端处理SQL格式的转储文件

## 联机备份与脱机备份

在线备份在MySQL服务器运行时进行，以便可以从服务器获取数据库信息。脱机备份在服务器停止时进行。这种区别也可以描述为"热"与"冷"备份；"热"备份是指服务器保持运行状态，但需要从外部访问数据库文件时锁定以防止修改数据

**联机备份方法具有以下特征**：

- 备份对于客户端的干扰较小，其他客户端可以在备份期间连接到MySQL服务器，并且可以访问数据
- 必须注意施加适当的锁定，以免发生会损害备份完整性的数据修改

**脱机备份方法具有以下特征**：

- 客户端可能会受到负面影响，因为服务器在备份期间不可用。因此，此类备份通常从副本服务器获取，该副本服务器可以在不损害可用性的情况下脱机
- 备份过程更简单，因为客户端活动不会干扰

## 快照备份

某些文件系统实现允许拍摄快照。它们提供文件系统在给定的时间点的逻辑副本，而不需要整个文件系统的物理副本

## 完整备份与增量备份

完整备份包括由MySQL服务器在给定时间点管理的所有数据

增量备份包括在给定时间跨度(从一个时间点到另一个时间点)内对数据所作的更改

## 完整恢复与时间点(增量)恢复

完整恢复从完整备份还原所有数据。这会将服务器实例还原到备份时的状态。如果该状态不够最新，则可以在完全恢复之后恢复自完整备份以来所作的增量备份，以使服务器处于更新状态

增量恢复是对给定时间跨度内所作更改的恢复。这也曾时间点恢复，因为它使服务器的状态在给定时间内保持最新。时间点恢复基于二进制日志，通常遵循从备份文件进行完全恢复之后，该恢复会将服务器还原到进行备份时的状态。然后，写入二进制日志文件中的数据更改作为增量恢复应用，以重做数据修改并使服务器达到所需的时间点

# 二进制日志

二进制日志包含描述数据库更改(创建、修改、删除)的"事件"。它还包含可能已进行更改的语句事件，除非使用基于行的日志记录。二进制日志还包含有关每条语句占用该更新数据多长时间的信息。二进制日志有两个重要用途：

- 对于复制，复制源服务器上的二进制日志提供要发送到副本的数据更改的记录。源将二进制日志中包含的事件发送到其副本，副本执行这些事件以进行与源上相同的数据更改
- 某些数据恢复操作需要使用二进制日志。还原备份后，将重新执行进行备份后记录的二进制日志中的事件。这些事件使数据库从备份点保持最新

# 复制实现

MySQL内建的复制功能是构建基于MySQL的`大规模`、`高性能`应用的基础，这类应用使用所谓的"`水平扩展`"的架构。通过为服务器配置一个或多个从库的方式来进行数据同步。

复制解决的基本问题是让一台服务器的数据与其他服务器保持同步。一台主库的数据可以同步到多台从库上，从库本身也可以被配置成为另一台服务器的主库

MySQL支持两种复制方式：

- 基于行的复制
- 基于语句的复制

## 优点

- 数据分布

  复制通常不会对带宽造成很大的压力，但是在基于行的复制会比传统的基于语句的复制模式的贷款压力大。可以随意停止或开始复制，并在**不同的地理位置**来分布数据备份。

- 负载均衡

  通过MySQL复制可以将读操作分布到多台服务器上，实现对读密集型应用的优化，并且实现很方便

- 备份

  **对于备份来说，复制是一项很有意义的技术补充，但复制既不是备份也不能狗取代备份**。

  **优点**：当主服务器发生故障或瘫痪可在一定程度上保证数据不会丢失，同时可以快速将备份服务器切换为主服务器

  **缺点**：当人(黑客)为对数据库进行删除加密等操作，作为备份服务器同样会被删除或进行加密

- 高可用性和故障切换

  避免**单点故障**，切换系统可**缩短宕机时间**

- 升级测试

  使用高版本的MySQL作为备库，保证升级全部实例前，查询能够在备库按照预期执行

## 复制原理

### 基于语句的复制

在早期版本只支持基于语句的复制(逻辑复制)，原理是主库会记录哪些造成数据更改的查询，当备库读取并重放这些事件时，实际上只是把主库上执行过的SQL再执行一遍。

### 基于行的复制

MySQL5.1开始支持行的复制，这种方式会将实际数据记录在二进制日志中，最大的好处是可以正确地复制每一行。一些语句可以被更加有效地复制

## 复制工作原理

![image-20221013001804788](image-20221013001804788.png)

MySQL实现复制数据的过程共有三个步骤：

1. 在主库上把数据更改记录到二进制日志（Binary Log）中，这些记录被称之为二进制日志事件
2. 备库将主库上的日志复制到自己的中继日志(Relay Log)中
3. 备库读取中继日志中的事件，将其重放到备库数据之上

# 实验章节

在实现MySQL主从架构，一定是从空数据库开始，如果是已有的数据MySQL数据库做主从这可能相对于比较麻烦，如果在数据库创建的时候就开启了二进制日志，那么在有数据的MySQL数据中是可以做主从，如果之前的MySQL数据库没有开启二进制日志并且想做主从的架构，那么从数据库需要保证与主数据库服务器原先的数据保持一致再进行复制

> 从节点可以保证主节点宕机之后还能提供读操作，或可以将从节点切换为主节点以提供读写

> 开启了二进制日志的MySQL服务器可以实现增量备份

![image-20221013004443899](image-20221013004443899.png)

根据系统下载对应的MySQL以及版本

我的下载：https://downloads.mysql.com/archives/get/p/23/file/mysql-5.7.39-1.el7.x86_64.rpm-bundle.tar

## 安装主节点

本次实验是在CentOS8.4上操作的，虽然MySQL5.7没有EL8的包但是可以在CentOS8上安装EL7的软件包

```shell
[root@master ~]# tar xf mysql-5.7.39-1.el7.x86_64.rpm-bundle.tar
[root@master ~]# ls
anaconda-ks.cfg                                   mysql-community-embedded-compat-5.7.39-1.el7.x86_64.rpm
mysql-5.7.39-1.el7.x86_64.rpm-bundle.tar          mysql-community-embedded-devel-5.7.39-1.el7.x86_64.rpm
mysql-community-client-5.7.39-1.el7.x86_64.rpm    mysql-community-libs-5.7.39-1.el7.x86_64.rpm
mysql-community-common-5.7.39-1.el7.x86_64.rpm    mysql-community-libs-compat-5.7.39-1.el7.x86_64.rpm
mysql-community-devel-5.7.39-1.el7.x86_64.rpm     mysql-community-server-5.7.39-1.el7.x86_64.rpm
mysql-community-embedded-5.7.39-1.el7.x86_64.rpm  mysql-community-test-5.7.39-1.el7.x86_64.rpm
[root@master ~]# dnf -y install *.rpm
# 使用dnf软件包管理工具安装rpm软件包可以自动解决依赖问题
```

## 配置主节点

```shell
[root@master ~]# vi /etc/my.cnf
# 在配置文件中开启这两项
log_bin = mysql-bin				# 以mysql-bin命名的二进制日志文件
server_id = 10					# 节点id
# 其余采用默认配置
```

![image-20221013005001875](image-20221013005001875.png)

## 启动主节点

```shell
[root@master ~]# systemctl enable --now mysqld
[root@master ~]# cat /var/log/mysqld.log | grep password			# 初次安装自动生成密码，通过日志查看
2022-10-12T16:51:22.192080Z 1 [Note] A temporary password is generated for root@localhost: dF4q%Xs6ylyP
[root@master ~]# mysql -uroot -pdF4q%Xs6ylyP
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.39-log

Copyright (c) 2000, 2022, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql>			# 初次登陆需要重置密码
mysql> set global validate_password_policy=0;		# 设置密码策略   如果对安全有要求可以跳过这两项操作，这里主要是为了演示采用简单密码
mysql> set global validate_password_length=1;		# 设置密码长度
mysql> alter user 'root'@'localhost' identified by '123456';		# 更新root密码
mysql> show master status;							# 查看master状态，可以看到二进制日志文件的名称
+------------------+----------+--------------+------------------+-------------------+
| File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
+------------------+----------+--------------+------------------+-------------------+
| mysql-bin.000002 |      398 |              |                  |                   |
+------------------+----------+--------------+------------------+-------------------+
1 row in set (0.00 sec)

mysql> grant replication slave,replication client on *.* to slave@"192.168.64.*" identified by '123456';
# 创建复制账号并设置密码
```

## 安装从节点

```shell
[root@slave ~]# ls
anaconda-ks.cfg  mysql-5.7.39-1.el7.x86_64.rpm-bundle.tar
[root@slave ~]# tar xf mysql-5.7.39-1.el7.x86_64.rpm-bundle.tar
[root@slave ~]# dnf -y install *.rpm
```

## 配置从节点

```shell
[root@slave ~]# vi /etc/my.cnf
log_bin = mysql-bin
server_id = 11
read_only = 1				# 开启只读，从节点只提供只读
```

![image-20221013011005455](image-20221013011005455.png)

## 启动从节点

```shell
[root@slave ~]# systemctl enable --now mysqld
[root@slave ~]# cat /var/log/mysqld.log | grep password
2022-10-12T17:11:25.637271Z 1 [Note] A temporary password is generated for root@localhost: mHJ5aTJE+grU
[root@slave ~]# mysql -uroot -pmHJ5aTJE+grU
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 2
Server version: 5.7.39-log

Copyright (c) 2000, 2022, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> set global validate_password_policy=0;							# 更改密码复杂度
Query OK, 0 rows affected (0.00 sec)

mysql> set global validate_password_length=1;							# 更改密码策略长度
Query OK, 0 rows affected (0.00 sec)

mysql> alter user 'root'@'localhost' identified by '123456';			# 更改root密码
Query OK, 0 rows affected (0.00 sec)
	
mysql> change master to master_host="192.168.64.147",			# 配置复制账号信息
    -> master_user="slave",
    -> master_password="123456",
    -> master_log_file="mysql-bin.000002",
    -> master_log_pos=0;
Query OK, 0 rows affected, 2 warnings (0.00 sec)

mysql> show slave status\G			# 查看slave状态
*************************** 1. row ***************************
               Slave_IO_State:
                  Master_Host: 192.168.64.147
                  Master_User: slave
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000002
          Read_Master_Log_Pos: 4
               Relay_Log_File: slave-relay-bin.000001
                Relay_Log_Pos: 4
        Relay_Master_Log_File: mysql-bin.000002
             Slave_IO_Running: No
            Slave_SQL_Running: No
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table:
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 4
              Relay_Log_Space: 154
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        Seconds_Behind_Master: NULL
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
  Replicate_Ignore_Server_Ids:
             Master_Server_Id: 0
                  Master_UUID:
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State:
           Master_Retry_Count: 86400
                  Master_Bind:
      Last_IO_Error_Timestamp:
     Last_SQL_Error_Timestamp:
               Master_SSL_Crl:
           Master_SSL_Crlpath:
           Retrieved_Gtid_Set:
            Executed_Gtid_Set:
                Auto_Position: 0
         Replicate_Rewrite_DB:
                 Channel_Name:
           Master_TLS_Version:
1 row in set (0.00 sec)

mysql> start slave;						# 启动复制，关闭使用stop slave;
Query OK, 0 rows affected (0.00 sec)

mysql> show slave status\G				# 查看状态
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 192.168.64.147
                  Master_User: slave
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000002
          Read_Master_Log_Pos: 1028
               Relay_Log_File: slave-relay-bin.000002
                Relay_Log_Pos: 1241
        Relay_Master_Log_File: mysql-bin.000002
             Slave_IO_Running: Yes						# IO启动     确保这两项为Yes
            Slave_SQL_Running: Yes						# SQL启动
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table:
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 1028
              Relay_Log_Space: 1448
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        Seconds_Behind_Master: 0
Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
  Replicate_Ignore_Server_Ids:
             Master_Server_Id: 10
                  Master_UUID: 19e30d90-4a4e-11ed-9534-000c2952ba66
             Master_Info_File: /var/lib/mysql/master.info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind:
      Last_IO_Error_Timestamp:
     Last_SQL_Error_Timestamp:
               Master_SSL_Crl:
           Master_SSL_Crlpath:
           Retrieved_Gtid_Set:
            Executed_Gtid_Set:
                Auto_Position: 0
         Replicate_Rewrite_DB:
                 Channel_Name:
           Master_TLS_Version:
1 row in set (0.00 sec)
```

## 测试主从

在主节点上对数据库进行写操作

```shell
mysql> create database xiaowangc;
```

在从简单上对数据库进行查看

```shell
mysql> show databases;
```

![image-20221013015033188](image-20221013015033188.png)

# 增量备份

```shell
--all-databases：备份所有的数据库
--databases db1 db2：备份指定的数据库
--single-transaction：对事务引擎执行热备
--flush-logs：更新二进制日志文件
--master-data=2
  1：每备份一个库就生成一个新的二进制文件(默认)
  2：只生成一个新的二进制文件
--quick：在备份大表时指定该选项
================================================================================
mysqldump -u root -p password --all-databases --single-transaction --flush-logs --master-data=2 > mysql_all.sql
# 备份所有库

mysqladmin -u root -p flush-logs   
# 增量备份，刷新二进制文件后最好再Copy一份到其他服务器上避免服务器崩溃
```

**不管做不做主从一定要开启二进制日志！！！**

# 复制架构

- 一主多从

  ![image-20221013021525912](image-20221013021525912.png)

- 多主架构

  - 主动

    ![image-20221013021551952](image-20221013021551952.png)

  - 被动

    ![image-20221013021609894](image-20221013021609894.png)

- 多主多从

  ![image-20221013021642526](image-20221013021642526.png)

- 环形复制

  ![image-20221013021705448](image-20221013021705448.png)

  ![image-20221013021721728](image-20221013021721728-16655986421531.png)

- 树形复制

  ![image-20221013021822328](image-20221013021822328.png)

# 允许Root从远程登录
```shell
update mysql.user set Host='%' where HOST='localhost' and User='root';
flush privileges;
```
  

















