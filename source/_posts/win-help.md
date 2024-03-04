---
title: 记一次Windows10故障处理
tags:
  - Windows更新
  - Windows故障
categories: Windows
cover: img/fengmian/windows.jpeg
abbrlink: 451f3905
date: 2023-03-17 11:52:45
---
# 记一次Windows10故障处理

在更新完系统补丁后重启，发现系统部分组合键无法使用，微软输入法打字但是不出现文字提示框并且开始菜单栏无法使用(其他问题还没验证)

sfc命令是一个非常有用的命令行工具，它的全程是system file checker(系统文件检查器)，主要用于扫描并修复操作系统中的损坏和丢失的系统文件，以确保系统的稳定性和安全性。

**常用命令**

`sfc /scannow`

这个命令将扫描整个系统并检查系统文件的完整性。如果有任何问题，它将自动修复文件，从备份中还原缺失或已损坏的文件

`sfc /verifyonly`

这个命令将扫描整个系统并检查系统文件的完整性，但不会自动修复



SFC命令主要用于扫描和修复系统文件的完整性，而DISM命令则是更高级的系统维护工具，它可以用于管理和维护Windows映像，例如更新、添加、删除、安装Windows组件和驱动程序等。SFC命令是从WindowsXP开始支持的，并支持所有的Windows版本。而DISM命令只在Windows7及其更高版本的Windows操作系统中支持

`dism /online /cleanup-image /scanhealth` 

该命令用于扫描当前在线 Windows 映像文件中的所有组件，检查其是否存在损坏或错误，并返回相关信息。 

`dism /online /cleanup-image /checkhealth` 

该命令用于检查当前在线 Windows 映像文件的健康状态。如果出现问题，它会返回错误信息，如果一切正常，则返回成功信息。 

`dism /online /cleanup-image /restorehealth` 

该命令用于还原当前在线 Windows 映像文件中的所有损坏或错误的组件。该命令需要 Internet 连接，因为它会下载缺少的组件。

