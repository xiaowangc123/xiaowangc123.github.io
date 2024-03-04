---
title: LVM实现数据一致性备份迁移
abbrlink: e54f90b7
date: 2022-10-24 14:47:10
tags:
  - LVM
  - Linux
  - 数据一致性
  - 备份
categories: Linux
cover: img/fengmian/linux.png
---
# LVM介绍

## 基础

算了，主要也不是讲LVM的操作，不介绍了....

## 快照

LVM快照机制，基于写时复制技术实现对数据进行备份/镜像，这比传统的备份技术效率要高，创建快照无需停止服务即可对数据进行备份/镜像

一般情况下，不停止服务或停机的情况下对数据进行备份，由于不停机整个数据块的内容是时时变化的，那么数据是存在不一致性的。**不一致的数据备份没有任何价值**，目前在LVM2中引入了基于软件实现快照的技术，几乎是零成本，但效果明显；

LVM快照是基于存储级别而不是文件级别，由于采用CoW技术，所以创建逻辑卷的快照时间几乎为0，这可以保证快照数据一致性至关重要，此时系统总存在两份数据，一份是源数据，一份是快照数据

# COW

**Copy-on-Write(COW)，写时复制技术**

当LVM创建快照的一瞬间，系统会记录那个时间点LV的数据块和状态等信息。当快照创建之后没有发生数据的修改，源数据和快照数据是共享的，也就是此时此刻的数据在存储中只有一份。当进程对文件进行增/改/删操作时，系统会先把原来的数据块Copy到快照中，然后再写入源数据块。此后再对这个已经修改的源数据块进行修改就不用再Copy到快照中！

![image-20221018174341086](image-20221018174341086.png)

# 实现

`保证快照LV大小要与源LV大小一致` 

`只能在同过一个VG中创建快照`

1. 添加一块硬盘

   ```shell
   [root@xiaowangc ~]# lsblk
   NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
   sr0          11:0    1  9.3G  0 rom
   nvme0n1     259:0    0   20G  0 disk
   ├─nvme0n1p1 259:1    0    1G  0 part /boot
   └─nvme0n1p2 259:2    0   19G  0 part
     ├─cl-root 253:0    0   17G  0 lvm  /
     └─cl-swap 253:1    0    2G  0 lvm  [SWAP]
   nvme0n2     259:3    0   20G  0 disk						# 此硬盘是新添加的
   ```

2. 创建PV

   ```shell
   [root@xiaowangc ~]# pvcreate /dev/nvme0n2
     Physical volume "/dev/nvme0n2" successfully created.
   ```

3. 创建VG

   ```shell
   [root@xiaowangc ~]# vgcreate data /dev/nvme0n2
     Volume group "data" successfully created
   ```

4. 创建LV

   ```shell
   [root@xiaowangc ~]# lvcreate -L +2G -n web data
     Logical volume "web" created.
   ```

5. 格式化LV

   ```shell
   [root@xiaowangc ~]# mkfs.ext4 /dev/mapper/data-web
   mke2fs 1.45.6 (20-Mar-2020)
   Creating filesystem with 524288 4k blocks and 131072 inodes
   Filesystem UUID: dc410526-15dd-4e8e-81ea-7b106b1ae656
   Superblock backups stored on blocks:
           32768, 98304, 163840, 229376, 294912
   
   Allocating group tables: done
   Writing inode tables: done
   Creating journal (16384 blocks): done
   Writing superblocks and filesystem accounting information: done
   ```

6. 挂载LV

   ```shell
   [root@xiaowangc ~]# mkdir /web_data
   [root@xiaowangc ~]# mount /dev/mapper/data-web /web_data/
   [root@xiaowangc ~]# blkid
   /dev/nvme0n1: PTUUID="6d0cc3a7" PTTYPE="dos"
   /dev/nvme0n1p1: UUID="dc078753-6fab-4c5a-8159-3b8574e695ba" BLOCK_SIZE="512" TYPE="xfs" PARTUUID="6d0cc3a7-01"
   /dev/nvme0n1p2: UUID="v7zY6z-be09-lpfv-M30s-zq74-pcdn-inhNdV" TYPE="LVM2_member" PARTUUID="6d0cc3a7-02"
   /dev/nvme0n2: UUID="sjdx2e-xE43-tcfL-n68g-qMpe-ayqZ-SDoWma" TYPE="LVM2_member"
   /dev/sr0: BLOCK_SIZE="2048" UUID="2021-06-01-20-39-18-00" LABEL="CentOS-8-4-2105-x86_64-dvd" TYPE="iso9660" PTUUID="44956b46" PTTYPE="dos"
   /dev/mapper/cl-root: UUID="a9c18d43-b830-4b9e-b81f-54fcb5a722e9" BLOCK_SIZE="512" TYPE="xfs"
   /dev/mapper/cl-swap: UUID="9306acb9-f748-4d55-a7a7-b127b7c9de7b" TYPE="swap"
   /dev/mapper/data-web: UUID="dc410526-15dd-4e8e-81ea-7b106b1ae656" BLOCK_SIZE="4096" TYPE="ext4"
   [root@xiaowangc ~]# echo 'UUID=dc410526-15dd-4e8e-81ea-7b106b1ae656 /web_data ext4 defaults 0 0' >> /etc/fstab
   ```

