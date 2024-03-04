---
title: Docker多阶段镜像构建
tags: Docker
cover: img/fengmian/docker.jpeg
categories: 容器
abbrlink: '12166148'
date: 2023-07-20 10:40:41
---
# Docker多阶段镜像构建

使用多阶段构建的主要有两个原因：

- 它允许并行构建步骤，使构建管道更快、更高效
- 它允许创建占用空间较小的最终镜像，仅包含运行程序所需的内容

在Dockerfile中，构建阶段由`FROM`指令表示，只有一个`FROM`都是一个构建阶段，这意味着最终的镜像因用于编译程序的资源而变得臃肿

![20230720093652](20230720093652.png)

在未使用多阶段构建之前，本人的博客镜像大小一直是`1.31GB`，为了图方便同时也在node基础镜像中安装了nginx，主要是为了在构建镜像之后直接就能运行。但采用了多阶段镜像构建之后镜像大小减少了`90%+`，最终大小为`72MB`

**原Dockerfile**

```dockerfile
FROM node:18
MAINTAINER xiaowangc<780312916@qq.com>
WORKDIR /app
COPY package*.json ./
RUN apt update && apt -y install nginx
RUN npm install && npm install hexo-cli -g
COPY . .
RUN hexo g
RUN cp -R public/* /var/www/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

**采用多阶段后的Dockerfile**

```dockerfile
FROM node:18 AS builder
MAINTAINER xiaowangc<780312916@qq.com>
ENV TZ=Asia/Shanghai
WORKDIR /app
COPY . .
RUN npm install && \
    npm install hexo-cli -g && \
    hexo g && \
    cp google319b15f7fe4c4ac3.html public/ && \
    cp sogousiteverification.txt public/

FROM nginx:1.24.0-alpine
MAINTAINER xiaowangc<780312916@qq.com>
ENV TZ=Asia/Shanghai
COPY --from=builder /app/public/ /usr/share/nginx/html/
```

同时将多个RUN合并成一个来减少镜像的层级，并设置了**时区的环境变量**，最终的镜像采用更小的的`nginx:1.24.0-alpine`版本，现在构建镜像后通过查看镜像的体积已经比原来的有所减小了。因为镜像不再包含node基础环境和博客项目文件，只有通过hexo生成好的静态文件。

## 阶段命名

默认情况下，阶段没有命名，我们可以通过它们的整数来引用它们，第一条`FROM`指令从0开始。但是也可以使用`AS <name>`通过在指令中来命名我们的阶段`FROM`,使用命名阶段来标识，无需在乎Dockerfile中指令的排序。

```dockerfile
FROM golang:1.16 AS builder
WORKDIR /go/src/github.com/alexellis/href-counter/
RUN go get -d -v golang.org/x/net/html  
COPY app.go ./
RUN CGO_ENABLED=0 go build -a -installsuffix cgo -o app .

FROM alpine:latest  
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /go/src/github.com/alexellis/href-counter/app ./
# 意味COPY来自builder阶段的/go/src/github.com/alexellis/href-counter/app文件到当前目录
CMD ["./app"]  
```

当上面的Dockerfile运行构建完毕之后除了`alpine:latest`保留，`golang:1.16`阶段的相关数据包括镜像都会被丢弃。

## 使用外部镜像的文件

在使用多阶段构建使，不仅限于从之前的Dockerfile中的阶段进行复制，可以使用`COPY --from`指令从单独的镜像进行复制，可以使用本地镜像、本地或者Docker Hub仓库上可用的镜像货镜像ID

```dockerfile
COPY --from=nginx:latest /etc/nginx/nginx.conf ./
```

## 挂载缓存

缓存允许要在构建期间使用的持久化。持久缓存有助于加快构建步骤，尤其是涉及使用包管理器安装包的步骤。例如构建一个springcloud项目每次在运行mvn构建都需要从在线仓库拉取依赖。第一次构建完成之后下载的依赖就会被删除，再次构建时就需要重新下载，如果使用持久化下一次构建只需要下载新的依赖或更改的依赖。

```docker
FROM golang:1.20-alpine AS base
WORKDIR /src
COPY go.mod go.sum .
RUN --mount=type=cache,target=/go/pkg/mod/ \
    go mod download -x
COPY . .

FROM base AS build-client
RUN --mount=type=cache,target=/go/pkg/mod/ \
    go build -o /bin/client ./cmd/client
    
FROM scratch AS server
COPY --from=build-server /bin/server /bin/
ENTRYPOINT [ "/bin/server" ]
```

## 更改运行时版本

当镜像使用golang:1.20-alpine镜像作为基础镜像时，但如果有人想使用不同版本的Go来构建应用时，虽然可以手动修改Dockerfile的版本，但是还有更加轻松的方式。

```shell
ARG GO_VERSION=1.20
FROM golang:${GO_VERSION}-alpine AS base
WORKDIR /src
RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=bind,source=go.sum,target=go.sum \
    --mount=type=bind,source=go.mod,target=go.mod \
    go mod download -x
    
FROM base AS build-client
RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=bind,target=. \
    go build -o /bin/client ./cmd/client
```

通过关键字`ARG`插入`FROM`指令中镜像的变量，构建参数默认值是`1.20`，如果未收到`GO_VERSION`构建参数，则`FROM`指令解析为`golang:1.20-alpine`，可以使用`--build-arg`构建命令来设置不同的版本

```shell
docker build --build-arg="GO_VERSION=1.19" .
```

## 导出二进制文件

如果只是将容器当做构建环境，并不想将应用程序构建成Docker镜像。可以使用导出器将构建好的二进制或包保存到磁盘。

```dockerfile
ARG GO_VERSION=1.20
FROM golang:${GO_VERSION}-alpine AS base
WORKDIR /src
RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=bind,source=go.sum,target=go.sum \
    --mount=type=bind,source=go.mod,target=go.mod \
    go mod download -x
    
FROM base AS build-client
RUN --mount=type=cache,target=/go/pkg/mod/ \
    --mount=type=bind,target=. \
    go build -o /bin/client ./cmd/client
```

可以使用--output导出二进制或包到磁盘,同时需要使用--target指定在哪个阶段

```shell
docker build --output=bin --target=build-client .
```

