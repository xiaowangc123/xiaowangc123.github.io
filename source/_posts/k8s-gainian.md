---
title: Kubernetes组件概念
abbrlink: 9b833745
date: 2022-11-28 15:53:15
tags:
  - kubernetes
categories: Kubernetes
cover: img/fengmian/k8s.jpeg
---
# Kubernetes组件

![Kubernetes 的组件](https://d33wubrfki0l68.cloudfront.net/2475489eaf20163ec0f54ddc1d92aa8d4c87c96b/e7c81/images/docs/components-of-kubernetes.svg)

## 控制平面组件

- kube-apiserver

  负责公开了 Kubernetes API，负责处理接受请求的工作

- etcd

  高度可用的键值存储，k8s集群的数据库

- kube-scheduler

   负责监视新调度创建的、未指定运行节点的Pods， 并选择节点来让 Pod 在上面运行

  调度决策考虑的因素包括单个 Pod 及 Pods 集合的资源需求、软硬件及策略约束、 亲和性及反亲和性规范、数据位置、工作负载间的干扰及最后时限

- kube-controller-manager

  - **节点控制器（Node Controller）**

    负责在节点出现故障时进行通知和响应

  - **任务控制器（Job Controller）**

    监测一次性任务的Job对象，然后创建Pods来运行这些任务直至完成

  - **端点分片控制器（EndpointSlice Controller）**

    填充端点分片(EndPointSlice)对象(对SVC和Pod之间进行关联)

  - **服务账号控制器（Service Account Controller）**

    为新的名称空间创建默认的服务账号（SA）

- cloud-conroller-manager

  允许将集群连接到云提供商的 API 之上， 并将与该云平台交互的组件与集群交互的组件分离开来。

  - **节点控制器（Node Controller）**

    在节点终止响应后检查云提供商以确定节点是否已删除

  - **路由控制器（Route Controller）**

    用于在底层云基础架构中设置路由

  - **服务控制器（Service Controller）**

    用于创建、更新和删除云提供商负载均衡器

## Node组件

- kubelet

  kubelet运行在集群中每个节点上。它保证容器都运行在Pod中

  kubelet接受到来自控制平面提供的PodSpecs，确保这些PodSpecs中描述的容器处于运行且状态健康。kubelet不会管理不是由k8s创建的容器

- kube-proxy

  kube-proxy运行集群中每个节点上的网络代理，实现k8s服务(Service)的一部分。

  维护节点上的网络规则，这些网络规则会允许从集群内部或外部的网络会话与Pod进行网络通信

- 容器运行时(Container Runtime)

  容器运行环境是负责运行容器的软件

  containerd、CRI-O、Docker(1.24开始需要安装cri-dockerd)、Podman等遵循CRI标准



# Pod创建流程

1. 用户通过kubectl等方式向ApiServer发送请求，需要创建新Pod
2. ApiServer验证请求身份信息无误后将新Pod的信息写入etcd中
3. ControllerManager通过ApiServer的watch(监视)接口发现了新的Pod信息更新，将该资源所依赖的拓扑结构进行整合，整合后将信息提交给ApiServer，通过ApiServer写入到etcd，此时Pod以及可以被调度了
4. Scheduler通过ApiServer的watch接口更新发现Pod可以被调度，通过算法给Pod分配节点，并将Pod和对应节点绑定的信息交给ApiServer，通过ApiServer写入到etcd，然后将PodSpecs交给kubelet
5. kubelet收到PodSpecs后，通过调用CRI，CNI、CSI去对容器、网络、存储等资源进行创建
6. 容器、网络、存储创建完成后Pod创建完成。

# Pod的生命周期

Pod 在其生命周期中只会被调度一次。 一旦 Pod 被调度（分派）到某个节点，Pod 会一直在该节点运行，直到 Pod 停止或者被终止

**Pod 被认为是相对临时性（而不是长期存在）的实体**。 Pod 会被创建、赋予一个唯一的 ID（UID）， 并被调度到节点，并在终止（根据重启策略）或删除之前一直运行在该节点

**Pod 自身不具有自愈能力**。如果 Pod 被调度到某节点而该节点之后失效， Pod 会被删除；类似地，**Pod 无法在因节点资源耗尽或者节点维护而被驱逐期间继续存活**。

Pod不会被重新调度到不同的节点，只会被一个新的，且几乎完全相同的Pod替换掉，新的Pod名字可以不变，但是UID会不一样

## Pod阶段

- Pending（等待）

  有一个或者多个容器未创建或未运行。此阶段包括等待 Pod 被调度的时间和通过网络下载镜像的时间

- Running

  Pod 已经绑定到了某个节点，Pod 中所有的容器都已被创建。至少有一个容器仍在运行，或者正处于启动或重启状态

- Succeeded

  Pod 中的所有容器都已成功终止，并且不会再重启

- Failed

  Pod 中的所有容器都已终止，并且至少有一个容器是因为失败终止

- Unknown

  因为某些原因无法取得 Pod 的状态

## 容器状态

- Waiting

  如果容器并不处在 `Running` 或 `Terminated` 状态之一，它就处在 `Waiting` 状态。 处于 `Waiting` 状态的容器仍在运行它完成启动所需要的操作：例如， 从某个容器镜像仓库拉取容器镜像，或者向容器应用 Secret数据等等。 当你使用 `kubectl` 来查询包含 `Waiting` 状态的容器的 Pod 时，会看到一个 Reason 字段，其中给出了容器处于等待状态的原因

- Running

  状态表明容器正在执行状态并且没有问题发生

- Terminated

  容器已经开始执行并且或者正常结束或者因为某些原因失败

## 容器探针

probe是由kubelet对容器执行的定期诊断

### 检查机制

- exec

  在容器内执行指定命令。如果命令退出时返回码为 0 则认为诊断成功。

- grpc

  使用gRPC执行一个远程过程调用

- httpGet

  对容器的 IP 地址上指定端口和路径执行 HTTP `GET` 请求

- tcpSocket

  对容器的 IP 地址上的指定端口执行 TCP 检查。如果端口打开，则诊断被认为是成功的

### 探测结果

- Success

  容器通过了诊断

- Failure

  容器未通过诊断

- Unknown

  诊断失败

### 探测类型

- LivenessProbe（持续运行）

  存活探针，探测容器是否正在运行，如果探测失败，kubelet会杀死容器，并根据重启策略来决定后续

- ReadingessProbe（持续运行）

  就绪探针，探测容器是否准备好提供服务，如果探测失败，端点控制器将从与Pod匹配的端点列表中删除该Pod的IP地址

- StartupProbe（容器创建时运行一次）

  启动探针，探测容器是否以及启动，如果使用启动探针，则其他探针都会被禁用，知道此探针成功为止。如果探测失败，kubelet将杀死容器，并根据其重启策略来决定后续

## initC(初始容器)

Init 容器是一种特殊容器，在Pod内的应用容器启动之前运行，每个 Pod中可以包含多个容器， 应用运行在这些容器里面，同时 Pod 也可以有一个或多个先于应用容器启动的 Init 容器。如果init容器运行失败，kublet会不断的重启init容器知道该容器成功为止。

**init容器不支持探针，且如果有多个init容器，这些容器将按照顺序执行，当上一个init容器运行成功后，下一个init容器才能运行。所有的init容器运行完成后，k8s才会初始化Pod并运行**

**init容器可以限制资源使用率以及重启策略**

## 容器钩子(Container hooks)

- **PostStart(容器启动后)**

  这个钩子会在容器创建之后立即被执行，但是不能保证钩子会在容器入口点(ENTRYPOINT)之前执行

- **PreStop(容器结束前)**

  在容器因API或管理事件(探针、资源抢占等)而被终止之前，此钩子会被调用，如果容器已经处于已终止或已完成状态，则PreStop钩子的调用失败



