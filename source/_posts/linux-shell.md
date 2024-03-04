---
title: Linux-Shell基础
abbrlink: 8baf922f
date: 2022-11-07 02:27:59
tags:
  - Linux
  - Shell
categories: Linux
cover: img/fengmian/linux.png
---
# Shell基础

## Bash注释

- Bash只支持单行注释，使用`#`开头的都被当作注释语句

  ```shell
  # 单行注释
  
  echo "Hello World"	#注释
  ```

  

- 通过Bash特性，可以实现多行注释

  ```shell
  :'
  注释
  '
  
  : <<'EOF'
  注释
  EOF
  
  ```

  

## Bash基本数据类型

- Bash中基本数据类型只有字符串类型，连数值类型都没有

  ```shell
  # 都是字符串类型，可用declare -i声明为数值类型
  [root@localhost ~]# echo hello
  [root@localhost ~]# echo 123
  ```

  

## Bash字符串串联

- Bash中字符串的串联操作，可用将两段数据连接在一起

  ```shell
  [root@localhost ~]# echo xiaowang xiaowangc
  xiaowang xiaowangc
  [root@localhost ~]#
  ```

  

## 变量赋值和引用变量

```shell
[root@localhost ~]# a=xiaowangc
[root@localhost ~]# echo $a
xiaowangc
[root@localhost ~]#
```

- Shell可用使用未定义的变量和使用空变量

  ```shell
  [root@localhost ~]# echo $abc
  
  [root@localhost ~]# a=
  [root@localhost ~]# echo $a
  
  [root@localhost ~]#
  ```

- 变量引用

  ```shell
  [root@localhost ~]# a=666
  [root@localhost ~]# echo $a 777
  666 777
  [root@localhost ~]#
  ```

  

## 命令替换

- 命令替换是值先执行id root，将id root的输出结果替换到$()

  ```shell
  [root@localhost ~]# echo $(id root)
  uid=0(root) gid=0(root) groups=0(root)
  ```

  

## 算数运算

- Shell可用使用$[]和$(())和let命令做算数运算

  ```shell
  [root@localhost ~]# a=10
  [root@localhost ~]# echo $[a+3]
  13
  [root@localhost ~]# echo $((a+3))
  13
  [root@localhost ~]# echo $((1+1))
  2
  [root@localhost ~]# let a+3
  [root@localhost ~]# let a=a+3
  [root@localhost ~]# echo $a
  13
  ```



## 退出状态码

> 每个命令执行之后都有对应的进程退出状态码，用来表示该进程是否正常退出。所以，在Shell中经常会使用特殊变量$?判断前台命令是否正常退出。

- 如果$?的值为：
  - 为0，表示进程成功执行，即正常退出
  - 非0，表示进程未成功执行，即非正常退出
  - 非0退出状态码不一定表示错误，也可能是逻辑上正常的退出
- 在Shell脚本中，所有条件判断（比如if语句、while语句）都以0退出状态码表示True，以非0退出状态码表示False



## Exit命令

> exit命令可用于退出当前Shell进程。退出Shell终端、脚本等。

```shell
$ exit
```



## 后台执行命令&

> 在命令的结尾使用&符号，表示将这个命令放入后台执行。

```shell
[root@localhost ~]# sleep 20 &
[root@localhost ~]# echo $!
```



## 多命令组合

> Shell中有多种组合多个命令的方式

- 分号

  ```shell
  [root@localhost ~]# echo xiaowangc ; echo hello
  xiaowangc
  hello
  [root@localhost ~]#
  ```

- &&

  前者正确执行完毕并正常退出后，执行后者命令

  ```shell
  [root@localhost ~]# echo xiaowangc && echo hello
  xiaowangc
  hello
  [root@localhost ~]#
  ```

- ||；如果前者正确只执行前者，前者不正确执行后者（或）

  ```shell
  [root@localhost ~]# ping asdf && ping www.baidu.com
  
  [root@localhost ~]# ping -c 4 www.baidu.com || ping abc
  ```

- 逻辑结合

  ```shell
  # 命令1 && 命令2 && 命令3...  
  如果命令1正确执行则执行命令2，如果命令2正确执行则执行命令3
  
  # 命令1 && 命令2 || 命令3...
  如果命令1正确执行则执行命令2，如果命令1不正确执行则执行命令3
  如果命令1正确执行则执行命令2，如果命令2不正确执行则执行命令3
  
  # 命令1 || 命令2 && 命令3...
  如果命令1正确执行则执行命令3
  如果命令1不正确执行则执行命令2，如果命令2正确执行则执行命令3
  ```

  

## 多个命令组合

- 通过小括号或者大括号组合多个命令

  ```shell
  (命令1 ; 命令2 ; 命令3)
  # 小括号是在子Shell中执行
  
  { 命令1 ; 命令2 ; 命令3}
  {
  	命令1
  	命令2
  	命令3
  }
  # 大括号当前Shell中执行
  ```

  

## 重定向

> 标准输入、标准输出、标准错误，在Linux系统中，每个程序默认都会打开三个文件描述符

- fd=0：标准输入
- fd=1：标准输出
- fd=2：标准错误

Linux中一切皆文件，文件描述符也是文件：

- fd = 0：对应/dev/stdin文件
- fd = 1：对应/dev/stdout文件
- fd = 2：对应/dev/stderr文件

```shell
[root@localhost ~]# ls -l /dev/std*
lrwxrwxrwx. 1 root root 15 May  3 04:28 /dev/stderr -> /proc/self/fd/2
lrwxrwxrwx. 1 root root 15 May  3 04:28 /dev/stdin -> /proc/self/fd/0
lrwxrwxrwx. 1 root root 15 May  3 04:28 /dev/stdout -> /proc/self/fd/1
[root@localhost ~]#
```



### 重定向操作

```shell
1. > #格式化输出

2. >> #追加输出

3. < #输入重定向

4. &> #特殊重定向，将标准错误和标准输出都重定向到指定的File中,等价于>file 2>&1

5. &>> #特殊重定向,将标准错误和标准输出都追加到指定File中，等价于>>file 2>&1
```

还有一种操作经常将输出的目标文件指定为/dev/null。它是空设备，

```shell
cat /dev/null > file  #清空文件

```



### cat命令

```shell
[root@localhost ~]# cat -n /etc/fstab		#-n选项，输出时带行号
     1
     2  #
     3  # /etc/fstab
     4  # Created by anaconda on Sun May  2 20:23:48 2021
     5  #
     6  # Accessible filesystems, by reference, are maintained under '/dev/disk/'.
     7  # See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info.
     8  #
     9  # After editing this file, run 'systemctl daemon-reload' to update systemd
    10  # units generated from this file.
    11  #
    12  /dev/mapper/cl-root     /                       xfs     defaults        0 0
    13  UUID=ffc9c9ba-0b05-43c3-8241-e19518b8c840 /boot                   ext4    defaults        1 2
    14  /dev/mapper/cl-swap     swap                    swap    defaults        0 0
[root@localhost ~]# cat < /etc/fstab

#
# /etc/fstab
# Created by anaconda on Sun May  2 20:23:48 2021
#
# Accessible filesystems, by reference, are maintained under '/dev/disk/'.
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info.
#
# After editing this file, run 'systemctl daemon-reload' to update systemd
# units generated from this file.
#
/dev/mapper/cl-root     /                       xfs     defaults        0 0
UUID=ffc9c9ba-0b05-43c3-8241-e19518b8c840 /boot                   ext4    defaults        1 2
/dev/mapper/cl-swap     swap                    swap    defaults        0 0
[root@localhost ~]#


```



