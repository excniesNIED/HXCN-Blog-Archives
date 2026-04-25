---
title: 我用 Cloudflare 搭了一个 FlashInbox 临时邮箱
pubDatetime: 2026-03-13T00:00:00.000+08:00
slug: build-flashinbox
tags:
  - Cloudflare
  - 临时邮箱
  - Workers
  - D1
  - 邮箱
category: 配置环境的日常
description: FlashInbox 私有临时邮箱部署教程，从零讲解 Cloudflare Workers、Email Routing、D1、Turnstile、域名路由、Secrets、邮件 Worker 和定时任务配置，并附常见收不到信的排查思路。适合想自建临时邮箱服务的用户。
---

我一直觉得，临时邮箱这种东西，能自己掌握还是自己掌握比较踏实。公共服务不是不能用，而是你用的时候总要多留个心眼：域名不是你的，地址不是你的，哪天规则变了、站点没了，或者数据清了，你也没什么办法。

刚好 `FlashInbox` 这套项目走的又是我比较喜欢的路线：前端 `Next.js`，部署在 Cloudflare Workers，收信靠 Cloudflare Email Routing，数据放进 `D1`。不需要自己折腾一整套传统邮件服务，成本和复杂度都低不少。

项目仓库在这里：`https://github.com/CtelSpecu/FlashInbox`

我这次就是把它从仓库拉下来，按自己的域名和 Cloudflare 环境跑了一遍。装完之后，手里会有一套自己的临时邮箱服务：能匿名创建地址，能收邮件，能认领邮箱拿 Key，也能靠 `username + key` 把邮箱找回来。默认 Key 有效期是 15 天，拿来收验证码、接通知、做注册测试都挺顺手。

最后大概会变成这样：网页在 `mail.example.com` 上打开，临时邮箱地址是 `bluepanda23@example.com` 这种形式，邮件能正常收进来，后台还能自己管域名、规则和隔离队列。

## FlashInbox 是什么

先把边界说清楚，免得装到一半才发现想要的根本不是这个。

`FlashInbox` 更像一个收件站，不是常规邮箱服务。它现在能做的事情主要有这些：

- 支持匿名创建临时邮箱
- 支持接收入站邮件
- 不存附件
- 支持认领邮箱并生成一次性明文 Key
- 支持用 `username + key` 恢复访问
- 提供一个管理后台

你如果想要的是“自己域名下的临时邮箱”，那这个方向没问题；如果想要的是“自己做一个 Gmail”，那就是另一回事了。

## 准备工作

先准备这些东西：

- 一个 Cloudflare 账号，并且已经开通 `Workers`、`D1`、`Email Routing`、`Turnstile`
- 一个已经接入 Cloudflare DNS 的域名，例如 `example.com`
- 本地环境里已经装好 `bun`
- 本地可以使用 `wrangler`

这里先记住一件事：Web 访问域名可以是 `mail.example.com`，真正收信的域名可以是 `example.com`。这两个域名最好分开，因为 Cloudflare Email Routing 的 catch-all 规则吃的是主域，不是 `mail.example.com` 这种 Web 子域。

## 架构先看明白

这套东西不是一个 Worker 从头跑到尾，而是三部分一起干活：

1. `flashinbox`
   这是主应用，负责网页、API、用户收件箱、管理后台。它读的是 `wrangler.toml`。

2. `flashinbox-email`
   这是入站邮件 Worker，负责接住 Email Routing 转过来的邮件，解析后写进 D1。它读的是 `wrangler.email.toml`。

3. `flashinbox-scheduled`
   这是定时任务 Worker，负责清理、统计之类的后台工作。它读的是 `wrangler.scheduled.toml`。

这三个 Worker 必须指向同一个 D1。很多“页面能打开但收不到信”的问题，最后查下来都不是代码坏了，而是这里没配对。

## 第 1 步：克隆仓库并安装依赖

先把仓库拉下来：

```bash
git clone https://github.com/CtelSpecu/FlashInbox.git
cd FlashInbox
```

```bash
bun install
```

项目里已经带了 `wrangler`，后面直接用 `bunx wrangler` 也行。

想先确认本地环境没问题，可以顺手看一眼 `package.json` 里的几个命令：

