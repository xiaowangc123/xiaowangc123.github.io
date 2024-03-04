---
title: ES&Kibana安装配置
abbrlink: 93a87db7
date: 2023-01-10 15:32:11
tags:
  - ElasticSearch
  - Kibana
cover: img/fengmian/elastic_logo.png
categories: ElasticSearch
---
# ES单节点安装

## 下载es并解压

```shell
[root@xiaowangc ~]# wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.5.3-linux-x86_64.tar.gz
[root@xiaowangc ~]# tar -xzf elasticsearch-8.5.3-linux-x86_64.tar.gz -C /usr/local
```

## 创建用户

```shell
# 使用elastic用户启动elasticsearch,使用root会报错
[root@xiaowangc ~]# useradd elastic
[root@xiaowangc ~]# cd /usr/local/
[root@xiaowangc local]# chown -R elastic.elastic elasticsearch-8.5.3
```

## 更改配置文件

```shell
[root@xiaowangc local]# vi elasticsearch-8.5.3/config/elasticsearch.yml
```

```yaml
# 证书和节点之间加密传输可配可不配，视情况而定，也可以只配置一个身份验证
cluster.name: xiaowangc													# ES集群名称
node.name: es.xiaowangc.local											# 节点名称
network.host: 192.168.10.224											# 节点IP
http.port: 9200															# ES端口
discovery.type: single-node												# 单节点需要加此选项

xpack.security.transport.ssl.enabled: true								# 在传输网络层上启用或禁用 TLS/SSL，节点使用这些层相互通信
xpack.security.transport.ssl.verification_mode: certificate 			# 控制证书的验证full、certificate、none
xpack.security.transport.ssl.client_authentication: required			# 控制服务器在请求证书方面的行为
xpack.security.transport.ssl.keystore.path: elastic-certificates.p12	# 包含专用密钥和证书的密钥库文件
xpack.security.transport.ssl.truststore.path: elastic-certificates.p12	# 包含要信任的证书的密钥库
xpack.security.enabled: true											# 开启身份验证

xpack.security.http.ssl.enabled: true									# 开启HTTPS	
xpack.security.http.ssl.keystore.path: http.p12							# 指定证书
```

## 创建CA的方法

```shell
[root@master ~]# ls
xiaowangc.cnf
[root@master ~]# cat xiaowangc.cnf
[ v3_ca ]
keyUsage = critical, keyCertSign, digitalSignature, keyEncipherment
basicConstraints = critical,CA:true
subjectKeyIdentifier = hash
subjectAltName = DNS:ca.xiaowangc.local
[root@master ~]# openssl req -new -newkey rsa:2048 -keyout ca.key -out ca.csr -nodes -subj '/CN=ca.xiaowangc.local'
[root@master ~]# openssl x509 -req -days 36500 -sha256 -extfile xiaowangc.cnf -extensions v3_ca -set_serial 0 -signkey ca.key -in ca.csr -out ca.crt
```

## 配置证书

