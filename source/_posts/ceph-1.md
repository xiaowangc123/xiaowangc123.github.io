---
title: Ceph集群-基操
tags:
  - Ceph
  - 存储
  - 文件存储
  - 对象存储
categories: Ceph
cover: img/fengmian/ceph.jpeg
abbrlink: 40095af5
date: 2023-03-30 16:19:34
---
# Ceph概念

Ceph可以为云平台提供对象存储、块存储、文件存储的开源存储系统，一个完整的Ceph集群需要一下组件：

- **监视器(Monitors)**：维护集群状态，包括监控映射、管理映射、OSD映射、MDS映射和CRUSH映射。这些Map非常重要，Ceph守护程序相互协调所需的集群状态。监视器还负责管理身份验证守护程序和客户端。

  **至少三个Monitors实现冗余和高可用**

- **Ceph Manager**：管理守护程序是负责跟踪运行时指标和当前Ceph集群的状态，包括存储利用率、性能指标和系统负载。Ceph Manager守护进程还托管基于Python的模块管理和公开Ceph集群信息，包括基于Web的Ceph仪表盘和REST API

  **通常需要两个实现高可用**

- Ceph OSD：对象存储守护进程，负责处理数据复制、恢复、重新平衡，并向Ceph提供一些监控信息通过其他Ceph OSD守护进程来监控和管理心跳。

  **至少三个实现冗余高可用**

- MDS：Ceph元数据服务器，Ceph文件系统的元数据，设备和Ceph对象存储不会使用MDS

Ceph存储集群是所有Ceph部署的基础。基于RADOS，Ceph存储集群由几种类型的守护进程组成：

- Ceph OSD守护进程：将数据作为对象存储在存储节点上
- Ceph监视器：维护集群映射的主副本
- Ceph管理器：Ceph守护进程



# 部署

**前提条件：**

- Python3
- Systemd
- Docker
- NTP/chrony（**分部署存储系统这么重要的东西你时间出问题了小心完蛋**）
- LVM2

## 环境

**配置hosts解析，且每台主机单独添加一块50GB的磁盘**

| 主机名 | IP            | OS          |
| ------ | ------------- | ----------- |
| ceph1  | 192.168.64.11 | Ubuntu22.04 |
| ceph2  | 192.168.64.12 | Ubuntu22.04 |
| ceph3  | 192.168.64.13 | Ubuntu22.04 |

## 配置时间

**所有节点都需要安装**

```shell
root@ceph1:~# apt -y install chrony
root@ceph1:~# timedatectl set-timezone Asia/Shanghai
root@ceph1:~# timedatectl status
               Local time: Mon 2023-02-13 14:19:57 CST
           Universal time: Mon 2023-02-13 06:19:57 UTC
                 RTC time: Mon 2023-02-13 06:19:58
                Time zone: Asia/Shanghai (CST, +0800)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no
```

## 安装Docker

**所有节点都需要安装**

```shell
root@ceph1:~# apt update
root@ceph1:~# apt -y install ca-certificates curl gnupg lsb-release

root@ceph1:~# mkdir -m 0755 -p /etc/apt/keyrings
root@ceph1:~# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

root@ceph1:~# echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
root@ceph1:~# apt update

root@ceph1:~# apt -y install docker-ce
root@ceph1:~# systemctl enable --now docker
```

## 安装cephadm

**所有节点都需要安装**

```shell
root@ceph1:~# apt install -y cephadm
```

## 初始化

注意：如果主机名是FQDN完全限定域名需要加`--allow-fqdn-hostname`

```shell
root@ceph1:~# cephadm bootstrap --mon-ip 192.168.64.11
Ceph Dashboard is now available at:

             URL: https://ceph1:8443/
            User: admin
        Password: 9f9jrhes6p

Enabling client.admin keyring and conf on hosts with "admin" label
Enabling autotune for osd_memory_target
You can access the Ceph CLI with:

		# 通过容器运行ceph工具
        sudo /usr/sbin/cephadm shell --fsid 5ec19d7a-ab69-11ed-9e7b-2d1a46bef9cc -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring   

Please consider enabling telemetry to help improve Ceph:

        ceph telemetry on

For more information see:

        https://docs.ceph.com/docs/master/mgr/telemetry/

Bootstrap complete.
```

## 安装客户端工具

```shell
root@ceph1:~# cephadm add-repo --release quincy
root@ceph1:~# cephadm install ceph-common
# 如果都用不了就用apt安装
root@ceph1:~# apt -y install ceph-common
```

## 加入节点

```shell
root@ceph1:~# ssh-copy-id -f -i /etc/ceph/ceph.pub ceph2
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/etc/ceph/ceph.pub"

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'ceph2'"
and check to make sure that only the key(s) you wanted were added.

root@ceph1:~# ssh-copy-id -f -i /etc/ceph/ceph.pub ceph3
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/etc/ceph/ceph.pub"

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh 'ceph3'"
and check to make sure that only the key(s) you wanted were added.

root@ceph1:~# ceph orch host add ceph2 192.168.64.12
Added host 'ceph2' with addr '192.168.64.12'
root@ceph1:~# ceph orch host add ceph2 192.168.64.13
Added host 'ceph2' with addr '192.168.64.13'
```

