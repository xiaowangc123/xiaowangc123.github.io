---
title: Docker网络与iptables
tags:
  - Docker
  - iptables
  - 防火墙
cover: img/fengmian/docker.jpeg
categories: 容器
abbrlink: 7ab398bf
date: 2024-02-09 02:03:17
---
# 简述

下图是TCP三次握手完成后在iptables中所有规则被匹配的次数

![image-20240208163903929](image-20240208163903929-1707381544844-2.png)

- PREROUTING链

  ![image-20240208163141255](image-20240208163141255.png)

- FORWARD链

  ![image-20240208163725169](image-20240208163725169.png)

通过上图和抓包的结果得出如下结论：

- 客户端访问有2个包
- 服务器响应有1个包
- 某些规则只匹配了1次，某些规则匹配了3次

# 第一次握手

- 本人在客户端通过使用Telnet工具对服务器192.168.66.100的80端口发起请求

  ![image-20240208164717035](image-20240208164717035.png)

  ```shell
  root@master:~# ip add
  1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
      link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
      inet 127.0.0.1/8 scope host lo
         valid_lft forever preferred_lft forever
      inet6 ::1/128 scope host
         valid_lft forever preferred_lft forever
  2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
      link/ether 00:0c:29:b6:16:6b brd ff:ff:ff:ff:ff:ff
      altname enp2s1
      inet 192.168.66.100/24 brd 192.168.66.255 scope global ens33
         valid_lft forever preferred_lft forever
      inet6 fe80::20c:29ff:feb6:166b/64 scope link
         valid_lft forever preferred_lft forever
  3: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
      link/ether 02:42:5f:9a:dc:2c brd ff:ff:ff:ff:ff:ff
      inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
         valid_lft forever preferred_lft forever
      inet6 fe80::42:5fff:fe9a:dc2c/64 scope link
         valid_lft forever preferred_lft forever
  19: veth50b382d@if18: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master docker0 state UP group default
      link/ether fa:9f:74:9c:7e:80 brd ff:ff:ff:ff:ff:ff link-netnsid 0
      inet6 fe80::f89f:74ff:fe9c:7e80/64 scope link
         valid_lft forever preferred_lft forever
  ```