```shell
[root@xiaowangc local]# cd elasticsearch-8.5.3
[root@xiaowangc elasticsearch-8.5.3]# ./bin/elasticsearch-certutil cert --ca-cert ca.crt --ca-key ca.key
# 这里的CA是我自建的一套，因为需要用我们自己CA的签发证书，方便信任管理
[root@es elasticsearch-8.5.3]# ls
bin  ca.crt  ca.key  config  data  elastic-certificates.p12  jdk  lib  LICENSE.txt  logs  modules  nohup.out  NOTICE.txt  plugins  README.asciidoc
# 上面那条命令会生成elastic-certificates.p12证书
[root@xiaowangc elasticsearch-8.5.3]# cp elastic-certificates.p12 config/
# 配置文件中指定的elastic-certificates.p12证书默认会在config目录中寻找
[root@xiaowangc elasticsearch-8.5.3]# chown -R elastic.elastic config

######################上面生成的p12证书是集群间通信加密的################################

[root@xiaowangc elasticsearch-8.5.3]$ ./bin/elasticsearch-certutil http			# 为节点申请证书
Generate a CSR? [y/N]n
# 不创建CSR

Use an existing CA? [y/N]y
# 使用现有CA

CA Path: ca.crt
# CA证书文件名   默认在config目录中寻找

CA Key: ca.key
# CA私钥文件名   默认在config目录中寻找

For how long should your certificate be valid? [5y]
# 设置证书的有效时间

Generate a certificate per node? [y/N]y
# 为每个节点生成证书

node #1 name: es.xiaowangc.local
# 节点1的名称

Enter all the hostnames that you need, one per line.
When you are done, press <ENTER> once more to move on to the next step.

es.xiaowangc.local

You entered the following hostnames.

 - es.xiaowangc.local

Is this correct [Y/n]y
# 确认信息无误

Enter all the IP addresses that you need, one per line.
When you are done, press <ENTER> once more to move on to the next step.

192.168.10.224
# 节点的IP

You entered the following IP addresses.

 - 192.168.10.224

Is this correct [Y/n]y
# 确认信息无误

The generated certificate will have the following additional configuration
values. These values have been selected based on a combination of the
information you have provided above and secure defaults. You should not need to
change these values unless you have specific requirements.

Key Name: es.xiaowangc.local
Subject DN: CN=es, DC=xiaowangc, DC=local
Key Size: 2048

Do you wish to change any of these options? [y/N]n
# 是否更改
Generate additional certificates? [Y/n]n
# 是否生成其他证书

If you wish to use a blank password, simply press <enter> at the prompt below.
Provide a password for the "http.p12" file:  [<ENTER> for none]
# 给证书加密，直接回车不加密

What filename should be used for the output zip file? [/usr/local/elasticsearch-8.5.3/elasticsearch-ssl-http.zip]
# 输出的文件名

[root@xiaowangc elasticsearch-8.5.3]# ls
bin  ca.crt  ca.key  config  data  elastic-certificates.p12  elasticsearch-ssl-http.zip  jdk  lib  LICENSE.txt  logs  modules  nohup.out  NOTICE.txt  plugins  README.asciidoc
[root@xiaowangc elasticsearch-8.5.3]# unzip elasticsearch-ssl-http.zip
[root@xiaowangc elasticsearch-8.5.3]# cp elasticsearch/http.p12 config/
[root@xiaowangc elasticsearch-8.5.3]# chown -R elastic.elastic config/
```

## 启动ES

```shell
[root@xiaowangc elasticsearch-8.5.3]# su elastic
[elastic@xiaowangc elasticsearch-8.5.3]$ nohup ./bin/elasticsearch &
```

## 更改ES密码

```shell
[elastic@xiaowangc elasticsearch-8.5.3]$ ./bin/elasticsearch-reset-password -u elastic
This tool will reset the password of the [elastic] user to an autogenerated value.
The password will be printed in the console.
Please confirm that you would like to continue [y/N]y


Password for the [elastic] user successfully reset.
New value: AaGWf1Krql6*rpnYBgjE
```

## 验证

![image-20230109150335931](image-20230109150335931.png)

**证书验证成功，前提得信任CA**

# ES集群配置方法

## 规划

| 主机名                 | IP地址            | 应用      |
| ---------------------- | ----------------- | --------- |
| es03.xiaowangc.local   | 192.168.10.233/24 | ES        |
| es02.xiaowangc.local   | 192.168.10.232/24 | ES        |
| es01.xiaowangc.local   | 192.168.10.231/24 | ES        |
| es.xiaowangc.local     | 192.168.10.230/24 | openresty |
| kibana.xiaowangc.local | 192.168.10.234/24 | kibana    |

## DNS

![image-20230109171612733](image-20230109171612733.png)

## 必要设置

**所有节点均需配置以免出问题，配置完重启**

```shell
[root@es01 ~]# cat /etc/security/limits.conf
*       soft    nofile  65536
*       hard    nofile  65536
root    soft    nofile  65536
root    hard    nofile  65536
[root@es01 ~]# cat /etc/sysctl.conf
net.core.somaxconn = 1024
net.core.netdev_max_backlog = 5000
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_wmem = 4096 12582912 16777216
net.ipv4.tcp_rmem = 4096 12582912 16777216
net.ipv4.tcp_max_syn_backlog = 8096
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 10240 65535
net.ipv4.ip_local_reserved_ports = 24224
vm.max_map_count=262144
[root@es01 ~]# systemctl disable --now firewalld
```



## 安装Nginx

