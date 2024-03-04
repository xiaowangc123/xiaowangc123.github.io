---
title: LVS
tags: 负载均衡
cover: img/fengmian/lvs.png
categories: 负载均衡
abbrlink: 9842572a
date: 2022-04-02 02:27:38
---
# LVS概念

> 最开始学的时候感觉这么老的技术为什么还在用，内心反感。直到思索K8S部署的时候如果采用LVS的某个功能可以加快K8S包转发效率，感觉是真不错。

LVS(Linux Virtual Server)，Linux虚拟服务器。是一个虚拟的服务器集群系统，通过LVS可提供负载均衡以及用来实现一个高可用、高性能的服务器集群，它有良好的可靠性、可扩展性和可操作性。LVS已集成在Linux内核(2.4+)中。

在诸多负载均衡技术中有基于DNS、客户端、应用层、IP等调度的方案。而LVS采用IP负载均衡和基于内容请求分发技术，主要功能有如下：

- 三种负载均衡技术(NAT/TUN/DR)
- 十种调度算法(rr/wrr/lc/wlc/lblc/lblcr/dh/sh/sed/nq)

LVS基于内核级别的应用软件，有着较高的性能和处理能力。可支持上百万个并发连接请求(据说在百兆网卡下，吞吐量可以达到1Gbits/s；千兆网卡可达到10Gbits/s，不知道是不是真的反正我没有试过！)

缺点也就是需要上层协议支持，QwQ还要单独配置网络环境烦死了



# 工作模式

> LVS有三种工作模式，Dr、Tun、Nat，后期实验只测试Dr和Tun。Tun跟Dr差不多只是跨网段，配置起来嘛，不会真有把调度器和集群分离的情况吧？？？

- **VS/NAT**

  VS/NAT即虚拟网络地址转换实现虚拟服务器。让我们想一下Nat的工作原理：

  ​														                                        外网<---------->Nat服务器<-------->内网

  `众所周知`Nat主要实现内外网络地址转换，以解决IPv4地址池不足问题以及端口映射等。当我们从外网访问Nat服务器的外网IP地址就会将地址转换成内外的某个给定的地址范围，并于内外某一个用户进行通信，用户再将信息返回给Nat进行转换为公网IP地址与外网进行通信。

  而VS/NAT就是基于此技术，但是Nat转换同一个端口/IP只对应内网的某个单一的服务器。那么就得说到一个LVS最重要的一个功能，那就是调度器。

  如下图：

![image-20220210011443401](20220210011443401.png)

  假如用户访问www.xiaowangc.com，众所周知www.xiaowangc.com是一个Web应用服务器。图上带着地球图标的Web服务器。举个例子www.xiaowangc.com对应IP地址：192.168.1.1/24，但实际上，真实的Web应用服务器不会是192.168.1.1，而且其他地址。这个192.168.1.1IP地址是由LVS上的VIP(虚拟地址，实际上是网口上的接口地址)。通过访问这个集群虚拟IP地址，LVS会将http/https请求按照设置的调度算法以此转发(Nat，通过对数据包中的源目的IP进行更改)给其中一台服务器(不知道我这么说明白了吗？反正我自己是清楚的！)。

  第一次请求进行转发后，那么LVS会记录下此次转发的情况，谁给我的？我又给谁的？并记录到Hash表中，当这个请求后续的数据包需要转发时直接查询Hash表进行转发。

  **Web服务器网关需要将LVS的接口IP地址(与服务器集群相连的那个接口的IP地址)设置为自身网关！因为服务器需要经过LVS对响应数据包进行转发**

  > LVS的VIP不能和服务器的网段处于同一网段！

- **VS/DR**

  VS/DR即直接路由实现虚拟服务器。什么叫直接路由？在了解了VS/Nat方式后，可以发现。一个数据包通常可分为请求/响应两种，用户请求访问网页，服务器返回资源给用户。那么VS/Nat模式不管是请求还是响应的数据包都是要经过LVS这会给LVS造成极大的压力。如果服务器网卡带宽本来就不高，还要承受请求和响应的数据转发，我都哭了~而且众所周知！响应数据包是要比请求包要大的！

  VS/DR的就是为了解决这个问题，请求响应分离！LVS以后之转发请求数据包，响应数据包由服务器直接转发给用户，分担LVS的工作量。

