---
title: Docker基础
date: '2022-04-01 23:10'
tags: Docker
cover: img/fengmian/docker.jpeg
categories: 容器
abbrlink: 1d9fbb6a
---
# Docker学习

# Docker概念

## Docker基本概念

###### Docker 是一个开源的应用容器引擎，让开发者可以打包他们的应用以及依赖包到一个可移植的容器中,然后发布到任何流行的Linux或Windows操作系统的机器上,也可以实现虚拟化,容器是完全使用沙箱机制,相互之间不会有任何接口。

###### Linux操作系统本身从系统层面就支持虚拟化技术LXC，LXC有三大特色：

- **cgroup**

  ###### Linux Cgroups (Control Groups ）提供了对组进程及将来子进程的资源限制、控制和统计的能力，这些资源包括 CPU、内存、存储、网络等 通过 Cgroups ，可以方便地限制某个进程的资源占用，并且可以实时地监控进程的监控和统计信息

- **namespace**

  ###### Linux Namespace是Kernel的一个功能，它可以隔离一系列的系统资源，比如PID、UserID、Netwokr等。

- **unionFS**

  ###### Union File System(UnionFS): 将其他文件系统联合到一个联合挂载点的文件系统服务。它使用branch把不同文件系统的文件和目录透明的覆盖，形成一个单一一致的文件系统，当对这个联合文件系统进行写操作时，系统是真正写到了一个新的文件中，这个虚拟后的联合文件系统是可以对任何文件进行操作的，但是它并没有改变原来的文件，因为unionfs用到了一个重要的资源管理技术，叫做写时复制。

  ###### **写时复制(Copy-on-write,CoW)**: 是一种对可修改的资源实现高校复制的资源管理技术。它的思想是，如果一个资源是重复的没有任何修改，这时并不需要立即创建一个新的资源，这个资源可以被新旧实例共享。创建新资源发生在第一次写操作，也就是对资源进行修改的时候。通过这种资源共享的方式，可以显著地减少未修改资源复制带来的消耗，但是资源也会在进行资源修改时增加小部分的开销。

  

## 虚拟化技术

### 虚拟化分类

- SaaS(软件即服务)

  > SaaS，是Software-as-a-Service的缩写名称，意思为软件即服务，即通过网络提供软件服务；简单来说用户需要使用某款软件直接双击进行运行，无需对软件进行下载安装等等。由SaaS进行提供，例如Office365

  - 各互联网的应用

- PaaS(平台即服务)

  > PaaS是（Platform as a Service）的缩写，是指平台即服务。 把服务器平台作为一种服务提供的商业模式，通过网络进行程序提供的服务称之为SaaS;简单来说就是通过互联网提供：(虚拟化)硬件+(各种)软件环境平台，例如做开发无需自行构建系统+编译环境，由PaaS进行提供。

  - Docker
  - LXC
  - OpenShitf

- IaaS(基础设施即服务)

  > IaaS（Infrastructure as a Service），即基础设施即服务。指把IT基础设施作为一种服务通过网络对外提供；简单来说就是通过网络向用户提供一套基础的硬件设施(CPU、内存、主板、网卡.....)。常见的如阿里云的云服务器，在购买时选择各种的硬件配置...
  
  - 阿里云ECS

### 传统虚拟化与容器

- 传统虚拟技术：

  ###### 通过虚拟化技术模拟出一整套硬件设施，然后在此基础上安装一套完整的操作系统，并在这个系统上面安装和运行软件

- 容器技术：

  ###### 直接运行在宿主机的内核，容器是没有自己的内核；每个容器都是互相隔离互不影响，每个容器都有自己的文件系统

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202112/2242444-20211218065435728-1516959397.png)


# Docker安装部署

## Docker的基本组成

- **仓库(Repository)：**
  - 用于存放镜像的地方；
  - 仓库分类：
    - 公有仓库：Docker_Hub、阿里云等
    - 私有仓库：自行创建
- **镜像(Image)：**
  - Docker镜像类似一个模板，可以通过模板进行创建容器
  - 一个镜像可以创建多个容器
- **容器(Container)：**
  - 利用容器技术，独立运行一个或一组应用，通过镜像来进行创建

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202112/2242444-20211218065715035-942358671.png)


## Docker安装

### 准备系统环境

- 操作系统
  - 操作系统：RedHat8.4(CentOS亦可)
  - CPU：x4
  - 内存：4GB
  - 内核：4.18.0-305.el8.x86_64

```shell
[root@node1 ~]# uname -a
Linux node1 4.18.0-305.el8.x86_64 #1 SMP Thu Apr 29 08:54:30 EDT 2021 x86_64 x86_64 x86_64 GNU/Linux
[root@node1 ~]# cat /etc/redhat-release
Red Hat Enterprise Linux release 8.4 (Ootpa)
[root@node1 ~]# free -h
              total        used        free      shared  buff/cache   available
Mem:          3.6Gi       327Mi       3.0Gi       9.0Mi       285Mi       3.1Gi
Swap:         2.0Gi          0B       2.0Gi
[root@node1 ~]# lscpu | grep Core
Core(s) per socket:  4
```

### 卸载旧版本

> 如果有安装旧版本先进行卸载，我这是全新的系统所以不用执行以下操作

```shell
[root@node1 ~]# dnf remove docker\
docker-client\
docker-client-latest\
docker-common\
docker-latest\
docker-logrotate\
docker-engine

Updating Subscription Management repositories.
Unable to read consumer identity

This system is not registered to Red Hat Subscription Management. You can use subscription-manager to register.

No match for argument: dockerdocker-clientdocker-client-latestdocker-commondocker-latestdocker-logrotatedocker-engine
No packages marked for removal.
Dependencies resolved.
Nothing to do.
Complete!
[root@node1 ~]#
```

### 安装方式

> Docker的安装方法有主要有3中，本文档主要介绍在线安装

- 设置Docker的存储库并从中进行安装，以便后续进行升级
- 下载RPM包进行手动安装或升级，在无法访问互联网的情况下使用
- 在特殊环境中使用自动化进行安装Docker

### 使用存储库进行在线安装

- 设置存储库

  > 由于国外镜像站速度鸡肋，这里我们使用阿里云的镜像

  ```shell
  [root@node1 ~]# wget -O /etc/yum.repos.d/docker-ce.repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
  --2021-12-09 01:38:19--  https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
  Resolving mirrors.aliyun.com (mirrors.aliyun.com)... 110.188.28.225, 110.188.28.226, 110.188.28.230, ...
  Connecting to mirrors.aliyun.com (mirrors.aliyun.com)|110.188.28.225|:443... connected.
  HTTP request sent, awaiting response... 200 OK
  Length: 1919 (1.9K) [application/octet-stream]
  Saving to: ‘/etc/yum.repos.d/docker-ce.repo’
  
  /etc/yum.repos.d/docker-ce.re 100%[=================================================>]   1.87K  --.-KB/s    in 0s
  
  2021-12-09 01:38:19 (53.8 MB/s) - ‘/etc/yum.repos.d/docker-ce.repo’ saved [1919/1919]
  
  [root@node1 ~]# dnf makecache
  Updating Subscription Management repositories.
  Unable to read consumer identity
  
  This system is not registered to Red Hat Subscription Management. You can use subscription-manager to register.
  
  Docker CE Stable - x86_64                                                                12 kB/s |  19 kB     00:01
  Metadata cache created.
  [root@node1 ~]#
  ```

- 安装Docker引擎

  ```shell
  # 由于我的RedHat8.4存在Podman、cockpit等软件包与Docker有冲突所以加了--allowerasing参数
  [root@node1 ~]# dnf -y install docker-ce docker-ce-cli containerd.io --allowerasing
    ...
    Verifying        : buildah-1.19.7-1.module+el8.4.0+10607+f4da7515.x86_64                                          6/9
    Verifying        : cockpit-podman-29-2.module+el8.4.0+10607+f4da7515.noarch                                       7/9
    Verifying        : podman-3.0.1-6.module+el8.4.0+10607+f4da7515.x86_64                                            8/9
    Verifying        : podman-catatonit-3.0.1-6.module+el8.4.0+10607+f4da7515.x86_64                                  9/9
  Installed products updated.
  
  Installed:
    containerd.io-1.4.12-3.1.el8.x86_64 docker-ce-3:20.10.11-3.el8.x86_64 docker-ce-rootless-extras-20.10.11-3.el8.x86_64
    libcgroup-0.41-19.el8.x86_64
  Removed:
    buildah-1.19.7-1.module+el8.4.0+10607+f4da7515.x86_64  cockpit-podman-29-2.module+el8.4.0+10607+f4da7515.noarch
    podman-3.0.1-6.module+el8.4.0+10607+f4da7515.x86_64    podman-catatonit-3.0.1-6.module+el8.4.0+10607+f4da7515.x86_64
  
  Complete!
  [root@node1 ~]#
  ```

- 启动并设置Docker为开机自启

  ```shell
  [root@node1 ~]# systemctl enable --now docker
  Created symlink /etc/systemd/system/multi-user.target.wants/docker.service → /usr/lib/systemd/system/docker.service.
  [root@node1 ~]#
  ```

- 查看Docker版本

  ```shell
  [root@node1 ~]# docker version
  Client: Docker Engine - Community
   Version:           20.10.11
   API version:       1.41
   Go version:        go1.16.9
   Git commit:        dea9396
   Built:             Thu Nov 18 00:36:58 2021
   OS/Arch:           linux/amd64
   Context:           default
   Experimental:      true
  
  Server: Docker Engine - Community
   Engine:
    Version:          20.10.11
    API version:      1.41 (minimum version 1.12)
    Go version:       go1.16.9
    Git commit:       847da18
    Built:            Thu Nov 18 00:35:20 2021
    OS/Arch:          linux/amd64
    Experimental:     false
   containerd:
    Version:          1.4.12
    GitCommit:        7b11cfaabd73bb80907dd23182b9347b4245eb5d
   runc:
    Version:          1.0.2
    GitCommit:        v1.0.2-0-g52b36a2
   docker-init:
    Version:          0.19.0
    GitCommit:        de40ad0
  [root@node1 ~]#
  ```

- 测试Docker

  ```shell
  [root@node1 ~]# docker run hello-world
  Unable to find image 'hello-world:latest' locally
  latest: Pulling from library/hello-world
  2db29710123e: Pull complete
  Digest: sha256:cc15c5b292d8525effc0f89cb299f1804f3a725c8d05e158653a563f15e4f685
  Status: Downloaded newer image for hello-world:latest
  
  Hello from Docker!
  # 此消息显示您的安装似乎工作正常。
  This message shows that your installation appears to be working correctly.
  # 为了生成此消息，Docker采取了以下步骤：
  To generate this message, Docker took the following steps:
  # Docker客户端已联系Docker守护程序。
   1. The Docker client contacted the Docker daemon.
  # Docker守护进程从Docker中心提取“hello world”映像。（amd64）
   2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
      (amd64)
  # Docker守护进程从运行生成当前正在读取的输出的可执行文件。
   3. The Docker daemon created a new container from that image which runs the
      executable that produces the output you are currently reading.
  # Docker守护进程将该输出流式传输到Docker客户端，后者将其发送到你的终点站
   4. The Docker daemon streamed that output to the Docker client, which sent it
      to your terminal.
  
  To try something more ambitious, you can run an Ubuntu container with:
   $ docker run -it ubuntu bash
  
  Share images, automate workflows, and more with a free Docker ID:
   https://hub.docker.com/
  
  For more examples and ideas, visit:
   https://docs.docker.com/get-started/
  
  [root@node1 ~]#
  ```



## 卸载Docker

> 如需卸载请按照如下步骤

- 卸载 Docker Engine、CLI 和 Containerd 包：

  ```shell
  dnf -y remove docker-ce docker-ce-cli containerd.io
  ```

- 主机上的映像、容器、卷或自定义配置文件不会自动删除。删除所有镜像、容器和卷：

  ```shell
  rm -rf /var/lib/docker
  rm -rf /var/lib/containerd
  ```



# Docker命令



> 掌握本图片的命令以及常用参数算是掌握Docker常用操作了

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202112/2242444-20211218065737234-1183832367.png)





