---
title: Prometheus-NodeExport
tags:
  - Prometheus
  - 监控
categories: 监控
cover: img/fengmian/Prometheus.jpg
abbrlink: dc8c870
date: 2022-06-21 12:24:11
---
# node_exporter安装

node_exporter安装非常简单，只需要解压后台运行即可，默认端口：9100

官方下载地址：https://prometheus.io/download/

```shell
wget https://github.com/prometheus/prometheus/releases/download/v2.36.1/prometheus-2.36.1.linux-amd64.tar.gz
tar xf prometheus-2.36.1.linux-amd64.tar.gz

mv prometheus-2.36.1.linux-amd64 /usr/loca/node

restorecon -Rv /usr/loca/node

tee > /usr/lib/systemd/system/node.service << EOF
[Unit]
Description=node_exporter

[Service]
Type=simple
ExecStart=/usr/loca/node/node_exporter \
--collector.systemd \
--collector.systemd.unit-whitelist="(ssh|docker).service"

[Install]
WantedBy=multi-user.target
EOF
systemctl enable --now node.service
```



# 启动说明

1. 启用systemd收集器

   systemd收集器记录systemd中服务和系统状态。需要通过参数--collector.systemd启动该收集器；

2. 指定textfile收集器目录

   textfile收集器可以让用户添加自定义的度量指标，功能类似pushgateway，同zabbix自定义的item一样，只要将度量指标和值按照Prometheus规范的格式输出到指定位置以.prom后缀文件保存，textfile收集器会自动读取collector.textfile.directory目录下所有以.prom结尾的文件，并提取所有格式为Prometheus的指标暴露给Prometheus抓取。

   textfile收集器默认是开启的，我们只需要指定--collector.textfile.directory的路径即可

   **例如**

   ```bash
   # 监控系统登录用户数
   echo "node_login_user $(who | wc -l)" > /path/login_users.prom
   
   # 以定时任务的方式采集
   */1 * * * * echo "login_users $(who | wc -l)" > /path/login_users.prom
   ```

3. 启动或禁用收集器

   通过./node_exporter -h 命令，可以看到默认启动了哪些收集器，若要禁用某个收集器，如：--collector.ntp，可以修改为--no-collector.ntp，即禁用该收集器

4. 只添加指定的收集器

   node_exporter等各种收集器默认会收集非常多的指标数据，有很多并非我们所需要的，是可以不收集的，除了在node_exporter启动时指定禁用某些收集器之外，也可以在Prometheus的配置文件中的scrape_config配置块下指定只收集哪些指标

   ```yaml
     params:
       collect[]:
         - foo
         - bar
   ```

   使用场景：

   在清楚每一个收集器的用途之后再使用该方法，推荐默认收集所有数据，然后过滤不需要的收集器

