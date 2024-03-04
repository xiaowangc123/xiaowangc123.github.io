---
title: Kubernetes-RuntimeClass
abbrlink: 9da39c32
date: 2022-12-06 09:56:23
tags:
  - kubernetes
  - RuntimeClass
categories: Kubernetes
cover: img/fengmian/k8s.jpeg
---
# RuntimeClass

![](architecture.png)

RuntimeClass 是一个用于选择容器运行时配置的特性，容器运行时配置用于运行 Pod 中的容器。

容器技术是通过namespace、cgroups等技术对进程实现隔离，相比于虚拟化，容器更小更快。传统虚拟化技术，通过虚拟化一套硬件并在这硬件上安装操作系统OS和部署应用程序。每个虚拟机都拥有属于自己的内核，虚拟机中病毒或被入侵对宿主机的影响较小。而容器和宿主机是共享内核，一旦容器被入侵、逃逸、中病毒等，会对宿主机产生较大影响。

RuntimeClass就是为了解决以上问题，也有称RuntimeClass为沙箱(沙箱容器)。Runtime主要有：

- **runC**

  根据OCI规范生成的运行容器的Runtime，且作为Containerd runtime的默认配置类型

  ![img](1.png)

  

- **Crun**

  使用C语言开发兼容OCI规范用于运行容器的Runtime，具有快速轻量、低内存占用等

- **gVisor（runSC）**

  由Google开源使用Go语言编写的Application内核，其包含一个兼容OCI规范的Runtime（runSC），用于在应用程序和主机内核之间提供隔离边界；runSC开源与主流的容器运行时Docker、Containerd、CRI-O、Kubernetes集成。gVisor提供了一个虚拟化环境，以便对容器进行沙盒处理

  ![img](2.png)

- **Kata**

  KataContainers是一个开源项目和社区，致力于构建轻量级虚拟机的标准实现；kata用于运行根据OCI规范打包的容器

![image-20221206095145816](3.png)

# 安装步骤

1. 在gVirsor官网根据教程部署runSC

   官网：[gvisor](https://gvisor.dev/)

   下载：[Github](https://github.com/containerd/containerd)

   containerd-1.6.10-linux-amd64.tar.gz 仅包含Containerd

   cri-containerd-1.6.10-linux-amd64.tar.gz 包含runC，Containerd

   cri-containerd-cni-1.6.10-linux-amd64.tar.gz	包含runC，Containerd，CNI

   ```shell
   [root@xiaowangc ~]# tar Cxzvf /usr/local containerd-1.6.2-linux-amd64.tar.gz
   [root@xiaowangc ~]# install -m 755 runc.amd64 /usr/local/sbin/runc
   [root@xiaowangc ~]# mkdir -p /opt/cni/bin
   [root@xiaowangc ~]# tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tgz
   ```

   

2. 通过配置Containerd的配置文件设置gvisor

   ```shell
   # 如果/etc/containerd/下没有文件通过命令containerd config default > config.toml生成
   
   # 在config.toml添加runtimes
   [plugins."io.containerd.grpc.v1.cri".containerd.runtimes]
   
     [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]		# 默认runtime
       base_runtime_spec = ""
       cni_conf_dir = ""
       cni_max_conf_num = 0
       container_annotations = []
       pod_annotations = []
       privileged_without_host_devices = false
       runtime_engine = ""
       runtime_path = ""
       runtime_root = ""
       runtime_type = "io.containerd.runc.v2"
   
       [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
         BinaryName = ""
         CriuImagePath = ""
         CriuPath = ""
         CriuWorkPath = ""
         IoGid = 0
         IoUid = 0
         NoNewKeyring = false
         NoPivotRoot = false
         Root = ""
         ShimCgroup = ""
         SystemdCgroup = true
     [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runsc]		# 新增runSC需要注意这里的名字要和k8s的handler一致(runsc)
       runtime_type = "io.containerd.runsc.v1"
   ```

3. 修改后重启containerd

4. 创建RuntimeClass

   ```yaml
   apiVersion: node.k8s.io/v1
   kind: RuntimeClass
   metadata:
     name: gvisor		# 自定义
   handler: runsc		# 要与Containerd配置的名字一致
   ```

5. 创建RuntimeClass

   ```shell
   [root@xiaowangc ~]# kubectl apply -f gvisor.yaml
   runtimeclass.node.k8s.io/gvisor create
   
   [root@xiaowangc ~]# kubectl get runtimeclass
   NAME     HANDLER   AGE
   gvisor   runsc     150m
   ```

6. 指定Pod在RuntimeClass(沙箱)中运行

   ```yaml
   apiVersion: v1
   kind: Pod
   metadata:
     name: mypod
   spec:
     nodeName: node1.xiaowangc.local
     runtimeClassName: gvisor				# 指定RuntimeClass的name
     containers:
     - name: nginx
       image: nginx
   ```

7. 部署

   ```shell
   [root@master1 runtimeClass]# kubectl get pod
   NAME    READY   STATUS    RESTARTS   AGE
   mypod   1/1     Running   0          132m
   
   [root@master1 runtimeClass]# kubectl describe pod mypod | grep Class
   Runtime Class Name:  gvisor
   ```

   