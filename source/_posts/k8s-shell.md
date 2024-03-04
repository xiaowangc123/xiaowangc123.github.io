---
title: k8s安装1.23.6脚本
date: '2022-04-17 16:28'
tags:
  - kubernetes
categories: Kubernetes
cover: img/fengmian/k8s.jpeg
abbrlink: 8b15daa1
---
## 脚本

适用于1.23.6版本

```shell
#!/bin/bash
function set_repo() {
echo "开始配置存储库..."
echo "清空默认存储库..."
sleep 2
rm -rf /etc/yum.repos.d/*.repo
echo "安装基础存储库..."
sleep 2
curl -o /etc/yum.repos.d/a.repo https://mirrors.aliyun.com/repo/Centos-vault-8.5.2111.repo
echo "安装k8s存储库..."
sleep 2
tee > /etc/yum.repos.d/kubernetes.repo << EOF
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64/
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg
EOF
echo "安装Docker-CE存储库..."
sleep 2
curl -o /etc/yum.repos.d/docker-ce.repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
}

function set_env() {
echo "关闭SeLinux..."
sleep 2
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
echo "永久关闭交换分区..."
sleep 2
swapoff -a
sed -ri 's/.*swap.*/#&/' /etc/fstab
echo "桥接流量..."
sleep 2
tee > /etc/modules-load.d/k8s.conf << EOF
br_netfilter
EOF
tee > /etc/sysctl.d/k8s.conf << EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl --system
echo "永久关闭Firewalld防火墙..."
sleep 2
systemctl disable --now firewalld
}

function install_software() {
echo "安装Docker-CE..."
sleep 2
dnf -y install docker-ce --allowerasing
echo "设置Docker开机自启并启动Docker..."
sleep 2
systemctl enable --now docker
echo "配置Docker..."
sleep 2
mkdir /etc/docker/
touch /etc/docker/daemon.json
tee > /etc/docker/daemon.json << EOF
{
 	"exec-opts":["native.cgroupdriver=systemd"]
}
EOF
systemctl daemon-reload
systemctl restart docker
sleep 2
echo "设置Docker开机自启并启动Docker..."
echo "安装K8S组件..."
sleep 2
dnf -y install kubelet-1.23.6 kubeadm-1.23.6 kubectl-1.23.6
echo "设置Kubelet自启..."
sleep 2
systemctl enable kubelet
}

function conf_k8smaster() {
echo "开始初始化K8S集群..."
sleep 2
read -p "请输入本机IP地址:" IP
read -p "请输入pod网络(x.x.x.x/x)：" PODIP
read -p "请输入Server网络(x.x.x.x/x)：" SRVIP
read -p "确认输入正确? [y/n] " input
case $input in
        [yY]*)
        		echo "开始初始化集群..."
                sleep 2
                echo "此过程可能需要几分钟请耐心等待..."
                kubeadm init --apiserver-advertise-address=$IP --pod-network-cidr=$PODIP --service-cidr=$SRVIP --image-repository=registry.cn-hangzhou.aliyuncs.com/ --kubernetes-version 1.23.6 google_containers > /root/.k8s.info
                export KUBECONFIG=/etc/kubernetes/admin.conf
                echo "请在客户端安装环境后输入如下命令加入集群！"
                echo "=================================="
                tail -n 2 /root/.k8s.info
                echo "=================================="
                echo "Master初始化完毕"
                
                ;;
        [nN]*)
				conf_k8s
				clear
                ;;
        *)
                echo "请手动初始化..."
                exit
                ;;
esac

}

function conf_k8snode(){
echo "正在下载组件！"
sleep 2
echo "请耐心等待，这个过程可能需要几分钟..."
kubeadm config images pull --image-repository=registry.cn-hangzhou.aliyuncs.com/google_containers
echo "Master初始化完毕!"
echo "接下来请输入Master生成的令牌将节点加入K8S集群"
}

function set_master_node() {
echo "
----------------------
1.初始化Master环境
2.初始化Node环境
"
read -p "请选择：" setMN
case $setMN in
        1*)
        		set_repo
				set_env
				install_software
				conf_k8smaster
                ;;
        2*)
				set_repo
				set_env
				install_software
				conf_k8snode
                ;;
        *)
                echo "脚本退出..."
                exit
                ;;
esac
}

function main() {
	echo "请确保CPU2大于两核，内存大于2G，否则初始化会报错！"
	sleep 3
	set_master_node
}

main

```