- **第一次握手**：客户端发送SYN包（SYN=x）的数据包到服务器，并进入SYN_SEND状态。这个数据包的状态是**NEW**，因为它是新建立的连接。当流量进入网卡后首先经过Preroutinng链Raw表、Mangle表和Nat表。

  ```shell
  root@master:~# iptables -vnL PREROUTING -t raw
  Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
   pkts bytes target     prot opt in     out     source               destination
  root@master:~# iptables -vnL PREROUTING -t mangle
  Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
   pkts bytes target     prot opt in     out     source               destination
  root@master:~# iptables -vnL PREROUTING -t nat
  Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
   pkts bytes target     prot opt in     out     source               destination
      1    52 DOCKER     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL
  ```

  Raw和Mangle表都无规则，只有Nat表有一条规则，这条规则表示数据包来自**任意网卡**、**任意IP**，目的地为**任意网卡**、**任意IP**和**任意端口**的数据包将进入**Docker自定义链Nat表**。

  ```shell
  root@master:~# iptables -vnL DOCKER -t nat
  Chain DOCKER (2 references)
   pkts bytes target     prot opt in     out     source               destination
      0     0 RETURN     all  --  docker0 *       0.0.0.0/0            0.0.0.0/0
      1    52 DNAT       tcp  --  !docker0 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:80 to:172.17.0.2:80
  ```

  此时Docker自定义链Nat表有2条规则

  1. 来自docker0网卡的所有数据包将不做处理
  2. **来自非docker0网卡的TCP协议且端口为80的数据包将做DNAT(目标地址转换)为172.17.0.2:80**

  匹配第2条规则对数据包进行数据处理**系统将记录下次Nat的转换的记录**，结束后离开PreRouting链进行**路由决策**。

  ![image-20240208180430796](image-20240208180430796.png)

  通过查询**路由表**来**判断是否为本机**的数据包，是就进入Input链否则进入Forward链。

  ```shell
  root@master:~# ip route list table local
  local 127.0.0.0/8 dev lo proto kernel scope host src 127.0.0.1
  local 127.0.0.1 dev lo proto kernel scope host src 127.0.0.1
  broadcast 127.255.255.255 dev lo proto kernel scope link src 127.0.0.1
  local 172.17.0.1 dev docker0 proto kernel scope host src 172.17.0.1
  broadcast 172.17.255.255 dev docker0 proto kernel scope link src 172.17.0.1
  local 192.168.66.100 dev ens33 proto kernel scope host src 192.168.66.100
  broadcast 192.168.66.255 dev ens33 proto kernel scope link src 192.168.66.100
  root@master:~# route -n
  Kernel IP routing table
  Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
  0.0.0.0         192.168.66.254  0.0.0.0         UG    0      0        0 ens33
  172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
  192.168.66.0    0.0.0.0         255.255.255.0   U     0      0        0 ens33
  ```

  通过查询数据包的目的地址显示不属于本机的，但**匹配到一条路由是发往docker0网卡**的

  ```shell
  Kernel IP routing table
  Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
  172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
  ```

  ![image-20240208175023537](image-20240208175023537.png)

  

  数据包将通过docker0网卡发送出去，接着进入Forward链的Mangle和Filter表，**如果不满足条件，数据包将被拒绝**。

  ```shell
  root@master:~# iptables -vnL FORWARD -t mangle
  Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
   pkts bytes target     prot opt in     out     source               destination
  root@master:~# iptables -vnL FORWARD -t filter
  Chain FORWARD (policy DROP 21 packets, 928 bytes)
   pkts bytes target     prot opt in     out     source               destination
      0   304 DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
      0   304 DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
      0   120 ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
      0    52 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
      0   132 ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
      0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
  ```

  ![image-20240208180901916](image-20240208180901916.png)

  Filter表中有5条规则首先进入DOCKER-USER自定义链中的filter表。filter表中的规则使所有数据包通过并返回，不做处理

  ```shell
  root@master:~# iptables -vnL DOCKER-USER -t filter
  Chain DOCKER-USER (1 references)
   pkts bytes target     prot opt in     out     source               destination
      1   304 RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
  ```

  ![image-20240208181722606](image-20240208181722606.png)

  在DOCKER-USER自定义链的Filter表中并未做处理只是RETURN回来了接着继续执行FORWARD链FIlter表的第二条规则,并进入DOCKER-ISOLATION-STAGE-1链。这条自定义链子中有2条规则：

  - 来自docker0网卡的数据包到非docker0网卡的数据包将进入DOCKER-ISOLATION-STAGE-2自定义链
  - **不满足第一条规则将继续RETURN回去**。

  ```shell
  root@master:~# iptables -vnL DOCKER-ISOLATION-STAGE-1 -t filter
  Chain DOCKER-ISOLATION-STAGE-1 (1 references)
   pkts bytes target     prot opt in     out     source               destination
      0   132 DOCKER-ISOLATION-STAGE-2  all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
      1   304 RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
  ```

  接着进入匹配第3条，第3条只允许RELATED,ESTABLISHED状态的数据包通过，因为是第一次请求，数据包状态为New，所以不匹配

  ```shell
      0   120 ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
  ```

  接着进入匹配第4条，发往docker0的数据包将进入DOCKER自定义链的Filter表

  ```shell
   0    52 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
  ```

  DOCKER链的Filter表允许来自非docker0网卡到docker0网卡，且目的地址是172.17.0.2端口为80的数据包通过。

  ```shell
  root@master:~# iptables -vnL DOCKER -t filter
  Chain DOCKER (1 references)
   pkts bytes target     prot opt in     out     source               destination
      1    52 ACCEPT     tcp  --  !docker0 docker0  0.0.0.0/0            172.17.0.2           tcp dpt:80
  ```

  

  ![image-20240208184023803](image-20240208184023803.png)

  通过后将进入PostRouting链的Mangle和Nat表，都不匹配，将数据包转发到docker0网卡

  ```shell
  root@master:~# iptables -vnL POSTROUTING -t mangle
  Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
   pkts bytes target     prot opt in     out     source               destination
  root@master:~# iptables -vnL POSTROUTING -t nat
  Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
   pkts bytes target     prot opt in     out     source               destination
      0     0 MASQUERADE  all  --  *      !docker0  172.17.0.0/16        0.0.0.0/0
      0     0 MASQUERADE  tcp  --  *      *       172.17.0.2           172.17.0.2           tcp dpt:80
  ```

  ![image-20240208231300952](image-20240208231300952.png)

  docker0网卡属于网桥设备桥接多块veth网卡，而veth网卡又和容器网卡一一对应。这里就不展开说明了。客户端到容器的数据包在宿主机经过上述转发成功达到容器。

