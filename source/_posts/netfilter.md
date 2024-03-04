---
title: NetFilter/IPtables
tags:
  - iptables
  - 防火墙
categories:
  - 安全
cover: img/fengmian/fhq.jpeg
abbrlink: 9fdd5e2e
date: 2022-08-26 10:26:32
---
# 概念

> 防火墙发展

防火墙检测技术经过了三个阶段:

1. 包过滤防火墙

   包过滤防火墙是基于路由器ACL规则的第一代防火墙，根据网络层协议中的地址信息或者传输层信息设定，通过允许和阻塞某些指定规则的数据包

2. 应用代理防火墙

   代理服务作用于网络的应用层，替代工作网络客户端执行应用层的连接，即提供代理服务；防火墙转发外部用户请求，与受信网络的服务器建立连接。与包过滤防火墙不同的是这些访问都是基于应用层中进行控制的

3. 状态检测防火墙

   第三代防火墙，类似于包过滤防火墙，采用更复杂的访问控制算法。状态检测防火墙工作在传输层，使用状态表记录会话信息。会话建立成功以后，记录信息并实时更新，所有会话数据都要与状态表信息匹配否则将被阻断

Netfilter项目是集成到Linux内核协议栈中的一套防火墙机制，现集成在Linux2.4.x及更高版本的内核中。用户可以通过运行工具将相关配置下发给防火墙，简单来说不管是使用iptables/firewalld的命令进行防火墙配置，这两款工具底层依靠的是Netfilter(真正起到防火墙的的功能的)。

该框架既简单又灵活，可实现安全策略应用中的许多功能，如数据包过滤、数据包处理、地址伪装、透明代理、动态网络地址转换，以及基于用户及媒体访问控制、地址的过滤和基于状态的过滤、包速率限制等。

Netfilter主要特点有：

- 无状态数据包过滤(IPV4&IPV6)
- 有状态数据包过滤(IPV4&IPV6)
- 各种网络地址和端口转换，NAT/NAPT(IPV4&IPV6)
- 灵活和可扩展的基础设施
- 用于第三方扩展的多层API

子系统常见框架：

- IPVS：四层负载均衡解决方案
- IPSet：由用户空间工具和内核部分组成的框架
- IPtables：Linux防火墙



# 四表五链

防火墙的功能就是对经过的数据包进行匹配规则，然后执行相应的动作。当数据包进入主机后必须匹配这个表中的相应规则进行相应的动作处理。而规则就存放于链中

- 链

  **prerouting**：路由前。数据包进入路由表之前(进站前)的数据包进行规则匹配

  **input**：进站。通过路由表查询后，目的地址为本机的数据包进行匹配规则

  **forward**：转发。通过路由表查询后，目的地址不为本机的数据包进行匹配规则

  **output**：出站。由本机产生的数据包，向外转发时的数据包进行匹配规则

  **postrouing**：路由后。发送到网卡之前(出站后)对数据包匹配规则

表是用于存放相同规则的集合

- 表

  **filter**：用于数据包过滤

  **nat**：用于nat功能(端口映射，地址转换)

  **raw**：有限级最高，设置此表是为了不让iptables做数据包的连接跟踪处理，提高性能

  **mangle**：用于对指定数据包的修改（拆包，修改，封包）

表和链的关系(某些链只能存放于特定的表)

| raw表        | mangle表      | nat表                | filter表  |
| ------------ | ------------- | -------------------- | --------- |
| PreRouting链 | PreRouting链  | PreRouting链         |           |
|              | InPut链       | **InPut链(CentOS7)** | InPut链   |
|              | Forward链     |                      | Forward链 |
| Output链     | Output链      | Output链             | OutPut链  |
|              | PostRouting链 | PostRouting链        |           |

# 数据流向

若仔细观察上表可得出表的优先

例如PreRouting链(路由前)可存放于三张表中，通过观察下图，可以得知数据包进入转发时先经过raw、mangle、nat表，刚好对应上表名称顺序。

> 表优先级（执行动作顺序）：raw > mangle > nat > filter，相同的链存在多个表中将会依照表优先级进行匹配执行

下图是将上表进行逻辑呈现，当数据包进入主机先匹配PreRouting链，而存放PreRouting链的表有raw，mangle，nat，将按照优先级依次进行匹配......

![image-20220219125859519](netfilter1.png)



> 需要开启Linux Forward功能需开启内核路由转发功能。echo "1" > /proc/sys/ipv4/ip_forward

# 动作及条件

**动作**(符合条件所执行的动作)：