### here docer

输入重定向是<，除此之外还有<<,<<<

- <<符号表示here doc，也就是后面表示跟着的是一篇文档。常用于多行数据输入

  ```shell
  [root@localhost ~]# cat << EOF		#here doc作为标准输入被读取，然后被cat输出
  > hello
  > xiaowangc
  > EOF
  hello
  xiaowangc
  [root@localhost ~]# cat << EOF > xiaowangc.txt	#here doc的内容还会被cat格式化输出到指定文档
  > hello
  > xiaowangc
  > EOF
  [root@localhost ~]# cat xiaowangc.txt
  hello
  xiaowangc
  [root@localhost ~]#
  ```

- <<<表示here string。也就是说该符号后面是一个字符串

  ```shell
  [root@localhost ~]# cat <<< xiaowangc
  xiaowangc
  [root@localhost ~]# a=11111
  [root@localhost ~]# cat <<< $a
  11111
  [root@localhost ~]# cat <<< "xiaowangc$a"	#使用双引号时会进行替换
  xiaowangc11111
  [root@localhost ~]# cat <<< 'xiaowangc$a'	#使用单引号时不会进行替换
  xiaowangc$a
  [root@localhost ~]#
  
  
  ```

  

## 管道

> 每一个竖线”|“代表一个管道，第一个命令的标准输出会放进管道，第二个命令会从管道中读取进行处理

```shell
[root@localhost ~]# ps -aux | grep sshd
root        1005  0.0  0.5  92968  4280 ?        Ss   May08   0:00 /usr/sbin/sshd -D -oCiphers=aes256-gcm@openssh.com,chacha20-poly1305@openssh.com,aes256-ctr,aes256-cbc,aes128-gcm@openssh.com,aes128-ctr,aes128-cbc -oMACs=hmac-sha2-256-etm@openssh.com,hmac-sha1-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-512-etm@openssh.com,hmac-sha2-256,hmac-sha1,umac-128@openssh.com,hmac-sha2-512 -oGSSAPIKexAlgorithms=gss-gex-sha1-,gss-group14-sha1- -oKexAlgorithms=curve25519-sha256,curve25519-sha256@libssh.org,ecdh-sha2-nistp256,ecdh-sha2-nistp384,ecdh-sha2-nistp521,diffie-hellman-group-exchange-sha256,diffie-hellman-group14-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512,diffie-hellman-group-exchange-sha1,diffie-hellman-group14-sha1 -oHostKeyAlgorithms=rsa-sha2-256,rsa-sha2-256-cert-v01@openssh.com,ecdsa-sha2-nistp256,ecdsa-sha2-nistp256-cert-v01@openssh.com,ecdsa-sha2-nistp384,ecdsa-sha2-nistp384-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-512-cert-v01@openssh.com,ecdsa-sha2-nistp521,ecdsa-sha2-nistp521-cert-v01@openssh.com,ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,ssh-rsa,ssh-rsa-cert-v01@openssh.com -oPubkeyAcceptedKeyTypes=rsa-sha2-256,rsa-sha2-256-cert-v01@openssh.com,ecdsa-sha2-nistp256,ecdsa-sha2-nistp256-cert-v01@openssh.com,ecdsa-sha2-nistp384,ecdsa-sha2-nistp384-cert-v01@openssh.com,rsa-sha2-512,rsa-sha2-512-cert-v01@openssh.com,ecdsa-sha2-nistp521,ecdsa-sha2-nistp521-cert-v01@openssh.com,ssh-ed25519,ssh-ed25519-cert-v01@openssh.com,ssh-rsa,ssh-rsa-cert-v01@openssh.com -oCASignatureAlgorithms=rsa-sha2-256,ecdsa-sha2-nistp256,ecdsa-sha2-nistp384,rsa-sha2-512,ecdsa-sha2-nistp521,ssh-ed25519,ssh-rsa
root       55071  0.0  1.2 152904  9960 ?        Ss   05:23   0:00 sshd: root [priv]
root       55085  0.0  0.6 152904  5060 ?        S    05:23   0:00 sshd: root@pts/0
root       58868  0.0  0.1  12112  1040 pts/0    R+   07:35   0:00 grep --color=auto sshd
[root@localhost ~]#
```

让grep既从/etc/fstab读取数据，也从管道中读取数据

```shell
[root@localhost ~]# ps aux | grep "#" /etc/fstab /dev/stdin
/etc/fstab:#
/etc/fstab:# /etc/fstab
/etc/fstab:# Created by anaconda on Sun May  2 20:23:48 2021
/etc/fstab:#
/etc/fstab:# Accessible filesystems, by reference, are maintained under '/dev/disk/'.
/etc/fstab:# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info.
/etc/fstab:#
/etc/fstab:# After editing this file, run 'systemctl daemon-reload' to update systemd
/etc/fstab:# units generated from this file.
/etc/fstab:#
/dev/stdin:zabbix     19079  0.0  0.3  76692  2584 ?        S    May08   0:00 /usr/sbin/zabbix_agentd: listener #1 [waiting for connection]
/dev/stdin:zabbix     19080  0.0  0.3  76692  2592 ?        S    May08   0:00 /usr/sbin/zabbix_agentd: listener #2 [waiting for connection]
/dev/stdin:zabbix     19081  0.0  0.3  76692  2672 ?        S    May08   0:00 /usr/sbin/zabbix_agentd: listener #3 [waiting for connection]
/dev/stdin:zabbix     19082  0.0  0.3  76692  2848 ?        S    May08   0:04 /usr/sbin/zabbix_agentd: active checks #1 [idle 1 sec]
/dev/stdin:root       58944  0.0  0.1  12112  1000 pts/0    R+   07:38   0:00 grep --color=auto # /etc/fstab /dev/stdin
[root@localhost ~]#

```



## tee命令

> tee命令可以将标准输入复制到标准输出和0或多个文件中。tee的作用是数据多重定向

```shell
[root@localhost ~]# echo hello | tee /tmp/xiaowangc /tmp/xiaowc | cat
hello
```



## 条件测试语句

test命令或Bash内置命令[ ]可以做条件测试，如果测试的结果为True，则退出的状态码为0

这些条件测试常用在if、while语句中

- true和false命令

  true命令返回true，退出码为0

  false命令返回false，退出码非0

  ```shell
  [root@localhost ~]# true
  [root@localhost ~]# echo $?
  0
  [root@localhost ~]# false
  [root@localhost ~]# echo $?
  1
  [root@localhost ~]#
  ```

