---
title: linux-ldd命令
tags:
  - Linux
  - ldd
categories: Linux
cover: img/fengmian/linux.png
abbrlink: e8b44a7a
date: 2023-03-14 16:57:16
---
# ldd命令

`ldd`是一个Linux/Unix命令，它用于打印一个可执行文件或共享库所依赖的动态链接库（shared libraries）列表。这些动态链接库在程序运行时被加载。

`ldd`命令的语法如下：

```
cssCopy code
ldd [options] file
```

其中，`file`是要检查的可执行文件或共享库的路径。

常见的选项包括：

- `-v`: 打印`ldd`命令的详细输出，包括搜索路径和版本信息等；
- `-u`: 只打印未满足依赖关系的库的名称；
- `-d`: 打印依赖库的调试信息，包括库的加载地址和符号表等。

示例：

假设我们要查看一个可执行文件`/usr/local/bin/myprogram`所依赖的库，可以执行以下命令：

```shell
ldd /usr/local/bin/myprogram
```

