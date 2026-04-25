---
title: 从 OpenClaw 迁移到 Hermes Agent 保姆级教程
pubDatetime: 2026-04-17T00:00:00.000+08:00
slug: openclaw2hermes-migration-cc-4-7-4
tags:
  - AI Agent
  - OpenClaw
  - Hermes Agent
  - 迁移
category: 技术教程
description: OpenClaw 迁移 Hermes Agent 保姆级教程改写稿，从 GitHub 增长和社区反馈切入，讲解 Harness、Nous Research、自动技能、分层记忆、安全稳定性和 token 消耗，并预告迁移步骤。适合想理解 Hermes 优势的新手。
---

## 一、导语

一个开源项目在 GitHub 单日涨 6400 多颗 Star，这种数字放到任何时候都值得多看一眼。

它叫 Hermes Agent。2 月底刚开源的时候还没什么动静，首月悄悄攒了 2.2 万 Star，直到 4 月 8 号 v0.8.0 版本发布那天开始霸榜——到现在总 Star 已经破了 4.7 万，连续好几天钉在全球开源榜第一。

![Gaj Varma 和 Teknium 在 X 上讨论 Hermes 的升级体验](./assets/6E84E04BF785493F4A6BF3B209A591E4.jpg)

它到底是什么？简单说就是一个"会自己长本事"的个人 AI 智能体。内置学习机制，完成任务之后会自动把方法总结成可复用的技能，记得住你的使用习惯，跨会话也能准确回忆之前的对话。部署方式多——5 美元 VPS、Docker、Serverless 都能跑，接 200 多个大模型改一行配置，Telegram、Discord、Slack 全都能接入，装起来一行命令。

社区反馈里有两类典型声音。一类是用得上瘾的："准备放弃龙虾转爱马仕了，爱马仕无论怎么重开、过多久都能记住，太香了。"另一类是务实派的吐槽。

![林亦 LYi 分享 Hermes 在错误恢复和 token 消耗上的实际表现](./assets/C479815ADCD7AA6F4E7B94F24FE83678.jpg)

真实用例也不少。有人用它两个半小时做了个《百战天虫》克隆版——持久 shell 模式、并行子 agent、/rollback 做检查点、CDP 做 Chrome 实时调试，Hermes 最后还把物理引擎那部分自己整理成了一个可复用 skill。

从 OpenClaw 切到 Hermes，你跟了吗？

## 二、Hermes Agent 到底是什么

想搞清楚 Hermes 在做什么，得先搞清楚一个词：Harness。

字面意思是马具。放到 AI 语境里，指的是连接"模型（马）"和"人类需求（骑手）"的那套控制框架——除去 Agent 的大脑（比如 Claude Opus 4.6 这类底层模型），剩下的部分都归 Harness 管。它不干活，也不让自己变聪明，只决定这匹马往哪跑、跑多快、什么时候停。

今年 2 月 OpenAI 发过一篇博客《Harness Engineering: Leveraging Codex in an Agent-First World》，讲一个三人工程师小组用这套思路，五个月写出了百万行代码的产品。行业里不少顶尖玩家几乎同时意识到：Prompt Engineering 和 Context Engineering 都不够用了，得加一层更高的约束系统。道理不复杂——自主权越大越容易跑偏，套上合适的马具反而能跑更远。

开发 Hermes 的是 Nous Research，MIT 许可、免费。这家公司定位是去中心化 AI 研究实验室，除了 Agent 还在推进一个叫 Psyche 的去中心化训练网络。所以 Hermes 不仅是一个本地工具，也是这套 AI 去中心化基础设施里最贴近用户的那层入口。

从用法上看，它和传统 Agent 最大的差别是"自进化"。一般 Agent 每次调用都是从零开始，Hermes 会从完成过的任务里学东西，在不同会话、不同平台之间保留记忆。社区反馈里有个很具体的感受：Hermes 在复杂任务里对提示词的依赖明显低了一档——给它一句模糊指令，比如"写一个抓数据然后画图的脚本"，它也能把任务拆开、读报错、尝试修复、在多次尝试里总结出方案。