## 移除节点

```shell
root@ceph1:~# ceph orch host drain ceph2	# 设置节点不可调度
root@ceph1:~# ceph orch osd rm status		# 查看osd是否删除掉了
No OSD remove/replace operations reported
root@ceph1:~# ceph orch ps ceph2			# 查看ceph2是否还有守护进程
No daemons reported	
root@ceph1:~# ceph orch host rm ceph2    	# 删除节点
```

## 创建OSD

```shell
# ceph orch apply osd --all-available-devices
# 添加所有可用和未使用的设备

root@ceph1:~# ceph orch device ls		# 列出所有节点的设备
HOST   PATH      TYPE  DEVICE ID   SIZE  AVAILABLE  REFRESHED  REJECT REASONS
ceph1  /dev/sdb  hdd              53.6G  Yes        9s ago
ceph1  /dev/sdc  hdd              21.4G             9s ago     LVM detected, locked
ceph2  /dev/sdb  hdd              53.6G  Yes        15s ago
ceph2  /dev/sdc  hdd              21.4G             15s ago    LVM detected, locked
ceph3  /dev/sdb  hdd              53.6G  Yes        10s ago
ceph3  /dev/sdc  hdd              21.4G             10s ago    LVM detected, locked

root@ceph1:~# ceph orch daemon add osd ceph3.xiaowangc.local:/dev/sdb
Created osd(s) 0 on host 'ceph3.xiaowangc.local'
root@ceph1:~# ceph orch daemon add osd ceph2.xiaowangc.local:/dev/sdb
Created osd(s) 1 on host 'ceph2.xiaowangc.local'
root@ceph1:~# ceph orch daemon add osd ceph1.xiaowangc.local:/dev/sdb
Created osd(s) 2 on host 'ceph1.xiaowangc.local'
```

## 删除OSD

> 注意OSD必须保证移除后大于等于3个否则集群状态可能会有问题，由于宿主机没有ceph-volume命令需要通过cephadm shell 启动容器客户端执行

```shell
root@ceph1:~# cephadm shell --fsid 5ec19d7a-ab69-11ed-9e7b-2d1a46bef9cc -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring

root@ceph1:~# ceph orch osd rm 4
Scheduled OSD(s) for removal.
VG/LV for the OSDs won't be zapped (--zap wasn't passed).
Run the `ceph-volume lvm zap` command with `--destroy` against the VG/LV if you want them to be destroyed.

#上面这段话表明了以下几个信息：

#1.OSD 设备已经被计划移除。
#2.在移除 OSD 设备时，与这些设备相关的卷组（VG）和逻辑卷（LV）不会被删除。
#3.如果需要删除与这些 OSD 设备相关的 VG/LV，需要运行 ceph-volume lvm zap 命令，并添加 --destroy 参数。
#4.换句话说，这个命令告诉你 OSD 设备即将被删除，但是与这些设备相关的 VG/LV 不会被自动删除，如果需要彻底删除这些 VG/LV，需要运行ceph-volume lvm zap 命令，并在命令中添加 --destroy 参数。

root@ceph1:/# ceph-volume lvm zap --destroy
--> Zapping successful for OSD: None
```

## 擦除设备

```shell
# 清空设备以便重复使用
root@ceph1:/# ceph orch device zap ceph2 /dev/sdc
```

如果使用了如下命令添加新的osd

```shell
root@ceph1:/# ceph orch apply osd --all-available-devices
```

请使用如下命令设置，否则擦除后会自动创建osd

```shell
root@ceph1:/# ceph orch apply osd --all-available-devices --unmanaged=true
```

## Pool

禁止删除Ceph存储池的配置设置。这个设置可以防止误删除Ceph存储池，从而保护Ceph存储系统的安全性

```shell
root@ceph1:~# ceph config set mon mon_allow_pool_delete false # 
```

## 列出Pool

```shell
root@ceph1:~# ceph osd lspools
1 .mgr
root@ceph1:~# ceph osd pool ls
.mgr
```

## 创建Pool

```shell
root@ceph1:~# ceph osd pool create pool_cephfs_xiaowangc 16
pool 'pool_cephfs_xiaowangc' created

# cephfs rbd 
root@ceph1:~# ceph osd pool application enable pool_cephfs_xiaowangc cephfs
enabled application 'cephfs' on pool 'pool_cephfs_xiaowangc'

# 对pool做容量限制：50G
root@ceph1:~# ceph osd pool set-quota pool_cephfs_xiaowangc max_bytes 50000000000
set-quota max_bytes = 50000000000 for pool pool_cephfs_xiaowangc
```

## 删除Pool

```shell
root@ceph1:~# ceph osd pool rm pool_cephfs_xiaowangc pool_cephfs_xiaowangc --yes-i-really-really-mean-it
```



## 文件存储