- 帮助命令

  ```shell
  docker version # 显示版本信息
  docker info # 显示docker系统详细信息
  docker 命令 --help # 显示命令的详细帮助
  ```

- docker命令

  ```shell
  [root@node1 ~]# docker
  #docker命令格式
  #docker [可选选项] 命令
  Usage:  docker [OPTIONS] COMMAND
  
  A self-sufficient runtime for containers
  # 选项
  Options:
  	  					   # 客户端配置文件地址(默认在"/root/.docker")
        --config string      Location of client config files (default "/root/.docker")
        					   # 用于连接到守护进程的上下文的名称
    -c, --context string     Name of the context to use to connect to the daemon (overrides DOCKER_HOST env var and
                             default context set with "docker context use")
                             # 开启调试模式
    -D, --debug              Enable debug mode
    						   # 连接到的守护程序套接字
    -H, --host list          Daemon socket(s) to connect to
    						   # 设置日志记录级别（“调试”|“信息”|“警告”|“错误”|“致命”）（默认为“信息”）
    -l, --log-level string   Set the logging level ("debug"|"info"|"warn"|"error"|"fatal") (default "info")
  						   # 使用TLS证书
  	  --tls                Use TLS; implied by --tlsverify
        					   # 仅由此CA签署的信任证书
        --tlscacert string   Trust certs signed only by this CA (default "/root/.docker/ca.pem")
  						   # TLS证书文件的路径(默认在"/root/.docker/cert.pem")
  	  --tlscert string     Path to TLS certificate file (default "/root/.docker/cert.pem")
  	  					   # TLS密钥文件的路径(默认在"/root/.docker/key.pem")
        --tlskey string      Path to TLS key file (default "/root/.docker/key.pem")
        					   # 使用TLS并验证远程
        --tlsverify          Use TLS and verify the remote
        					   # 打印版本信息并退出
    -v, --version            Print version information and quit
  
  # 管理命令
  Management Commands:
    app*        Docker App (Docker Inc., v0.9.1-beta3)	# Docker应用
    builder     Manage builds		# 管理构建
    buildx*     Build with BuildKit (Docker Inc., v0.6.3-docker)		# 使用BuildKit构建
    config      Manage Docker configs		# 管理Docker配置
    container   Manage containers 	#管理容器
    context     Manage contexts 	# 管理上下文
    image       Manage images		# 管理镜像
    manifest    Manage Docker image manifests and manifest lists 	# 管理Docker映像清单和清单列表
    network     Manage networks	# 管理网络
    node        Manage Swarm nodes	# 管理群集节点
    plugin      Manage plugins 	# 管理插件
    scan*       Docker Scan (Docker Inc., v0.9.0) 	# Docker扫描
    secret      Manage Docker secrets 	# 管理Docker机密
    service     Manage services 	# 管理服务
    stack       Manage Docker stacks 	# 管理Docker堆栈
    swarm       Manage Swarm 	# 管理群集
    system      Manage Docker # 管理Docker
    trust       Manage trust on Docker images 	# 管理对Docker映像的信任
    volume      Manage volumes 	# 管理卷
  
  # 命令
  Commands:
  			  # 将本地标准输入、输出和错误流附加到正在运行的容器
    attach      Attach local standard input, output, and error streams to a running container
    build       Build an image from a Dockerfile	# 从Dockerfile生成映像
    commit      Create a new image from a container's changes	 # 根据容器的更改创建新图像
    			  # 在容器和本地文件系统之间复制文件/文件夹
    cp          Copy files/folders between a container and the local filesystem
    create      Create a new container 	# 创建一个新容器
    			  # 检查对容器文件系统上的文件或目录的更改
    diff        Inspect changes to files or directories on a container's filesystem
    events      Get real time events from the server  # 从服务器获取实时事件
    exec        Run a command in a running container	# 在正在运行的容器中运行命令
    export      Export a container's filesystem as a tar archive	# 将容器的文件系统导出为tar归档
    history     Show the history of an image	# 显示镜像的历史记录
    images      List images	# 列出镜像
    import      Import the contents from a tarball to create a filesystem image	# 从tarball导入内容以创建文件系统映像
    info        Display system-wide information	# 显示系统范围的信息
    inspect     Return low-level information on Docker objects	# 返回有关Docker对象的低级信息
    kill        Kill one or more running containers	# 杀死一个或多个正在运行的容器
    load        Load an image from a tar archive or STDIN	# 从tar存档或STDIN加载镜像
    login       Log in to a Docker registry	# 登录到Docker注册表
    logout      Log out from a Docker registry	# 从Docker注册表注销
    logs        Fetch the logs of a container		# 获取容器的日志
    pause       Pause all processes within one or more containers		# 暂停一个或多个容器中的所有进程
    port        List port mappings or a specific mapping for the container		# 列出容器的端口映射或特定映射
    ps          List containers		# 列出容器
    pull        Pull an image or a repository from a registry		# 从注册表中提取镜像或存储库
    push        Push an image or a repository to a registry		# 将镜像或存储库推送到注册表
    rename      Rename a container		# 重命名容器
    restart     Restart one or more containers		# 重新启动一个或多个容器
    rm          Remove one or more containers			# 移除一个或多个容器
    rmi         Remove one or more images			# 删除一个或多个镜像
    run         Run a command in a new container		# 在新容器中运行命令
    			  # 将一个或多个镜像保存到tar存档（默认情况下流式传输到stdout）
    save        Save one or more images to a tar archive (streamed to STDOUT by default)
    search      Search the Docker Hub for images	# 在Docker Hub中搜索镜像
    start       Start one or more stopped containers		# 启动一个或多个停止的容器
    stats       Display a live stream of container(s) resource usage statistics	# 显示容器资源使用统计信息的实时流
    stop        Stop one or more running containers		# 停止一个或多个正在运行的容器
    tag         Create a tag TARGET_IMAGE that refers to SOURCE_IMAGE		# 创建引用源镜像的标记目标镜像;给镜像打标签
    top         Display the running processes of a container		# 显示容器的运行进程
    unpause     Unpause all processes within one or more containers		# 取消暂停一个或多个容器中的所有进程
    update      Update configuration of one or more containers		# 更新一个或多个容器的配置
    version     Show the Docker version information		# 显示Docker版本信息
                # 阻止，直到一个或多个容器停止，然后打印其出口代码
    wait        Block until one or more containers stop, then print their exit codes	
  
  # 有关命令的详细信息，请运行“docker 命令 --help”。
  Run 'docker COMMAND --help' for more information on a command.
  [root@node1 ~]#
  ```



## 镜像命令

- docker images	

  > 查询本地所有的镜像

  ```shell
  [root@node1 ~]# docker images
  # 存储库		标签		 镜像ID		   创建时间        大小
  REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
  hello-world   latest    feb5d9fea6a5   2 months ago   13.3kB
  [root@node1 ~]# docker images --help
  
  Usage:  docker images [OPTIONS] [REPOSITORY[:TAG]]
  
  List images
  
  Options:
    -a, --all             Show all images (default hides intermediate images)		# 显示所有镜像
        --digests         Show digests	# 显示摘要
    -f, --filter filter   Filter output based on conditions provided
        --format string   Pretty-print images using a Go template		# 根据提供的条件筛选输出
        --no-trunc        Don't truncate output		# 不要截断输出
    -q, --quiet           Only show image IDs		# 仅显示镜像ID
  [root@node1 ~]#
  ```

- docker search

  > 搜索镜像命令

  ```shell
  [root@node1 ~]# docker search nginx
  #镜像名称						    描述											   星星		正式的		自动化
  NAME                              DESCRIPTION                                     STARS     OFFICIAL   AUTOMATED
  nginx                             Official build of Nginx.                        15928     [OK]
  jwilder/nginx-proxy               Automated Nginx reverse proxy for docker con…   2101                 [OK]
  richarvey/nginx-php-fpm           Container running Nginx + PHP-FPM capable of…   820                  [OK]
  jc21/nginx-proxy-manager          Docker container for managing Nginx proxy ho…   288
  linuxserver/nginx                 An Nginx container, brought to you by LinuxS…   160
  tiangolo/nginx-rtmp               Docker image with Nginx using the nginx-rtmp…   147                  [OK]
  jlesage/nginx-proxy-manager       Docker container for Nginx Proxy Manager        145                  [OK]
  alfg/nginx-rtmp                   NGINX, nginx-rtmp-module and FFmpeg from sou…   111                  [OK]
  nginxdemos/hello                  NGINX webserver that serves a simple page co…   79                   [OK]
  privatebin/nginx-fpm-alpine       PrivateBin running on an Nginx, php-fpm & Al…   61                   [OK]
  nginx/nginx-ingress               NGINX and  NGINX Plus Ingress Controllers fo…   57
  nginxinc/nginx-unprivileged       Unprivileged NGINX Dockerfiles                  55
  nginxproxy/nginx-proxy            Automated Nginx reverse proxy for docker con…   29
  staticfloat/nginx-certbot         Opinionated setup for automatic TLS certs lo…   25                   [OK]
  nginx/nginx-prometheus-exporter   NGINX Prometheus Exporter for NGINX and NGIN…   22
  schmunk42/nginx-redirect          A very simple container to redirect HTTP tra…   19                   [OK]
  centos/nginx-112-centos7          Platform for running nginx 1.12 or building …   16
  centos/nginx-18-centos7           Platform for running nginx 1.8 or building n…   13
  bitwarden/nginx                   The Bitwarden nginx web server acting as a r…   11
  flashspys/nginx-static            Super Lightweight Nginx Image                   11                   [OK]
  mailu/nginx                       Mailu nginx frontend                            9                    [OK]
  sophos/nginx-vts-exporter         Simple server that scrapes Nginx vts stats a…   7                    [OK]
  ansibleplaybookbundle/nginx-apb   An APB to deploy NGINX                          3                    [OK]
  wodby/nginx                       Generic nginx                                   1                    [OK]
  arnau/nginx-gate                  Docker image with Nginx with Lua enabled on …   1                    [OK]
  
  [root@node1 ~]# docker search --help
  
  Usage:  docker search [OPTIONS] TERM
  
  Search the Docker Hub for images
  
  Options:
    -f, --filter filter   Filter output based on conditions provided		# 根据提供的条件筛选输出
        --format string   Pretty-print search using a Go template
        --limit int       Max number of search results (default 25)	# 最大搜索结果数（默认值25）
        --no-trunc        Don't truncate output		# 不要截断输出
        
  [root@node1 ~]# docker search tomcat -f STARS=1000		# 根据条件进行筛选
  NAME      DESCRIPTION                                     STARS     OFFICIAL   AUTOMATED
  tomcat    Apache Tomcat is an open source implementati…   3193      [OK]
  [root@node1 ~]#
  ```
  
