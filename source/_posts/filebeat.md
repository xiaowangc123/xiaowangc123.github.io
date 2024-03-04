---
title: filebeat收集问题
tags:
  - filebeat
  - ELK
cover: img/fengmian/elastic_logo.png
categories: ElasticSearch
abbrlink: b0bbbe8c
date: 2023-03-17 11:45:41
---
1.可以通过filebeat test output和filebeat test config命令测试配置文件和Output是否能连接上
root@node1:/usr/local/filebeat-8.6.2# ./filebeat test output
Kafka: 192.168.10.232:9092...
  parse host... OK
  dns lookup... OK
  addresses: 192.168.10.232
  dial up... OK

2.通过命令filebeat -e -d "*"调试
从调试给出的日志信息：
{"log.level":"debug","@timestamp":"2023-03-11T13:59:55.268+0800","log.logger":"input","log.origin":{"file.name":"log/input.go","file.line":342},"message":"File /var/log/containers/speaker-r7567_metallb-system_speaker-8eb13abb16ca0e73cdffefd565011ad3a3ce60dee2280964cb0d769e7e5e01fe.log skipped as it is a symlink.","service.name":"filebeat","input_id":"d5424200-bd9d-4258-b5bc-08a9778bf92b","ecs.version":"1.6.0"}
其中发现filebeat确实可以访问/var/log/containers/*.log相关的文件，"skipped as it is a symlink."给出关键信息
跳过因为它是一个软连接文件，导致了我的Kafka没有接收到任何日志

3.修改：
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/containers/*.log

filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/containers/*.log
  symlinks: true
