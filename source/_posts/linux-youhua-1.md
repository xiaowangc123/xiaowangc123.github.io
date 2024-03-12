---
title: Linux60秒分析法
tags:
  - 性能分析
  - Linux
categories: Linux
cover: img/fengmian/linux.png
abbrlink: 4ef3b579
date: 2024-03-12 14:01:44
---
# 性能分析工具

使用标准Linux工具，通过分析以下清单中的输出，可定位大部分常见的性能问题。

- `uptime`
- `dmesg | tail`
- `vmstat 1`
- `mpstat -P ALL 1`
- `pidstat 1`
- `iostat -xz 1`
- `free -h`
- `sar -n DEV 1`
- `sar -n TCP,ETCP 1`
- `top`

有关这些工具的更多信息，请参考`man`手册页

# uptime

通过使用`uptime`命令查看系统平均负载情况，平均负载指示要运行的任务或进程的数量。

```shell
root@master:~# uptime
 01:57:27 up 16 min,  1 user,  load average: 0.04, 0.07, 0.09
```

load average后面的三个数字是指数衰减移动总和平均值，常数为1分钟、5分钟和15分钟。如果1分钟的值远低于15分钟的值，那么可能登录的过晚而错过了该问题。

如果1分钟的值大于15分钟，这将意味着CPU使用过高，可使用`vmstat`和`mpstat`命令进行确认

# dmesg

使用`dmesg`命令查询系统消息，查找可能导致性能问题的错误例如OOM-KILLER和TCP丢弃请求。

```shell
root@master:~# dmesg | tail
[ 1771.625010] docker0: port 1(veth2361f92) entered disabled state
[ 1771.625242] vethc3969c9: renamed from eth0
[ 1771.665042] docker0: port 1(veth2361f92) entered disabled state
[ 1771.666491] device veth2361f92 left promiscuous mode
[ 1771.666507] docker0: port 1(veth2361f92) entered disabled state
```

# vmstat

`vmstat`命令是虚拟内存统计的缩写，它可以在每一行打印关键服务器统计信息的摘要。

```shell
root@master:~# vmstat 1
procs -----------memory---------- ---swap-- -----io---- -system-- ------cpu-----
 r  b   swpd   free   buff  cache   si   so    bi    bo   in   cs us sy id wa st
 1  0      0 2902648  82232 4272704    0    0   363   144  117  211  0  1 97  2  0
 0  0      0 2902728  82240 4272696    0    0     0    36  315  515  0  0 100  0  0
 0  0      0 2902728  82240 4272704    0    0     0     0  290  470  0  0 100  0  0
 0  0      0 2902728  82240 4272704    0    0     0     0  292  484  0  0 100  0  0
 0  0      0 2902728  82240 4272704    0    0     0     0  295  470  0  0 100  0  0
```

要检查的列：

- **r:** 在CPU上运行并等待轮流(轮流就是大家一起用,你用完我用我用完你用)的进程数。这提供了比负载平均值更好的信号来确定CPU饱和度，且它不包括I/O，**r值**大于CPU计数就是饱和。
- **free：**可用内存以千字节为单位。如果数值太多则表示系统有足够内存
- **si,so：**换入和换出。如果这些数值不为0，则说明内存不足。
- **us、sy、id、wa、st：**这些是所有CPU的平均CPU时间细分。这些分别是：用户时间、系统(内核)时间、空闲、等待I/O和窃取时间

# mpstat

`mpstat`命令打印每个CPU的CPU时间细分，可用于检查不平衡的情况。单个CPU可以作为单线程应用的证据。

```shell
root@master:~# mpstat -P ALL 1
Linux 5.15.0-97-generic (master)        03/12/2024      _x86_64_        (4 CPU)

02:46:13 AM  CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
02:46:14 AM  all    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
02:46:14 AM    0    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
02:46:14 AM    1    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
02:46:14 AM    2    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
02:46:14 AM    3    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00

02:46:14 AM  CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
02:46:15 AM  all    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
02:46:15 AM    0    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
02:46:15 AM    1    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
02:46:15 AM    2    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
02:46:15 AM    3    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
^C
Average:     CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest  %gnice   %idle
Average:     all    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
Average:       0    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
Average:       1    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
Average:       2    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
Average:       3    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00    0.00  100.00
```

# pidstat