- docker pull

  > 下载镜像

  ```shell
  [root@node1 ~]# docker pull
  "docker pull" requires exactly 1 argument.
  See 'docker pull --help'.
  
  Usage:  docker pull [OPTIONS] NAME[:TAG|@DIGEST]
  
  Pull an image or a repository from a registry
  
  [root@node1 ~]# docker pull --help
  
  #用法: docker pull [选项] NAME[:Tag|@DIGEST]		# []表示可选可不选 
  Usage:  docker pull [OPTIONS] NAME[:TAG|@DIGEST]
  
  Pull an image or a repository from a registry
  
  Options:
    -a, --all-tags                Download all tagged images in the repository	# 下载存储库中所有标记的镜像
        --disable-content-trust   Skip image verification (default true) # 跳过镜像验证（默认为开启）
        							# 如果服务器支持多平台，则设置平台
        --platform string         Set platform if server is multi-platform capable
    -q, --quiet                   Suppress verbose output	# 抑制详细输出
    
  [root@node1 ~]#
  [root@node1 ~]# docker pull mysql
  Using default tag: latest		# 使用默认标记：最新
  latest: Pulling from library/mysql	# 最新版本：从库/mysql中提取
  ffbb094f4f9e: Pull complete			# 分层下载，Docker的核心，联合文件系统
  df186527fc46: Pull complete	
  fa362a6aa7bd: Pull complete
  5af7cb1a200e: Pull complete
  949da226cc6d: Pull complete
  bce007079ee9: Pull complete
  eab9f076e5a3: Pull complete
  8a57a7529e8d: Pull complete
  b1ccc6ed6fc7: Pull complete
  b4af75e64169: Pull complete
  3aed6a9cd681: Pull complete
  23390142f76f: Pull complete
  Digest: sha256:ff9a288d1ecf4397967989b5d1ec269f7d9042a46fc8bc2c3ae35458c1a26727	# 摘要校验
  Status: Downloaded newer image for mysql:latest		# 状态：已下载mysql的较新镜像：最新
  docker.io/library/mysql:latest		# 真实地址
  [root@node1 ~]#
  [root@node1 ~]# docker pull mysql:5.7	# 指定版本下载,一定是官方有支持的版本！
  5.7: Pulling from library/mysql
  ffbb094f4f9e: Already exists		# Already exists表示已经存在
  df186527fc46: Already exists
  fa362a6aa7bd: Already exists
  5af7cb1a200e: Already exists
  949da226cc6d: Already exists
  bce007079ee9: Already exists
  eab9f076e5a3: Already exists
  c7b24c3f27af: Pull complete
  6fc26ff6705a: Downloading [=============>                                     ]   29.4MB/108.6MB
  6fc26ff6705a: Pull complete
  bec5cdb5e7f7: Pull complete
  6c1cb25f7525: Pull complete
  Digest: sha256:d1cc87a3bd5dc07defc837bc9084f748a130606ff41923f46dec1986e0dc828d
  Status: Downloaded newer image for mysql:5.7
  docker.io/library/mysql:5.7
  [root@node1 ~]#
  ```

- docker images

  > 查看本机镜像

  ```shell
  [root@node1 ~]# docker images
  #存储库		#标签		#镜像ID		  # 创建时间		# 大小
  REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
  mysql         5.7       738e7101490b   8 days ago     448MB
  mysql         latest    bbf6571db497   8 days ago     516MB
  hello-world   latest    feb5d9fea6a5   2 months ago   13.3kB
  [root@node1 ~]#
  [root@node1 ~]# docker images --help
  
  Usage:  docker images [OPTIONS] [REPOSITORY[:TAG]]
  
  List images
  
  Options:
  						# 显示所有镜像（默认隐藏中间镜像）
    -a, --all             Show all images (default hides intermediate images)
        --digests         Show digests	# 显示摘要
    -f, --filter filter   Filter output based on conditions provided	# 根据提供的条件筛选输出
        --format string   Pretty-print images using a Go template	# 使用Go模板打印镜像
        --no-trunc        Don't truncate output		# 不要截断输出
    -q, --quiet           Only show image IDs		# 仅显示镜像ID
    
  ```

- docker rmi

  > 删除镜像

  ```shell
  [root@node1 ~]# docker images	# 查询镜像
  REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
  mysql         5.7       738e7101490b   8 days ago     448MB
  mysql         latest    bbf6571db497   8 days ago     516MB
  hello-world   latest    feb5d9fea6a5   2 months ago   13.3kB
  [root@node1 ~]# docker rmi 738	# 删除镜像id为738开头的
  Untagged: mysql:5.7
  Untagged: mysql@sha256:d1cc87a3bd5dc07defc837bc9084f748a130606ff41923f46dec1986e0dc828d
  Deleted: sha256:738e7101490b45decf606211a5437ed87aa6a82f1ff03c354564bf9375ce20f9
  Deleted: sha256:addad8cfeac97b96eb6652a576269346ac96def9a6709ed2388e24fff4345837
  Deleted: sha256:e288c3439a7e2f423f50bf22979a759371c51a70bbbaa450993c336978460b1a
  Deleted: sha256:33ece15accaa3bb20e3dee84e2e4501469b917c3abba3d5475cd1fec8bb3e82c
  Deleted: sha256:6b15390bceeca8424d82e75f5c9aca5eb4693f96849d6382168a99747877693d
  [root@node1 ~]# docker images		# 查询镜像发现镜像id738开头的mysql5.7已经被删除了
  REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
  mysql         latest    bbf6571db497   8 days ago     516MB
  hello-world   latest    feb5d9fea6a5   2 months ago   13.3kB
  [root@node1 ~]#
  [root@node1 ~]# docker rmi --help
  
  Usage:  docker rmi [OPTIONS] IMAGE [IMAGE...]
  
  Remove one or more images
  
  Options:
    -f, --force      Force removal of the image	# 强制删除镜像
        --no-prune   Do not delete untagged parents	# 不要删除未标记的父项
  ```

  ```shell
  # 批量删除所有镜像 $(将查询出镜像作为rmi的输入)
  [root@node1 ~]# docker rmi -f $(docker images -qa)
  Untagged: mysql:latest
  Untagged: mysql@sha256:ff9a288d1ecf4397967989b5d1ec269f7d9042a46fc8bc2c3ae35458c1a26727
  Deleted: sha256:bbf6571db4977fe13c3f4e6289c1409fc6f98c2899eabad39bfe07cad8f64f67
  Deleted: sha256:a72da99dce60d6f8d4c4cffa4173153c990537fcdfaa27c35324c3348d55dd5c
  Deleted: sha256:8b535d432ef2fbd45d93958347b2587c5cbe334f07d6909ad9d2d480ebbafb65
  Deleted: sha256:14d13a3b33fc76839f156cd24b4636dab121e6d3d026cefa2985a4b89e9d4df8
  Deleted: sha256:77c21a5a897a1ba752f3d742d6c94ee7c6b0e373fd0aeecc4bf88b9a3982007e
  Deleted: sha256:189162becec8bb4588c54fb4ea7e62d20121812e68aeb0291fb4bb5df9ec0985
  Deleted: sha256:34980dadfd6a5bb9d7f9e8d4e408000e0a8f4840cc7d3092dc94357ebe7a89b6
  Deleted: sha256:15b2beb64a91785c8f3709ecd2410d13577b3174faad164524434ce6a7633506
  Deleted: sha256:e38dd14d47b61171927ea4b928f7296123b65a81ad1cfde8f5d00cadf1e81bbb
  Deleted: sha256:865abdfd8444741f581ce582e4ac5746c4a00c282febf65aa808a235ec7abf78
  Deleted: sha256:b1e35233e1ac953bd06fc8fa83afb3a88c39c1aeae0c89a46cb1b652d6821b38
  Deleted: sha256:3bcfdf6641227ff63e3ddf9e38e45cf317b178a50a664e45c6ae596107d5bc46
  Deleted: sha256:f11bbd657c82c45cc25b0533ce72f193880b630352cc763ed0c045c808ff9ae1
  Untagged: hello-world:latest
  Untagged: hello-world@sha256:cc15c5b292d8525effc0f89cb299f1804f3a725c8d05e158653a563f15e4f685
  Deleted: sha256:feb5d9fea6a5e9606aa995e879d862b825965ba48de054caab5ef356dc6b3412
  [root@node1 ~]#
  # 删除多个镜像
  [root@node1 ~]# docker rmi 镜像id1 镜像id2 ...
  ```

  

## 容器命令

> 在创建容器之前，得先下载一个镜像

```shell
[root@node1 ~]# docker pull centos
Using default tag: latest
latest: Pulling from library/centos
a1d0c7532777: Pull complete
Digest: sha256:a27fd8080b517143cbbbab9dfb7c8571c40d67d534bbdee55bd6c473f432b177
Status: Downloaded newer image for centos:latest
docker.io/library/centos:latest
[root@node1 ~]#
```

