---
title: Linux证书有效期检测脚本
abbrlink: bc2a8490
date: 2023-01-22 02:51:55
tags:
  - Shell
  - OpenSSL
categories: Linux
cover: img/fengmian/linux.png
---
```shell
#!/bin/bash

Domain="""
www.xiaowangc.com
www.baidu.com
www.so.com
developer.aliyun.com
www.google.com
harbor.xiaowangc.local
"""

echo "-----------开始检查证书有效期-----------"
for i in ${Domain};
do
    end_time=$(timeout 3 openssl s_client -connect $i:443 2> /dev/null | openssl x509 -noout -enddate 2> /dev/null | awk -F '=' '{print $2}')
    
    if [ $? -ne 0 ] || [[ $end_time == '' ]];then
        echo -e "当前域名为: $i"
        echo -e "\e[33m未能检测成功,请稍后重试\e[0m"
        echo "----------------------------------------"
        continue
    fi 
    
    echo -e "当前检查的域名: $i"
    
    temp_time_1=$(date -d "$end_time" +%s)
    temp_time_2=$(date -d "$(date -u '+%b %d %T %Y GMT')" +%s )
    
    let temp_time_3=$temp_time_1-$temp_time_2
    days=`expr $temp_time_3 / 86400`
    
    if [ $days -lt 30 ];then
        echo -e "\e[31m剩余天数：$days天\e[0m"
        echo "----------------------------------------"
        continue
    fi
    
    echo -e "\e[32m剩余天数：$days天\e[0m"
    echo "----------------------------------------"

done
```