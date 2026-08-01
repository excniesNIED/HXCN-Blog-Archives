# GitHub Star 批量分类文章设计

## 目标

把现有 `~/stars-backup/blog-批量分类star教程.md` 重写为可发布的中文技术文章，并在归档仓库创建正式稿：

- `20260801-github-stars-batch-classification/index.md`
- 同步覆盖 `~/stars-backup/blog-批量分类star教程.md`

文章面向第一次使用 `gh` CLI、不了解 GitHub GraphQL、收藏仓库数量较多的用户。读者完成文章后，应能独立执行旧列表备份、Star 拉取、分类体系设计、GraphQL 列表创建、仓库归位和结果核验。

## 文风

以 HXCN-Blog-Archives 的个人实录为主：

- 第一人称说明真实场景、做法与踩坑，不使用空泛的教程套话。
- 先说明边界和容易误判的地方，再给命令和步骤。
- 命令后解释为什么这样写、写错会发生什么。
- 高频问题放在正文相应步骤内，文末保留压缩后的复盘清单。

吸收两家科技媒体的优点，但不模仿其固定口头禅：

- 蓝点网：标题包含核心问题、工具、结果，导语信息密度高，结论直白。
- IT 之家：首段先交代时间、对象、数据与已验证结果；关键数字加粗；来源和事实边界清楚。

降低 AI 味：

- 不使用“为什么要重新分类”“本文将带你”“接下来我们”等模板化引导。
- 不做对称式三段总结，不重复复述步骤。
- 避免每节都用同一种开头，段落长短自然变化。
- 不编造来源、数据、速度或 GitHub API 行为。
- 保留实际失败：REST 404、缺少 `user` scope、`query=` 前缀遗漏、数组变量解析、空列表核验和全量幂等重跑。

## 标题与元数据

标题方向：

> GitHub Star 太多怎么整理？用 gh CLI 和 GraphQL 批量分类 2098 个收藏仓库实录

Frontmatter：

- `pubDatetime`: `2026-08-01T00:00:00.000+08:00`
- `slug`: `github-stars-batch-classification`
- `tags`: GitHub、gh CLI、GraphQL、GitHub Star、自动化、AI Agent
- `category`: 技术教程 / 配置环境的日常
- `description`: 明确写出 2098 个仓库、31 个旧列表、25 个新列表、GraphQL 批量归位和核验。

## 文章结构

1. **背景**：2098 个 Star、31 个列表、32 个上限；旧列表仅覆盖 89 条成员关系。
2. **先看结果**：25 个分类、2098/2098 全部归位、逐分类数量匹配。
3. **GitHub 列表 API 的边界**：Star 拉取走 REST；列表管理只能走 GraphQL；mutation 要 `user` scope。
4. **准备环境与权限**：安装/登录 `gh`，临时 PAT 与吊销说明。
5. **备份现有 Star 和列表**：数据格式、`node_id`、联合类型片段。
6. **拉取全部 Star**：内联 `?per_page=100` 的实际可用写法及 `-f` 404 复盘。
7. **先探索，再定分类**：解释两轮子代理流程、分类上限和留冗余原则。
8. **把标准写进 AGENTS.md**：决策顺序、划入标准和边界规则。
9. **删旧建新**：为什么受 32 个上限影响必须先删旧列表。
10. **批量归位**：`updateUserListsForItem`、内联 GraphQL 字面量、并行与重试。
11. **技术复盘**：静默失败原因、验证为何必须逐分类比较，设备流与临时目录的风险。
12. **核验与后续维护**：25/25、2098/2098；新 Star 的单仓库入列命令；备份目录说明。

## 事实与数据

正文必须保持以下已验证事实：

- 账号：`excniesNIED`
- Star 数量：2098
- 原列表：31
- GitHub 列表上限：32
- 原列表成员关系：89
- 新列表：25
- 核验：25 个列表数量全部与分类文件一致，总和 2098
- Star REST：`GET /user/starred`
- 列表 GraphQL：`createUserList`、`deleteUserList`、`updateUserListsForItem`
- `updateUserListsForItem` 会替换仓库的完整列表成员关系

## 验证标准

- 归档稿和备份稿正文一致。
- Frontmatter 符合归档仓库现有格式。
- 代码块中无真实 PAT、验证码、账号密钥。
- 所有 GraphQL 命令包含 `query=`。
- 不使用失败的 `-F` 数组写法作为推荐方案。
- 文章不把社区/实测结论写成 GitHub 官方承诺。
- 去 AI 味复核：删除模板式引导、空泛结论和重复总结。