```shell
root@ceph1:~# ceph fs volume create cephfs

# 直接使用上面的命令将自动创建两个pool存储池，一个是存储数据一个是存储元数据
root@ceph1:~# ceph fs status
cephfs - 0 clients
======
RANK  STATE           MDS             ACTIVITY     DNS    INOS   DIRS   CAPS
 0    active  cephfs.ceph3.ieepsg  Reqs:    0 /s    10     13     12      0
       POOL           TYPE     USED  AVAIL
cephfs.cephfs.meta  metadata  2162   94.9G
cephfs.cephfs.data    data       0   94.9G
    STANDBY MDS
cephfs.ceph1.aogolg
MDS version: ceph version 17.2.5 (98318ae89f1a893a6ded3a640405cdbb33e08757) quincy (stable)
```

## 创建文件系统

Ceph文件系统至少需要两个RADOS池，一个用于存储数据，另一个用于存储元数据，在创建和规划池的时候需要考虑：

1. 元数据池至少三个副本，因为元数据丢失会导致整个文件系统无法访问
2. 元数据因使用低延迟的存储设备(NVMe、SAS/STAT SSD)，否则会影响客户端文件系统操作的延迟
3. 数据池是存放inode backtrace信息的位置，在数据池种至少有一个对象。如果要为文件系统数据使用纠删码，最好将默认配置为复制池，以在更新回溯时提高小对象写入和读取性能

```shell
root@ceph1:~# ceph osd pool create xiaowangc_data
root@ceph1:~# ceph osd pool create xiaowangc_metadata
root@ceph1:~# ceph fs new xiaowangc xiaowangc_metadata xiaowangc_data
# ceph fs new 文件系统名称 元数据pool 数据pool
```

## 删除文件系统

```shell
root@ceph1:~# ceph fs fail xiaowangc	# 将文件系统标记为失败状态
root@ceph1:~# ceph fs rm xiaowangc --yes-i-really-mean-it
```



## 块存储

```shell
root@ceph1:~# ceph osd pool create xiaowangc
pool 'xiaowangc' created

root@ceph1:~# rbd pool init xiaowangc

root@ceph1:~# rbd create --size 1024 xiaowangc/disk1
```

### 列出块设备

```yaml
root@ceph1:~# rbd ls xiaowangc   # xiaowangc为pool池
disk1
```

### 获取副本

```shell
root@ceph1:~# ceph osd dump | grep 'replicated size'
pool 1 '.mgr' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 1 pgp_num 1 autoscale_mode on last_change 21 flags hashpspool stripe_width 0 pg_num_max 32 pg_num_min 1 application mgr
pool 6 'xiaowangc' replicated size 3 min_size 2 crush_rule 0 object_hash rjenkins pg_num 32 pgp_num 32 autoscale_mode on last_change 97 lfor 0/0/91 flags hashpspool,selfmanaged_snaps stripe_width 0 application rbd
```

## 客户端挂载

### Windows客户端

`ceph-dokan`可用于在Windows上挂载CephFS文件系统。它利用Dokany，这是一个允许在用户空间中实现文件系统的Windows驱动程序，与FUSE非常相似。

Dokany安装程序：`https://github.com/dokan-dev/dokany/releases`

MSI安装程序下载地址：`https://cloudbase.it/ceph-for-windows/`

### Linux客户端(RBD挂载方法)

> 前提需安装ceph客户端工具，文件系统也类似只不过命令不一样

在Ceph上创建用户给客户端或使用admin的也可(不安全)

```shell
# 创建一个新的用户
root@ceph1:~# ceph auth get-or-create client.Linux mon 'profile rbd' osd 'profile rbd pool=Linux' mgr 'profile rbd pool=Linux'
[client.Linux]
        key = AQAJOSVkcnJwExAA5lTKgWEnc3ZfaQUVrAVzsQ==
# 生成CEPH-CSI CONFIGMAP
root@ceph1:~# ceph mon dump
epoch 3
fsid 18733b14-ae6e-11ed-92e5-d508fed1aa63
last_changed 2023-02-17T03:07:41.879350+0000
created 2023-02-17T02:53:21.937597+0000
min_mon_release 17 (quincy)
election_strategy: 1
0: [v2:192.168.10.221:3300/0,v1:192.168.10.221:6789/0] mon.ceph1
1: [v2:192.168.10.222:3300/0,v1:192.168.10.222:6789/0] mon.ceph2
2: [v2:192.168.10.223:3300/0,v1:192.168.10.223:6789/0] mon.ceph3
dumped monmap epoch 3
```

将上述信息写入客户端中