![image-20220210014303277](20220210014303277.png)

  那么就会有朋友问了！我用户访问的是LVS的接口地址IP（VIP），那服务器如果直接返回给用户那么源地址不就是Web服务器的IP地址就是VIP，这样客户端就会丢弃的！***其实在LVS调度器转发给后端服务器之前就通过更改目的Mac地址对数据包进行转发***，而且IP层还是`[源地址：客户IP地址 | 目的地址：LVSIP地址]`，那么并在Web服务器的**Lo本地回环网卡上配置一个VIP**，并修改配置**关闭ARP应答**。这样一来，服务器在进行转发给用户的时候数据包源地址依然是VIP。

  直接路由也就是服务器直接转发给客户端，而不需要经过LVS~

  > 二层局域网中实际上传输的是帧，而帧依靠目的Mac地址进行转发。关闭ARP。在Lo回环口设置VIP！！！当然还要保证Web服务器能上网的情况下

- **VS/TUN**

  这个东东感觉有点复杂(实现复杂，本来Dr就麻烦，这个还加了隧道)了o(*≧▽≦)ツ┏━┓，VS/Tun即是IP隧道技术现实虚拟服务器。这个技术跟VS/Dr差不多，也是将请求/响应进行分离，由服务器直接转发给用户。来看图：

![image-20220210020648189](20220210020648189.png)

  各位发现了没有，这图好像跟前一张图差不多好像几乎一模一样。不，仔细看，LVS到Web应用服务器之间连接到线变成了虚线，这个线还叫IP隧道！这种技术主要是用在跨网段，跨区域情况下使用。那么就会有兄弟说了：难道我这就在一个本地区域使用不行吗？啊这。。。那用VS/Dr模式不就行了吗？还省去配置隧道的过程。而且哪个工程师会将调度器和应用分开部署的......除真有特别极端的情况，服务器有部分或all都不在一个区域，我分别将服务器放在北上广深，但是我LVS就想放在成都，那么你就可以用VS/Tun来实现。

  而且图中的虚线也就LVS与服务器跨了一个或多个网络才会采用IP隧道技术实现将LVS与服务器虚拟在一个网络中。工作流程还是跟VS/Dr一样，LVS接收并转发请求，而此模式的请求是经过隧道并转发给服务器，服务器在将响应数据通过互联网直接发送给用户。

  > 用跨一个或多个网络的情况下。

# 3. 调度算法

> 根据前面的介绍依据大概对LVS有了一个基础的认识，LVS是做负载均衡的！

> 而负载均衡最核心的就是调度和算法，下面就来了解一下LVS的十种调度算法

1. **轮询**

   轮询算法(rr)，就是按照依次循环的方式将请求调度到不同的服务器上。

   例：第一个请求我给A，第二个请求我给B，第三个请求我给C，第四个请求我给A......以此往复

   这种算法的特点就是简单，但是它忽略了服务器的真实负载情况。

   例：假如有两台Web服务器A、B。我们知道请求是有一个连接(会话)的

   ```shell
   第一个请求------------>A		# 这个连接三秒后就断开了	
   第二个请求------------>B		# 这个连接一直保持连接
   第三个请求------------>A		# 此时A的连接数为1
   第四个请求------------>B		# 此时B的连接数为2
   ```

   此种情况，连接数小还行，如果大了，会将差距拉开，这将导致无法将请求均匀的分配的每个服务器

2. **加权轮询**

   加权轮询算法(wrr)，这种调度算法算法是对轮询**(rr)**进行优化和改进的。这考虑到服务器的性能情况，让性能Newbee的服务器承担多一点（能力越大责任越大），减轻低性能服务器的压力。

   ```shell
   A服务器权重为1
   B服务器权重为2
   # 有3个请求，那么2个都会分给B服务器，1个分给A服务器
   ```

