---
title: Kubernetes安全-Kube-Bench
abbrlink: 2031d73f
date: 2022-11-29 14:50:57
tags:
  - kubernetes
  - CKS
  - 安全
  - Kube-Bench
categories: Kubernetes
cover: img/fengmian/kubebench-logo.png
---
# Kube-Bench

kube-bench是一个工具，通过运行CIS Kubernetes基准测试中记录的检查来检查Kubernetes是否安全部署，测试使用YAML文件进行部署，使此工具易于随着测试规范的发展而更新

[GitHub网站](https://github.com/aquasecurity/kube-bench)下载，我这里是CentOS8的环境因为有rpm包就直接安装，可以通过docker、二进制或其他方式进行安装

```shell
[root@xiaowangc ~]# wget https://github.com/aquasecurity/kube-bench/releases/download/v0.6.10/kube-bench_0.6.10_linux_amd64.rpm
[root@xiaowangc ~]# dnf -y install kube-bench_0.6.10_linux_amd64.rpm

[root@xiaowangc ~]# kube-bench run --targets node
# 安全检测
# INFO信息 PASS通过 WARN警告 FAIL失败
# WARN和FAIL级别信息需要处理
# [信息级别] 序号 提示信息
[INFO] 4 Worker Node Security Configuration
[INFO] 4.1 Worker Node Configuration Files
[PASS] 4.1.1 Ensure that the kubelet service file permissions are set to 644 or more restrictive (Automated)
[PASS] 4.1.2 Ensure that the kubelet service file ownership is set to root:root (Automated)
[PASS] 4.1.3 If proxy kubeconfig file exists ensure permissions are set to 644 or more restrictive (Manual)
[PASS] 4.1.4 If proxy kubeconfig file exists ensure ownership is set to root:root (Manual)
[PASS] 4.1.5 Ensure that the --kubeconfig kubelet.conf file permissions are set to 644 or more restrictive (Automated)
[PASS] 4.1.6 Ensure that the --kubeconfig kubelet.conf file ownership is set to root:root (Automated)
[PASS] 4.1.7 Ensure that the certificate authorities file permissions are set to 644 or more restrictive (Manual)
[PASS] 4.1.8 Ensure that the client certificate authorities file ownership is set to root:root (Manual)
[PASS] 4.1.9 Ensure that the kubelet --config configuration file has permissions set to 644 or more restrictive (Automated)
[PASS] 4.1.10 Ensure that the kubelet --config configuration file ownership is set to root:root (Automated)
[INFO] 4.2 Kubelet
[PASS] 4.2.1 Ensure that the --anonymous-auth argument is set to false (Automated)
[PASS] 4.2.2 Ensure that the --authorization-mode argument is not set to AlwaysAllow (Automated)
[PASS] 4.2.3 Ensure that the --client-ca-file argument is set as appropriate (Automated)
[PASS] 4.2.4 Ensure that the --read-only-port argument is set to 0 (Manual)
[PASS] 4.2.5 Ensure that the --streaming-connection-idle-timeout argument is not set to 0 (Manual)
[FAIL] 4.2.6 Ensure that the --protect-kernel-defaults argument is set to true (Automated)
[PASS] 4.2.7 Ensure that the --make-iptables-util-chains argument is set to true (Automated)
[PASS] 4.2.8 Ensure that the --hostname-override argument is not set (Manual)
[WARN] 4.2.9 Ensure that the --event-qps argument is set to 0 or a level which ensures appropriate event capture (Manual)
[WARN] 4.2.10 Ensure that the --tls-cert-file and --tls-private-key-file arguments are set as appropriate (Manual)
[PASS] 4.2.11 Ensure that the --rotate-certificates argument is not set to false (Automated)
[PASS] 4.2.12 Verify that the RotateKubeletServerCertificate argument is set to true (Manual)
[WARN] 4.2.13 Ensure that the Kubelet only makes use of Strong Cryptographic Ciphers (Manual)

== Remediations node ==
# 补救措施或步骤(修正节点)
# 此修正提示的编号与上面检测的编号一一对应,告诉你如何纠正
4.2.6 If using a Kubelet config file, edit the file to set `protectKernelDefaults` to `true`.
If using command line arguments, edit the kubelet service file
/lib/systemd/system/kubelet.service on each worker node and
set the below parameter in KUBELET_SYSTEM_PODS_ARGS variable.
--protect-kernel-defaults=true
Based on your system, restart the kubelet service. For example:
systemctl daemon-reload
systemctl restart kubelet.service

4.2.9 If using a Kubelet config file, edit the file to set `eventRecordQPS` to an appropriate level.
If using command line arguments, edit the kubelet service file
/lib/systemd/system/kubelet.service on each worker node and
set the below parameter in KUBELET_SYSTEM_PODS_ARGS variable.
Based on your system, restart the kubelet service. For example,
systemctl daemon-reload
systemctl restart kubelet.service

4.2.10 If using a Kubelet config file, edit the file to set `tlsCertFile` to the location
of the certificate file to use to identify this Kubelet, and `tlsPrivateKeyFile`
to the location of the corresponding private key file.
If using command line arguments, edit the kubelet service file
/lib/systemd/system/kubelet.service on each worker node and
set the below parameters in KUBELET_CERTIFICATE_ARGS variable.
--tls-cert-file=<path/to/tls-certificate-file>
--tls-private-key-file=<path/to/tls-key-file>
Based on your system, restart the kubelet service. For example,
systemctl daemon-reload
systemctl restart kubelet.service

4.2.13 If using a Kubelet config file, edit the file to set `TLSCipherSuites` to
TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_GCM_SHA256
or to a subset of these values.
If using executable arguments, edit the kubelet service file
/lib/systemd/system/kubelet.service on each worker node and
set the --tls-cipher-suites parameter as follows, or to a subset of these values.
--tls-cipher-suites=TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256,TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384,TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305,TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_256_GCM_SHA384,TLS_RSA_WITH_AES_128_GCM_SHA256
Based on your system, restart the kubelet service. For example:
systemctl daemon-reload
systemctl restart kubelet.service


== Summary node ==
# 摘要
19 checks PASS
1 checks FAIL
3 checks WARN
0 checks INFO

== Summary total ==
# 汇总
19 checks PASS
1 checks FAIL
3 checks WARN
0 checks INFO
```

```shell
# 安全检测
···
···
···
# 修正措施
...
...
...
# 摘要
...
# 汇总
```

**基本kube-bench检测后的格式如上所示**

# 常用命令

```shell
[root@xiaowangc ~]# kube-bench	# 对所有targets进行检测(master node etcd等)
[root@xiaowangc ~]# kube-bench run --targets master # 对master进行检测
[root@xiaowangc ~]# kube-bench run -s node # 对node进行检测
[root@xiaowangc ~]# kube-bench run -s master # 对master进行检测
[root@xiaowangc ~]# kube-bench master # 对master进行检测

# 使用cis-1.4对node进行检测
[root@xiaowangc ~]# kube-bench node --benchmark cis-1.4
# 针对kubernetes1.13版本进行检测
kube-bench node --version 1.13
```

# 支持版本

| 源   | CIS Kubernetes Benchmark                                     | kube-bench 配置          | Kubernetes 版本 |
| ---- | ------------------------------------------------------------ | ------------------------ | --------------- |
| CIS  | [1.5.1](https://workbench.cisecurity.org/benchmarks/4892)    | cis-1.5                  | 1.15            |
| CIS  | [1.6.0](https://workbench.cisecurity.org/benchmarks/4834)    | cis-1.6                  | 1.16-1.18       |
| CIS  | [1.20](https://workbench.cisecurity.org/benchmarks/6246)     | cis-1.20                 | 1.19-1.21       |
| CIS  | [1.23](https://workbench.cisecurity.org/benchmarks/7532)     | cis-1.23                 | 1.22-1.23       |
| CIS  | [1.24](https://workbench.cisecurity.org/benchmarks/10873)    | cis-1.24                 | 1.24            |
| CIS  | [GKE 1.0.0](https://workbench.cisecurity.org/benchmarks/4536) | gke-1.0                  | GKE             |
| CIS  | [GKE 1.2.0](https://workbench.cisecurity.org/benchmarks/7534) | gke-1.2.0                | GKE             |
| CIS  | [EKS 1.0.1](https://workbench.cisecurity.org/benchmarks/6041) | eks-1.0.1                | EKS             |
| CIS  | [EKS 1.1.0](https://workbench.cisecurity.org/benchmarks/6248) | eks-1.1.0                | EKS             |
| CIS  | [ACK 1.0.0](https://workbench.cisecurity.org/benchmarks/6467) | ack-1.0                  | ACK             |
| CIS  | [AKS 1.0.0](https://workbench.cisecurity.org/benchmarks/6347) | aks-1.0                  | AKS             |
| RHEL | RedHat OpenShift hardening guide                             | rh-0.7                   | OCP 3.10-3.11   |
| CIS  | [OCP4 1.1.0](https://workbench.cisecurity.org/benchmarks/6778) | rh-1.0                   | OCP 4.1-        |
| CIS  | [1.6.0-k3s](https://docs.rancher.cn/docs/k3s/security/self-assessment/_index) | cis-1.6-k3s              | k3s v1.16-v1.24 |
| DISA | [Kubernetes Ver 1, Rel 6](https://dl.dod.cyber.mil/wp-content/uploads/stigs/zip/U_Kubernetes_V1R6_STIG.zip) | eks-stig-kubernetes-v1r6 | EKS             |