- accept：允许数据包通过
- drop：丢弃数据包，不会返回响应
- reject：拒绝数据包，必要时会发送一个响应信息，告诉客户端被拒绝
- snat：源地址转换
- dnat：目的地址转换
- masquerade：
- log：记录日志信息
- masquerade：特殊的SNAT，用于动态IP的SNAT

**条件**(同于匹配数据包)：

- 基本条件

  源地址，目的地址

- 扩展条件

  TCP

  UDP

  ICMP

  MAC

  MARK

  OWNE

  LIMIT

  STATE

  INVALID

  ESTABLISHED

  NEW

  RELATED

  TOS

# iptables命令

## 查

使用iptables -L 默认查询的filter表

-L，列出规则

-v，列出详细规则

--line-numbers(-line)，列出规则时显示编号

-t，操作的表

-n，不对IP或者端口进行名称解析

```shell
[root@localhost ~]# iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain FORWARD (policy DROP)
target     prot opt source               destination
DOCKER-USER  all  --  anywhere             anywhere
DOCKER-ISOLATION-STAGE-1  all  --  anywhere             anywhere
ACCEPT     all  --  anywhere             anywhere             ctstate RELATED,ESTABLISHED
DOCKER     all  --  anywhere             anywhere
ACCEPT     all  --  anywhere             anywhere
ACCEPT     all  --  anywhere             anywhere

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination

Chain DOCKER (1 references)
target     prot opt source               destination

Chain DOCKER-ISOLATION-STAGE-1 (1 references)
target     prot opt source               destination
DOCKER-ISOLATION-STAGE-2  all  --  anywhere             anywhere
RETURN     all  --  anywhere             anywhere

Chain DOCKER-ISOLATION-STAGE-2 (1 references)
target     prot opt source               destination
DROP       all  --  anywhere             anywhere
RETURN     all  --  anywhere             anywhere

Chain DOCKER-USER (1 references)
target     prot opt source               destination
RETURN     all  --  anywhere             anywhere
[root@localhost ~]#
```

使用iptables -t 表名 -L 

```shell
[root@localhost ~]# iptables -t raw -L
Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination
[root@localhost ~]# iptables -t nat -L
Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination
DOCKER     all  --  anywhere             anywhere             ADDRTYPE match dst-type LOCAL

Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination
MASQUERADE  all  --  172.17.0.0/16        anywhere

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination
DOCKER     all  --  anywhere            !127.0.0.0/8          ADDRTYPE match dst-type LOCAL

Chain DOCKER (2 references)
target     prot opt source               destination
RETURN     all  --  anywhere             anywhere
[root@localhost ~]#
```

使用iptables -t 表名 -vL 查看详细信息

iptables -t nat -vL 链名 可查看nat表下链的详细信息

```shell
[root@localhost ~]# iptables -t nat -vL
# 链   PREROUTING (策略 放行9个包，大小2485bytes)
Chain PREROUTING (policy ACCEPT 9 packets, 2485 bytes)
#匹配包个数 包大小总和 协议 选项 数据包进网口 数据包出网口 源地址 目的地址
 pkts bytes target     prot opt in     out     source               destination
    4   272 DOCKER     all  --  any    any     anywhere             anywhere             ADDRTYPE match dst-type LOCAL

Chain INPUT (policy ACCEPT 4 packets, 272 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain POSTROUTING (policy ACCEPT 51 packets, 3835 bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 MASQUERADE  all  --  any    !docker0  172.17.0.0/16        anywhere

Chain OUTPUT (policy ACCEPT 51 packets, 3835 bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 DOCKER     all  --  any    any     anywhere            !127.0.0.0/8          ADDRTYPE match dst-type LOCAL

Chain DOCKER (2 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 RETURN     all  --  docker0 any     anywhere             anywhere
#################################################################################
[root@localhost ~]# iptables -t nat -vL INPUT
Chain INPUT (policy ACCEPT 4 packets, 272 bytes)
 pkts bytes target     prot opt in     out     source               destination
[root@localhost ~]#
#################################################################################
[root@localhost ~]# iptables -t nat -vnL
Chain PREROUTING (policy ACCEPT 10 packets, 2569 bytes)
 pkts bytes target     prot opt in     out     source               destination
    5   356 DOCKER     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL

Chain INPUT (policy ACCEPT 5 packets, 356 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain POSTROUTING (policy ACCEPT 63 packets, 4732 bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 MASQUERADE  all  --  *      !docker0  172.17.0.0/16        0.0.0.0/0

Chain OUTPUT (policy ACCEPT 63 packets, 4732 bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 DOCKER     all  --  *      *       0.0.0.0/0           !127.0.0.0/8          ADDRTYPE match dst-type LOCAL

Chain DOCKER (2 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 RETURN     all  --  docker0 *       0.0.0.0/0            0.0.0.0/0
[root@localhost ~]#
```