3. **最小连接**

   最小连接算法(lc)，我们前面说过轮询算法(rr)不能判断服务器的真实负载情况。而通过最小连接算法(lc)，就是将请求调度到连接数量最小的服务器上。

4. **加权最小连接**

   加权最小连接算法(wlc)，通过设置权重，来决定分配给服务器请求，在平横实际请求的同时兼顾服务器性能，权重大的服务器收到的请求占比较多。

5. **目标地址散列**

   目标地址散列算法(dh)，根据目标IP地址通过散列函数将目标IP服务器建立映射关系，出现服务器不可用或负载过高的情况下，发往该IP的请求会固定发给该服务器

6. **源地址散列**

   源地址散列算法(sh)，与目标地址散列类似，但是它是根据源地址散列算法进行静态分配固定的服务器资源

7. **基于局部的最少连接**

   基于局部的最少连接算法(lblc)，该算法主要用于Cache集群系统，用于判断服务器的活动状态且负载能力不佳的情况下，将发往该IP地址的数据包重定向到其他服务器，并按照最小连接数算法分配到集群其中的一台服务器

8. **带有复制调度的基于局部的最少连接**

   带有复制调度的基于局部的最少连接算法(lblcr)，他会维护目标IP到服务器集群之间的连接记录，防止单点负载过高

9. **最短期望的延迟**

   最短期望的延迟算法(sed)，该算法将网络连接分配给具有最短预期延迟的服务器

10. **从不排队调度**

    从不排队调度算法(nq)，当有空闲服务器可用时，请求会被发送到该服务器，如果没有，请求将会被发送到最小期望的延迟服务器(最短期望的延迟)

# 4. 命令格式

简化：

```shell
用于虚拟服务
-A		# 添加一个虚拟服务,使用IP+端口+协议定义
—E		# 编辑一个虚拟服务
-D		# 删除一个虚拟服务
-C		# 清空虚拟服务列表
-s		# 指定LVS采用的算法
-S		# 保存虚拟服务规则至标准输出，输出的规则可通过-R导入
用于服务器
-a		# 在虚拟服务中添加一个服务器
-e		# 在虚拟服务中编辑一个服务器
-d		# 在虚拟服务中删除一个服务器
-r		# 设置真实服务器IP地址与端口信息
-g		# 设置LVS工作模式为Dr
-i		# 设置LVS工作模式为Tun
-m		# 设置LVS工作模式为Nat
-w		# 设置权重
其他
-L		# 显示虚拟服务列表
-n		# 数字格式输出
-c		# 连接状态配合-L使用
-t		# 使用TCP
-u		# 使用UDP
例：
[root@localhost ~]# ipvsadm -A 192.168.1.1:80 -s rr	
# 设置192.168.1.1:80虚拟服务并使用轮询(rr)算法
[root@localhost ~]# ipvadm -a -t 192.168.1.1:80 -r 192.168.2.1:80 -m -w
# 从192.168.1.1:80虚拟服务中添加192.168.2.1:80服务器并设置工作模式为Nat，权重为1(不指定默认为1)
[root@localhost ~]# ipvadm -a -t 192.168.1.1:80 -r 192.168.2.2:80 -m -w 2
# 从192.168.1.1:80虚拟服务中添加192.168.2.2:80服务器并设置工作模式为Nat，权重为2
```

完整：

