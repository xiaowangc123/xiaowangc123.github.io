---
title: 个人生成的Docker镜像
abbrlink: 736ef7f1
date: 2022-11-04 15:52:39
tags: Docker
cover: img/fengmian/docker.jpeg
categories: 容器
---
# LNMP
```yaml
FROM centos:centos7.9.2009

MAINTAINER xiaowangc<780312916@qq.com>

COPY my.cnf /etc/my.cnf

RUN rm -rf /etc/yum.repos.d/* && \
    curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.cloud.tencent.com/repo/centos7_base.repo && \
    yum makecache && \
    yum -y install gcc gcc-c++ make libpng-devel automake autoconf glibc wget prce pcre-devel openssl openssl-devel numactl libaio libxml2 libxml2-devel sqlite-devel libcurl libcurl-devel ncurses-devel&& \
    yum clean all && \
    mkdir /lnmp

WORKDIR /lnmp

RUN wget https://nginx.org/download/nginx-1.22.1.tar.gz && \
    tar xf nginx-1.22.1.tar.gz && \
    rm -rf nginx-1.22.1.tar.gz && \
    useradd nginx && \
    cd nginx-1.22.1/ && \
    ./configure --prefix=/lnmp/nginx \
    --user=nginx \
    --group=nginx \
    --with-compat \
    --with-file-aio \
    --with-threads \
    --with-http_addition_module \
    --with-http_auth_request_module \
    --with-http_dav_module \
    --with-http_flv_module \
    --with-http_gunzip_module \
    --with-http_gzip_static_module \
    --with-http_mp4_module \
    --with-http_random_index_module \
    --with-http_realip_module \
    --with-http_secure_link_module \
    --with-http_slice_module \
    --with-http_ssl_module \
    --with-http_stub_status_module \
    --with-http_sub_module \
    --with-http_v2_module \
    --with-mail \
    --with-mail_ssl_module \
    --with-stream \
    --with-stream_realip_module \
    --with-stream_ssl_module \
    --with-stream_ssl_preread_module && \
    make && make install && cd /lnmp/ && rm -rf nginx-1.22.1 && \
    chown -R nginx.nginx nginx

RUN wget --no-check-certificate https://vpn.xiaowangc.com/cmake-3.25.0-rc3-linux-x86_64.tar.gz && \
    tar xf cmake-3.25.0-rc3-linux-x86_64.tar.gz && rm -rf cmake-3.25.0-rc3-linux-x86_64.tar.gz && \
    mv cmake-3.25.0-rc3-linux-x86_64 cmake && \
    wget --no-check-certificate https://libzip.org/download/libzip-1.9.2.tar.gz && \
    tar xf libzip-1.9.2.tar.gz && \
    cd libzip-1.9.2 && \
    mkdir build && cd build && \
    /lnmp/cmake/bin/cmake .. && \
    make && make install && \
    cd ../../ && rm -rf libzip-1.9.2 libzip-1.9.2.tar.gz && \
    rm -rf cmake

ENV PKG_CONFIG_PATH /usr/local/lib64/pkgconfig

RUN cd /lnmp && wget https://www.php.net/distributions/php-7.4.33.tar.gz && \
    tar xf php-7.4.33.tar.gz && \
    rm -rf php-7.4.33.tar.gz && \
    cd php-7.4.33 && \
    ./configure --prefix=/lnmp/php \
    --with-config-file-path=/lnmp/php7/etc \
    --with-config-file-scan-dir=/lnmp/php/etc/php.d \
    --enable-mysqlnd \
    --with-mysqli \
    --with-pdo-mysql \
    --enable-fpm \
    --with-fpm-user=nginx \
    --with-fpm-group=nginx \
    --enable-gd \
    --with-iconv \
    --with-zlib \
    --enable-xml \
    --enable-shmop \
    --enable-sysvsem \
    --enable-inline-optimization \
    --enable-mbregex \
    --enable-mbstring \
    --disable-mbregex \
    --enable-ftp \--with-openssl \
    --enable-pcntl \
    --enable-sockets \
    --with-xmlrpc \
    --without-pear \
    --disable-phar \
    --with-zip \
    --enable-soap \
    --without-pear \
    --with-gettext \
    --enable-session \
    --with-curl \
    --enable-bcmath \
    --enable-opcache && \
    make && make install && \
    cd /lnmp && rm -rf php-7.4.33 && \
    cp php/etc/php-fpm.conf.default php/etc/php-fpm.conf && \
    cp php/etc/php-fpm.d/www.conf.default php/etc/php-fpm.d/www.conf

COPY nginx.conf /lnmp/nginx/conf/nginx.conf

RUN wget --no-check-certificate https://vpn.xiaowangc.com/cmake-3.25.0-rc3-linux-x86_64.tar.gz && \
    tar xf cmake-3.25.0-rc3-linux-x86_64.tar.gz && rm -rf cmake-3.25.0-rc3-linux-x86_64.tar.gz && \
    mv cmake-3.25.0-rc3-linux-x86_64 cmake && \
    wget https://downloads.mysql.com/archives/get/p/23/file/mysql-boost-5.7.39.tar.gz && \
    tar xf mysql-boost-5.7.39.tar.gz && \
    rm -rf mysql-boost-5.7.39.tar.gz && \
    cd mysql-5.7.39 && \
    useradd mysql && \
    /lnmp/cmake/bin/cmake \
    -DCMAKE_INSTALL_PREFIX=/lnmp/mysql \
    -DMYSQL_DATADIR=/var/lib/mysql \
    -DMYSQL_UNIX_ADDR=/var/lib/mysql/mysql.sock \
    -DWITH_INNOBASE_STORAGE_ENGINE=1 \
    -DSYSCONFDIR=/etc \
    -DENABLED_LOCAL_INFILE=1 \
    -DWITH_EXTRA_CHARSETS=all \
    -DDEFAULT_CHARSET=utf8mb4 \
    -DDEFAULT_COLLATION=utf8mb4_unicode_ci \
    -DWITH_BOOST=/lnmp/mysql-5.7.39/boost/boost_1_59_0 && \
    make && make install && cd .. && rm -rf mysql-5.7.39 && \
    mkdir /var/lib/mysql && chown -R mysql.mysql /var/lib/mysql && \
    cd /lnmp && rm -rf cmake

ENV PATH $PATH:/lnmp/nginx/sbin:/lnmp/php/sbin:/lnmp/mysql/bin:/lnmp/mysql/support-files

VOLUME ["/lnmp/nginx/html","/var/lib/mysql"]

EXPOSE 80 3306

COPY docker-entrypoint.sh /

RUN chmod 777 /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]
```