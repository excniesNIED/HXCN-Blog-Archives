---
title: 龙虾跑路指南：从 OpenClaw 迁移到 Hermes Agent 保姆级教程
pubDatetime: 2026-04-17T00:00:00.000+08:00
slug: openclaw2hermes-migration
tags:
  - AI Agent
  - OpenClaw
  - Hermes Agent
  - Harness Engineering
  - macOS
category: 
  - 配置环境的日常
  - 折腾Linux的日常
description: OpenClaw 迁移到 Hermes Agent 保姆级教程，从趋势背景讲解 Hermes 的记忆与技能机制、OpenClaw 与 Hermes 的稳定性和安全差异、安装 Hermes、迁移配置、接入模型提供商和飞书机器人。适合想从 OpenClaw 平滑迁移的 AI Agent 用户。
---

## 这匹「马」为什么火了

Hermes Agent，2 月底开源，首月 2.2 万星。4 月 8 日 v0.8.0 发布后单日涨 6400 颗，总数突破 4.7 万，连续多天占据 GitHub 全球趋势榜首。大量 OpenClaw 用户正在往 Hermes 搬家。

简单说，Hermes 是个能积累经验的 AI 智能体：做完任务自动总结、存成可复用技能，下次碰到类似情况直接调用。兼容 200 多个大模型，Telegram/Discord/Slack 全平台接入，一条命令装好。

![Gaj Varma 与 Teknium 的推文](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/6E84E04BF785493F4A6BF3B209A591E4.webp)

用户 Gaj Varma 说，从 0.5 升到 0.8，OpenClaw 得花两三个小时修问题，Hermes 跑通 695 个 commit 零故障。创始人 Teknium 回复：「我倒想问 OpenClaw 到底干了啥，才让升级这么折腾。」

![林亦 LYi 的推文](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/C479815ADCD7AA6F4E7B94F24FE83678.webp)

林亦的实测：Hermes 碰到报错会一直尝试到有明确结果，不会莫名其妙停下来；而且省 token，聊很久上下文也就三四万，OpenClaw 同样场景早过十万。

社区里还有人把 Hermes 装在 Mac mini 上常驻，通过 SSH 和 Telegram 操控，汇总日历/Gmail/Todoist，再分派给 Claude Code 执行，结果同步回 Obsidian vault，全程无人值守。也有人 2.5 小时用它做出《百战天虫》克隆版，Agent 自己把物理引擎逻辑整理成了可复用的 skill 插件。

## Hermes 做了什么不一样的事

先理解一个词：Harness（马具）。在 AI 语境里，指的是连接模型和人类需求的控制框架。除去 Agent 的大脑（底层大模型），剩下的都归 Harness 管：往哪跑、跑多快、什么时候停。今年 2 月 OpenAI 发过一篇博客《Harness Engineering: Leveraging Codex in an Agent-First World》，行业共识是 Prompt Engineering 和 Context Engineering 都不够用了，需要更高一层的约束系统。自主权越大越容易跑偏，套合适的马具反而跑更远。

Hermes 由 Nous Research 开发，MIT 许可。Nous 定位去中心化 AI 研究实验室，同时在推进去中心化训练网络 Psyche。

和传统 Agent 最大的区别是自进化：一般 Agent 每次调用从零开始，Hermes 从完成过的任务里学东西，跨会话、跨平台保留记忆。给一句模糊指令比如"写一个抓数据然后画图的脚本"，它能自己拆任务、读报错、尝试修复、总结方案。官方口号「the agent that grows with you」，想把 AI 能力从一次性调用变成持续积累，数据和记忆留在用户自己手里而不是平台。

记忆噪音、技能质量、部署门槛都还在打磨，但方向已经清楚。

## 龙虾 vs 爱马仕

OpenClaw 是 2026 年初火起来的开源 AI Agent，标志是龙虾，做的事是让 LLM 能干活：工具调用、自动化执行、长期记忆、沙箱、多平台接入。像个开箱即用的数字管家。

两家在本地优先、数据不上云、走即时通讯入口这些方向上一致。分歧在路径：

**技能来源。** OpenClaw 靠人写：开发者用代码或 Prompt 定义 Skill，稳定可预测，但上限取决于你愿意手写多少。Hermes 靠涌现：完成复杂任务后自己抽方法存成 Skill，下次直接复用。