```shell
root@client:/etc/ceph# cat ceph.client.keyring
[client.Linux]
        key = AQAJOSVkcnJwExAA5lTKgWEnc3ZfaQUVrAVzsQ==
root@client:/etc/ceph# cat ceph.conf
[global]
        fsid = 18733b14-ae6e-11ed-92e5-d508fed1aa63
        mon_host = [v2:192.168.10.221:3300/0,v1:192.168.10.221:6789/0] [v2:192.168.10.222:3300/0,v1:192.168.10.222:6789/0] [v2:192.168.10.223:3300/0,v1:192.168.10.223:6789/0]
# 获取映像        
root@kafka:~# rbd list Linux --id Linux --keyring /etc/ceph/ceph.client.keyring
disk1
# 映射块设备
root@client:/etc/ceph# rbd device map Linux/disk1 --id Linux --keyring /etc/ceph/ceph.client.keyring
/dev/rbd0

root@client:~# lsblk
NAME                      MAJ:MIN RM   SIZE RO TYPE MOUNTPOINTS
loop0                       7:0    0  63.3M  1 loop /snap/core20/1828
loop1                       7:1    0  63.3M  1 loop /snap/core20/1852
loop2                       7:2    0   103M  1 loop /snap/lxd/23541
loop3                       7:3    0 111.9M  1 loop /snap/lxd/24322
loop4                       7:4    0  49.8M  1 loop /snap/snapd/18357
loop5                       7:5    0  49.8M  1 loop /snap/snapd/18596
sda                         8:0    0    40G  0 disk
├─sda1                      8:1    0     1M  0 part
├─sda2                      8:2    0   1.8G  0 part /boot
├─sda3                      8:3    0  18.2G  0 part
│ └─ubuntu--vg-ubuntu--lv 253:0    0    30G  0 lvm  /
└─sda4                      8:4    0    20G  0 part
  └─ubuntu--vg-ubuntu--lv 253:0    0    30G  0 lvm  /
sr0                        11:0    1  1024M  0 rom
rbd0                      252:0    0     1G  0 disk
# 正常格式化并挂在(过程略过)
root@client:/etc/ceph# df -h
Filesystem                         Size  Used Avail Use% Mounted on
tmpfs                              389M  1.6M  388M   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv   30G   10G   19G  36% /
tmpfs                              1.9G     0  1.9G   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
/dev/sda2                          1.8G  253M  1.4G  16% /boot
tmpfs                              389M  4.0K  389M   1% /run/user/0
/dev/rbd0p1                        989M   24K  922M   1% /disk1

# 显示当前块设备
root@client:~# rbd device list
id  pool   namespace  image  snap  device
0   Linux             disk1  -     /dev/rbd0
```

**取消映射块设备**

```shell
root@client:~# rbd device unmap /dev/rbd/Linux/disk1
```

**自动挂载**

> 为 RBD 映像编写`/etc/fstab`条目时，最好指定“noauto”（或“nofail”）挂载选项。这可以防止 init 系统过早地尝试挂载设备——甚至在相关设备存在之前。（由于`rbdmap.service` 执行 shell 脚本，它通常在引导序列中很晚才被触发。）

```shell
root@client:~# vi /etc/ceph/rbdmap
Linux/disk1             id=Linux,keyring=/etc/ceph/ceph.client.keyring
root@client:~# systemctl enable rbdmap.service
root@client:~# vi /etc/fstab
/dev/rbd0p1     /disk1  ext4    noauto  0       0
```

# Ceph集成Kubernetes

```shell
root@ceph1:~# ceph osd pool create kubernetes
root@ceph1:~# rbd pool init kubernetes

# 创建一个新的用户
root@ceph1:~# ceph auth get-or-create client.kubernetes mon 'profile rbd' osd 'profile rbd pool=kubernetes' mgr 'profile rbd pool=kubernetes'
[client.kubernetes]
        key = AQBjLvRjZm5ZHhAAFyD/ncEfDyYA8BpqRES2Ww==
# 生成CEPH-CSI CONFIGMAP
root@ceph1:~# ceph mon dump
epoch 3
fsid 18733b14-ae6e-11ed-92e5-d508fed1aa63
last_changed 2023-02-17T03:07:41.879350+0000
created 2023-02-17T02:53:21.937597+0000
min_mon_release 17 (quincy)
election_strategy: 1
0: [v2:192.168.10.221:3300/0,v1:192.168.10.221:6789/0] mon.ceph1
1: [v2:192.168.10.222:3300/0,v1:192.168.10.222:6789/0] mon.ceph2
2: [v2:192.168.10.223:3300/0,v1:192.168.10.223:6789/0] mon.ceph3
dumped monmap epoch 3
```

```shell
root@master:~/ceph# vi csi-config-map.yaml
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ceph-csi-config
  namespace: ceph
data:
  config.json: |-
    [
      {
        "clusterID": "18733b14-ae6e-11ed-92e5-d508fed1aa63",
        "monitors": [
          "192.168.10.221:6789",
          "192.168.10.222:6789",
          "192.168.10.223:6789"
        ]
      }
    ]

```

```shell
root@master:~/ceph# kubectl apply -f csi-config-map.yaml
root@master:~/ceph# vi csi-kms-config-map.yaml
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ceph-csi-encryption-kms-config
  namespace: ceph
data:
  config.json: |-
    {}
```

```shell
root@master:~/ceph# kubectl apply -f csi-kms-config-map.yaml
root@master:~/ceph# vi ceph-config-map.yaml
```

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: ceph-config
  namespace: ceph
data:
  ceph.conf: |
    [global]
    auth_cluster_required = cephx
    auth_service_required = cephx
    auth_client_required = cephx
    # keyring is a required key and its value should be empty
  keyring: |
```

```shell
root@master:~/ceph# kubectl apply -f ceph-config-map.yaml
root@master:~/ceph# vi csi-rbd-secret.yaml
```

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: csi-rbd-secret
  namespace: ceph
stringData:
  # 这里是之前创建的kubernetes用户的key
  userID: kubernetes
  userKey: AQBjLvRjZm5ZHhAAFyD/ncEfDyYA8BpqRES2Ww==
```

