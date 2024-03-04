---
title: Git分布式版本控制
tags: Git
cover: img/fengmian/git.png
abbrlink: a13195e8
categories: Git
date: 2022-07-04 23:11:31
---
# Git概述

官网：https://git-scm.com/

Git 是一个免费和开源的 分布式版本控制系统，旨在以速度和效率处理从小型到大型项目的所有内容。

Git易于学习， 占用空间小，性能快如闪电。它优于 SCM 工具，如 Subversion、CVS、Perforce 和 ClearCase，具有廉价的本地分支、方便的暂存区域和 多个工作流等功能。

其功能：

- 记录代码的变更(记录开发过程的变更和进程)
- 实现多人协作(多人的代码进行合并)

## 版本控制

版本控制是一种记录一个或若干文件内容变化，以便将来查阅特定版本修订情况的系统

可以将选定的文件回溯到之前的状态，甚至将整个项目都回退到过去某个时间点的状态，你可以比较文件的变化细节，查出最后是谁修改了哪个地方，从而找出导致怪异问题出现的原因，又是谁在何时报告了某个功能缺陷等等。 使用版本控制系统通常还意味着，就算你乱来一气把整个项目中的文件改的改删的删，你也照样可以轻松恢复到原先的样子。 但额外增加的工作量却微乎其微

**从个人开发过渡到团队协作的**

### 本地版本控制

复制整个项目目录的方式来保存不同的版本，并改名加上备份时间以示区别，有时候会混淆所在的工作目录，一不小心会写错文件或者覆盖意想外的文件。

为了解决这个问题，人们很久以前就开发了许多种本地版本控制系统，大多都是采用某种简单的数据库来记录文件的历次更新差异。

![本地版本控制图解](local.png)



### 集中式版本控制

如何让在不同系统上的开发者协同工作？ 于是，集中化的版本控制系统（Centralized Version Control Systems，简称 CVCS）应运而生。 这类系统，诸如 CVS、Subversion 以及 Perforce 等，都有一个单一的集中管理的服务器，保存所有文件的修订版本，而协同工作的人们都通过客户端连到这台服务器，取出最新的文件或者提交更新。 多年以来，这已成为版本控制系统的标准做法。

![集中化的版本控制图解](centralized.png)

这种做法带来了许多好处，特别是相较于老式的本地 VCS 来说。 现在，每个人都可以在一定程度上看到项目中的其他人正在做些什么。 而管理员也可以轻松掌控每个开发者的权限，并且管理一个 CVCS 要远比在各个客户端上维护本地数据库来得轻松容易。

事分两面，有好有坏。 这么做最显而易见的缺点是中央服务器的**单点故障**。 如果宕机一小时，那么在这一小时内，谁都无法提交更新，也就无法协同工作。 **如果中心数据库所在的磁盘发生损坏，又没有做恰当备份，毫无疑问你将丢失所有数据**——包括项目的整个变更历史，只剩下人们在各自机器上保留的单独快照。 本地版本控制系统也存在类似问题，只要整个项目的历史记录被保存在单一位置，就有丢失所有历史更新记录的风险。

### 分布式版本控制

客户端并不只提取最新版本的文件快照， 而是把代码仓库完整地镜像下来，包括完整的历史记录。 这么一来，任何一处协同工作用的服务器发生故障，事后都可以用任何一个镜像出来的本地仓库恢复。 因为每一次的克隆操作，实际上都是一次对代码仓库的完整备份。

![分布式版本控制图解](distributed.png)

许多这类系统都可以指定和若干不同的远端代码仓库进行交互。籍此，你就可以在同一个项目中，分别和不同工作小组的人相互协作。 你可以根据需要设定不同的协作流程，比如层次模型式的工作流，而这在以前的集中式系统中是无法实现的。

- 服务器断网的情况下也可以进行开发（版本控制是在本地进行的）
- 每个客户端保存的也都说完整的项目（包含历史记录，更加安全）



# 基本命令

## 用户签名

签名的作用是区分不同操作者的身份。用户的签名信息在每一个版本的提交信息中能够看到，以此确认此次提交是谁做的。Git首次安装需要设置用户签名，否则无法提交代码(和代码托管中心的账号没有关系)

```shell
# 设置用户名
git config --global user.name 用户名
# 设置邮箱
git config --global user.email 邮箱
# 列出Git当前能找到的配置
git config --list
```

## 初始化

一个项目只需要初始化一次本地库即可，可通过项目目录查看是否有.git目录来辨别是否初始化过

