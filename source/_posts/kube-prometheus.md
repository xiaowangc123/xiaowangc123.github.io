---
title: Kube-Prometheus
tags:
  - kubernetes
  - kube-Prometheus
  - Prometheus
  - 监控
categories: Kubernetes
cover: img/fengmian/k8s.jpeg
abbrlink: c50ce44c
date: 2023-12-26 16:50:11
---
## Kubernetes集群监控

使用Prometheus Operator通过Prometheus提供易于操作的端到端Kubernetes集群监控

该软件包中包含的组件

- The Prometheus Operator
- Highly availavle Prometheus
- Highly available Alertmanager
- Prometheus node-exporter
- Prometheus Adapter for Kubernetes
- kube-state-metrics
- Grafana

## 前提条件

需要一个Kubernetes集群，kubelet配置必须包含以下标志：

- `--authentication-token-webhook=true`此标志使`ServiceAccount`令牌可用于针对`kubelet`进行身份验证
- `--authorization-mode=Webhook`此标志使`kubelet`将使用API执行RBAC请求，以确定是否允许请求实体访问资源，特别是对本项目的端点`/metrics`。也可以通过将`kubelet`配置值设置为`authorization.mode` `webhook`来启用此功能

**验证方式：**

> 默认就已经配置了，但需进行确认一下

```shell
root@master:~# cat /var/lib/kubelet/config.yaml
apiVersion: kubelet.config.k8s.io/v1beta1
authentication:
  anonymous:
    enabled: false		# 默认关闭匿名访问
  webhook:
    cacheTTL: 0s
    enabled: true		# 开启webhook认证
  x509:
    clientCAFile: /etc/kubernetes/pki/ca.crt
authorization:
  mode: Webhook			# 认证模式webhook
  webhook:
    cacheAuthorizedTTL: 0s
    cacheUnauthorizedTTL: 0s
cgroupDriver: systemd
clusterDNS:
- 172.12.0.10
```

## 兼容性

