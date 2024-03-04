---
title: Kubernetes-RBAC
abbrlink: 37cc241
date: 2022-11-29 13:16:06
tags:
  - kubernetes
  - RBAC
categories: Kubernetes
cover: img/fengmian/k8s.jpeg
---
# 认证

## 证书申请信息

```text
Country Name (2 letter code) [XX]: 国家
State or Province Name (full name) []: 省
Locality Name (eg, city) [Default City]:  市
Organization Name (eg, company) [Default Company Ltd]: 组织名称
Organizational Unit Name (eg, section) []:  组织单位名称
Common Name (eg, your name or your server's hostname) []: 主机名

对应简写

C 国家

ST 省

L 城市

O 组织名称 	# 对应K8S的组名	

OU 组织单位名称

CN 主机名	 # 对应K8S的用户名
```



## 查看K8S资源

```shell
# 非名称空间级别的资源(集群资源)
[root@master1 ~]# kubectl api-resources --namespaced=false
NAME                              SHORTNAMES   APIVERSION                             NAMESPACED   KIND
componentstatuses                 cs           v1                                     false        ComponentStatus
namespaces                        ns           v1                                     false        Namespace
nodes                             no           v1                                     false        Node
persistentvolumes                 pv           v1                                     false        PersistentVolume
mutatingwebhookconfigurations                  admissionregistration.k8s.io/v1        false        MutatingWebhookConfiguration
validatingwebhookconfigurations                admissionregistration.k8s.io/v1        false        ValidatingWebhookConfiguration
customresourcedefinitions         crd,crds     apiextensions.k8s.io/v1                false        CustomResourceDefinition
...
...

# 名称空间级别的资源
[root@master1 ~]# kubectl api-resources --namespaced=true
NAME                        SHORTNAMES   APIVERSION                     NAMESPACED   KIND
bindings                                 v1                             true         Binding
configmaps                  cm           v1                             true         ConfigMap
endpoints                   ep           v1                             true         Endpoints
events                      ev           v1                             true         Event
limitranges                 limits       v1                             true         LimitRange
persistentvolumeclaims      pvc          v1                             true         PersistentVolumeClaim
pods                        po           v1                             true         Pod
podtemplates                             v1                             true         PodTemplate
replicationcontrollers      rc           v1                             true         ReplicationController
resourcequotas              quota        v1                             true         ResourceQuota
secrets                                  v1                             true         Secret
serviceaccounts             sa           v1                             true         ServiceAccount
services                    svc          v1                             true         Service
controllerrevisions                      apps/v1                        true         ControllerRevision
daemonsets                  ds           apps/v1                        true         DaemonSet
deployments                 deploy       apps/v1                        true         Deployment
replicasets                 rs           apps/v1                        true         ReplicaSet
statefulsets                sts          apps/v1                        true         StatefulSet
localsubjectaccessreviews                authorization.k8s.io/v1        true         LocalSubjectAccessReview
horizontalpodautoscalers    hpa          autoscaling/v2                 true         HorizontalPodAutoscaler
cronjobs                    cj           batch/v1                       true         CronJob
jobs                                     batch/v1                       true         Job
...
...
```

# RBAC

RBAC API声明了四种Kubernetes对象：

- Role（角色）
  1. 用于在某个名称空间内设置资源对象的访问权限，创建Role必须指定名称空间
- ClusterRole（集群角色）
  1. 定义对某个名称空间的资源对象的访问权限，并授予在某个名称空间内访问权限
  2. 为名称空间作用域的资源对象访问权限，并授予跨所有名称空间的访问权限
  3. 为集群作用域的资源对象定义访问权限

- RoleBinding（角色绑定）
- ClusterRoleBinding（集群角色绑定）

```shell
User------RoleBinding-------------Role				# 名称空间资源
授予对某一个名称空间级别资源的权限(限制在名称空间中)
User------RoleBinding-------------ClusterRole		# 名称空间资源(包含多个)
授予对多个名称空间级别资源的权限(限制在多个名称空间中,不能对集群资源进行操作)
User------ClusterRoleBinding------ClusterRole		# 集群资源
```

## 主体

- User（用户）
- Group（组）
- ServiceAccount（SA服务账号）

## **权限**

- create （创建）
- delete（删除）
- deletecollection（删除集合）
- get（获取）
- list（列出）
- patch（补丁）
- update（更新）
- watch（查看）
- *（所有）

## Role

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default	# Role必须填写名称空间
  name: pod-reader		# Role名称
rules:
- apiGroups: [""] # "" 标明 core API 组
  resources: ["pods"]		# 名称空间级别资源
  verbs: ["get", "watch", "list"]	# 权限
