---
title: ssh免密
date: '2021-05-16 10:00'
tags: ssh免密
cover: img/fengmian/ssh.png
categories: openssh
abbrlink: '17703002'
---
# 记一次ssh免密登录

# 概念

```shell
Secure Shell(安全外壳协议，ssh)，是一种加密的网络传输协议，可在不安全的网络中为网络服务提供安全的传输环境。SSH通过在网络中创建安全隧道来实现SSH客户端与服务器之间的连接。虽然如何网络服务都可以通过SSH实现安全传输，SSH最常见的用途是远程登陆系统，通常利用SSH来传输命令行界面和远程执行命令。
```

- 对称加密

  ###### 对称加密使用同一个密钥来进行加密和解密。账号密码(口令)可以看作一种对称加密方式

- 非对称加密

  ###### 非对称加密有两个密钥：私钥和公钥，数据使用公钥加密后，只能用私钥进行解密。

  - 公钥：加密，公开
  - 私钥：解密，私有

- SSH的两种登录方式

  - 口令登录

   ![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210516095918016-940482157.png)



  - 密钥登录

    ```shell
    # 提前将公钥发送到目标服务器中
    ```

    

    ![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210516095927182-1093029143.png)



    1. 发送登录请求并发送一个公钥指纹，服务器对指纹进行验证，查看指纹是否一致
    2. 服务器随机生成一串随机数，使用公钥加密
    3. 客户端使用私钥进行解密，并发送解密后的信息
    4. 对解密后的信息对比是否一致

# 路由器配置ssh免密登录

> 以H3C路由器为例，HCL环境

![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210516095940072-1200134666.png)



1. 配置IP地址略

2. 生成密钥对

   ```shell
   # win10的cmd下生成的，也可使用其它工具进行生成
   # 
   
   C:\Users\Tao>ssh-keygen -t rsa -b 2048
   # t 指定密钥类型	默认rsa
   # b 指定密钥长度	默认2048
   Generating public/private rsa key pair.
   Enter file in which to save the key (C:\Users\Tao/.ssh/id_rsa): Tao   # 保存的文件名
   Enter passphrase (empty for no passphrase):		# 这里设置密钥的密码		按需设置
   Enter same passphrase again:		# 这里确认密钥的密码
   Your identification has been saved in Tao.
   Your public key has been saved in Tao.pub.
   The key fingerprint is:		
   SHA256:B0k4N7yruAZ3CYD9a3wbOq97kNKvwa/tmdmg1PNhWFo tao@DESKTOP-3TSULKA		# 指纹信息
   The key's randomart image is:
   +---[RSA 2048]----+
   | o     o.        |
   |. o   o.+.       |
   |   o   ooo       |
   |    o   ..       |
   |   o + .E..      |
   |  o.O.==..       |
   |   =+B*+o        |
   |   .===X .       |
   |   .B@O o        |
   +----[SHA256]-----+
   ```

3. 将公钥放置路由器

   我这里使用的win10的IIS中的FTP配置过程略

   ```shell
   <H3C>ftp 192.168.56.101		# 使用ftp登录
   Press CTRL+C to abort.
   Connected to 192.168.56.101 (192.168.56.101).
   220 Microsoft FTP Service
   User (192.168.56.101:(none)): anonymous		# 输入用户名  匿名用户名为：anonymous
   331 Anonymous access allowed, send identity (e-mail name) as password.
   Password:	
   230 User logged in.
   Remote system type is Windows_NT.
   ftp> dir		# 列出文件
   227 Entering Passive Mode (192,168,56,101,249,170).
   125 Data connection already open; Transfer starting.
   05-16-21  08:35AM                  402 Tao.pub		# 这是我们的公钥 ，生成两个文件后缀为.pub的是公钥，没有后缀的是私钥
   226 Transfer complete.
   ftp> get Tao.pub	# 下载
   227 Entering Passive Mode (192,168,56,101,249,171).
   125 Data connection already open; Transfer starting.
   .
   226 Transfer complete.
   402 bytes received in 0.002 seconds (196.29 Kbytes/s)
   ftp> quit	# 退出ftp
   221 Goodbye.
   <H3C>dir	# 查看路由器的文件
   Directory of flash:
      0 -rw-         402 May 16 2021 08:36:36   Tao.pub
      1 drw-           - May 15 2021 17:19:14   diagfile
      2 -rw-         402 May 16 2021 04:31:50   h3c.pub	# 这就是我们刚刚下载下来的公钥
      3 -rw-         735 May 16 2021 04:32:38   hostkey
      4 -rw-       43136 May 15 2021 17:19:14   licbackup
      5 drw-           - May 15 2021 17:19:14   license
      6 -rw-       43136 May 15 2021 17:19:14   licnormal
      7 drw-           - May 15 2021 17:19:14   logfile
      8 -rw-           0 May 15 2021 17:19:14   msr36-cmw710-boot-a7514.bin
      9 -rw-           0 May 15 2021 17:19:14   msr36-cmw710-system-a7514.bin
     10 drw-           - May 15 2021 17:19:20   pki
     11 drw-           - May 15 2021 17:19:14   seclog
     12 -rw-         591 May 16 2021 04:32:38   serverkey
   
   1046512 KB total (1046356 KB free)
   
   <H3C>
   ```