> 注意：对于 Kubernetes v1.21.z 之前的版本，请参阅[Kubernetes 兼容性矩阵](https://github.com/prometheus-operator/kube-prometheus/blob/main/README.md#compatibility)以选择兼容分支

以下 Kubernetes 版本受支持，并且在我们在各自分支中针对这些版本进行测试时可以正常工作。但请注意，其他版本也可能有效！

| kube-prometheus stack                                        | Kubernetes 1.22 | Kubernetes 1.23 | Kubernetes 1.24 | Kubernetes 1.25 | Kubernetes 1.26 | Kubernetes 1.27 | Kubernetes 1.28 |
| ------------------------------------------------------------ | --------------- | --------------- | --------------- | --------------- | --------------- | --------------- | --------------- |
| [`release-0.10`](https://github.com/prometheus-operator/kube-prometheus/tree/release-0.10) | ✔               | ✔               | ✗               | ✗               | x               | x               | x               |
| [`release-0.11`](https://github.com/prometheus-operator/kube-prometheus/tree/release-0.11) | ✗               | ✔               | ✔               | ✗               | x               | x               | x               |
| [`release-0.12`](https://github.com/prometheus-operator/kube-prometheus/tree/release-0.12) | ✗               | ✗               | ✔               | ✔               | x               | x               | x               |
| [`release-0.13`](https://github.com/prometheus-operator/kube-prometheus/tree/release-0.13) | ✗               | ✗               | ✗               | x               | ✔               | ✔               | ✔               |
| [`main`](https://github.com/prometheus-operator/kube-prometheus/tree/main) | ✗               | ✗               | ✗               | x               | x               | ✔               | ✔               |

## 部署

**注意事项：**

1. **默认Prometheus和Grafana是没有做数据持久化的**
2. **默认部署在monitoring名称空间下**
3. **默认是无法从其他名称空间访问**
4. **某些环境原因或镜像国内可能无法拉取的自行替换或使用其他方法**

```shell
root@master:~# git clone https://github.com/prometheus-operator/kube-prometheus.git
Cloning into 'kube-prometheus'...
remote: Enumerating objects: 19144, done.
remote: Counting objects: 100% (5747/5747), done.
remote: Compressing objects: 100% (440/440), done.
remote: Total 19144 (delta 5503), reused 5366 (delta 5288), pack-reused 13397
Receiving objects: 100% (19144/19144), 10.11 MiB | 8.38 MiB/s, done.
Resolving deltas: 100% (12948/12948), done.
root@master:~# cd kube-prometheus/
root@master:~/kube-prometheus# kubectl apply --server-side -f manifests/setup
customresourcedefinition.apiextensions.k8s.io/alertmanagerconfigs.monitoring.coreos.com serverside-applied
customresourcedefinition.apiextensions.k8s.io/alertmanagers.monitoring.coreos.com serverside-applied
customresourcedefinition.apiextensions.k8s.io/podmonitors.monitoring.coreos.com serverside-applied
customresourcedefinition.apiextensions.k8s.io/probes.monitoring.coreos.com serverside-applied
customresourcedefinition.apiextensions.k8s.io/prometheuses.monitoring.coreos.com serverside-applied
customresourcedefinition.apiextensions.k8s.io/prometheusagents.monitoring.coreos.com serverside-applied
customresourcedefinition.apiextensions.k8s.io/prometheusrules.monitoring.coreos.com serverside-applied
customresourcedefinition.apiextensions.k8s.io/scrapeconfigs.monitoring.coreos.com serverside-applied
customresourcedefinition.apiextensions.k8s.io/servicemonitors.monitoring.coreos.com serverside-applied
customresourcedefinition.apiextensions.k8s.io/thanosrulers.monitoring.coreos.com serverside-applied
namespace/monitoring serverside-applied
root@master:~/kube-prometheus# kubectl wait --for condition=Established --all CustomResourceDefinition --namespace=monitoring
# 使用wait命令等待CustomResourceDefinition资源状态都变为“Established”状态，当所有资源状态正常后此命令才结束
customresourcedefinition.apiextensions.k8s.io/addresspools.metallb.io condition met
customresourcedefinition.apiextensions.k8s.io/alertmanagerconfigs.monitoring.coreos.com condition met
customresourcedefinition.apiextensions.k8s.io/alertmanagers.monitoring.coreos.com condition met
customresourcedefinition.apiextensions.k8s.io/bfdprofiles.metallb.io condition met
customresourcedefinition.apiextensions.k8s.io/bgpadvertisements.metallb.io condition met
customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.org condition met
...
...
...
root@master:~/kube-prometheus# kubectl apply -f manifests/
alertmanager.monitoring.coreos.com/main created
networkpolicy.networking.k8s.io/alertmanager-main created
poddisruptionbudget.policy/alertmanager-main created
...
...
...
root@master:~/kube-prometheus# kubectl  get pod -n monitoring
NAME                                   READY   STATUS    RESTARTS   AGE
alertmanager-main-0                    2/2     Running   0          2m19s
alertmanager-main-1                    2/2     Running   0          2m19s
alertmanager-main-2                    2/2     Running   0          2m19s
blackbox-exporter-76b5c44577-w6nfk     3/3     Running   0          3m34s
grafana-69f6b485b9-csxlx               1/1     Running   0          3m34s
kube-state-metrics-cff77f89d-7694m     3/3     Running   0          3m34s
node-exporter-2vth4                    2/2     Running   0          3m33s
node-exporter-fpcfx                    2/2     Running   0          3m33s
node-exporter-g6fzm                    2/2     Running   0          3m33s
node-exporter-q79x4                    2/2     Running   0          3m33s
prometheus-adapter-74894c5547-6gjhs    1/1     Running   0          3m33s
prometheus-adapter-74894c5547-gjn8n    1/1     Running   0          3m33s
prometheus-k8s-0                       2/2     Running   0          2m10s
prometheus-k8s-1                       2/2     Running   0          2m10s
prometheus-operator-57757d758c-86l79   2/2     Running   0          3m33s
```

## 访问UI

```shell
root@master:~/kube-prometheus# kubectl --namespace monitoring port-forward svc/prometheus-k8s --address 192.168.66.10 9090
Forwarding from 192.168.66.10:9090 -> 9090
# 使用master的ip+9090转发到Prometheus
```

**其他服务同上**

![68470d5d652c8419c38d59803e79a2be](68470d5d652c8419c38d59803e79a2be.png)

## 使用Ingress暴露

```shell
root@master:~/kube-prometheus# vi manifests/prometheus-networkPolicy.yaml
```

```yaml
kind: NetworkPolicy
metadata:
  labels:
    app.kubernetes.io/component: prometheus
    app.kubernetes.io/instance: k8s
    app.kubernetes.io/name: prometheus
    app.kubernetes.io/part-of: kube-prometheus
    app.kubernetes.io/version: 2.48.1
  name: prometheus-k8s
  namespace: monitoring
spec:
  egress:
  - {}
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: prometheus
    ports:
    - port: 9090
      protocol: TCP
    - port: 8080
      protocol: TCP
  - from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: prometheus-adapter
    ports:
    - port: 9090
      protocol: TCP
  - from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/name: grafana
    ports:
    - port: 9090
      protocol: TCP
  - from:
    - podSelector:
        matchLabels:
          app.kubernetes.io/instance: ingress-nginx		# 在pod标签中新增，允许ingress控制器访问Prometheus
    ports:
    - port: 9090
      protocol: TCP
  podSelector:
    matchLabels:
      app.kubernetes.io/component: prometheus
      app.kubernetes.io/instance: k8s
      app.kubernetes.io/name: prometheus
      app.kubernetes.io/part-of: kube-prometheus
  policyTypes:
  - Egress
  - Ingress
```

```shell
root@master:~/kube-prometheus# kubectl apply -f manifests/prometheus-networkPolicy.yaml
root@master:~/kube-prometheus# vi ~/prometheus.yaml
```

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: prometheus
  namespace: monitoring
spec:
  rules:
  - host: prometheus.xiaowangc.com
    http:
      paths:
      - pathType: Prefix
        path: "/"
        backend:
          service:
            name: prometheus-k8s
            port:
              number: 9090
```

```shell
root@master:~/kube-prometheus# kubectl apply ~/prometheus.yaml
root@master:~# kubectl get ingress -n monitoring
NAME         CLASS   HOSTS                      ADDRESS          PORTS   AGE
prometheus   nginx   prometheus.xiaowangc.com   192.168.66.220   80      158m
```

![bda85049bd3dc9f1bdda4e2de1e5c99d](bda85049bd3dc9f1bdda4e2de1e5c99d.png)