```

## ClusterRole

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  # "namespace" 被忽略，因为 ClusterRoles 不受名字空间限制
  name: secret-reader
rules:
- apiGroups: [""]
  # 在 HTTP 层面，用来访问 Secret 资源的名称为 "secrets"
  resources: ["secrets"]	# 名称空间级别资源 Or 使用集群资源级别
  verbs: ["get", "watch", "list"] 	# 权限
```

## RoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
# 此角色绑定允许 "jane" 读取 "default" 名字空间中的 Pod
# 你需要在该命名空间中有一个名为 “pod-reader” 的 Role
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
# 你可以指定不止一个“subject（主体）”
- kind: User
  name: jane # "name" 是区分大小写的
  apiGroup: rbac.authorization.k8s.io
roleRef:
  # "roleRef" 指定与某 Role 或 ClusterRole 的绑定关系
  kind: Role        # 此字段必须是 Role 或 ClusterRole
  name: pod-reader  # 此字段必须与你要绑定的 Role 或 ClusterRole 的名称匹配
  apiGroup: rbac.authorization.k8s.io
  
=======================================================
# 虽然是集群角色但是加了名称空间只能访问这个名称空间，除非不加名称空间就可以访问多个名称空间

apiVersion: rbac.authorization.k8s.io/v1
# 此角色绑定使得用户 "dave" 能够读取 "development" 名字空间中的 Secrets
# 你需要一个名为 "secret-reader" 的 ClusterRole
kind: RoleBinding
metadata:
  name: read-secrets
  # RoleBinding 的名字空间决定了访问权限的授予范围。
  # 这里隐含授权仅在 "development" 名字空间内的访问权限。
  namespace: development
subjects:
- kind: User
  name: dave # 'name' 是区分大小写的
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

## ClusterRoleBinding 

```yaml
apiVersion: rbac.authorization.k8s.io/v1
# 此集群角色绑定允许 “manager” 组中的任何人访问任何名字空间中的 Secret 资源
kind: ClusterRoleBinding
metadata:
  name: read-secrets-global
subjects:
- kind: Group
  name: manager      # 'name' 是区分大小写的
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

## 对资源的引用

### 子资源

```yaml
# 允许某主体读取 pods 同时访问这些 Pod 的 log 子资源
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: pod-and-pod-logs-reader
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list"]
```

### 单实例

```yaml
# 允许get or update configmaps下的my-configmap实例对象
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: configmap-updater
rules:
- apiGroups: [""]
  # 在 HTTP 层面，用来访问 ConfigMap 资源的名称为 "configmaps"
  resources: ["configmaps"]
  resourceNames: ["my-configmap"]
  verbs: ["update", "get"]
```

### 所有资源

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: example.com-superuser  
rules:
- apiGroups: [""]
  resources: ["*"]
  verbs: ["*"]
```

### API组

```yaml
# 允许对默认名称空间apps下的deployments控制器做所有操作
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: example.com-superuser
rules:
- apiGroups: ["apps"]
  # 在 HTTP 层面，用来访问 Deployment 资源的名称为 "deployments"
  resources: ["deployments"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
=============================================
# 允许对默认名称空间apps下的所有资源做所有操作
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: example.com-superuser
rules:
- apiGroups: ["apps"]
  resources: ["*"]
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
==============================================
# 只允许对指定控制器进行所有操作
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: default
  name: example.com-superuser
rules:
- apiGroups: ["apps"]
  resources: ["deployments"]
  resourcesName: ["具体deploy的名称"]			# 具体deploy控制器的名称
  verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
```

**apps包含如下资源**

```shell
[root@xiaowangc ~]# kubectl api-resources --namespaced | grep apps
controllerrevisions                      apps/v1                        true         ControllerRevision
daemonsets                  ds           apps/v1                        true         DaemonSet
deployments                 deploy       apps/v1                        true         Deployment
replicasets                 rs           apps/v1                        true         ReplicaSet
statefulsets                sts          apps/v1                        true         StatefulSet
```

## 资源查看命令

```yaml
# 名称空间级别的资源
[root@master1 ~]# kubectl api-resources --namespaced=true
# 名称空间级别的资源的权限有哪些
[root@master1 ~]# kubectl api-resources --namespaced=true -o wide
# 非名称空间级别的资源(集群资源)
[root@master1 ~]# kubectl api-resources --namespaced=false -o wide
# 非名称空间级别的资源的权限有哪些
[root@master1 ~]# kubectl api-resources --namespaced=false -o wide
```