- 文件类测试

  | 条件表达式 |               含义               |
  | :--------: | :------------------------------: |
  |     -e     |         判断文件是否存在         |
  |     -f     |   判断文件是否存在且为普通文件   |
  |     -b     |    判断文件是否存在且为块设备    |
  |     -c     |   判断文件是否存在且为字符设备   |
  |     -S     |  判断文件是否存在且为套接字文件  |
  |     -p     | 判断文件是否存在且为命令管道文件 |
  |     -l     | 判断文件是否存在且为一个链接文件 |
  |     -d     |   判断文件是否存在且为普通目录   |

- 文件属性类测试

  | 条件表达式 |                  含义                  |
  | :--------: | :------------------------------------: |
  |     -r     |       文件是否存在且当前用户可读       |
  |     -w     |       文件是否存在且当前用户可写       |
  |     -x     |      文件是否存在且当前用户可执行      |
  |     -s     |        文件是否存在且为非空文件        |
  |     -N     | 文件是否存在，且上次read后是否被modify |

- 两个文件之间的比较

  |   条件表达式    |              含义              |
  | :-------------: | :----------------------------: |
  | file1 -nt file2 |     判断file1是否比file2新     |
  | file1 -ot file2 |     判断file1是否比file2旧     |
  | file1 -ef file2 | 判断file1与file2是否为同一文件 |

- 数值大小比较

  |  条件表达式   |      含义      |
  | :-----------: | :------------: |
  | int1 -eq int2 |  两个数值相等  |
  | int1 -ne int2 | 两个数值不相等 |
  | int1 -gt int2 |    n1大于n2    |
  | int1 -lt int2 |    n1小于n2    |
  | int1 -ge int2 |  n1大于等于n2  |
  | int1 -le int2 |  n1小于等于n2  |

  

- 字符串比较

  |         条件表达式          |                  含义                  |
  | :-------------------------: | :------------------------------------: |
  |           -z str            |      判断字符串是否为空，返回true      |
  |        str or -n str        |     判断字符串是否为空，返回falsh      |
  | str1 = str2 or str1 == str2 | 判断str1和str2是否相同，相同则返回true |
  |        str1 ！= str2        |         判断str1是否不等于str2         |
  |         str1 > str2         |          判断str1是否大于str2          |
  |         str1 < str          |          判断str1是否小于str2          |

- 逻辑运算符

  | 条件表达式 |              含义              |
  | :--------: | :----------------------------: |
  |  -a or &&  |   两表达式同时为true才为true   |
  | -o or \|\| | 两表达式任何一个为true则为true |
  |     ！     |          对表达式取反          |
  |    （）    |        更改表达式优先级        |

  

## if语句

```shell
if 条件判断式1; then
	#当条件满足时，执行的语句
	语句;
[elif 条件判断式2; then
	#当条件满足时，执行的语句;]
[else 所有条件不成立时，执行此语句;]
fi

#test-commands既可以是test测试或[]、[[]]测试，也可以是任何其他命令，test-commands用于条件测试，它只判断命令的退出状态码是否为0，为0则为true
```



实例：

```shell
#! /bin/sh
dir_d=/media/disk_d		#定义了三个变量
dir_e=/media/disk_e
dir_f=/media/disk_f

a=`ls $dir_d | wc -l`	#将ls和wl命令运行的返回值赋值给a、b、c
b=`ls $dir_e | wc -l`
c=`ls $dir_f | wc -l`
echo "检查 disk_d.."
if [ $a -eq 0 ]; then	#判断$a变量是否等于0，等于0则代表不存在
    echo "disk_d 不存在,现在开始创建..."		
    sudo  mount -t ntfs /dev/disk/by-label/software /media/disk_d	#挂载
else	
    echo "disk_d 存在"	
fi
```



## case

case用于确定的分支判断。

实例：

```shell
#! /bin/bash
case $a in
	"1")
		#执行此语句
		;;
	"2")
		#执行此语句
		;;
	*)
		#如果都不满足则执行此语句
		;;
esac


#case以case开头，以esac结尾
#在每个分支后面都要以;;结尾
```



## for循环

> 两种for循环结构：

```shell
#第一种
for i in s1 s2 s3 ...;do 语句;done

for i in s1 s2 s3;do
  语句
done

#第二种
for ((初始化；循环控制条件；变量变化));
do
语句
done
```



## while循环

```shell
while 测试条件;
do
	语句
done
```

> ​	无限循环的写法

```shell
while :
do
	命令
done

while true
do
	命令
done
```



## Shell函数

Shell函数可以当作命令一样执行，它是一个或多个命令的组合结构体。

```shell
#Shell函数的几种语法格式

function 函数名 { 命令 }
函数名() { 命令 }
function 函数名() {  命令 }
```

函数定义后，可以直接使用函数名来进行调用，同时可以向函数传递0个或多个参数

```shell
#不传递参数
函数名

#传递多个参数
函数名 参数1 参数2 参数3 ...
```

- 在函数中，那些位置变量将具有特殊的含义：
  - $1、$2、$3...：传递给函数的第一个参数保存在$1中，第二个参数保存在$2中，以此类推
  - $@、$*：保存所有参数，各参数使用空格分隔
    - 不用双引号包围时，两者没区别
    - 使用双引号包围时，$@的各个元素都被双引号包围，$*的所有元素一次性被双引号包围

**local**在函数里定义局部变量

**return**语句可以来定义函数的返回值



## 实践：分析一段Shell脚本

