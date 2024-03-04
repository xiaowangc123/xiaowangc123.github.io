---
title: Linux信号
tags:
  - Linux
  - Shell
categories: Linux
cover: img/fengmian/linux.png
abbrlink: '99134621'
date: 2023-07-14 16:36:41
---
# Linux信号

Linux信号是一种进程间通信机制，一般由用户、系统、进程产生，用于通知进程某个状态的改变或者系统异常。现在的Linux系统中有几十种信号的类型，每个信号都有一个数字和一个名字。可以通过命令`trap -l`或`kill -l`来查看系统中所有的信号。注意同样的信号名在不通的平台上可能对应不同的数字，跨平台脚本推荐使用信号名。

Bash的内建命令`kill`可以发送任意指定的信号到某个进程。如果没有指定参数，kill命令默认发送信号15 SIGTERM，在收到这个信号以后，进程会终止执行。

通过使用组合键`Ctrl`+`C`结束前台进程是发送了`INT`信号给前台进程，退出状态码为相应的信号数字再加上`128`;组合键`Ctrl`+`Z`会发送TSTP信号，即terminal stop挂起前台运行的进程，所以进程会被暂停，在命令行中执行jobs可以查看进程的状态为Stopped，通过fg命令可以恢复执行；而组合键`Ctrl`+`\`发送的是QUIT信号，前台进程在收到QUIT信号后同样会被终止，可视作加强版`Ctrl`+`C`

# 信号处理

在运行Shell的过程中可能会创建临时文件，这些文件在脚本运行的过程中使用，一般情况下在脚本运行完毕后清除这些临时文件，只要在脚本退出时使用`rm`命令删除临时文件即可，但是如果在脚本运行的过程中，用户通过组合键或者`kill`命令发送TERM信号终止脚本的运行，那么临时文件就不会被删除。可以使用如下方法，使脚本在接收到用户的信号时也可以自动删除这些临时文件，通过自定义的回调函数来执行这些操作，注册信号的回调函数需要使用`trap`命令来实现。

```shell
#!/bin/bash
TMP_FILE=tmpfile.$$

Clean_TMP(){
	if [ -f"$TMP_FILE" ];then
	   echo "Clean TMP_FILE..."
	   rm -rf $TMP_FILE
	   echo "Done."
	fi
	
	exit 2
}

trap Clean_TMP 1 2 3 15

for i in {1..10};
do
	echo "number $i" >> $TMP_FILE
	sleep 1
done
```

当然也可以单独为某些信号设置定义一个函数

```shell
#!/bin/bash
TMP_FILE=tmpfile.$$

Clean_TMP(){
	if [ -f"$TMP_FILE" ];then
	   echo "Clean TMP_FILE..."
	   rm -rf $TMP_FILE
	   echo "Done."
	fi
	
	exit 1
}

Hello(){
	echo "Hello,xiaowangc"
	if [ -f"$TMP_FILE" ];then
	   echo "Clean TMP_FILE..."
	   rm -rf $TMP_FILE
	   echo "Done."
	fi
	exit 1
}

trap Clean_TMP 2 3 15
trap Hello 1


for i in {1..10};
do
	echo "number $i" >> $TMP_FILE
	sleep 1
done
```



# 忽略信号

当我们的脚本需要执行较长时间才能完成时，用户可以通过组合键来终止脚本，但是如果脚本在执行一些关键性的操作，并不希望被打算时，例如备份或恢复数据等操作时，就需要屏蔽用户使用`Ctrl`+`C`或者`kill`命令发送的INT信号

```shell
#!/bin/bash

trap '' INT		# 三种方式都可 trap '' 2 / trap : 2

for i in {1..10};
do
	echo "number $i"
	sleep 1
done
```

当关键操作结束后，可以允许用户通过组合键来终止脚本

```shell
#!/bin/bash

trap '' 2

for i in {1..10};
do
	echo "number $i"
	sleep 1
done

trap 2

echo "可以使用Ctrl + C结束脚本"

for i in {1..10};
do
	echo "xiaowangc $i"
	sleep 1
done
```