```shell
[root@localhost ~]# ipvsadm --help
ipvsadm v1.31 2019/12/24（使用popt和IPVS v1.2.1编译）
用法：
  ipvsadm -A|E 虚拟服务 [-s 调度程序] [-p [超时]] [-M 网络掩码] [--pe persistence_engine] [-b sched-flags]
  ipvsadm -D 虚拟服务
  ipvsadm -C
  ipvsadm -R
  ipvsadm -S [-n]
  ipvsadm -a|e 虚拟服务 -r 服务器地址 [选项]
  ipvsadm -d 虚拟服务 -r 服务器地址
  ipvsadm -L|l [虚拟服务] [选项]
  ipvsadm -Z [虚拟服务]
  ipvsadm --set tcp tcpfin udp
  ipvsadm --start-daemon {master|backup} [daemon-options]
  ipvsadm --stop-daemon {master|backup}
  ipvsadm -h

命令：
允许做多或做空期权。
  --add-service -A 添加带有选项的虚拟服务
  --edit-service -E 使用选项编辑虚拟服务
  --delete-service -D 删除虚拟服务
  --clear -C 清空整个表
  --restore -R 从标准输入恢复规则
  --save -S 保存规则到标准输出
  --add-server -a 添加带有选项的真实服务器
  --edit-server -e 使用选项编辑真实服务器
  --delete-server -d 删除真实服务器
  --list -L|-l 列出表
  --zero -Z 服务或所有服务中的零计数器
  --set tcp tcpfin udp 设置连接超时值
  --start-daemon 启动连接同步守护进程
  --stop-daemon 停止连接同步守护进程
  --help -h 显示此帮助信息

虚拟服务：
  --tcp-service|-t 服务地址 服务地址是主机[:端口]
  --udp-service|-u 服务地址 服务地址是主机[:端口]
  --sctp-service 服务地址 服务地址是主机[:端口]
  --fwmark-service|-f fwmark fwmark 是大于零的整数

选项：
  --ipv6 -6 fwmark 条目使用 IPv6
  --scheduler -s 调度程序 rr|wrr|lc|wlc|lblc|lblcr|dh|sh|sed|nq|fo|ovf|mh 之一，
                                      默认调度程序是 wlc。
  --pe engine 替代持久性引擎可能是 sip，
                                      默认情况下未设置。
  --persistent -p [超时] 持久化服务
  --netmask -M netmask 持久粒度掩码
  --real-server -r server-address server-address 是主机（和端口）
  --gatewaying -g 网关（直接路由）（默认）
  --ipip -i ipip 封装（隧道）
  --masquerading -m 伪装（NAT）
  --tun-type 类型之一 ipip|gue|gre,
                                      默认隧道类型为 ipip。
  --tun-port port 隧道目的端口
  --tun-nocsum 没有校验和的隧道封装
  --tun-csum 带校验和的隧道封装
  --tun-remcsum 带有远程校验和的隧道封装
  --weight -w 真实服务器的权重容量
  --u-threshold -x uthreshold 连接上限阈值
  --l-threshold -y lthreshold 连接的下限阈值
  --connection -c 当前 IPVS 连接的输出
  --timeout 超时输出（tcp tcpfin udp）
  --daemon 输出守护进程信息
  --stats 输出统计信息
  --rate 输出速率信息
  --exact 扩展数字（显示精确值）
  --thresholds 输出阈值信息
  --persistent-conn 持久连接信息的输出
  --tun-info 输出隧道信息
  --nosort 禁用服务/服务器条目的排序输出
  --sort 什么都不做，为了向后兼容
  --ops -o 一包调度
  --numeric -n 地址和端口的数字输出
  --sched-flags -b flags 调度程序标志（逗号分隔）
守护进程选项：
  --syncid sid syncid 用于连接同步（默认=255）
  --sync-maxlen length 最大同步消息长度（默认=1472）
  --mcast-interface interface 用于连接同步的多播接口
  --mcast-group 地址 IPv4/IPv6 组（默认=224.0.0.81）
  --mcast-port 端口 UDP 端口（默认=8848）
  --mcast-ttl ttl 多播 TTL (默认=1)
```

# 实验

## VS/NAT

拓扑：

> 简述：在内外部署一套Web应用服务器对外提供服务，由于并发量较大，许采用LVS实现负载均衡。客户端通过访问：100.1.1.2:80获取到Web应用资源。

![image-20220207233553299](20220207233553299.png)