```shell
  1 #!/bin/bash
  2 #
  3
  4 function prepare_check() {
  5   isRoot=`id -u -n | grep root | wc -l`
  6   if [ "x$isRoot" != "x1" ]; then
  7       echo -e "[\033[31m ERROR \033[0m] Please use root to execute the installation script (请用 root 用户执行安装脚本)"
  8       exit 1
  9   fi
 10   processor=`cat /proc/cpuinfo| grep "processor"| wc -l`
 11   if [ $processor -lt 2 ]; then
 12       echo -e "[\033[31m ERROR \033[0m] The CPU is less than 2 cores (CPU 小于 2核，JumpServer 所在机器的 CPU 需要至少 2核)"
 13       exit 1
 14   fi
 15   memTotal=`cat /proc/meminfo | grep MemTotal | awk '{print $2}'`
 16   if [ $memTotal -lt 3750000 ]; then
 17       echo -e "[\033[31m ERROR \033[0m] Memory less than 4G (内存小于 4G，JumpServer 所在机器的内存需要至少 4G)"
 18       exit 1
 19   fi
 20 }
 21
 22 function install_soft() {
 23     if command -v dnf > /dev/null; then
 24       if [ "$1" == "python" ]; then
 25         dnf -q -y install python2
 26         ln -s /usr/bin/python2 /usr/bin/python
 27       else
 28         dnf -q -y install $1
 29       fi
 30     elif command -v yum > /dev/null; then
 31       yum -q -y install $1
 32     elif command -v apt > /dev/null; then
 33       apt-get -qqy install $1
 34     elif command -v zypper > /dev/null; then
 35       zypper -q -n install $1
 36     elif command -v apk > /dev/null; then
 37       apk add -q $1
 38     else
 39       echo -e "[\033[31m ERROR \033[0m] Please install it first (请先安装) $1 "
 40       exit 1
 41     fi
 42 }
 43
 44 function prepare_install() {
 45   for i in curl wget zip python; do
 46     command -v $i &>/dev/null || install_soft $i
 47   done
 48 }
 49
 50 function get_installer() {
 51   echo "download install script to /opt/jumpserver-installe (开始下载安装脚本到 /opt/jumpserver-installe)"
 52   Version=$(curl -s 'https://api.github.com/repos/jumpserver/installer/releases/latest' | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
 53   if [ ! "$Version" ]; then
 54     echo -e "[\033[31m ERROR \033[0m] Network Failed (请检查网络是否正常或尝试重新执行脚本)"
 55   fi
 56   cd /opt
 57   if [ ! -d "/opt/jumpserver-installer-$Version" ]; then
 58     wget -qO jumpserver-installer-$Version.tar.gz https://github.com/jumpserver/installer/releases/download/$Version/jumpserver-installer-$Version.tar.gz || {
 59       rm -rf /opt/jumpserver-installer-$Version.tar.gz
 60       echo -e "[\033[31m ERROR \033[0m] Failed to download jumpserver-installer (下载 jumpserver-installer 失败, 请检查网络是否正常或尝试重新执行脚本)"
 61       exit 1
 62     }
 63     tar -xf /opt/jumpserver-installer-$Version.tar.gz -C /opt || {
 64       rm -rf /opt/jumpserver-installer-$Version
 65       echo -e "[\033[31m ERROR \033[0m] Failed to unzip jumpserver-installe (解压 jumpserver-installer 失败, 请检查网络是否正常或尝试重新执行脚本)"
 66       exit 1
 67     }
 68     rm -rf /opt/jumpserver-installer-$Version.tar.gz
 69   fi
 70 }
 71
 72 function config_installer() {
 73   cd /opt/jumpserver-installer-$Version
 74   JMS_Version=$(curl -s 'https://api.github.com/repos/jumpserver/jumpserver/releases/latest' | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
 75   if [ ! "$JMS_Version" ]; then
 76     echo -e "[\033[31m ERROR \033[0m] Network Failed (请检查网络是否正常或尝试重新执行脚本)"
 77     exit 1
 78   fi
 79   sed -i "s/VERSION=.*/VERSION=$JMS_Version/g" /opt/jumpserver-installer-$Version/static.env
 80   ./jmsctl.sh install
 81 }
 82
 83 function main(){
 84   prepare_check
 85   prepare_install
 86   get_installer
 87   config_installer
 88 }
 89
 90 main              
```

> 分析

```shell
#不要被那么多代码量给吓到了，我们慢慢来分析
#先了解整个shell的框架如下，
"定义的函数不会直接运行，必须通过函数名去调用才会执行"
prepare_check() {
	#定义prepare_check函数
}

install_soft() {
	#定义install_soft函数
}

prepare_install() {
	#定义prepare_install函数
}

get_installer() {
	#定义get_installer函数
}

config_installer() {
	#定义config_installer函数
}

main() {
	#定义主函数
}

main #执行主函数

#我们了解到这段shell脚本有6个函数
#shell一开始运行并不会直接执行某个函数，只是定义了一个函数告诉系统有这么个名字为***的函数
#使用函数名进行调用，才会运行函数体里面的语句！
#我们从大概的结构看，最后一行对main主函数进行了调用，也就是运行main主函数，我们来分析以下主函数里面做了什么？

```

> 主函数

```shell
function main(){
   prepare_check	#第一步：调用prepare_check函数
   prepare_install	#第二步：调用prepare_install函数
   get_installer	#第三步：调用get_installer函数
   config_installer	#第四步：调用config_installer函数
 }

# 主函数main函数体内对4个自定义函数进行了调用，当调用prepare_check函数则程序会跳转到prepare_check函数体内执行此函数体内的代码
# 接下来我们分析prepare_check函数
```

> prepare_check函数

```shell
function prepare_check() {
  isRoot=`id -u -n | grep root | wc -l`
  #执行命令id -u -n | grep root | wc -l并将返回值赋值给isRoot变量
  #判断当前用户是否为root用户并对输出的结果计数
  #如果是root用户则为1否则为0
  
  if [ "x$isRoot" != "x1" ]; then	#条件判断，这里的$isRoot为调用变量，如果x$isRoot不等于"x1"
  	  #如果满足上面的条件则执行下面两条语句
  	  #输出：请用 root 用户执行安装脚本的提示
  	  #-e选项是激活转义字符 “\”表示转义   [\033[31m ERROR \033[0m] 表示ERROR用红色显示
      echo -e "[\033[31m ERROR \033[0m] Please use root to execute the installation script (请用 root 用户执行安装脚本)"
      #exit为退出
      exit 1
  fi
  
  processor=`cat /proc/cpuinfo| grep "processor"| wc -l`
  #执行命令cat /proc/cpuinfo | grep "processor" | wc -l 对/proc/cpuinfo文件的processor的字段进行计数并将结果赋值给processor变量
  
  if [ $processor -lt 2 ]; then		#条件判断，如果processor变量的值小于2
  	  #输出：CPU 小于 2核，JumpServer 所在机器的 CPU 需要至少 2核
      echo -e "[\033[31m ERROR \033[0m] The CPU is less than 2 cores (CPU 小于 2核，JumpServer 所在机器的 CPU 需要至少 2核)"
      #退出shell
      exit 1
  fi

  memTotal=`cat /proc/meminfo | grep MemTotal | awk '{print $2}'`	#输出/proc/meminfo文件的MemTotal字段的第二列的结果赋值给memTotal变量
  
  if [ $memTotal -lt 3750000 ]; then	#判断memTotal变量的值是否小于3750000
  	  #输出：内存小于 4G，JumpServer 所在机器的内存需要至少 4G
      echo -e "[\033[31m ERROR \033[0m] Memory less than 4G (内存小于 4G，JumpServer 所在机器的内存需要至少 4G)"
      #退出shell
      exit 1
  fi
}

#prepare_check函数主要用来判断主机的CPU、内存、用户是否都满足条件，如果不满足则退出shell脚本
#如果满足我们则执行main函数的第二条语句
#看下面
```

> 主函数

```shell
function main(){
   prepare_check	#这步已经执行完毕，主机各项配置都符合条件，接下来执行下面那条语句；如果第一个函数其中一项不满足条件，整个shell进行退出，不会再执行下面的语句了。    
   prepare_install	#第二步：调用prepare_install函数
   get_installer	#第三步：调用get_installer函数
   config_installer	#第四步：调用config_installer函数
 }
 
#下面进入prepare_install函数
```

> prepare_install函数

```shell
function prepare_install() {
  for i in curl wget zip python; do		
  #使用for循环进行迭代，for循环共会执行4次，每次的i变量的参数为curl、wget、zip、python
    command -v $i &>/dev/null || install_soft $i
    #使用command -v 命令判断i变量中的参数(也就是判断系统有没有这个命令)，如果有，则开始下一轮循环，如果没有则调用install_soft函数并传递变量i的值，并进行相应命令的安装
  done
}

#本函数用来判断Linux系统中是否存在curl、wget、zip、python这四条命令，如果都有，则本函数执行完毕！如果没有则将没有的命令通过变量i传递至install_soft函数
#接下来我们看install_soft函数
```

