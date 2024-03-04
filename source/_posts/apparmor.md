---
title: Kubernetes-AppArmor
abbrlink: e72cab47
date: 2022-12-02 11:39:40
tags:
  - kubernetes
  - AppArmor
  - CKS
  - 安全
categories: Kubernetes
cover: img/fengmian/avatar.png
---
# Linux强制访问控制系统

**AppArmor(Application Armor)**是Linux内核的一个安全模块，AppAromor允许系统管理员将每个程序与一个安全配置文件关联，从而限制程序的功能。AppArmor是与SELinux类似的一个访问控制系统，通过它可以**指定程序可以读、写或运行哪些文件，是否可以打开网络端口等**。作为对传统Unix的自主访问控制模块的补充，AppAromor提供了强制访问控制机制。

AppArmor 可以配置为任何应用程序减少潜在的攻击面，并且提供更加深入的防御，AppArmor 可以通过限制允许容器执行的操作， 和通过系统日志提供更好的审计来帮助你运行更安全的部署

## 工作模式

Apparmor有两种工作模式：

- enforcing（强制模式）

  遵循配置文件的规则限制，阻止访问不允许访问的资源

- complain（警告模式）

  遵循配置文件的规则限制，对访问禁止的资源发出警告但不做限制

  

## 测试

**Kubernetes版本不低于v1.4，CentOS不支持AppArmor**

- 查看AppArmor是否开启

  ```shell
  root@node3:~# cat /sys/module/apparmor/parameters/enabled
  Y
  root@node3:~# aa-status
  apparmor module is loaded.
  30 profiles are loaded.
  30 profiles are in enforce mode.
  ```

- 确保节点的AppArmor都处于运行状态

  ```shell
  [root@master1 ~]# kubectl get nodes -o=jsonpath='{range .items[*]}{@.metadata.name}: {.status.conditions[?(@.reason=="KubeletReady")].message}{"\n"}{end}'
  master1.xiaowangc.local: kubelet is posting ready status
  master2.xiaowangc.local: kubelet is posting ready status
  master3.xiaowangc.local: kubelet is posting ready status
  node1.xiaowangc.local: kubelet is posting ready status
  node2.xiaowangc.local: kubelet is posting ready status
  node3.xiaowangc.local: kubelet is posting ready status. AppArmor enabled
  node4.xiaowangc.local: kubelet is posting ready status. AppArmor enabled
  
  # 我这里集群一开始是在CentOS8上部署的高可用Kubernetes,为了测试才加入两台Ubuntu节点
  [root@master1 ~]# kubectl get node -o wide
  NAME                      STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION              CONTAINER-RUNTIME
  master1.xiaowangc.local   Ready    control-plane   8d    v1.25.4   192.168.10.1    <none>        CentOS Linux 8       4.18.0-305.3.1.el8.x86_64   docker://20.10.21
  master2.xiaowangc.local   Ready    control-plane   8d    v1.25.4   192.168.10.2    <none>        CentOS Linux 8       4.18.0-305.3.1.el8.x86_64   docker://20.10.21
  master3.xiaowangc.local   Ready    control-plane   8d    v1.25.4   192.168.10.3    <none>        CentOS Linux 8       4.18.0-305.3.1.el8.x86_64   docker://20.10.21
  node1.xiaowangc.local     Ready    nodes           8d    v1.25.4   192.168.10.11   <none>        CentOS Linux 8       4.18.0-305.3.1.el8.x86_64   docker://20.10.21
  node2.xiaowangc.local     Ready    nodes           8d    v1.25.4   192.168.10.12   <none>        CentOS Linux 8       4.18.0-305.3.1.el8.x86_64   docker://20.10.21
  node3.xiaowangc.local     Ready    <none>          11h   v1.25.4   192.168.10.13   <none>        Ubuntu 22.04.1 LTS   5.15.0-43-generic           docker://20.10.21
  node4.xiaowangc.local     Ready    <none>          11h   v1.25.4   192.168.10.14   <none>        Ubuntu 22.04.1 LTS   5.15.0-43-generic           docker://20.10.21
  ```

- 在所有Ubuntu节点上加载AppArmor配置

  ```shell
  [root@node3 ~]# apparmor_parser -q <<EOF
  #include <tunables/global>
  
  profile k8s-apparmor-deny-write flags=(attach_disconnected) {
    #include <abstractions/base>
    file,
    deny /** w,
  }
  EOF
  
  # 查看是否加载
  root@node3:~# cat /sys/kernel/security/apparmor/profiles | grep k8s-apparmor-deny-write
  k8s-apparmor-deny-write (enforce)
  ```

- 创建Pod测试

  ```shell
  [root@master1 ~]# cat busybox-test.yaml
  apiVersion: v1
  kind: Pod
  metadata:
    name: hello-apparmor
    labels:
      app: nginx
    annotations:
      container.apparmor.security.beta.kubernetes.io/test: localhost/k8s-apparmor-deny-write
      # 表示对nginx容器应用本地的k8s-apparmor-deny-write策略
  spec:
    nodeName: node3.xiaowangc.local			# 由于Pod的创建是通过调度器可能不会调度到Ubuntu节点，我就直接使用节点选择器测试
    containers:
    - name: test
      image: busybox
      command: ["sh", "-c", "echo 'Hello xiaowangc!' && sleep 1h"]
      
  [root@master1 ~]# kubectl apply -f busybox-test.yaml
  pod/hello-apparmor created
  
  [root@master1 ~]# kubectl get pod -o wide
  NAME             READY   STATUS    RESTARTS   AGE   IP              NODE                    NOMINATED NODE   READINESS GATES
  hello-apparmor   1/1     Running   0          32s   172.21.33.134   node3.xiaowangc.local   <none>           <none>
  
  [root@master1 ~]# kubectl exec hello-apparmor -- cat /proc/1/attr/current
  # 查看是否加载了Apparmor配置
  k8s-apparmor-deny-write (enforce)
  
  [root@master1 ~]# kubectl exec hello-apparmor -- touch /tmp/test
  # 写入测试文件可以看到被拒绝访问了
  touch: /tmp/test: Permission denied
  command terminated with exit code 1
  ```

  