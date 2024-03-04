---
title: Kubernetes-QoS
tags:
  - kubernetes
categories: Kubernetes
cover: img/fengmian/k8s.jpeg
abbrlink: 6e84fad4
date: 2024-02-06 05:51:19
---
# QoS概述

QoS(Quality of Service,服务质量)，最开始接触是在网络中。当网络发生拥塞的时候，所有数据包都可能被丢弃，为了满足用户对不同应用不同服务质量的要求，就需要网络根据用户的要求分配和调度资源，对不同的数据提供不同的服务质量，对实时性强且重要的数据优先处理；对于实时性不强的普通数据提供较低的处理优先级，网络拥塞时甚至丢弃。

而Kubernetes通过QoS通过为Pod中的容器指定**资源约束(限制)**为每个Pod设置QoS类。Kubernetes依赖这些分类来决定当Node上**没有足够资源时要驱逐哪些Pod。**

# QoS类

Kubernetes可选的QoS类有`Guaranteed`、`Burstable`和`BestEffort`。**当一个Node耗尽资源时，Kubernetes将首先驱逐在该Node上运行的`BestEffort`Pod，然后是`Burstable`，最后是`Guaranteed`Pod。**

![podqos](podqos-1707163001832-3.png)

- 所有超过资源限制limit的容器都将被kubelet杀死并重启，不会影响Pod其他的容器
- 容器超出自身资源的request且该容器运行的节点出现资源压力时，则该容器所在的Pod就会成为被驱逐的候选对象
- Pod的资源request等于其所有容器的request的和，同理limit同样是所有容器的和

## Guaranteed

**Guaranteed(有保证的)Pod**具有最严格的资源限制，Pod不可以获得超出指定的limit限制的资源，并且最不可能面临驱逐。通过如下来配置Guaranteed Pod，**必须要求Pod中每个容器都必须设置CPU和内存且request和limit必须相等**。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: xiaowangc
spec:
  containers:
  - name: app1
    image: nginx
    resources:
      requests:
        memory: "512Mi"
        cpu: "500m"
      limits:
        memory: "512Mi"
        cpu: "500m"
  - name: app2
    image: nginx
    resources:
      requests:
        memory: "1024Mi"
        cpu: "1"
      limits:
        memory: "1024Mi"
        cpu: "1"
```

## Burstable

**Burstable(突发型的)Pod**在有一些基于request的资源下限保证，但不需要特定的limit，如果未指定limit，则默认limit等于Node容量，这允许Pod在资源可用时灵活地为其增加资源。在所有`BestEffort`Pod被驱逐后这些Pod才会被驱逐。通过如下来配置Burstable Pod，**Pod中至少一个容器有CPU或内存的request或者limit配置**。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: xiaowangc-1
spec:
  containers:
  - name: app
    image: nginx
    resources:
      limits:
        memory: "200Mi"
      requests:
        memory: "100Mi"
---
apiVersion: v1
kind: Pod
metadata:
  name: xiaowangc-2
spec:
  containers:
  - name: app
    image: nginx
    resources:
      requests:
        cpu: "100m"
---
apiVersion: v1
kind: Pod
metadata:
  name: xiaowangc-3
spec:
  containers:
  - name: app
    image: nginx
    resources:
      limits:
        memory: "200Mi"      
```

## BestEffort

**BestEffort(最大努力的)Pod**会尝试使用Node剩余资源，如果节点遇到资源压力，kubelet将优先驱逐`BestEffort`Pod。通过如下来配置`BestEffort`Pod即无需为Pod或容器设置资源请求/限制

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: xiaowangc
spec:
  containers:
  - name: app
    image: nginx
```