```bash
bun run build:worker
bun run dev
bun test
```

## 第 2 步：创建 D1

先登录：

```bash
wrangler login
```

再创建生产数据库：

```bash
wrangler d1 create flashinbox-db
```

执行完以后，Cloudflare 会返回一个 `database_id`。把它分别填到 `wrangler.toml`、`wrangler.email.toml` 和 `wrangler.scheduled.toml` 里。这三份配置里的 `database_id` 必须一致。只改主应用那一份不够，网页是能开，后台也可能能进，但邮件根本不会进到你以为的那个库里。

## 第 3 步：执行数据库迁移

接着把表建好：

```bash
wrangler d1 execute flashinbox-db --remote --file=migrations/0001_init.sql
wrangler d1 execute flashinbox-db --remote --file=migrations/0002_mailboxes_banned.sql
```

两条都跑，不要省。`0001_init.sql` 是基础表结构，`0002_mailboxes_banned.sql` 跟后台禁用邮箱的状态有关，少跑一条，后面多半要踩坑。

如果迁移时碰到 `BEGIN TRANSACTION`、`COMMIT` 之类的报错，说明迁移文件不符合 D1 的要求。当前仓库里的迁移文件已经处理过，照着跑通常没事。

## 第 4 步：配置域名

`wrangler.toml` 里有两个地方必须看：

1. 生产环境路由

例如：

```toml
[env.production]
name = "flashinbox"
routes = [
  { pattern = "mail.example.com", custom_domain = true }
]
```

2. 默认邮箱域名

例如：

```toml
[env.production.vars]
DEFAULT_DOMAIN = "example.com"
```

这两个值不是一回事。`mail.example.com` 是用户打开网页的地址，`example.com` 才是真正生成临时邮箱地址时用的收信域名。很多人第一次配的时候，脑子里只有一个“域名”，结果 Web 域名和收信域名搅在一起，后面查问题会非常累。

## 第 5 步：创建 Turnstile

`FlashInbox` 的认领流程用到了 Turnstile，所以这里先建一个站点，绑定主应用域名，比如 `mail.example.com`。建好之后，把 `TURNSTILE_SITE_KEY` 和 `TURNSTILE_SECRET_KEY` 记下来，后面填进主应用配置里。

## 第 6 步：配置 Secrets

接下来配主应用的 Secrets：

```bash
wrangler secret put ADMIN_TOKEN --env production
wrangler secret put KEY_PEPPER --env production
wrangler secret put SESSION_SECRET --env production
wrangler secret put TURNSTILE_SECRET_KEY --env production
wrangler secret put TURNSTILE_SITE_KEY --env production
```

这里最重要的是 `ADMIN_TOKEN`、`KEY_PEPPER` 和 `SESSION_SECRET`。前者是后台登录口令，后两个分别用于 Key 哈希和会话签名。尤其是 `KEY_PEPPER`，这个值别随便改，它跟 Key 哈希和恢复流程绑得很死。你改一次，旧 Key 基本就都失效了。

## 第 7 步：部署主应用

主应用这一层走的是 `Next.js + OpenNext + Cloudflare Workers`。

先构建：

```bash
bun run build:worker
```

再部署：

```bash
wrangler deploy --env production
```

跑到这里，站点本身应该已经能打开了，比如：

```text
https://mail.example.com
```

如果这时候网页都打不开，就别急着去查邮件链路，先把主应用的构建、路由和自定义域名检查完。

## 第 8 步：部署两个 Worker

主应用只是前台，收邮件和做清理的活，还得靠另外两个 Worker。

先部署 Email Worker：

```bash
wrangler deploy --config wrangler.email.toml
```

再部署 Scheduled Worker：

```bash
wrangler deploy --config wrangler.scheduled.toml
```

这一步特别容易漏，而且一漏就很容易把人带偏。页面能开，创建邮箱也不报错，乍一看像是已经部署好了，甚至会让人误以为后面只剩发邮件验证一下。等你真的往那个地址发一封测试邮件，才会发现收件箱安静得像没通电。

页面能开，不代表收信链路已经通了。

## 第 9 步：初始化 `domains`

这里也是高频坑。`FlashInbox` 的 Email Worker 不会见信就收，它会先查 D1 里的 `domains` 表，看这个域名是不是存在、是不是 `enabled`。表里没有，或者状态不对，邮件就进不来。