`pidstat`命令有点像top的每个进程的摘要，相比top打印滚动摘要而不是清除屏幕。这对于观察一段时间内的模式以及可以将所看到的内容记录到调查记录中非常有用。

```shell
root@master:~# pidstat 1
Linux 5.15.0-97-generic (master)        03/12/2024      _x86_64_        (4 CPU)

02:49:11 AM   UID       PID    %usr %system  %guest   %wait    %CPU   CPU  Command

02:49:12 AM   UID       PID    %usr %system  %guest   %wait    %CPU   CPU  Command
02:49:13 AM   114      1030    0.00    1.00    0.00    0.00    1.00     3  mysqld

02:49:13 AM   UID       PID    %usr %system  %guest   %wait    %CPU   CPU  Command
02:49:14 AM     0       771    1.00    0.00    0.00    0.00    1.00     2  vmtoolsd
02:49:14 AM   114      1030    1.00    0.00    0.00    0.00    1.00     3  mysqld
02:49:14 AM     0      2715    0.00    1.00    0.00    0.00    1.00     1  pidstat

02:49:14 AM   UID       PID    %usr %system  %guest   %wait    %CPU   CPU  Command
02:49:15 AM     0      2715    1.00    0.00    0.00    0.00    1.00     1  pidstat

02:49:15 AM   UID       PID    %usr %system  %guest   %wait    %CPU   CPU  Command
02:49:16 AM   114      1030    1.00    0.00    0.00    0.00    1.00     3  mysqld
^C

Average:      UID       PID    %usr %system  %guest   %wait    %CPU   CPU  Command
Average:        0       771    0.20    0.00    0.00    0.00    0.20     -  vmtoolsd
Average:      114      1030    0.40    0.20    0.00    0.00    0.60     -  mysqld
Average:        0      2715    0.20    0.20    0.00    0.00    0.40     -  pidstat
```

上面的例式标识了消耗CPU的mysqld进程。%CPU列是所有CPU的总和

# iostat

通过使用`iostat`命令了解块设备所应用的工作负载和产生的性能的绝佳工具

该命令使用了`-m`参数以megabytes(兆字节)形式展示统计信息:

- **r/s、w/s、rMB/s、wMB/s：**这些是每秒向设备传送的读取、写入、读取兆字节、写入兆字节数。
- **wait：**包括IO的平均时间(以毫秒为单位)，这表示应用程序所遭受的时间，它包括等待时间和服务时间。大于预期的平均值可能表明设备饱和或出现了问题。
- **aqu-sz：**向设备发出的平均请求数，该值如果大于1则表明饱和
- **%util：**设备利用率。这是一个忙碌的百分比，显示设备每秒的工作时间。大于60%通常会导致设备性能变差，当然这取决于设备，接近100%表示设备饱和。

如果存储是逻辑磁盘设备，面对许多后端磁盘，那么100%利用率只是意味着某些I/O正在100%的时间处理，但是后端磁盘远未饱和，并且也许可以处理更多的工作。磁盘I/O性能不佳不一定是应用程序问题，许多技术通常用于异步执行I/O，以便程序不会阻塞并直接遭受延迟。

```shell
root@master:~# iostat -xzm 1
Linux 5.15.0-97-generic (master)        03/12/2024      _x86_64_        (4 CPU)

avg-cpu:  %user   %nice %system %iowait  %steal   %idle
           0.17    0.01    0.34    0.71    0.00   98.76

Device            r/s     rMB/s   rrqm/s  %rrqm r_await rareq-sz     w/s     wMB/s   wrqm/s  %wrqm w_await wareq-sz     d/s     dMB/s   drqm/s  %drqm d_await dareq-sz     f/s f_await  aqu-sz  %util
dm-0            10.65      0.58     0.00   0.00    8.91    55.46    3.66      0.24     0.00   0.00    1.73    67.63    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.10   2.26
loop0            0.01      0.00     0.00   0.00   38.37     8.05    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.03
loop1            0.04      0.00     0.00   0.00   11.14    10.16    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.05
loop2            0.01      0.00     0.00   0.00   35.59    21.18    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.03
loop3            0.01      0.00     0.00   0.00   27.25    15.19    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.03
loop4            0.11      0.00     0.00   0.00    8.57    36.52    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.12
loop5            0.00      0.00     0.00   0.00    0.09     1.27    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.00
sda              7.82      0.58     2.92  27.16    6.14    75.74    1.76      0.24     2.08  54.18    2.71   140.91    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.05   2.27
sr0              0.00      0.00     0.00   0.00    0.10     0.20    0.00      0.00     0.00   0.00    0.00     0.00    0.00      0.00     0.00   0.00    0.00     0.00    0.00    0.00    0.00   0.00
```