## 增

```shell
[root@localhost ~]# iptables -t filter -I INPUT -s 192.168.1.1 -j DROP
-t # 选择表
-I # insert在什么链中插入规则
-s # 源地址
-j # 动作
-A # 追加
```

## 删

> 可以通过--line显示序号删除，或者写完整的策略进行删除

```shell
[root@localhost ~]# iptables -t filter -D INPUT -s 192.168.1.1 -j DROP
-D # 删除delete删除某个链下的规则
[root@localhost ~]# iptables -t filter -F
-F # 清空所有链上的规则
[root@localhost ~]# iptables -t filter -L
```

```shell
[root@localhost ~]# iptables -vL --line	
Chain INPUT (policy ACCEPT 22720 packets, 64M bytes)
num   pkts bytes target     prot opt in     out     source               destination
1        0     0 DROP       all  --  any    any     192.168.1.1          anywhere

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
num   pkts bytes target     prot opt in     out     source               destination

Chain OUTPUT (policy ACCEPT 15639 packets, 1048K bytes)
num   pkts bytes target     prot opt in     out     source               destination
[root@localhost ~]# iptables -t filter -D INPUT 1	# 删除对应编号的规则
--line	# 使规则输出时带编号

```



## 改

> IPTALBES默认是黑名单，可以通过iptables修改成白名单

```shell
[root@localhost ~]# iptables -t filter -R INPUT  1 -s 192.168.2.1 -j REJECT
-R 	
# 修改对应编号的规则为...
```

```shell
[root@localhost ~]# iptables -t mangle -L
Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination

Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination

Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination
[root@localhost ~]# iptables -t mangle -P FORWARD DROP
[root@localhost ~]#
[root@localhost ~]# iptables -t mangle -L
Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination

Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain FORWARD (policy DROP)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination

Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination
[root@localhost ~]# iptables -t mangle -P FORWARD ACCEPT


-R #修改链默认规则
```

## 存

```shell
1、service iptables save
2、iptables-save > /etc/sysconfig/iptables		# iptables-save只能输出当前规则
3、iptables-restore < /etc/sysconfig/iptables	# 重新加载规则
```



# 匹配规则

## IP(IPrange)

```shell
[root@localhost ~]# iptables -t filter -I INPUT -s 192.168.1.1,192.168.1.2 -j DROP
# 拒绝两个源IP为xxx
[root@localhost ~]# iptables -t filter -I INPUT -s 192.168.1.0/24 -j DROP
# 拒绝一个网段
[root@localhost ~]# iptables -t filter -I INPUT -d 192.168.1.1 -j DROP
# 拒绝一个目的IP为xxx
[root@localhost ~]# iptables -t filter -I INPUT -s 192.168.2.1 -d 192.168.1.1 -j DROP
# 拒绝一个源IP为xxx目的IP为xxx
[root@localhost ~]# iptables -t filter -I INPUT -m iprange --src-range 192.168.2.1-192.168.2.100 -j DROP
# 通过iprange模块拒绝一段范围的源IP地址
[root@localhost ~]# iptables -t filter -I INPUT -m iprange --dst-range 192.168.2.1-192.168.2.100 -j DROP
# 通过iprange模块拒绝一段范围的目的IP地址

```

## 协议

```shell
[root@localhost ~]# iptables -t filter -I INPUT -s 192.168.2.1 -d 192.168.1.1 -p tcp -j DROP
# 拒绝源IP为xxx目的IP为xxx的tcp协议
[root@localhost ~]# iptables -t filter -I INPUT -s 192.168.2.1 -d 192.168.1.1 -p tcp -j DROP
[root@localhost ~]# iptables -t filter -I INPUT -s 192.168.2.1 -d 192.168.1.1 -p udp -j DROP
[root@localhost ~]# iptables -t filter -I INPUT -s 192.168.2.1 -d 192.168.1.1 -p icmp -j DROP
[root@localhost ~]# iptables -L INPUT
Chain INPUT (policy ACCEPT)
target     prot opt source               destination
DROP       icmp --  192.168.2.1          192.168.1.1
DROP       udp  --  192.168.2.1          192.168.1.1
DROP       tcp  --  192.168.2.1          192.168.1.1
[root@localhost ~]#
```

