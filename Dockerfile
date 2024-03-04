FROM node:18 AS builder
MAINTAINER xiaowangc.com<780312916@qq.com>
ENV TZ=Asia/Shanghai
WORKDIR /app
COPY . .
RUN npm install && \
    npm install hexo-cli -g && \
    hexo g && \
    cp google319b15f7fe4c4ac3.html public/ && \
    cp sogousiteverification.txt public/

FROM nginx:1.24.0-alpine
MAINTAINER xiaowangc.com<780312916@qq.com>
ENV TZ=Asia/Shanghai
COPY --from=builder /app/public/ /usr/share/nginx/html/
