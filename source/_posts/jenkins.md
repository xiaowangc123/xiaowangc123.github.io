---
title: Jenkins-安装
tags:
  - Jenkins
  - ci&cd
cover: img/fengmian/jenkins.jpg
categories: Jenkins
abbrlink: 705f63c3
date: 2022-07-05 23:10:32
---
# 概述

Jenkins是一款开源 CI&CD 软件，用于自动化各种任务，包括构建、测试和部署软件。

Jenkins 支持各种运行方式，可通过系统包、Docker 或者通过一个独立的 Java 程序。

# 系统要求

最低推荐配置：

- 256MB可用内存
- 1GB可用磁盘空间

小团队推荐配置：

- 1GB+可用内存
- 50GB+可用磁盘空间

软件配置：

- Java8

# 安装Jenkins

Jenkins通常作为一个独立的应用程序在其自己的流程中运行， 内置Java servlet 容器/应用程序服务器（Jetty）

Jenkins也可以运行在不同的Java servlet容器(（如Apache Tomcat 或 GlassFish）)中作为servlet运行

## 安装环境

1. 软件包方式安装

   ```shell
   dnf -y install java
   ```

2. 二进制方式安装

   官网：https://www.oracle.com/java/technologies/downloads/，需要oracle账号

   Jre和jdk环境都可，这里我们使用jdk的二进制包进行安装

   ![image-20220705204344220](image-20220705204344220.png)

   下载好之后将压缩包上传至服务器

   ```shell
   [root@jenkins ~]# ls
   anaconda-ks.cfg  jdk-8u321-linux-x64.tar.gz
   [root@jenkins ~]# tar xf jdk-8u321-linux-x64.tar.gz		#解压
   [root@jenkins ~]# mv jdk1.8.0_321 /usr/local/
   [root@jenkins ~]# export JAVA_HOME=/usr/local/jdk1.8.0_321
   [root@jenkins ~]# export CLASSPATH=$JAVA_HOME/lib:$JAVA_HOME/jre/lib
   [root@jenkins ~]# export PATH=$PATH:$JAVA_HOME/bin:$JAVA_HOME/jre/bin
   [root@jenkins ~]# java -version
   java version "1.8.0_321"
   Java(TM) SE Runtime Environment (build 1.8.0_321-b07)
   Java HotSpot(TM) 64-Bit Server VM (build 25.321-b07, mixed mode)
   ```

## 下载安装Jenkins

官网：https://www.jenkins.io/zh/download/

下载好之后上传至服务器

```shell
[root@jenkins ~]# ls
anaconda-ks.cfg  jenkins.war
[root@jenkins ~]# nohup java -jar jenkins.war --httpPort=80 > jenkins.log 2>&1 &
```

## 访问测试

![image-20220705211926441](image-20220705211926441.png)

