---
title: etcd备份和检查集群状态命令
abbrlink: f2101881
date: 2022-11-24 00:05:09
tags:
  - kubernetes
  - etcd
  - 备份
categories: etcd
cover: img/fengmian/etcd.jpeg
---
# etcd备份命令

```shell
# 前提需要安装etcdctl工具
# https://github.com/etcd-io/etcd/

# 查看etcd集群状态
[root@master1 ~]# etcdctl \
--endpoints master1.xiaowangc.local:2379,master2.xiaowangc.local:2379,master3.xiaowangc.local:2379 \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--cert /etc/kubernetes/pki/etcd/server.crt \
--key /etc/kubernetes/pki/etcd/server.key \
--write-out=table endpoint status 

+------------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|           ENDPOINT           |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+------------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
| master1.xiaowangc.local:2379 | 4e2cf6f6c40333c8 |   3.5.5 |  5.2 MB |     false |      false |         8 |      69635 |              69635 |        |
| master2.xiaowangc.local:2379 | 7308778bf3dd1f82 |   3.5.5 |  5.2 MB |      true |      false |         8 |      69635 |              69635 |        |
| master3.xiaowangc.local:2379 | 99148080d033de44 |   3.5.5 |  5.3 MB |     false |      false |         8 |      69635 |              69635 |        |
+------------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+

# 查看etcd集群状态
[root@master1 ~]# etcdctl \
--endpoints master1.xiaowangc.local:2379,master2.xiaowangc.local:2379,master3.xiaowangc.local:2379 \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--cert /etc/kubernetes/pki/etcd/server.crt \
--key /etc/kubernetes/pki/etcd/server.key endpoint health

master3.xiaowangc.local:2379 is healthy: successfully committed proposal: took = 8.169826ms
master2.xiaowangc.local:2379 is healthy: successfully committed proposal: took = 10.849518ms
master1.xiaowangc.local:2379 is healthy: successfully committed proposal: took = 8.282098ms

# 备份命令
[root@master1 ~]# etcdctl \
--endpoints master1.xiaowangc.local:2379 \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--cert /etc/kubernetes/pki/etcd/server.crt \
--key /etc/kubernetes/pki/etcd/server.key snapshot save my.db

{"level":"info","ts":"2022-11-23T23:44:32.593+0800","caller":"snapshot/v3_snapshot.go:65","msg":"created temporary db file","path":"my.db.part"}
{"level":"info","ts":"2022-11-23T23:44:32.598+0800","logger":"client","caller":"v3@v3.5.6/maintenance.go:212","msg":"opened snapshot stream; downloading"}
{"level":"info","ts":"2022-11-23T23:44:32.598+0800","caller":"snapshot/v3_snapshot.go:73","msg":"fetching snapshot","endpoint":"master1.xiaowangc.local:2379"}
{"level":"info","ts":"2022-11-23T23:44:32.630+0800","logger":"client","caller":"v3@v3.5.6/maintenance.go:220","msg":"completed snapshot read; closing"}
{"level":"info","ts":"2022-11-23T23:44:32.634+0800","caller":"snapshot/v3_snapshot.go:88","msg":"fetched snapshot","endpoint":"master1.xiaowangc.local:2379","size":"5.2 MB","took":"now"}
{"level":"info","ts":"2022-11-23T23:44:32.634+0800","caller":"snapshot/v3_snapshot.go:97","msg":"saved","path":"my.db"}
Snapshot saved at my.db

# 查看备份
[root@master1 ~]# etcdctl \
--endpoints master1.xiaowangc.local:2379 \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--cert /etc/kubernetes/pki/etcd/server.crt \
--key /etc/kubernetes/pki/etcd/server.key \
--write-out=table snapshot status my.db

Deprecated: Use `etcdutl snapshot status` instead.

+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| 9c4365f3 |    52313 |       1941 |     5.2 MB |
+----------+----------+------------+------------+

[root@master1 etcd_backup]# vi backup.sh
# 简单的备份脚本自行添加到定时任务执行
#/bin/bash
/usr/local/sbin/etcdctl \
--endpoints master1.xiaowangc.local:2379 \
--cacert /etc/kubernetes/pki/etcd/ca.crt \
--cert /etc/kubernetes/pki/etcd/server.crt \
--key /etc/kubernetes/pki/etcd/server.key \
--write-out=table snapshot save /root/etcd_backup/`date +%Y%m%d%H%M`.db
```