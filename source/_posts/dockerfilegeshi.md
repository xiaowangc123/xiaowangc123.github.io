---
title: Dockerfile-格式
tags: Docker
cover: img/fengmian/docker.jpeg
categories: 容器
abbrlink: 7f64b8d4
date: 2023-12-26 11:04:37
---
# Dockerfile格式

```dockerfile
FROM openjdk:8-jdk-alpine

WORKDIR /work-dir

ARG JAR_FILE=/path/app.jar

COPY ${JAR_FILE} app.jar

EXPOSE 8080

ENV TZ=Asia/Shanghai JAVA_OPTS="-Xms128m -Xmx256m -Djava.security.egd=file:/dev/./urandom

CMD sleep 3; java $JAVA_OPTS -jar app.jar
```