```shell
root@master:~/ceph# kubectl apply -f csi-rbd-secret.yaml
```

## 鉴权

根据需求修改相应的namespace和image

```shell
https://raw.githubusercontent.com/ceph/ceph-csi/master/deploy/rbd/kubernetes/csi-provisioner-rbac.yaml
https://raw.githubusercontent.com/ceph/ceph-csi/master/deploy/rbd/kubernetes/csi-nodeplugin-rbac.yaml
https://raw.githubusercontent.com/ceph/ceph-csi/master/deploy/rbd/kubernetes/csi-rbdplugin-provisioner.yaml
https://raw.githubusercontent.com/ceph/ceph-csi/master/deploy/rbd/kubernetes/csi-rbdplugin.yaml
```

```shell
root@master:~/ceph# vi csi-provisioner-rbac.yaml
```

```yaml
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: rbd-csi-provisioner
  # replace with non-default namespace name
  namespace: ceph

---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: rbd-external-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["list", "watch", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "update", "delete", "patch"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims/status"]
    verbs: ["update", "patch"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["snapshot.storage.k8s.io"]
    resources: ["volumesnapshots"]
    verbs: ["get", "list", "patch"]
  - apiGroups: ["snapshot.storage.k8s.io"]
    resources: ["volumesnapshots/status"]
    verbs: ["get", "list", "patch"]
  - apiGroups: ["snapshot.storage.k8s.io"]
    resources: ["volumesnapshotcontents"]
    verbs: ["create", "get", "list", "watch", "update", "delete", "patch"]
  - apiGroups: ["snapshot.storage.k8s.io"]
    resources: ["volumesnapshotclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["volumeattachments"]
    verbs: ["get", "list", "watch", "update", "patch"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["volumeattachments/status"]
    verbs: ["patch"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["csinodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["snapshot.storage.k8s.io"]
    resources: ["volumesnapshotcontents/status"]
    verbs: ["update", "patch"]
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get"]
  - apiGroups: [""]
    resources: ["serviceaccounts"]
    verbs: ["get"]
  - apiGroups: [""]
    resources: ["serviceaccounts/token"]
    verbs: ["create"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: rbd-csi-provisioner-role
subjects:
  - kind: ServiceAccount
    name: rbd-csi-provisioner
    # replace with non-default namespace name
    namespace: ceph
roleRef:
  kind: ClusterRole
  name: rbd-external-provisioner-runner
  apiGroup: rbac.authorization.k8s.io

---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  # replace with non-default namespace name
  namespace: ceph
  name: rbd-external-provisioner-cfg
rules:
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get", "list", "watch", "create", "update", "delete"]
  - apiGroups: ["coordination.k8s.io"]
    resources: ["leases"]
    verbs: ["get", "watch", "list", "delete", "update", "create"]

---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: rbd-csi-provisioner-role-cfg
  # replace with non-default namespace name
  namespace: ceph
subjects:
  - kind: ServiceAccount
    name: rbd-csi-provisioner
    # replace with non-default namespace name
    namespace: ceph
roleRef:
  kind: Role
  name: rbd-external-provisioner-cfg
  apiGroup: rbac.authorization.k8s.io
```

```shell
root@master:~/ceph# kubectl apply -f csi-provisioner-rbac.yaml
root@master:~/ceph# vi csi-nodeplugin-rbac.yaml
```

```shell
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: rbd-csi-nodeplugin
  # replace with non-default namespace name
  namespace: ceph
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: rbd-csi-nodeplugin
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get"]
  # allow to read Vault Token and connection options from the Tenants namespace
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get"]
  - apiGroups: [""]
    resources: ["configmaps"]
    verbs: ["get"]
  - apiGroups: [""]
    resources: ["serviceaccounts"]
    verbs: ["get"]
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["volumeattachments"]
    verbs: ["list", "get"]
  - apiGroups: [""]
    resources: ["serviceaccounts/token"]
    verbs: ["create"]
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: rbd-csi-nodeplugin
subjects:
  - kind: ServiceAccount
    name: rbd-csi-nodeplugin
    # replace with non-default namespace name
    namespace: ceph
roleRef:
  kind: ClusterRole
  name: rbd-csi-nodeplugin
  apiGroup: rbac.authorization.k8s.io
```

```shell
root@master:~/ceph# kubectl apply -f  csi-nodeplugin-rbac.yaml
root@master:~/ceph# vi csi-rbdplugin-provisioner.yaml
```