底层思路更有意思。Hermes 想把 AI 能力从一次性调用变成可以持续积累的东西——Agent 不该只是临时调的接口，而应该是长期跑着的私有系统。主流产品的数据和记忆大多沉淀在平台那边，Hermes 想把这些尽量留在用户自己手里。

这条路还很早期，记忆噪音、技能质量、训练反馈稳定性都要打磨，部署门槛也还在。但方向清楚了：未来评估一个 Agent 可能不再只看它"当下能做什么"，而是看它"在时间里变成了什么"。

## 三、Hermes 和 OpenClaw 到底差在哪

先说 OpenClaw 是什么来头。

Claw 家族（Clawdbot、Moltbot 及衍生版本）是 2026 年初爆火的开源 AI Agent 生态，核心就是 OpenClaw。标志是只龙虾，做的事是把 LLM 从"只会聊天"升级成"能干活"——工具调用、自动化执行、长期记忆、沙箱、多平台接入全都包。OpenClaw 本身像个开箱即用的数字管家，邮件、日程、服务器监控、文件操作都能搞。

两家在"数字主权"这件事上是一致的：本地优先、数据不上云；放弃 Web UI 改走 Telegram、WhatsApp 这类即时通讯入口；支持定时任务，能 24 小时后台静默跑。分歧主要在路径选择上。

**技能怎么来。** OpenClaw 走人类预设路线——开发者用代码或 Prompt 写 Skill，定义它做什么它就做什么，稳定可预测，但上限就是你愿意花多少时间手写。Hermes 走经验涌现路线，完成复杂任务之后自己把方法抽出来存成 Skill，下次遇到类似任务直接复用。

**记忆怎么存。** OpenClaw 偏显式记忆加检索，本质是 RAG——知道"信息在哪里"，需要时去调。Hermes 用分层记忆，除了显性部分还建了一个"关于你的模型"，跨会话理解你的代码风格、对报错的容忍度、喜欢的技术栈。

**安全和稳定性上差距最大。** OpenClaw 因为增长太快，生态（ClawHub）膨胀失控，代码库跟着膨胀，大量社区 PR 过不了 CI，启动崩溃、网关冻结、模型适配失败这些回归 bug 高频出现；2026 年初到现在已经披露多个高危 CVE，其中 CVE-2026-25253 的 CVSS 打到 8.8，可以一键 RCE；ClawHub 里还被 Koi Security、Trend Micro 多次爆出恶意技能偷凭证、植入窃取器的事件。

![Summer Yue 讲述邮箱被 OpenClaw 一夜清空的经历](./assets/aba5968c-ca5c-4e95-a320-7d125ebe36eb.png)

Meta 安全对齐总监 Summer Yue 的遭遇是个典型案例：她明明设置了"操作前先确认"，OpenClaw 还是开始清空收件箱，她在手机上拦不住，最后冲回家用 Mac mini 像拆炸弹一样手动停下来。

Hermes 走的是更保守的设计：危险操作要人工批准（Tirith 预执行扫描器会先检查终端命令），技能生态小、攻击面窄，到现在没出现过类似的集中高危事件。

**Token 消耗和长程任务也差不少。** 养虾人抱怨最多的就是烧钱和长程任务不靠谱，跨 24 小时的任务里撒手不管，要么 Token 烧完事情只干一半，要么某一步走偏一路错到底。Hermes 用户反馈起手还是一万多 token，聊很久也能维持在三四万，同样场景 OpenClaw 早过 10 万；遇到错误会继续搞到明确成功或失败为止。

不过社区共识并不是替代关系。Reddit、YouTube、X 上主流看法是两者互补：OpenClaw 负责干活，Hermes 负责动脑。常见做法是把 Hermes 当高级规划器挂在 OpenClaw 之上，一行 `hermes claw migrate` 就能把现有技能、记忆和配置平滑搬过来。

具体怎么迁，下一部分细说。

## 四、从 OpenClaw 迁移到 Hermes Agent
