---
title: Systemd-Unit配置
abbrlink: 38fea313
date: 2022-11-24 01:08:00
tags:
  - Linux
  - Systemd
categories: Linux
cover: img/fengmian/linux.png
---
# Unit相关

1. unit相关文件目录

   ```shell
   /lib/systemd/system		# 本地的系统单元
   /run/systemd/system		# 运行时的系统单元
   /usr/lib/systemd/system	# 第三方的系统单元
   /etc/systemd/system		# Systgemd默认从这个目录读取单元
   /etc/systemd/system/multi-user.target.wants		# systemd开机自动启动此目录的单元,当配置enable时就会自动创建链接文件到此目录
   ```

2. unit分类

   - **Service Unit：系统服务**
   - **Target Unit：由多个Unit构成的**
   - Device Unit：硬件设备
   - Mount Unit：文件系统的挂载点
   - Automount Unit：自动挂载点
   - Path Unit：文件或路径
   - Slice Unit：进程组
   - Snapshot Unit：快照
   - Socket Unit：进程间通信的Socket
   - Swap Unit：Swap文件
   - Time Unit：定时器

   **查看单元命令**

   ```shell
   [root@gateway ~]# systemctl list-units			# 查看正在运行的Unit
   [root@gateway ~]# systemctl list-units --all	# 查看所有的Unit
   [root@gateway ~]# systemctl list-units --all --state=inactive		# 查看没有运行的Unit
   [root@gateway ~]# systemctl list-units --failed	# 查看加载失败的Unit
   ```

   

# 常用命令

```shell
[root@gateway ~]# systemctl start nginx		# 启动服务
[root@gateway ~]# systemctl status nginx	# 查看服务状态
[root@gateway ~]# systemctl stop nginx		# 停止服务
[root@gateway ~]# systemctl kill nginx		# 杀死与服务相关的子进程
[root@gateway ~]# systemctl reload nginx	# 重载服务的配置
[root@gateway ~]# systemctl daemon-reload	# 重载所有修改过的配置
[root@gateway ~]# systemctl show nginx		# 查看服务所有配置
[root@gateway ~]# systemctl list-dependencies nginx		# 查看服务的依赖关系
[root@gateway ~]# systemctl cat nginx.service			# 查看服务的配置文件
```



# 创建Service Unit

## 查看Service Unit

```shell
[root@gateway ~]# systemctl cat nginx.service
# /usr/lib/systemd/system/nginx.service
[Unit]
Description=The nginx HTTP and reverse proxy server
After=network.target remote-fs.target nss-lookup.target

[Service]
Type=forking
PIDFile=/run/nginx.pid
# Nginx will fail to start if /run/nginx.pid already exists but has the wrong
# SELinux context. This might happen when running `nginx -t` from the cmdline.
# https://bugzilla.redhat.com/show_bug.cgi?id=1268621
ExecStartPre=/usr/bin/rm -f /run/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=/bin/kill -s HUP $MAINPID
KillSignal=SIGQUIT
TimeoutStopSec=5
KillMode=mixed
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

## 配置格式

官网配置大全：[(www.freedesktop.org)](https://www.freedesktop.org/software/systemd/man/systemd.unit.html)

通常Service配置文件如下分为三大块

```shell
[Unit]
...
[Service]
...
[Install]
...
```

**[Unit]**: 用来配置元数据以及与其他Unit的关系

- **Description** 描述
- **Documentation** 文档地址
- **Requires** 如果此字段的Unit没有启动，则Unit会启动失败
- **Wants** 如果此字段的Unit没有启动，则Unit不会启动失败
- **BindsTo** 此字段的Unit退出，此Unit会停止运行
- **Before** 此字段的Unit要启动，那么必须要在当前Unit启动之后
- **After** 此字段的Unit要启动，那么必须要在当前Unit启动之前
- **Conflicts** 此字段的Unit不能与当前Unit同时启动

**[Service]**: 用来定义服务(程序)的配置，只有Service类型的Unit才有这个配置

- **Type**: 定义启动时进程的行为
  - **simple**：默认值，执行ExecStart指定的命令
  - forking：以fork方式从父进程创建子进程，创建后父进程会立即退出
  - oneshot：一次性进程，Systemd会等待当前服务退出再继续执行
  - dbus：当前服务通过D-bus启动
  - notify：当前服务启动完毕后，会通知Systemd再继续往下执行
- **ExecStart**：启动当前服务的命令
- ExecStartPre：启动当前服务之前执行的命令
- ExecStartPost：启动当前服务之后执行的命令
- ExecReload：重启当前服务时执行的命令
- ExecStop：停止当前服务时执行的命令
- ExecStopPort：停止当前服务之后执行的命令
- **RestartSec**：自动重启当前服务的间隔秒数
- **Restart**：定义重启策略
  - always	总是重启
  - on-success
  - on-failure
  - on-abnormal
  - no-abort
  - on-watchdog
- TimeoutSec：停止当前服务之前等待多少秒
- **Environment**：指定环境变量

**[Install]**: 用来定义程序如何启动以及是否开启自启

- **WantedBy** 此字段的值是一个或多个Target，当前 Unit 激活时（enable）符号链接会放入`/etc/systemd/system`目录下面以 Target 名 + `.wants`后缀构成的子目录中(**enable时才会自启**)
- **RequiredBy** 此字段的值是一个或多个Target，它的值是一个或多个 Target，当前 Unit 激活时，符号链接会放入`/etc/systemd/system`目录下面以 Target 名 + `.required`后缀构成的子目录中(**start就自启**)
- **Alias**：别名
- **Also**：当前Unit激活时(enable)，同时激活其他的Unit