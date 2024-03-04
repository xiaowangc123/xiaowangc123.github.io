---
title: Nginx-GeoIP2模块备忘
tags: nginx
cover: img/fengmian/nginx.png
categories:
  - nginx
abbrlink: db72cc22
date: 2023-02-02 05:53:56
---
# Nginx配置GeoIP2模块备忘

```shell
# 例如下配置,需要注意两种情况
# 第一种无反向代理的情况,对于geoip2默认使用的就是$remote_addr变量获取客户IP地址
# 第二种有反向代理的情况,对于geoip2默认使用的就是$remote_addr变量获取客户IP地址，需要反向代理携带客户端IP，将每行的变量都添加上$http_x_real_ip变量
# 例如 $geoip2_data_city source=$http_x_real_ip city names zh-CN; 

# geoip2_data_***为变量名,自定义变量名称亦可

geoip2 /root/GeoLite2-City.mmdb {
  $geoip2_data_country "default=中国" source=$remote_addr country names zh-CN;  # 中国
  $geoip2_data_country_code country iso_code;                  # CN
  $geoip2_data_country_continent continent names zh-CN;        # 亚洲
  $geoip2_data_country_continent_code continent code;          # AS
  $geoip2_data_province_name subdivisions 0 names zh-CN;       # 浙江省
  $geoip2_data_province_isocode subdivisions 0 names iso_code; # "ZJ"
  $geoip2_data_city city names zh-CN;                          # 杭州
  $geoip2_data_city_longitude location longitude;              # 120.161200
  $geoip2_data_city_latitude location latitude;                # 30.299400
  $geoip2_data_city_time_zone location time_zone;              # "Asia/Shanghai"
}
```

**上面的例子除了前面的变量名称可自定义外，后面的格式可以通过mmdblookup工具查看具体用法(有关联)**

**例如：$geoip2_data_city city names zh-CN;即是下面查询的：city---name---zh-CN**

**也就是geoip2_data_city变量中保存的数据是通过客户端IP地址查询后信息格式使用的city---name---zh-CN中的格式**

**按照下面的json也就是geoip2_data_city = "深圳"**

```shell
root@harbor:~# mmdblookup -f GeoLite2-City_20230131/GeoLite2-City.mmdb -i 120.229.70.51
```

```json
{
    "city":
      {
        "geoname_id":
          1795565 <uint32>
        "names":
          {
            "de":
              "Shenzhen" <utf8_string>
            "en":
              "Shenzhen" <utf8_string>
            "es":
              "Shenzhen" <utf8_string>
            "fr":
              "Shenzhen" <utf8_string>
            "ja":
              "深セン市" <utf8_string>
            "pt-BR":
              "Shenzhen" <utf8_string>
            "ru":
              "Шэньчжэнь" <utf8_string>
            "zh-CN":
              "深圳" <utf8_string>
          }
      }
    "continent":
      {
        "code":
          "AS" <utf8_string>
        "geoname_id":
          6255147 <uint32>
        "names":
          {
            "de":
              "Asien" <utf8_string>
            "en":
              "Asia" <utf8_string>
            "es":
              "Asia" <utf8_string>
            "fr":
              "Asie" <utf8_string>
            "ja":
              "アジア" <utf8_string>
            "pt-BR":
              "Ásia" <utf8_string>
            "ru":
              "Азия" <utf8_string>
            "zh-CN":
              "亚洲" <utf8_string>
          }
      }
    "country":
      {
        "geoname_id":
          1814991 <uint32>
        "iso_code":
          "CN" <utf8_string>
        "names":
          {
            "de":
              "China" <utf8_string>
            "en":
              "China" <utf8_string>
            "es":
              "China" <utf8_string>
            "fr":
              "Chine" <utf8_string>
            "ja":
              "中国" <utf8_string>
            "pt-BR":
              "China" <utf8_string>
            "ru":
              "Китай" <utf8_string>
            "zh-CN":
              "中国" <utf8_string>
          }
      }
    "location":
      {
        "accuracy_radius":
          100 <uint16>
        "latitude":
          22.555900 <double>
        "longitude":
          114.057700 <double>
        "time_zone":
          "Asia/Shanghai" <utf8_string>
      }
    "registered_country":
      {
        "geoname_id":
          1814991 <uint32>
        "iso_code":
          "CN" <utf8_string>
        "names":
          {
            "de":
              "China" <utf8_string>
            "en":
              "China" <utf8_string>
            "es":
              "China" <utf8_string>
            "fr":
              "Chine" <utf8_string>
            "ja":
              "中国" <utf8_string>
            "pt-BR":
              "China" <utf8_string>
            "ru":
              "Китай" <utf8_string>
            "zh-CN":
              "中国" <utf8_string>
          }
      }
    "subdivisions":
      [
        {
          "geoname_id":
            1809935 <uint32>
          "iso_code":
            "GD" <utf8_string>
          "names":
            {
              "en":
                "Guangdong" <utf8_string>
              "fr":
                "Province de Guangdong" <utf8_string>
              "zh-CN":
                "广东" <utf8_string>
            }
        }
      ]
  }

```

# 容器化

本人nginx的编译是在容器外编译的，亦可自行在Dockerfile对Nginx进行编译

```yaml
FROM ubuntu:22.04

MAINTAINER xiaowangc<780312916@qq.com>

RUN apt update && apt -y install libmaxminddb0 libmaxminddb-dev mmdb-bin libssl-dev libgd-dev libgeoip-dev

WORKDIR /root/app

EXPOSE 80

CMD ["/root/app/sbin/nginx","-g","daemon off;"]
```

编译后通过volume的方式启动Nginx

```shell
docker run -itdp 6002:80 -v /root/app:/root/app nginx:ip
```

# 附Nginx构建参数

**须安装libmaxminddb0 libmaxminddb-dev mmdb-bin libssl-dev libgd-dev libgeoip-dev**

**根据构建提示解决响应的软件包**

```shell
./configure --prefix=/root/app \		
--with-mail \
--with-stream \
--with-threads \
--with-file-aio \
--with-poll_module \
--with-select_module \
--with-http_v2_module \
--with-http_flv_module \
--with-http_mp4_module \
--with-http_sub_module \
--with-http_dav_module \
--with-http_flv_module \
--with-http_ssl_module \
--with-http_geoip_module \
--with-http_slice_module \
--with-http_gunzip_module \
--with-http_realip_module \
--with-http_addition_module \
--with-http_image_filter_module \
--with-http_gzip_static_module \
--with-http_random_index_module \
--with-http_secure_link_module \
--with-http_degradation_module \
--with-http_stub_status_module \
--with-mail_ssl_module \
--with-stream_ssl_module \
--with-stream_realip_module \
--with-stream_ssl_preread_module \
--add-module=/root/ngx_http_geoip2_module
```