## 总结

总结上述转发流程。整体如下图所示，**无需关注绿色线条。绿色代表从容器转发到客户端或公网的流向**。

TCP三次握手的第一个SYN同步数据包转发到容器的过程在iptables匹配规则的次数

```shell
root@master:~# iptables -vnL -t nat
Chain PREROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
    1    52 DOCKER     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL

Chain DOCKER (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 RETURN     all  --  docker0 *       0.0.0.0/0            0.0.0.0/0
    1   112 DNAT       tcp  --  !docker0 *       0.0.0.0/0            0.0.0.0/0            tcp dpt:80 to:172.17.0.2:80
```

TCP三次握手共有2个从客户端发往容器的数据包，1个从容器响应的数据包，而在PREROUTING链的NAT表中只匹配了一次。这是因为新的连接被建立时，NAT会跟踪这条连接并记录下来，当后续的数据包再次经过时会查找已经存在的条目，如果匹配就会继续使用这个条目的信息，如果不匹配则再次进行转换。这样可以提高NAT转换效率，就类似NAT缓存。**所以一次完整的连接在iptables的规则中只匹配了一次**。这个刚好对应简述中的第一张图

![](完整版.png)

在Prerouting链中进行NAT之后将进行路由决策，可以通过命令`ip route list table local`查询数据包是否为本机，很显然在NAT转换的过程中目的地址就已经变更成为172.17.0.2了，与命令查询的结果并不匹配。**不配进入forward链**，匹配进入Input链。

```shell
root@master:~# ip route list table local
local 127.0.0.0/8 dev lo proto kernel scope host src 127.0.0.1
local 127.0.0.1 dev lo proto kernel scope host src 127.0.0.1
broadcast 127.255.255.255 dev lo proto kernel scope link src 127.0.0.1
local 172.17.0.1 dev docker0 proto kernel scope host src 172.17.0.1
broadcast 172.17.255.255 dev docker0 proto kernel scope link src 172.17.0.1
local 192.168.66.100 dev ens33 proto kernel scope host src 192.168.66.100
broadcast 192.168.66.255 dev ens33 proto kernel scope link src 192.168.66.100
```

在Forward链中只有filter表有规则，且**链默认策略是拒绝**，也就是**必须匹配否则数据包将被拒绝**。

1. 第一条规则会将所有数据包转发到DOCKER-USER链的filter表中所以pkts+1，DOCKER-USER链的filter表中只有一条规则允许所有数据包，并返回(return)forward链的filter表中接着匹配下面的规则，所以DOCKER-USER中filter表的pkts+1。

   ```shell
   Chain FORWARD (policy DROP 21 packets, 928 bytes)
    pkts bytes target     prot opt in     out     source               destination
    1   11M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    0   11M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    0   11M ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
    0    52 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
    0  136K ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER-USER (1 references)
    pkts bytes target     prot opt in     out     source               destination
    1   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
   ```

2. 接着继续进入DOCKER-ISOLATION-STAGE-1链的filter表，因为允许所有数据包所以pkts+1。DOCKER-ISOLATION-STAGE-1链的filter表中有2条规则，数据包来自docker0网卡并转发到非docker0网卡将进入DOCKER-ISOLATION-STAGE-2。而我们的数据包是从ens33到docker0的，所以不匹配。接着继续下一条规则return所有数据包回到forward链的filter表，所以第二条规则pkts+1

   ```shell
   Chain FORWARD (policy DROP 21 packets, 928 bytes)
    pkts bytes target     prot opt in     out     source               destination
    1   11M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    1   11M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    0   11M ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
    0    52 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
    0  136K ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER-ISOLATION-STAGE-1 (1 references)
    pkts bytes target     prot opt in     out     source               destination
    0  136K DOCKER-ISOLATION-STAGE-2  all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    1   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER-USER (1 references)
    pkts bytes target     prot opt in     out     source               destination
    1   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
   ```

