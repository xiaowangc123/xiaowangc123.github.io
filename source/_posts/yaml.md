---
title: yaml语法
tags: yaml
cover: >-
  https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fpic.51yuansu.com%2Fpic2%2Fcover%2F00%2F52%2F33%2F5816b34acabdc_610.jpg&refer=http%3A%2F%2Fpic.51yuansu.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=auto?sec=1660167772&t=6fa1255fe1b74a3cef0ccefb6d3be285
categories: YAML
abbrlink: f0b5a6ea
date: 2022-07-12 05:40:54
---
# 概念

YAML(YAML Ain't Markup Language)，是一种可读性非常高的数据格式。YAML不再以标记为重点语言，而是围绕数据来组织结构化格式。常见YAML用于Playbook、K8S资源文件的书写标准

YAML文件后缀为yml、yaml

# YAML语法规则

1. 使用缩进表示层级关系、缩进的空格数不重要，只要相同的元素左对齐即可
2. YAML支持字典、数组、纯量(字符串、布尔值、整数、浮点数、Null、时间、日期)
3. YAML以#表示注释
4. 区分大小写

## 纯量

```yaml
name: xiaowangc		# 字符串
age: 18				# 整数
number:	18.1		# 浮点数
one: true			# 布尔值
two: null			# null
two: ~				# null
date: 2022-07-09	# 时间
time: 2022-07-09T20:30+08:00	# 日期 年月日 小时分钟 时区

# 多行表示
str: >
  This is a long string written by xiaowangc
  This is a long string written by xiaowangc

效果: "This is a long string written by xiaowangc This is a long string written by xiaowangc"

# 按原格式
str: |
  This is a long string written by xiaowangc
  This is a long string written by xiaowangc
  This is a long string written by xiaowangc

效果: "
  This is a long string written by xiaowangc
  This is a long string written by xiaowangc
  This is a long string written by xiaowangc
"
```

## 数组

```yaml
# 方式一
name:
- xiaowangc
- zhangsan

# 方式二
name:
  - xiaowangc
  - zhangsan
  
# 方式三
name: [xiaowangc,zhangsan]
```

## 对象

```yaml
names:
  name01: xiaowangc
  name02: zhangsan
  name03: lisi
  name04: wanger
  age01: 1234
  age02: 7.7
```