- docker run

  > 运行容器

  ```shell
  [root@node1 ~]# docker run --help
  
  Usage:  docker run [OPTIONS] IMAGE [COMMAND] [ARG...]
  
  Run a command in a new container
  
  Options:
        --add-host list                  Add a custom host-to-IP mapping (host:ip)	# 添加自定义主机到IP映射（主机：IP）
    -a, --attach list                    Attach to STDIN, STDOUT or STDERR	# 连接到标准输入、标准输出或标准输出
    									   # 块IO（相对权重），介于10和1000之间，或0禁用（默认为0）
        --blkio-weight uint16            Block IO (relative weight), between 10 and 1000, or 0 to disable (default 0)
        								   # 块IO权重（相对设备权重）（默认值[]）
        --blkio-weight-device list       Block IO weight (relative device weight) (default [])
        --cap-add list                   Add Linux capabilities	# 添加Linux功能
        --cap-drop list                  Drop Linux capabilities	# 放弃Linux功能
        --cgroup-parent string           Optional parent cgroup for the container		# 容器的可选父cgroup
        --cgroupns string                Cgroup namespace to use (host|private)	# 要使用的Cgroup命名空间（主机|专用）
        								   # 在Docker主机的cgroup命名空间中运行容器
                                         'host':    Run the container in the Docker host's cgroup namespace
                                         # 在其自己的私有cgroup命名空间中运行容器
                                         'private': Run the container in its own private cgroup namespace
                                         # 使用由配置的cgroup命名空间守护进程上的默认cgroupns模式选项（默认）
                                         '':        Use the cgroup namespace as configured by the
                                                    default-cgroupns-mode option on the daemon (default)
        --cidfile string                 Write the container ID to the file	# 将容器ID写入文件
        								   # 限制CPU CFS（完全公平调度程序）周期
        --cpu-period int                 Limit CPU CFS (Completely Fair Scheduler) period
        								   # 限制CPU CFS（完全公平调度程序）配额
        --cpu-quota int                  Limit CPU CFS (Completely Fair Scheduler) quota
        								   # 以微秒为单位限制CPU实时周期
        --cpu-rt-period int              Limit CPU real-time period in microseconds
        								   # 以微秒为单位限制CPU实时运行时间
        --cpu-rt-runtime int             Limit CPU real-time runtime in microseconds
    -c, --cpu-shares int                 CPU shares (relative weight)		# CPU份额（相对权重）
        --cpus decimal                   Number of CPUs	# CPU数量
        --cpuset-cpus string             CPUs in which to allow execution (0-3, 0,1)		# 允许执行的CPU（0-3,0,1）
        --cpuset-mems string             MEMs in which to allow execution (0-3, 0,1)		# 允许执行的MEMs（0-3,0,1）
    -d, --detach                         Run container in background and print container ID	# 在后台运行容器并打印容器ID
    									   # 覆盖用于分离容器的键序列
        --detach-keys string             Override the key sequence for detaching a container
        								   # 将主机设备添加到容器中
        --device list                    Add a host device to the container
        								   # 将规则添加到cgroup allowed devices列表
        --device-cgroup-rule list        Add a rule to the cgroup allowed devices list
        								   # 限制设备的读取速率（每秒字节数）（默认值[]）
        --device-read-bps list           Limit read rate (bytes per second) from a device (default [])
        								   # 限制设备的读取速率（IO/秒）（默认值[]）
        --device-read-iops list          Limit read rate (IO per second) from a device (default [])
        								   # 限制对设备的写入速率（每秒字节数）（默认值[]）
        --device-write-bps list          Limit write rate (bytes per second) to a device (default [])
        								   # 限制对设备的写入速率（IO/秒）（默认值[]）
        --device-write-iops list         Limit write rate (IO per second) to a device (default [])
        								   # 跳过镜像验证（默认为开启）
        --disable-content-trust          Skip image verification (default true)
        --dns list                       Set custom DNS servers	# 设置自定义DNS服务器
        --dns-option list                Set DNS options	# 设置DNS选项
        --dns-search list                Set custom DNS search domains	# 设置自定义DNS搜索域
        --domainname string              Container NIS domain name		# 容器NIS域名
        --entrypoint string              Overwrite the default ENTRYPOINT of the image		# 覆盖图像的默认入口点
    -e, --env list                       Set environment variables		# 设置环境变量
        --env-file list                  Read in a file of environment variables		# 读入环境变量文件
        --expose list                    Expose a port or a range of ports	# 公开一个端口或一系列端口
        								   # 要添加到容器中的GPU设备（“全部”用于传递所有GPU）
        --gpus gpu-request               GPU devices to add to the container ('all' to pass all GPUs)
        --group-add list                 Add additional groups to join		# 添加要加入的其他组
        --health-cmd string              Command to run to check health		# 要运行以检查运行状况的命令
        								   # 运行检查之间的时间（ms | s | m | h）（默认为0秒）
        --health-interval duration       Time between running the check (ms|s|m|h) (default 0s)	
        --health-retries int             Consecutive failures needed to report unhealthy	# 需要报告连续故障
        --health-start-period duration   Start period for the container to initialize before starting health-retries countdown (ms|s|m|h) (default 0s)				# 开始运行状况重试倒计时之前要初始化的容器的开始时间（ms | s | m | h）（默认为0s）
        								   # 允许运行一次检查的最长时间（ms | s | m | h）（默认为0秒）
        --health-timeout duration        Maximum time to allow one check to run (ms|s|m|h) (default 0s)
        --help                           Print usage	# 打印使用帮助
    -h, --hostname string                Container host name		# 容器主机名
    									   # 在容器内运行一个init，它转发信号并接收进程
        --init                           Run an init inside the container that forwards signals and reaps processes
        								   # 即使未连接，也保持标准输入打开
    -i, --interactive                    Keep STDIN open even if not attached
        --ip string                      IPv4 address (e.g., 172.30.100.104)		# IPv4地址（例如172.30.100.104）
        --ip6 string                     IPv6 address (e.g., 2001:db8::33)		# IPv6地址（例如，2001:db8:：33）
        --ipc string                     IPC mode to use		# 要使用的IPC模式
        --isolation string               Container isolation technology	# 容器隔离技术
        --kernel-memory bytes            Kernel memory limit		# 内核内存限制
    -l, --label list                     Set meta data on a container		# 在容器上设置元数据
        --label-file list                Read in a line delimited file of labels		# 读入以行分隔的标签文件
        --link list                      Add link to another container		# 添加指向另一个容器的链接
        --link-local-ip list             Container IPv4/IPv6 link-local addresses		# 容器IPv4/IPv6链路本地地址
        --log-driver string              Logging driver for the container		# 容器的日志记录驱动程序
        --log-opt list                   Log driver options		# 日志驱动程序选项
        --mac-address string             Container MAC address (e.g., 92:d0:c6:0a:29:33)	# 容器MAC地址（例如，92:d0:c6:0a:29:33）
    -m, --memory bytes                   Memory limit		# 内存限制
        --memory-reservation bytes       Memory soft limit	# 内存软限制
        								   # 交换限制等于内存加交换：'-1'以启用无限制交换
        --memory-swap bytes              Swap limit equal to memory plus swap: '-1' to enable unlimited swap
        								   # 调整容器内存交换（0到100）（默认值-1）
        --memory-swappiness int          Tune container memory swappiness (0 to 100) (default -1)
        --mount mount                    Attach a filesystem mount to the container	# 将文件系统装载附加到容器
        --name string                    Assign a name to the container	# 为容器指定一个名称
        --network network                Connect a container to a network		# 将容器连接到网络
        --network-alias list             Add network-scoped alias for the container		# 为容器添加网络范围的别名
        --no-healthcheck                 Disable any container-specified HEALTHCHECK		# 禁用任何指定的容器HEALTHCHECK
        --oom-kill-disable               Disable OOM Killer	# 禁用OOM杀手
        --oom-score-adj int              Tune host's OOM preferences (-1000 to 1000)		# 调整主机的OOM首选项（-1000到1000）
        --pid string                     PID namespace to use		# 要使用的PID命名空间
        --pids-limit int                 Tune container pids limit (set -1 for unlimited)	# 调整容器pids限制（设置为-1表示无限制）
        --platform string                Set platform if server is multi-platform capable	# 如果服务器支持多平台，则设置平台
        --privileged                     Give extended privileges to this container		# 为此容器授予扩展权限
    -p, --publish list                   Publish a container's port(s) to the host		# 将容器的端口发布到主机
    -P, --publish-all                    Publish all exposed ports to random ports		# 将所有公开端口发布到随机端口
    									   # 运行前拉取图像（“始终”|“缺少”|“从不”）（默认为“缺少”）
        --pull string                    Pull image before running ("always"|"missing"|"never") (default "missing")
        --read-only                      Mount the container's root filesystem as read only	# 以只读方式装载容器的根文件系统
        								   # 容器退出时应用的重新启动策略（默认为“否”）
        --restart string                 Restart policy to apply when a container exits (default "no")
        --rm                             Automatically remove the container when it exits		# 当容器退出时自动将其移除
        --runtime string                 Runtime to use for this container		# 用于此容器的运行时
        --security-opt list              Security Options		# 安全选项
        --shm-size bytes                 Size of /dev/shm		# /dev/shm的大小
        --sig-proxy                      Proxy received signals to the process (default true)	# 代理接收到进程的信号（默认为true）
        --stop-signal string             Signal to stop a container (default "SIGTERM")		# 停止容器的信号（默认为“SIGTERM”）
        --stop-timeout int               Timeout (in seconds) to stop a container		# 停止容器的超时（秒）
        --storage-opt list               Storage driver options for the container		# 容器的存储驱动程序选项
        --sysctl map                     Sysctl options (default map[])		# Sysctl选项（默认映射[]）
        --tmpfs list                     Mount a tmpfs directory		# 安装tmpfs
    -t, --tty                            Allocate a pseudo-TTY		# 分配一个伪TTY
        --ulimit ulimit                  Ulimit options (default [])	# Ulimit选项（默认值[]）
        								   # 用户名或UID（格式：<name | UID>[：<group | gid>）
    -u, --user string                    Username or UID (format: <name|uid>[:<group|gid>])
        --userns string                  User namespace to use	# 要使用的用户命名空间
        --uts string                     UTS namespace to use		# 要使用的名称空间
    -v, --volume list                    Bind mount a volume		# 绑定并装入卷
        --volume-driver string           Optional volume driver for the container	# 容器的可选卷驱动程序
        --volumes-from list              Mount volumes from the specified container(s)		# 从指定容器装入卷
    -w, --workdir string                 Working directory inside the container		# 容器内的工作目录
  ```

  ```shell
  # 常用参数
  --name='xxx'  	设置容器名称用于区分容器
  -d				后台运行
  -it				使用交互方式运行
  -p				指定容器端口 -p 8080:8080/主机端口:容器端口
  -P				随机指定端口
  # 示例
  [root@node1 ~]# docker images
  REPOSITORY   TAG       IMAGE ID       CREATED        SIZE
  centos       latest    5d0da3dc9764   2 months ago   231MB
  [root@node1 ~]# docker run -it 5d /bin/bash
  [root@b267d2d19ef4 /]#	  					# 已经进入到容器
  [root@b267d2d19ef4 /]# exit
  ```

- docker ps

  > 列出所有运行中的容器

  ```shell
  [root@node1 ~]# docker ps --help
  
  Usage:  docker ps [OPTIONS]
  
  List containers
  
  Options:
    -a, --all             Show all containers (default shows just running)	# 显示所有容器（默认显示正在运行）
    -f, --filter filter   Filter output based on conditions provided		# 根据提供的条件筛选输出
        --format string   Pretty-print containers using a Go template
        					# 显示n个上次创建的容器（包括所有状态）（默认值-1）
    -n, --last int        Show n last created containers (includes all states) (default -1)	
    -l, --latest          Show the latest created container (includes all states)	# 显示最新创建的容器（包括所有状态）
        --no-trunc        Don't truncate output	# 不要截断输出
    -q, --quiet           Only display container IDs		# 仅显示容器ID
    -s, --size            Display total file sizes		# 显示总文件大小
  [root@node1 ~]# docker ps -a
  # 容器ID		 #镜像		# 命令		# 创建时间		  # 状态						# 端口	 # 容器名称
  CONTAINER ID   IMAGE     COMMAND       CREATED          STATUS                      PORTS     NAMES
  fe8edecbd757   centos    "/bin/bash"   13 seconds ago   Exited (0) 11 seconds ago             mystifying_satoshi
  2c3fb40f1d3e   centos    "/bin/bash"   6 minutes ago    Up 3 minutes                          exciting_morse
  ```

- 退出容器

  ```shell
  exit #直接退出容器
  Ctrl + q + p #不停止容器并退出
  ```

- docker rm

  > 删除容器

  ```shell
  [root@node1 ~]# docker rm --help
  
  Usage:  docker rm [OPTIONS] CONTAINER [CONTAINER...]
  
  Remove one or more containers
  
  Options:
  				  # 强制移除正在运行的容器（使用SIGKILL）
    -f, --force     Force the removal of a running container (uses SIGKILL)
    -l, --link      Remove the specified link	# 删除指定的链接
    -v, --volumes   Remove anonymous volumes associated with the container # 删除与容器关联的匿名卷
  
  [root@node1 ~]# docker ps -a	# 查看所有容器
  CONTAINER ID   IMAGE     COMMAND       CREATED          STATUS                     PORTS     NAMES
  fe8edecbd757   centos    "/bin/bash"   7 minutes ago    Exited (0) 7 minutes ago             mystifying_satoshi
  2c3fb40f1d3e   centos    "/bin/bash"   13 minutes ago   Up 11 minutes                        exciting_morse
  [root@node1 ~]# docker rm fe8edecbd757	# 删除一个已经停止的容器
  fe8edecbd757
  [root@node1 ~]# docker ps -a			# 再次查看发现已经被删除了
  CONTAINER ID   IMAGE     COMMAND       CREATED          STATUS          PORTS     NAMES
  2c3fb40f1d3e   centos    "/bin/bash"   14 minutes ago   Up 11 minutes             exciting_morse
  [root@node1 ~]#
  ```

- 容器的启动删除退出

  ```shell
  docker start 容器ID		# 启动容器
  docker stop 容器ID		# 停止容器
  docker restart 容器ID		# 重启容器
  docker kill 容器ID		# 强制停止容器
  ```

- docker exec

  > 以新的TTY进入容器

  ```shell
  [root@node1 ~]# docker exec --help
  
  Usage:  docker exec [OPTIONS] CONTAINER COMMAND [ARG...]
  
  Run a command in a running container
  
  Options:
    -d, --detach               Detached mode: run command in the background	# 分离模式：在后台运行命令
        --detach-keys string   Override the key sequence for detaching a container	# 覆盖用于分离容器的键序列
    -e, --env list             Set environment variables	# 设置环境变量
        --env-file list        Read in a file of environment variables	# 读入环境变量文件
    -i, --interactive          Keep STDIN open even if not attached	# 即使未连接，也保持标准输入打开
        --privileged           Give extended privileges to the command #  为命令授予扩展权限
    -t, --tty                  Allocate a pseudo-TTY	# 分配一个伪TTY
    						 	 # 用户名或UID（格式：<name | UID>[：<group | gid>）
    -u, --user string          Username or UID (format: <name|uid>[:<group|gid>])
    -w, --workdir string       Working directory inside the container		#  容器内的工作目录
  [root@node1 ~]# docker ps
  CONTAINER ID   IMAGE     COMMAND                  CREATED             STATUS          PORTS     NAMES
  5db7847b3285   centos    "/bin/bash -c 'while…"   25 minutes ago      Up 25 minutes             shell3
  2c3fb40f1d3e   centos    "/bin/bash"              About an hour ago   Up 58 minutes             exciting_morse
  [root@node1 ~]# docker exec -it 5db /bin/bash
  [root@5db7847b3285 /]#
  ```

- docker attach

  > 打开正在运行的TTY

  ```shell
  [root@node1 ~]# docker ps
  CONTAINER ID   IMAGE     COMMAND                  CREATED             STATUS             PORTS     NAMES
  5db7847b3285   centos    "/bin/bash -c 'while…"   34 minutes ago      Up 34 minutes                shell3
  2c3fb40f1d3e   centos    "/bin/bash"              About an hour ago   Up About an hour             exciting_morse
  [root@node1 ~]# docker attach 5db
  ```

  

## 其他命令

- 后台启动容器

  ```shell
  docker -d
  ```

