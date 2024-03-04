---
title: Kubernetes-审计
abbrlink: 926e9fa1
date: 2022-11-30 14:13:42
tags:
  - kubernetes
  - 审计
  - CKS
  - 安全
categories: Kubernetes
cover: img/fengmian/k8s.jpeg
---
# 审计

Kubernetes审计提供了与安全相关的、按时间顺序排列的记录集，记录每个用户、使用Kubernetes API的应用以及控制平面自身引发的活动

审计功能可以让管理员回答以下问题：

- 发什么甚么事了
- 什么时候发生的
- 谁触发的事件记录
- 活动发生做哪些对象上（对哪些资源进行了变更）
- 在哪观察到的
- 它从哪触发的
- 活动的后续处理行为是什么

审计记录最初产生于`kube-apiserver`内部。每个请求在不同执行阶段都会生成审计事件；这些审计事件会根据特定策略被预处理并写入后端。策略确定要记录的内容和用来存储记录的后端。当前的后端支持日志文件和webhook

每个请求都可被记录其相关的阶段(Stage)。已定义的阶段有：

- RequestReceived

  接收到请求，响应头发出之前记录审计日志

- ResponseStarted

  在响应消息的头部发送后，响应消息体发送前生成的事件，只有长时间运行的请求才会生成这个阶段

- ResponseComplete

  当响应消息体完成并且没有更多数据需要传输的时候

- Panic

  当panic发生时生成

# 审计策略

Kubernetes审计策略定义了关于应记录哪些事件以及应包含哪些数据的规则，审计策略对象结构定义在`audit.k8s.io` `API`组处理事件时，将按顺序与规则列表进行比较。第一个匹配规则设置事件的审计级别**（Audit ）**。已定义的审计级别有：

- **None**

  符合规则的日志不会被记录

- **Metadata**

  记录请求的元数据（请求的用户，时间戳，资源，动作等），但是不记录请求或相应的消息体

- **Request**

  记录事件的元数据和请求的消息体，但是不记录响应的消息体。这不适用于非资源类型的请求

- **RequestResponse**

  记录事件的元数据，请求和响应的消息体。这不适用于非资源类型的请求

## 示例

```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages:								# 省略阶段
  - "RequestReceived"						# 不在RequestReceived阶段为任何请求生成审计事件
rules:									# 规则
  - level: RequestReceived  				# 级别
    resources:								# 资源
    - group: ""									# 组
      resources: ["pods"]						# 资源(与RABA策略一致，NS级别，集群级别)
  # 在日志中按Metadata级别记录"pods/log"、"pods/status"请求
  - level: Metadata
    resources:
    - group: ""
      resources: ["pods/log","pods/status"]
  # 不在日志中记录对应名称为"controller-leader"的ConfigMap的请求
  - level: None
    resources:
    - group: ""
      resources: ["services"]
      resourcesName: ["controller-leader"]
  # 不在日志中记录由"system:kube-proxy"发起对端点或服务的监测请求
  - level: None
    users: ['system:kube-proxy']
    verbs: ['watch']
    resources:
    - group: ""
      resources: ['endpoints','services']
   # 在日志中记录kube-system名称空间中configmap变更的请求消息体
   - level: Request
     namespace: ["kube-system"]
     resources:
     - group: ""
       resources: ["configmaps"]
   # 在日志中按Metadata级别记录所有名称空间的configmap和secret的变更
   - level: Metadata
     resources:
     - group: ""
       resources: ["configmaps","secrets"]
   # 在日志中以Request级别记录所有其他core和extensions组中的资源操作
   - level: Request
     resources:
     - group: ""
     - group: "extensions"
   # 在日志中以Metadta级别记录所有规则的所有其他请求
   - level: Metadata
     omitStages:
       - "RequestReceived"
```

# 审计后端(存储)

审计后端实现将审计事件到处到外部存储。`Kube-apiserver`默认提供两个后端：

- Log后端

  将事件写入到文件系统

- WebHook

  将事件发送到外部HTTP API

## Log后端

Log后端将审计事件写入`Jsonlines`格式的文件。使用`kube-apiserver`标志配置Log审计后端：

- --audit-log-path

  指定日志审计事件的日志文件路径，不指定此标志会禁用日志

- --audit-log-maxage

  保留审计日志文件的最大天数

- --audit-log-maxbackup

  保留审计日志文件的最大数量

- --audit-log-maxsize

  定义审计日志文件的最大大小(兆字节)

如果集群控制平面以Pod的形式运行`Kube-apiserver`，需要使用`hostPath`卷来访问策略文件和日志文件所在的目录，这样审计记录才会持久保存

