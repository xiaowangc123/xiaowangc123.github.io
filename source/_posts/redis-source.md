---
title: 源码安装Redis
tags:
  - Redis
  - NoSQL
categories: NoSQL
cover: img/fengmian/redis.jpeg
abbrlink: 49dcd92b
date: 2023-08-11 15:39:55
---
## 源码安装Reids

> 系统：Ubuntu 22.04

```shell
root@redis01:~# wget wget https://download.redis.io/redis-stable.tar.gz
root@redis01:~# tar xf redis-stable.tar.gz
root@redis01:~# apt -y install build-essential automake
root@redis01:~# cd redis-stable/
root@redis01:~/redis-stable# make
root@redis01:~/redis-stable# make install
root@redis01:~# redis-cli -v
redis-cli 7.0.12
```

## Redis单实例启动

```shell
root@redis01:~# echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
root@redis01:~# sysctl -p
root@redis01:~# redis-server
7744:C 11 Aug 2023 02:36:52.619 # oO0OoO0OoO0Oo Redis is starting oO0OoO0OoO0Oo
7744:C 11 Aug 2023 02:36:52.619 # Redis version=7.0.12, bits=64, commit=00000000, modified=0, pid=7744, just started
7744:C 11 Aug 2023 02:36:52.619 # Warning: no config file specified, using the default config. In order to specify a config file use redis-server /path/to/redis.conf
7744:M 11 Aug 2023 02:36:52.619 * Increased maximum number of open files to 10032 (it was originally set to 1024).
7744:M 11 Aug 2023 02:36:52.619 * monotonic clock: POSIX clock_gettime
                _._
           _.-``__ ''-._
      _.-``    `.  `_.  ''-._           Redis 7.0.12 (00000000/0) 64 bit
  .-`` .-```.  ```\/    _.,_ ''-._
 (    '      ,       .-`  | `,    )     Running in standalone mode
 |`-._`-...-` __...-.``-._|'` _.-'|     Port: 6379
 |    `-._   `._    /     _.-'    |     PID: 7744
  `-._    `-._  `-./  _.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |           https://redis.io
  `-._    `-._`-.__.-'_.-'    _.-'
 |`-._`-._    `-.__.-'    _.-'_.-'|
 |    `-._`-._        _.-'_.-'    |
  `-._    `-._`-.__.-'_.-'    _.-'
      `-._    `-.__.-'    _.-'
          `-._        _.-'
              `-.__.-'