- docker log

  > 查看容器日志

  ```shell
  [root@node1 ~]# docker logs --help
  
  Usage:  docker logs [OPTIONS] CONTAINER
  
  Fetch the logs of a container
  
  Options:
        --details        Show extra details provided to logs		# 显示提供给日志的其他详细信息
    -f, --follow         Follow log output	# 跟踪日志输出
    					   # 显示自时间戳（例如2013-01-02T13:23:37Z）或相对时间戳（例如42分钟的42m）以来的日志
        --since string   Show logs since timestamp (e.g. 2013-01-02T13:23:37Z) or relative (e.g. 42m for 42 minutes)
        				   # 从日志末尾显示的行数（默认为“全部”）
    -n, --tail string    Number of lines to show from the end of the logs (default "all")
    -t, --timestamps     Show timestamps		# 显示时间戳
    					   # 在时间戳（例如2013-01-02T13:23:37Z）或相对时间戳（例如42分钟的42m）之前显示日志
        --until string   Show logs before a timestamp (e.g. 2013-01-02T13:23:37Z) or relative (e.g. 42m for 42 minutes)
  ```

- docker top

  > 查看容器进程

  ```shell
  [root@node1 ~]# docker ps
  CONTAINER ID   IMAGE     COMMAND                  CREATED          STATUS          PORTS     NAMES
  5db7847b3285   centos    "/bin/bash -c 'while…"   3 minutes ago    Up 3 minutes              shell3
  2c3fb40f1d3e   centos    "/bin/bash"              39 minutes ago   Up 36 minutes             exciting_morse
  [root@node1 ~]# docker top 5db
  UID                 PID                 PPID                C                   STIME               TTY                 TIME                CMD
  root                10825               10804               0                   22:08               ?                   
  root                11202               10825               0                   22:12               ?                   
  [root@node1 ~]#
  ```

- docker inspect

  > 查看容器元数据

  ```shell
  [root@node1 ~]# docker inspect --help
  
  Usage:  docker inspect [OPTIONS] NAME|ID [NAME|ID...]
  
  Return low-level information on Docker objects
  
  Options:
    -f, --format string   Format the output using the given Go template
    -s, --size            Display total file sizes if the type is container		# 如果类型为容器，则显示总文件大小
        --type string     Return JSON for specified type		# 返回指定类型的JSON
  [root@node1 ~]# docker ps
  CONTAINER ID   IMAGE     COMMAND                  CREATED          STATUS          PORTS     NAMES
  5db7847b3285   centos    "/bin/bash -c 'while…"   8 minutes ago    Up 8 minutes              shell3
  2c3fb40f1d3e   centos    "/bin/bash"              43 minutes ago   Up 40 minutes             exciting_morse
  [root@node1 ~]# docker inspect 5db
  [
      {
          "Id": "5db7847b3285ebb0bc78785808ed597f85c5476e84d24541cc5d135abc199bc2",		
          "Created": "2021-12-11T14:08:37.31918904Z",		
          "Path": "/bin/bash",	
          "Args": [
              "-c",
              "while true;do echo hhhh;sleep 1;done"
          ],
          "State": {
              "Status": "running",
              "Running": true,
              "Paused": false,
              "Restarting": false,
              "OOMKilled": false,
              "Dead": false,
              "Pid": 10825,
              "ExitCode": 0,
              "Error": "",
              "StartedAt": "2021-12-11T14:08:37.712499657Z",
              "FinishedAt": "0001-01-01T00:00:00Z"
          },
          "Image": "sha256:5d0da3dc976460b72c77d94c8a1ad043720b0416bfc16c52c45d4847e53fadb6",
          "ResolvConfPath": "/var/lib/docker/containers/5db7847b3285ebb0bc78785808ed597f85c5476e84d24541cc5d135abc199bc2/resolv.conf",
          "HostnamePath": "/var/lib/docker/containers/5db7847b3285ebb0bc78785808ed597f85c5476e84d24541cc5d135abc199bc2/hostname",
          "HostsPath": "/var/lib/docker/containers/5db7847b3285ebb0bc78785808ed597f85c5476e84d24541cc5d135abc199bc2/hosts",
          "LogPath": "/var/lib/docker/containers/5db7847b3285ebb0bc78785808ed597f85c5476e84d24541cc5d135abc199bc2/5db7847b3285ebb0bc78785808ed597f85c5476e84d24541cc5d135abc199bc2-json.log",
          "Name": "/shell3",
          "RestartCount": 0,
          "Driver": "overlay2",
          "Platform": "linux",
          "MountLabel": "",
          "ProcessLabel": "",
          "AppArmorProfile": "",
          "ExecIDs": null,
          "HostConfig": {
              "Binds": null,
              "ContainerIDFile": "",
              "LogConfig": {
                  "Type": "json-file",
                  "Config": {}
              },
              "NetworkMode": "default",
              "PortBindings": {},
              "RestartPolicy": {
                  "Name": "no",
                  "MaximumRetryCount": 0
              },
              "AutoRemove": false,
              "VolumeDriver": "",
              "VolumesFrom": null,
              "CapAdd": null,
              "CapDrop": null,
              "CgroupnsMode": "host",
              "Dns": [],
              "DnsOptions": [],
              "DnsSearch": [],
              "ExtraHosts": null,
              "GroupAdd": null,
              "IpcMode": "private",
              "Cgroup": "",
              "Links": null,
              "OomScoreAdj": 0,
              "PidMode": "",
              "Privileged": false,
              "PublishAllPorts": false,
              "ReadonlyRootfs": false,
              "SecurityOpt": null,
              "UTSMode": "",
              "UsernsMode": "",
              "ShmSize": 67108864,
              "Runtime": "runc",
              "ConsoleSize": [
                  0,
                  0
              ],
              "Isolation": "",
              "CpuShares": 0,
              "Memory": 0,
              "NanoCpus": 0,
              "CgroupParent": "",
              "BlkioWeight": 0,
              "BlkioWeightDevice": [],
              "BlkioDeviceReadBps": null,
              "BlkioDeviceWriteBps": null,
              "BlkioDeviceReadIOps": null,
              "BlkioDeviceWriteIOps": null,
              "CpuPeriod": 0,
              "CpuQuota": 0,
              "CpuRealtimePeriod": 0,
              "CpuRealtimeRuntime": 0,
              "CpusetCpus": "",
              "CpusetMems": "",
              "Devices": [],
              "DeviceCgroupRules": null,
              "DeviceRequests": null,
              "KernelMemory": 0,
              "KernelMemoryTCP": 0,
              "MemoryReservation": 0,
              "MemorySwap": 0,
              "MemorySwappiness": null,
              "OomKillDisable": false,
              "PidsLimit": null,
              "Ulimits": null,
              "CpuCount": 0,
              "CpuPercent": 0,
              "IOMaximumIOps": 0,
              "IOMaximumBandwidth": 0,
              "MaskedPaths": [
                  "/proc/asound",
                  "/proc/acpi",
                  "/proc/kcore",
                  "/proc/keys",
                  "/proc/latency_stats",
                  "/proc/timer_list",
                  "/proc/timer_stats",
                  "/proc/sched_debug",
                  "/proc/scsi",
                  "/sys/firmware"
              ],
              "ReadonlyPaths": [
                  "/proc/bus",
                  "/proc/fs",
                  "/proc/irq",
                  "/proc/sys",
                  "/proc/sysrq-trigger"
              ]
          },
          "GraphDriver": {
              "Data": {
                  "LowerDir": "/var/lib/docker/overlay2/c3c47f255c9d1db61b969601df06f580012e1783c6aa2bbbbe03e9bc970d105f-init/diff:/var/lib/docker/overlay2/41ea41b839add0b7e657a3b18b47d03f209199589ea6e20e52503cce2f8d580f/diff",
                  "MergedDir": "/var/lib/docker/overlay2/c3c47f255c9d1db61b969601df06f580012e1783c6aa2bbbbe03e9bc970d105f/merged",
                  "UpperDir": "/var/lib/docker/overlay2/c3c47f255c9d1db61b969601df06f580012e1783c6aa2bbbbe03e9bc970d105f/diff",
                  "WorkDir": "/var/lib/docker/overlay2/c3c47f255c9d1db61b969601df06f580012e1783c6aa2bbbbe03e9bc970d105f/work"
              },
              "Name": "overlay2"
          },
          "Mounts": [],
          "Config": {
              "Hostname": "5db7847b3285",
              "Domainname": "",
              "User": "",
              "AttachStdin": false,
              "AttachStdout": false,
              "AttachStderr": false,
              "Tty": false,
              "OpenStdin": false,
              "StdinOnce": false,
              "Env": [
                  "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
              ],
              "Cmd": [
                  "/bin/bash",
                  "-c",
                  "while true;do echo hhhh;sleep 1;done"
              ],
              "Image": "centos",
              "Volumes": null,
              "WorkingDir": "",
              "Entrypoint": null,
              "OnBuild": null,
              "Labels": {
                  "org.label-schema.build-date": "20210915",
                  "org.label-schema.license": "GPLv2",
                  "org.label-schema.name": "CentOS Base Image",
                  "org.label-schema.schema-version": "1.0",
                  "org.label-schema.vendor": "CentOS"
              }
          },
          "NetworkSettings": {
              "Bridge": "",
              "SandboxID": "a70d09048c929f2be067a98b10fb37d64287fd39d5fe0001a536fe70c8e9e002",
              "HairpinMode": false,
              "LinkLocalIPv6Address": "",
              "LinkLocalIPv6PrefixLen": 0,
              "Ports": {},
              "SandboxKey": "/var/run/docker/netns/a70d09048c92",
              "SecondaryIPAddresses": null,
              "SecondaryIPv6Addresses": null,
              "EndpointID": "8799f54ad2618d76893aeed3c1dafc959d83e63a7c153555fc0fe946d3c52ce9",
              "Gateway": "172.17.0.1",
              "GlobalIPv6Address": "",
              "GlobalIPv6PrefixLen": 0,
              "IPAddress": "172.17.0.3",
              "IPPrefixLen": 16,
              "IPv6Gateway": "",
              "MacAddress": "02:42:ac:11:00:03",
              "Networks": {
                  "bridge": {
                      "IPAMConfig": null,
                      "Links": null,
                      "Aliases": null,
                      "NetworkID": "d7122c9cff979c8ad84c9d6f473ade3c87f211708febd877b1e6d5b0f50a9d79",
                      "EndpointID": "8799f54ad2618d76893aeed3c1dafc959d83e63a7c153555fc0fe946d3c52ce9",
                      "Gateway": "172.17.0.1",
                      "IPAddress": "172.17.0.3",
                      "IPPrefixLen": 16,
                      "IPv6Gateway": "",
                      "GlobalIPv6Address": "",
                      "GlobalIPv6PrefixLen": 0,
                      "MacAddress": "02:42:ac:11:00:03",
                      "DriverOpts": null
                  }
              }
          }
      }
  ]
  [root@node1 ~]#
  ```

