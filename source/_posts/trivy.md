---
title: Kubernetes-Trivy容器镜像扫描仪
abbrlink: 1cfc3e42
date: 2022-12-01 09:48:07
tags:
  - kubernetes
  - Trivy
  - CKS
  - 安全
  - 扫描工具
categories: Kubernetes
cover: img/fengmian/trivy-logo.png
---
# Trivy

Trivy是一款全面且多功能的安全扫描仪。Trivy用扫描仪来寻找安全问题，并瞄准可以找到这些问题的目标。

Trivy可以扫描的目标：

- 容器镜像
- 文件系统
- Git存储库
- 虚拟机映像

# 安装

更多方式请到：[安装 - Trivy (aquasecurity.github.io)](https://aquasecurity.github.io/trivy/v0.35/getting-started/installation/)

本次演示OS：CentOS8.5

```yaml
# 直接通过rpm包进行安装
[root@harbor ~]# wget https://github.com/aquasecurity/trivy/releases/download/v0.35.0/trivy_0.35.0_Linux-64bit.rpm
[root@harbor ~]# dnf -y install trivy_0.35.0_Linux-64bit.rpm
```

**Trivy除了扫描器本体还需要安装数据库，Trivy第一次扫描时会自动下载漏洞数据库，但是由于被墙可能导致数据库无法下载**

**可到墙外部署并扫描后将`/root/cache/trivy`缓存目录进行打包并`COPY`到本机进行覆盖**





# 扫描

```yaml
--ignore-unfixed	# 跳过无法修复的漏洞,暂时没有解决方案的漏洞
--skip-db-update	# 跳过数据库更新
--severity			# 扫描后显示特定风险等级的漏洞 UNKNOWN,LOW,MEDIUM,HIGH,CRITICAL
--output			# 输出到指定文件
--format			# 指定输出格式(table、json)
```
**扫描镜像**

```shell
[root@harbor ~]# trivy image python:3.4-alpine
2022-11-30T17:20:29.382+0800    INFO    Vulnerability scanning is enabled
2022-11-30T17:20:29.382+0800    INFO    Secret scanning is enabled
2022-11-30T17:20:29.382+0800    INFO    If your scanning is slow, please try '--security-checks vuln' to disable secret scanning
2022-11-30T17:20:29.382+0800    INFO    Please see also https://aquasecurity.github.io/trivy/v0.35/docs/secret/scanning/#recommendation for faster secret detection
2022-11-30T17:20:29.387+0800    INFO    Detected OS: alpine
2022-11-30T17:20:29.387+0800    INFO    Detecting Alpine vulnerabilities...
2022-11-30T17:20:29.388+0800    INFO    Number of language-specific files: 1
2022-11-30T17:20:29.388+0800    INFO    Detecting python-pkg vulnerabilities...
2022-11-30T17:20:29.389+0800    WARN    This OS version is no longer supported by the distribution: alpine 3.9.2
2022-11-30T17:20:29.389+0800    WARN    The vulnerability detection may be insufficient because security updates are not provided

python:3.4-alpine (alpine 3.9.2)

Total: 37 (UNKNOWN: 0, LOW: 4, MEDIUM: 16, HIGH: 13, CRITICAL: 4)
# 总计：37   （未知：0，低：4，中等：16，高：13，严重：4）
```

**扫描文件系统(扫描包含特定语言文件的本地项目)**

```shell
[root@harbor ~]# trivy fs /path/to/project

# Trivy将根据锁定文件（如Gemfile.lock和package-lock.json）查找漏洞
[root@harbor ~]# trivy fs ~/src/github.com/aquasecurity/trivy-ci-test
```

**扫描根文件系统（例如主机、虚拟机映像或解压缩的容器映像文件系统）**

```shell
[root@harbor ~]# trivy rootfs /
```

**Git存储库**

```shell
[root@harbor ~]# trivy repo https://github.com/xxx/xxx
[root@harbor ~]#trivy repo --branch <branch-name> <repo-name>		# 扫描分支
```

**私有库**

```yaml
# 为了扫描私有 GitHub 或 GitLab 存储库，必须分别使用有权访问正在扫描的私有存储库的有效令牌设置环境变量或
GITHUB_TOKEN
GITLAB_TOKEN
```

**K8S**

```shell
[root@master1 ~]# trivy k8s --report summary cluster		# 扫描Kubernetes集群

[root@master1 ~]# trivy k8s --report=summary deploy			# 扫描所有的deploy并显示摘要信息

[root@master1 ~]# trivy k8s --report=all deploy				# 扫描所有的deploy并显示全部信息

[root@master1 ~]# trivy k8s --report=all deploy/xxx			# 扫描指定的deploy并显示全部信息

[root@master1 ~]# trivy k8s --namespace=default --report summary pods/nginx-deployment-68db55bfc6-5xsqp		# 扫描特定的Pod

[root@master1 ~]# trivy k8s --namespace=kube-system --report=summary configmaps
7 / 7 [------------------------------------------------------------------------] 100.00% 2 p/s

Summary Report for kubernetes-admin@kubernetes


Workload Assessment
┌───────────┬──────────┬───────────────────┬───────────────────┬───────────────────┐
│ Namespace │ Resource │  Vulnerabilities  │ Misconfigurations │      Secrets      │
│           │          ├───┬───┬───┬───┬───┼───┬───┬───┬───┬───┼───┬───┬───┬───┬───┤
│           │          │ C │ H │ M │ L │ U │ C │ H │ M │ L │ U │ C │ H │ M │ L │ U │
└───────────┴──────────┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘
Severities: C=CRITICAL H=HIGH M=MEDIUM L=LOW U=UNKNOWN

[root@master1 ~]# trivy k8s --namespace=kube-system --report=summary deploy		# 扫描kube-system名称空间的所有deployment
2 / 2 [------------------------------------------------------------------------] 100.00% 1 p/s

Summary Report for kubernetes-admin@kubernetes


Workload Assessment
┌─────────────┬────────────────────────────────────┬───────────────────┬────────────────────┬───────────────────┐
│  Namespace  │              Resource              │  Vulnerabilities  │ Misconfigurations  │      Secrets      │
│             │                                    ├───┬───┬───┬───┬───┼───┬───┬───┬────┬───┼───┬───┬───┬───┬───┤
│             │                                    │ C │ H │ M │ L │ U │ C │ H │ M │ L  │ U │ C │ H │ M │ L │ U │
├─────────────┼────────────────────────────────────┼───┼───┼───┼───┼───┼───┼───┼───┼────┼───┼───┼───┼───┼───┼───┤
│ kube-system │ Deployment/coredns                 │ 1 │ 3 │ 1 │ 1 │ 5 │   │   │ 3 │ 5  │   │   │   │   │   │   │
│ kube-system │ Deployment/calico-kube-controllers │ 1 │ 1 │   │   │ 1 │   │   │ 3 │ 10 │   │   │   │   │   │   │
└─────────────┴────────────────────────────────────┴───┴───┴───┴───┴───┴───┴───┴───┴────┴───┴───┴───┴───┴───┴───┘
Severities: C=CRITICAL H=HIGH M=MEDIUM L=LOW U=UNKNOWN
```