7. 写入数据测试

   ```shell
   [root@xiaowangc ~]# vi w_file.sh
   /bin/bash
   for i in {1..1000000000000000};
   do
     sleep 0.1
     touch /web_data/file_$i
   done
   [root@xiaowangc ~]# nohup bash w_file.sh &
   [1] 1960
   nohup: ignoring input and appending output to 'nohup.out'
   [root@xiaowangc ~]# ls /web_data/
   file_1    file_113  file_128  file_142  file_157  file_171  file_186  file_28  file_42  file_57  file_71  file_86
   file_10   file_114  file_129  file_143  file_158  file_172  file_187  file_29  file_43  file_58  file_72  file_87
   file_100  file_115  file_13   file_144  file_159  file_173  file_188  file_3   file_44  file_59  file_73  file_88
   file_101  file_116  file_130  file_145  file_16   file_174  file_189  file_30  file_45  file_6   file_74  file_89
   file_102  file_117  file_131  file_146  file_160  file_175  file_19   file_31  file_46  file_60  file_75  file_9
   file_103  file_118  file_132  file_147  file_161  file_176  file_190  file_32  file_47  file_61  file_76  file_90
   ```

8. 对LV创建快照

   ```shell
   [root@xiaowangc ~]# [root@xiaowangc ~]# lvcreate -n web_data_bak -s -L 2G /dev/mapper/data-web
     Logical volume "web_data_bak" created.
   [root@xiaowangc ~]# lvs
     LV           VG   Attr       LSize   Pool Origin Data%  Meta%  Move Log Cpy%Sync Convert
     root         cl   -wi-ao---- <17.00g
     swap         cl   -wi-ao----   2.00g
     web          data owi-aos---   2.00g
     web_data_bak data swi-a-s---   2.00g      web    0.03			# 瞬间进行快照
   ```

9. 查看快照

   ```shell
   [root@xiaowangc ~]# mount /dev/mapper/data-web_data_bak /root/test/
   [root@xiaowangc ~]# cd test/
   [root@xiaowangc test]# ls
   file_1                        file_1249  file_150   file_1751  file_2001  file_2253  file_2504  file_499  file_75
   file_10                       file_125   file_1500  file_1752  file_2002  file_2254  file_2505  file_5    file_750
   file_100                      file_1250  file_1501  file_1753  file_2003  file_2255  file_2506  file_50   file_751
   file_1000                     file_1251  file_1502  file_1754  file_2004  file_2256  file_2507  file_500  file_752
   file_1001                     file_1252  file_1503  file_1755  file_2005  file_2257  file_2508  file_501  file_753
   ```

10. 对比数据

    ```shell
    [root@xiaowangc test]# df -h
    Filesystem                     Size  Used Avail Use% Mounted on
    devtmpfs                       1.8G     0  1.8G   0% /dev
    tmpfs                          1.9G     0  1.9G   0% /dev/shm
    tmpfs                          1.9G  9.0M  1.9G   1% /run
    tmpfs                          1.9G     0  1.9G   0% /sys/fs/cgroup
    /dev/mapper/cl-root             17G  2.8G   15G  17% /
    /dev/nvme0n1p1                1014M  197M  818M  20% /boot
    tmpfs                          371M     0  371M   0% /run/user/0
    /dev/mapper/data-web           2.0G  6.3M  1.8G   1% /web_data
    /dev/mapper/data-web_data_bak  2.0G  6.1M  1.8G   1% /root/test
    [root@xiaowangc test]# pwd
    /root/test
    [root@xiaowangc test]# ls | wc -l
    2511
    [root@xiaowangc test]# ls /web_data/ | wc -l
    7031
    ```

11. 对数据进行打包备份

    ```shell
    [root@xiaowangc test]# tar zcvf /root/web_backup.tar.gz *
    ```

    













































