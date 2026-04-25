---
title: 从 OpenClaw 迁移到 Hermes Agent 保姆级教程
pubDatetime: 2026-04-17T00:00:00.000+08:00
slug: openclaw2hermes-migration-cc-4-7-3-5
tags:
  - AI Agent
  - OpenClaw
  - Hermes Agent
  - 迁移
category: 技术教程
description: OpenClaw 迁移 Hermes Agent 保姆级教程草稿，介绍 Hermes 的开源热度、Harness 控制框架、自进化 Agent 定位、OpenClaw 技能与记忆差异、安全稳定性问题，以及一键迁移入口。适合整理迁移教程结构。
---

## 一、导语

最近几周，X 和 GitHub 上一个叫 Hermes Agent 的项目有点刷屏。

2 月底开源，第一个月破了 2.2 万 Star。4 月 8 号 v0.8.0 一发布，单日再涨 6400 多。不到两个月 GitHub 总 Star 突破 4.7 万，连着几天霸着全球开源榜第一。

![Gaj Varma 和 Teknium 讨论从 OpenClaw 升级到 Hermes 的体验](./assets/6E84E04BF785493F4A6BF3B209A591E4.jpg)

它是什么？一句话概括：一个会自己长本事的个人 AI 智能体。内置学习机制，能从任务里自动总结出可复用的技能，记得住你的使用习惯，跨会话还能把之前聊过的东西准确捞回来。部署灵活，5 美元 VPS、Docker、Serverless 都能跑，接 200 多个大模型改一行配置就行，Telegram、Discord、Slack 全都能接，一行命令搞定安装。

有人说它是 OpenClaw 的平替，也有人觉得比 OpenClaw 更好用。"准备放弃龙虾转爱马仕了，爱马仕无论怎么重开、过多久都能记住，太香了。"社区里这样的声音越来越多。

![林亦 LYi 在微博上分享 Hermes 的两个实际优点](./assets/C479815ADCD7AA6F4E7B94F24FE83678.jpg)

有开发者用它花两个半小时做了一个《百战天虫》克隆版——持久 shell 模式、并行子 agent、/rollback 做检查点、CDP 做 Chrome 实时调试，Hermes 最后还把物理引擎那部分自己整理成了一个可复用 skill。

从 OpenClaw 切到 Hermes，你跟了吗？

## 二、Hermes Agent 到底是什么

Hermes 在希腊神话里是信使，但开发团队还提到了另一个词 Harness——字面意思是马具。

放到 AI 语境里，Harness 指的是连接"模型（马）"和"人类需求（骑手）"之间的那套控制框架。除去 Agent 的大脑（比如 Claude Opus 4.6 这种底层模型），剩下的部分都算 Harness。它不干具体的活，也不让自己变聪明，只决定这匹马往哪跑、跑多快、什么时候停。

这不是某家公司的一厢情愿。今年 2 月 OpenAI 发过一篇博客 *Harness Engineering: Leveraging Codex in an Agent-First World*，讲一个三人工程师小组用 Harness Engineering 的思路，五个月写出了百万行代码的产品。行业里不少顶尖玩家几乎同时意识到：Prompt Engineering、Context Engineering 都不够用了，得有更高一层的约束系统。

Hermes Agent 由 Nous Research 开发，MIT 许可、免费。定位是一个"自进化 Agent"：从完成过的任务里学习，在不同会话、不同平台之间保留记忆，慢慢形成一套属于你自己的能力结构。

社区反馈里有一点特别突出：Hermes 在复杂任务里对提示词的依赖明显降低。有人只给一个模糊指令——比如"写一个抓数据然后画图的脚本"——Agent 也能把任务拆开、一步步生成代码，中途读报错、尝试修复、在多次尝试里总结出可复用的方案。这不代表它能做到全自动开发，但至少不用非得拿到精确 prompt 才能往前推。

底层思路上 Hermes 和 OpenClaw 走的几乎是相反的路：后者在意连接能力的广度，Hermes 更执着于学习能力的深度。官方那句 "the agent that grows with you" 指向的是一整套围绕持续学习构建的底层设计——把 AI 能力从一次性调用，变成可以持续积累的东西。