```bash
用法：node_exporter [<flags>]

标志：
  -h, --help 显示上下文相关帮助（也可以试试 --help-long 和 --help-man）。
      --collector.bcache.priorityStats
                                 公开昂贵的优先级统计数据。
      --collector.cpu.guest 启用指标 node_cpu_guest_seconds_total
      --collector.cpu.info 启用度量 cpu_info
      --collector.cpu.info.flags-include=COLLECTOR.CPU.INFO.FLAGS-INCLUDE
                                 使用必须是正则表达式的值过滤 cpuInfo 中的 `flags` 字段
      --collector.cpu.info.bugs-include=COLLECTOR.CPU.INFO.BUGS-INCLUDE
                                 使用必须是正则表达式的值过滤 cpuInfo 中的 `bugs` 字段
      --collector.diskstats.ignored-devices="^(ram|loop|fd|(h|s|v|xv)d[az]|nvme\\d+n\\d+p)\\d+$"
                                 diskstats 要忽略的设备的正则表达式。
      --collector.ethtool.device-include=COLLECTOR.ETHTOOL.DEVICE-INCLUDE
                                 要包含的 ethtool 设备的正则表达式（与设备排除互斥）。
      --collector.ethtool.device-exclude=COLLECTOR.ETHTOOL.DEVICE-EXCLUDE
                                 要排除的 ethtool 设备的正则表达式（与 device-include 互斥）。
      --collector.ethtool.metrics-include=".*"
                                 要包含的 ethtool 统计信息的正则表达式。
      --collector.filesystem.mount-points-exclude="^/(dev|proc|run/credentials/.+|sys|var/lib/docker/.+)($|/)"
                                 要为文件系统收集器排除的挂载点的正则表达式。
      --collector.filesystem.fs-types-exclude="^(autofs|binfmt_misc|bpf|cgroup2?|configfs|debugfs|devpts|devtmpfs|fusectl|hugetlbfs|iso9660|mqueue|nsfs|overlay|proc|procfs|pstore| rpc_pipefs|securityfs|selinuxfs|squashfs|sysfs|tracefs)$"
                                 要为文件系统收集器排除的文件系统类型的正则表达式。
      --collector.ipvs.backend-labels="local_address,local_port,remote_address,remote_port,proto,local_mark"
                                 IPVS 后端统计标签的逗号分隔列表。
      --collector.netclass.ignored-devices="^$"
                                 网络类收集器要忽略的网络设备的正则表达式。
      --collector.netclass.ignore-invalid-speed
                                 忽略速度无效的设备。这将是 2.x 中的默认行为。
      --collector.netdev.device-include=COLLECTOR.NETDEV.DEVICE-INCLUDE
                                 要包含的网络设备的正则表达式（与设备排除互斥）。
      --collector.netdev.device-exclude=COLLECTOR.NETDEV.DEVICE-EXCLUDE
                                 要排除的网络设备的正则表达式（与设备包含互斥）。
      --collector.netdev.address-info
                                 收集每个设备的地址信息
      --collector.netstat.fields="^(.*_(InErrors|InErrs)|Ip_Forwarding|Ip(6|Ext)_(InOctets|OutOctets)|Icmp6?_(InMsgs|OutMsgs)|TcpExt_(Listen.*| Syncookies.*|TCPSynRetrans|TCPTimeouts)|Tcp_(ActiveOpens|InSegs|OutSegs|OutRsts|PassiveOpens|RetransSegs|CurrEstab)|Udp6?_(InDatagrams|OutDatagrams|NoPorts|RcvbufErrors|SndbufErrors))$"
                                 为 netstat 收集器返回的字段正则表达式。
      --collector.ntp.server="127.0.0.1"
                                 用于 ntp 收集器的 NTP 服务器
      --collector.ntp.protocol-version=4
                                 NTP协议版本
      --collector.ntp.server-is-local
                                 证明 collector.ntp.server 地址不是公共 ntp 服务器
      --collector.ntp.ip-ttl=1 发送 NTP 查询时使用的 IP TTL
      --collector.ntp.max-distance=3.46608s
                                 到根的最大累积距离
      --collector.ntp.local-offset-tolerance=1ms
                                 本地时钟和本地 ntpd 时间之间允许的偏移量
      --path.procfs="/proc" procfs 挂载点。
      --path.sysfs="/sys" sysfs 挂载点。
      --path.rootfs="/" rootfs 挂载点。
      --collector.perf.cpus="" 应该从中收集性能指标的 CPU 列表
      --collector.perf.tracepoint=COLLECTOR.PERF.TRACEPOINT ...
                                 应该收集的性能跟踪点
      --collector.powersupply.ignored-supplies="^$"
                                 powersupplyclass 收集器要忽略的电源正则表达式。
      --collector.qdisc.fixtures=""
                                 用于 qdisc 收集器端到端测试的测试装置
      --collector.runit.servicedir="/etc/service"
                                 runit 服务目录的路径。
      --collector.supervisord.url="http://localhost:9001/RPC2"
                                 XML RPC 端点。
      --collector.systemd.unit-include=".+"
                                 要包含的 systemd 单元的正则表达式。单元必须同时匹配 include 和不匹配 exclude 才能被包含。
      --collector.systemd.unit-exclude=".+\\.(automount|device|mount|scope|slice)"
                                 要排除的 systemd 单位的正则表达式。单元必须同时匹配 include 和不匹配 exclude 才能被包含。
      --collector.systemd.enable-task-metrics
                                 启用服务单元任务指标 unit_tasks_current 和 unit_tasks_max
      --collector.systemd.enable-restarts-metrics
                                 启用服务单元指标 service_restart_total
      --collector.systemd.enable-start-time-metrics
                                 启用服务单元度量 unit_start_time_seconds
      --collector.tapestats.ignored-devices="^$"
                                 Tapestats 要忽略的设备的正则表达式。
      --collector.textfile.directory=""
                                 从中读取带有度量的文本文件的目录。
      --collector.vmstat.fields="^(oom_kill|pgpg|pswp|pg.*fault).*"
                                 为 vmstat 收集器返回的字段正则表达式。
      --collector.wifi.fixtures=""
                                 用于 wifi 收集器指标的测试装置
      --collector.arp 启用 arp 收集器（默认：启用）。
      --collector.bcache 启用 bcache 收集器（默认值：启用）。
      --collector.bonding 启用绑定收集器（默认值：启用）。
      --collector.btrfs 启用 btrfs 收集器（默认：启用）。
      --collector.buddyinfo 启用 buddyinfo 收集器（默认：禁用）。
      --collector.conntrack 启用 conntrack 收集器（默认：启用）。
      --collector.cpu 启用 cpu 收集器（默认：启用）。
      --collector.cpufreq 启用 cpufreq 收集器（默认：启用）。
      --collector.diskstats 启用 diskstats 收集器（默认：启用）。
      --collector.dmi 启用 dmi 收集器（默认：启用）。
      --collector.drbd 启用 drbd 收集器（默认：禁用）。
      --collector.drm 启用 drm 收集器（默认值：禁用）。
      --collector.edac 启用 edac 收集器（默认值：启用）。
      --collector.entropy 启用熵收集器（默认：启用）。
      --collector.ethtool 启用 ethtool 收集器（默认：禁用）。
      --collector.fiberchannel 启用光纤通道收集器（默认：启用）。
      --collector.filefd 启用 filefd 收集器（默认：启用）。
      --collector.filesystem 启用文件系统收集器（默认：启用）。
      --collector.hwmon 启用 hwmon 收集器（默认值：启用）。
      --collector.infiniband 启用 infiniband 收集器（默认：启用）。
      --collector.interrupts 启用中断收集器（默认值：禁用）。
      --collector.ipvs 启用 ipvs 收集器（默认：启用）。
      --collector.ksmd 启用 ksmd 收集器（默认值：禁用）。
      --collector.lnstat 启用 lnstat 收集器（默认值：禁用）。
      --collector.loadavg 启用 loadavg 收集器（默认值：启用）。
      --collector.logind 启用登录收集器（默认值：禁用）。
      --collector.mdadm 启用 mdadm 收集器（默认：启用）。
      --collector.meminfo 启用 meminfo 收集器（默认：启用）。
      --collector.meminfo_numa 启用 meminfo_numa 收集器（默认：禁用）。
      --collector.mountstats 启用 mountstats 收集器（默认：禁用）。
      --collector.netclass 启用网络类收集器（默认：启用）。
      --collector.netdev 启用 netdev 收集器（默认：启用）。
      --collector.netstat 启用 netstat 收集器（默认：启用）。
      --collector.network_route 启用 network_route 收集器（默认：禁用）。
      --collector.nfs 启用 nfs 收集器（默认值：启用）。
      --collector.nfsd 启用 nfsd 收集器（默认值：启用）。
      --collector.ntp 启用 ntp 收集器（默认值：禁用）。
      --collector.nvme 启用 nvme 收集器（默认值：启用）。
      --collector.os 启用 os 收集器（默认：启用）。
      --collector.perf 启用性能收集器（默认值：禁用）。
      --collector.powersupply 类
                                 启用 powersupplyclass 收集器（默认值：启用）。
      --collector.pressure 启用压力收集器（默认：启用）。
      --collector.processes 启用进程收集器（默认：禁用）。
      --collector.qdisc 启用 qdisc 收集器（默认值：禁用）。
      --collector.rapl 启用 rapl 收集器（默认：启用）。
      --collector.runit 启用 runit 收集器（默认值：禁用）。
      --collector.schedstat 启用 schedstat 收集器（默认：启用）。
      --collector.sockstat 启用 sockstat 收集器（默认：启用）。
      --collector.softnet 启用 softnet 收集器（默认值：启用）。
      --collector.stat 启用统计收集器（默认：启用）。
      --collector.supervisord 启用 supervisord 收集器（默认值：禁用）。
      --collector.systemd 启用 systemd 收集器（默认：禁用）。
      --collector.tapestats 启用tapestats 收集器（默认：启用）。
      --collector.tcpstat 启用 tcpstat 收集器（默认值：禁用）。
      --collector.textfile 启用文本文件收集器（默认：启用）。
      --collector.thermal_zone 启用 thermo_zone 收集器（默认：启用）。
      --collector.time 启用时间收集器（默认：启用）。
      --collector.timex 启用 timex 收集器（默认：启用）。
      --collector.udp_queues 启用 udp_queues 收集器（默认：启用）。
      --collector.uname 启用 uname 收集器（默认值：启用）。
      --collector.vmstat 启用 vmstat 收集器（默认：启用）。
      --collector.wifi 启用 wifi 收集器（默认：禁用）。
      --collector.xfs 启用 xfs 收集器（默认值：启用）。
      --collector.zfs 启用 zfs 收集器（默认：启用）。
      --collector.zoneinfo 启用 zoneinfo 收集器（默认值：禁用）。
      --web.listen-address=":9100"
                                 公开指标和 Web 界面的地址。
      --web.telemetry-path="/metrics"
                                 公开指标的路径。
      --web.disable-exporter-metrics
                                 排除有关导出器本身的指标（promhttp_*、process_*、go_*）。
      --web.max-requests=40 最大并行抓取请求数。使用 0 禁用。
      --collector.disable-defaults
                                 默认情况下将所有收集器设置为禁用。
      --web.config="" [EXPERIMENTAL] 可以启用 TLS 或身份验证的配置 yaml 文件的路径。
      --log.level=info 仅记录具有给定严重性或更高级别的消息。之一：[调试、信息、警告、错误]
      --log.format=logfmt 日志消息的输出格式。之一：[logfmt，json]
      --version 显示应用程序版本。
```