```shell
[root@es ~]# yum install pcre-devel openssl-devel gcc curl
[root@es ~]# wget https://openresty.org/package/centos/openresty.repo
[root@es ~]# mv openresty.repo /etc/yum.repos.d/
[root@es ~]# dnf makecache
[root@es ~]# dnf -y install openresty
[root@es ~]# cd /usr/local/openresty
[root@es openresty]# vi nginx/conf/nginx.conf
```

```yaml
worker_processes  auto;

events {
    worker_connections  1024;
}

http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;

    keepalive_timeout  65;

    server {
        listen       80;
        server_name  es.xiaowangc.local;

        return 301 https://es.xiaowangc.com;
        
        location / {
            root    html;
            index   index.html;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }

    upstream es_cluster {
        server es01.xiaowangc.local:9200;
        server es02.xiaowangc.local:9200;
        server es03.xiaowangc.local:9200;
    }

    server {
        listen       443 ssl;
        server_name  es.xiaowangc.local;

        ssl_certificate      es.crt;
        ssl_certificate_key  es.key;

        ssl_session_cache    shared:SSL:1m;
        ssl_session_timeout  5m;

        ssl_ciphers  HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers  on;

        location / {
            root   html;
            index  index.html index.htm;
            proxy_pass http://es_cluster;
            proxy_set_header Host $proxy_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-forwarded $proxy_add_x_forwarded_for;
        }
    }

}
```

```shell
[root@es openresty]# ./bin/openresty
```

## ES01安装配置

```shell
[root@es01 ~]# tar xf elasticsearch-8.5.3-linux-x86_64.tar.gz -C /usr/local/
[root@es01 ~]# useradd elastic
[root@es01 ~]# cd /usr/local/elasticsearch-8.5.3/
[root@es01 elasticsearch-8.5.3]# vi config/elasticsearch.yml
```

```yaml
cluster.name: xiaowangc
node.name: es01.xiaowangc.local		
network.host: 0.0.0.0
http.port: 9200
discovery.seed_hosts: ["es01.xiaowangc.local","es02.xiaowangc.local","es03.xiaowangc.local"]
cluster.initial_master_nodes: ["es03.xiaowangc.local","es02.xiaowangc.local","es01.xiaowangc.local"]
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.client_authentication: required
xpack.security.transport.ssl.keystore.path: elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: elastic-certificates.p12
xpack.security.enabled: true
```

## ES02配置

**其余配置和ES01一样就不写出来了**

```yaml
cluster.name: xiaowangc
node.name: es02.xiaowangc.local		
network.host: 0.0.0.0
http.port: 9200
discovery.seed_hosts: ["es01.xiaowangc.local","es02.xiaowangc.local","es03.xiaowangc.local"]
cluster.initial_master_nodes: ["es03.xiaowangc.local","es02.xiaowangc.local","es01.xiaowangc.local"]
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.client_authentication: required
xpack.security.transport.ssl.keystore.path: elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: elastic-certificates.p12
xpack.security.enabled: true
```

## ES03配置

**其余配置和ES01一样就不写出来了**

```yaml
cluster.name: xiaowangc
node.name: es03.xiaowangc.local		
network.host: 0.0.0.0
http.port: 9200
discovery.seed_hosts: ["es01.xiaowangc.local","es02.xiaowangc.local","es03.xiaowangc.local"]
cluster.initial_master_nodes: ["es03.xiaowangc.local","es02.xiaowangc.local","es01.xiaowangc.local"]
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.client_authentication: required
xpack.security.transport.ssl.keystore.path: elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: elastic-certificates.p12
xpack.security.enabled: true
```

## 生成证书

**注意：每个节点都需要指定p12格式的证书，来加密集群间的通信，生成一次就行了，拷贝到其他节点**

**ES集群必须配置集群间的加密**

```shell
[root@es01 ~]# ./bin/elasticsearch-certutil cert --ca-cert ca.crt --ca-key ca.key
# 跟单机配置一样，集群必须配置TSL使集群间通信进行加密否则集群无法启动
[root@es01 elasticsearch-8.5.3]# mv elastic-certificates.p12 config/
# 其他节点无需生成,直接copy节点1的p12证书过去即可
```

## 启动

**所有节点均需要使用普通用户启动elasticsearch**

