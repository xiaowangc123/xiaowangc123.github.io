---
title: Ubuntu 22.04-DNS无法解析
abbrlink: 3033751c
date: 2022-12-02 10:16:51
tags:
  - Ubuntu
  - Linux
  - DNS
categories: Linux
cover: img/fengmian/ubuntu.jpeg
---
# Ubuntu-DNS解析问题

当配置好DNS之后发现怎么都无法进行解析

```yaml
root@node3:~# cat /etc/netplan/00-installer-config.yaml
# This is the network config written by 'subiquity'
network:
  ethernets:
    ens33:
      addresses:
        - 192.168.10.13/24
      routes:
        - to: default
          via: 192.168.10.254
      nameservers:
        addresses: [192.168.10.254]
        search: ["xiaowangc.local"]
  version: 2
```

查看/etc/resolv.conf发现DNS服务器地址一直都是127.0.0.53，修改后临时有效，一旦重启后DNS将无法再次解析

```shell
root@node3:~# cat /etc/resolv.conf
# This is /run/systemd/resolve/stub-resolv.conf managed by man:systemd-resolved(8).
# Do not edit.
#
# This file might be symlinked as /etc/resolv.conf. If you're looking at
# /etc/resolv.conf and seeing this text, you have followed the symlink.
#
# This is a dynamic resolv.conf file for connecting local clients to the
# internal DNS stub resolver of systemd-resolved. This file lists all
# configured search domains.
#
# Run "resolvectl status" to see details about the uplink DNS servers
# currently in use.
#
# Third party programs should typically not access this file directly, but only
# through the symlink at /etc/resolv.conf. To manage man:resolv.conf(5) in a
# different way, replace this symlink by a static file or a different symlink.
#
# See man:systemd-resolved.service(8) for details about the supported modes of
# operation for /etc/resolv.conf.

nameserver 127.0.0.53
options edns0 trust-ad
```

从/etc/resolv.conf的配置文件的注释来看，告诉我们不要修改这个文件，这个文件由systemd-resolved服务管理，这是一个动态文件。通过查看端口得知确实有这么个端口

```shell
root@node3:~# ss -lntp | grep 53                                                                                                 
LISTEN 0      4096   127.0.0.53%lo:53         0.0.0.0:*    users:(("systemd-resolve",pid=34041,fd=14))                           
LISTEN 0      4096         0.0.0.0:8181       0.0.0.0:*    users:(("nginx",pid=2253,fd=52),("nginx",pid=2222,fd=52))             
LISTEN 0      4096         0.0.0.0:443        0.0.0.0:*    users:(("nginx",pid=2253,fd=38),("nginx",pid=2222,fd=38))             
LISTEN 0      4096            [::]:80            [::]:*    users:(("nginx",pid=2253,fd=31),("nginx",pid=2222,fd=31))             
LISTEN 0      4096            [::]:8181          [::]:*    users:(("nginx",pid=2247,fd=53),("nginx",pid=2222,fd=53))             
LISTEN 0      4096            [::]:8181          [::]:*    users:(("nginx",pid=2253,fd=59),("nginx",pid=2222,fd=59))             
LISTEN 0      4096               *:45367            *:*    users:(("cri-dockerd",pid=1180,fd=10))
```

通过配置systemd-resolved来解决DNS无法解析的问题

```shell
root@node3:~# vi /etc/systemd/resolved.conf
[Resolve]
DNS=192.168.10.254
Domains=xiaowangc.local				# 因为我是自建DNS的原因所以加上域名,没有自建DNS可不加
```

重启生效

```shell
root@node3:~# systemctl restart systemd-resolved.service
root@node3:~# resolvectl status
Global
         Protocols: -LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
  resolv.conf mode: stub
Current DNS Server: 192.168.10.254
       DNS Servers: 192.168.10.254
        DNS Domain: xiaowangc.local

Link 2 (ens33)
    Current Scopes: DNS
         Protocols: +DefaultRoute +LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
Current DNS Server: 192.168.10.254
       DNS Servers: 192.168.10.254
        DNS Domain: xiaowangc.local

Link 3 (docker0)
Current Scopes: none
     Protocols: -DefaultRoute +LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported

Link 4 (kube-ipvs0)
Current Scopes: none
     Protocols: -DefaultRoute +LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported

Link 5 (tunl0)
Current Scopes: none
     Protocols: -DefaultRoute +LLMNR -mDNS -DNSOverTLS DNSSEC=no/unsupported
root@node3:~# ping api.xiaowangc.local
PING api.xiaowangc.local (192.168.10.100) 56(84) bytes of data.
64 bytes from 192.168.10.100 (192.168.10.100): icmp_seq=1 ttl=64 time=0.212 ms
64 bytes from 192.168.10.100 (192.168.10.100): icmp_seq=2 ttl=64 time=0.228 ms
64 bytes from 192.168.10.100 (192.168.10.100): icmp_seq=3 ttl=64 time=0.227 ms
64 bytes from 192.168.10.100 (192.168.10.100): icmp_seq=4 ttl=64 time=0.182 ms
--- api.xiaowangc.local ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3004ms
rtt min/avg/max/mdev = 0.182/0.212/0.228/0.018 ms
```