- docker cp

  > Docker拷贝命令；用于从Docker中将文件拷贝至主机

  ```shell
  [root@node1 ~]# docker cp --help
  
  Usage:  docker cp [OPTIONS] CONTAINER:SRC_PATH DEST_PATH|-
          docker cp [OPTIONS] SRC_PATH|- CONTAINER:DEST_PATH
  
  Copy files/folders between a container and the local filesystem
  
  Use '-' as the source to read a tar archive from stdin
  and extract it to a directory destination in a container.
  Use '-' as the destination to stream a tar archive of a
  container source to stdout.
  
  Options:
    -a, --archive       Archive mode (copy all uid/gid information)   # 存档模式（复制所有uid/gid信息）
    -L, --follow-link   Always follow symbol link in SRC_PATH		# 始终遵循SRC_路径中的符号链接
  ```

  ```shell
  # 使用示例
  [root@node1 ~]# docker ps -a		# 查看历史容器
  CONTAINER ID   IMAGE     COMMAND                  CREATED       STATUS                        PORTS     NAMES
  5db7847b3285   centos    "/bin/bash -c 'while…"   2 hours ago   Exited (137) 11 minutes ago             shell3
  df37e27d97c6   centos    "/bin/sh -C 'while t…"   2 hours ago   Exited (127) 2 hours ago                shell2
  6e442975e003   centos    "/bin/bash -C 'while…"   2 hours ago   Exited (127) 2 hours ago                shell
  2c3fb40f1d3e   centos    "/bin/bash"              3 hours ago   Exited (0) 52 seconds ago               exciting_morse
  [root@node1 ~]# docker start -a -i 2c	# 运行容器
  [root@2c3fb40f1d3e /]# echo hello,world > /root/xiaowangc
  [root@2c3fb40f1d3e /]# ls /root/
  abc  anaconda-ks.cfg  anaconda-post.log  original-ks.cfg  xiaowangc
  [root@2c3fb40f1d3e /]# 		# 使用ctrl q p 退出
  [root@node1 ~]# docker ps	# 查看容器还在运行
  CONTAINER ID   IMAGE     COMMAND       CREATED       STATUS              PORTS     NAMES
  2c3fb40f1d3e   centos    "/bin/bash"   3 hours ago   Up About a minute             exciting_morse
  [root@node1 ~]# ls
  anaconda-ks.cfg  initial-setup-ks.cfg
  [root@node1 ~]# docker cp 2c:/root/xiaowangc ./
  [root@node1 ~]# ls
  anaconda-ks.cfg  initial-setup-ks.cfg  xiaowangc
  [root@node1 ~]# cat xiaowangc
  hello,world
  [root@node1 ~]#
  
  # 如果需要将主机文件考至容器 即: docker cp 主机文件 容器：路径
  ```

## Docker commit

> 从容器创建一个新的镜像

```shell
[root@node1 ~]# docker commit
"docker commit" requires at least 1 and at most 2 arguments.
See 'docker commit --help'.

Usage:  docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]

Create a new image from a container's changes
[root@node1 ~]# docker commit --help

Usage:  docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]

Create a new image from a container's changes

Options:
						 # 作者（例如，“约翰·汉尼拔·史密斯<hannibal@a-team.com>）
  -a, --author string    Author (e.g., "John Hannibal Smith <hannibal@a-team.com>")
  						 # 将Dockerfile指令应用于创建的镜像
  -c, --change list      Apply Dockerfile instruction to the created image
  -m, --message string   Commit message		# 提交消息
  -p, --pause            Pause container during commit (default true)		# 提交期间暂停容器（默认为true）
```

```shell
[root@node1 ~]# docker pull tomcat
[root@node1 ~]# docker images
REPOSITORY      TAG       IMAGE ID       CREATED        SIZE
tomcat          latest    24207ccc9cce   3 days ago     680MB
centos          latest    5d0da3dc9764   2 months ago   231MB
elasticsearch   latest    5acf0e8da90b   3 years ago    486MB
[root@node1 ~]# docker run -d -P 24
efa6bf9baf159b64b4b82d5f7d3330d6f83eddfe834d88ea8af21570ddb74ab4
[root@node1 ~]# docker ps
CONTAINER ID   IMAGE     COMMAND             CREATED          STATUS          PORTS                                         NAMES
efa6bf9baf15   24        "catalina.sh run"   28 seconds ago   Up 27 seconds   0.0.0.0:49154->8080/tcp, :::49154->8080/tcp   hungry_zhukovsky
[root@node1 ~]# docker exec -it efa /bin/bash
root@efa6bf9baf15:/usr/local/tomcat# ls
BUILDING.txt     LICENSE  README.md      RUNNING.txt  conf  logs            temp     webapps.dist
CONTRIBUTING.md  NOTICE   RELEASE-NOTES  bin          lib   native-jni-lib  webapps  work
root@efa6bf9baf15:/usr/local/tomcat# cp -a webapps.dist/* webapps/
root@efa6bf9baf15:/usr/local/tomcat# exit
# 访问当前宿主机IP:49154
# 官方镜像默认是无法打开此页面
```

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202112/2242444-20211218065838524-2076511357.png)



```shell

[root@node1 ~]# docker ps
CONTAINER ID   IMAGE     COMMAND             CREATED         STATUS         PORTS                                         NAMES
efa6bf9baf15   24        "catalina.sh run"   4 minutes ago   Up 4 minutes   0.0.0.0:49154->8080/tcp, :::49154->8080/tcp   hungry_zhukovsky
# 								 作者				描述			  容器id  镜像:tag[版本]
[root@node1 ~]# docker commit -a xiaowangc -m "Modify home page" efa tomcat01:1.0
sha256:fb71bc6566f66ab89c1b2c7b17358ade7a44f17c89f5c8193fa054b5d771f658
[root@node1 ~]# docker images
REPOSITORY      TAG       IMAGE ID       CREATED         SIZE
tomcat01        1.0       fb71bc6566f6   3 seconds ago   684MB		# 打包可以查看镜像
tomcat          latest    24207ccc9cce   3 days ago      680MB
centos          latest    5d0da3dc9764   2 months ago    231MB
elasticsearch   latest    5acf0e8da90b   3 years ago     486MB
[root@node1 ~]# docker ps
CONTAINER ID   IMAGE     COMMAND             CREATED         STATUS         PORTS                                         NAMES
efa6bf9baf15   24        "catalina.sh run"   9 minutes ago   Up 9 minutes   0.0.0.0:49154->8080/tcp, :::49154->8080/tcp   hungry_zhukovsky
[root@node1 ~]# docker stop efa		# 停止之前的容器
efa
[root@node1 ~]# docker run -d -P fb71		# 通过我们打包后的镜像创建容器
a1b1c2987c3fee9546335a0070a31c3f5d903c3e17f04f34452aca775e7e1b10
[root@node1 ~]# docker ps			
CONTAINER ID   IMAGE     COMMAND             CREATED         STATUS         PORTS                                         NAMES
a1b1c2987c3f   fb71      "catalina.sh run"   2 seconds ago   Up 2 seconds   0.0.0.0:49155->8080/tcp, :::49155->8080/tcp   compassionate_fermat

# 直接访问 宿主机IP:49155
# 官方的tomcat镜像不做修改，无法访问这个主页，现在我们通过修改后的容器打包成镜像，再创建就可以直接访问
```

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202112/2242444-20211218065903247-64115338.png)



# 容器卷(容器数据持久化)

> 数据可以存储在容器中，但是一旦将容器进行删除就等同删库跑路了qwq。

###### Docker对于宿主机来说，只是一个运行在Linux上的应用程序，因此它的的数据存储还是会依赖宿主机，实现数据持久化的两种方式：

- **Bind Mount**

  ###### Bind Mount数据持久化的方式，如果挂载本地的一个目录，则对应容器的目录下的内容会被本地的数据覆盖。使用Bind Mount还需要指定本地的某个目录挂载到容器的某个目录。

- **Docker Manager Volume**

  ###### Docker Manager Volume相比Bind Mount，挂载目录到容器中数据不会被覆盖，同时也不需要管理员指定从宿主机挂载到容器中的某个目录，只需要指定对容器的某个目录进行挂载，而挂载到宿主机的某个目录是由Docker来进行统一管理。

###### 任一一种方式的持久化都不会在容器被删除后导致数据丢失

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202112/2242444-20211218065958095-151971623.png)





## Bind Mount

Bind Mount挂载卷有两种方式：

- -v [主机路径:]容器路径 [:可选参数]

  ```shell
  [root@node1 ~]# ls /root/		# 查看主机root下并没有docker-volume目录
  anaconda-ks.cfg  Documents  initial-setup-ks.cfg  Pictures  quick_start.sh  Videos
  Desktop          Downloads  Music                 Public    Templates       xiaowangc
  [root@node1 ~]# docker run --help | grep volume
    -v, --volume list                    Bind mount a volume	# 使用方式  -v 宿主机路径:容器路径
        --volume-driver string           Optional volume driver for the container
        --volumes-from list              Mount volumes from the specified container(s)
  [root@node1 ~]# docker run -it -v /root/docker-volume:/root/docker centos /bin/bash		# 启动容器并进行绑定
  [root@e8136a876260 /]# ls
  bin  dev  etc  home  lib  lib64  lost+found  media  mnt  opt  proc  root  run  sbin  srv  sys  tmp  usr  var
  [root@e8136a876260 /]# touch /root/docker/abc		# 在对于的挂载位置创建一个文件
  [root@e8136a876260 /]# exit							# 退出
  exit
  [root@node1 ~]# ls /root/docker-volume/		# 查看本机对于的目录位置，可以看到我们之前在容器中创建的abc文件
  abc
  [root@node1 ~]# docker ps -a		# 查看更改创建的容器id
  CONTAINER ID   IMAGE           COMMAND                  CREATED         STATUS                       PORTS     NAMES
  e8136a876260   centos          "/bin/bash"              3 minutes ago   Exited (0) 3 minutes ago               distracted_bose
  a1b1c2987c3f   fb71            "catalina.sh run"        3 hours ago     Exited (143) 5 minutes ago             compassionate_fermat
  efa6bf9baf15   24              "catalina.sh run"        3 hours ago     Exited (143) 3 hours ago               hungry_zhukovsky
  a1099bfaa7ff   tomcat          "catalina.sh run"        13 hours ago    Exited (143) 11 hours ago              clever_carson
  ca73206e78db   tomcat          "catalina.sh run"        13 hours ago    Exited (130) 13 hours ago              keen_mclean
  62d75c8f96c8   tomcat          "/bin/bash"              13 hours ago    Exited (0) 13 hours ago                strange_rhodes
  afecd5719875   elasticsearch   "/docker-entrypoint.…"   22 hours ago    Exited (130) 22 hours ago              modest_hawking
  [root@node1 ~]# docker inspect e8		# 获取容器元数据
  ...
   "Binds": [
                  "/root/docker-volume:/root/docker"
              ],
  ...
  "Mounts": [
              {
                  "Type": "bind",		# 类型
                  "Source": "/root/docker-volume",	# 源目录(宿主机路径)
                  "Destination": "/root/docker",		# 目的目录(Docker容器中路径)
                  "Mode": "",
                  "RW": true,							
                  "Propagation": "rprivate"
              }
          ],
  ...
  # 我们试着将容器进行删除
  [root@node1 ~]# docker ps -a		# 找到更改创建的容器id
  CONTAINER ID   IMAGE           COMMAND                  CREATED          STATUS                        PORTS     NAMES
  e8136a876260   centos          "/bin/bash"              10 minutes ago   Exited (0) 10 minutes ago               distracted_bose
  a1b1c2987c3f   fb71            "catalina.sh run"        3 hours ago      Exited (143) 12 minutes ago             compassionate_fermat
  efa6bf9baf15   24              "catalina.sh run"        3 hours ago      Exited (143) 3 hours ago                hungry_zhukovsky
  a1099bfaa7ff   tomcat          "catalina.sh run"        13 hours ago     Exited (143) 11 hours ago               clever_carson
  ca73206e78db   tomcat          "catalina.sh run"        13 hours ago     Exited (130) 13 hours ago               keen_mclean
  62d75c8f96c8   tomcat          "/bin/bash"              13 hours ago     Exited (0) 13 hours ago                 strange_rhodes
  afecd5719875   elasticsearch   "/docker-entrypoint.…"   22 hours ago     Exited (130) 22 hours ago               modest_hawking
  [root@node1 ~]# docker rm e81		# 删除容器
  e81
  [root@node1 ~]# ls /root/docker-volume/		# 再次查看发现数据还存在
  abc
  [root@node1 ~]#
  ```

  下面我们再深入了解一下-v

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202112/2242444-20211218070017530-1564959356.png)



  ```shell
  [root@node1 ~]# man docker run		# 有兴趣的可以自己阅读翻译
  
         -v|--volume[=[[HOST-DIR:]CONTAINER-DIR[:OPTIONS]]]
            Create a bind mount. If you specify, -v /HOST-DIR:/CONTAINER-DIR, Docker
            bind mounts /HOST-DIR in the host to /CONTAINER-DIR in the Docker
            container. If 'HOST-DIR' is omitted,  Docker automatically creates the new
            volume on the host.  The OPTIONS are a comma delimited list and can be:
            #创建绑定挂载。如果指定-v/HOST-DIR:/CONTAINER-DIR，则为Docker将主机中的mounts/HOST-DIR绑定到Docker中的/CONTAINER-DIR容器如果省略“HOST-DIR”，Docker会自动创建新的主机上的卷。选项是逗号分隔的列表，可以是：
  
                · [rw|ro]	# 设置卷是否可读写，在上面的实例中我们看到一行 "RW": true,表示可读写，当然我们也可以在挂载之前设置为ro(只读)
  
                · [z|Z]
  
                · [[r]shared|[r]slave|[r]private]
  
                · [delegated|cached|consistent]
  
                · [nocopy]
                
  	   # 这里告诉我们CONTAINER-DIR(容器目录)必须使用绝对路径，而HOST-DIR可以使用相对/绝对路径
         The  CONTAINER-DIR must be an absolute path such as /src/docs. The HOST-DIR can be an absolute path or a name value. A name value must start with an alphanumeric character, followed by a-z0-9, _ (underscore), . (period) or -
         (hyphen). An absolute path starts with a / (forward slash).
  
  	   # 如果HOST-DIR是绝对路径，Docker Bind会装载到指定路径。如果是名称docker会使用该名称创建一个以改名称命名的卷
         If you supply a HOST-DIR that is an absolute path,  Docker bind-mounts to the path you specify. If you supply a name, Docker creates a named volume by that name. For example, you can specify either /foo or foo for a HOST-DIR value. If you supply the /foo value, Docker creates a bind mount. If you supply the foo specification, Docker creates a named volume.
  
  	   # 可以使用-v绑定一个或多个，如果其他容器也要使用请用--volumes-from选项
         You can specify multiple  -v options to mount one or more mounts to a container. To use these same mounts in other containers, specify the --volumes-from option also.
  
  	   #你还可以在：后面使用多个参数，设置读写权限rw、ro 例如： -v 主机路径:容器路径：ro...;还能使用Z/z设置Docker重新标记共享卷上的文件对象，Z选项告诉Docker使用私有非共享标签。只有当前容器才能使用专用卷。z表示共享卷内容
         You  can  supply  additional  options for each bind mount following an additional colon.  A :ro or :rw suffix mounts a volume in read-only or read-write mode, respectively. By default, volumes are mounted in read-write mode.
         You can also specify the consistency requirement for the mount, either :consistent (the default), :cached, or :delegated.  Multiple options are separated by commas, e.g. :ro,cached.
  
         Labeling systems like SELinux require that proper labels are placed on volume content mounted into a container. Without a label, the security system might prevent the processes running inside the  container  from  using  the
         content. By default, Docker does not change the labels set by the OS.
  
         To  change  a label in the container context, you can add either of two suffixes :z or :Z to the volume mount. These suffixes tell Docker to relabel file objects on the shared volumes. The z option tells Docker that two con‐
         tainers share the volume content. As a result, Docker labels the content with a shared content label. Shared volume labels allow all containers to read/write content.  The Z option tells Docker to label the  content  with  a
         private unshared label.  Only the current container can use a private volume.
  
         By  default bind mounted volumes are private. That means any mounts done inside container will not be visible on host and vice-a-versa. One can change this behavior by specifying a volume mount propagation property. Making a
         volume shared mounts done under that volume inside container will be visible on host and vice-a-versa. Making a volume slave enables only one way mount propagation and that is mounts done on host under that  volume  will  be
         visible inside container but not the other way around.
  
  # 要控制卷的装载传播属性，可以使用：[r]共享、：[r]从属或：[r]专用传播标志。只能为绑定装入的卷指定传播属性，而不能为内部卷或命名卷指定传播属性卷。要使装载传播工作，源装载点（装载源目录的装载点）必须具有正确的传播属性。对于共享卷，必须共享源装载点。对于从卷，源装载必须是共享的或从的。
         To  control  mount  propagation  property of volume one can use :[r]shared, :[r]slave or :[r]private propagation flag. Propagation property can be specified only for bind mounted volumes and not for internal volumes or named
         volumes. For mount propagation to work source mount point (mount point where source dir is mounted on) has to have right propagation properties. For shared volumes, source mount point has to be shared. And for slave volumes,
         source mount has to be either shared or slave.
     
         ...
         
         To disable automatic copying of data from the container path to the volume, use the nocopy flag. The nocopy flag can be set on bind mounts and named volumes.
  # 另请参见--mount，它是--tmpfs和--volume的继承者。即使没有计划弃用--volume，也建议使用--mount。
         See also --mount, which is the successor of --tmpfs and --volume.  Even though there is no plan to deprecate --volume, usage of --mount is recommended.
  ```

  

