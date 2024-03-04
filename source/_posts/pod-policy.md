---
title: Pod安全性标准
abbrlink: 2d6df133
date: 2022-11-30 14:39:55
tags:
  - kubernetes
  - Pod安全
  - CKS
categories: Kubernetes
cover: img/fengmian/k8s.jpeg
---
# Pod安全性标准

Pod安全性标准定义了三种不同的策略（Policy），广泛覆盖安全应用场景。这些策略是叠加式的，安全级别从高度宽松至高度受限

- **Privileges**

  **Privileged策略是有目的地开放且完全无限制的策略**。此类策略通常针对由特权较高、受信任的用户所管理的系统级或基础设施级负载

- **Baseline**

  **Baseline 策略的目标是便于常见的容器化应用采用，同时禁止已知的特权提升。** 此策略针对的是应用运维人员和非关键性应用的开发人员

- **Restricted**

  **Restricted 策略旨在实施当前保护 Pod 的最佳实践，尽管这样作可能会牺牲一些兼容性。** 该类策略主要针对运维人员和安全性很重要的应用的开发人员，以及不太被信任的用户