---
title: Containerd环境&Buildkit构建镜像问题
abbrlink: 291462a3
date: 2024-01-16 15:51:37
tags:
  - Containerd
  - Buildkit
categories: 容器
cover: img/fengmian/k8s.jpeg
---
# Buildkit

BuildKit 由`buildkitd`守护进程和`buildctl`客户端组成。虽然`buildctl`客户端可用于 Linux、macOS 和 Windows，但`buildkitd`守护程序目前仅适用于 Linux。

该`buildkitd`守护程序需要安装以下组件：

- runc或crun
- containerd（如果你想使用容器工作）

**按照流程正确安装完containerd上述组件都有**

## 安装Buildkit

> GIthub: https://github.com/moby/buildkit

```shell
root@master:~/app# wget https://github.com/moby/buildkit/releases/download/v0.12.4/buildkit-v0.12.4.linux-amd64.tar.gz
root@master:~/app# tar xf buildkit-v0.12.4.linux-amd64.tar.gz
root@master:~/app# mv bin/* /usr/local/sbin/
```

## 创建Systemd单元文件

```shell
root@master:~/app# vi /lib/systemd/system/buildkit.service
```

```shell
[Unit]
Description=BuildKit
Requires=buildkit.socket
After=buildkit.socket
Documentation=https://github.com/moby/buildkit

[Service]
Type=notify
ExecStart=/usr/local/sbin/buildkitd --addr fd://

[Install]
WantedBy=multi-user.target
```

```shell
root@master:~/app# vi /lib/systemd/system/buildkit.socket
```

```shell
[Unit]
Description=BuildKit
Documentation=https://github.com/moby/buildkit

[Socket]
ListenStream=%t/buildkit/buildkitd.sock
SocketMode=0660

[Install]
WantedBy=sockets.target
```

## 创建Buildkit配置文件

**buildkitd 守护进程支持两个工作后端：OCI (runc) 和 containerd。**

**默认情况下，使用 OCI (runc) 工作线程。所以需要创建配置文件让buildkitd使用containerd作为工作后端**

**否则构建镜像会出现问题，且名称空间必须是buildkit否则无法使用本地镜像进行FROM！！！**

```shell
root@master:~/app# mkdir -p /etc/buildkit/
root@master:~/app# vi /etc/buildkit/buildkitd.toml
```

```shell
[worker.oci]
  enabled = false

[worker.containerd]
  enabled = true
  namespace = "buildkit"
```

```shell
root@master:~/app# systemctl enable --now buildkit
```

## 使用本地镜像构建测试

```shell
root@master:~/app/xiaowangc/db# buildctl build  --frontend dockerfile.v0 --local context=. --local dockerfile=. --output type=image,name=harbor.xiaowangc.com/app/mysql:1.0
[+] Building 1.2s (11/11) FINISHED
 => [internal] load build definition from Dockerfile                                                                               0.0s
 => => transferring dockerfile: 421B                                                                                               0.0s
 => [internal] load metadata for docker.io/mysql/mysql-server:8.0.32                                                               1.0s
 => [internal] load .dockerignore                                                                                                  0.0s
 => => transferring context: 2B                                                                                                    0.0s
 => [1/6] FROM docker.io/mysql/mysql-server:8.0.32@sha256:d6c8301b7834c5b9c2b733b10b7e630f441af7bc917c74dba379f24eeeb6a313         0.1s
 => => resolve docker.io/mysql/mysql-server:8.0.32@sha256:d6c8301b7834c5b9c2b733b10b7e630f441af7bc917c74dba379f24eeeb6a313         0.1s
 => [internal] load build context                                                                                                  0.0s
 => => transferring context: 132B                                                                                                  0.0s
 => CACHED [2/6] RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo Asia/Shanghai > /etc/timezone                 0.0s
 => CACHED [3/6] COPY ./a.sql /docker-entrypoint-initdb.d                                                                          0.0s
 => CACHED [4/6] COPY ./b.sql /docker-entrypoint-initdb.d                                                                          0.0s
 => CACHED [5/6] COPY ./c.sql /docker-entrypoint-initdb.d                                                                          0.0s
 => CACHED [6/6] COPY ./d.sql /docker-entrypoint-initdb.d                                                                          0.0s
 => exporting to image                                                                                                             0.0s
 => => exporting layers                                                                                                            0.0s
 => => exporting manifest sha256:679dee80be7ed7d7e16a228d0a1b6877042ba1cb45b96541403ad8928e749ecd                                  0.0s
 => => exporting config sha256:16a5a4dc8b779513d756cf60a4e17caef59e21961085abafcd6ba3b81f5c2648                                    0.0s
 => => naming to harbor.xiaowangc.com/app/mysql:1.0                                                                                0.0s
```
```shell
root@master:~/app/xiaowangc/db# ctr -n buildkit i ls
REF                                TYPE                                                 DIGEST                                      SIZE      PLATFORMS   LABELS
harbor.xiaowangc.com/app/mysql:1.0 application/vnd.docker.distribution.manifest.v2+json sha256:679dee80be7ed7d7e16...               158.2 MiB linux/amd64 -
```
```shell
root@master:~/app/xiaowangc/db# cd
root@master:~# cat Dockerfile
FROM harbor.xiaowangc.com/app/mysql:1.0
CMD sleep 3600
```
```shell
root@master:~# buildctl build  --frontend dockerfile.v0 --local context=. --local dockerfile=. --output type=image,name=harbor.xiaowangc.com/app/test:1.0
[+] Building 36.8s (6/6) FINISHED
 => [internal] load build definition from Dockerfile                                                                                     0.0s
 => => transferring dockerfile: 92B                                                                                                      0.0s
 => [internal] load metadata for harbor.xiaowangc.com/app/mysql:1.0                                                                     18.4s
 => [auth] sharing credentials for harbor.xiaowangc.com                                                                                  0.0s
 => [internal] load .dockerignore                                                                                                        0.0s
 => => transferring context: 2B                                                                                                          0.0s
 => CACHED [1/1] FROM harbor.xiaowangc.com/app/mysql:1.0@sha256:679dee80be7ed7d7e16a228d0a1b6877042ba1cb45b96541403ad8928e749ecd        18.3s
 => => resolve harbor.xiaowangc.com/app/mysql:1.0@sha256:679dee80be7ed7d7e16a228d0a1b6877042ba1cb45b96541403ad8928e749ecd               18.3s
 => exporting to image                                                                                                                   0.0s
 => => exporting layers                                                                                                                  0.0s
 => => exporting manifest sha256:b54a975c33c8124d162896652b08449dc0807f5e8ebcd8b4d675caa4a39d3f2d                                        0.0s
 => => exporting config sha256:56f3e6f2916898348f2bd92ab855b56c0a57a390ac8560f998d8065550fa024e                                          0.0s
 => => naming to harbor.xiaowangc.com/app/test:1.0                                                                                       0.0s
```