- --mount

  第二种通过--mount也是官方建议使用的方法，它相比-v跟灵活、可读性高。

  ```shell
  [root@node1 ~]# man docker run		# 有兴趣的可以自己阅读翻译 
  
        --mount type=TYPE,TYPE-SPECIFIC-OPTION[,...]
            Attach a filesystem mount to the container
  
  	   # 当前支持的装载类型有bind、volume和tmpfs。
         Current supported mount TYPES are bind, volume, and tmpfs.
  
         e.g.	# 例如
  	   # bind类型(Bind Mount)，源地址，目录地址
         type=bind,source=/path/on/host,destination=/path/in/container
  
  	   # volume类型(Docker Manager Volume)，源地址，目的地址，卷标，卷标
         type=volume,source=my-volume,destination=/path/in/container,volume-label="color=red",volume-label="shape=round"
  
  	   # 前面图上的tmpfs
         type=tmpfs,tmpfs-size=512M,destination=/path/in/container
  
  	   # 常用选项
         Common Options:
  			  # 设置源地址
                · src, source: mount source spec for bind and volume. Mandatory for bind.
  			  # 设置目的地址
                · dst, destination, target: mount destination spec.
  			  # 设置权限
                · ro, readonly: true or false (default).
  
  		...
  ```

  

## Docker  Manager Volume 

通过上面对--mount参数的了解，我想对使用Docker Manager Volume方法挂载或绑定应该知道改怎么操作了~

下面来实践一下

```shell
[root@node1 ~]# docker run -it --mount src=docker_home,dst=/home centos /bin/bash
[root@69a38a458cb7 /]#   #ctrl + q + p 不停止退出容器
[root@node1 ~]# docker ps
CONTAINER ID   IMAGE     COMMAND       CREATED          STATUS          PORTS     NAMES
69a38a458cb7   centos    "/bin/bash"   41 seconds ago   Up 41 seconds             mystifying_satoshi
[root@node1 ~]# docker inspect 69
        "Mounts": [
            {
                "Type": "volume",		# 挂载类型 volume
                "Name": "docker_home",	# 前面有提到过，如果设置名称那么将以名称来创建对于卷
                "Source": "/var/lib/docker/volumes/docker_home/_data",		# 主机上目录地址(Docker自行创建)
                "Destination": "/home",										# 目录地址
                "Driver": "local",											# 设备为本地
                "Mode": "z",												# z表示共享卷内容
                "RW": true,													# 表示可读写
                "Propagation": ""
            }
```



## 聚名和匿名挂载

> 在通过docker volume ls 查看卷的时候会发现有卷名为哈希值命名的是因为在挂载的时候并未指定卷名，bind不能通过--mount设置卷名，但可以直接使用-v 进行设置例: -v 卷名:容器路径 ，volume方式可以通过--mount 卷名:容器路径进行设置卷名，如果未设置将以哈希值进行命名

```shell
[root@node1 ~]# docker volume ls	# 查看卷
DRIVER    VOLUME NAME
local     15d9a94c6a8cdbffa66b3d9c76d476243c312f70f7e54d46549d137193036479	# 匿名挂载，这是因为在挂载的时候并未指定源路径的名称
local     docker_home	# 聚名挂载，如果指定了名称那么将会以名称创建对于的卷
[root@node1 ~]# docker volume inspect 15d9a94c6a8cdbffa66b3d9c76d476243c312f70f7e54d46549d137193036479
[
    {
        "CreatedAt": "2021-12-12T04:57:10+08:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/15d9a94c6a8cdbffa66b3d9c76d476243c312f70f7e54d46549d137193036479/_data",
        "Name": "15d9a94c6a8cdbffa66b3d9c76d476243c312f70f7e54d46549d137193036479",
        "Options": null,
        "Scope": "local"
    }
]
[root@node1 ~]# docker volume inspect docker_home
[
    {
        "CreatedAt": "2021-12-13T04:19:01+08:00",
        "Driver": "local",
        "Labels": null,
        "Mountpoint": "/var/lib/docker/volumes/docker_home/_data",
        "Name": "docker_home",
        "Options": null,
        "Scope": "local"
    }
]
[root@node1 ~]#  
```



# Docker File

> 此镜像在构建基本镜像（例如[`debian`](https://registry.hub.docker.com/_/debian/)和[`busybox`](https://registry.hub.docker.com/_/busybox/)）或超级小镜像（仅包含单个二进制文件和它需要的任何内容，例如[`hello-world`](https://registry.hub.docker.com/_/hello-world/)）的上下文中最有用。

CentOS的官方Dockerfile

```shell
FROM scratch												# 最基础的镜像
ADD centos-8-x86_64.tar.xz /								# 添加centos-8-x86_64软件包
LABEL org.label-schema.schema-version="1.0"/				# 添加元数据到镜像
	  org.label-schema.name="CentOS Base Image"/
	  org.label-schema.vendor="CentOS"/
	  org.label-schema.license="GPLv2"/
	  org.label-schema.build-date="20210915"
CMD ["/bin/bash"]
```

DockerFile常用命令：

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202112/2242444-20211218070042966-277361809.png)



```shell
[root@node1 ~]# docker build --help

Usage:  docker build [OPTIONS] PATH | URL | -

Build an image from a Dockerfile		# 从Dockerfile生成镜像

Options:
								# 添加自定义主机到IP映射（主机：IP）
      --add-host list           Add a custom host-to-IP mapping (host:ip)
      --build-arg list          Set build-time variables		# 设置构建时变量
      --cache-from strings      Images to consider as cache sources		# 视为高速缓存源的镜像
      --cgroup-parent string    Optional parent cgroup for the container	# 容器的可选父cgroup
      --compress                Compress the build context using gzip		# 使用gzip压缩构建上下文
      							# 限制CPU CFS（完全公平调度程序）周期
      --cpu-period int          Limit the CPU CFS (Completely Fair Scheduler) period
      							# 限制CPU CFS（完全公平调度程序）配额
      --cpu-quota int           Limit the CPU CFS (Completely Fair Scheduler) quota
  -c, --cpu-shares int          CPU shares (relative weight)	# CPU份额（相对权重）
      --cpuset-cpus string      CPUs in which to allow execution (0-3, 0,1)		# 允许执行的CPU（0-3,0,1）
      --cpuset-mems string      MEMs in which to allow execution (0-3, 0,1)		# 允许执行的MEMs（0-3,0,1）
      --disable-content-trust   Skip image verification (default true)			# 跳过镜像验证（默认为真）
      							# Dockerfile的名称（默认值为“路径/Dockerfile”）
  -f, --file string             Name of the Dockerfile (Default is 'PATH/Dockerfile')
      --force-rm                Always remove intermediate containers			# 务必拆下中间容器
      --iidfile string          Write the image ID to the file					# 将镜像ID写入文件
      --isolation string        Container isolation technology					# 容器隔离技术
      --label list              Set metadata for an image						# 设置镜像的元数据
  -m, --memory bytes            Memory limit									# 内存限制
  								# 交换限制等于内存加交换：'-1'以启用无限制交换
      --memory-swap bytes       Swap limit equal to memory plus swap: '-1' to enable unlimited swap
      							# 在构建期间为运行指令设置网络模式（默认值为“默认值”）
      --network string          Set the networking mode for the RUN instructions during build (default "default")
      --no-cache                Do not use cache when building the image	# 生成镜像时不要使用缓存
      --pull                    Always attempt to pull a newer version of the image # 始终尝试提取镜像的更新版本
      							# 成功时抑制生成输出并打印镜像ID
  -q, --quiet                   Suppress the build output and print image ID on success
  								# 成功生成后删除中间容器（默认为true）
      --rm                      Remove intermediate containers after a successful build (default true)
      --security-opt strings    Security options								# 安全选项
      --shm-size bytes          Size of /dev/shm								# /dev/shm的大小
      							# 名称和可选的“名称：标记”格式的标记
  -t, --tag list                Name and optionally a tag in the 'name:tag' format
      --target string           Set the target build stage to build.			# 将目标构建阶段设置为build。
      --ulimit ulimit           Ulimit options (default [])						# Ulimit选项（默认值[]）
```