**记忆方式。** OpenClaw 本质是 RAG，知道信息在哪，需要时去取。Hermes 用分层记忆，额外建了一个用户模型，跨会话记住你的代码风格和技术栈偏好。

**团队背景。** Hermes 由 Nous Research 主导，团队工程和研究背景都比较硬，从一开始就走「opinionated」路线：Python 实现，核心 agent loop、记忆系统和技能生成机制集中、结构清晰，宁愿做小做精也不追求生态最大化。OpenClaw 早期病毒式增长，社区 PR 爆炸式涌入，Node.js/TypeScript 基础叠加海量插件，代码和技能生态迅速膨胀，维护难度急剧上升。

**代码质量与 CI 纪律。** OpenClaw 的主分支有时直接构建失败，PR 卡 CI、回归 bug 频发是常态，社区有帖子直接吐槽「缺乏基本的 DevOps 纪律」（无 staging、测试不充分、合并过快）。Hermes 仓库已积累 4k+ commits，但核心文件结构依然干净，release notes 经常出现「数百 commits + 大量 bug fixes 和 reliability enhancements」的描述，CI 投诉远少于 OpenClaw。即便 stars 数已逼近 9 万，也没有重蹈「PR 洪水 + CI 崩溃」的覆辙，社区主流评价是「更稳、更注重深度而非广度」。

**安全差距最明显。** OpenClaw 增长太快，生态（ClawHub）膨胀失控，启动崩溃、网关冻结等回归 bug 高频出现；已披露多个高危 CVE，CVE-2026-25253 的 CVSS 8.8 可一键 RCE；ClawHub 里多次被爆出恶意技能偷凭证。

![Summer Yue 讲述邮箱被 OpenClaw 一夜清空的经历](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/aba5968c-ca5c-4e95-a320-7d125ebe36eb.webp)

Meta 安全对齐总监 Summer Yue 明明设置了"操作前先确认"，OpenClaw 还是自行清空收件箱，她在手机上拦不住，最后冲回家手动停下来。Hermes 这边更保守，危险操作需人工批准（Tirith 预执行扫描器先检查终端命令），技能生态小、攻击面窄，到现在没出现类似的集中高危事件。

**Token 消耗。** 养虾人抱怨最多的就是烧钱和长程任务不靠谱，OpenClaw 跨 24 小时任务容易 token 烧完事情只干一半，或者某步走偏一路错到底。Hermes 用户反馈起手还是一万多 token，聊很久也能维持在三四万，同样场景 OpenClaw 早过 10 万；遇到错误会继续搞到明确成功或失败为止。

不过社区主流看法并非替代关系，而是互补：OpenClaw 干活，Hermes 动脑。常见做法是把 Hermes 当规划器挂在 OpenClaw 之上，`hermes claw migrate` 一行命令就能把现有技能、记忆和配置平滑搬过来。

下面就来介绍如何从 OpenClaw 迁移到 Hermes Agent。

## 从 OpenClaw 迁移到 Hermes Agent