```yaml
---
kind: Service
apiVersion: v1
metadata:
  name: csi-rbdplugin-provisioner
  # replace with non-default namespace name
  namespace: ceph
  labels:
    app: csi-metrics
spec:
  selector:
    app: csi-rbdplugin-provisioner
  ports:
    - name: http-metrics
      port: 8080
      protocol: TCP
      targetPort: 8680

---
kind: Deployment
apiVersion: apps/v1
metadata:
  name: csi-rbdplugin-provisioner
  # replace with non-default namespace name
  namespace: ceph
spec:
  replicas: 3
  selector:
    matchLabels:
      app: csi-rbdplugin-provisioner
  template:
    metadata:
      labels:
        app: csi-rbdplugin-provisioner
    spec:
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - labelSelector:
                matchExpressions:
                  - key: app
                    operator: In
                    values:
                      - csi-rbdplugin-provisioner
              topologyKey: "kubernetes.io/hostname"
      serviceAccountName: rbd-csi-provisioner
      priorityClassName: system-cluster-critical
      containers:
        - name: csi-provisioner
          image: registry.cn-shenzhen.aliyuncs.com/xiaowangc/app:7
          args:
            - "--csi-address=$(ADDRESS)"
            - "--v=1"
            - "--timeout=150s"
            - "--retry-interval-start=500ms"
            - "--leader-election=true"
            #  set it to true to use topology based provisioning
            - "--feature-gates=Topology=false"
            - "--feature-gates=HonorPVReclaimPolicy=true"
            - "--prevent-volume-mode-conversion=true"
            # if fstype is not specified in storageclass, ext4 is default
            - "--default-fstype=ext4"
            - "--extra-create-metadata=true"
          env:
            - name: ADDRESS
              value: unix:///csi/csi-provisioner.sock
          imagePullPolicy: "IfNotPresent"
          volumeMounts:
            - name: socket-dir
              mountPath: /csi
        - name: csi-snapshotter
          image: registry.cn-shenzhen.aliyuncs.com/xiaowangc/app:8
          args:
            - "--csi-address=$(ADDRESS)"
            - "--v=1"
            - "--timeout=150s"
            - "--leader-election=true"
            - "--extra-create-metadata=true"
          env:
            - name: ADDRESS
              value: unix:///csi/csi-provisioner.sock
          imagePullPolicy: "IfNotPresent"
          volumeMounts:
            - name: socket-dir
              mountPath: /csi
        - name: csi-attacher
          image: registry.cn-shenzhen.aliyuncs.com/xiaowangc/app:9
          args:
            - "--v=1"
            - "--csi-address=$(ADDRESS)"
            - "--leader-election=true"
            - "--retry-interval-start=500ms"
            - "--default-fstype=ext4"
          env:
            - name: ADDRESS
              value: /csi/csi-provisioner.sock
          imagePullPolicy: "IfNotPresent"
          volumeMounts:
            - name: socket-dir
              mountPath: /csi
        - name: csi-resizer
          image: registry.cn-shenzhen.aliyuncs.com/xiaowangc/app:10
          args:
            - "--csi-address=$(ADDRESS)"
            - "--v=1"
            - "--timeout=150s"
            - "--leader-election"
            - "--retry-interval-start=500ms"
            - "--handle-volume-inuse-error=false"
            - "--feature-gates=RecoverVolumeExpansionFailure=true"
          env:
            - name: ADDRESS
              value: unix:///csi/csi-provisioner.sock
          imagePullPolicy: "IfNotPresent"
          volumeMounts:
            - name: socket-dir
              mountPath: /csi
        - name: csi-rbdplugin
          # for stable functionality replace canary with latest release version
          image: quay.io/cephcsi/cephcsi:canary
          args:
            - "--nodeid=$(NODE_ID)"
            - "--type=rbd"
            - "--controllerserver=true"
            - "--endpoint=$(CSI_ENDPOINT)"
            - "--csi-addons-endpoint=$(CSI_ADDONS_ENDPOINT)"
            - "--v=5"
            - "--drivername=rbd.csi.ceph.com"
            - "--pidlimit=-1"
            - "--rbdhardmaxclonedepth=8"
            - "--rbdsoftmaxclonedepth=4"
            - "--enableprofiling=false"
            - "--setmetadata=true"
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
            - name: NODE_ID
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            # - name: KMS_CONFIGMAP_NAME
            #   value: encryptionConfig
            - name: CSI_ENDPOINT
              value: unix:///csi/csi-provisioner.sock
            - name: CSI_ADDONS_ENDPOINT
              value: unix:///csi/csi-addons.sock
          imagePullPolicy: "IfNotPresent"
          volumeMounts:
            - name: socket-dir
              mountPath: /csi
            - mountPath: /dev
              name: host-dev
            - mountPath: /sys
              name: host-sys
            - mountPath: /lib/modules
              name: lib-modules
              readOnly: true
            - name: ceph-csi-config
              mountPath: /etc/ceph-csi-config/
            - name: ceph-csi-encryption-kms-config
              mountPath: /etc/ceph-csi-encryption-kms-config/
            - name: keys-tmp-dir
              mountPath: /tmp/csi/keys
            - name: ceph-config
              mountPath: /etc/ceph/
            - name: oidc-token
              mountPath: /run/secrets/tokens
              readOnly: true
        - name: csi-rbdplugin-controller
          # for stable functionality replace canary with latest release version
          image: quay.io/cephcsi/cephcsi:canary
          args:
            - "--type=controller"
            - "--v=5"
            - "--drivername=rbd.csi.ceph.com"
            - "--drivernamespace=$(DRIVER_NAMESPACE)"
            - "--setmetadata=true"
          env:
            - name: DRIVER_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
          imagePullPolicy: "IfNotPresent"
          volumeMounts:
            - name: ceph-csi-config
              mountPath: /etc/ceph-csi-config/
            - name: keys-tmp-dir
              mountPath: /tmp/csi/keys
            - name: ceph-config
              mountPath: /etc/ceph/
        - name: liveness-prometheus
          image: quay.io/cephcsi/cephcsi:canary
          args:
            - "--type=liveness"
            - "--endpoint=$(CSI_ENDPOINT)"
            - "--metricsport=8680"
            - "--metricspath=/metrics"
            - "--polltime=60s"
            - "--timeout=3s"
          env:
            - name: CSI_ENDPOINT
              value: unix:///csi/csi-provisioner.sock
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
          volumeMounts:
            - name: socket-dir
              mountPath: /csi
          imagePullPolicy: "IfNotPresent"
      volumes:
        - name: host-dev
          hostPath:
            path: /dev
        - name: host-sys
          hostPath:
            path: /sys
        - name: lib-modules
          hostPath:
            path: /lib/modules
        - name: socket-dir
          emptyDir: {
            medium: "Memory"
          }
        - name: ceph-config
          configMap:
            name: ceph-config
        - name: ceph-csi-config
          configMap:
            name: ceph-csi-config
        - name: ceph-csi-encryption-kms-config
          configMap:
            name: ceph-csi-encryption-kms-config
        - name: keys-tmp-dir
          emptyDir: {
            medium: "Memory"
          }
        - name: oidc-token
          projected:
            sources:
              - serviceAccountToken:
                  path: oidc-token
                  expirationSeconds: 3600
                  audience: ceph-csi-kms
```

