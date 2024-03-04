---
title: Prometheus-查询
tags:
  - Prometheus
  - 监控
categories: 监控
cover: img/fengmian/Prometheus.jpg
abbrlink: 762f83eb
date: 2022-06-22 12:24:11
---
# 度量类型

**Prometheus 支持四种类型的指标，它们是 - Counter - Gauge - Histogram - Summary**

1. Counter(计数器类型)

   计数器是一个只能增加或重置的度量值，即该值不能比之前的值减少。它可用于请求数量、错误数量等指标。

   不是Counter类型的度量却当作Counter类型计算，会得到一个错误的结果。例如，使用计数器来计算当前正在运行的进程的数量；应该使用Gauge

   ![counter_example](counter_example.png)


2. Gauge(仪表测量类型）

   Gauge是一个可以上升或下降的数字。它可用于衡量指标，例如集群中的 pod 数量、队列中的事件数量等。

   ![gauge_example](gauge_example.png)

3. Histogram(直方图类型)

   Histogram是对数据进行采样的指标类型，用来展示数据集的频率分布。Histogram是表示数值分布的图形，它将数值分组到一个一个的bucket当中，然后计算每个bucket中值出现的次数。在Histogram上，X轴表示数值的范围，Y轴表示该对应数值出现的频次

4. Summary(摘要类型)

   Summary和Histogram类似，主要也是用于表示一段时间内数据采样结果，它直接存储了quantile(分位图)数据，而不是根据统计区间计算出来的



# 查询语法

Prometheus 提供了一种称为 PromQL（Prometheus Query Language）的功能性查询语言，让用户可以实时选择和聚合时间序列数据。表达式的结果既可以显示为图形，也可以在 Prometheus 的表达式浏览器中以表格数据的形式显示，或者由外部系统通过HTTP API 使用。

在Prometheus的表达式语言中，表达式或者子表达式可以计算为以下四种类型之一

1. 瞬时向量
2. 范围向量
3. 数量
4. String

时间序列选择器：

1. 瞬时矢量选择器

   瞬时矢量选择器可以即时为每个度量选择一个样本值，最简单的形式就是给度量名称，这样将返回所有包含此度量名称的时间序列元素的瞬时向量。可以通过{}大括号中附加逗号的标签匹配器列表来进一步筛选这些时间序列

   - =(等于)：选择与提供的字符串完全相等的标签。
   - ！=(不等于)：选择不等于提供的字符串的标签。
   - =~(模糊匹配)：选择与提供的字符串进行正则表达式匹配的标签。
   - !~(模糊匹配取反)：选择与提供的字符串不匹配的标签。

2. 范围矢量选择器

   范围向量字面量的工作方式类似于瞬时向量字面量，只是它们从当前时刻选择一系列样本

3. 偏移修饰器

   该`offset`修饰符允许更改查询中各个瞬间和范围向量的时间偏移量。

# 常用函数

官网：https://prometheus.io/docs/prometheus/latest/querying/functions/

1. increase()函数，该函数结合counter数据类型使用，获取区间向量中的第一个和最后一个样本并返回其增长量。如果除以时间就可以获得该时间内的平均增长值

2. rate()函数，该函数配置counter数据类型使用，用于获取时间段内的平均每秒增量

   通过rate函数获取在1分钟内网卡每秒接收字节数：

   rate(node_network_receive_bytes_total {app="app01",device="ens33"}[1m])

3. irate()函数，用于计算指定时间范围内每秒瞬时增长率，是基于该时间范围内最后两个点来计算。rate取指定时间范围的所有值，算出一组速率，然后取平均值

4. sum()函数，实际工作中CPU大多数是多核心，而node_cpu_seconds_total会将每个核的数据单独显示出来，因此可以使用sum()函数求和之后得出百分比之和

   sum(increase(node_cpu_seconds_total {app=”node01“,mode="user"}[1m])/60)

5. count()函数，该函数用于统计或用来做一些模糊判断。

   统计当前TCP连接是否大于200

   count(node_netstat_tcp_currestab {app="node01"} > 200 )

6. topk()函数，该函数从大量数据中取出排行前N的数值。

   例如从所有主机中找出近5分钟网卡流量排名前3的主机(Counter类型数据)

   topk(3,rate(node_network_receive_bytes_total {device="ens33"}[3m]))

7. predict_linear()函数，根据前一个时间段的值来预测未来某个时间点数据的走势
