---
title: Kubernetes-Join流程
abbrlink: ceed1ba0
date: 2022-12-01 17:35:44
tags:
  - kubernetes
categories: Kubernetes
cover: img/fengmian/k8s.jpeg
---
### join 工作流

`kubeadm join` 初始化 Kubernetes 工作节点或控制平面节点并将其添加到集群中。 对于工作节点，该操作包括以下步骤：

1. kubeadm 从 API 服务器下载必要的集群信息（Public名称空间下名为Cluster-info的Configmap）。 默认情况下，它使用引导令牌和 CA 密钥哈希来验证数据的真实性。 也可以通过文件或 URL 直接发现根 CA。

1. 一旦知道集群信息，kubelet 就可以开始 TLS 引导过程。

   TLS 引导程序使用共享令牌与 Kubernetes API 服务器进行临时的身份验证，以提交证书签名请求 (CSR)； 默认情况下，控制平面自动对该 CSR 请求进行签名。

1. 最后，kubeadm 配置本地 kubelet 使用分配给节点的确定标识连接到 API 服务器。

对于控制平面节点，执行额外的步骤：

1. 从集群下载控制平面节点之间共享的证书（如果用户明确要求）。
2. 生成控制平面组件清单、证书和 kubeconfig。
3. 添加新的本地 etcd 成员。