> install_soft函数

```shell
function install_soft() {
    if command -v dnf > /dev/null; then		#判断系统是否有dnf命令
      if [ "$1" == "python" ]; then		#判断$1为 调用函数时传递进来的参数 也就是没有前面没有安装的命令 判断是否为python
        dnf -q -y install python2		#安装python2
        ln -s /usr/bin/python2 /usr/bin/python	#对python2命令进行软链接
      else
        dnf -q -y install $1	#如果不等于python则安装$1 也就是传递进来的参数(命令)
      fi
    elif command -v yum > /dev/null; then	#判断系统是否有yum命令
      yum -q -y install $1		#安装$1变量里的命令
    elif command -v apt > /dev/null; then	#判断系统是否有apt命令
      apt-get -qqy install $1	#安装$1变量里的命令
    elif command -v zypper > /dev/null; then	#判断系统是否有zypper命令
      zypper -q -n install $1	#安装$1变量里的命令
    elif command -v apk > /dev/null; then	#判断系统是否有apk命令
      apk add -q $1		#安装$1变量里的命令
    else
      echo -e "[\033[31m ERROR \033[0m] Please install it first (请先安装) $1 "		#如果以上方法都无法进行安装，则输出：...请安装**
      #退出shell
      exit 1
    fi
}

#回到prepare_install函数
```

> prepare_install函数

```shell
function prepare_install() {
  for i in curl wget zip python; do		
    command -v $i &>/dev/null || install_soft $i
  done
}

#通过prepare_install函数和install_soft的判断和安装
#我们可以确定系统已经有curl wget zip python等4条命令了，如果正常执行完install_soft函数体里的命令(不正常情况shell已退出)，则回到main主函数
```

> 主函数

```shell
function main(){
   prepare_check	#这步已经执行完毕，主机各项配置都符合条件，接下来执行下面那条语句；如果第一个函数其中一项不满足条件，整个shell进行退出，不会再执行下面的语句了。    
   prepare_install	#这部已经执行完毕，主机必要的命令已存在
   get_installer	#第三步：调用get_installer函数
   config_installer	#第四步：调用config_installer函数
 }
 
#下面进入get_isntaller函数
```

> get_installer函数

```shell
function get_installer() {
  echo "download install script to /opt/jumpserver-installe (开始下载安装脚本到 /opt/jumpserver-installe)"
  #输出：开始下载安装脚本...
  
  Version=$(curl -s 'https://api.github.com/repos/jumpserver/installer/releases/latest' | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
  #对链接的信息进行筛选，找到"tag-name"字符的第一行，并对接下来的结果筛选，并将结果赋值给Version变量
  if [ ! "$Version" ]; then		# 取反
    echo -e "[\033[31m ERROR \033[0m] Network Failed (请检查网络是否正常或尝试重新执行脚本)"
  fi
  cd /opt	#进入/opt目录
  
  if [ ! -d "/opt/jumpserver-installer-$Version" ]; then	#判断这个目录是否存在，并取反
  	#如果不存在，则开始下载相应的文件，如果下载不成功，删除下载的文件，并提示检查网络是否正常
    wget -qO jumpserver-installer-$Version.tar.gz https://github.com/jumpserver/installer/releases/download/$Version/jumpserver-installer-$Version.tar.gz || {
      rm -rf /opt/jumpserver-installer-$Version.tar.gz
      echo -e "[\033[31m ERROR \033[0m] Failed to download jumpserver-installer (下载 jumpserver-installer 失败, 请检查>网络是否正常或尝试重新执行脚本)"
      exit 1
    }
    #	下载成功后对文件进行解压缩 || 前者不成功则进行删除相应的目录并提示：网络问题或重新执行脚本并退出
    tar -xf /opt/jumpserver-installer-$Version.tar.gz -C /opt || {
      rm -rf /opt/jumpserver-installer-$Version
      echo -e "[\033[31m ERROR \033[0m] Failed to unzip jumpserver-installe (解压 jumpserver-installer 失败, 请检查网络>是否正常或尝试重新执行脚本)"
      exit 1
    }
    #	如果成功解压后，删除下载的压缩包
    rm -rf /opt/jumpserver-installer-$Version.tar.gz
  fi
}

#成功执行完毕返回main主函数
```

> 主函数

```shell
function main(){
   prepare_check	#这步已经执行完毕，主机各项配置都符合条件，接下来执行下面那条语句；如果第一个函数其中一项不满足条件，整个shell进行退出，不会再执行下面的语句了。    
   prepare_install	#这部已经执行完毕，主机必要的命令已存在
   get_installer	#这部已经执行完毕，相应的文件已下载并解压
   config_installer	#第四步：调用config_installer函数
 }

#下面进入config_installer函数
```

> config_installer函数

```shell
function config_installer() {
  cd /opt/jumpserver-installer-$Version
  #	进入相应的目录
  
  JMS_Version=$(curl -s 'https://api.github.com/repos/jumpserver/jumpserver/releases/latest' | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
  #将链接的信息进行筛选并赋值给JMS_Version变量
  
  if [ ! "$JMS_Version" ]; then		#取反
  	#如果为假 则提示：检查网络或重新执行脚本，并退出
    echo -e "[\033[31m ERROR \033[0m] Network Failed (请检查网络是否正常或尝试重新执行脚本)"
    exit 1
  fi
  
  sed -i "s/VERSION=.*/VERSION=$JMS_Version/g" /opt/jumpserver-installer-$Version/static.env
  #在/opt/jumpserver-installer-$Version/static.env文件中插入s/VERSION=.*/VERSION=$JMS_Version/g参数
  ./jmsctl.sh install
  #运行脚本
}

#config_installer函数执行完毕，返回主函数main
```

> 主函数

```shell
function main(){
   prepare_check	#这步已经执行完毕，主机各项配置都符合条件，接下来执行下面那条语句；如果第一个函数其中一项不满足条件，整个shell进行退出，不会再执行下面的语句了。    
   prepare_install	#这部已经执行完毕，主机必要的命令已存在
   get_installer	#这部已经执行完毕，相应的文件已下载并解压
   config_installer	#这部已经执行完毕，已配置完毕相应的配置并运行jumpserver
 }
 
 
#---------------------- 至此shell分析结束，如果有不到位的请留言提出qwq或私信我--------------------
#
# 除了某些命令可能不是很了解，其实看完前面的基础和掌握Linux基础命令，对上面的shell也能大致的进行分析了
#
# 接下来就是多多练习了~
#
```



# 记一次MySQL-Shell学习

## 日志记录函数

