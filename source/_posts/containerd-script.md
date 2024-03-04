---
title: Containerd安装脚本
abbrlink: d89a6add
date: 2023-01-20 20:03:22
tags:
  - Kubernetes
  - Containerd
  - Shell
categories: Kubernetes
cover: img/fengmian/k8s.jpeg
---
# Containerd安装脚本
```shell
#/bin/bash
# install containerd script

containerd_version=1.6.15
containerd_pause_version=3.9
kubernetes_version=1.26.1-00

function install_containerd(){
    wget https://github.com/containerd/containerd/releases/download/v${containerd_version}/cri-containerd-cni-${containerd_version}-linux-amd64.tar.gz
    tar xf cri-containerd-cni-${containerd_version}-linux-amd64.tar.gz
    mkdir -p /opt/cni/bin && mkdir -p /etc/containerd
    mv ./opt/cni/bin/* /opt/cni/bin/ && mv ./usr/local/bin/* /usr/local/bin/ && mv ./usr/local/sbin/* /usr/local/sbin/ && mv ./etc/systemd/system/containerd.service /lib/systemd/system/
} 

function config_containerd(){
    /usr/local/bin/containerd config default > /etc/containerd/config.toml
    sed -i "s/SystemdCgroup = false/SystemdCgroup = true/g" /etc/containerd/config.toml
    sed -i "s/sandbox_image = \"registry.k8s.io\/pause:3.6\"/sandbox_image = \"registry.k8s.io\/pause:${containerd_pause_version}\"/g" /etc/containerd/config.toml
    systemctl enable --now containerd
    
}

function config_cri_env(){
tee > /etc/modules-load.d/k8s.conf << EOF
overlay
br_netfilter
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
EOF

modprobe overlay
modprobe br_netfilter  
modprobe ip_vs
modprobe ip_vs_rr
modprobe ip_vs_wrr
modprobe ip_vs_sh 
modprobe nf_conntrack

tee > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

sysctl --system

swapoff -a
sed -ri 's/.*swap.*/#&/' /etc/fstab
}

function install_kubernetes_google(){
    apt update
    apt-get install -y apt-transport-https ca-certificates curl
    curl -fsSLo /etc/apt/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | tee /etc/apt/sources.list.d/kubernetes.list
    apt-get update
    apt-get install -y kubelet=${kubernetes_version} kubeadm=${kubernetes_version} kubectl=${kubernetes_version}
    apt-mark hold kubelet kubeadm kubectl
    systemctl enable kubelet
}

function install_kubernetes_ali(){
apt-get update && apt-get install -y apt-transport-https
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 
    
tee > /etc/apt/sources.list.d/kubernetes.list << EOF
deb https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF

sed -i "s/sandbox_image = \"registry.k8s.io\/pause:${containerd_pause_version}\"/sandbox_image = \"registry.cn-hangzhou.aliyuncs.com\/google_containers\/pause:${containerd_pause_version}\"/g" /etc/containerd/config.toml
systemctl restart containerd.service

apt-get update
apt-get install -y kubelet=${kubernetes_version} kubeadm=${kubernetes_version} kubectl=${kubernetes_version}
apt-mark hold kubelet kubeadm kubectl
systemctl enable kubelet
}

function main(){
    install_containerd
    config_containerd
    config_cri_env
    #install_kubernetes_google
    install_kubernetes_ali
}

main
```