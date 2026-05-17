---
title: 使用 aerc + isync/mbsync + notmch 在 Arch 上管理本地邮件
created: 2026-05-17
updated: 2026-05-17
topics:
  - drafts
  - workflow
---

# 使用 aerc + isync + notmuch 在 Arch Linux 上管理本地邮件

本文记录我在 Arch Linux 上折腾终端邮件工作流的过程。目标是：在本地电脑上同步、索引、阅读和发送多个邮箱的邮件，同时避免把邮箱授权码明文写进配置文件里。

最终采用的方案是：

- pass / GPG: 管理邮箱授权码
- isync / mbsync: 通过 IMAP 把远程邮箱同步到本地 Maildir
- notmuch: 为本地邮件建立索引
- aerc: 在终端阅读、搜索、回复和发送邮件

这套方案的特点是工具之间职责分离。`mbsync` 只负责同步，`notmuch`  只负责索引和搜索，`aerc` 负责交互界面，`pass` 负责管理敏感凭证。

## 为什么选择这样的方案

我希望使用一个不依赖 KDE / Gnome 的桌面邮件管理方式。图形邮件客户端往往会把同步、数据库、界面、账户管理都放一起，使用上简单，但是迁移会收到客户端影响。终端邮件工作流更接近 Unix 工具组合的思想：每个工具只完成一件事情，通过配置文件和命令连接起来。

