---
title: keepalived
tags: 负载均衡
cover: img/fengmian/keepalive.png
categories: 负载均衡
abbrlink: 7377fd95
date: 2022-04-02 03:04:02
---
# Keepalived概念

> 前置知识LVS，[点我转到LVS](https://www.xiaowangc.com/archives/lvslinuxvirtualserver)

Keepalived最初是为LVS而设计，用于避免LVS的单点故障(只有一台LVS服务器，当它Down之后整个集群就崩溃了)。该项目主要是为了Linux系统和基础设施提供简单而强大的负载均衡和高可用性，Keepalived中的负载均衡框架依赖与LVS(IPVS)内核模块，提供4层(OSI七层模型中的第四层)负载均衡。

简单来说，Keepalived是LVS的升级版，在此基础上增加了**故障检测**和**高可用(VRRP)**功能，之前我们配置LVS的时候是使用ipvsadm软件包来进行设置的，但使用keepalived之后就无需通过ipvsadm进行配置管理，更多的是用来查看LVS的配置。

![image-20220212070236487](20220212070236487.png)

如上图所示：

- 传统LVS实现Web应用的高可用，但是LVS存在单点故障。当LVS服务器Down掉之后，整个集群将瘫痪无法对外提供服务。
- Keepalived+LVS架构解决了LVS存在的单点故障并提供负载均衡、高可用性。当Master节点Down掉之后，Backup发现之后就会代替Master接管VIP的工作
- Keepalived节点可以任意台(大于等于2)



# 配置文件解析

Keepalived配置分为三大模块

```shell
global_defs{
	# 全局配置块
}

vrrp_instance VI_1 {
	# VRRP配置块
}

virtual_server 192.168.1.1 80 {
	# LVS配置块
}
```

默认配置文件：

```shell
! Configuration File for keepalived
# keepalived配置文件

#####################全局配置块##########################
global_defs {
   # 定义邮箱列表
   notification_email {
     acassen@firewall.loc
     failover@firewall.loc
     sysadmin@firewall.loc
   }
   # 定义邮件发送者
   notification_email_from Alexandre.Cassen@firewall.loc
   # 设置邮件服务器地址
   smtp_server 192.168.200.1
   # 邮件服务器连接超时30s
   smtp_connect_timeout 30
   # 路由ID(设备标识)
   router_id LVS_DEVEL
   # 如果通告与接收的上一个通告来自相同的master路由器，则不执行检查(跳过检查),默认开启
   vrrp_skip_check_adv_addr
   # 配置VRRP检测脚本
   vrrp_strict
   # 在接口上配置免费ARP发送时间
   vrrp_garp_interval 0
   # 在接口上发送未经请求的NA消息之间的延迟
   vrrp_gna_interval 0
}
#####################VRRP配置块##########################
# 定义VRRP实例
vrrp_instance VI_1 {
	# 设置VRRP状态(MASTER为主，BACKUP为备)
    state MASTER
    # VRRP绑定的网络接口
    interface eth0
    # 虚拟路由ID(相同的VRID为一个组，主从服务器需设为一致；该值为0-255)
    virtual_router_id 51
    # 优先级(越大越优)
    priority 100
    # 检查时间为1s
    advert_int 1
    # 验证方式
    authentication {
    	# 认证类型(PASS或AH)
        auth_type PASS
        # 验证密码
        auth_pass 1111
    }
    # 定义VIP，只有VRRP实例中MASTER拥有
    virtual_ipaddress {
        192.168.200.16
        192.168.200.17
        192.168.200.18
    }
}
################### LVS配置块############################
# 定义LVS虚拟服务
virtual_server 192.168.200.100 443 {
	# 服务器轮询间隔时间
    delay_loop 6
    # LVS调度算法(rr,wrr,lc,wlc,lblc,sh,dh)
    lb_algo rr
    # LVS工作模式(NAT,DR,TUN)
    lb_kind NAT
    # 会话保持时间
    persistence_timeout 50
    # 数据转发协议
    protocol TCP

	# 定义后端真实服务器IP及端口
    real_server 192.168.201.100 443 {
    	# 权重
        weight 1
        # 健康检测器(HTTP_GET\SSL_GET)
        SSL_GET {
        	# 统一资源定位器
            url {
              # 路径 
              path /
              # 摘要(监控检测需要设置摘要或status_code)
              digest ff20ad2481f97b1754ef3e12ecd3a9cc
              # status_code 200
            }
            url {
              path /mrtg/
              digest 9b3a0c85a887a256d6939da88aabd8cd
            }
            # 连接超时3s
            connect_timeout 3
            # 重试3次
            retry 3
            # 失败后重试之前的延迟
            delay_before_retry 3
        }
    }
}

virtual_server 10.10.10.2 1358 {
    delay_loop 6
    lb_algo rr
    lb_kind NAT
    persistence_timeout 50
    protocol TCP

    sorry_server 192.168.200.200 1358

    real_server 192.168.200.2 1358 {
        weight 1
        HTTP_GET {
            url {
              path /testurl/test.jsp
              digest 640205b7b0fc66c1ea91c463fac6334d
            }
            url {
              path /testurl2/test.jsp
              digest 640205b7b0fc66c1ea91c463fac6334d
            }
            url {
              path /testurl3/test.jsp
              digest 640205b7b0fc66c1ea91c463fac6334d
            }
            connect_timeout 3
            retry 3
            delay_before_retry 3
        }
    }

    real_server 192.168.200.3 1358 {
        weight 1
        HTTP_GET {
            url {
              path /testurl/test.jsp
              digest 640205b7b0fc66c1ea91c463fac6334c
            }
            url {
              path /testurl2/test.jsp
              digest 640205b7b0fc66c1ea91c463fac6334c
            }
            connect_timeout 3
            retry 3
            delay_before_retry 3
        }
    }
}

virtual_server 10.10.10.3 1358 {
    delay_loop 3
    lb_algo rr
    lb_kind NAT
    persistence_timeout 50
    protocol TCP

    real_server 192.168.200.4 1358 {
        weight 1
        HTTP_GET {
            url {
              path /testurl/test.jsp
              digest 640205b7b0fc66c1ea91c463fac6334d
            }
            url {
              path /testurl2/test.jsp
              digest 640205b7b0fc66c1ea91c463fac6334d
            }
            url {
              path /testurl3/test.jsp
              digest 640205b7b0fc66c1ea91c463fac6334d
            }
            connect_timeout 3
            retry 3
            delay_before_retry 3
        }
    }

    real_server 192.168.200.5 1358 {
        weight 1
        HTTP_GET {
            url {
              path /testurl/test.jsp
              digest 640205b7b0fc66c1ea91c463fac6334d
            }
            url {
              path /testurl2/test.jsp
              digest 640205b7b0fc66c1ea91c463fac6334d
            }
            url {
              path /testurl3/test.jsp
              digest 640205b7b0fc66c1ea91c463fac6334d
            }
            connect_timeout 3
            retry 3
            delay_before_retry 3
        }
    }
}

```



# 实验

## keepalived部署及配置

- 实验拓扑

  由两台服务器共同维护一个VIP，VIP正常情况下由Master接管，当Master发生故障后由Backup代替接管

  ![image-20220212165741955](20220212165741955.png)

- IP地址配置(略)

- Master配置

  ```shell
  [root@backup ~]# systemctl disable --now firewalld
  [root@master ~]# ip add
  1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
      link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
      inet 127.0.0.1/8 scope host lo
         valid_lft forever preferred_lft forever
      inet6 ::1/128 scope host
         valid_lft forever preferred_lft forever
  2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
      link/ether 00:0c:29:73:6d:58 brd ff:ff:ff:ff:ff:ff
      inet 172.25.250.101/24 brd 172.25.250.255 scope global noprefixroute ens33
         valid_lft forever preferred_lft forever
      inet6 fe80::20c:29ff:fe73:6d58/64 scope link noprefixroute
         valid_lft forever preferred_lft forever
  [root@master ~]# dnf -y install keepalived
  [root@master ~]# cd /etc/keepalived/
  [root@master keepalived]# cp keepalived.conf keepalived.conf.bak
  [root@master keepalived]# vim keepalived.conf
  ! Configuration File for keepalived
  
  global_defs {
     notification_email {
         # 邮箱列表没有不写
     }
     router_id master	# 路由表示设置为主机名
     vrrp_skip_check_adv_addr
     vrrp_garp_interval 0
     vrrp_gna_interval 0
  }
  
  vrrp_instance VI_1 {
      state MASTER	# 状态设置为master
      interface ens33		# 绑定接口为ens33
      virtual_router_id 51	# 虚拟路由IP
      priority 100	# 优先级
      advert_int 1
      authentication {
          auth_type PASS
          auth_pass 1111
      }
      virtual_ipaddress {
          172.25.250.100	# VIP
      }
  }
  [root@master keepalived]# systemctl enable --now keepalived
  ```

- Backup配置

  ```shell
  [root@backup ~]# systemctl disable --now firewalld
  [root@backup ~]# dnf -y install keepalived
  [root@backup ~]# cd /etc/keepalived/
  [root@backup keepalived]# ls
  keepalived.conf
  [root@backup keepalived]# mv keepalived.conf keepalived.conf.bak
  # 这里我就不修改了直接拷贝Master的配置文件过来
  [root@backup keepalived]# scp root@172.25.250.101:/etc/keepalived/keepalived.conf .		
  root@172.25.250.101's password:
  keepalived.conf                                                                       100%  424   233.5KB/s   00:00
  [root@backup keepalived]# vim keepalived.conf
  ! Configuration File for keepalived
  
  global_defs {
     notification_email {
     }
     router_id backup		# 路由ID改为主机名
     vrrp_skip_check_adv_addr
     vrrp_garp_interval 0
     vrrp_gna_interval 0
  }
  
  vrrp_instance VI_1 {
      state BACKUP	# 状态为备用
      interface ens33		# 接口
      virtual_router_id 51	# 虚拟路由ID，同于一个vrrp组需一样
      priority 99				# 备节点需比Master优先级低
      advert_int 1
      authentication {
          auth_type PASS
          auth_pass 1111		# 密码验证
      }
      virtual_ipaddress {
          172.25.250.100		# VIP
      }
  }
  [root@backup ~]# systemctl enable --now keepalived
  
  ```

  ![image-20220212171839534](20220212171839534.png)

- 验证阶段

  ```shell
  [root@master ~]# ip add
  1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
      link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
      inet 127.0.0.1/8 scope host lo
         valid_lft forever preferred_lft forever
      inet6 ::1/128 scope host
         valid_lft forever preferred_lft forever
  2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
      link/ether 00:0c:29:73:6d:58 brd ff:ff:ff:ff:ff:ff
      inet 172.25.250.101/24 brd 172.25.250.255 scope global noprefixroute ens33
         valid_lft forever preferred_lft forever
      inet 172.25.250.100/32 scope global ens33		# VIP
         valid_lft forever preferred_lft forever
      inet6 fe80::20c:29ff:fe73:6d58/64 scope link noprefixroute
         valid_lft forever preferred_lft forever
  -------------------------------------------------------------------------------------------
  [root@backup ~]# ip add
  1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
      link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
      inet 127.0.0.1/8 scope host lo
         valid_lft forever preferred_lft forever
      inet6 ::1/128 scope host
         valid_lft forever preferred_lft forever
  2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
      link/ether 00:0c:29:b7:ea:f8 brd ff:ff:ff:ff:ff:ff
      inet 172.25.250.102/24 brd 172.25.250.255 scope global noprefixroute ens33
         valid_lft forever preferred_lft forever
      inet6 fe80::20c:29ff:feb7:eaf8/64 scope link noprefixroute
         valid_lft forever preferred_lft forever
  [root@backup ~]#
  # 通过ipadd命令查看，可以发现VIP由master接管
  ------------------------------------------------------------------------------------------
  ```

  ![image-20220212183851781](20220212183851781.png)

  当我主动断开master网卡接口之后，172.25.250.100被backup接管

- 分析日志

  ```shell
  [root@backup ~]# tail -n 50 /var/log/messages
  Feb 12 05:30:02 backup Keepalived_vrrp[1141]: (VI_1) Sending/queueing gratuitous ARPs on ens33 for 172.25.250.100
  Feb 12 05:30:02 backup Keepalived_vrrp[1141]: Sending gratuitous ARP on ens33 for 172.25.250.100
  Feb 12 05:30:02 backup Keepalived_vrrp[1141]: Sending gratuitous ARP on ens33 for 172.25.250.100
  Feb 12 05:30:02 backup Keepalived_vrrp[1141]: Sending gratuitous ARP on ens33 for 172.25.250.100
  Feb 12 05:30:02 backup Keepalived_vrrp[1141]: Sending gratuitous ARP on ens33 for 172.25.250.100
  Feb 12 05:30:02 backup Keepalived_vrrp[1141]: Sending gratuitous ARP on ens33 for 172.25.250.100
  Feb 12 05:30:16 backup Keepalived_vrrp[1141]: (VI_1) Master received advert from 172.25.250.101 with higher priority 255, ours 99
  Feb 12 05:30:16 backup Keepalived_vrrp[1141]: (VI_1) Entering BACKUP STATE	# 此时服务器还是backup状态
  Feb 12 05:30:16 backup Keepalived_vrrp[1141]: (VI_1) removing VIPs.	# 并移除VIP
  Feb 12 05:30:53 backup kernel: perf: interrupt took too long (4036 > 3271), lowering kernel.perf_event_max_sample_rate to 49000
  Feb 12 05:36:40 backup systemd[1]: Starting Cleanup of Temporary Directories...
  Feb 12 05:36:40 backup systemd[1]: systemd-tmpfiles-clean.service: Succeeded.
  Feb 12 05:36:40 backup systemd[1]: Started Cleanup of Temporary Directories.
  Feb 12 05:37:59 backup Keepalived_vrrp[1141]: (VI_1) Backup received priority 0 advertisement
  Feb 12 05:38:00 backup Keepalived_vrrp[1141]: (VI_1) Receive advertisement timeout	# 检查超时，此时因为我们关闭了master的网卡
  Feb 12 05:38:00 backup Keepalived_vrrp[1141]: (VI_1) Entering MASTER STATE	# 服务器进入master状态进行接管
  Feb 12 05:38:00 backup Keepalived_vrrp[1141]: (VI_1) setting VIPs.	# 添加VIP
  Feb 12 05:38:00 backup Keepalived_vrrp[1141]: (VI_1) Sending/queueing gratuitous ARPs on ens33 for 172.25.250.100
  Feb 12 05:38:00 backup Keepalived_vrrp[1141]: Sending gratuitous ARP on ens33 for 172.25.250.100
  Feb 12 05:38:00 backup Keepalived_vrrp[1141]: Sending gratuitous ARP on ens33 for 172.25.250.100
  Feb 12 05:38:00 backup Keepalived_vrrp[1141]: Sending gratuitous ARP on ens33 for 172.25.250.100
  Feb 12 05:38:00 backup Keepalived_vrrp[1141]: Sending gratuitous ARP on ens33 for 172.25.250.100
  Feb 12 05:38:00 backup Keepalived_vrrp[1141]: Sending gratuitous ARP on ens33 for 172.25.250.100
  Feb 12 05:38:05 backup Keepalived_vrrp[1141]: (VI_1) Sending/queueing gratuitous ARPs on ens33 for 172.25.250.100
  Feb 12 05:38:05 backup Keepalived_vrrp[1141]: Sending gratuitous ARP on ens33 for 172.25.250.100
  Feb 12 05:38:05 backup Keepalived_vrrp[1141]: Sending gratuitous ARP on ens33 for 172.25.250.100
  Feb 12 05:38:05 backup Keepalived_vrrp[1141]: Sending gratuitous ARP on ens33 for 172.25.250.100
  Feb 12 05:38:05 backup Keepalived_vrrp[1141]: Sending gratuitous ARP on ens33 for 172.25.250.100
  Feb 12 05:38:05 backup Keepalived_vrrp[1141]: Sending gratuitous ARP on ens33 for 172.25.250.100
  ```

  

## LVS+Keepalived实践

> 采用LVS VS/DR模式+Keepalived

- 实验拓扑

  ![image-20220212204324934](20220212204324934.png)

- 配置环境

  - 四台Web服务器

    ```shell
    [root@web01 ~]# vi /etc/sysctl.conf
    net.ipv4.conf.all.arp_ignore = 1
    net.ipv4.conf.lo.arp_ignore = 1
    net.ipv4.conf.all.announce = 2
    net.ipv4.conf.lo.announce = 2
    [root@web01 ~]# sysctl -p
    [root@web01 ~]# ip address add 192.168.100.100/32 dev lo
    [root@web01 ~]# ip address
    ```

    ![image-20220212210709887](20220212210709887.png)

    ``` shell
    [root@web01 ~]# mount /dev/sr0 /mnt/
    [root@web01 ~]# tee > /etc/yum.repos.d/a.repo << EOF
    [BaseOS]
    name = BaseOS
    baseurl = file:///mnt/BaseOS
    enabled = 1 
    gpgcheck = 0
    
    [AppStream]
    name = AppStream
    baseurl = file:///mnt/AppStream
    enabled = 1
    gpgcheck = 0
    EOF
    [root@web01 ~]# dnf -y install httpd
    [root@web01 ~]# systemctl enable --now httpd
    [root@web01 ~]# systemctl disable --now firewalld
    [root@web01 ~]# echo "web01" > /var/www/html/index.html
    [root@web01 ~]# curl http://localhost
    ```

    ![image-20220212211319941](20220212211319941.png)

    ```shell
    [root@web01 ~]# scp /etc/sysctl.conf 192.168.200.102:/etc/sysctl.conf
    [root@web01 ~]# scp /etc/sysctl.conf 192.168.200.103:/etc/sysctl.conf
    [root@web01 ~]# scp /etc/sysctl.conf 192.168.200.104:/etc/sysctl.conf
    [root@web01 ~]# scp /etc/yum.repos.d/a.repo 192.168.200.102:/etc/yum.repos.d/a.repo
    [root@web01 ~]# scp /etc/yum.repos.d/a.repo 192.168.200.103:/etc/yum.repos.d/a.repo
    [root@web01 ~]# scp /etc/yum.repos.d/a.repo 192.168.200.104:/etc/yum.repos.d/a.repo
    [root@web01 ~]# ssh 192.168.200.102
    [root@web02 ~]# sysctl -p
    [root@web02 ~]# ip address add 192.168.100.100/32 dev lo
    [root@web02 ~]# mount /dev/sr0 /mnt
    [root@web02 ~]# dnf -y install httpd
    [root@web02 ~]# systemctl enable --now httpd
    [root@web02 ~]# systemctl disable --now firewalld
    [root@web02 ~]# curl http://localhost
    ```

   ![image-20220212212042834](20220212212042834.png)

    ```shell
    [root@web02 ~]# ssh 192.168.200.103
    [root@web03 ~]# sysctl -p
    [root@web03 ~]# ip address add 192.168.100.100/32 dev lo
    [root@web03 ~]# mount /dev/sr0 /mnt/
    [root@web03 ~]# dnf -y install httpd
    [root@web03 ~]# systemctl enable --now httpd
    [root@web03 ~]# systemctl disable --now firewalld
    [root@web03 ~]# echo "web03" > /var/www/html/index.html
    [root@web03 ~]# curl http://localhost
    ```

   ![image-20220212212600468](20220212212600468.png)

    ```shell
    [root@web03 ~]# ssh 192.168.200.104
    [root@web04 ~]# mount /dev/sr0 /mnt
    [root@web04 ~]# sysctl -p
    [root@web04 ~]# ip add add 192.168.100.100/32 dev lo
    [root@web04 ~]# dnf -y install httpd
    [root@web04 ~]# systemctl enable --now httpd
    [root@web04 ~]# systemctl disable --now firewalld
    [root@web04 ~]# echo "web04" > /var/www/html/index.html
    [root@web04 ~]# curl http://localhost
    ```

    ![image-20220212212940769](20220212212940769.png)

    

  - **配置Keepalived(Master)+LVS**

    IP配置略

    ![image-20220212214708348](20220212214708348.png)

    ```shell
    [root@master ~]# scp 192.168.200.101:/etc/yum.repos.d/a.repo /etc/yum.repos.d/a.repo
    [root@master ~]# mount /dev/sr0 /mnt
    [root@master ~]# systemctl disable --now firewalld
    [root@master ~]# echo "1" > /proc/sys/net/ipv4/ip_forward
    [root@master ~]# dnf -y install keepalived
    [root@master ~]# dnf -y install vim 
    [root@master ~]# cp /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.bak
    [root@master ~]# vim /etc/keepalived/keepalived.conf
    ! Configuration File for keepalived
    
    global_defs {
    	router_id master
    }
    
    vrrp_instance VI_1 {
    	state MASTER
    	interface ens33
    	virtual_router_id 51
    	priority 100
    	advert_int 1
    	authentication {
    		auth_type PASS
    		auth_pass 1111
    	}
    	virtual_ipaddress {
    		192.168.100.100
    	}
    }
    
    virtual_server 192.168.100.100 80 {
    	delay_loop 6
    	lb_algo rr
    	lb_kind DR
    	persistence_timeout 50
    	
    	real_server 192.168.200.101 80 {
    		weight 1
    	}
    	real_server 192.168.200.102 80 {
    		weight 1
    	}
    	real_server 192.168.200.103 80 {
    		weight 1
    	}
    	real_server 192.168.200.104 80 {
    		weight 1
    	}
    }
    [root@master ~]# systemctl enable --now keepalived
    
    ```

  - **配置Keepalived(Backup)+LVS**

    ```shell
    [root@backup ~]# mount /dev/sr0 /mnt/
    [root@backup ~]# scp 192.168.100.101:/etc/yum.repos.d/a.repo /etc/yum.repos.d/a.repo
    [root@backup ~]# systemctl disable --now firewalld
    [root@backup ~]# echo "1" > /proc/sys/net/ipv4/ip_forward
    [root@backup ~]# dnf -y install vim keepalived
    [root@backup ~]# scp 192.168.100.101:/etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf
    [root@backup ~]# vim /etc/keepalived/keepalived.conf
    ! Configuration File for keepalived
    
    global_defs {
    	router_id backup
    }
    
    vrrp_instance VI_1 {
    	state BACKUP
    	interface ens33
    	virtual_router_id 51
    	priority 99
    	advert_int 1
    	authentication {
    		auth_type PASS
    		auth_pass 1111
    	}
    	virtual_ipaddress {
    		192.168.100.100
    	}
    }
    
    virtual_server 192.168.100.100 80 {
    	delay_loop 6
    	lb_algo rr
    	lb_kind DR
    	persistence_timeout 50
    	
    	real_server 192.168.200.101 80 {
    		weight 1
    	}
    	real_server 192.168.200.102 80 {
    		weight 1
    	}
    	real_server 192.168.200.103 80 {
    		weight 1
    	}
    	real_server 192.168.200.104 80 {
    		weight 1
    	}
    }
    [root@backup ~]# systemctl enable --now keepalived
    ```

  - **配置网关及Nat**

    - 配置网卡

    ![image-20220212221601562](20220212221601562.png)

    - 安装服务

      ![image-20220212221808032](20220212221808032.png)

      选择路由然后一下步直至安装完毕

      ![image-20220212221823741](20220212221823741.png)

      

    - 安装好之后配置NAT

      ![image-20220212222047738](20220212222047738.png)

      ![image-20220212222248554](20220212222248554.png)

- 测试

  IP地址随意，不一定按照拓扑图上来

  我这测试的情况是一台主机发送请求后一直对应后端的Web02服务器，更换IP后后端Web才变

  ![image-20220212225053422](20220212225053422.png)

  ![image-20220212225231668](20220212225231668.png)

- 断开Master网卡

  ```shell
  [root@master ~]# nmcli connection down ens33
  ```

  再次访问(结果正常，实现了LVS的高可用)

  ![image-20220212225440861](20220212225440861.png)

  - Backup正常接管VIP

![image-20220212225536408](20220212225536408.png)

