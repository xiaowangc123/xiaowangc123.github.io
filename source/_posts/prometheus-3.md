---
title: Prometheus-Alertmanager
tags:
  - Prometheus
  - 监控
categories: 监控
cover: img/fengmian/Prometheus.jpg
abbrlink: 446ae31b
date: 2022-06-23 13:24:11
---
# Alertmanager

Prometheus发出告警时分为两部分。首先，Prometheus按告警规则（rule_files配置块）向alertmanager发送告警（即告警规则是在Prometheus上定义的）。然后由Alertmanager来管理这些告警，包括去重（Deduplicating）、分组（Grouping）、静音（Silencing）、抑制（Inhibition）、聚合（Aggregation），最终通过电子邮件、WebHook等方式告警通知对应的联系人



# 安装Alertmanager

```shell
tar xf alertmanager-0.24.0.linux-amd64.tar.gz
mv alertmanager-0.24.0.linux-amd64 /usr/local/
```

```yaml
[root@localhost alertmanager]# cat alertmanager.yml
route:	# 路由
  group_by: ['alertname']	# 分组聚合
  group_wait: 30s			# 当新组被创建需等待多久才发送初始通知
  group_interval: 5m		# 
  repeat_interval: 1h		# c
  receiver: 'web.hook'
receivers: 
  - name: 'web.hook'
    webhook_configs:
      - url: 'http://127.0.0.1:5001/'
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
```

# 修改Prometheus配置，对Alertmanager进行关联，同时添加监控

```yaml
# my global config
global:
  scrape_interval: 5s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 5s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
            - 172.25.250.5:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  - "first_rules.yml"
  - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: "prometheus"

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets: ["localhost:9090"]
        labels:
          app: xiaowangc

  - job_name: "node"
    static_configs:
      - targets: ["172.25.250.9:9100"]
        labels:
          app: node01
      - targets: ["172.25.250.6:9100"]
        labels:
          app: node02
      - targets: ["172.25.250.7:9100"]
        labels:
          app: node03
  - job_name: "alermanager"
    static_configs:
      - targets: ["172.25.250.5:9093"]
        labels:
          app: alermanager
```

```yaml
# 记录规则 first_rules.yml
groups:
  - name: node_rules
    rules:
    - record: node_cpu		# 时间序列名称
      expr: 100-avg(irate(node_cpu_seconds_total{mode="idle"}[1m]))by(app)*100	# 查询表达式
      labels:
        metrice_type: cpu
    - record: load1m_monitor
      expr: node_load1
      labels:
        metrice_type: load1m_monitor
    - record: node_mem
      expr: 100-(node_memory_Active_bytes/node_memory_MemTotal_bytes)*100
      labels:
        metrice_type: node_mem
        
        
# 报警规则 second_rules.yml

groups:
  - name: node_alerts
    rules:	# 规则
    - alert: node_cpu		# 关联记录规则的时间序列名称
      expr: node_cpu > 80	# 值大于80
      for: 1m		# 持续时间
      labels:
        severity: warning
      annotations:		# 提示信息
        summary: 主机 {{ $labels.app }} 的CPU使用率持续1分钟超出阈值，当前为{{ $value }} %
    - alert: cpu
      expr: load1m_monitor > 20
      for: 1m
      labels:
        severity: warning
      annotations:
        summary: 主机 {{ $labels.app}} CPU1分钟负载阈值超出当前为{{$value}}%
```

可选for子句使 Prometheus 在第一次遇到新的表达式输出向量元素和将警报计数为针对该元素触发之间等待一定的持续时间。在这种情况下，Prometheus 将在每次评估期间检查警报是否继续处于活动状态 10 分钟，然后再触发警报。处于活动状态但尚未触发的元素处于挂起状态。

该labels子句允许指定一组附加标签附加到警报。任何现有的冲突标签都将被覆盖。标签值可以模板化。

该annotations子句指定一组信息标签，可用于存储更长的附加信息，例如警报描述或运行手册链接。注释值可以被模板化。