3. 返回到forward链的filter表继续匹配第3条规则`ACCEPT all -- * docker0 0.0.0.0/0 0.0.0.0/0 ctstate RELATED,ESTABLISHED`,这条允许的规则相对来说**比较重要**，它只允许包状态为`RELATED`,`ESTABLISHED`的数据包通过。什么意思呢？因为TCP三次握手的第一个和第二个数据包都是new状态，是刚刚建立的状态。iptables的**状态跟踪连接有4种**：

   1. **NEW**：这个数据包是收到的第一个数据包
   2. **ESTABLISHED**：只要发送并接到应答，一个数据包的状态就会从NEW变成ESTABLISHED，并且改状态会继续匹配后续数据包。
   3. **RELATED**：当数据包的状态处于ESTABLISHED状态的连接有关系的时候，就会被认为是RELATED。
   4. **INVALID**：未知连接或者没有任何关系的状态，一般这种数据包都是被拒绝的。

   所以在概述中，**TCP三次握手后这第三条规则才匹配一次**。因为这次状态是NEW所以不匹配，直接到第四条，第四条允许所有来自任意网卡的到docker0网卡的数据包进入DOCKER链的filter表中，所以第四条规则pkts+1。DOCKER链的filter表中只有一条规则，允许TCP协议从非docker0网卡到docker0网卡且目的IP地址为172.17.0.2端口为80的数据包通过(ACCEPT)。至此数据包离开了FORWARD链。DOCKER链中filter表pkts+1。

   ```shell
   Chain FORWARD (policy DROP 21 packets, 928 bytes)
    pkts bytes target     prot opt in     out     source               destination
    1   11M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    1   11M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    0   11M ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
    1    52 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
    0  136K ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER (1 references)
    pkts bytes target     prot opt in     out     source               destination
    1    52 ACCEPT     tcp  --  !docker0 docker0  0.0.0.0/0            172.17.0.2           tcp dpt:80
    
    Chain DOCKER-ISOLATION-STAGE-1 (1 references)
    pkts bytes target     prot opt in     out     source               destination
    0  136K DOCKER-ISOLATION-STAGE-2  all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    1   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER-USER (1 references)
    pkts bytes target     prot opt in     out     source               destination
    1   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
   ```

   因为后续的POSRROUTIG链中并未有相关规则就略过了。数据包顺利的到达了docker0网桥并转发给了容器。第一次握手到此结束

# 第二次握手

**容器到客户端是绿色的线**

- 第二次握手是由容器发往客户端的SYN+ACK(同步确认数据包)。当容器发送同步确认数据包即响应数据包时，将通过默认路由将其发送给docker0网桥。而Docker0和宿主机属于**同一个网络空间**所以直接进入PreRouting链。

  ![image-20240209002004288](image-20240209002004288.png)

  

- 进入到PreRouting链中，因为这是一个连接的响应数据包或说是后续数据包，因为先前有做NAT转换把192.168.66.100转换成172.17.0.2并记录了下来所以这次并不会进入NAT表进行匹配。而是使用之前的的NAT条目(缓存)将172.17.0.2转换成192.168.66.100，并离开PreRouting链进行路由决策。

  ![image-20240209002357795](image-20240209002357795.png)