```shell
$ git init -h
用法：git init [-q | --quiet] [--bare] [--template=<template-directory>] [--shared[=<permissions>]] [<directory>]

     --template <模板目录>
                           将使用模板的目录
     --bare 创建一个裸仓库
     --shared[=<权限>]
                           指定 git 存储库将在多个用户之间共享
     -q, --quiet 安静
     --separate-git-dir <gitdir>
                           将 git 目录与工作树分开
     -b, --initial-branch <名称>
                           覆盖初始分支的名称
     --object-format <哈希>
                           指定要使用的哈希算法
# 不指定即当前目录
```

## 查看状态

通过查看状态对文件进行检查是否提交，如果文件没有进行提交，则不允许进行下一步操作包括创建分支、拉取代码、切换分支等等。

```shell
$ git status -h
用法：git status [<options>] [--] <pathspec>...

    -v, --verbose 详细
    -s, --short 简明地显示状态
    -b, --branch 显示分支信息
    --show-stash 显示存储信息
    --ahead-behind 计算完整的提前/落后值
    --porcelain[=<版本>]
                          机器可读的输出
    --long 以长格式显示状态（默认）
    -z, --null 以 NUL 终止条目
    -u, --untracked-files[=<模式>]
                          显示未跟踪的文件，可选模式：全部、正常、否。 （默认：全部）
    --ignored[=<mode>] 显示被忽略的文件，可选模式：传统、匹配、否。 （默认：传统）
    --ignore-submodules[=<何时>]
                          忽略对子模块的更改，可选时：全部、脏、未跟踪。 （默认：全部）
    --column[=<style>] 按列列出未跟踪的文件
    --no-renames 不检测重命名
    -M, --find-renames[=<n>]
                          检测重命名，可选择设置相似度索引
    --no-lock-index （已弃用：使用 `git --no-optional-locks status` 代替）不要锁定索引
```

```shell
Tao@DESKTOP-41ETPE3 MINGW64 /e/code (master)
$ git status
在主分支

还没有提交

无需提交（创建/复制文件并使用“git add”进行跟踪）
```

## 添加命令

将工作区变更的文件提交至暂存区

```shell
$ git add -h
用法： git add [<options>] [--] <pathspec>...

    -n, --dry-run 试运行
    -v, --verbose 详细

    -i, --interactive 交互式拾取
    -p, --patch 以交互方式选择帅哥
    -e, --edit 编辑当前差异并应用
    -f, --force 允许添加其他被忽略的文件
    -u, --update 更新跟踪的文件
    --renormalize 重新规范化跟踪文件的 EOL（隐含 -u）
    -N, --intent-to-add 只记录后面要添加的路径
    -A, --all 添加所有已跟踪和未跟踪文件的更改
    --ignore-removal 忽略工作树中删除的路径（与 --no-all 相同）
    --refresh 不添加，只刷新索引
    --ignore-errors 只是跳过由于错误而无法添加的文件
    --ignore-missing 检查是否 - 甚至丢失 - 文件在试运行中被忽略
    --sparse 允许更新稀疏结帐锥之外的条目
    --chmod (+|-)x 覆盖列出文件的可执行位
    --pathspec-from-file <文件>
                          从文件中读取路径规范
    --pathspec-file-nul 和 --pathspec-from-file，pathspec 元素用 NUL 字符分隔
```

示例：

```shell
Tao@DESKTOP-41ETPE3 MINGW64 /e/code (master)
$ git add 1.txt
warning: in the working copy of '1.txt', LF will be replaced by CRLF the next time Git touches it
# 对换行符进行转换
Tao@DESKTOP-41ETPE3 MINGW64 /e/code (master)
$ git status
On branch master

No commits yet

Changes to be committed:
  (use "git rm --cached <file>..." to unstage)
        new file:   1.txt


Tao@DESKTOP-41ETPE3 MINGW64 /e/code (master)

```

## 删除命令

```shell
$ git rm -h
用法： git rm [<options>] [--] <file>...

     -n, --dry-run 试运行
     -q, --quiet 不列出删除的文件
     --cached 仅从索引中删除
     -f, --force 覆盖最新检查
     -r 允许递归删除
     --ignore-unmatch 即使没有匹配项也以零状态退出
     --sparse 允许更新稀疏结帐锥之外的条目
     --pathspec-from-file <文件>
                           从文件中读取路径规范
     --pathspec-file-nul 和 --pathspec-from-file，pathspec 元素用 NUL 字符分隔
```

## 提交命令