这套方案里，`aerc` 是终端邮件客户端，[官方 README](https://git.sr.ht/~rjarry/aerc) 里对它的定位就是 "an email client for your terminal"。它支持 `IMAP`、`Maildir`、`notmuch` 等多种后端，适合作为终端里的邮件前端。

`isync` 是同步工具，实际使用的命令叫做 `mbsync` 。[官方说明](https://isync.sourceforge.io/) 中，`isync` 是一个命令行邮箱同步程序，支持 `IMAP4` 和 `Maildir` ，同步内容包含新邮件、删除和 flag 状态，也适合 IMAP-disconnected mode ，也就是把远程 IMAP 邮箱离线同步到本地使用。

`notmuch` 是本地邮件索引、搜索和标签系统。[官方说明](https://notmuchmail.org/) 提到它可以把大量 `Maildir` 或 MH 格式的邮件进行 indexing, searching, reading, tagging ，并使用 `Xapian` 提供全文搜索能力。它本身也能读邮件，但这里主要用作 `aerc` 的搜索后端。

`pass` 是标准 Unix 风格密码管理器。它使用 GPG 加密每条密码，并把密码以普通目录树的形式存放在 `~/.password-store` 中。官方说明里也提到它可以结合 Git 使用，适合 Linux 、BSD 、 MacOS 上的轻量密码管理。


## 整体数据流

整个系统可以理解为四层：

- 远程邮件服务器: Gmail IMAP / QQ IMAP
- 同步层: `mbsync`
- 本地邮件目录:
  - `~/.local/share/mail/gmail/`
  - `~/.local/share/mail/qq/`
- 索引层: `notmuch`
- 交互层: `aerc`

其中密码读取链路是：

GPG 私钥 -> pass -> mail-pass 脚本 -> `mbsync` / `aerc`

`mbsync` 通过 `PassCmd` 调用外部命令读取密码。`aerc` 也支持通过 `source-cred-cmd` 或 `outgoing-cred-cmd` 调用外部命令读取凭证；[`aerc` 账户配置手册](https://git.sr.ht/~rjarry/aerc/tree/master/item/doc/aerc-accounts.5.scd) 明确说明了这些命令型凭据配置项。

## 安装基础工具

在 Arch Linux 上安装:

```bash
sudo pacman -S gnupg git isync notmuch aerc
```

几个包的作用如下：

- `pass`: 本地密码管理器
- `gnupg`: 为 `pass` 提供加密能力
- `git`: 给 `password-store` 做版本记录
- `isync`: 提供 `mbsync` 命令
- `notmuch`: 本地邮件索引器
- `aerc`: 终端邮件客户端

## 配置 `pass` 管理邮箱授权码

先创建 GPG 密钥:

```bash
gpg --full-generate-key
```


建议选择 `RSA 4096`，邮箱地址用自己常用邮箱。生成完成后查看密钥:

```bash
gpg --list-secret-keys --keyid-format lONG
```

初始化密码库:

```bash
pass init "你的名字 <邮箱>"
```

也可以用 GPG key id:

```bash
pass init ABCD1234567890
```

启用 git 记录:

```bash
pass git init
```

我的密码条目组织方式如下:

```
Password Store
└── mail
    ├── 163
    │   └── imap-password
    ├── gmail
    │   └── app-password
    └── qq
        └── imap-password
```


保存 Gmail 应用专用密码:

```bash
pass insert mail/gmail/app-password
```

保存 QQ 邮箱授权码:

```bash
pass insert mail/qq/imap-password
```

读取测试:

```bash
pass show mail/gmail/app-password
pass show mail/qq/imap-password
```

为了让 `mbsync` 和 `aerc` 的配置更简洁，我创建了一个小脚本:

```bash
mkdir -p ~/.local/bin
nvim ~/.local/bin/mail-pass
```

写入:

```bash
#!/usr/bin/env bash
set -euo pipefail

pass show "$1" | head -n1
```

并通过 `chmod +x ~/.local/bin/mail-pass` 授予其执行权限。这里 `head -n1` 的意思是只取密码条目的第一行。`pass` 的条目可以存在多行，比如第一行是密码，后面写备注；但邮件工具只需要密码本身，因此输出第一行更稳定。

## 配置 `mbsync` 同步 Gmail

`mbsync` 的配置文件是:

```
~/.mbsyncrc
```

先创建本地邮箱目录：

```
mkdir -p ~/.local/share/mail/gmail/
chmod 700 ~/.local/share/mail ~/.local/share/mail/gmail/
```

Gmail 需要先在网页端开启 IMAP ，并使用应用专用密码。我们实际遇到过一个问题: `mbsync` 默认可能尝试 `XOAUTH2` ，但我们使用的是 Gmail 应用专用密码，因此需要强制 `LOGING` 。配置中使用：

```conf
AuthMechs LOGIN
```

Gmail 配置如下:

```conf
IMAPAccount gmail
Host imap.gmail.com
User 你的邮箱地址
PassCmd "mail-pass mail/gmail/app-password"
TLSType IMAPS
AuthMechs LOGIN

IMAPStore gmail-remote
Account gmail

MaildirStore gmail-local
Path ~/.local/share/mail/gmail
Inbox ~/.local/share/mail/gmail/INBOX
SubFolders Verbatim

Channel gmail
Far :gmail-remote:
Near :gmail-local:
Patterns INBOX Notes "[Gmail]/垃圾邮件" "[Gmail]/已删除邮件" "[Gmail]/已加星标" "[Gmail]/已发邮件" "[Gmail]/所有邮件" "[Gmail]/草稿" "[Gmail]/重要"
Create Near
SyncState *
Expunge None
Sync Pull
```

### 配置解释

- `IMAPAccount gmail` 定义一个远程 IMAP 账户，名字叫 `gmail` 。
- `Host imap.gmail.com` 是 Gmail 的 IMAP 服务器。
- `User 邮箱名` 是登陆用户名。
- `PassCmd` 这一行是执行命令获取密码。这样 `.mbsyncrc` 里就不会出现明文授权码。
- `TLSType IMAPS` 表示使用 IMAPS ，也就是通过 TLS 加密到 993 端口。
- `AuthMechs LOGING` 表示使用 LOGIN 认证机制。我们之前遇到过 `XOAUTH2` 报错，就让这一行后 Gmail 应用专用密码可以正常工作。
- `IMAPStore gmail-remote` 定义远程邮箱存储。
- `MaildirStore` 定义本地 `Maildir` 存储。
- `Path ~/.local/share/mail/gmail` 是本地邮箱根目录。
- `Inbox ~/.local/share/mail/gmail/INBOX` 指定本地 INBOX 目录。
- `SubFolders Verbatim` 表示保留远程邮箱层级命名。比如 Gmail 的 `[Gmail]/所有邮件` 会在本地对应到: `~/.local/share/mail/gmail/[Gmail]/所有邮件` 。
- `Channel gmail` 定义同步通道。
- `Far :gmail-remote:` 表示远端是 `gmail-remote` 。
- `Near :gmail-local:` 表示近端/本地是 `gmail-local` 。
- `Patterns ...` 表示要同步哪些 mailbox 。`Patterns` 可以选择一组 mailbox, 同时 `INBOX` 不会被通配符自动匹配，因此需要手动写出。
- `Create Near` 表示在远程存在、本地缺失的 mailbox 会在本地创建
- `SyncState *` 表示把同步文件保存在对应 mailbox 中。同步状态用于记录 UID、已同步状态等信息。
- `Expunge None` 表示同步时不主动删除状态。初期这样更安全。