- 通过查询**路由表**来**判断是否为本机**的数据包，是就进入Input链否则进入Forward链。显然是不是本机的而是发往192.168.66.0网段的需要通过ens33网卡转发出去。接着进入forward链。

  ```shell
  root@master:~# ip route list table local
  local 127.0.0.0/8 dev lo proto kernel scope host src 127.0.0.1
  local 127.0.0.1 dev lo proto kernel scope host src 127.0.0.1
  broadcast 127.255.255.255 dev lo proto kernel scope link src 127.0.0.1
  local 172.17.0.1 dev docker0 proto kernel scope host src 172.17.0.1
  broadcast 172.17.255.255 dev docker0 proto kernel scope link src 172.17.0.1
  local 192.168.66.100 dev ens33 proto kernel scope host src 192.168.66.100
  broadcast 192.168.66.255 dev ens33 proto kernel scope link src 192.168.66.100
  root@master:~# route -n
  Kernel IP routing table
  Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
  0.0.0.0         192.168.66.254  0.0.0.0         UG    0      0        0 ens33
  172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
  192.168.66.0    0.0.0.0         255.255.255.0   U     0      0        0 ens33
  ```

- 进入forward链的filter表之后匹配到第一条规则并进入自定义DOCKER-USER链中filter表，因为第一条规则允许所有数据包

  ```shell
  Chain FORWARD (policy DROP 21 packets, 928 bytes)
   pkts bytes target     prot opt in     out     source               destination
   0   11M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
   0   11M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
   0   11M ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
   0    52 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
   0  136K ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
   0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
  ```

  ![image-20240209003521931](image-20240209003521931.png)

- 自定义DOCKER-USER链中filter表中规则ruturn返回所有数据包接着回到forward链中的filter表。匹配第二条规则

  ![image-20240209003934693](image-20240209003934693.png)

- 第二条规则允许所有数据包进入自定义链DOCKER-ISOLATION-STAGE-1中的filter表。而表中有2条规则第1条匹配所有来自docker0网卡到非docker0网卡的数据包，并进入自定义链DOCKER-ISOLATION-STAGE-2中的filter表，自定义链DOCKER-ISOLATION-STAGE-2中的filter表中的规则禁止容器数据转发到容器的数据包。因为我们是响应客户端所以不匹配。此规则因该是防止容器到容器的数据包进入到宿主机，因为容器到容器的数据包在docker0网桥就能进行转发了。所以继续匹配DOCKER-ISOLATION-STAGE-2中的filter表中的第2条规则并返回到DOCKER-ISOLATION-STAGE-1中的filter表。接着匹配DOCKER-ISOLATION-STAGE-1中的filter表中的第二条规则ruturn返回所有数据包回到forward链中的filter表

  ```shel
  Chain FORWARD (policy DROP 21 packets, 928 bytes)
   pkts bytes target     prot opt in     out     source               destination
   0   11M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
   0   11M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
   0   11M ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
   0    52 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
   0  136K ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
   0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
   
   Chain DOCKER-ISOLATION-STAGE-1 (1 references)
   pkts bytes target     prot opt in     out     source               destination
   0  136K DOCKER-ISOLATION-STAGE-2  all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
   0   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
  
  Chain DOCKER-ISOLATION-STAGE-2 (1 references)
   pkts bytes target     prot opt in     out     source               destination
      0     0 DROP       all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
      0  136K RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
  ```

  ![image-20240209004427086](image-20240209004427086.png)

- 第3条也无法匹配，因出网卡并非是docker0且第二次握手的数据包也是NEW状态。第4条也无法匹配因为出网卡并非是docker0。接着匹配第5条规则，第5条规则允许所有来自docker0网卡并去往非docker0网卡的流量。自此，响应数据包将经过PostRouting链从ens33网卡转发出去

  ```shell
  Chain FORWARD (policy DROP 21 packets, 928 bytes)
   pkts bytes target     prot opt in     out     source               destination
   0   11M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
   0   11M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
   0   11M ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
   0    52 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
   0  136K ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
   0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
  ```

## 总结

当从容器响应客户端的数据包进入docker0网卡时，docker0是跟宿主机是同一个网络空间，数据包直接进入PreRouting链。在第一次握手时，TCP连接就已经被Linux追踪了，二次握手和后续数据包都属于同一个连接，所以不会进入PreRouting链中的NAT表匹配规则，而是通过前面第一次请求所建立的NAT条目(缓存)将**源地址**转换成为宿主机的IP地址即192.168.66.100。并进行路由决策环节。

通过查询路由匹配到`192.168.66.0 0.0.0.0 255.255.255.0 U 0 0 0 ens33`这条路由规则并通过ens33网卡转发出去，接着进入Forward链的filter表。