## 网口

```shell
[root@localhost ~]# iptables -t filter -I INPUT -i ens33 -p icmp -j DROP
# 拒绝网卡ens33的ICMP协议
-i # 指定网卡，只用用于PREROUTING、INPUT、FORWARD
-p # 协议
```

## 端口

```shell
[root@localhost ~]# iptables -t filter -I INPUT  -s 192.168.2.1 -d 192.168.1.1 -p tcp -m tcp --dport 22 -j DROP
# 拒绝源IP为xxx到目的IP为xxx的ssh协议请求
-m # 使用扩展规则需要使用-m指定扩展模块为tcp
--dport # 端口
[root@localhost ~]# iptables -t filter -I INPUT  -s 192.168.2.1 -d 192.168.1.1 -p tcp -m tcp --sport 22 -j DROP
# 拒绝IP:22到IPxxx
[root@localhost ~]# iptables -t filter -I INPUT  -s 192.168.2.1 -d 192.168.1.1 -p tcp -m tcp --sport 22:32 -j DROP
# 拒绝一段端口
```

## Time

```shell
#时间模块，通过time模块指定在某时间段之间的报文匹配规则
[root@localhost ~]# iptables -t filter -I OUTPUT -p tcp --dport 80 -m time --timestart 08:00:00 --timestop 12:00:00 -j REJECT
[root@localhost ~]# iptables -t filter -I OUTPUT -p tcp --dport 443 -m time --timestart 08:00:00 --timestop 12:00:00 -j REJECT
# 在早上8点到中午12点不能访问网页
[root@localhost ~]# iptables -t filter -I OUTPUT -p tcp --dport 80 -m time --weekdays 1,2,3,4,5 -j REJECT
# 工作日不能访问网页
[root@localhost ~]# iptables -t filter -I OUTPUT -p tcp --dport 80 -m time --weekdays 6,7 --timestart 08:00:00 --timestop 12:00:00 -j REJECT
# 周末的8-12点不能访问网页
[root@localhost ~]# iptables -t filter -I OUTPUT -p tcp --dport 80 -m time --datastart 2022-07-06 --datastop 2022-07-08 -j REJECT
# 指定日期不能访问网页
```

## connlimit

```shell
# 通过connlimit限制连接数量，不指定IP地址，默认就是对单一IP的并发数量进行限制
[root@localhost ~]# iptables -I INPUT -p tcp --dport 80 -m connlimit --connlimit-above 2 -j REJECT
# 每个客户端只能与服务器建立两个80端口连接
```

## limit

```shell
# 通过limit限制报文到达的速率，例如每秒最多有多少个包进行传入，或者每分钟
[root@localhost ~]# iptables -t filter -I INPUT -p icmp -m limit --limit 10/m -J ACCEPT
# 每分钟放行10个ICMP数据包
# 注意链中默认策略是放行，当超过10/m是虽然是无法匹配的 但是默认策略是运行放行的
[root@localhost ~]# iptables -t filter -I INPUT -p icmp -m limit --limit-burst 3 --limit 10/m -J ACCEPT
# 使用令牌桶，最大有3个名额，每分钟生成10个，每6秒生成一个，只有有名额的时候才能放行
# 单位s m h d
```

## TCP-Flags

```shell
# 可使用TCP模块的TCP-Flags对TCP中的标志位进行控制
#
#
#
[root@localhost ~]# iptables -t filter -I INPUT -p tcp -m tcp --dport 22 --tcp-flags SYN,ACK,FIN,RST,URG,PSH SYN -j REJECT
# 禁止连接到服务器22号端口的SYN标志的TCP报文(第一次握手)
[root@localhost ~]# iptables -t filter -I INPUT -p tcp -m tcp --dport 22 --tcp-flags SYN,ACK,FIN,RST,URG,PSH SYN,ACK -j REJECT
# 禁止连接到服务器22号端口的SYN,ACK标志的TCP报文(第二次握手)
[root@localhost ~]# iptables -t filter -I INPUT -p tcp -m tcp --dport 22 --tcp-flags ALL SYN,ACK -j REJECT
# 标志位可以用ALL代替

[root@localhost ~]# iptables -t filter -I INPUT -p tcp -m tcp --dport 22 --syn -j REJECT
# 专门禁止第一次握手


```

## ICMP

ICMP协议(互联网传输控制协议)，用于探测网络是否可达，主机是否存活等。

图下为ICMP报文类型以及代码

![img](netfilter2.jpeg)