当然这条路还很早期。记忆噪音、技能质量、训练反馈稳定性都还要打磨，部署门槛也在，离"普通用户无感使用"挺远。但方向已经比较清楚了。

## 三、Hermes 和 OpenClaw 到底差在哪

先简单介绍一下 OpenClaw。

Claw 家族（也叫 Clawdbot、Moltbot、OpenClaw 及其衍生）是 2026 年初爆火的开源 AI Agent 生态，核心是 OpenClaw。标志是只龙虾，思路是让 LLM 从"只会聊天"变成"能干活"——工具调用、自动化执行、长期记忆、安全沙箱、多平台接入全都支持。家族里还有 NanoClaw、PicoClaw、ZeroClaw 等变体。OpenClaw 本身像个可部署的个人 AI 管家，邮件、日程、服务器监控、文件操作都能处理。

两者共同点是"数字主权"：本地优先、数据不上云；放弃 Web UI，改用 Telegram、WhatsApp 这类即时通讯工具交互；支持定时任务，能 24 小时在后台跑。

不同之处就多了。

**技能获取方式不一样。** OpenClaw 的能力边界由"人类预设"决定——开发者通过代码或 Prompt 写 Skill，稳定可控，但天花板在于你愿意花多少时间手写。Hermes 的能力是"涌现"出来的：完成一个复杂任务后，它会自动把方法抽象出来、沉淀成可复用的 Skill，后续任务里不断迭代。

**记忆机制不一样。** OpenClaw 更偏显式记忆和检索，本质是 RAG 思路——它知道"信息在哪里"，需要时去调。Hermes 用的是分层记忆，除了显性记忆还建了一个"关于你的模型"，在跨会话的使用里逐渐理解你的代码风格、对报错的容忍度、喜欢的技术栈，甚至会定期主动整理这些东西。

**安全和稳定性差距更明显。** OpenClaw 因为病毒式增长，生态（ClawHub）膨胀得特别快，代码库也跟着膨胀。大量社区 PR 过不了 CI，启动崩溃、网关冻结、模型适配失败这些回归 bug 频繁出现；2026 年初到现在披露了多个高危 CVE，其中 CVE-2026-25253 的 CVSS 打到 8.8，能一键 RCE；ClawHub 里还被 Koi Security、Trend Micro 多次爆出恶意技能偷凭证、植入窃取器的事件。

![Meta 安全对齐总监 Summer Yue 讲述自己的邮箱被 OpenClaw 一夜清空](./assets/aba5968c-ca5c-4e95-a320-7d125ebe36eb.png)

Meta 安全对齐总监 Summer Yue 的邮箱被 OpenClaw 一夜清空就是个经典例子。她明明设置了"操作前先确认"，OpenClaw 还是直接开始清空收件箱，手机上拦不住，只能冲回家用 Mac mini 像拆炸弹一样手动停。

Hermes 这边采用的是更保守的设计：危险操作要人工批准（Tirith 预执行扫描器会先检查终端命令）；技能生态小、攻击面窄；到目前为止没出过类似的集中高危事件。开发团队是 Nous Research——做模型训练的那拨人——对架构质量更上心。

**Token 消耗和长程任务表现也差得多。** 养虾人抱怨最多的就是烧钱和长程任务不靠谱。把 OpenClaw 扔进跨 24 小时以上的任务里撒手不管，Token 烧完事情只干一半、或者某一步走偏一路错到底都是常见结局。Hermes 用户反馈起手还是一万多 token，但聊很久能维持在三四万，换 OpenClaw 早就过 10 万了。

社区的共识其实不是 Hermes 替代了 OpenClaw，而是两者互补。OpenClaw 负责"干活"——多通道交互、团队工作流、复杂生态对接；Hermes 负责"动脑"——持久化记忆、自动生成技能、长链路推理。常见做法是把 Hermes 当高级规划器挂在 OpenClaw 工具之上。只要跑一行 `hermes claw migrate`，现有的 OpenClaw 技能、记忆和设置就能平滑迁移过来。

具体怎么迁，下一部分细说。

## 四、从 OpenClaw 迁移到 Hermes Agent