```shell
root@master:~# ip route list table local
local 127.0.0.0/8 dev lo proto kernel scope host src 127.0.0.1
local 127.0.0.1 dev lo proto kernel scope host src 127.0.0.1
broadcast 127.255.255.255 dev lo proto kernel scope link src 127.0.0.1
local 172.17.0.1 dev docker0 proto kernel scope host src 172.17.0.1
broadcast 172.17.255.255 dev docker0 proto kernel scope link src 172.17.0.1
local 192.168.66.100 dev ens33 proto kernel scope host src 192.168.66.100
broadcast 192.168.66.255 dev ens33 proto kernel scope link src 192.168.66.100
root@master:~# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.66.254  0.0.0.0         UG    0      0        0 ens33
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
192.168.66.0    0.0.0.0         255.255.255.0   U     0      0        0 ens33
```

在Forward链中只有filter表有规则，且**链默认策略是拒绝**，也就是**必须匹配否则数据包将被拒绝**。

1. 下面的pkts(包)数量是第一次握手的记录，让我们继续看看在第二次握手后pkts的变化。

   ```shell
   Chain FORWARD (policy DROP 21 packets, 928 bytes)
    pkts bytes target     prot opt in     out     source               destination
    1   11M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    1   11M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    0   11M ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
    1    52 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
    0  136K ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER (1 references)
    pkts bytes target     prot opt in     out     source               destination
    1    52 ACCEPT     tcp  --  !docker0 docker0  0.0.0.0/0            172.17.0.2           tcp dpt:80
    
    Chain DOCKER-ISOLATION-STAGE-1 (1 references)
    pkts bytes target     prot opt in     out     source               destination
    0  136K DOCKER-ISOLATION-STAGE-2  all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    1   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER-USER (1 references)
    pkts bytes target     prot opt in     out     source               destination
    1   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
   ```

2. 第1条规则允许所有数据包进入DOCKER-USER链pkts+1。DOCKER-USER链中的规则只有一条规则ruturn返回所有所有数据包pkts+1。

   ```shell
   Chain FORWARD (policy DROP 21 packets, 928 bytes)
    pkts bytes target     prot opt in     out     source               destination
    2   11M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    1   11M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    0   11M ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
    1    52 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
    0  136K ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER-USER (1 references)
    pkts bytes target     prot opt in     out     source               destination
    2   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
   ```

3. 接着匹配第2条规则允许所有数据包进入DOCKER-ISOLATION-STAGE-1链的filter表，pkts+1。DOCKER-ISOLATION-STAGE-1链的filter表中第1条规则匹配所有来自docker0转发到非docker0的流量并进入DOCKER-ISOLATION-STAGE-2链的filter表，pkts+1。

   ```shel
   Chain FORWARD (policy DROP 21 packets, 928 bytes)
    pkts bytes target     prot opt in     out     source               destination
    2   11M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    2   11M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    0   11M ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
    1    52 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
    0  136K ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER-ISOLATION-STAGE-1 (1 references)
    pkts bytes target     prot opt in     out     source               destination
    1  136K DOCKER-ISOLATION-STAGE-2  all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    1   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER-USER (1 references)
    pkts bytes target     prot opt in     out     source               destination
    2   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
   ```

4. 进入到DOCKER-ISOLATION-STAGE-2链的filter表，第一条拒绝来自容器到容器的数据包，防止容器流量进入宿主机，显然不匹配，通过第2条return返回到DOCKER-ISOLATION-STAGE-1链的filter表，pkts+1。回到DOCKER-ISOLATION-STAGE-1链的filter表继续匹配第2条并return返回到forward链的filter表中，pkts+1

   ```shell
   Chain FORWARD (policy DROP 21 packets, 928 bytes)
    pkts bytes target     prot opt in     out     source               destination
    2   11M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    2   11M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    0   11M ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
    1    52 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
    0  136K ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER-ISOLATION-STAGE-1 (1 references)
    pkts bytes target     prot opt in     out     source               destination
    1  136K DOCKER-ISOLATION-STAGE-2  all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    2   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER-ISOLATION-STAGE-2 (1 references)
    pkts bytes target     prot opt in     out     source               destination
       0     0 DROP       all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
       1  136K RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER-USER (1 references)
    pkts bytes target     prot opt in     out     source               destination
    2   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
   ```

