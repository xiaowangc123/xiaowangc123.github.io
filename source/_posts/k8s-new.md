---
title: docker安装k8s 1.24+
abbrlink: 847c320a
date: 2022-11-23 15:35:26
tags:
  - kubernetes
categories: Kubernetes
cover: img/fengmian/k8s.jpeg
---
```shell
# 正常安装Docker并配置sysstemd驱动,K8S前置条件基本不变除了Docker环节
[root@master1 ~]# cat /etc/docker/daemon.json
{
        "exec-opts":["native.cgroupdriver=systemd"],
        "registry-mirrors": ["https://vrm5w46o.mirror.aliyuncs.com"],
        "insecure-registries": ["https://harbor.xiaowangc.local"]
}

# 下载cri-docker,我这里环境是CentOS8所以直接用rpm安装
cri-docker地址: https://github.com/Mirantis/cri-dockerd/

[root@master1 ~]# wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.2.6/cri-dockerd-0.2.6-3.el8.x86_64.rpm
[root@master1 ~]# dnf -y install cri-dockerd-0.2.6-3.el8.x86_64.rpm

# 修改pause版本  1.24.x版本应该用的是3.6  我这里是1.25.x所以改成3.8
[root@master1 ~]# vi /lib/systemd/system/cri-docker.service
...
[Service]
Type=notify
ExecStart=/usr/bin/cri-dockerd --container-runtime-endpoint fd:// --pod-infra-container-image=registry.cn-hangzhou.aliyuncs.com/google_containers/pause:3.8
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutSec=0
RestartSec=2
Restart=always
...

[root@master1 ~]# systemctl enable --now cri-docker

# 初始化
[root@master1 ~]# kubeadm init --control-plane-endpoint api.xiaowangc.local:16443 \
--upload-certs --apiserver-advertise-address 192.168.10.1 \
--pod-network-cidr 172.21.0.0/16 --service-cidr 172.22.0.0/16 \
--image-repository registry.cn-hangzhou.aliyuncs.com/google_containers \
--cri-socket unix:///run/cri-dockerd.sock
```