# 监控系统资源

在Google SRE Handbook中提出了评估系统是否存在问题，用户体验是否受影响，用四个黄金信号来判断：

Latency（延迟）、Traffic（流量）、Errors（错误数）、Saturation（饱和度）

但在系统资源监控用的较多的方法是“USE”方法，分别为：Utilization（使用率）、Saturation（饱和度）、Errors（错误数）

1. CPU使用率监控

    (1-(avg(irate(node_cpu_seconds_total{app="node01",mode="idle"}[5m])))) * 100

2. 内存使用率监控

   (node_memory_MemAvailable_bytes{app="node01"}/node_memory_MemTotal_bytes{app="node01"})* 100

3. 磁盘分区使用率监控

   (1-(node_filesystem_avail_bytes{app="node01",mountpoint="/"}/node_filesystem_size_bytes{app='node01',mountpoint='/'}))*100

4. CPU饱和度监控

   avg(node_load1{app="node01"})/count(node_cpu_seconds_total{app="node01",mode="system"})

5. 内存饱和度监控

   node_vmstat_pswpin：系统每秒从磁盘读到内存的字节数

   node_vmstat_pswpout：系统每秒从内存写到磁盘的字节数

6. 网卡接收/发送流量监控

   irate(node_network_receive_bytes_total{app="node01",device="ens33"}[5m])*8

   irate(node_network_transmit_bytes_total{app="node01",device="ens33"}[5m])*8