本人此前在 macOS 上部署了 OpenClaw，现在同样在 macOS 终端里安装 Hermes。你也可以在 Linux 发行版甚至 Android（通过 Termux）上部署。如果你用的是 Windows，建议先[在 WSL2 上安装 Ubuntu](https://ain.hmgf.hxcn.space/sre/first-vm-2024#%E4%BD%BF%E7%94%A8-wsl-%E5%AE%89%E8%A3%85-ubuntu) 再进行部署，体验更佳。

### 1. 安装 Hermes Agent

首先运行在线安装脚本：

```bash
# Linux / macOS / WSL2 / Android (Termux)
curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
```

脚本会自动完成运行环境和 Skills 的安装，随后进入 Hermes Setup。Setup Wizard 检测到本机已安装 OpenClaw，提示可以在正式变更前先预览将要迁移的内容。输入 `Y` 继续，设置向导会列出全部可迁移项，包括但不限于配置（平台接入、设置等）、记忆（长期/短期记忆、SOUL.md 等）、技能（Skills）、API 密钥，以及部分会话历史（较新版本兼容性更好）。确认无误后再输入 `Y`，开始正式迁移：

```bash
Would you like to see what can be imported? [Y/n]: Y

◆ Migration Preview — 166 item(s) would be imported
  No changes have been made yet. Review the list below:

  Would import:
      soul                   → ~/.hermes/SOUL.md
      user-profile           → ~/.hermes/memories/USER.md
      provider-keys          → ~/.hermes/.env
      model-config           → ~/.hermes/config.yaml
      shared-skills          → ~/.hermes/skills/openclaw-imports/antfu
      shared-skills          → ~/.hermes/skills/openclaw-imports/brave-web-search
......
      personal-skills        → ~/.hermes/skills/openclaw-imports/xlsx
      shared-skill-category  → ~/.hermes/skills/openclaw-imports/DESCRIPTION.md
      daily-memory           → ~/.hermes/memories/MEMORY.md
      agent-config           → config.yaml agent/compression/terminal
      env-var                → .env HERMES_GATEWAY_TOKEN
      full-providers         → config.yaml custom_providers[minimax-portal]

  ── Warnings ──
    ⚠ Config values — OpenClaw settings may not map 1:1 to Hermes equivalents
    ⚠ Context file — may contain OpenClaw-specific instructions
    ⚠ Gateway/messaging — this will configure Hermes to use your OpenClaw messaging channels
    ⚠ Instruction file — may contain OpenClaw-specific setup/restart procedures
    ⚠ Memory/context file — may reference OpenClaw-specific infrastructure
    ⚠ Slack — this will point Hermes at your OpenClaw Slack workspace

  Note: OpenClaw config values may have different semantics in Hermes.
  For example, OpenClaw's tool_call_execution: "auto" ≠ Hermes's yolo mode.
  Instruction files (.md) from OpenClaw may contain incompatible procedures.

Proceed with migration? [y/N]: y
```

> 迁移工具默认只处理标准的 `workspace/` 路径。如果你在 OpenClaw 中使用了多个自定义 workspace（如 `workspace-project-a`），这些目录不会被自动迁移，需要额外操作。详见[常见问题：无法迁移其他 workspace](#无法迁移其他-workspace)。如果迁移完成后对话时出现 `AuthenticationError [HTTP 401]` 报错，请参阅[常见问题：认证报错](#认证报错-authenticationerror)。

### 2. 配置模型提供商

迁移完成后即进入设置阶段。设置向导会询问采用快速设置还是完整设置，这里使用 <kbd>↑</kbd><kbd>↓</kbd> 键选中快速设置（Quick setup），按 <kbd>Space</kbd> 勾选该选项，再按 <kbd>Enter</kbd> 进入下一步：

![image-20260418012955409](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418012955409.webp)

接着选择模型提供商。这里选择本人订阅的 ark（火山引擎编码计划），输入模型名 `ark-code-latest`：

![image-20260418013325785](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418013325785.webp)

你也可以根据自身需求选择其他供应商。如果此前没有订阅，推荐[购买 MiniMax Token Plan](https://platform.minimaxi.com/subscribe/token-plan?code=L5Ua6ZLLoY&source=link)。MiniMax M2.7 是目前 Hermes Agent 中使用量最高的模型之一，在工具调用准确度、复杂 Skills 遵循、Agent Harness 适配等方面表现俱佳，性价比也相当出色。此处可以暂时跳过，阅读[常见问题：设置多个模型提供商](#设置多个模型提供商)章节设置模型。

### 3. 配置聊天平台

接下来选择接入的聊天平台，这里选择飞书，然后通过 APP ID 登录，绑定飞书机器人：

![image-20260418013430828](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418013430828.webp)

本人在先前配置 OpenClaw 时已经创建过飞书机器人。如果你此前没有创建，请前往[飞书开放平台](https://open.feishu.cn/app)新建。登录飞书后，点击「创建企业自建应用」，填写应用名称和应用描述，可按个人喜好设置应用图标，然后点击「创建」：

![image-20260418014150010](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418014150010.webp)

点击左侧的「添加应用能力」，再点击「添加」机器人：

![image-20260418020151521](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418020151521.webp)

点击左侧的「事件与回调」，在「订阅方式」旁点击编辑按钮，将订阅方式设为「长连接」，然后点击「保存」：

![image-20260418015229088](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418015229088.webp)

仍在「事件与回调」页面，点击「添加事件」，搜索「接收消息」并勾选，点击添加，在弹窗中点击「确认开通权限」：

![image-20260418015803619](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418015803619.webp)

点击「权限管理」，选择「开通权限」，勾选全部权限，然后点击「确认开通权限」：

![image-20260418020425172](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418020425172.webp)

![image-20260418020446781](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418020446781.webp)

最后点击左侧的「版本管理与发布」，点击「创建版本」，填写版本号（如 1.0.0）和更新说明，点击「保存」，再点击「确认发布」：

![image-20260418020601681](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418020601681.webp)

![image-20260418020652380](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418020652380.webp)

![image-20260418020731932](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418020731932.webp)

![image-20260418020811484](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418020811484.webp)

点击「凭证与基础信息」。如果需要修改机器人信息，在此编辑相应字段即可（注意：修改后需要重新发布）：

![image-20260418021101878](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418021101878.webp)

随后分别复制 APP ID 和 APP Secret，依次粘贴到终端中：

![image-20260418013746135](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418013746135.webp)

选择飞书国内版：

![image-20260418013820810](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418013820810.webp)

连接模式选择「WebSocket」：

![image-20260418021214604](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418021214604.webp)

在「How should direct messages be authorized?」一项，选择默认的「Use DM pairing approval」：

![image-20260418021242947](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418021242947.webp)

在「How should group chats be handled?」一项，保持默认「Respond only when @mentioned in groups」即可——这表示只有在群聊中 @ 机器人时它才会响应。如果完全不需要在群聊中使用 Hermes，可以选择「Disable group chats」：

![image-20260418021343280](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418021343280.webp)

Home Chat ID 为可选项，用于将定时任务（Cron）的执行结果和提醒、系统通知、告警、工具执行输出、长期记忆更新或重要技能生成后的总结等统一推送到指定聊天平台。由于这里只接入了飞书，直接按 <kbd>Enter</kbd> 采用默认配置即可；如果接入了多个聊天平台，可按需指定。

![image-20260418021853819](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418021853819.webp)

### 4. 将网关注册为服务

将网关注册为系统服务后，Hermes 便能随系统开机自动启动，不再需要手动拉起。如果后续想要调整网关配置，可以随时执行下面命令重新进入网关设置：

```bash
hermes gateway setup
```

如果不希望将网关注册为系统服务，也可以选择前台运行 + tmux 常驻的方式，详见[常见问题：使用 tmux 让网关后台运行](#使用-tmux-让网关后台运行)。

#### MacOS

在 macOS 上，Hermes 会将网关注册为 launchd 服务。到这一步直接输入「Y」确认即可：

![image-20260418021920240](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418021920240.webp)

在「Start the service now?」提示处输入「Y」立即启动服务：

![image-20260418022036777](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418022036777.webp)

#### Linux

未完待续

### 5. 开始使用

至此，设置向导全部完成。此后若需重新调整配置，可随时执行：

```bash
hermes setup
```

随后向导会提示「Launch hermes chat now?」，输入 `Y` 即可启动 Hermes。当出现下图中的提示时，说明 Hermes 已经成功运行：

![image-20260418022548383](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418022548383.webp)

如果启动时遇到 `tirith security scanner enabled but not available` 报错导致直接退出，请参阅[常见问题：启动时 Tirith 报错](#启动时-tirith-报错)；如果对话时出现 `AuthenticationError [HTTP 401]` 报错，请参阅[常见问题：认证报错](#认证报错-authenticationerror)。

### 6. 绑定飞书

首次在飞书中给机器人发送消息，由于尚未完成身份配对，Hermes Agent 会回复 `Hi~ I don't recognize you yet!`，并附带一段一次性的配对码：

![image-20260524012459748](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260524012459748.webp)

此时新开一个终端，执行配对命令，将飞书账号与 Hermes Agent 关联起来（请将下面的占位符替换为飞书消息中收到的配对码）：

```bash
hermes pairing approve feishu <改为你的配对码>
```

终端返回类似下面的提示即说明配对成功：

```bash
excnies@HXCN-Win-Magic:~$ hermes pairing approve feishu EFS7PRQ6

  Approved! User 萑澈 (c*****a) on feishu can now use the bot~
  They'll be recognized automatically on their next message.
```

回到飞书再次发送消息，机器人即可正常响应：

![image-20260524013020255](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260524013020255.webp)

## 常见问题

### 设置多个模型提供商

新开一个干净的终端窗口（Terminal 或 iTerm2 均可），输入以下命令并回车：

```bash
hermes model
```

在弹出的界面中使用 <kbd>↑</kbd><kbd>↓</kbd> 键选中快速设置（Quick setup），按 <kbd>Space</kbd> 勾选后再按 <kbd>Enter</kbd>。以 MiniMax Token Plan 为例，选择 MiniMax China：

![image-20260418151551231](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418151551231.webp)

接下来填入 API Key。前往 [MiniMax Token Plan 开放平台](https://platform.minimaxi.com/user-center/payment/token-plan) 复制密钥：

![image-20260418151742782](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418151742782.webp)

然后粘贴到终端：

![image-20260418151822881](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418151822881.webp)

随后提示设置 BaseURL，这里直接按 <kbd>Enter</kbd> 使用默认值，然后选择模型 `MiniMax-M2.7`：

![image-20260418152012768](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418152012768.webp)

终端提示 `Default model set to: MiniMax-M2.7 (via MiniMax (China))`，模型设置完成。

### 启动时 Tirith 报错

如果启动 Hermes 时遇到以下报错并直接退出：

```bash
  ⚠ tirith security scanner enabled but not available — command scanning will use pattern matching only

Goodbye! ⚕
```

请关闭当前终端，新开一个终端窗口，执行下面的命令，即可正常进入聊天界面：

```bash
hermes chat
```

如果仍然失败，重新执行一次 setup（向导会跳过已完成的步骤，或让你重新确认配置）：

```bash
hermes setup
```

### 认证报错 `AuthenticationError`

如果对话时出现 `API call failed (attempt 1/3): AuthenticationError [HTTP 401]` 报错：

![image-20260418152644914](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418152644914.webp)

原因可能是此前使用了 Clawx 等第三方 OpenClaw 客户端。这类客户端并不会把 API Key 明文存入 OpenClaw 的配置文件，因此迁移时无法读取到密钥。使用下面的命令编辑环境变量文件：

```bash
vim ~/.hermes/.env
```

以本人订阅的火山引擎编码计划为例，对应的环境变量是 `ARK_API_KEY`。核对后发现该值确实为空，填入正确的 Key 即可：

![image-20260418153204888](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418153204888.webp)

### 使用 tmux 让网关后台运行

如果不希望将 Hermes 注册为系统服务，最直接的办法是手动拉起网关：

```bash
$ hermes gateway run
┌─────────────────────────────────────────────────────────┐
│           ⚕ Hermes Gateway Starting...                 │
├─────────────────────────────────────────────────────────┤
│  Messaging platforms + cron scheduler                    │
│  Press Ctrl+C to stop                                   │
└─────────────────────────────────────────────────────────┘
```

但这种方式需要终端持续保持开启，一旦关闭窗口，网关也会随之停止。相比 screen、nohup 等老牌方案，tmux 更现代、用法更简单、配置也更可靠，会话与终端完全解耦，关掉窗口、断开 SSH 都不会影响里面运行的进程，需要查看时随时重新接入即可，因此推荐配合 **tmux** 让网关在后台常驻。

如果系统中尚未安装 tmux，按所用发行版执行对应命令安装：

```bash
# macOS（需先安装 Homebrew）
brew update && brew install tmux

# Debian 系（Debian / Ubuntu / Kali / Pop!_OS 等）
sudo apt update && sudo apt install tmux -y

# RHEL 系（CentOS / Rocky Linux / openEuler / Fedora 等）
sudo dnf makecache && sudo dnf install tmux -y

# Arch 系（Arch Linux / Manjaro / CachyOS 等）
sudo pacman -Syu tmux

# SUSE 系（openSUSE Leap / Tumbleweed / SLES 等）
sudo zypper refresh && sudo zypper install tmux
```

随后新建一个名为 `hermes` 的会话，并在其中启动网关：

```bash
tmux new -s hermes 'hermes gateway run'
```

启动后按 <kbd>Ctrl</kbd>+<kbd>b</kbd>，再按 <kbd>d</kbd> 即可 detach，把会话挂到后台。需要查看运行状态时，重新接入：

```bash
tmux attach -t hermes
```

查看当前所有 tmux 会话：

```bash
tmux ls
```

不再需要这个网关进程时，直接杀掉对应会话即可：

```bash
tmux kill-session -t hermes
```

如果环境受限无法使用 tmux，可改用更传统的会话工具作为兜底方案，具体用法参见下一节[用传统会话让网关后台运行](#用传统会话让网关后台运行)。

### 用传统会话让网关后台运行

[上一节](#使用-tmux-让网关后台运行)推荐使用 tmux 让 `hermes gateway run` 在后台常驻。如果所处环境无法安装 tmux，screen 和 nohup 也可以作为兜底方案。

**screen** 是更早期的终端复用工具，部分老旧发行版自带，使用习惯与 tmux 接近。启动并进入名为 `hermes` 的会话：

```bash
screen -S hermes hermes gateway run
```

挂起会话按 <kbd>Ctrl</kbd>+<kbd>a</kbd>，再按 <kbd>d</kbd>；想重新接入时执行：

```bash
screen -r hermes
```

查看所有 screen 会话，以及结束指定会话分别是：

```bash
screen -ls
screen -X -S hermes quit
```

**nohup** 则胜在开箱即用、几乎所有发行版都自带，配合 `&` 即可让进程脱离终端在后台运行，缺点是日志和进程管理都较为简陋。启动命令如下：

```bash
nohup hermes gateway run > ~/.hermes/hermes.log 2>&1 &
```

实时查看运行日志：

```bash
tail -f ~/.hermes/hermes.log
```

停止后台进程：

```bash
pkill -f "hermes gateway run"
```

### 无法迁移其他 workspace

执行 `hermes claw migrate --dry-run` 时，可能会看到 `workspace-agents  No workspace target was provided` 这类提示，并且某些自定义 workspace 没有被识别：

```bash
user@Mac ~ % hermes claw migrate --dry-run

┌─────────────────────────────────────────────────────────┐
│          ⚕ Hermes — OpenClaw Migration                 │
└─────────────────────────────────────────────────────────┘


◆ Migration Settings
  Source:      /Users/user/.openclaw
  Target:      /Users/user/.hermes
  Preset:      full
  Overwrite:   no (skip conflicts)
  Secrets:     yes (allowlisted only)


✗ Hermes gateway is running with active connections: feishu
  Migrating bot tokens while the gateway is active will cause conflicts (Telegram, Discord, and Slack only allow one active session per token).
  Recommendation: stop the gateway first with 'hermes stop'.

Continue anyway? [y/N]: y


◆ Migration Preview — 7 item(s) would be imported
  No changes have been made yet. Review the list below:


◆ Dry Run Results
  No files were modified. This is a preview of what would happen.

  ✓ Would migrate:
      user-profile           → ~/.hermes/memories/USER.md
      daily-memory           → ~/.hermes/memories/MEMORY.md
      agent-config           → config.yaml agent/compression/terminal
      env-var                → .env HERMES_GATEWAY_TOKEN
      env-var                → .env ARK_API_KEY
      env-var                → .env UNICOM_CLOUD_API_KEY
      env-var                → .env MINIMAX_PORTAL_API_KEY

  ⚠ Conflicts (skipped — use --overwrite to force):
      soul                    Target exists and overwrite is disabled
      provider-keys           Destination .env already has different values
      model-config            Model already set and overwrite is disabled
      shared-skills           Destination skill already exists
      ......
      personal-skills         Destination skill already exists
      full-providers          Provider 'ark' already exists
      full-providers          Provider 'unicom-cloud' already exists
      full-providers          Provider 'minimax-portal' already exists

  ─ Skipped:
      workspace-agents        No workspace target was provided
      memory                  Source file not found
      ......

  Summary: 7 would migrate, 157 conflict(s), 23 skipped

  To execute the migration, run without --dry-run:
    hermes claw migrate --preset full
user@Mac ~ % ls .openclaw
agents                  extensions              openclaw.json.bak.2     update-check.json
browser                 identity                openclaw.json.bak.3     wechat-access-guid
canvas                  logs                    openclaw.json.bak.4     workspace
completions             media                   openclaw_副本.json      workspace-project-a
cron                    memory                  qqbot                   workspace-project-b
delivery-queue          openclaw.json           skills
devices                 openclaw.json.bak       subagents
exec-approvals.json     openclaw.json.bak.1     tasks
```

在 Hermes 官方的迁移逻辑中，`hermes claw migrate` 默认只会查找标准的 `workspace/` 或 `workspace-main/` 路径。由于 OpenClaw 的多 Agent 架构会将不同的工作区存储在类似 `workspace-project-a` 或 `workspace-project-b` 这样的独立目录下，迁移工具在没有明确指引时会跳过这些「非标」路径（即上面看到的 `workspace-agents No workspace target was provided`）。

要迁移这些额外的 workspace，需要采取**分步指定目标**或**手动补齐**的策略。

#### 方法一：指定目标路径（推荐）

使用 `--workspace-target` 参数，针对每个特定的 workspace 运行一次迁移命令，手动指定其目标位置：

```bash
# 迁移 workspace-project-a 到指定的 Hermes 目录
hermes claw migrate --preset full \
  --source ~/.openclaw/workspace-project-a \
  --workspace-target ~/.hermes/workspaces/project-a
```

> **注意**：如果该 workspace 中包含 API Key（`.env` 文件），请记得带上 `--migrate-secrets` 标志。

#### 方法二：手动搬运

由于 Hermes 的核心架构（如 `SOUL.md` 和 `MEMORY.md`）与 OpenClaw 高度兼容，自动化工具识别不到时，手动复制关键文件通常是最快最稳妥的办法。

对于上面列出的 `workspace-project-a` 等目录，手动迁移路径如下：

| OpenClaw 源文件（每个 workspace 下） | Hermes 目标路径 | 说明 |
| --- | --- | --- |
| `SOUL.md` | `~/.hermes/memories/SOUL_{name}.md` | 代理的人格定义 |
| `MEMORY.md` | `~/.hermes/memories/MEMORY.md`（追加） | 长期记忆（建议合并） |
| `USER.md` | `~/.hermes/memories/USER.md` | 用户画像信息 |
| `skills/` | `~/.hermes/skills/` | 自定义技能脚本 |

操作建议：

1. **合并记忆**：将不同 workspace 下的 `MEMORY.md` 内容复制并粘贴到 `~/.hermes/memories/MEMORY.md` 中。Hermes 在启动时会自动对内容进行语义去重。
2. **迁移技能**：直接将 `.openclaw/skills` 下的文件夹拷贝到 `.hermes/skills` 下。

也可以直接在终端中，让 Hermes 主动读取和迁移关键文件：

```
@~/.openclaw中有三个工作区，分别为workspace、workspace-1、workspace-2，请
1. 将SOUL.md完整继承到~/.hermes/hermes-persona.md，USER.md完整继承到~/.hermes/memories/USER.md ，skills/完整继承到~/.hermes/skills/
2. memory/ 保存的记忆完整继承到~/.hermes/memories/MEMORY.md，
2. TOOLS.md主要部分继承到~/.hermes/AGENTS.md，如工具使用习惯、约定、本地路径、偏好（如 “用 pnpm”、“避免某些命令”）等，
3. 具体工具使用细节在~/.hermes/skills/ 目录下创建 SKILL.md 文件，并在~/.hermes/AGENTS.md严格且详细规定使用工具使用 skills 完成任务
4. 继承配置文件时务必确保内容完整详细，而不是将内容总结后进行继承
```

![image-20260521151429812](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260521151429812.webp)

#### 方法三：处理冲突

Dry Run 中出现大量 `Conflict (skipped)`，是因为 `.hermes` 目录下已存在同名文件。如果确定以 OpenClaw 的配置为准覆盖现有 Hermes 配置，在命令中加入 `--overwrite`：

```bash
hermes claw migrate --preset full --overwrite --migrate-secrets
```

#### 推荐操作流

1. **停止 Gateway**：先运行 `hermes stop`，避免出现 feishu 连接冲突。
2. **全量强制迁移一次**：

   ```bash
   hermes claw migrate --preset full --overwrite --migrate-secrets
   ```

3. **针对特殊 workspace 补录**：手动将 `workspace-project-a` 和 `workspace-project-b` 里的 `SOUL.md` 或 `AGENTS.md` 内容补充到 Hermes 的相应配置文件或 `memories` 文件夹中。