```shell
[root@es01 elasticsearch-8.5.3]# cd ..
[root@es01 local]# chown -R elastic.elastic elasticsearch-8.5.3/
[root@es01 local]# su elastic
[root@es01 local]# su elastic
[elastic@es01 local]$ cd elasticsearch-8.5.3/
[elastic@es01 elasticsearch-8.5.3]$ nohup ./bin/elasticsearch &
```

## 更改密码

```shell
# 自动设置所有密码,只能使用一次
[elastic@es01 elasticsearch-8.5.3]$ ./bin/elasticsearch-reset-password auto


# 手动设置跟单机一样
[elastic@es01 elasticsearch-8.5.3]$ ./bin/elasticsearch-reset-password -u elastic
This tool will reset the password of the [elastic] user to an autogenerated value.
The password will be printed in the console.
Please confirm that you would like to continue [y/N]y


Password for the [elastic] user successfully reset.
New value: cmo6aWzTVF+YegghL+h=
```

## 附加：配置HTTPS

### 生成证书

直接通过`elasticsearch-certutil http`为所有节点生成证书

**自行准备ca**

```shell
[root@es01 elasticsearch-8.5.3]# ./bin/elasticsearch-certutil http
Generate a CSR? [y/N]n
Use an existing CA? [y/N]y
CA Path: ca.crt
CA Key: ca.key
For how long should your certificate be valid? [5y]
Generate a certificate per node? [y/N]y					# 是否为每个节点生成证书
node #1 name: es01.xiaowangc.local

Enter all the hostnames that you need, one per line.
When you are done, press <ENTER> once more to move on to the next step.

node01.xiaowangc.local

You entered the following hostnames.

 - node01.xiaowangc.local

Is this correct [Y/n]y

Enter all the IP addresses that you need, one per line.
When you are done, press <ENTER> once more to move on to the next step.

192.168.10.231

You entered the following IP addresses.

 - 192.168.10.231

Is this correct [Y/n]y

Key Name: node01.xiaowangc.local
Subject DN: CN=node01, DC=xiaowangc, DC=local
Key Size: 2048

Do you wish to change any of these options? [y/N]n
Generate additional certificates? [Y/n]y				# 是否继续生成证书

node #2 name: es02.xiaowangc.local

Enter all the hostnames that you need, one per line.
When you are done, press <ENTER> once more to move on to the next step.

es02.xiaowangc.local

You entered the following hostnames.

 - es02.xiaowangc.local

Is this correct [Y/n]y

Enter all the IP addresses that you need, one per line.
When you are done, press <ENTER> once more to move on to the next step.

192.168.10.232

You entered the following IP addresses.

 - 192.168.10.232

Is this correct [Y/n]y
Do you wish to change any of these options? [y/N]n
Generate additional certificates? [Y/n]y				# 是否继续生成证书

node #3 name: es03.xiaowangc.local

Enter all the hostnames that you need, one per line.
When you are done, press <ENTER> once more to move on to the next step.

es03.xiaowangc.local

You entered the following hostnames.

 - es03.xiaowangc.local

Is this correct [Y/n]y

Enter all the IP addresses that you need, one per line.
When you are done, press <ENTER> once more to move on to the next step.

192.168.10.233

You entered the following IP addresses.

 - 192.168.10.233

Is this correct [Y/n]y
Do you wish to change any of these options? [y/N]n
Generate additional certificates? [Y/n]n

If you wish to use a blank password, simply press <enter> at the prompt below.
Provide a password for the "http.p12" file:  [<ENTER> for none]

## Where should we save the generated files?

What filename should be used for the output zip file? [/usr/local/elasticsearch-8.5.3/elasticsearch-ssl-http.zip]

```

### 解压

```shell
[root@es01 elasticsearch-8.5.3]# dnf -y install unzip tree
[root@es01 elasticsearch-8.5.3]# unzip elasticsearch-ssl-http.zip
[root@es01 elasticsearch-8.5.3]# tree elasticsearch
elasticsearch
├── es02.xiaowangc.local
│   ├── http.p12
│   ├── README.txt
│   └── sample-elasticsearch.yml
├── es03.xiaowangc.local
│   ├── http.p12
│   ├── README.txt
│   └── sample-elasticsearch.yml
└── node01.xiaowangc.local
    ├── http.p12
    ├── README.txt
    └── sample-elasticsearch.yml

3 directories, 9 files
```

### 配置方法

**将证书copy到每个节点，将对应节点的证书放到config目录中，并修改权限**

