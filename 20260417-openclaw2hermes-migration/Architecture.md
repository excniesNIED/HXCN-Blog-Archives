---
title: OpenClaw 迁移 Hermes Agent 教程写作提纲与参考资料
pubDatetime: 2026-04-17T00:00:00.000+08:00
slug: openclaw2hermes-migration-architecture
tags:
  - AI Agent
  - OpenClaw
  - Hermes Agent
  - 写作提纲
category: 写作资料
description: OpenClaw 迁移 Hermes Agent 教程写作提纲，汇总导语、Hermes 介绍、OpenClaw 对比、社区反馈、插图文字和参考语料，并预留迁移操作章节。适合作为小白向 AI Agent 迁移教程的写作素材。
---

- 我在写一个从Openclaw迁移到Hermas Agents的技术教程，用于面向小白和获取新闻咨询的技术爱好者操作。主要分为四大部分：导语、介绍、对比和操作。

  导语+爱马仕介绍+claw与爱马仕对比，前三三部分字数控制在600-1200字左右，帮我给出前三部分到index中。使用 /de-ai-writings 去ai味。第四部分只留一个标题。下面给了很多每个部分的参考语料。最后的迁移不要看，只预留题目。

  ## 插图

  怕你看不了图片，转成文字了，注意在文章中预留插图位置（在./assets文件夹）

  ```6E84E04BF785493F4A6BF3B209A591E4.jpg
  Gaj Varma@GajVarma·12小时
  I just did an update from 0.5 to 0.8.
  With OpenClaw, I would put aside 2-3 hours to fix issues.
  With Hermes, it just worked. Even with 695 commits.
  I'm just curious, what are doing differently?
  Regardless, well done!
  我刚从0.5版本更新到0.8。
  要是用OpenClaw，我得花上两三个小时来解决问题。
  Hermes，切顺利。即便有695次提交。
  我只是好奇，你们到底做了什么不同的事？
  无论如何，干得漂亮！
  @Teknium·10小时
  Teknium (e/λ)
  My question is what is openclaw doing thats so crazy bad that this doesn't
  just work haha
  我的问题是，OpenClaw到底做了什么糟糕透顶的事，才让这玩意儿没法直接
  运行呢，哈哈
  ```

  ```C479815ADCD7AA6F4E7B94F24FE83678.jpg
  林亦LYi
  @linyiLYi
  已严肃使Hermes，还真不是因为Hermes能“我进化”这些虚的，有俩很
  实在的点：1.Hermes遇到错误会继续搞，直到明确成功/失败，但
  OpenClaw经常莫名其妙就停了；2.真的省token，虽然起手还是一万多，
  但聊很久上下文也维持在三、四万token，换OpenClaw早就过10万了。
  ```

  ```aba5968c-ca5c-4e95-a320-7d125ebe36eb.png
  Summer Yue
  @summeryue0
  Nothing humbles you like telling your OpenClaw "confirm before acting"
  and watching it speedrun deleting your inbox. I couldn't stop it from my
  phone. I had to RUN to my Mac mini like I was defusing a bomb.
  ```

  ## 导语

  最近几周，在 X 和 GitHub 上，一个名为 Hermes Agent 的开源项目火了。

  从 2 月底开源首月破 2.2 万星，到 4 月 8 日 v0.8.0 版本发布后单日新增 6400 + 星，Hermes Agent 在不到两个月的时间里，GitHub 总星标已突破 4.7 万，并在多日内持续霸榜全球开源榜单第一。

  Hermes Agent 是什么？

  简单来说，它是一款「会自我成长」的个人 AI 智能体：内置学习闭环，能从任务中自动提炼技能、持久记忆用户偏好、跨会话精准回忆，越用越懂你；支持 5 美元 VPS、Docker、Serverless 等 6 种部署方式，兼容 200 + 大模型一键切换微博，Telegram、Discord、Slack 全平台接入，一行命令即可安装运行。

  有人说它是 OpenClaw 的平替，有人说它比 OpenClaw 更好用，在极短的时间内，它不仅收获了数万颗 Star，也让开发者感叹：AI 可以「越用越像自己的一部分」。

  从 OpenClaw 切换到爱马仕 Hermes，你跟了吗？

  近日，Hermes Agent 在国内突然爆火。Hermes Agent 从 2 月份开源以来，现已获得超 3.9 万 stars，目前还在快速增长。

  “准备放弃龙虾转爱马仕了，龙虾记忆太差了，爱马仕无论怎么重开，过多久都能记住，太香了！”有网友说道。谷歌高级 AI 产品经理 Shubham Saboo 发推称赞其好用。

  有用户在 Mac M3 上通过 LM Studio 本地运行 Qwen 3.5-35B，并把 OpenRouter 作为备用后端，Hermes 则 24 小时持续运行。

  Hermes 可以把日历、Gmail 和 Todoist 的信息先汇总到一个分析步骤里，再把任务分派给 Claude Code，持续跟踪进度，同时回写到用户的 Obsidian vault。X 上还有人提到，他们的 Hermes Agent 会自主给商业伙伴的 Hermes Agent 发消息，协同完成某项任务，全程没有人工介入。

  有位开发者用 Hermes Agent 花费 2.5 小时做出了 《百战天虫》克隆版。他用的是持久 shell 模式、并行子 agent、通过 /rollback 实现文件系统检查点，以及借助 CDP 进行实时 Chrome 调试。而且，这个 gent 还自己把物理引擎逻辑整理成了一个可复用的 skill 插件。

  还有用户在发现每次 API 调用里有 73% 都是固定开销后，做了一个开源仪表盘。其中特别大的开销来自：工具定义占 46%，system prompt 占 27%。现在大家也在分享一些降本方法，比如按平台拆分工具集，或者按需懒加载 skill。

  Hermes 可以自托管在 5 美元的 VPS 上，将其与 Ollama 结合使用，即可实现本地推理，成本几乎为零。

  “我试过 OpenClaw、Nanobot、Nanoclaw 等等，但 Hermes Agent 是我最喜欢的。它把我真正关心的功能都做进去了，同时又没有那些臃肿累赘的东西。”有用户表示。

  该用户进一步解释道，“在我看来，它更容易审计、也更安全，和我本地跑的模型配合得也很好。我把 Hermes 装在一台始终在线的 Mac mini 上，这台机器可以通过预共享密钥 SSH 访问我的 Ubuntu 服务器。对我来说，这台 Mac mini 就是整个编排体系里的中枢。我平时要么直接在 Mac mini 上用它，要么从 MacBook SSH 连到 Mac mini 去用，要么通过 Telegram 来操作。完全不需要多节点部署。至于一些更轻量的任务，我最近在测试 pi.dev 和 opencode 的效果对比，不过到目前为止，我还是挺喜欢它更省 token 的用法。

  官方还给了从 OpenClaw 迁移到 Hermes 办法。不过也有使用过用户表示，“我大概不会直接替换掉现有的 Claude Code 工作流，但把 Hermes 并行挂在旁边，专门负责常在线消息处理和个人助理这一层，确实很有吸引力。”

  ## 介绍

  Harness 这个词，字面意思是马具。

  放到 AI 语境里，它指的是连接「模型（马匹）」和「人类需求（骑手）」的那套控制框架。

  简单地说，除去 Agent 的「大脑」（如 Claude Opus 4.6），其余部分都是 Harness。

  它不参与任务执行本身，也不让自己变得更聪明，但它决定这匹马往哪里跑、跑多快、什么时候该停下来。

  这个判断已经不是某一家公司的一厢情愿。

  今年 2 月，OpenAI 发了一篇官方博客，标题叫《Harness Engineering: Leveraging Codex in an Agent-First World》，用一组实验证明，一个三人工程师小组通过 Harness Engineering，可以在五个月里让 Agent 写出百万行代码的产品。

  也就是说，在 OpenClaw 之后，行业里的顶尖玩家几乎是同时发现，Prompt Engineering 和 Context Engineering 都不够用了，得有更高一层的约束系统。

  Harness 的逻辑听起来有点反直觉，用约束换自主。

  但背后的道理其实很好理解，自主权越大的东西越容易跑偏，所以给它套上足够好的马具，它反而能跑得更远。

  这个共识正在快速收敛。

  对普通用户来说，接下来半年到一年里大概率会冒出一批新的 AI 产品，不再强调自己的模型有多大，而是强调自己会「驯服」模型。

  就在这个当口，有家成立四个多月的公司已经悄悄把两轮重金收进口袋。

  Hermes Agent 是 Nous Research 开发的免费、MIT 许可的自主 AI 框架，它的核心定位是，一个会随着使用不断成长的「自进化 Agent」。

  和传统 Agent 不同，Hermes 试图成为一个能够持续积累经验的长期系统：它会从已经完成的任务中学习，在不同会话、不同平台之间保留记忆，并逐渐形成一套属于用户自己的能力结构。

  自 2026 年 2 月发布以来，它在短短几周内狂揽超过 2.2 万颗 GitHub Star，目前为止已超过 4.7 万，贡献者也有数百名。从社区反馈来看，这种设定正好击中了一个长期存在的需求——开发者越来越关心，Agent 能不能「记住」和「变强」。

  在 X 和开发者社区的讨论中，让人印象深刻的，是 Hermes 在复杂任务中对提示词的依赖明显降低了。

  有开发者在使用 gemma 26B 或 Hermes 系列模型测试时提到，即便只给出一个相对模糊的指令，例如「写一个抓取数据并生成可视化的脚本」，Agent 也能够完成从任务拆解到代码生成的一整套流程。

  在执行过程中，它会根据执行反馈不断调整路径——包括读取报错信息、尝试修复问题，甚至在多次尝试中形成可复用的解决方案。

  这种体验并不意味着 Hermes 具备稳定的「全自动开发能力」，但它至少让开发者感受到：Agent 不再完全依赖精确 prompt，也可以在模糊目标下推进复杂任务。

  Hermes Agent 更值得关注的，其实是其底层的架构。

  从架构上看，它和 OpenClaw 走的是两条几乎相反的路径：前者强调连接能力的广度，后者则更执着于学习能力的深度。Hermes 的那句口号——「the agent that grows with you」，是指向一整套围绕「学习闭环」构建的底层设计。

  Hermes Agent 在试图把「AI 能力」从一次性调用，变成可以持续积累的资产。

  Agent 不应该只是一个临时调用的接口，而应该是一种长期存在的系统——它是私有的、持续运行的，并且可以在使用过程中不断积累能力，最终反过来影响模型本身。

  主流产品的数据、记忆、行为轨迹，大多沉淀在平台侧，而 Hermes 想做的，是把这些能力尽可能留在用户自己的系统里。

  这意味着 AI 的能力，不再只是「被调用」，而是可以「被拥有」。在开源社区里，Hermes Agent 的热度，很大一部分来自于它把这条路径真正跑通了一部分。

  它在尝试打通一条更完整的链路：从任务执行，到技能沉淀，再到记忆积累，甚至进一步，成为训练数据的一部分。

  当一个 Agent 开始具备这样的循环能力——自己解决问题 → 记录经验 → 复用经验 → 优化方法 → 再反哺自身——它就开始接近一个可持续进化的系统。

  目前来看，这条路径还很初期。记忆的噪音、技能的质量、训练闭环的稳定性，仍然是需要反复打磨的问题。部署门槛也依然存在，距离「普通用户无感使用」还有不小的距离。

  但方向已经很清晰。Hermes 至少让一件事变得具体起来：私有 AI，不只是一个使用形态，而可能是一种可以持续演进的资产形态。

  如果这条路径成立，未来我们评估一个 Agent 的方式，可能会发生变化： 从看它「当下能做什么」到看它「在时间里变成了什么」。谁能在时间里积累更多能力，谁就拥有更高的上限。

  ## 对比openclaw

  最近，OpenClaw等开源AI Agent项目在开发者社区火爆出圈。只需要一句话，Agent就能自动帮你写代码、查资料、操作本地文件，甚至接管电脑。

  这些 Agent 惊人自主性的背后，离不开工具调用提供的能力，MCP（Model Context Protocol，模型上下文协议）正是统一AI工具生态的接口。就像USB-C让电脑可以连接各种设备一样，MCP让大模型能够以标准化方式调用文件系统、浏览器、数据库等外部工具。

  面对如此庞大的生态，连主打原生命令行的OpenClaw，也通过适配器接入了 MCP，以获取更广阔的工具能力。

  然而，**当AI的「手」越伸越长，危险也随之降临**。如果Agent调用的工具本身被黑客投毒了呢？如果工具返回的报错信息里藏着恶意指令呢？

  当大模型毫无防备地执行这些指令时，你的隐私数据、本地文件甚至服务器权限，都将沦为黑客的囊中之物。

  ### OpenClaw 当前的核心问题（你提到的基本都真实存在）

  - **代码量爆炸 + 维护混乱**：OpenClaw（前 Clawdbot/Moltbot）因病毒式增长，生态（技能/ClawHub）迅速膨胀，导致代码库快速膨胀。大量社区 PR 和 commit 涌入，但质量参差不齐，很多 PR 过不了 CI（格式检查失败、测试 OOM、构建崩溃等）。GitHub issues 中频繁出现 CI 崩溃、格式失败、回归 bug 等。
  - **Bug 多且高频**：启动崩溃、网关冻结、模型适配失败、编辑工具失效等回归问题常见。更新后“25% 概率破坏某些功能”的用户反馈不少。
  - **高危漏洞频发**：2026 年初至今已披露多个高危 CVE（如 CVE-2026-25253 CVSS 8.8，一键 RCE 通过 WebSocket 劫持令牌；命令注入、SSRF、路径遍历、权限提升等）。恶意技能（ClawHub 中数百个恶意插件）导致供应链攻击风险高。安全研究机构（如 Koi Security、Trend Micro）多次报告恶意技能偷取凭证或植入窃取器。很多实例暴露在公网，零认证配置加剧风险。即使官方快速打补丁，攻击面大（Node.js 生态 + 大量插件）让问题难以根治。
  - **结果**：对于生产/日常重度使用，OpenClaw 越来越像“高速发展的混乱生态”——功能多、集成广，但稳定性差、安全负担重，维护成本高。

  这些问题正是快速流行开源项目常见的“成长烦恼”：贡献者多 → 代码/技能暴增 → 质量控制跟不上。

  ### Hermes Agent 在这些方面的优势

  Hermes（Nous Research 出品）定位不同，采用**更保守、专注的学习型架构**（Python 实现），强调“与你一起成长”的闭环，而不是追求最大生态。

  - 代码质量与维护性更好：
    - 代码库规模小得多（GitHub 显示约 3600+ commits，但核心文件结构清晰，单文件如 run_agent.py ~9200 行，整体更精炼）。
    - 没有 OpenClaw 那样海量社区 PR 导致的 CI 灾难。开发团队（Nous Research，训练模型的团队）更注重架构质量，更新相对稳健，用户反馈中“代码混乱”“CI 崩”的吐槽远少。
    - 内置自我进化机制：任务后自动萃取/优化技能，避免手动维护大量低质代码。记忆系统有界（MEMORY.md 限制字符数，自动压缩/总结），不像 OpenClaw 那样容易内存/日志膨胀。
  - 安全性更可靠：
    - 采用**保守设计**：危险操作需人工批准（Tirith 预执行扫描器检查终端命令）；技能生态小，攻击面窄；没有类似 ClawHub 的大规模恶意技能问题。
    - 至今未出现 OpenClaw 那样集中的高危 CVE 或供应链攻击事件。安全模型更注重“从底层做对”（凭证隔离、注入检测）。
    - 用户和评测反馈：Hermes 在安全边界上更“从地基做起”，适合不希望每天处理新漏洞的用户。
  - 稳定性与用户体验：
    - 很多从 OpenClaw 迁移的用户反馈：Hermes 执行更快、上下文管理更好、自我改进循环真实有效（重复任务越用越聪明）。
    - Bug 相对少，更新后回归问题少见（虽非零 bug，但规模小，修复更可控）。
    - 缺点：生态/插件不如 OpenClaw 丰富（技能需自己生成或少量社区），集成平台支持稍弱。如果你需要海量现成技能或极致多平台，Hermes 可能需要额外配置。

  总体来说，**Hermes 更像一个“精炼、自我维护的个人助理”**，而 OpenClaw 更像“热闹但乱的数字管家”。如果你被 OpenClaw 的代码/质量/安全问题折磨，Hermes 能显著降低这些负担，尤其长期使用时（记忆和技能会越积累越好，而不是越用越乱）。

  **Hermes Agent**（由 Nous Research 开发）是一个开源的自适应 **AI Agent 框架**，核心理念是“与你一起成长”。它强调**程序性记忆**和**闭环学习**：每次完成复杂任务后，会自动从经验中萃取可重用的“技能”（Skill），下次遇到类似任务时直接调用并持续优化。简单说，它像一个长期跟你的私人助理，越用越懂你、越熟练。

  **Claw 家族**（也称 Clawdbot / Moltbot / OpenClaw 及其衍生）是 2026 年初爆火的开源 AI Agent 生态，以 **OpenClaw**（原 ClawdBot）为核心。它的标志是一只“龙虾”（Claw 指钳子/机械爪），核心是让 LLM 从“只会聊天”变成“能实际做事”的代理人：支持工具调用、自动化执行、长期记忆、安全沙箱、多平台接入等。家族包括 NanoClaw、PicoClaw、ZeroClaw 等变体，以及大量衍生技能/工具，强调“AI 动手能力”和可落地自动化。OpenClaw 本身像一个可部署的个人 AI 管家，能处理邮件、日程、服务器监控、文件操作等。

  当 Hermes Agent 在 X 上大放异彩时，开发者不可避免地将它与今年年初在开源社区大火的另一个现象级项目——OpenClaw 进行对比。

  OpenClaw 同样是一个本地优先的个人 AI 助理框架。它与 Hermes Agent 这两者都试图解决传统 SaaS 型 AI 的隐私和控制权问题，但在底层哲学上，它们走向不同。

  两者的相同点在于「数字主权」。

  无论是 Hermes 还是龙虾，它们在出现之初都拥有相同的底层基因：

  - 本地优先与隐私至上：数据不会上传到不可控的商业云端，所有记忆、代码执行过程，甚至文件与目录级别的授权，都尽可能留存在用户本地设备或私有环境中。
  - 基于消息通道的交互：它们都放弃了繁琐的 Web UI，转而拥抱 Telegram、WhatsApp 等即时通讯工具，让 AI 真正融入人类日常的沟通链路。
  - 全天候的自动化（24/7 Agent）：支持定时任务，可以在后台静默运行，无需人类时刻盯盘。

  这种对「数字主权」的强调，本质上是一种基础设施层的选择。而在这一点背后，Hermes 与 OpenClaw 的差异，其实已经开始显现。Nous Research 的定位是一家「去中心化 AI 研究实验室」，他们不仅做 Agent，还在推进名为 Psyche 的去中心化训练网络——试图利用区块链协调全球闲置 GPU 来训练大模型。

  所以，Hermes Agent 不仅仅是一个本地工具，也是这一整套「AI 去中心化基础设施」中，最贴近用户的一层入口。

  两者的不同之处在于能力生长的路径之争。如果说 OpenClaw 代表的是一种更偏「确定性」的路径，那么 Hermes 则更接近一种「进化式」的系统。

  首先是技能获取方式的不同（Human-authored vs. Autonomous）。龙虾的能力边界主要由「人类预设」决定。龙虾倾向于让开发者通过明确的代码或 Prompt 来编写 Skill。它是一个完美的控制面，用户定义了它能做什么，它就会以高稳定性和确定性去执行。

  Hermes Agent 的能力则是通过「经验涌现」出来的。在完成复杂任务之后，它会自动抽象出方法论，将其沉淀为可复用的 Skill，并在后续任务中不断迭代优化。这使得它的能力边界不是预先写死的，而是在使用中逐渐扩展。

  其次是记忆机制的差异。

  OpenClaw 更偏向显式记忆与检索机制，本质上是典型的 RAG 思路——它知道「信息在哪里」，并在需要时调取。

  Hermes Agent 则采用的是分层的记忆系统，除了显性记忆，最核心的是它建立了一个「关于你的模型」。它会在跨会话的交互中，逐渐理解用户的代码风格、对待报错的容忍度、喜欢的技术栈。它甚至会定期「轻推」自己去整理和固化这些知识。

  适用场景上，两者也有区别。

  如果用户要一个极其安全、步骤明确、用于处理批量数据或金融交易等容错率极低的任务，龙虾的权限控制（最新版）更严格，行为更可预测。如果用户进行探索性的编程、创意开发，或者处理那些流程模糊、需要不断试错的复杂工程，Hermes 带来的自主性将为用户省下不少负担。

  不过，在 Reddit、Youtube 和 X 上的社区共识并不是 Hermes 取代了 OpenClaw，而是认为它们是互补的。

  OpenClaw 负责「干活」——处理多通道交互、团队工作流和复杂的生态对接；而 Hermes 负责「动脑」——主攻持久化记忆、自动生成技能和高维度的模型推理。

  常见的设置是将 Hermes 作为高级规划器运行在 OpenClaw 工具之上。只需要运行 hermes claw migrate 指令，就可以将现有的 OpenClaw 技能、记忆和设置一键平滑迁移到 Hermes 中。

  **Hermes Agent**：自学习、成长型个人助理。重点在“持久记忆 + 自主技能进化”，像养一个会累积经验的系统。支持从 OpenClaw 直接迁移（有专用命令 hermes claw migrate，能导入记忆、技能、配置等）。

  **Claw家族 (OpenClaw 主力)**：执行型 AI Agent 平台。强调“动手能力”（工具调用、自动化流程）、沙箱安全和多 Agent 架构。像一个开箱即用的“数字管家”或“牛马”，适合直接落地日常任务。家族生态丰富，有各种轻量/安全/分布式变体。

  **Hermes** 最强：跨会话持久记忆 + 自动技能萃取/优化 + 用户画像建模。像“数据库脑”，会主动改进技能（例如网站结构变了，它自己调整而非人工介入）。

  **Claw/OpenClaw**：有长短期记忆、Memory.md 等，支持工作区式记忆（像笔记本），但学习更依赖人工喂 skill 或手动优化。

  困扰养虾人最大的问题，第一是 Token 太费钱，第二是长程任务不靠谱。

  把 OpenClaw 扔进一个需要跨越 24 小时以上的长程任务里，中间撒手不管，结果往往并不乐观。

  要么是 Token 烧完了事情只干了一半，要么是某一步走偏之后一路错到黑，交回来的东西完全不能用。

  Meta 安全对齐总监 Summer Yue 的邮箱被 OpenClaw 一夜清空的故事，也是「经典咏流传」。

  更早之前，还有不止一个 Agent 把敏感公司数据泄露给无权限员工的案例。

  这些事摆在一起，指向同一个问题。

  越聪明的单体智能，一旦被放进更长的时间维度和更复杂的协作链条里，就越容易在关键节点掉链子。

  这就像一个 IQ 很高但没人管的实习生，前半小时让人惊艳，后半小时就开始自己给自己出难题。

  行业里的人开始意识到，光让模型变聪明不够，还得有个东西来管它怎么用自己的聪明。

  这个东西最近有个越来越高频的名字，Harness。

  ## 迁移

  以下是从 **OpenClaw**（或 Claw 家族）迁移到 **Hermes Agent** 和 **AstrBot** 的详细指南。Hermes 有官方内置的一键迁移工具，操作非常顺畅；AstrBot 作为独立的基础设施框架，没有官方自动迁移命令，通常需要手动配置或部分数据迁移。

  ### 迁移到 Hermes Agent（推荐，有官方无缝迁移）

  Hermes Agent 专门为 OpenClaw 用户设计了迁移路径，能自动导入：

  - 配置（平台接入、设置等）
  - 记忆（长期/短期记忆、SOUL.md 等）
  - 技能（Skills）
  - API 密钥（可选）
  - 部分会话历史（较新版本支持更好）

  #### 迁移步骤（保姆级）：

  1. 安装 Hermes Agent

     - 推荐使用官方安装脚本（Linux/macOS/WSL2）：

       Bash

       ```
       curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
       ```

     - 然后运行初始化：hermes setup（安装向导会自动检测 OpenClaw 并提示迁移）。

  2. 执行迁移命令

     （核心步骤）：

     - 先预览（强烈推荐，不修改任何文件）：

       ```
       hermes claw migrate --dry-run
       ```

     - 正式迁移（交互式，会显示预览并确认）：

       ```
       hermes claw migrate
       ```

     - 其他常用参数：

       - --preset full：完整迁移（含 API keys）
       - --yes 或 --overwrite：跳过确认、覆盖冲突
       - --source /path/to/openclaw：如果 OpenClaw 不在默认路径（~/.openclaw）

  3. 迁移后操作：

     - 运行 hermes setup 完成剩余配置（模型、平台网关等）。
     - 启动网关：hermes gateway（或后台运行）。
     - 测试技能和记忆是否正常导入。
     - 如果有问题，可参考官方文档检查路径映射。

  **官方迁移文档**（强烈建议先读）： https://hermes-agent.nousresearch.com/docs/guides/migrate-from-openclaw

  **GitHub 主页**（含 README 迁移说明）： https://github.com/NousResearch/hermes-agent

  **实用视频教程**（中文，保姆级，包含安装+迁移+实战）：

  - 从 OpenClaw 到 Hermes Agent：安装、迁移、配置、实战演示（YouTube） https://www.youtube.com/watch?v=SNzEM5ilwJ8
  - Hermes Agent 自我进化 + 完美平滑迁移全流程（YouTube） https://www.youtube.com/watch?v=WPtm7mJKUR4
  - Bilibili 相关实测视频也可搜索“OpenClaw Hermes 迁移”

  **注意事项**：

  - 迁移后建议备份 OpenClaw 目录（会自动备份为 ~/.openclaw.pre-migration-日期）。
  - 部分复杂多 Agent 或旧格式 Skill 可能需手动调整。
  - 新版本（v0.3.0+）迁移工具已很成熟，社区反馈整体顺畅。