```shell
mysql_log() {
        local type="$1"; shift
        local text="$*"; if [ "$#" -eq 0 ]; then text="$(cat)"; fi
        local dt; dt="$(date --rfc-3339=seconds)"
        printf '%s [%s] [Entrypoint]: %s\n' "$dt" "$type" "$text"
}
mysql_note() {
        mysql_log Note "$@"
}
mysql_warn() {
        mysql_log Warn "$@" >&2
}
mysql_error() {
        mysql_log ERROR "$@" >&2
        exit 1
}

```

## 文件变量函数

```shell
file_env() {
        local var="$1"
        local fileVar="${var}_FILE"
        local def="${2:-}"
        if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
                mysql_error "Both $var and $fileVar are set (but are exclusive)"
        fi
        local val="$def"
        if [ "${!var:-}" ]; then
                val="${!var}"
        elif [ "${!fileVar:-}" ]; then
                val="$(< "${!fileVar}")"
        fi
        export "$var"="$val"
        unset "$fileVar"
}
```

## 检测文件本身函数

```shell
_is_sourced() {
        [ "${#FUNCNAME[@]}" -ge 2 ] \
                && [ "${FUNCNAME[0]}" = '_is_sourced' ] \
                && [ "${FUNCNAME[1]}" = 'source' ]
}
```

## 进程初始化文件函数

```shell
docker_process_init_files() {
        mysql=( docker_process_sql )

        echo
        local f
        for f; do
                case "$f" in
                        *.sh)
                                if [ -x "$f" ]; then
                                        mysql_note "$0: running $f"
                                        "$f"
                                else
                                        mysql_note "$0: sourcing $f"
                                        . "$f"
                                fi
                                ;;
                        *.sql)     mysql_note "$0: running $f"; docker_process_sql < "$f"; echo ;;
                        *.sql.bz2) mysql_note "$0: running $f"; bunzip2 -c "$f" | docker_process_sql; echo ;;
                        *.sql.gz)  mysql_note "$0: running $f"; gunzip -c "$f" | docker_process_sql; echo ;;
                        *.sql.xz)  mysql_note "$0: running $f"; xzcat "$f" | docker_process_sql; echo ;;
                        *.sql.zst) mysql_note "$0: running $f"; zstd -dc "$f" | docker_process_sql; echo ;;
                        *)         mysql_warn "$0: ignoring $f" ;;
                esac
                echo
        done
}
```



## 检测配置函数

```shell
mysql_check_config() {
        local toRun=( "$@" "${_verboseHelpArgs[@]}" ) errors
        if ! errors="$("${toRun[@]}" 2>&1 >/dev/null)"; then
                mysql_error $'mysqld failed while attempting to check config\n\tcommand was: '"${toRun[*]}"$'\n\t'"$errors"
        fi
}
```

## 获取配置函数

```shell
mysql_get_config() {
        local conf="$1"; shift
        "$@" "${_verboseHelpArgs[@]}" 2>/dev/null \
                | awk -v conf="$conf" '$1 == conf && /^[^ \t]/ { sub(/^[^ \t]+[ \t]+/, ""); print; exit }'
}
```

## 套接字函数

```shell
mysql_socket_fix() {
        local defaultSocket
        defaultSocket="$(mysql_get_config 'socket' mysqld --no-defaults)"
        if [ "$defaultSocket" != "$SOCKET" ]; then
                ln -sfTv "$SOCKET" "$defaultSocket" || :
        fi
}
```

## 临时启动服务函数

```shell
docker_temp_server_start() {
        if [ "${MYSQL_MAJOR}" = '5.7' ]; then
                "$@" --skip-networking --default-time-zone=SYSTEM --socket="${SOCKET}" &
                mysql_note "Waiting for server startup"
                local i
                for i in {30..0}; do
                        # only use the root password if the database has already been initialized
                        # so that it won't try to fill in a password file when it hasn't been set yet
                        extraArgs=()
                        if [ -z "$DATABASE_ALREADY_EXISTS" ]; then
                                extraArgs+=( '--dont-use-mysql-root-password' )
                        fi
                        if docker_process_sql "${extraArgs[@]}" --database=mysql <<<'SELECT 1' &> /dev/null; then
                                break
                        fi
                        sleep 1
                done
                if [ "$i" = 0 ]; then
                        mysql_error "Unable to start server."
                fi
        else
                # For 5.7+ the server is ready for use as soon as startup command unblocks
                if ! "$@" --daemonize --skip-networking --default-time-zone=SYSTEM --socket="${SOCKET}"; then
                        mysql_error "Unable to start server."
                fi
        fi
}
```

## 停止临时服务函数

```shell
docker_temp_server_stop() {
        if ! mysqladmin --defaults-extra-file=<( _mysql_passfile ) shutdown -uroot --socket="${SOCKET}"; then
                mysql_error "Unable to shut down server."
        fi
}
```

## 检查密码函数

```shell
docker_verify_minimum_env() {
        if [ -z "$MYSQL_ROOT_PASSWORD" -a -z "$MYSQL_ALLOW_EMPTY_PASSWORD" -a -z "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
                mysql_error << -'EOF'
                        Database is uninitialized and password option is not specified
                            You need to specify one of the following as an environment variable:
                            - MYSQL_ROOT_PASSWORD
                            - MYSQL_ALLOW_EMPTY_PASSWORD
                            - MYSQL_RANDOM_ROOT_PASSWORD
                
        fi

        # This will prevent the CREATE USER from failing (and thus exiting with a half-initialized database)
        if [ "$MYSQL_USER" = 'root' ]; then
                mysql_error << -'EOF'
                        MYSQL_USER="root", MYSQL_USER and MYSQL_PASSWORD are for configuring a regular user and cannot be used for the root user
                            Remove MYSQL_USER="root" and use one of the following to control the root user password:
                            - MYSQL_ROOT_PASSWORD
                            - MYSQL_ALLOW_EMPTY_PASSWORD
                            - MYSQL_RANDOM_ROOT_PASSWORD
                EOF
        fi

        # warn when missing one of MYSQL_USER or MYSQL_PASSWORD
        if [ -n "$MYSQL_USER" ] && [ -z "$MYSQL_PASSWORD" ]; then
                mysql_warn 'MYSQL_USER specified, but missing MYSQL_PASSWORD; MYSQL_USER will not be created'
        elif [ -z "$MYSQL_USER" ] && [ -n "$MYSQL_PASSWORD" ]; then
                mysql_warn 'MYSQL_PASSWORD specified, but missing MYSQL_USER; MYSQL_PASSWORD will be ignored'
        fi
}
```

## 创建数据库文件函数

```shell
docker_create_db_directories() {
        local user; user="$(id -u)"

        local -A dirs=( ["$DATADIR"]=1 )
        local dir
        dir="$(dirname "$SOCKET")"
        dirs["$dir"]=1

        # "datadir" and "socket" are already handled above (since they were already queried previously)
        local conf
        for conf in \
                general-log-file \
                keyring_file_data \
                pid-file \
                secure-file-priv \
                slow-query-log-file \
        ; do
                dir="$(mysql_get_config "$conf" "$@")"

                # skip empty values
                if [ -z "$dir" ] || [ "$dir" = 'NULL' ]; then
                        continue
                fi
                case "$conf" in
                        secure-file-priv)
                                # already points at a directory
                                ;;
                        *)
                                # other config options point at a file, but we need the directory
                                dir="$(dirname "$dir")"
                                ;;
                esac

                dirs["$dir"]=1
        done

        mkdir -p "${!dirs[@]}"

        if [ "$user" = "0" ]; then
                # this will cause less disk access than `chown -R`
                find "${!dirs[@]}" \! -user mysql -exec chown --no-dereference mysql '{}' +
        fi
}
```