```shell
# 如果使用基础匹配对ICMP进行过滤来实现禁Ping，虽然是可以实现的，但是也阻断了本身的Ping功能
[root@localhost ~]# iptables -t filter -I INPUT -p ICMP -J REJECT

# 想要实现禁止Ping但自身能够Ping的规则如下
[root@localhost ~]# iptables -t filter -I INPUT -p ICMP -m ICMP --icmp-type 8/0 -j REJECT
```

## State

> state模块是对TCP、UDP、ICMP等有连接的报文进行控制的，

报文的可分为5中状态：

1. NEW

   A向B发送建立请求的第一个包，状态为NEW(第一次握手)

2. ESTABLISHED

   B向A返回请求并开放端口，状态为ESTABLISHED(第二次握手，第二次握手之后的报文都是此状态)

3. RELATED

   临时连接

4. INVALID

   无状态

5. UNTRACKED

   报文未被追踪到，无法找到相关的连接

```shell
[root@localhost ~]# iptables -t filter -I INPUT -m state --state NEW -j REJECT
# 拒绝别人向本机建立连接，但是我可以向别人建立连接
[root@localhost ~]# iptables -t filter -I INPUT -m state --state RELATED,ESTABLISHED -j ACESSPT
[root@localhost ~]# iptables -t filter -A INPUT -j REJECT
# 拒绝别人向我建立连接，但是我可以向别人建立连接
```

# 自定义链

Netfilter默认是有四表五链的，而规则是保存在链(链表)中，自定义链类似用来给我们的规则进行分组，当规则条数过多全部放在默认的链中不方便我们对其进行管理

## 新建链

```shell
[root@localhost ~]# iptables -N Nginx			# 默认在filter表中
[root@localhost ~]# iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination

Chain Nginx (0 references)
target     prot opt source               destination
```

## 修改链

```shell
[root@localhost ~]# iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination

Chain Nginx (0 references)
target     prot opt source               destination
[root@localhost ~]# iptables -E Nginx Web_APP
[root@localhost ~]# iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination

Chain Web_APP (0 references)
target     prot opt source               destination
[root@localhost ~]#
```

## 删除链

```shell
[root@localhost ~]# iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination

Chain Web_APP (0 references)
target     prot opt source               destination
[root@localhost ~]# iptables -X Web_APP
[root@localhost ~]# iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination
```

## 关联链

> 在了解四表五连的流量走向后，可以知道默认数据都是在四张表中的默认链进行转发的，我们创建的自定义链必须与默认链进行关联，也就是在满足什么规则后将流量转发进入到自定义链中

```shell
[root@localhost ~]# iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination
[root@localhost ~]# iptables -N Web_App										# 在filter表中创建Web_app链
[root@localhost ~]# iptables -I INPUT -p tcp --dport 80 -j Web_App			# 当流量进入filter表的INPUT链条件匹配目标端口为80时将其转发到Web_app链中
[root@localhost ~]# iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination
Web_App    tcp  --  anywhere             anywhere             tcp dpt:http

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination

Chain Web_App (1 references)			# 对链进行关联后references为1(引用计数)
target     prot opt source               destination
```

# 扩展动作

## LOG日志

> 顾名思义就是对符合条件的数据包做记录的

```shell
[root@localhost ~]# iptables -I INPUT -p tcp --dport 22 -j LOG
# 对进栈访问22端口的流量进行记录；在/var/log/messages
# 可修改日志保存的文件
# 可发行版也许有差异
#/etc/rsyslog.conf
#kern.warning /root/iptables.log
```

```shell
[root@localhost ~]# iptables -I INPUT -p tcp --dport 22 -m state --state NEW -j LOG --log-prefix "ssh client conn"
# 对建立22连接的流量数据包进行记录
```

## SNAT

```shell
[root@localhost ~]# iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -j SNAT --to-source 1.1.1.1
# 对符合条件的数据包做源地址转换
```

## DNAT

```shell
# 目的地址转换
[root@localhost ~]# iptables -t nat -I PREROUTING -d 192.168.1.1 -p tcp --dport 80 -j DNAT --to-destination 10.1.1.1:80
```

## MASQUERADE

```shell
# 动态地址转换,与SNAT相比会动态将源地址修改成网卡上可用的IP地址
[root@localhost ~]# iptables -t nat -I POSTROUTING -s 192.168.1.0/24 -o ens33 -j MASQUERADE
```

## REDIRECT

```shell
# 端口映射
[root@localhost ~]# iptables -t nat -I PREROUTING -p tcp -dport 80 -j REDIRECT --tp-ports 8080
```