```shell
$ git commit -h
用法：git commit [<options>] [--] <pathspec>...

    -q, --quiet 成功提交后抑制摘要
    -v, --verbose 在提交消息模板中显示差异

Commit message options
    -F, --file <file> 从文件中读取消息
    --author <author> 覆盖提交的作者
    --date <date> 覆盖提交的日期
    -m, --message <消息>
                          提交信息
    -c, --reedit-message <提交>
                          重用和编辑来自指定提交的消息
    -C, --reuse-message <提交>
                          重用来自指定提交的消息
    --fixup [(修正|reword):]提交
                          使用 autosquash 格式的消息来修复或修改/改写指定的提交
    --squash <commit> 使用自动压缩格式的消息来压缩指定的提交
    --reset-author 提交现在由我创作（与 -C/-c/--amend 一起使用）
    --trailer <trailer> 添加自定义预告片
    -s, --signoff 添加一个 Signed-off-by 预告片
    -t, --template <文件>
                          使用指定的模板文件
    -e, --edit 强制编辑提交
    --cleanup <mode> 如何去除消息中的空格和#comments
    --status 在提交消息模板中包含状态
    -S, --gpg-sign[=<key-id>]
                          GPG 签署提交

Commit contents options
    -a, --all 提交所有更改的文件
    -i, --include 将指定文件添加到索引以进行提交
    --interactive 交互式添加文件
    -p, --patch 以交互方式添加更改
    -o, --only 只提交指定的文件
    -n, --no-verify 绕过 pre-commit 和 commit-msg 钩子
    --dry-run 显示将要提交的内容
    --short 简明扼要地显示状态
    --branch 显示分支信息
    --ahead-behind 计算完整的提前/落后值
    --porcelain 机器可读输出
    --long 以长格式显示状态（默认）
    -z, --null 以 NUL 终止条目
    --amend 修改之前的提交
    --no-post-rewrite 绕过 post-rewrite 钩子
    -u, --untracked-files[=<模式>]
                          显示未跟踪的文件，可选模式：全部、正常、否。 （默认：全部）
    --pathspec-from-file <文件>
                          从文件中读取路径规范
    --pathspec-file-nul 和 --pathspec-from-file，pathspec 元素用 NUL 字符分隔
```

## 查看日志

```shell
$ git log -h
用法：git log [<options>] [<revision-range>] [[--] <path>...]
    或： git show [<options>] <object>...

     -q, --quiet 抑制差异输出
     --source 显示源
     --use-mailmap 使用邮件映射文件
     --mailmap 别名 --use-mailmap
     --decorate-refs <模式>
                           只装饰匹配 <pattern> 的 refs
     --decorate-refs-exclude <模式>
                           不要装饰匹配 <pattern> 的 refs
     --decorate[=...] 装饰选项
     -L <range:file> 跟踪行范围 <start>,<end> 或 function :<funcname> in <file> 的演变
```

## 版本穿梭

```shell
# git reflog 查看版本信息
# git log 查看版本详细信息	
$ git reset -h
用法：git reset [--mixed | --软 | --硬 | --合并 | --keep] [-q] [<提交>]
   或： git reset [-q] [<tree-ish>] [--] <pathspec>...
   或： git reset [-q] [--pathspec-from-file [--pathspec-file-nul]] [<tree-ish>]
   或： git reset --patch [<tree-ish>] [--] [<pathspec>...]
   或：已弃用：git reset [-q] [--stdin [-z]] [<tree-ish>]

    -q, --quiet 安静，只报告错误
    --no-refresh 重置后跳过刷新索引
    --mixed 重置 HEAD 和索引
    --soft reset only HEAD
    --hard reset HEAD、索引和工作树
    --merge 重置 HEAD、索引和工作树
    --keep reset HEAD 但保留本地更改
    --recurse-submodules[=<重置>]
                          控制子模块的递归更新
    -p, --patch 以交互方式选择帅哥
    -N, --intent-to-add 仅记录删除的路径将在以后添加的事实
    --pathspec-from-file <文件>
                          从文件中读取路径规范
    --pathspec-file-nul 和 --pathspec-from-file，pathspec 元素用 NUL 字符分隔
    -z 已弃用（使用 --pathspec-file-nul 代替）：路径用 NUL 字符分隔
    --stdin 已弃用（使用 --pathspec-from-file=- 代替）：从 <stdin> 读取路径
```

```shell
# 指定文件回到某个版本
git checkout 版本号 文件名
```

# 分支

## 分支概述

使用分支意味着你可以把你的工作从开发主线上分离开来，以免影响开发主线。最简单的可以理解为副本

