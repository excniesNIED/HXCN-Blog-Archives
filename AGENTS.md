# AGENTS.md — HXCN-Blog-Archives

本仓库是博客 [萑澈的寒舍](https://hs.cnies.org)（Halo 2.25.4）的文章 **Markdown 归档备份**。站点是内容的事实来源（source of truth）：仓库内的 front matter 可能滞后于线上，**以线上站点的标题、slug、分类为准**（sitemap: https://hs.cnies.org/sitemap.xml）。

## 新文章格式

每篇文章一个目录，命名 `YYYYMMDD-<kebab-slug>/`，主文件为 `index.md`：

```markdown
---
title: <文章标题>
pubDatetime: 2026-08-01T00:00:00.000+08:00
slug: <kebab-case-slug>
tags:
  - <标签>
  - <标签>
category: <站点分类>
description: <SEO 描述，见下节模板>
---
```

规则：

- **目录名**：`YYYYMMDD-<slug>/`，日期取文章发布日期。
- **slug**：kebab-case 英文。注意：线上 slug 可能与仓库 front matter 不一致（如 STL 文章线上为 `algorithm-STL-time-complexity-2025`），引用/生成链接时以 sitemap 为准。
- **pubDatetime**：ISO 8601，含时区，格式 `YYYY-MM-DDTHH:MM:SS.000+08:00`。
- **category**：只用站点现有 5 个分类之一：
  - `配置环境的日常`（envs）
  - `折腾Linux的日常`（linux）
  - `被算法折磨的日常`（algorithms）
  - `踩坑日志`（exception）
  - `天空之镜`（hevspecu）
- **英文版本**：两种既有模式均可——
  1. 独立目录 `YYYYMMDD-<slug>-en/index.md`（slug 加 `-en` 后缀）；
  2. 与中文版同目录 `index.en.md`（slug 仍加 `-en` 后缀）。
- **封面**：`Cover.png` / `Cover.webp` 放在文章目录内，生成方式见下节。
- **图片**：正文图片引用线上对象存储 `https://gastigado.cnies.org/d/...`，不提交大体积本地图片（归档除外）。
- **空壳目录**：没有 front matter 的空 `index.md`（如 `20241003-wsl-arch-install-scripts`）视为未发布草稿，不参与 llms.txt。

## 封面生成

使用本地工具 `~/image-gen/`（GPT Image 2 独立生成脚本）生成封面：

```bash
cd ~/image-gen
npm run generate -- "<提示词>"
```

- 配置已内置于 `~/image-gen/.env`（`BASE_URL` / `API_KEY`），无需额外设置。
- 输出到 `~/image-gen/output/YYYY-MM-DDTHH-MM-SS-N.png`，复制到文章目录并命名为 `Cover.png`（如需 `Cover.webp` 自行转换）。
- 提示词要求：指定主题、构图、配色；明确「不要文字/水印」（正文标题由 Halo 站点叠加，封面不要自带文字）。

**可选封面风格**（后续会继续增加）：

- [Anthropic 编辑插画风](https://github.com/HalfAI1102/anthropic-art)：满版柔和背景 + 不规则象牙白承载形 + 近黑色粗手绘线条。

## description 模板

一句话定位 + 内容清单 + 附加价值 + 目标读者：

```
{主题}教程，从零讲解{核心步骤/要点，顿号分隔}，并附{补充内容}。适合{目标读者}。
```

示例（已发布文章）：

> Ubuntu 22.04 LTS 与 Windows 11 双系统安装教程，从零讲解安装前准备、关闭 BitLocker 与快速启动、下载镜像、制作启动盘、磁盘分区、BIOS 启动、安全启动、Ubuntu 安装和系统切换，并附引导与时间问题参考。适合新手搭建 Linux 开发环境。

要点：50–150 字；覆盖关键词（工具名、系统名、技术栈）；结尾必须给出目标读者；英文版同结构译写。

## llms.txt 维护

`llms.txt` 位于仓库根，遵循 https://llmstxt.org 规范，是站点的 LLM 友好索引。结构固定：

```
# 萑澈的寒舍            ← H1（站点名，唯一必需节）
> <站点 meta-description>   ← blockquote 简介
<详情段落>               ← 非标题内容（口号、分类导航等）
## 中文文章              ← H2 文件列表
- [标题](https://hs.cnies.org/archives/<slug>): 一句话说明
## English Posts
- [Title](https://hs.cnies.org/archives/<slug-en>): one-line note
## Optional              ← 必须位于文件末尾（可跳过内容）
```

**新增文章时必须同步更新 llms.txt：**

1. 在对应语言分区（`## 中文文章` / `## English Posts`）追加条目，格式 `- [标题](URL): 说明`，说明沿用 front matter 的 description 精炼版（一句话）。
2. **URL 的 slug 必须取线上 sitemap 中的值**（`https://hs.cnies.org/sitemap.xml` 的 `/archives/` 条目），不要直接抄仓库 front matter——两者可能不一致。
3. **标题取线上文章 `<title>`**（去掉 ` - 萑澈的寒舍` 后缀），不用仓库 front matter 的旧标题。
4. 校验项：
   - 每个条目匹配 `^- \[[^\]]+\]\(https://hs\.cnies\.org/archives/[a-zA-Z0-9-]+\)(: .+)?$`；
   - llms.txt 中 `/archives/` URL 集合 == sitemap 中文章 URL 集合（无缺失、无多余）；
   - 结构顺序：H1 → blockquote → 详情 → H2 列表 → 末尾 `## Optional`；
   - 无尾随空格。

## 提交规范（Conventional Commits）

```text
<type>(<scope>): <subject>
```

- type：`feat`（新文章/新功能）、`fix`（修正内容/链接/标题）、`docs`（文档/文章内容修改）、`style`（措辞润色）、`chore`（资产归档、杂务）、`refactor`。
- scope：常用 `articles`、`assets`、文章 slug 片段（如 `mimo`、`openclaw2hermes`、`academic-edu-refund`）、`llms.txt`。
- subject：祈使句、小写开头（中文除外）、≤ 72 字符。

示例：

```text
feat(articles): publish English translation of GitHub Stars batch-classification article
fix(articles): retitle post for click-through and Google length limits
docs(llms.txt): add entry for new article
```

已推送的历史不可随意改写；确需改写时用 `git filter-branch --msg-filter` + `--force-with-lease` 推送，并先 stash 未提交改动。