4. 配置路由器SSH

   ```shell
   [H3C]public-key local create rsa	# 生成rsa密钥对
   [H3C]ssh server enable	# 开启ssh
   [H3C]line vty 0 4	# 配置虚拟接口
   [H3C-line-vty0-4]authentication-mode scheme		# 认证方式
   [H3C-line-vty0-4]quit
   [H3C]public-key peer h3c import sshkey Tao.pub  # 导入公钥并更名为h3c
   
   # 配置ssh用户的认证方式并指定公钥为h3c
   [H3C]ssh user xiaowangc service-type stelnet authentication-type publickey assign publickey h3c
   [H3C]local-user xiaowangc class manage		# 创建本地用户
   [H3C-luser-manage-xiaowangc]service-type ssh	# 服务器类型
   [H3C-luser-manage-xiaowangc]authorization-attribute user-role network-admin  # 用户角色
   [H3C-luser-manage-xiaowangc]quit
   ```

5. 测试连接

   ```shell
   C:\Users\Tao>ssh xiaowangc@192.168.56.110 -c aes128-cbc -i Tao
   # i 指定私钥
   # c 指定加密类型
   The authenticity of host '192.168.56.110 (192.168.56.110)' can't be established.
   RSA key fingerprint is SHA256:wMmxasuUNqNvee0426c5wUcV5rcdphvVoGw3SaR7vBU.
   Are you sure you want to continue connecting (yes/no)? yes	# 是否永久添加到列表
   Warning: Permanently added '192.168.56.110' (RSA) to the list of known hosts.
   
   ******************************************************************************
   * Copyright (c) 2004-2017 New H3C Technologies Co., Ltd. All rights reserved.*
   * Without the owner's prior written consent,                                 *
   * no decompiling or reverse-engineering shall be allowed.                    *
   ******************************************************************************
   
   <H3C>
   ```

   ![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210516095955089-30077918.png)



6. 如果不想每次连接都指定加密类型和密钥可配置config文件（略）



# Linux配置ssh免密登录

1. [安装](https://www.cnblogs.com/xiaowangc/p/14743138.html),网络拓扑
   ![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210516100810436-2011226014.png)



2. 生成密钥对

   ```shell
   # win10的cmd下生成的，也可使用其它工具进行生成
   # 
   
   C:\Users\Tao>ssh-keygen -t rsa -b 2048
   # t 指定密钥类型	默认rsa
   # b 指定密钥长度	默认2048
   Generating public/private rsa key pair.
   Enter file in which to save the key (C:\Users\Tao/.ssh/id_rsa): Tao   # 保存的文件名
   Enter passphrase (empty for no passphrase):		# 这里设置密钥的密码		按需设置
   Enter same passphrase again:		# 这里确认密钥的密码
   Your identification has been saved in Tao.
   Your public key has been saved in Tao.pub.
   The key fingerprint is:		
   SHA256:B0k4N7yruAZ3CYD9a3wbOq97kNKvwa/tmdmg1PNhWFo tao@DESKTOP-3TSULKA		# 指纹信息
   The key's randomart image is:
   +---[RSA 2048]----+
   | o     o.        |
   |. o   o.+.       |
   |   o   ooo       |
   |    o   ..       |
   |   o + .E..      |
   |  o.O.==..       |
   |   =+B*+o        |
   |   .===X .       |
   |   .B@O o        |
   +----[SHA256]-----+
   ```

3. 将公钥上传至服务器，并进行配置

   ```shell
   [root@localhost ~]# yum -y install ftp		# 安装ftp客户端
   [root@localhost ~]# ftp 192.168.204.1		# 登录
   Connected to 192.168.204.1 (192.168.204.1).
   220 Microsoft FTP Service
   Name (192.168.204.1:root): anonymous
   331 Anonymous access allowed, send identity (e-mail name) as password.
   Password:
   230 User logged in.
   Remote system type is Windows_NT.
   ftp> dir
   227 Entering Passive Mode (192,168,204,1,253,61).
   125 Data connection already open; Transfer starting.
   05-16-21  08:35AM                  402 Tao.pub
   226 Transfer complete.
   ftp> get Tao.pub		# 下载公钥
   local: Tao.pub remote: Tao.pub
   227 Entering Passive Mode (192,168,204,1,253,63).
   125 Data connection already open; Transfer starting.
   226 Transfer complete.
   402 bytes received in 0.0001 secs (4020.00 Kbytes/sec)
   ftp>quit
   [root@localhost ~]# mkdir .ssh		# 创建.ssh文件
   [root@localhost ~]# cat Tao.pub >> .ssh/authorized_keys		# 将公钥存放至文件
   ```

4. 测试

   ```shell
   C:\Users\Tao>ssh root@192.168.204.131 -i Tao
   Last login: Sun May 16 09:41:55 2021 from 192.168.204.1
   [root@localhost ~]#
   ```

   ![](https://images.weserv.nl/?url=https://img2020.cnblogs.com/blog/2242444/202105/2242444-20210516100007661-2090560518.png)