```shell
root@master:~/ceph# kubectl apply -f csi-rbdplugin-provisioner.yaml
root@master:~/ceph# vi csi-rbdplugin.yaml
```

```yaml
---
kind: DaemonSet
apiVersion: apps/v1
metadata:
  name: csi-rbdplugin
  # replace with non-default namespace name
  namespace: ceph
spec:
  selector:
    matchLabels:
      app: csi-rbdplugin
  template:
    metadata:
      labels:
        app: csi-rbdplugin
    spec:
      serviceAccountName: rbd-csi-nodeplugin
      hostNetwork: true
      hostPID: true
      priorityClassName: system-node-critical
      # to use e.g. Rook orchestrated cluster, and mons' FQDN is
      # resolved through k8s service, set dns policy to cluster first
      dnsPolicy: ClusterFirstWithHostNet
      containers:
        - name: driver-registrar
          # This is necessary only for systems with SELinux, where
          # non-privileged sidecar containers cannot access unix domain socket
          # created by privileged CSI driver container.
          securityContext:
            privileged: true
            allowPrivilegeEscalation: true
          image: registry.cn-shenzhen.aliyuncs.com/xiaowangc/app:11
          args:
            - "--v=1"
            - "--csi-address=/csi/csi.sock"
            - "--kubelet-registration-path=/var/lib/kubelet/plugins/rbd.csi.ceph.com/csi.sock"
          env:
            - name: KUBE_NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
          volumeMounts:
            - name: socket-dir
              mountPath: /csi
            - name: registration-dir
              mountPath: /registration
        - name: csi-rbdplugin
          securityContext:
            privileged: true
            capabilities:
              add: ["SYS_ADMIN"]
            allowPrivilegeEscalation: true
          # for stable functionality replace canary with latest release version
          image: quay.io/cephcsi/cephcsi:canary
          args:
            - "--nodeid=$(NODE_ID)"
            - "--pluginpath=/var/lib/kubelet/plugins"
            - "--stagingpath=/var/lib/kubelet/plugins/kubernetes.io/csi/"
            - "--type=rbd"
            - "--nodeserver=true"
            - "--endpoint=$(CSI_ENDPOINT)"
            - "--csi-addons-endpoint=$(CSI_ADDONS_ENDPOINT)"
            - "--v=5"
            - "--drivername=rbd.csi.ceph.com"
            - "--enableprofiling=false"
            # If topology based provisioning is desired, configure required
            # node labels representing the nodes topology domain
            # and pass the label names below, for CSI to consume and advertise
            # its equivalent topology domain
            # - "--domainlabels=failure-domain/region,failure-domain/zone"
            #
            # Options to enable read affinity.
            # If enabled Ceph CSI will fetch labels from kubernetes node and
            # pass `read_from_replica=localize,crush_location=type:value` during
            # rbd map command. refer:
            # https://docs.ceph.com/en/latest/man/8/rbd/#kernel-rbd-krbd-options
            # for more details.
            # - "--enable-read-affinity=true"
            # - "--crush-location-labels=topology.io/zone,topology.io/rack"
          env:
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
            - name: NODE_ID
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            - name: POD_NAMESPACE
              valueFrom:
                fieldRef:
                  fieldPath: metadata.namespace
            # - name: KMS_CONFIGMAP_NAME
            #   value: encryptionConfig
            - name: CSI_ENDPOINT
              value: unix:///csi/csi.sock
            - name: CSI_ADDONS_ENDPOINT
              value: unix:///csi/csi-addons.sock
          imagePullPolicy: "IfNotPresent"
          volumeMounts:
            - name: socket-dir
              mountPath: /csi
            - mountPath: /dev
              name: host-dev
            - mountPath: /sys
              name: host-sys
            - mountPath: /run/mount
              name: host-mount
            - mountPath: /etc/selinux
              name: etc-selinux
              readOnly: true
            - mountPath: /lib/modules
              name: lib-modules
              readOnly: true
            - name: ceph-csi-config
              mountPath: /etc/ceph-csi-config/
            - name: ceph-csi-encryption-kms-config
              mountPath: /etc/ceph-csi-encryption-kms-config/
            - name: plugin-dir
              mountPath: /var/lib/kubelet/plugins
              mountPropagation: "Bidirectional"
            - name: mountpoint-dir
              mountPath: /var/lib/kubelet/pods
              mountPropagation: "Bidirectional"
            - name: keys-tmp-dir
              mountPath: /tmp/csi/keys
            - name: ceph-logdir
              mountPath: /var/log/ceph
            - name: ceph-config
              mountPath: /etc/ceph/
            - name: oidc-token
              mountPath: /run/secrets/tokens
              readOnly: true
        - name: liveness-prometheus
          securityContext:
            privileged: true
            allowPrivilegeEscalation: true
          image: quay.io/cephcsi/cephcsi:canary
          args:
            - "--type=liveness"
            - "--endpoint=$(CSI_ENDPOINT)"
            - "--metricsport=8680"
            - "--metricspath=/metrics"
            - "--polltime=60s"
            - "--timeout=3s"
          env:
            - name: CSI_ENDPOINT
              value: unix:///csi/csi.sock
            - name: POD_IP
              valueFrom:
                fieldRef:
                  fieldPath: status.podIP
          volumeMounts:
            - name: socket-dir
              mountPath: /csi
          imagePullPolicy: "IfNotPresent"
      volumes:
        - name: socket-dir
          hostPath:
            path: /var/lib/kubelet/plugins/rbd.csi.ceph.com
            type: DirectoryOrCreate
        - name: plugin-dir
          hostPath:
            path: /var/lib/kubelet/plugins
            type: Directory
        - name: mountpoint-dir
          hostPath:
            path: /var/lib/kubelet/pods
            type: DirectoryOrCreate
        - name: ceph-logdir
          hostPath:
            path: /var/log/ceph
            type: DirectoryOrCreate
        - name: registration-dir
          hostPath:
            path: /var/lib/kubelet/plugins_registry/
            type: Directory
        - name: host-dev
          hostPath:
            path: /dev
        - name: host-sys
          hostPath:
            path: /sys
        - name: etc-selinux
          hostPath:
            path: /etc/selinux
        - name: host-mount
          hostPath:
            path: /run/mount
        - name: lib-modules
          hostPath:
            path: /lib/modules
        - name: ceph-config
          configMap:
            name: ceph-config
        - name: ceph-csi-config
          configMap:
            name: ceph-csi-config
        - name: ceph-csi-encryption-kms-config
          configMap:
            name: ceph-csi-encryption-kms-config
        - name: keys-tmp-dir
          emptyDir: {
            medium: "Memory"
          }
        - name: oidc-token
          projected:
            sources:
              - serviceAccountToken:
                  path: oidc-token
                  expirationSeconds: 3600
                  audience: ceph-csi-kms
---
# This is a service to expose the liveness metrics
apiVersion: v1
kind: Service
metadata:
  name: csi-metrics-rbdplugin
  # replace with non-default namespace name
  namespace: ceph
  labels:
    app: csi-metrics
spec:
  ports:
    - name: http-metrics
      port: 8080
      protocol: TCP
      targetPort: 8680
  selector:
    app: csi-rbdplugin
```

