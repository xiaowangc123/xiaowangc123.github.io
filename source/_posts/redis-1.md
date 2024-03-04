---
title: Redis单机数据迁移
abbrlink: b37d654d
date: 2022-10-27 09:51:36
tags:
  - Redis
  - NoSQL
categories: NoSQL
cover: img/fengmian/redis.jpeg
---
# Redis单机数据持久化迁移
![redis-boot](redis-boot.png)
**注意RDB和AOF加载流程**
停止 Redis，关闭 AOF 持久化，保留 RDB 持久化，防止启动时生成 appendonly.aof 文件；
拷贝 RDB 文件到数据目录，启动 Redis，启动后 Redis 会使用 RDB 文件恢复数据；
确认数据恢复，在命令行热修改配置开启 AOF 持久化 config set appendonly yes；
等待 Redis 将内存中的数据写入 appendonly.aof 文件，此时 RDB 和 AOF 数据已同步；
停止 Redis，修改配置文件开启 AOF 持久化和 RDB 持久化；
启动 Redis，数据恢复和持久化配置完成。