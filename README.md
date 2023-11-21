# Git Log as Markdown Format
将 Git 提交日志以 Markdown 格式输出。

## 使用方法

```shell
$ chmod +x changelog.sh
$ copy changelog.sh /usr/local/bin
$ changelog.sh -v
v1.0.4
```

详细的使用方法请使用 `--help` 选项查看：

```shell
$ changelog.sh --help

USAGE
    changelog.sh [--since [VERSION]] [--until [VERSION]]

OPTIONS
    -h | --help)      Print help
    -v | --version)   Print version info
    -p | --prefix)    If provided, search all sub-folders with this prefix.
                      Otherwise process current directory.
    -s | --since)     Commit id from
    -u | --until)     Commit id to

EXAMPLES
    1. Generate all change logs between 1.0.1 and 1.0.2

        $ changelog.sh --since 1.0.1 --until 1.0.2

    2. Generate all change logs of version 1.0.2 from the very beginning

        $ changelog.sh --until 1.0.2

    3. Generate all change logs since version 1.0.2

        $ changelog.sh --since 1.0.2

```

## 举例

```shell
$ changelog.sh --until v1.0.0
[INFO] CHANGELOG will be written to file CHANGELOG-v1.0.0.md
```

打开 CHANGELOG-v1.0.0.md 之后效果如下（以 devbox 项目为例）：

`git log --no-merges --format="%h %ad %an %s" --date=short v1.0.0`

CHANGELOG FOR devbox

-----------------------

| COMMIT ID | COMMIT DATE | AUTHOR | COMMIT MSG.                                        |
| --------- | ----------- | ------ | -------------------------------------------------- |
| 46d29ed   | 2023-11-20  | eliu   | Change vagrant box to bento/centos-7               |
| 9802713   | 2023-11-20  | eliu   | Fix error: Unknown configuration section 'vbguest' |
| 0f01240   | 2023-11-17  | eliu   | 前端工具以单独的置备器提供                         |
| ad61b8b   | 2023-11-16  | eliu   | 解决各种兼容性问题                                 |
| 878a050   | 2021-03-09  | eliu   | add LICENSE.                                       |
| 095d3b3   | 2021-03-09  | eliu   | first commit                                       |



## 创作灵感

[如何生成 Markdown 格式的 Git 日志 | 楓の葉 (eliu.github.io)](https://eliu.github.io/2020/12/30/git-log-to-markdown/)



## 许可

Apache-2.0
