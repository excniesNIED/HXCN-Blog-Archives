# 龙虾跑路指南：从 OpenClaw 迁移到 Hermes Agent 保姆级教程

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

### 2. 配置模型提供商

迁移完成后即进入设置阶段。设置向导会询问采用快速设置还是完整设置，这里使用 <kbd>↑</kbd><kbd>↓</kbd> 键选中快速设置（Quick setup），按 <kbd>Space</kbd> 勾选该选项，再按 <kbd>Enter</kbd> 进入下一步：

![image-20260418012955409](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418012955409.webp)

接着选择模型提供商。这里选择本人订阅的 ark（火山引擎编码计划），输入模型名 `ark-code-latest`：

![image-20260418013325785](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418013325785.webp)

你也可以根据自身需求选择其他供应商。如果此前没有订阅，推荐[购买 MiniMax Token Plan](https://platform.minimaxi.com/subscribe/token-plan?code=L5Ua6ZLLoY&source=link)。MiniMax M2.7 是目前 Hermes Agent 中使用量最高的模型之一，在工具调用准确度、复杂 Skills 遵循、Agent Harness 适配等方面表现俱佳，性价比也相当出色。此处可以暂时跳过，阅读 [6. 设置多个模型提供商](#6. 设置多个模型提供商) 章节设置模型。

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

### 4. 将网关注册为 launchd 服务

将网关注册为系统服务后，Hermes 便可在电脑开机时自动启动。输入「Y」确认即可：

![image-20260418021920240](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418021920240.webp)

在「Start the service now?」提示处输入「Y」立即启动服务：

![image-20260418022036777](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418022036777.webp)

### 5. 开始使用

至此，设置向导全部完成。此后若需重新调整配置，可随时执行：

```bash
hermes setup
```

随后向导会提示「Launch hermes chat now?」，输入 `Y` 即可启动 Hermes。当出现下图中的提示时，说明 Hermes 已经成功运行：

![image-20260418022548383](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418022548383.webp)

如果遇到以下报错：

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

如果对话时出现 `API call failed (attempt 1/3): AuthenticationError [HTTP 401]` 报错：

![image-20260418152644914](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418152644914.webp)

原因可能是此前使用了 Clawx 等第三方 OpenClaw 客户端。这类客户端并不会把 API Key 明文存入 OpenClaw 的配置文件，因此迁移时无法读取到密钥。使用下面的命令编辑环境变量文件：

```bash
vim ~/.hermes/.env
```

以本人订阅的火山引擎编码计划为例，对应的环境变量是 `ARK_API_KEY`。核对后发现该值确实为空，填入正确的 Key 即可：

![image-20260418153204888](https://gastigado.cnies.org/d/20260418_openclaw2hermes_migration/image-20260418153204888.webp)

### 6. 设置多个模型提供商

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
