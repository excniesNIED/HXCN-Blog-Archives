# GitHub Star Batch Classification Article Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Publish a fact-grounded Chinese tutorial and technical postmortem for classifying 2098 GitHub Stars with `gh` CLI and GraphQL, then synchronize the same article into the local Stars backup repository.

**Architecture:** The archive copy is the publication source of truth with repository frontmatter. The backup copy is kept byte-for-byte identical after writing so commands, verified counts, and maintenance guidance cannot drift. Validation checks frontmatter, factual counts, token patterns, GraphQL syntax, and exact file equality.

**Tech Stack:** Markdown, GitHub CLI (`gh`), GitHub REST API, GitHub GraphQL API, Bash, Python, jq.

---

### Task 1: Draft the publication article

**Files:**
- Create: `20260801-github-stars-batch-classification/index.md`
- Reference: `docs/plans/2026-08-01-github-stars-batch-classification-design.md`
- Reference: `/home/excnies/stars-backup/AGENTS.md`
- Reference: `/home/excnies/stars-backup/overview.md`

**Step 1: Create the article directory**

Run:

```bash
mkdir -p 20260801-github-stars-batch-classification
```

Expected: directory exists and is untracked.

**Step 2: Write repository-compatible frontmatter**

Include:

```yaml
---
title: GitHub Star 太多怎么整理？用 gh CLI 和 GraphQL 批量分类 2098 个收藏仓库实录
pubDatetime: 2026-08-01T00:00:00.000+08:00
slug: github-stars-batch-classification
tags:
  - GitHub
  - GitHub Star
  - gh CLI
  - GraphQL
  - 自动化
  - AI Agent
category: 配置环境的日常
description: 使用 gh CLI 和 GitHub GraphQL 批量整理 2098 个 Star 的真实实录，包含旧列表备份、全量拉取、两轮分类、25 个列表重建、权限问题、静默失败复盘和逐分类核验。
---
```

**Step 3: Write the factual lead and background**

State the verified result first: 2098 Stars, 31 old lists, 32-list limit, 25 new categories, 25/25 counts matching, 2098/2098 assigned. Use first-person experience and avoid generic tutorial framing.

**Step 4: Write the complete workflow**

Cover, in this order:

1. 背景与已完成结果
2. GitHub Star 与 List API 边界
3. `gh` 环境和 `user` scope
4. 备份原 Star / List
5. 全量拉取 Star
6. 先探索再确定 25 类
7. `AGENTS.md` 分类标准
8. 先删旧列表再建新列表
9. 全量 GraphQL 归位
10. 逐分类核验
11. 技术复盘
12. 后续新增 Star 的维护方法

**Step 5: Embed only working command forms**

Requirements:

- REST pagination uses `'/user/starred?per_page=100'`.
- Every GraphQL command uses `-f 'query=...'` or `-f "query=..."`.
- `updateUserListsForItem` uses inline literal `listIds`, not the failed `-F` array form.
- Token examples use placeholders only.
- Explain that `updateUserListsForItem` replaces complete list membership.

### Task 2: Run the de-AI writing pass

**Files:**
- Modify: `20260801-github-stars-batch-classification/index.md`

**Step 1: Diagnose structure**

Search for and remove formulaic headings or phrasing such as:

- 为什么要重新分类
- 本文将
- 接下来我们
- 综上所述
- 值得注意的是（when used as filler）

**Step 2: Repair voice and pacing**

- Keep first person stable.
- Use concrete failure/result statements.
- Convert repeated bullet recaps into prose where clearer.
- Keep numbered steps only where readers must act in order.
- Retain uncertainty where behavior is empirical rather than official.

**Step 3: Preserve facts**

Confirm these exact numbers remain: `2098`, `31`, `32`, `89`, `25`.

### Task 3: Synchronize the backup copy

**Files:**
- Source: `20260801-github-stars-batch-classification/index.md`
- Modify: `/home/excnies/stars-backup/blog-批量分类star教程.md`

**Step 1: Copy the publication article**

Run:

```bash
cp 20260801-github-stars-batch-classification/index.md /home/excnies/stars-backup/blog-批量分类star教程.md
```

Expected: both files are byte-for-byte identical.

### Task 4: Validate the article

**Files:**
- Validate: `20260801-github-stars-batch-classification/index.md`
- Validate: `/home/excnies/stars-backup/blog-批量分类star教程.md`

**Step 1: Validate synchronization**

Run:

```bash
cmp 20260801-github-stars-batch-classification/index.md /home/excnies/stars-backup/blog-批量分类star教程.md
```

Expected: exit code 0.

**Step 2: Validate required facts and syntax**

Run targeted checks for:

- title, pubDatetime, slug, tags, category, description
- `2098`, `31`, `32`, `89`, `25`
- `createUserList`, `deleteUserList`, `updateUserListsForItem`
- `query=mutation`

Expected: all terms present.

**Step 3: Validate no leaked credentials**

Search both files for:

```regex
gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}
```

Expected: no matches.

**Step 4: Commit archive changes**

Use a Lore-format commit that explains why the article keeps a real failure analysis rather than publishing only a happy-path command list.