```shell
root@master:~/ceph# kubectl apply -f csi-rbdplugin.yaml
root@master:~/ceph# vi csi-rbd-sc.yaml
```

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
   name: csi-rbd-sc
provisioner: rbd.csi.ceph.com
parameters:
   clusterID: 18733b14-ae6e-11ed-92e5-d508fed1aa63			# Ceph集群ID
   pool: kubernetes											# Pool
   imageFeatures: layering
   csi.storage.k8s.io/provisioner-secret-name: csi-rbd-secret
   csi.storage.k8s.io/provisioner-secret-namespace: ceph				# 注意名称空间
   csi.storage.k8s.io/controller-expand-secret-name: csi-rbd-secret
   csi.storage.k8s.io/controller-expand-secret-namespace: ceph			# 注意名称空间
   csi.storage.k8s.io/node-stage-secret-name: csi-rbd-secret
   csi.storage.k8s.io/node-stage-secret-namespace: ceph					# 注意名称空间
reclaimPolicy: Delete
allowVolumeExpansion: true
mountOptions:
   - discard
```

```shell
root@master:~/ceph# kubectl apply -f csi-rbd-sc
storageclass.storage.k8s.io/csi-rbd-sc created
root@master:~/ceph# kubectl get sc
NAME         PROVISIONER        RECLAIMPOLICY   VOLUMEBINDINGMODE   ALLOWVOLUMEEXPANSION   AGE
csi-rbd-sc   rbd.csi.ceph.com   Delete          Immediate           true                   3s
```



