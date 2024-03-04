---
title: AWT is not properly configured on this server.
abbrlink: 4d672e21
date: 2022-11-08 10:42:03
cover: img/fengmian/gitlab.jpeg
categories: Gitlab
tags:
  - Gitlab
---

`错误`：AWT is not properly configured on this server.
```shell
yum -y install fontconfig
```

`错误`：
Nov 08, 2022 10:29:14 AM executable.Main verifyJavaVersion
SEVERE: Running with Java class version 52, which is older than the Minimum required version 55. See https://jenkins.io/redirect/java-support/
java.lang.UnsupportedClassVersionError: 52.0
        at executable.Main.verifyJavaVersion(Main.java:145)
        at executable.Main.main(Main.java:109)

Jenkins requires Java versions [17, 11] but you are running with Java 1.8 from /usr/java/jdk1.8.0_351-amd64/jre
java.lang.UnsupportedClassVersionError: 52.0
        at executable.Main.verifyJavaVersion(Main.java:145)
        at executable.Main.main(Main.java:109)

```shell
使用java11/java17启动
```