**每个节点的配置中加入两项配置并重启**

```yaml
xpack.security.http.ssl.enabled: true									# 开启HTTPS	
xpack.security.http.ssl.keystore.path: http.p12							# 指定证书 默认会在config目录中找http.p12文件
```

### nginx参考

```yaml
#user  nobody;
worker_processes  auto;

#error_log  logs/error.log;
#error_log  logs/error.log  notice;
#error_log  logs/error.log  info;

#pid        logs/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    sendfile        on;
    #tcp_nopush     on;

    #keepalive_timeout  0;
    keepalive_timeout  65;

    #gzip  on;

    server {
        listen       80;
        server_name  es.xiaowangc.local;

        return 301 https://es.xiaowangc.com;

        location / {
            root    html;
            index   index.html;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
    }

    upstream es_cluster {
        server es01.xiaowangc.local:9200;
        server es02.xiaowangc.local:9200;
        server es03.xiaowangc.local:9200;
    }

    server {
        listen       443 ssl;
        server_name  es.xiaowangc.local;

        ssl_certificate      es.crt;
        ssl_certificate_key  es.key;

        ssl_session_cache    shared:SSL:1m;
        ssl_session_timeout  5m;

        ssl_ciphers  HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers  on;

        location / {
            root   html;
            index  index.html index.htm;
            proxy_pass https://es_cluster;				# 配置成https
            proxy_set_header Host $proxy_host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-forwarded $proxy_add_x_forwarded_for;
        }
    }

}
```

# Kibana安装

## 配置

```shell
[root@kibana ~]# tar xf kibana-8.5.3-linux-x86_64.tar.gz -C /usr/local/
[root@kibana local]#
[root@kibana local]# cd kibana-8.5.3/
[root@kibana kibana-8.5.3]# vi config/kibana.yml
```

```yaml
server.port: 5601
server.host: "kibana.xiaowangc.local"
server.publicBaseUrl: "https://kibana.xiaowangc.local"
server.name: "kibana.xiaowangc.local"
i18n.locale: "zh-CN"								# 设置中文
server.ssl.enabled: true
server.ssl.certificate: /usr/local/kibana-8.5.3/config/kibana.crt						# 指定kibana证书
server.ssl.key: /usr/local/kibana-8.5.3/config/kibana.key								# 指定kibana私钥
elasticsearch.hosts: ["https://es.xiaowangc.local/"]									# 我这用的是LB地址
elasticsearch.username: "kibana_system"				# ES中的kibana_system账号
elasticsearch.password: "oXeQUf8eMlZ2glRbVL_8"		# 密码auto的时候会自动配置，或者手动设置也行				
elasticsearch.ssl.certificateAuthorities: [ "/usr/local/kibana-8.5.3/ca.pem" ]			# 指定CA证书
```

## 生成证书

**还是用之前的CA**

```shell
[root@gateway ca]# ls
ca.crt  ca.key   kibana.cnf

[root@gateway ca]# cat kibana.cnf
[ v3_req ]
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth,clientAuth
basicConstraints = critical, CA:FALSE
authorityKeyIdentifier = keyid,issuer
subjectAltName = DNS:kibana.xiaowangc.local,IP:192.168.10.234

[root@gateway ca]# openssl req -new -newkey rsa:2048 -keyout kibana.key -out kibana.csr -nodes -subj '/CN=kibana.xiaowangc.local'

[root@gateway ca]# openssl x509 -req -sha256 -days 36500 -extfile kibana.cnf -extensions v3_req -in kibana.csr -CA ca.crt -CAkey ca.key -out kibana.crt -CAcreateserial

[root@gateway ca]# ls
ca.crt  ca.key  ca.srl  kibana.cnf  kibana.crt  kibana.csr  kibana.key
```

**将证书拷贝到kibana对应的路径即可（略），包括CA证书**

```shell
[root@kibana kibana-8.5.3]# useradd kibana
[root@kibana kibana-8.5.3]# chown -R kibana.kibana /usr/local/kibana-8.5.3/
[root@kibana kibana-8.5.3]# su kibana
[kibana@kibana kibana-8.5.3]$ nohup bin/kibana &
```

![image-20230110152649136](image-20230110152649136.png)

**登录用elastic账号登录就行了**

**不想使用5601端口可以做nginx代理或直接修改配置文件端口，自行尝试**