- 配置Web01服务器

  ```shell
  [root@apache01 ~]# vi /etc/sysconfig/network-scripts/ifcfg-ens33
  TYPE=Ethernet
  PROXY_METHOD=none
  BROWSER_ONLY=no
  BOOTPROTO=none
  DEFROUTE=yes
  IPV4_FAILURE_FATAL=no
  IPV6INIT=yes
  IPV6_AUTOCONF=yes
  IPV6_DEFROUTE=yes
  IPV6_FAILURE_FATAL=no
  NAME=ens33
  UUID=d9aa645a-2436-4aa2-b595-88fe28f7eeb9
  DEVICE=ens33
  ONBOOT=yes
  IPADDR=192.168.20.1					
  PREFIX=24
  GATEWAY=192.168.20.254				# 网关指向LVS内部接口
  [root@apache01 ~]# dnf -y install httpd
  [root@apache01 ~]# systemctl enable --now httpd
  [root@apache01 ~]# systemctl disable --now firewalld
  [root@apache01 ~]# echo "apache01" > /var/www/html/index.html
  [root@apache01 ~]# curl http://localhost
  apache01
  ```

- 配置Web02服务器

  ```shell
  [root@apache02 ~]# vi /etc/sysconfig/network-scripts/ifcfg-ens33
  TYPE=Ethernet
  PROXY_METHOD=none
  BROWSER_ONLY=no
  BOOTPROTO=none
  DEFROUTE=yes
  IPV4_FAILURE_FATAL=no
  IPV6INIT=yes
  IPV6_AUTOCONF=yes
  IPV6_DEFROUTE=yes
  IPV6_FAILURE_FATAL=no
  NAME=ens33
  UUID=d9aa645a-2436-4aa2-b595-88fe28f7eeb9
  DEVICE=ens33
  ONBOOT=yes
  IPADDR=192.168.20.2					
  PREFIX=24
  GATEWAY=192.168.20.254				# 网关指向LVS内部接口
  [root@apache02 ~]# dnf -y install httpd
  [root@apache02 ~]# systemctl enable --now httpd
  [root@apache02 ~]# systemctl disable --now firewalld
  [root@apache02 ~]# echo "apache02" > /var/www/html/index.html
  [root@apache02 ~]# curl http://localhost
  apache02
  ```

- 配置LVS调度

  > 虽然LVS内置在内核中但是我们需要安装ipvsadm工具对其进行配置


  ```shell
  IP配置略
  [root@LVS ~]# dnf -y install ipvsadm		# 安装ipvsadm工具包
  [root@LVS ~]# systemctl disable --now firewalld
  [root@LVS ~]# ipvsadm -A -t 192.168.10.1:80 -s rr
  [root@LVS ~]# ipvsadm -a -t 192.168.10.1:80 -r 192.168.20.1:80 -m -w 1
  [root@LVS ~]# ipvsadm -a -t 192.168.10.1:80 -r 192.168.20.2:80 -m -w 1
  [root@LVS ~]# ipvsadm -S > /etc/sysconfig/ipvsadm
  [root@LVS ~]# systemctl enable --now ipvsadm
  [root@LVS ~]# echo "1" > /proc/sys/net/ipv4/ip_forward
  [root@LVS ~]# systemctl status ipvsadm
  ● ipvsadm.service - Initialise the Linux Virtual Server
     Loaded: loaded (/usr/lib/systemd/system/ipvsadm.service; enabled; vendor preset: disabled)
     Active: active (exited) since Wed 2022-02-09 23:22:52 EST; 40min ago
    Process: 970 ExecStart=/bin/bash -c exec /sbin/ipvsadm-restore < /etc/sysconfig/ipvsadm (code=exited, status=0/SUCCES>
   Main PID: 970 (code=exited, status=0/SUCCESS)
      Tasks: 0 (limit: 4757)
     Memory: 0B
     CGroup: /system.slice/ipvsadm.service
  
  Feb 09 23:22:52 localhost.localdomain systemd[1]: Starting Initialise the Linux Virtual Server...
  Feb 09 23:22:52 localhost.localdomain systemd[1]: Started Initialise the Linux Virtual Server.
  
  # 我们通过LVS本地访问VIP地址就可以得到效果了
  
  [root@LVS ~]# curl http://192.168.10.1
  apache01
  [root@LVS ~]# curl http://192.168.10.1
  apache02
  [root@LVS ~]# curl http://192.168.10.1
  apache01
  [root@LVS ~]# curl http://192.168.10.1
  apache02
  [root@LVS ~]# curl http://192.168.10.1
  apache01
  [root@LVS ~]# curl http://192.168.10.1
  apache02
  [root@LVS ~]# curl http://192.168.10.1
  apache01
  [root@LVS ~]# curl http://192.168.10.1
  apache02
  [root@LVS ~]# curl http://192.168.10.1
  apache01
  
  # 查看列表
  
  [root@LVS ~]# ipvsadm -L
  IP Virtual Server version 1.2.1 (size=4096)
  Prot LocalAddress:Port Scheduler Flags
    -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
  TCP  LVS:http rr
    -> 192.168.20.1:http            Masq    1      0          5			# 向192.168.20.1转发了5次
    -> 192.168.20.2:http            Masq    1      0          4			# 向192.168.20.2转发了4次
  [root@LVS ~]#
  ```

  