# free

网站：[https://www.linuxatemyram.com/](https://www.linuxatemyram.com/)

Linux会将未使用的内存进行磁盘缓存，这使得看上去空闲内存不足，但事实并非如此。我们无法完全禁用磁盘缓存。磁盘缓存可以使应用程序加载速度更快，运行更流畅，但它永远不会占用它们(应用程序)的内存，如果要释放可使用`echo 3 | sudo tee /proc/sys/vm/drop_caches`命令

- buffers：用于缓冲区高速缓存，用于块设备I/O
- cached：用于页面缓存，由系统文件使用

**一个拥有足够内存的健康Linux系统，在运行一段时间后会显示如下信息：**

- free内存接近为0
- available内存有足够空间
- swap userd未使用

**真正内存不足的警告信号：**

- available接近为0
- swap user增加或波动
- dmesg | grep oom-killerd 显示OutOfMemory杀手的工作进程

```shell
root@master:~# free -h
               total        used        free      shared  buff/cache   available
Mem:           7.7Gi       773Mi       2.4Gi       1.0Mi       4.5Gi       6.7Gi
Swap:          1.8Gi          0B       1.8Gi
```

# sar

使用`sar`命令检查网络接口吞吐量：rxkB/s和txkB/s作为工作负载的度量。并检查是否达到网卡限制。

```shell
root@master:~# sar -n DEV 1 3
Linux 5.15.0-97-generic (master)        03/12/2024      _x86_64_        (4 CPU)

05:46:36 AM     IFACE   rxpck/s   txpck/s    rxkB/s    txkB/s   rxcmp/s   txcmp/s  rxmcst/s   %ifutil
05:46:37 AM        lo      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
05:46:37 AM     ens33      1.00      1.00      0.06      0.15      0.00      0.00      0.00      0.00
05:46:37 AM   docker0      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00

05:46:37 AM     IFACE   rxpck/s   txpck/s    rxkB/s    txkB/s   rxcmp/s   txcmp/s  rxmcst/s   %ifutil
05:46:38 AM        lo      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
05:46:38 AM     ens33      1.00      1.00      0.06      0.81      0.00      0.00      0.00      0.00
05:46:38 AM   docker0      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00

05:46:38 AM     IFACE   rxpck/s   txpck/s    rxkB/s    txkB/s   rxcmp/s   txcmp/s  rxmcst/s   %ifutil
05:46:39 AM        lo      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
05:46:39 AM     ens33      1.00      2.00      0.06      0.89      0.00      0.00      0.00      0.00
05:46:39 AM   docker0      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00

Average:        IFACE   rxpck/s   txpck/s    rxkB/s    txkB/s   rxcmp/s   txcmp/s  rxmcst/s   %ifutil
Average:           lo      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
Average:        ens33      1.00      1.33      0.06      0.62      0.00      0.00      0.00      0.00
Average:      docker0      0.00      0.00      0.00      0.00      0.00      0.00      0.00      0.00
```

这是TCP的一些关键指标：

- active/s：每秒本地发起的TCP连接数
- passive/s：每秒远程发起的TCP连接数
- retrans/s：每秒TCP重传次数

```shell
root@master:~# sar -n TCP,ETCP 1 2
Linux 5.15.0-97-generic (master)        03/12/2024      _x86_64_        (4 CPU)

05:49:53 AM  active/s passive/s    iseg/s    oseg/s
05:49:54 AM      0.00      0.00      1.00      1.00

05:49:53 AM  atmptf/s  estres/s retrans/s isegerr/s   orsts/s
05:49:54 AM      0.00      0.00      0.00      0.00      0.00

05:49:54 AM  active/s passive/s    iseg/s    oseg/s
05:49:55 AM      0.00      0.00      1.00      1.00

05:49:54 AM  atmptf/s  estres/s retrans/s isegerr/s   orsts/s
05:49:55 AM      0.00      0.00      0.00      0.00      0.00

Average:     active/s passive/s    iseg/s    oseg/s
Average:         0.00      0.00      1.00      1.00

Average:     atmptf/s  estres/s retrans/s isegerr/s   orsts/s
Average:         0.00      0.00      0.00      0.00      0.00
```