使用分支可以并行推进多个功能的开发，提高开发效率；例如某分支在开发的过程中出现Bug，不会对其他分支有影响；失败的分支可以删除重新开始

## 查看分支

```shell
git branch -v

git branch
```



## 创建分支

```shell
git branch 分支名
```

```shell
Tao@DESKTOP-41ETPE3 MINGW64 /e/code (master)
$ git branch -v
* master 96bceab there modify

Tao@DESKTOP-41ETPE3 MINGW64 /e/code (master)
$ git branch
* master

Tao@DESKTOP-41ETPE3 MINGW64 /e/code (master)
$ git branch hot-fix

Tao@DESKTOP-41ETPE3 MINGW64 /e/code (master)
$ git branch
  hot-fix
* master

Tao@DESKTOP-41ETPE3 MINGW64 /e/code (master)
```

## 切换分支

```shell
git checkout 分支名
```

```shell
Tao@DESKTOP-41ETPE3 MINGW64 /e/code (master)
$ git branch hot-fix

Tao@DESKTOP-41ETPE3 MINGW64 /e/code (master)
$ git branch
  hot-fix
* master

Tao@DESKTOP-41ETPE3 MINGW64 /e/code (master)
$ git checkout hot-fix
Switched to branch 'hot-fix'

Tao@DESKTOP-41ETPE3 MINGW64 /e/code (hot-fix)
```

## 合并分支

1.正常合并

```shell
 git merge 分支名
 
 -----------------------------
 # 注意如果要将分支合并到Master需切换到master在合并
```

 2.冲突合并

在合并分支时，两个分支在同一个文件的同一个位置有两条完全不相同的修改。Git无法替我们决定使用哪一个。必须人为决定代码内容

```shell
在手动合并之后会报错
需要手动修改文件确认需要合并的代码
之后手动添加到暂存区提交本地库
之后合并不需要指定文件名提交
```



# 远程仓库

## 别名

```shell
# 别名用于代替远程代码托管中心的连接
git remote add xiaowangc https://github.com/qq780312916/xiaowangc.git

# 例如将我的github地址取了一个别名叫做xiaowangc
```

## 推送

```shell
git push 别名 分支
```

```shell
$ git push xiaowangc master
warning: ----------------- SECURITY WARNING ----------------
warning: | TLS certificate verification has been disabled! |
warning: ---------------------------------------------------
warning: HTTPS connections may not be secure. See https://aka.ms/gcm/tlsverify for more information.
warning: ----------------- SECURITY WARNING ----------------
warning: | TLS certificate verification has been disabled! |
warning: ---------------------------------------------------
warning: HTTPS connections may not be secure. See https://aka.ms/gcm/tlsverify for more information.
Enumerating objects: 13, done.
Counting objects: 100% (13/13), done.
Delta compression using up to 16 threads
Compressing objects: 100% (7/7), done.
Writing objects: 100% (13/13), 999 bytes | 999.00 KiB/s, done.
Total 13 (delta 0), reused 0 (delta 0), pack-reused 0
To https://github.com/qq780312916/xiaowangc.git
 * [new branch]      master -> master
```

## 拉取

```shell
$  git pull xiaowangc master

# 存在两种情况
# 将远程(新)代码同步至本地仓库
# 在空仓库拉取到本地仓库，需先初始化git
```

```shell
$  git pull xiaowangc master
remote: Enumerating objects: 5, done.
remote: Counting objects: 100% (5/5), done.
remote: Compressing objects: 100% (3/3), done.
remote: Total 3 (delta 0), reused 0 (delta 0), pack-reused 0
Unpacking objects: 100% (3/3), 689 bytes | 43.00 KiB/s, done.
From https://github.com/qq780312916/xiaowangc
 * branch            master     -> FETCH_HEAD
   9b571ca..0a29e5d  master     -> xiaowangc/master
Updating 9b571ca..0a29e5d
Fast-forward
 2.txt | 1 +
 1 file changed, 1 insertion(+)
```

## 克隆

```shell
git clone 链接
# clone会进行代码的拉取、初始化本地仓库、创建别名
```

```shell
$ git clone https://github.com/qq780312916/xiaowangc.git
Cloning into 'xiaowangc'...
remote: Enumerating objects: 16, done.
remote: Counting objects: 100% (16/16), done.
remote: Compressing objects: 100% (10/10), done.
remote: Total 16 (delta 1), reused 12 (delta 0), pack-reused 0
Receiving objects: 100% (16/16), done.
Resolving deltas: 100% (1/1), done.
```