5. 接着匹配forward链filter表的第3条规则，第二次握手的数据包也属于NEW状态的且是来自docker0到ens33的流量，并不匹配。接着是第4条规则，第4条规则也不匹配，因为是来自docker0到ens33的流量。第5条规则允许来自docker0到非docker0网卡的所有流量，所以匹配，pkts+1。并ACCEPT通过Forward链进入PostRouting链。

   ```shell
   Chain FORWARD (policy DROP 21 packets, 928 bytes)
    pkts bytes target     prot opt in     out     source               destination
    2   11M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    2   11M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    0   11M ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
    1    52 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
    1  136K ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER (1 references)
    pkts bytes target     prot opt in     out     source               destination
    1    52 ACCEPT     tcp  --  !docker0 docker0  0.0.0.0/0            172.17.0.2           tcp dpt:80
    
    Chain DOCKER-ISOLATION-STAGE-1 (1 references)
    pkts bytes target     prot opt in     out     source               destination
    1  136K DOCKER-ISOLATION-STAGE-2  all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    2   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER-ISOLATION-STAGE-2 (1 references)
    pkts bytes target     prot opt in     out     source               destination
       0     0 DROP       all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
       1  136K RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER-USER (1 references)
    pkts bytes target     prot opt in     out     source               destination
    2   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
   ```

6. 因为后续的POSRROUTIG链中并未有相关规则就略过了。数据包顺利的通过ens33网卡转发出去。第二次握手到此结束。

# 第三次握手

通过前两次握手，我们基本已经连接从客户端到容器的流量经过以及从容器到客户端的流量经过。第三次握手和第一次握手有许多相同之处。接下来相同之处就不展开说明。

![](完整版.png)

- 第三次握手数据包进入ens33网卡，因为跟直接同属一个连接，并且Linux对其进行了跟踪，且做了NAT条目，所以无需再次进行NAT地址转换。通过路由决策之后进入forward链中的filter表。

  ![image-20240209013450858](image-20240209013450858.png)

- 在进入forward链filter表之后，数据包不会和第一次握手一样经过第4条规则匹配。而是在第3条规则进行了匹配，因为这是后续数据包，Linux对TCP连接进行了跟踪，这个数据包已经是`ESTABLISHED`状态。

  ```shell
  Chain FORWARD (policy DROP 21 packets, 928 bytes)
   pkts bytes target     prot opt in     out     source               destination
   0      11M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
   0      11M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
   0      11M ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
   0      52 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
   0      136K ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
   0         0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
  ```

- 任何接下来就通过了Forward链子并进入PostRouting链，因为PostRouting中也没相关的规则所以数据包直接转发到了docker0网桥，由docker0转发给容器。

## 总结

自此三次握手的整个过程就完成了。我们继续统计数据包经过iptables四表五链的次数。下面的pkts数还是继第二次握手的统计。

```shell
Chain FORWARD (policy DROP 21 packets, 928 bytes)
 pkts bytes target     prot opt in     out     source               destination
 2   11M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
 2   11M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
 0   11M ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
 1    52 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
 1  136K ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
 0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
 
 Chain DOCKER (1 references)
 pkts bytes target     prot opt in     out     source               destination
 1    52 ACCEPT     tcp  --  !docker0 docker0  0.0.0.0/0            172.17.0.2           tcp dpt:80
 
 Chain DOCKER-ISOLATION-STAGE-1 (1 references)
 pkts bytes target     prot opt in     out     source               destination
 1  136K DOCKER-ISOLATION-STAGE-2  all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
 2   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
 
 Chain DOCKER-ISOLATION-STAGE-2 (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 DROP       all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
    1  136K RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
 
 Chain DOCKER-USER (1 references)
 pkts bytes target     prot opt in     out     source               destination
 2   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
```

在Forward链中只有filter表有规则，且**链默认策略是拒绝**，也就是**必须匹配否则数据包将被拒绝**。