## VS/DR

拓扑：

> 此实验与VS/NAT的实验的区别就是将Web应用服务器的网关设置为真实网关，并添加Lo回环接口地址，关闭ARP。


![image-20220211005508487](20220211005508487.png)


- 配置Web01服务器

  > 应用服务器重要步骤即：先配置ARP转发策略，再配置lo地址

  ```shell
  [root@apache01 ~]# tee > /etc/sysctl.conf << EOF
  net.ipv4.conf.all.arp_ignore = 1
  net.ipv4.conf.lo.arp_ignore = 1
  net.ipv4.conf.all.arp_announce = 2
  net.ipv4.conf.lo.arp_announce = 2
  EOF
  [root@apache01 ~]# ip add
  1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
      link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
      inet 127.0.0.1/8 scope host lo
         valid_lft forever preferred_lft forever
      inet6 ::1/128 scope host
         valid_lft forever preferred_lft forever
  2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
      link/ether 00:0c:29:f2:2a:52 brd ff:ff:ff:ff:ff:ff
      inet 192.168.10.101/24 brd 192.168.10.255 scope global noprefixroute ens33
         valid_lft forever preferred_lft forever
      inet6 fe80::20c:29ff:fef2:2a52/64 scope link noprefixroute
         valid_lft forever preferred_lft forever
  [root@apache01 ~]# ip address add 172.16.10.1/32 dev lo
  # ens33 自行按照拓扑图正常配置即可，网关指向正常网关，而非LVS
  [root@apache01 ~]# systemctl disable --now firewalld
  ```



  ```shell
  [root@apache01 ~]# dnf -y install httpd
  [root@apache01 ~]# systemctl enable --now httpd
  [root@apache01 ~]# echo "apache01" > /var/www/html/index.html
  [root@apache01 ~]# curl http://localhost
  ```



- 配置Web02服务器

  ```shell
  [root@apache02 ~]# tee > /etc/sysctl.conf << EOF
  net.ipv4.conf.all.arp_ignore = 1
  net.ipv4.conf.lo.arp_ignore = 1
  net.ipv4.conf.all.arp_announce = 2
  net.ipv4.conf.lo.arp_announce = 2
  EOF
  [root@apache02 ~]# ip address add 172.16.10.1/32 dev lo
  [root@apache02 ~]# systemctl disable -now firewalld
  [root@apache02 ~]# dnf -y install httpd
  [root@apache02 ~]# systemctl enable --now httpd
  [root@apache02 ~]# echo "apache02" > /var/www/html/index.html
  [root@apache02 ~]# curl http://localhost
  ```



- 配置LVS调度

  ```shell
  [root@LVS ~]# echo "1" > /proc/sys/net/ipv4/ip_forwared
  [root@LVS ~]# dnf -y install ipvsadm
  [root@LVS ~]# ipvsadm -A -t 172.16.10.1:80 -s rr
  [root@LVS ~]# ipvsadm -a -t 172.16.10.1:80 -r 192.168.10.101:80 -g
  [root@LVS ~]# ipvsadm -a -t 172.16.10.1:80 -r 192.168.10.102:80 -g
  [root@LVS ~]# ipvsadm -L
  ```


  ```shell
  [root@LVS ~]# ipvsadm -S > /etc/sysconfig/ipvsadm
  [root@LVS ~]# systemctl enable --now ipvsadm
  [root@LVS ~]# systemctl disable --now firewalld
  ```



