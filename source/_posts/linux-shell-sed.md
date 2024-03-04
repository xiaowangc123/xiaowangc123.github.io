---
title: Sed流编辑器
tags:
  - Linux
  - Shell
categories: Linux
cover: img/fengmian/linux.png
abbrlink: da1d0783
date: 2023-07-17 14:39:29
---
# Sed流编辑器

Sed是一个流编辑器(Stream editor)，它可以对从标准输入流中得到的数据进行处理，然后把处理以后的结果输出到标准输出或者也可以把标准输出重定向到文件，对处理后的结果保存到磁盘文件中。sed只会对流经过它的数据流进行处理和编辑，而不会对原始文件做如何修改。

sed命令的两种形式：

```shell
$ some_command |sed 'edit commands'
# 从管道中读取输入数据

$ sed 'edit commands' files
# 使用命令行参数读取文件内容，而不是从标准输入中
```

当执行sed命令时，从输入文件中读取一行数据，并把这行数据复制一份保存在它内部的一个工作缓存中。sed命令把它的这个缓存叫做模式空间(pattern space)，所有的数据都是在这个缓存中被处理的，然后sed命令会根据指定的编辑命令对缓存中的数据进行处理。当处理完这行数据后，sed会读取下一行数据，重复整个过程直到所有的数据都被处理完为止。sed命令的特性是使用相同的一系列操作重复处理文件中的每一行文本。

单引号中的编辑命令`edit command`的一般形式为：`/pattern/action`

其中pattern是一个正则表达式，而pattern两侧的斜杠`/`作为分隔符限定了正则表达式的起始和结束的位置，通过这些表达式来确定我们要操作的数据的哪些部分

```shell
Action		描述
p			打印行(print)
d			删除行(delete)
s			用一个新的表达式替换旧的表达式(substitute
i or I		忽略大小写
w FILENAME	如果匹配成功，把结果写入到文件FILENAME中
num			只取代第num个匹配
```

```shell
字符				描述
.				 匹配一个任意字符
*				 匹配任意个在它前面的字符
[characters]	 匹配chatacters字符集合中的任意一个字符，也可以通过-指定字符的范围，也可以使用字符^取反
^				 匹配行的开始
$				 匹配行的结尾
\				 转义字符
```



```shell
sed 's/admin@xiaowangc.com/karry@xiaowangc/g' "$file" > "$file.$$"
```

```shell
# 上面的编辑命令的形式如下，其中pattern1被省略掉了
/pattern1/s/pattern2/pattern3/
# 所以执行的行为是s/pattern2/pattern3
```

pattern1，pattern2和pattern3都是正则表达式。pattern1是正则表达式pattern用来确定我们要操作的行，而s/pattern2/pattern3/可以整体看做action,意思把要操作的行数据中的pattern2替换为pattern3，在实际应用中，pattern1通常会被省略掉。就像上面一样。

替换命令`s`默认只会对行数据中的第一个匹配pattern2的字符串进行替换，所以如果一行中包含两个或两个以上的匹配字符而且希望把它们都替换掉，就需要在替换命令的结尾添加全局符号`g`(global)

## 多个匹配规则

两条编辑命令通过分号连接并且一起放在单引号中。第一条编辑命令替换了email地址，然后通过分号；添加了第二条编辑命令，把2019替换为2022并且指定了符号g进行全局替换。

还可以使用-e选项指定其他的编辑命令，或者使用-f选项通过文件指定编辑命令。

```shell
sed 's/admin@xiaowangc.com/karry@xiaowangc.com/g;s/2019/2022/g' "$file" > "$file.$$"
```

```shell
sed 's/admin@xiaowangc.com/karry@xiaowangc.com/g' -e 's/2019/2022/g' "$file" > "$file.$$"
```

```shell
sed -f xiaowangc.modify "$file" > "$file.$$"
```

## 删除指定行

```shell
cat -n /etc/passwd | sed '11d' | more		#删除第11行
```

```shell
cat -n /etc/passwd | sed '3,23d' 			# 删除第3行到26行
```

sed命令的默认行为是输出所有的数据，无论它是否被修改过。因此可以通过选项-n关闭这个默认行为，从而使得只有那些被明确要求打印的数据才会被输出。

```shell
cat -n /etc/passwd | sed -n '11p' | more
```

```shell
cat -n /etc/passwd | sed -n '3,23p' 
```

上面使用了`-n`和编辑命令`p`的组合，关闭了默认的打印功能，而命令p的作用是告诉sed命令打印某些行，因此通过使用它们的组合从一个文件中提取某些行或一个范围

## 取反

使用叹号`!`对地址范围进行取反

```shell
cat -n /etc/passwd | sed -n '2,23!p'
```

## 取奇数行

gun的sed命令支持一种叫做`address stepping`的寻址方式，通过它可以定位要操作的行是所有的单数行

```shell
cat -n /etc/passwd | sed -n '1~2p'   # 1 3 5 7
```

使用`1~2p`，其中数字1表示起始地址，波浪号后面的数字2叫做step increment，表示从上一次操作的行增加2行就可以得到这次操作的行。因为提取出文件中的奇数行，所以指定了起始行为1，step increment为2，然后使用打印命令p和选项-n输出/etc/passwd文件中所有奇数行。

```shell
cat -n /etc/passwd | sed -n '2~2p'   # 2 4 6 8 
```

```shell
cat -n /etc/passwd | sed -n '2~3p'	 # 2 5 8 11
```

## 删除注释行和空行

使用正则表达式来确定要操作的行。字符`^`表达的含义是匹配行的开始，因此正则表达式`^#`的意思是：如果某一行是以字符`#`开始的就匹配这一行

```shell
etc /etc/sysctl.conf | sed '/^#/d'
```

编辑命令`/^$/d`。正则表达式中字符`$`的含义正好与字符`^`相反，其代表的含义是匹配行的结尾。因此正则表达式`^$`的含义就是在行首和行尾没有任何字符，也就是一个空行

```shell
cat /etc/sysctl.conf | sed -e '/^#/' -e '/^$/d'
```

## 数字结尾

```shell
cat /etc/sysctl.conf | sed -n '/[0-9]$/p'
```

```shell
[a-z]			匹配一个小写字母
[A-Z]			匹配一个大写字母
[a-zA-Z]		匹配一个字母
[a-zA-Z0-9]		匹配一个字母或数字
```

## 在匹配的行头部加注释

正则表达式`.*swap.*`用于匹配中间包含`swap`字符前后不论是任意字符的行。`.`表示匹配除换行以外的任何单个字符，而`*`表示匹配零个或多个前导字符。因此当它们组合在一起时，`.*`表示匹配任意数量的任意字符。

```shell
cat /etc/fstab | sed -n 's/.*swap.*/#&/p'
```

正则表达式`#&`用于在匹配到符合条件的行头部添加`#`,字符`&`表示匹配到的字符串，在匹配到符合条件的行首添加`#`注释