7744:M 11 Aug 2023 02:36:52.620 # Server initialized
7744:M 11 Aug 2023 02:36:52.620 * Loading RDB produced by version 7.0.12
7744:M 11 Aug 2023 02:36:52.620 * RDB age 17 seconds
7744:M 11 Aug 2023 02:36:52.620 * RDB memory usage when created 0.82 Mb
7744:M 11 Aug 2023 02:36:52.620 * Done loading RDB, keys loaded: 0, keys expired: 0.
7744:M 11 Aug 2023 02:36:52.620 * DB loaded from disk: 0.000 seconds
7744:M 11 Aug 2023 02:36:52.620 * Ready to accept connections
```

## 创建Redis集群

1. 准备配置文件

   ```shell
   root@redis01:~# tree redis
   redis
   ├── 6001
   │   └── redis.conf
   ├── 6002
   │   └── redis.conf
   ├── 6003
   │   └── redis.conf
   ├── 6004
   │   └── redis.conf
   ├── 6005
   │   └── redis.conf
   └── 6006
       └── redis.conf
   
   6 directories, 6 files
   ```

   配置文件

   ```shell
   port 6001			# 根据目录名称来设置或自定义
   cluster-enabled yes		# 开启集群
   cluster-config-file nodes.conf 	 # 设置集群配置文件
   cluster-node-timeout 5000	# 节点超时时间
   appendonly yes	# 启动AOF持久化
   daemonize yes	# 后台运行
   requirepass 123456	# 设置密码，因为redis默认启动启动保护模式，必须设置密码或者关闭保护模式
   ```

2. 运行Redis

   ```shell
   root@redis01:~/redis# ls
   6001  6002  6003  6004  6005  6006
   root@redis01:~/redis# cd 6001/
   root@redis01:~/redis/6001# redis-server redis.conf
   root@redis01:~/redis/6001# cd ../6002/
   root@redis01:~/redis/6002# redis-server redis.conf
   root@redis01:~/redis/6002# cd ../6003/
   root@redis01:~/redis/6003# redis-server redis.conf
   root@redis01:~/redis/6003# cd ../6004/
   root@redis01:~/redis/6004# redis-server redis.conf
   root@redis01:~/redis/6004# cd ../6005/
   root@redis01:~/redis/6005# redis-server redis.conf
   root@redis01:~/redis/6005# cd ../6006/
   root@redis01:~/redis/6006# redis-server redis.conf
   LISTEN 0      511          0.0.0.0:16001      0.0.0.0:*    users:(("redis-server",pid=9394,fd=9))
   LISTEN 0      511          0.0.0.0:16002      0.0.0.0:*    users:(("redis-server",pid=9402,fd=9))
   LISTEN 0      511          0.0.0.0:16003      0.0.0.0:*    users:(("redis-server",pid=9410,fd=9))
   LISTEN 0      511          0.0.0.0:16004      0.0.0.0:*    users:(("redis-server",pid=9416,fd=9))
   LISTEN 0      511          0.0.0.0:16005      0.0.0.0:*    users:(("redis-server",pid=9422,fd=9))
   LISTEN 0      511          0.0.0.0:16006      0.0.0.0:*    users:(("redis-server",pid=9428,fd=9))
   LISTEN 0      511          0.0.0.0:6001       0.0.0.0:*    users:(("redis-server",pid=9394,fd=6))
   LISTEN 0      511          0.0.0.0:6002       0.0.0.0:*    users:(("redis-server",pid=9402,fd=6))
   LISTEN 0      511          0.0.0.0:6003       0.0.0.0:*    users:(("redis-server",pid=9410,fd=6))
   LISTEN 0      511          0.0.0.0:6004       0.0.0.0:*    users:(("redis-server",pid=9416,fd=6))
   LISTEN 0      511          0.0.0.0:6005       0.0.0.0:*    users:(("redis-server",pid=9422,fd=6))
   LISTEN 0      511          0.0.0.0:6006       0.0.0.0:*    users:(("redis-server",pid=9428,fd=6))
   LISTEN 0      511             [::]:16001         [::]:*    users:(("redis-server",pid=9394,fd=10))
   LISTEN 0      511             [::]:16002         [::]:*    users:(("redis-server",pid=9402,fd=10))
   LISTEN 0      511             [::]:16003         [::]:*    users:(("redis-server",pid=9410,fd=10))
   LISTEN 0      511             [::]:16004         [::]:*    users:(("redis-server",pid=9416,fd=10))
   LISTEN 0      511             [::]:16005         [::]:*    users:(("redis-server",pid=9422,fd=10))
   LISTEN 0      511             [::]:16006         [::]:*    users:(("redis-server",pid=9428,fd=10))
   LISTEN 0      511             [::]:6001          [::]:*    users:(("redis-server",pid=9394,fd=7))
   LISTEN 0      511             [::]:6002          [::]:*    users:(("redis-server",pid=9402,fd=7))
   LISTEN 0      511             [::]:6003          [::]:*    users:(("redis-server",pid=9410,fd=7))
   LISTEN 0      511             [::]:6004          [::]:*    users:(("redis-server",pid=9416,fd=7))
   LISTEN 0      511             [::]:6005          [::]:*    users:(("redis-server",pid=9422,fd=7))
   LISTEN 0      511             [::]:6006          [::]:*    users:(("redis-server",pid=9428,fd=7))
   ```

3. 初始化集群

   ```shell
   root@redis01:~/redis/6006# redis-cli --cluster create \
   192.168.66.11:6001 \
   192.168.66.11:6002 \
   192.168.66.11:6003 \
   192.168.66.11:6004 \
   192.168.66.11:6005 \
   192.168.66.11:6006 \
   --cluster-replicas 1 \
   -a 123456
   Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
   >>> Performing hash slots allocation on 6 nodes...
   Master[0] -> Slots 0 - 5460
   Master[1] -> Slots 5461 - 10922
   Master[2] -> Slots 10923 - 16383
   Adding replica 192.168.66.11:6005 to 192.168.66.11:6001
   Adding replica 192.168.66.11:6006 to 192.168.66.11:6002
   Adding replica 192.168.66.11:6004 to 192.168.66.11:6003
   >>> Trying to optimize slaves allocation for anti-affinity
   [WARNING] Some slaves are in the same host as their master
   M: 09dffc30ed9c3a337596b0adb301e16830c226ac 192.168.66.11:6001
      slots:[0-5460] (5461 slots) master
   M: 8ed9d30ee063c708a5208c7aca8daffb70ecd710 192.168.66.11:6002
      slots:[5461-10922] (5462 slots) master
   M: 945afa23a9d0f0db653404f850e9327b3e16a5c2 192.168.66.11:6003
      slots:[10923-16383] (5461 slots) master
   S: 6ce8cf89caec9561fb70d37956a3f2a8261c3c5e 192.168.66.11:6004
      replicates 8ed9d30ee063c708a5208c7aca8daffb70ecd710
   S: 8b8f2fce9e06991ef7bc37d4096258ac75c69b50 192.168.66.11:6005
      replicates 945afa23a9d0f0db653404f850e9327b3e16a5c2
   S: 8a3210ce900daf7196128008d2fa679cffffa195 192.168.66.11:6006
      replicates 09dffc30ed9c3a337596b0adb301e16830c226ac
   Can I set the above configuration? (type 'yes' to accept): yes
   >>> Nodes configuration updated
   >>> Assign a different config epoch to each node
   >>> Sending CLUSTER MEET messages to join the cluster
   Waiting for the cluster to join
   
   >>> Performing Cluster Check (using node 192.168.66.11:6001)
   M: 09dffc30ed9c3a337596b0adb301e16830c226ac 192.168.66.11:6001
      slots:[0-5460] (5461 slots) master
      1 additional replica(s)
   M: 945afa23a9d0f0db653404f850e9327b3e16a5c2 192.168.66.11:6003
      slots:[10923-16383] (5461 slots) master
      1 additional replica(s)
   S: 8a3210ce900daf7196128008d2fa679cffffa195 192.168.66.11:6006
      slots: (0 slots) slave
      replicates 09dffc30ed9c3a337596b0adb301e16830c226ac
   S: 8b8f2fce9e06991ef7bc37d4096258ac75c69b50 192.168.66.11:6005
      slots: (0 slots) slave
      replicates 945afa23a9d0f0db653404f850e9327b3e16a5c2
   S: 6ce8cf89caec9561fb70d37956a3f2a8261c3c5e 192.168.66.11:6004
      slots: (0 slots) slave
      replicates 8ed9d30ee063c708a5208c7aca8daffb70ecd710
   M: 8ed9d30ee063c708a5208c7aca8daffb70ecd710 192.168.66.11:6002
      slots:[5461-10922] (5462 slots) master
      1 additional replica(s)
   [OK] All nodes agree about slots configuration.
   >>> Check for open slots...
   >>> Check slots coverage...
   [OK] All 16384 slots covered.
   ```

4. 查看集群

   ```shell
   root@redis01:~# redis-cli -c -p 6001 -a 123456 cluster nodes
   Warning: Using a password with '-a' or '-u' option on the command line interface may not be safe.
   945afa23a9d0f0db653404f850e9327b3e16a5c2 192.168.66.11:6003@16003 master - 0 1691733745292 3 connected 10923-16383
   8a3210ce900daf7196128008d2fa679cffffa195 192.168.66.11:6006@16006 slave 09dffc30ed9c3a337596b0adb301e16830c226ac 0 1691733746298 1 connected
   09dffc30ed9c3a337596b0adb301e16830c226ac 192.168.66.11:6001@16001 myself,master - 0 1691733745000 1 connected 0-5460
   8b8f2fce9e06991ef7bc37d4096258ac75c69b50 192.168.66.11:6005@16005 slave 945afa23a9d0f0db653404f850e9327b3e16a5c2 0 1691733747304 3 connected
   6ce8cf89caec9561fb70d37956a3f2a8261c3c5e 192.168.66.11:6004@16004 slave 8ed9d30ee063c708a5208c7aca8daffb70ecd710 0 1691733746600 2 connected
   8ed9d30ee063c708a5208c7aca8daffb70ecd710 192.168.66.11:6002@16002 master - 0 1691733746801 2 connected 5461-10922
   ```

   

