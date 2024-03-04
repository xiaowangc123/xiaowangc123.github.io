---
title: CentoOS8 TLS目录
abbrlink: 9b886d63
date: 2022-11-23 18:05:21
tags:
  - TLS
  - Linux
categories: Linux
cover: img/fengmian/openssl.jpg
---
快速帮助1：要将简单PEM或DER文件格式的证书添加到系统上受信任的CA列表中，请执行以下操作：
·将其作为新文件添加到/etc/pki/catrust/source/achors目录/
·运行更新ca信任提取

快速帮助2：如果您的证书是扩展的BEGIN TRUSTED文件格式（可能包含不信任/黑名单信任标志，或TLS以外的其他用途的信任标志），则：
·将其作为新文件添加到/etc/pki/catrust/source目录/
·运行更新ca信任提取

为了提供简单性和灵活性，证书文件的处理方式取决于它们安装到的子目录。
·简单信任锚子目录：/usr/share/pki/ca-trust-source/achors/或/etc/pki/ca-trust/source/achors/
·简单黑名单（不信任）子目录：/usr/share/pki/ca-trust-source/blact/或/etc/pki/ca-trust/source/black/
·扩展格式目录：/usr/share/pki/ca-trust-source/或/etc/pki/ca-trust/source/

在主目录/usr/share/pki/ca-trust-source/或/etc/pki/ca-trust/source/中，可以安装以下文件格式的一个或多个文件：
·包含信任标志的证书文件，采用BEGIN/END TRUSTED certificate文件格式（任何文件名），这些文件是使用openssl x509工具和-addreject创建的
-添加信任选项。支持具有多个证书的捆绑文件。

·p11工具包文件格式的文件，使用.p11工具包文件扩展名，可以（例如）用于基于序列号和颁发者名称不信任证书，而不具有完整的证书可用。（这目前是一种未记录的格式，稍后将进行扩展。有关支持的格式的示例，请参阅ca证书包附带的文件。）

·没有信任标志的DER文件格式或PEM（BEGIN/END certificate）文件格式（任何文件名）的证书文件。此类文件将以中立信任添加既不信任也不信任。系统只需知道它们，这可能有助于密码软件构建证书链。（如果您需要CA要信任这些文件格式的证书，您应该将其从该目录中删除，并将其移至./anchors子目录。）