1. 数据包匹配第1条规则，进入DOCKER-USER链，pkts+1。DOCKER-USER链return返回到forward链，pkts+1。

   ```shell
   Chain FORWARD (policy DROP 21 packets, 928 bytes)
    pkts bytes target     prot opt in     out     source               destination
    3   11M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    2   11M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    0   11M ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
    1    52 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
    1  136K ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER (1 references)
    pkts bytes target     prot opt in     out     source               destination
    1    52 ACCEPT     tcp  --  !docker0 docker0  0.0.0.0/0            172.17.0.2           tcp dpt:80
    
    Chain DOCKER-ISOLATION-STAGE-1 (1 references)
    pkts bytes target     prot opt in     out     source               destination
    1  136K DOCKER-ISOLATION-STAGE-2  all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    2   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER-ISOLATION-STAGE-2 (1 references)
    pkts bytes target     prot opt in     out     source               destination
       0     0 DROP       all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
       1  136K RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER-USER (1 references)
    pkts bytes target     prot opt in     out     source               destination
    3   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
   ```

2. 继续匹配第2条规则，进入DOCKER-ISOLATION-STAGE-1链，pkts+1。在DOCKER-ISOLATION-STAGE-1链中匹配第2条规则并返回forward链，pkts+1。

   ```shell
   Chain FORWARD (policy DROP 21 packets, 928 bytes)
    pkts bytes target     prot opt in     out     source               destination
    3   11M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    3   11M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    0   11M ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
    1    52 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
    1  136K ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER (1 references)
    pkts bytes target     prot opt in     out     source               destination
    1    52 ACCEPT     tcp  --  !docker0 docker0  0.0.0.0/0            172.17.0.2           tcp dpt:80
    
    Chain DOCKER-ISOLATION-STAGE-1 (1 references)
    pkts bytes target     prot opt in     out     source               destination
    1  136K DOCKER-ISOLATION-STAGE-2  all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    3   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER-ISOLATION-STAGE-2 (1 references)
    pkts bytes target     prot opt in     out     source               destination
       0     0 DROP       all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
       1  136K RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER-USER (1 references)
    pkts bytes target     prot opt in     out     source               destination
    3   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
   ```

3. 匹配forrward链第3条规则，数据包不会和第一次握手一样经过第4条规则匹配，因为这是后续数据包，Linux对TCP连接进行了跟踪，这个数据包已经是`ESTABLISHED`状态。pkts+1。**自此，pkts和简述中对iptables查询数量已经一致了**。PostRouting链中并未有相关规则就略过了，数据包再次通过docker0网桥转发到容器中。

   ```shell
   Chain FORWARD (policy DROP 21 packets, 928 bytes)
    pkts bytes target     prot opt in     out     source               destination
       3   11M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
       3   11M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
       1   11M ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
       1    52 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
       1  136K ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
       0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER (1 references)
    pkts bytes target     prot opt in     out     source               destination
       1    52 ACCEPT     tcp  --  !docker0 docker0  0.0.0.0/0            172.17.0.2           tcp dpt:80
    
    Chain DOCKER-ISOLATION-STAGE-1 (1 references)
    pkts bytes target     prot opt in     out     source               destination
       1  136K DOCKER-ISOLATION-STAGE-2  all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
       3   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER-ISOLATION-STAGE-2 (1 references)
    pkts bytes target     prot opt in     out     source               destination
       0     0 DROP       all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
       1  136K RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
    
    Chain DOCKER-USER (1 references)
    pkts bytes target     prot opt in     out     source               destination
       3   11M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
   ```

# PostRouting规则

此规则是为了处理容器到互联网而设置的。转发流程和第二次握手相似，无需经过PreRouting的Nat转换，不同之处在PostRouting链中才对数据包做源地址转换，并转换为宿主机连接互联网网卡的IP，并继续对连接做追踪记录NAT条目。

```shell
 Chain POSTROUTING (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
    6   360 MASQUERADE  all  --  *      !docker0  172.17.0.0/16        0.0.0.0/0
    0     0 MASQUERADE  tcp  --  *      *       172.17.0.2           172.17.0.2           tcp dpt:80
```

