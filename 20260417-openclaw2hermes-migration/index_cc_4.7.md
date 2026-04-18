# 从 OpenClaw 迁移到 Hermes Agent 保姆级教程

## 导语

过去两个月，Hermes Agent 在 GitHub 上爆火。2 月底开源首月 2.2 万 star，4 月 8 日 v0.8.0 发布当天单日新增 6400+，总数已突破 4.7 万，多次霸榜开源周趋势第一。

![Gaj Varma 推文：从 0.5 升到 0.8，OpenClaw 要花两三小时修 bug，Hermes 直接跑通](./assets/6E84E04BF785493F4A6BF3B209A591E4.jpg)

Hermes 由 Nous Research 开源，MIT 协议，定位是一个会跟着你一起成长的个人 AI 智能体：自己从任务里提炼技能、记住你的偏好、跨会话精准回忆；支持 5 美元 VPS、Docker、Serverless 等 6 种部署方式；兼容 200 多个大模型；Telegram、Discord、Slack 都能接。国内有人直接说"准备放弃龙虾转爱马仕，龙虾记忆太差，爱马仕重开多久都记得住"。谷歌高级 AI 产品经理 Shubham Saboo 也转发推荐。

从 OpenClaw 换到 Hermes，你跟了吗？

## Hermes Agent 是什么

Hermes 直译爱马仕，这牌子 logo 里有马具——Harness 在英文里的本意就是马具。

挪到 AI 语境，Harness 指连接"模型"和"人类需求"之间的那层控制框架。Claude Opus 4.6 这种算大脑，一个 Agent 减去大脑剩下的部分，就是 Harness。它不做推理，只管模型往哪跑、跑多快、什么时候停。

这不是一家公司的自说自话。今年 2 月 OpenAI 的博客 *Harness Engineering: Leveraging Codex in an Agent-First World* 里写过一组实验：三个工程师靠 Harness Engineering，在五个月里让 Agent 产出了百万行代码。继 Prompt Engineering 和 Context Engineering 之后，行业正往更高一层的约束系统收敛。道理也不绕：自主权越大的系统越容易跑偏，套上合适的马具反而跑得更远。

Hermes 就在这个背景下做出来。Nous Research 是"去中心化 AI 研究实验室"，除了 Agent，他们还在推一个叫 Psyche 的去中心化训练网络，想把全球闲置 GPU 组织起来训练大模型。Hermes 相当于这套基础设施里最贴近终端用户的那一层。主流 SaaS 型 AI 把数据、记忆、行为轨迹都沉淀到平台侧，Hermes 想把这些留在用户自己手里——AI 能力不只是被调用一下就走，而是可以被持有、被积累、甚至反过来喂给模型训练。

## Hermes 和 OpenClaw 差在哪

相同点先列出来：数据不上商用云、记忆和执行过程留本地、直接接 Telegram/WhatsApp 这类 IM、支持 24/7 常驻。差异主要在三点。

**技能是写出来的还是长出来的。** OpenClaw 的能力边界靠人预设，开发者写代码或 Prompt 明确定义 Skill。Hermes 这边，任务完成后它自己把方法论抽出来做成 Skill，下次再用还会继续迭代。

**记忆怎么存。** OpenClaw 接近典型 RAG，知道"信息存在哪"，要用时再取。Hermes 是分层记忆，核心是后台建了一个"关于你的模型"——代码风格、对报错的容忍度、常用技术栈，跨会话慢慢摸清，还会定期整理固化。

![林亦 LYi 评论：Hermes 遇错继续搞到明确成败，OpenClaw 经常莫名其妙就停了](./assets/C479815ADCD7AA6F4E7B94F24FE83678.jpg)

**稳定性和安全。** 林亦 LYi 把体感说得很直白：Hermes 遇到错误会继续搞，直到明确成功或失败，OpenClaw 经常莫名其妙就停；Token 也真的省，聊很久上下文维持在三四万，换 OpenClaw 早就过 10 万。OpenClaw 流行得太快，社区 PR 质量参差，CI 时不时崩、启动卡死、网关冻结、更新后某些功能 25% 概率坏掉。更棘手的是安全：2026 年初到现在 OpenClaw 已经披露过多个高危 CVE，CVE-2026-25253 评到 8.8，可以通过 WebSocket 劫持令牌一键 RCE；ClawHub 上还出现过几百个恶意插件偷凭证。

![Summer Yue 推文：给 OpenClaw 下了"执行前先确认"，结果看着它狂删邮件](./assets/aba5968c-ca5c-4e95-a320-7d125ebe36eb.png)

最出圈的案例是 Meta 安全对齐总监 Summer Yue：她给 OpenClaw 下了"执行前先确认"的指令，眼睁睁看着它在自己邮箱里狂奔删邮件，手机拦不住，只能冲到 Mac mini 前手动断，"像在拆炸弹"。Hermes 这边走保守路线：危险操作要人工批准，配了一个叫 Tirith 的预执行扫描器做命令检查；技能生态规模小，攻击面窄。代价是生态不如 OpenClaw 热闹，现成插件也少一些。

所以 Reddit、YouTube 和 X 上的主流共识不是"Hermes 取代 OpenClaw"，而是两者互补：OpenClaw 负责动手，多通道交互、团队工作流更熟；Hermes 负责动脑，主攻持久记忆、自动技能生成和规划。官方也给了迁移路径——一条 `hermes claw migrate` 命令，现有的技能、记忆、配置能一键搬过来。

## 保姆级迁移教程