这个表有两种初始化办法。

### 方案 A：后台添加

部署完成后，访问：

```text
https://mail.example.com/admin
```

用 `ADMIN_TOKEN` 登录，在 Domains 页面里把 `example.com` 加进去，并设置为 `enabled`。

### 方案 B：写入 D1

```bash
wrangler d1 execute flashinbox-db --remote --command "INSERT INTO domains (name, status, note, created_at, updated_at) VALUES ('example.com', 'enabled', 'prod', strftime('%s','now')*1000, strftime('%s','now')*1000);"
```

如果你后面打算让多个域名一起收信，比如 `example.com` 和 `example.net`，那每个域名都得写进去，别指望一个默认值把所有事情包圆。

## 第 10 步：配置 Email Routing

下面开始配真正的收信链路。

在 Cloudflare Dashboard 里打开你的域名，进入 Email Routing，把下面几项配上：

- 启用 Email Routing
- 创建一条 Catch-all 规则
- Action 选择 `Send to a Worker`
- Worker 选择 `flashinbox-email`

逻辑很简单：别人发到 `anything@example.com` 的邮件，Cloudflare 先接住，再转给你的 Email Worker。

这里最容易混的是两件事：

1. Catch-all 针对的是主收信域名

也就是说，通常是 `example.com`，不是 `mail.example.com`。

2. 如果 Catch-all 没指向 Worker

那邮件就可能直接被丢掉，而且不一定给你多清楚的提示。很多时候你只能在 Activity log 里看到一个 `Dropped`。

## 第 11 步：验证收信

配置做完之后，最好马上测一遍。

先打开你的站点，创建一个临时邮箱。假设系统给你分配了：

```text
bluepanda23@example.com
```

然后拿另一个外部邮箱，往这个地址发一封测试邮件。

重点看三件事：前端能不能看到收件箱内容，管理后台里的域名状态是不是正常，以及 Cloudflare Email Routing 的 Activity log 里这封邮件有没有被正确投递。

如果前端没看到邮件，就按这个顺序排：

- `domains` 表里有没有 `example.com`
- 这个域名状态是不是 `enabled`
- Email Routing 的 Catch-all 是否真的指向了 `flashinbox-email`
- 三个 Worker 是否都已经部署
- 三份 Wrangler 配置是不是都绑到了同一个 D1

如果还不行，可以直接看 Email Worker 日志：

```bash
wrangler tail flashinbox-email
```

如果日志里出现 `Domain not found`、`Domain is disabled` 这种提示，就别猜了，直接回去查配置。

## 几个常见坑

### 1. 主站能开，不等于邮箱已经能收信

这是最容易让人误判的一点。网页能开，只代表主应用部署好了；真正决定能不能收信的，是 Email Routing、Email Worker 和 `domains` 表有没有一起对上。

### 2. 三个 Worker 必须共用同一个 D1

别把它们当成三个独立项目。对 `FlashInbox` 来说，这就是同一套系统的三个入口。

### 3. `DEFAULT_DOMAIN` 不是网页访问域名

它代表的是默认收信域名，不是网页访问域名。这个值写错，前端生成出来的邮箱地址就会跟你的预期不一致。

### 4. 附件不会保存

这不是 bug，而是项目本身就没打算存附件。收验证码、通知、注册链接都没问题，但别拿它当文件邮箱用。

### 5. Cloudflare Email Routing 有平台限制

大于 `25 MiB` 的邮件别指望它稳稳接住。这个上限不是 `FlashInbox` 自己定的，是 Cloudflare Email Routing 本身的限制。

## 适合哪些场景

这篇方案更适合下面这些场景：

- 你想用自己的域名收临时邮件
- 你不想继续依赖公共临时邮箱
- 你不想自己维护完整邮件服务器
- 你希望网页、收信、存储和后台都留在 Cloudflare 体系里

如果你的需求差不多就是这些，那 `FlashInbox` 值得花点时间装一下。

它当然不是正式办公邮箱的替代品，也不适合做复杂邮件协作。但如果你只是想把“临时邮箱”这件事握回自己手里，用自己的域名来收，用自己的后台来管，那这套东西已经够用了。
