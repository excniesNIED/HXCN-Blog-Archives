# 从 OpenClaw 迁移到 Hermes Agent 保姆级教程

## 导语

最近两个月，X 和 GitHub 上冒出一个叫 Hermes Agent 的开源项目。2 月底首次放出，一个月就攒了 2.2 万颗星；4 月 8 日 v0.8.0 发布后，单日新增 6400 颗。到现在，总 Star 数已经冲过 4.7 万，在开源榜单上霸榜了好几天。

![Gaj Varma 关于升级体验的推文](./assets/6E84E04BF785493F4A6BF3B209A591E4.jpg)

一位叫 Gaj Varma 的用户从 0.5 升到 0.8，几分钟就搞定了——换成 OpenClaw，他按老习惯给自己留了两三个小时处理升级出岔子。695 次 commit，一次到位没翻车。这种体感上的落差，是 Hermes 最近在 X 上刷屏的直接原因。Teknium 在底下接了一句：OpenClaw 到底做了啥奇葩事，这点事都能让它崩。

国内也跟着热起来。不少人之前一直用 OpenClaw（俗称「龙虾」），现在开始往 Hermes 搬，理由很直白：省 Token、跨会话能记住事、任务跑着跑着不会莫名其妙停住。

这篇文章想讲清楚三件事：Hermes 到底是什么、和 OpenClaw 差在哪、以及怎么把已有的 OpenClaw 配置平滑搬过去。前两部分是背景，如果你已经看过介绍，可以直接跳到第四部分看操作。

## Hermes Agent 是什么

先从 Harness 这个词说起，字面意思是马具。

放到 AI 语境里，Harness 指的是连接「模型（马）」和「用户需求（骑手）」的那整套控制框架。除去 Agent 的大脑（比如 Claude Opus 4.6），剩下那些决定「它往哪跑、跑多快、什么时候停」的部分，都算 Harness。它不让模型变聪明，但管着模型怎么使用它的聪明。

今年 2 月，OpenAI 发过一篇博客《Harness Engineering: Leveraging Codex in an Agent-First World》，用一组数据说明三人小组靠 Harness Engineering，五个月就能做出百万行代码的产品。这意味着，行业里的头部玩家差不多同时意识到——光靠 Prompt Engineering 和 Context Engineering 已经不够用了，需要更高一层的约束系统。

Hermes Agent 就是 Nous Research 做出来的这么一套 Harness，MIT 协议、免费开源。它的卖点不是「更强的大脑」，而是「会跟着你一起长」的个人 Agent。核心机制三条：

- 任务跑完，自动把里面能复用的步骤抽出来，存成 Skill；
- 跨会话的记忆放在本地，用得越久越知道你的偏好和代码风格；
- 部署门槛低，5 美元 VPS、Docker、Serverless 都能跑，兼容 200 多个模型，微信、Telegram、Discord、Slack 都能接。

从 2026 年 2 月发布到现在，GitHub 上贡献者几百人，Star 4.7 万。有开发者用 gemma 26B 配合 Hermes 测过：就算只给一句模糊指令——「写个抓数据并画图的脚本」——Agent 也能自己拆任务、写代码、读报错、试修复，走完一整套流程。这不等于全自动开发，但比每次都要精确写 Prompt 确实省心。

还有人干了更野的事：有开发者用 Hermes 的持久 shell 模式加并行子 agent，2.5 小时复刻了一个《百战天虫》克隆版，中间还用 `/rollback` 做文件系统检查点，借 CDP 实时调试 Chrome。Agent 干完活，顺手把物理引擎逻辑整理成了一个可复用的 Skill。这种「干完活还顺便攒经验」的路子，是它和传统 Agent 最大的区别。

## 和 OpenClaw 差在哪

OpenClaw（原名 Clawdbot/Moltbot，外号「龙虾」）是今年年初火起来的 Agent 项目，强调工具调用的广度。它和 Hermes 有相同的基因：本地优先、走消息通道交互、支持 7×24 后台跑，都是在回应 SaaS 型 AI 的隐私焦虑。

但两者的分叉点也很清楚。

OpenClaw 走的是「把生态做大」的路。插件市场 ClawHub 上 Skill 数以千计，什么都能接。代价是代码库膨胀得很快，社区 PR 质量参差，CI 经常挂；2026 年以来披露了多个高危 CVE，包括一个 CVSS 8.8 的 WebSocket 劫持 RCE，ClawHub 上还出现过批量的恶意技能投毒。Meta 对齐研究负责人 Summer Yue 就在 X 上吐槽过：她明明给 OpenClaw 下过「执行前确认」的指令，结果眼睁睁看着它把自己邮箱清空了，手机上根本拦不住，她飞奔到 Mac mini 边上硬拔电源，像在拆炸弹。

![Summer Yue 关于 OpenClaw 删邮箱的推文](./assets/aba5968c-ca5c-4e95-a320-7d125ebe36eb.png)

Hermes 走的是另一条——生态小，但架构更收。它的 Skill 是 Agent 在任务里自己萃取的，不是靠社区往里塞；记忆文件 MEMORY.md 有字符上限，满了会自动压缩总结；危险操作前面挂了个叫 Tirith 的预执行扫描器，需要人工批准才放行。到目前为止没出现过 OpenClaw 那种级别的集中 CVE。

这两点在真实用户那里也有反馈。B 站 up 主林亦 LYi 说得很直：一是 Hermes 遇到错误会接着跑，直到明确成功或失败，OpenClaw 经常跑着跑着就莫名停了；二是真省 Token，聊很久上下文还能稳定在三四万，换 OpenClaw 早就过 10 万了。

![林亦 LYi 对 Hermes 的实测评价](./assets/C479815ADCD7AA6F4E7B94F24FE83678.jpg)

选哪个其实看场景。做金融交易、批量数据处理这种容错率极低的活，OpenClaw 新版本的权限控制更严、行为更好预测；做探索性开发、流程模糊的长任务，Hermes 的自主性能省下不少盯盘的时间。社区里常见的做法是两者并着用：OpenClaw 负责「干活」，对接多通道和现成工具；Hermes 负责「动脑」，做长期记忆和高层规划。这种组合用一条 `hermes claw migrate` 命令就能搭起来——下一部分详细讲操作。

## 迁移操作