```yaml
--audit-policy-file=/etc/kubernetes/audit-policy.yaml \
--audit-log-path=/var/log/kubernetes/audit/audit.log
```

挂载数据卷

```yaml
volumeMounts:
  - mountPath: /etc/kubernetes/audit-policy.yaml
    name: audit
    readOnly: true
  - mountPath: /var/log/kubernetes/audit/
    name: audit-log
    readOnly: false
---
volumes:
- name: audit
  hostPath:
    path: /etc/kubernetes/audit-policy.yaml
    type: File

- name: audit-log
  hostPath:
    path: /var/log/kubernetes/audit/
    type: DirectoryOrCreate
```

## WebHook后端

WebHook后端将审计日志发送到远程WebAPI，该远程API应该暴露与Kube-apiserver形式相同的API，包括其身份验证机制

- --audit-webhook-config-file

  设置Webhook配置文件的路径，webhook配置文件实际上是一个kubeconfig文件

- --audit-webhook-initial-backoff

  第一次失败后重发请求等待事件



# 日志格式

截取部分格式化后如下：

**例1：**

```json
{
    "kind": "Event",
    "apiVersion": "audit.k8s.io/v1",
    "level": "Metadata",										// 审计级别
    "auditID": "db8c4ca2-cbee-468d-bb93-a483f29073e0",
    "stage": "ResponseStarted",									// 发出响应头后开始记录
    "requestURI": "/api/v1/nodes?allowWatchBookmarks=true\\u0026fieldSelector=metadata.name%3Dnode2.xiaowangc.local\\u0026resourceVersion=1207264\\u0026timeout=6m4s\\u0026timeoutSeconds=364\\u0026watch=true",				 // 请求路径
    "verb": "watch",										  	// 动作
    "user": {
        "username": "system:serviceaccount:kube-system:kube-proxy",
        "uid": "2af30a3f-64b9-4475-9efc-621b9cf356a8",
        "groups": [
            "system:serviceaccounts",
            "system:serviceaccounts:kube-system",
            "system:authenticated"
        ],
        "extra": {
            "authentication.kubernetes.io/pod-name": [
                "kube-proxy-9tc94"
            ],
            "authentication.kubernetes.io/pod-uid": [
                "79788f0f-e471-481e-b783-17c4e3c523d5"
            ]
        }
    },
    "sourceIPs": [												// 在哪台机器操作的
        "192.168.10.1"
    ],
    "userAgent": "kube-proxy/v1.25.4 (linux/amd64) kubernetes/872a965",
    "objectRef": {
        "resource": "nodes",
        "name": "node2.xiaowangc.local",
        "apiVersion": "v1"
    },
    "responseStatus": {											// 操作结果
        "metadata": {},
        "code": 200
    },
    "requestReceivedTimestamp": "2022-11-30T05:40:24.573747Z",	// 开始时间
    "stageTimestamp": "2022-11-30T05:40:24.574373Z",			// 结束时间
    "annotations": {
        "authorization.k8s.io/decision": "allow",
        "authorization.k8s.io/reason": "RBAC: allowed by ClusterRoleBinding \"kubeadm:node-proxier\" of ClusterRole \"system:node-proxier\" to ServiceAccount \"kube-proxy/kube-system\""
    }
}
```

![image-20221130140512079](image-20221130140512079.png)

**例2：**

```json
{
    "kind": "Event",
    "apiVersion": "audit.k8s.io/v1",
    "level": "Metadata",
    "auditID": "0355f932-2c04-418c-b40a-8ea0cc467917",
    "stage": "ResponseComplete",
    "requestURI": "/apis/apps/v1/namespaces/default/deployments/nginx-deployment?fieldManager=kubectl-client-side-apply\\u0026fieldValidation=Strict",
    "verb": "patch",
    "user": {
        "username": "kubernetes-admin",
        "groups": [
            "system:masters",
            "system:authenticated"
        ]
    },
    "sourceIPs": [
        "192.168.10.1"
    ],
    "userAgent": "kubectl/v1.25.4 (linux/amd64) kubernetes/872a965",
    "objectRef": {
        "resource": "deployments",
        "namespace": "default",
        "name": "nginx-deployment",
        "apiGroup": "apps",
        "apiVersion": "v1"
    },
    "responseStatus": {
        "metadata": {},
        "code": 200
    },
    "requestReceivedTimestamp": "2022-11-30T06:06:54.749969Z",
    "stageTimestamp": "2022-11-30T06:06:54.786396Z",
    "annotations": {
        "authorization.k8s.io/decision": "allow",
        "authorization.k8s.io/reason": ""
    }
}
```