```shell
[root@node1 docker]# vim Dockerfile
FROM centos
MAINTAINER xiaowangc<780312916@qq.com>
ADD jdk-8u202-linux-x64.tar.gz /usr/local
ADD apache-tomcat-10.0.14.tar.gz /usr/local
ENV MYPATH /usr/local
WORKDIR $MYPATH
ENV JAVA_HOME /usr/local/jdk1.8.0_202
ENV CLASSPATH $JAVA_HOME/lib/dt.jar;$JAVA_HOME/lib/tools.jar
ENV CATALINA_HOME /usr/local/apache-tomcat-10.0.14
ENV CATALINA_BASH /usr/local/apache-tomcat-10.0.14
ENV PATH $PATH:$JAVA_HOME/bin:$CATALINA_HOME/lib:$CATALINA_HOME/bin
EXPOSE 8080
CMD /usr/local/apache-tomcat-10.0.14/bin/startup.sh && tail -F /usr/local/apache-tomcat-10.0.14/bin/logs/catalina.out
[root@node1 docker]# docker build -t tomcat:1.0 .
Sending build context to Docker daemon  626.3MB
Step 1/13 : FROM centos
 ---> 5d0da3dc9764
Step 2/13 : MAINTAINER xiaowangc<780312916@qq.com>
 ---> Running in c4eb917f2af7
Removing intermediate container c4eb917f2af7
 ---> ce301fca9581
Step 3/13 : ADD jdk-8u202-linux-x64.tar.gz /usr/local
 ---> 80553040d2a3
Step 4/13 : ADD apache-tomcat-10.0.14.tar.gz /usr/local
 ---> e817c2abc0ea
Step 5/13 : ENV MYPATH /usr/local
 ---> Running in dc72d266f4eb
Removing intermediate container dc72d266f4eb
 ---> 9a11104f7a13
Step 6/13 : WORKDIR $MYPATH
 ---> Running in cdf0377b61ad
Removing intermediate container cdf0377b61ad
 ---> e94e866312c7
Step 7/13 : ENV JAVA_HOME /usr/local/jdk1.8.0_202
 ---> Running in 460df16b993a
Removing intermediate container 460df16b993a
 ---> 6523add551dc
Step 8/13 : ENV CLASSPATH $JAVA_HOME/lib/dt.jar;$JAVA_HOME/lib/tools.jar
 ---> Running in c3243bb658ab
Removing intermediate container c3243bb658ab
 ---> d27761de5003
Step 9/13 : ENV CATALINA_HOME /usr/local/apache-tomcat-10.0.14
 ---> Running in a202f40d116f
Removing intermediate container a202f40d116f
 ---> 3e2b79eac04f
Step 10/13 : ENV CATALINA_BASH /usr/local/apache-tomcat-10.0.14
 ---> Running in 75aa2512492c
Removing intermediate container 75aa2512492c
 ---> 69f0cf1dfa7c
Step 11/13 : ENV PATH $PATH:$JAVA_HOME/bin:$CATALINA_HOME/lib:$CATALINA_HOME/bin
 ---> Running in 61d1715c1996
Removing intermediate container 61d1715c1996
 ---> 9c10da8b965f
Step 12/13 : EXPOSE 8080
 ---> Running in 27eb03392b67
Removing intermediate container 27eb03392b67
 ---> 29061051cbe8
Step 13/13 : CMD /usr/local/apache-tomcat-10.0.14/bin/startup.sh && tail -F /usr/local/apache-tomcat-10.0.14/bin/logs/catalina.out
 ---> Running in 96463dc0a1e7
Removing intermediate container 96463dc0a1e7
 ---> c6bbae39158e
Successfully built c6bbae39158e
Successfully tagged tomcat:1.0
[root@node1 docker]# docker run -itdp 80:8080 c6	# 将容器8080映射到主机80
212d00ffa33649ac8f4370feab11a36552d2ae40719d398718c29c233e3c09ed
[root@node1 docker]# docker ps						# 查看容器是否正在运行
CONTAINER ID   IMAGE     COMMAND                  CREATED         STATUS         PORTS                                   NAMES
212d00ffa336   c6        "/bin/sh -c '/usr/lo…"   3 seconds ago   Up 3 seconds   0.0.0.0:80->8080/tcp, :::80->8080/tcp   confident_archimedes
[root@node1 docker]#
```

**访问宿主机IP**

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202112/2242444-20211218070057949-125116092.png)





# Docker Network

> Docker网络模式
>

| Docker网络 |                             说明                             |
| :--------: | :----------------------------------------------------------: |
|    Host    |                 容器和宿主机共用Network/Port                 |
| Container  |               容器和另外的容器共用Network/Port               |
|    None    |                       关闭该容器的网络                       |
|   Bridge   | 容器会分配到属于各自的IP，并连接到Docker0的虚拟网桥，通过Docker0与宿主机通信(默认模式) |

## Bridge

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202112/2242444-20211218070111722-358208503.png)



###### 桥接(Bridge)网络从上图就可以看出来，我们创建的两台容器是不能直接进行通信而是经过Docker0进行桥接实现的(二层交换)。在创建容器时，如果没有更改容器网络那么容器默认将加入到Docker0中。

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202112/2242444-20211218070123087-2044118293.png)



通过在宿主机和容器通过命令对网络进行查看，我们还会会看到宿主机和容器的网卡的名称有着微妙的联系，if7-if8、if9-if10...

这里是因为容器使用了veth-pair,veth设备的特点(在Bridge的第一张图就能看出)：

- veth设备是成对出现的，另一端两个设备彼此相连
- 一个设备收到协议栈的数据发送请求后，会将数据发送到另一个设备上去

```shell
# 创建一个新桥并加入容器
[root@node1 ~]# docker network

Usage:  docker network COMMAND

Manage networks

Commands:
  connect     Connect a container to a network		# 将容器连接到网络
  create      Create a network						# 创建一个新网络
  disconnect  Disconnect a container from a network		# 断开容器与网络的连接
  inspect     Display detailed information on one or more networks		# 显示一个或多个网络上的详细信息
  ls          List networks		# 列出所有网络
  prune       Remove all unused networks	# 删除所有未使用的网络
  rm          Remove one or more networks		# 删除一个或多个网络
```

###### 由Docker默认创建的网络

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202112/2242444-20211218070133875-1412409362.png)



```shell
[root@node1 ~]# docker network create --subnet 192.168.233.0/24 --gateway 192.168.233.254 netWork
8e707433b97d58fb6329ec3cf6cf770d34df82b1050e16b56c4f7e6090cfbcc5
[root@node1 ~]# docker network ls
NETWORK ID     NAME      DRIVER    SCOPE
712b32668ed2   bridge    bridge    local
ca94de41081d   host      host      local
8e707433b97d   netWork   bridge    local		# 这是我们新建出来的网络
2ef78fbe2411   none      null      local
[root@node1 ~]# docker run -it --network=8e centos /bin/bash		# 通过--network来指定容器网络
[root@d9c64ba08629 /]# ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
14: eth0@if15: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:c0:a8:e9:01 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 192.168.233.1/24 brd 192.168.233.255 scope global eth0			# 已经获取到我们设置的地址
       valid_lft forever preferred_lft forever
[root@d9c64ba08629 /]#
```

**#不同Bridge的容器之间不能互通**





## Container

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202112/2242444-20211218070145064-275099183.png)



###### Container模式是将创建好的新容器和已经存在的容器共享同一个网络(IP/Port)，而不是跟Bridge模式一样，新容器也不会创建一个属于自己的网卡和配置IP地址等等。当然，除了网络环境容器的其他资源还是默认进行隔离的。

## None

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202112/2242444-20211218070154007-2147253083.png)



###### None模式Docker不会为容器进行任何网络的设置，当创建好这个容器它不会拥有IP地址、DNS、路由等等，需要我们手动对容器进行设置，这种网络类型的容器是没有办法进行联网的。

```shell
# 创建容器并设置网络为None
[root@node1 ~]# docker network ls
NETWORK ID     NAME      DRIVER    SCOPE
712b32668ed2   bridge    bridge    local
ca94de41081d   host      host      local
8e707433b97d   netWork   bridge    local
2ef78fbe2411   none      null      local
[root@node1 ~]# docker run -itd --network=none centos
0f2e0509e81bb5e34f68eabe429eaf0ab4eca6d1937c62626635fdb625b16676
[root@node1 ~]# docker exec -it 0f ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
[root@node1 ~]#
```





## Host

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202112/2242444-20211218070205869-613575948.png)



###### Host模式是指容器可以直接使用宿主机的IP地址进行通信，容器内的端口可以直接使用宿主机的端口不需要进行NAT。

```shell
# 创建容器并设置网络为Host
[root@node1 ~]# docker network ls
NETWORK ID     NAME      DRIVER    SCOPE
712b32668ed2   bridge    bridge    local
ca94de41081d   host      host      local
8e707433b97d   netWork   bridge    local
2ef78fbe2411   none      null      local
[root@node1 ~]# docker run -itd --network host centos
3ef7cf52eba35f6286ecc863f896ff96386fb61b79815100fe1666a7a0381e3e
[root@node1 ~]# docker exec -it 3e ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: ens160: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:0c:29:d0:69:a9 brd ff:ff:ff:ff:ff:ff
    inet 172.25.250.9/24 brd 172.25.250.255 scope global noprefixroute ens160
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:fed0:69a9/64 scope link noprefixroute
       valid_lft forever preferred_lft forever
3: virbr0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default qlen 1000
    link/ether 52:54:00:69:3a:f3 brd ff:ff:ff:ff:ff:ff
    inet 192.168.122.1/24 brd 192.168.122.255 scope global virbr0
       valid_lft forever preferred_lft forever
4: virbr0-nic: <BROADCAST,MULTICAST> mtu 1500 qdisc fq_codel master virbr0 state DOWN group default qlen 1000
    link/ether 52:54:00:69:3a:f3 brd ff:ff:ff:ff:ff:ff
5: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:b7:51:5a:38 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:b7ff:fe51:5a38/64 scope link
       valid_lft forever preferred_lft forever
13: br-8e707433b97d: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:a0:c6:26:d2 brd ff:ff:ff:ff:ff:ff
    inet 192.168.233.254/24 brd 192.168.233.255 scope global br-8e707433b97d
       valid_lft forever preferred_lft forever
    inet6 fe80::42:a0ff:fec6:26d2/64 scope link
       valid_lft forever preferred_lft forever
17: vethbe82798@if16: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master docker0 state UP group default
    link/ether d2:95:6d:24:8b:5f brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::d095:6dff:fe24:8b5f/64 scope link
       valid_lft forever preferred_lft forever
19: veth76775e3@if18: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master br-8e707433b97d state UP group default
    link/ether 1a:48:2c:6f:f5:01 brd ff:ff:ff:ff:ff:ff link-netnsid 1
    inet6 fe80::1848:2cff:fe6f:f501/64 scope link
       valid_lft forever preferred_lft forever
21: vethfd72d16@if20: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master docker0 state UP group default
    link/ether ae:d3:7c:80:fc:4e brd ff:ff:ff:ff:ff:ff link-netnsid 2
    inet6 fe80::acd3:7cff:fe80:fc4e/64 scope link
       valid_lft forever preferred_lft forever
25: vethafacb9a@if24: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master docker0 state UP group default
    link/ether a2:dc:c1:1d:0d:66 brd ff:ff:ff:ff:ff:ff link-netnsid 3
    inet6 fe80::a0dc:c1ff:fe1d:d66/64 scope link
       valid_lft forever preferred_lft forever
[root@node1 ~]#
```