## 初始化数据库目录函数

```shell
docker_init_database_dir() {
        mysql_note "Initializing database files"
        "$@" --initialize-insecure --default-time-zone=SYSTEM
        mysql_note "Database files initialized"
}
```

## 设置环境变量

```shell
docker_setup_env() {
        # Get config
        declare -g DATADIR SOCKET
        DATADIR="$(mysql_get_config 'datadir' "$@")"
        SOCKET="$(mysql_get_config 'socket' "$@")"

        # Initialize values that might be stored in a file
        file_env 'MYSQL_ROOT_HOST' '%'
        file_env 'MYSQL_DATABASE'
        file_env 'MYSQL_USER'
        file_env 'MYSQL_PASSWORD'
        file_env 'MYSQL_ROOT_PASSWORD'

        declare -g DATABASE_ALREADY_EXISTS
        if [ -d "$DATADIR/mysql" ]; then
                DATABASE_ALREADY_EXISTS='true'
        fi
}
```

## 执行SQL脚本函数

```shell
docker_process_sql() {
        passfileArgs=()
        if [ '--dont-use-mysql-root-password' = "$1" ]; then
                passfileArgs+=( "$1" )
                shift
        fi
        # args sent in can override this db, since they will be later in the command
        if [ -n "$MYSQL_DATABASE" ]; then
                set -- --database="$MYSQL_DATABASE" "$@"
        fi

        mysql --defaults-extra-file=<( _mysql_passfile "${passfileArgs[@]}") --protocol=socket -uroot -hlocalhost --socket="${SOCKET}" --comments "$@"
}
```

## 初始化数据库函数

```shell
docker_setup_db() {
        # Load timezone info into database
        if [ -z "$MYSQL_INITDB_SKIP_TZINFO" ]; then
                # sed is for https://bugs.mysql.com/bug.php?id=20545
                mysql_tzinfo_to_sql /usr/share/zoneinfo \
                        | sed 's/Local time zone must be set--see zic manual page/FCTY/' \
                        | docker_process_sql --dont-use-mysql-root-password --database=mysql
                        # tell docker_process_sql to not use MYSQL_ROOT_PASSWORD since it is not set yet
        fi
        # Generate random root password
        if [ -n "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
                MYSQL_ROOT_PASSWORD="$(openssl rand -base64 24)"; export MYSQL_ROOT_PASSWORD
                mysql_note "GENERATED ROOT PASSWORD: $MYSQL_ROOT_PASSWORD"
        fi
        # Sets root password and creates root users for non-localhost hosts
        local rootCreate=
        # default root to listen for connections from anywhere
        if [ -n "$MYSQL_ROOT_HOST" ] && [ "$MYSQL_ROOT_HOST" != 'localhost' ]; then
                # no, we don't care if read finds a terminating character in this heredoc
                # https://unix.stackexchange.com/questions/265149/why-is-set-o-errexit-breaking-this-read-heredoc-expression/265151#265151
                ## read -r -d '' rootCreate <<-EOSQL || true
                        CREATE USER 'root'@'${MYSQL_ROOT_HOST}' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
                        GRANT ALL ON *.* TO 'root'@'${MYSQL_ROOT_HOST}' WITH GRANT OPTION ;
                EOSQL
        fi

        local passwordSet=
        # no, we don't care if read finds a terminating character in this heredoc (see above)
        #read -r -d '' passwordSet <<-EOSQL || true
                ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
        EOSQL

        # tell docker_process_sql to not use MYSQL_ROOT_PASSWORD since it is just now being set
        docker_process_sql --dont-use-mysql-root-password --database=mysql <<-EOSQL
                -- What's done in this file shouldn't be replicated
                --  or products like mysql-fabric won't work
                SET @@SESSION.SQL_LOG_BIN=0;

                ${passwordSet}
                GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION ;
                FLUSH PRIVILEGES ;
                ${rootCreate}
                DROP DATABASE IF EXISTS test ;
        EOSQL

        # Creates a custom database and user if specified
        if [ -n "$MYSQL_DATABASE" ]; then
                mysql_note "Creating database ${MYSQL_DATABASE}"
                docker_process_sql --database=mysql <<<"CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;"
        fi

        if [ -n "$MYSQL_USER" ] && [ -n "$MYSQL_PASSWORD" ]; then
                mysql_note "Creating user ${MYSQL_USER}"
                docker_process_sql --database=mysql <<<"CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' ;"

                if [ -n "$MYSQL_DATABASE" ]; then
                        mysql_note "Giving user ${MYSQL_USER} access to schema ${MYSQL_DATABASE}"
                        docker_process_sql --database=mysql <<<"GRANT ALL ON \`${MYSQL_DATABASE//_/\\_}\`.* TO '$MYSQL_USER'@'%' ;"
                fi
        fi
}
```

## 回显密码函数

```shell
_mysql_passfile() {
        # echo the password to the "file" the client uses
        # the client command will use process substitution to create a file on the fly
        # ie: --defaults-extra-file=<( _mysql_passfile )
        if [ '--dont-use-mysql-root-password' != "$1" ] && [ -n "$MYSQL_ROOT_PASSWORD" ]; then
                ##cat <<-EOF
                        [client]
                        password="${MYSQL_ROOT_PASSWORD}"
                EOF
        fi
}
```

## 标志ROOT过期函数

```shell
mysql_expire_root_user() {
        if [ -n "$MYSQL_ONETIME_PASSWORD" ]; then
                ##docker_process_sql --database=mysql <<-EOSQL
                        ALTER USER 'root'@'%' PASSWORD EXPIRE;
                EOSQL
        fi
}
```

## 检查是否包含导进程停止的参数函数

```shell
_mysql_want_help() {
        local arg
        for arg; do
                case "$arg" in
                        -'?'|--help|--print-defaults|-V|--version)
                                return 0
                                ;;
                esac
        done
        return 1
}
```

## 主函数

```shell
_main() {
        # if command starts with an option, prepend mysqld
        if [ "${1:0:1}" = '-' ]; then
                set -- mysqld "$@"
        fi

        # skip setup if they aren't running mysqld or want an option that stops mysqld
        if [ "$1" = 'mysqld' ] && ! _mysql_want_help "$@"; then
                mysql_note "Entrypoint script for MySQL Server ${MYSQL_VERSION} started."

                mysql_check_config "$@"
                # Load various environment variables
                docker_setup_env "$@"
                docker_create_db_directories "$@"

                # If container is started as root user, restart as dedicated mysql user
                if [ "$(id -u)" = "0" ]; then
                        mysql_note "Switching to dedicated user 'mysql'"
                        exec gosu mysql "$BASH_SOURCE" "$@"
                fi

                # there's no database, so it needs to be initialized
                if [ -z "$DATABASE_ALREADY_EXISTS" ]; then
                        docker_verify_minimum_env

                        # check dir permissions to reduce likelihood of half-initialized database
                        ls /docker-entrypoint-initdb.d/ > /dev/null

                        docker_init_database_dir "$@"

                        mysql_note "Starting temporary server"
                        docker_temp_server_start "$@"
                        mysql_note "Temporary server started."

                        mysql_socket_fix
                        docker_setup_db
                        docker_process_init_files /docker-entrypoint-initdb.d/*

                        mysql_expire_root_user

                        mysql_note "Stopping temporary server"
                        docker_temp_server_stop
                        mysql_note "Temporary server stopped"

                        echo
                        mysql_note "MySQL init process done. Ready for start up."
                        echo
                else
                        mysql_socket_fix
                fi
        fi
        exec "$@"
}
```

## 入口

```shell
if ! _is_sourced; then
        _main "$@"
fi


```



# 分析脚本

## 判断脚本的运行方式

```shell
if ! _is_sourced; then			# _is_sourced为假则开始运行主函数
        _main "$@"   			# 进入主函数并携带所有的参数
fi
```

```shell
_is_sourced() {
        [ "${#FUNCNAME[@]}" -ge 2 ] \
                && [ "${FUNCNAME[0]}" = '_is_sourced' ] \
                && [ "${FUNCNAME[1]}" = 'source' ]
}

$FUNCNAME表示函数的名字，它是一个数组变量，其中包含了整个调用链上所有的函数的名字，故变量${FUNCNAME[0]}代表shell脚本当前正在执行的函数的名字，而变量${FUNCNAME[1]}则代表调用函数${FUNCNAME[0]}的函数的名字，依此类推。

如果是./执行则函数为假执行_main函数，如果是source则为真不执行_main
```

## 进入主函数

```shell
_main() {
        # 判断CMD提供的命令是否是mysqld -xxx -xxx的形式   ${1:0:1}即第二个字符串的第一个字符是否是-；如果是就执行CMD给定的参数
        if [ "${1:0:1}" = '-' ]; then   
                set -- mysqld "$@"			# $@表示所有参数  
                # set -- 后无内容，将当前 shell 脚本的参数置空，$1 $? $@ 等都为空。
				# set -- 后有内容，当前 shell 脚本的参数被替换为 set -- 后的内容，$1 $? $@ 等相应地被改变。
        fi
   
        # 判断第一个参数是否为mysqld并且将所有参数传递给_mysql_want_help函数,跳到_mysql_want_help函数
        if [ "$1" = 'mysqld' ] && ! _mysql_want_help "$@"; then    
                mysql_note "Entrypoint script for MySQL Server ${MYSQL_VERSION} started."
				# 将信息传到日志函数
				
                mysql_check_config "$@"
                # 检查配置
                
                docker_setup_env "$@"
                # 将传入的值作为环境变量
                
                docker_create_db_directories "$@"
				# 创建数据库目录

                # 判断用户是否为root得切换mysql用户启动
                if [ "$(id -u)" = "0" ]; then
                        mysql_note "Switching to dedicated user 'mysql'"
                        exec gosu mysql "$BASH_SOURCE" "$@"
                fi

                # 在环境变量函数中就判断数据目录是否存在   -z判断变量是否为空，如果是空就执行下面的初始化过程
                if [ -z "$DATABASE_ALREADY_EXISTS" ]; then			
                        docker_verify_minimum_env

                        # check dir permissions to reduce likelihood of half-initialized database
                        ls /docker-entrypoint-initdb.d/ > /dev/null

                        docker_init_database_dir "$@"

                        mysql_note "Starting temporary server"
                        docker_temp_server_start "$@"
                        mysql_note "Temporary server started."

                        mysql_socket_fix
                        docker_setup_db
                        docker_process_init_files /docker-entrypoint-initdb.d/*

                        mysql_expire_root_user

                        mysql_note "Stopping temporary server"
                        docker_temp_server_stop
                        mysql_note "Temporary server stopped"

                        echo
                        mysql_note "MySQL init process done. Ready for start up."
                        echo
                else
                        mysql_socket_fix
                fi
        fi
        exec "$@"
}
```

## 检查是否包含导进程停止的参数函数

```shell
_mysql_want_help() {
        local arg		# 将传递进来的变量作为局部变量arg
        for arg; do
                case "$arg" in		# 判断变量(参数)是否包含如下选项是这返回0否则返回1
                        -'?'|--help|--print-defaults|-V|--version)
                                return 0
                                ;;
                esac
        done
        return 1
}
```

## 记录日志函数

```shell
mysql_note() {
        mysql_log Note "$@"			# 将传入的值进行记录
}
```

## 检查配置函数

```shell
mysql_check_config() {
        local toRun=( "$@" "${_verboseHelpArgs[@]}" ) errors
        if ! errors="$("${toRun[@]}" 2>&1 >/dev/null)"; then
                mysql_error $'mysqld failed while attempting to check config\n\tcommand was: '"${toRun[*]}"$'\n\t'"$errors"
        fi
}
```

## 设置环境变量函数

```shell
docker_setup_env() {
        # Get config
        declare -g DATADIR SOCKET
        DATADIR="$(mysql_get_config 'datadir' "$@")"
        SOCKET="$(mysql_get_config 'socket' "$@")"

        # Initialize values that might be stored in a file
        file_env 'MYSQL_ROOT_HOST' '%'
        file_env 'MYSQL_DATABASE'
        file_env 'MYSQL_USER'
        file_env 'MYSQL_PASSWORD'
        file_env 'MYSQL_ROOT_PASSWORD'

        declare -g DATABASE_ALREADY_EXISTS
        if [ -d "$DATADIR/mysql" ]; then			# 判断数据目录是否存在
                DATABASE_ALREADY_EXISTS='true'
        fi
}
```

## 创建数据库目录函数

```shell
docker_create_db_directories() {
        local user; user="$(id -u)"

        local -A dirs=( ["$DATADIR"]=1 )
        local dir
        dir="$(dirname "$SOCKET")"
        dirs["$dir"]=1

        # "datadir" and "socket" are already handled above (since they were already queried previously)
        local conf
        for conf in \
                general-log-file \
                keyring_file_data \
                pid-file \
                secure-file-priv \
                slow-query-log-file \
        ; do
                dir="$(mysql_get_config "$conf" "$@")"

                # skip empty values
                if [ -z "$dir" ] || [ "$dir" = 'NULL' ]; then
                        continue
                fi
                case "$conf" in
                        secure-file-priv)
                                # already points at a directory
                                ;;
                        *)
                                # other config options point at a file, but we need the directory
                                dir="$(dirname "$dir")"
                                ;;
                esac

                dirs["$dir"]=1
        done

        mkdir -p "${!dirs[@]}"

        if [ "$user" = "0" ]; then
                # this will cause less disk access than `chown -R`
                find "${!dirs[@]}" \! -user mysql -exec chown --no-dereference mysql '{}' +
        fi
}
```
