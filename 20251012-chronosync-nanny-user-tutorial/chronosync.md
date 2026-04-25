---
title: 时序同笺 (SDNUChronoSync)
pubDatetime: 2025-10-12T00:00:00.000+08:00
slug: chronosync
tags:
  - 时序同笺
  - SDNU
  - 正方教务
  - 课表
  - SDNUChronoSync
  - 团队协作
  - Astro
category: 天空之镜
description: 一个现代化的响应式多用户课表与日程管理 Web 应用，专为山东师范大学设计。功能包括个人与团队日历视图、ICS 导出以及用于用户和日程管理的管理员权限。A modern, responsive multi-user schedule management web app for SDNU. Features include personal and team calendar views, ICS export, and admin controls for user and schedule management. Built with a Python (FastAPI) backend and a TypeScript (Astro, Vue.js) frontend.
---

## 🌐 在线访问

**线上地址：[https://sxtj.hxcn.space](https://sxtj.hxcn.space)**

**使用教程：[时序同笺保姆级用户教程](https://hs.cnies.org/archives/chronosync-nanny-user-tutorial)**

欢迎访问在线版本，体验完整的课表与日程管理功能。

## 📋 项目简介

时序同笺 (SDNUChronoSync) 是一个现代化的、全功能的多用户课表与日程管理 Web 应用，专为山东师范大学设计。支持个人多课表管理、高级调休功能、完整的团队协作系统，以及灵活的管理员控制功能。专为教育机构和团队协作场景设计。

## ✨ 功能特性

### 个人日程管理

- **多课表管理**：支持创建多个课表，如"大二上学期"、"大二下学期"等
- **灵活导入方式**：
  - 从正方教务系统一键导入课表
  - 从ICS文件导入（支持其他日历应用导出的文件）
  - 手动创建日程事件
- **灵活的日程编辑**：支持手动创建、编辑和删除日程事件
- **多视图模式**：支持课表周视图、日历日视图、甘特图周视图、周列表视图四种模式自由切换
- **月视图分栏联动**：月视图支持左侧月历 + 右侧当日课表分栏，点击日期即可查看当日分组课程
- **个性化卡片配色**：支持单色/多彩两种卡片配色模式，并可分别调整背景色、文字色、当前时间指示线和即将开始课程高亮样式
- **自定义日期/时间选择器**：日期与时间输入统一使用弹出式日历/时间面板，支持在抽屉、弹窗和移动端视口中自适应定位
- **多种导出格式**：
  - 导出为PNG图片，方便分享截图
  - 导出为ICS文件，兼容各大日历应用（苹果日历、Google Calendar等）

### 智能调休系统

- **节假日设置**：HOLIDAY类型调整，逻辑隐藏指定日期的所有课程
- **智能换课系统**：SWAP类型调整，将源日期课程完整移动到目标日期
- **服务器端逻辑**：调休计算在后端处理，确保数据一致性和完整性
- **调休记录追踪**：完整记录所有调休操作的历史和影响范围
- **实时生效机制**：调休设置立即在课表视图中反映，无需刷新

### 团队协作系统

- **智能邀请机制**：8位随机邀请码（大写字母+数字，避免易混淆字符0,O,1,I）
- **灵活团队管理**：团队创建者自动成为管理员，支持添加/移除成员、编辑团队介绍和团队图标
- **团队管理员角色**：支持指定团队管理员，分担团队管理工作
  - 创建者可以提升成员为团队管理员
  - 团队管理员拥有成员管理和课表管理权限
  - 支持随时添加或移除团队管理员权限
- **团队所有权转让**：创建者可以将团队管理权转让给其他成员
- **分层权限控制**：系统管理员 > 团队创建者 > 团队管理员 > 普通成员的四级权限体系
- **团队课表聚合**：实时查看团队所有成员的活跃课程安排和时间冲突
- **高级筛选功能**：支持按成员姓名、学号、班级、年级等多维度筛选
- **团队资料增强**：团队列表卡片展示团队介绍、团队图标、邀请码和成员预览，创建/编辑时支持上传图标与选择预设图标
- **便捷成员操作**：通过学号精确添加成员，支持成员自主退出和管理员移除
- **团队生命周期管理**：从创建、管理、转让到解散的完整流程

### 管理员功能

- **用户管理**：创建、编辑、删除用户账户
- **用户状态管理**：支持多种封禁类型（账号封禁、IP封禁、邮箱封禁）和恢复用户账户
- **高级筛选功能**：支持按角色、封禁状态等多维度筛选用户
- **登录记录监控**：查看所有用户的登录历史和活动追踪
- **批量操作**：支持批量删除、封禁、恢复用户，配合批量操作工具栏高效管理
- **团队监控**：监管所有团队的运行状态
- **系统设置**：配置头像上传、存储、邮箱通知等系统参数
- **站点配置**：自定义站点名称、描述、Logo和Favicon
- **邮箱配置**：配置SMTP服务器、测试邮件连接

### 高级功能

- **课表分享系统**：
  - 生成公开分享链接（支持有效期和权限设置）
  - 访问者可查看或导入分享的课表
  - 完整的分享管理面板（查看访问量、二维码、撤销分享）
- **空教室查询系统**：
  - 实时查询山东师范大学各校区空闲教室
  - 支持按时间段、教学楼、教室类型筛选
  - 独立会话管理，不影响平台登录状态
  - 直观的查询结果展示
- **首页引导与演示系统**：
  - 首页升级为完整落地页（导航栏、主题 Hero、功能区、CTA 区）
  - Hero 区"井然有序"标题下方加粗连续波浪下划线，教程按钮与注册/登录/特色功能并排展示
  - 提供团队排班、空教室查询、课表分享（图片/链接/ICS）、教务导入、团队管理的交互式演示卡片
  - `PerspectiveSchedule` 使用真实 demo 课程数据展示三种日程视图，并保留自动轮播课程详情弹窗动画与当前时间标签
  - 关键流程内置教程入口（导入、调休、团队协作等）
- **站点配置系统**：
  - 动态修改站点标题、描述和关键词
  - 支持上传或使用外部链接设置Logo和Favicon
  - 受控代码注入（统计脚本 / 样式表 / Meta 标签）

## 🔐 受控代码注入（Analytics / Styles / Meta）

本项目支持在页面 `head` / `body` 注入第三方统计或样式资源，但为避免 XSS 风险，已将“代码注入”收敛为**受控白名单机制**：后端负责解析与校验，前端仅按结构化数据创建 DOM 元素（不使用任意 HTML 注入）。

### 校验失败时的行为

- **系统设置页保存**：校验失败会拒绝保存（返回 400），并提示具体原因。
- **配置文件预置（config.toml）**：配置依然会被正常加载，但系统设置页会显示校验告警，并对有问题的编辑器区域进行红色高亮提示；公开端点会 fail-closed（返回空列表，不注入任何内容）。

### 允许的标签与限制

- **允许的标签**
  - `script`：必须使用 `src`（禁止 inline script）
  - `link`：仅允许 `rel="stylesheet"` 且必须使用 `href`
  - `meta`：仅允许 `name/property + content`（禁止 `http-equiv` / `charset`）
- **允许的属性**
  - `script`：`src`, `async`, `defer`, `type`, `integrity`, `crossorigin`, `referrerpolicy`, 以及 `data-*`
  - `link`：`rel`, `href`, `media`, `integrity`, `crossorigin`, `referrerpolicy`
  - `meta`：`name`, `property`, `content`
- **URL 规则**
  - 同源脚本只允许 `/assets/*.js`
  - 同源样式只允许 `/assets/*.css`
  - 外部资源只允许 `https://` 且域名必须在白名单 `CODE_INJECTION_ALLOWED_HOSTS` 中
- **安全限制**
  - 禁止任何事件属性（如 `onclick`）
  - 最大长度：`20_000` 字符；最大条目数：`50`
  - 校验失败会拒绝保存 / 或公开端点返回空列表（fail-closed）

### 如何添加 Umami（示例）

在管理后台 → 系统设置 → 代码注入（Header）中填写：

```html
<script defer src="https://analytics.hxcn.dev/script.js" data-website-id="<your-id>"></script>
```

其中 `data-website-id` 属于 `data-*`，会被保留并透传。

### 如何配置外域白名单（CODE_INJECTION_ALLOWED_HOSTS）

- **源码/直接运行（本地开发）**
  - **步骤 1：写入 `backend/.env`**（推荐）
    - 在 `backend/.env` 添加：
      - `CODE_INJECTION_ALLOWED_HOSTS=analytics.hxcn.dev`
  - **步骤 2：重启后端服务**
    - 重新启动 `uv run python main.py` / `uv run uvicorn` 进程（环境变量只在进程启动时读取）。
  - **可选：用系统环境变量代替 `.env`**
    - Linux/macOS：
      - `export CODE_INJECTION_ALLOWED_HOSTS=analytics.hxcn.dev`
    - Windows PowerShell：
      - `$env:CODE_INJECTION_ALLOWED_HOSTS="analytics.hxcn.dev"`
    - 多个域名用逗号分隔：
      - `CODE_INJECTION_ALLOWED_HOSTS=analytics.hxcn.dev,hm.baidu.com`

- **systemd 部署（后端进程托管）**
  - **步骤 1：在 unit 文件中增加环境变量**
    - `Environment="CODE_INJECTION_ALLOWED_HOSTS=analytics.hxcn.dev"`
    - 或使用 `EnvironmentFile=/path/to/your.env`
  - **步骤 2：重新加载并重启服务**
    - `systemctl daemon-reload`
    - `systemctl restart <your-service-name>`

- **Docker Compose 部署**
  - **步骤 1：在 `docker-compose.yml` 添加环境变量**
    - 在服务的 `environment:` 中增加：
      - `CODE_INJECTION_ALLOWED_HOSTS=analytics.hxcn.dev`
  - **步骤 2：重启容器**
    - `docker compose up -d --build`（或 `docker compose restart`）

- **Docker 单容器部署（docker run）**
  - **步骤：启动时添加 `-e`**
    - `docker run ... -e CODE_INJECTION_ALLOWED_HOSTS=analytics.hxcn.dev ...`
  - 已在跑的容器需要重建/重启（修改容器环境变量不能热更新）。

### CSP 注意事项

如果你允许外域统计脚本，反向代理层（Nginx/Caddy/Cloudflare 等）需要同步放行：

- `script-src` / `script-src-elem`：允许脚本域名
- `connect-src`：允许统计上报域名（很多统计会用 `fetch` 上报）

Docker 镜像自带的 `docker/nginx.conf` 已包含 CSP 示例配置；如果你更换统计域名，需要同步更新 CSP。

### UI/UX 特性

- **响应式设计**：完美适配桌面、平板和手机
- **可折叠侧边栏**：支持展开/收起状态持久化，节省屏幕空间；折叠后图标悬停显示 Tooltip 提示导航名称
- **统一认证页壳**：登录、注册、找回密码统一使用 AuthShell 布局，减少重复并保持体验一致
- **OTP验证码输入**：注册、找回、绑定邮箱/改密等流程统一使用多格 OTP 输入组件
- **表单反馈一致性**：认证与空教室登录表单统一使用 Toast 反馈，不依赖浏览器原生提示
- **统一模态框系统**：基于Headless UI的可访问性组件
- **统一页面头卡系统**：个人中心、我的团队、我的课表等页面使用统一 PageHeaderCard 顶部信息卡片
- **Toast通知系统**：HeroUI风格的3D堆叠Toast通知，支持多种类型和自动消失
- **智能加载指示器**：统一的加载状态视觉反馈
- **实时状态反馈**：操作结果立即反馈给用户
- **直观的视觉设计**：清晰的信息层次和交互指引
- **批量操作支持**：高效的批量管理功能，配合批量操作工具栏
- **自定义滚动条**：优雅的细滚动条样式，提升视觉体验
- **固定表头设计**：大数据表格支持固定表头，滚动内容时表头保持可见
- **弹层层级与菜单自适应**：下拉/弹窗层级统一，管理员列表操作菜单根据剩余空间自动向上/向下展开；日期/时间选择器在抽屉和移动端中会自动避让边缘；带搜索的下拉菜单会保持实底搜索区并支持点击外部关闭
- **更新日志集成**：实时查看系统版本更新内容

### 高性能架构

- **前后端分离**：Astro + Vue.js 前端，FastAPI 后端
- **智能状态管理**：Pinia 驱动的响应式状态系统
- **数据库优化**：SQLAlchemy ORM 的高效查询
- **API设计**：RESTful接口设计，支持并发访问
- **开发期稳定性优化**：Vite 预构建排除 `@headlessui/vue`，并使用 `astro dev --force` 降低依赖缓存失效导致的水合异常

## 📖 使用指南

### 🎯 首页与新手引导

1. **访问首页**：

   - 未登录用户可直接从首页进入注册/登录
   - 已登录用户可从首页右上角菜单进入工作台或个人中心
   - 退出登录后将返回首页，不再强制跳转登录页
   - 从退出态重新登录时，会默认回到 `/dashboard/my-schedule`

2. **查看交互演示**：

   - 首页提供日程视图、团队协作、空教室查询三类可视化演示
   - 可快速了解核心功能后再进入工作台实操

3. **使用教程入口**：

   - 首页功能区、导入弹窗、调休页、团队页均提供教程跳转入口
   - 可直达“个人课表 / 导入课表 / 高级调休 / 团队协作”对应章节

### 🎯 个人课表管理

1. **创建课表**：

   - 访问"我的课表"页面
   - 点击课表下拉菜单中的"新建课表"
   - 设置课表名称、学期开始日期和总周数
   - 如果当前没有可用课表，页面空状态仍会直接提供"新建课表"、"导入课表"和教程入口

2. **使用"更多"操作菜单**：

   - 点击页面右上角的"更多"按钮，可访问以下功能：
     - **添加日程**：手动创建日程事件
     - **导入课表**：选择从ICS文件或教务系统导入
     - **分享课表**：生成分享链接、导出为图片或ICS文件
     - **放假调休**：设置节假日和课程对调
     - **课表设置**：编辑课表名称、日期等信息

3. **切换视图与跳转日期**：

   - 课表页顶部可直接切换课表、视图和课表操作菜单
   - 支持课表、日历、甘特、周列表四种视图
   - 顶部"跳转"与各类日期/时间输入均使用统一弹出式选择器

4. **导入课程**：

   - **从教务系统导入**：
     - 点击"更多" → "导入课表" → "从教务系统导入"
     - 输入学号、密码和验证码
     - 系统自动获取并导入课表

   - **从ICS文件导入**：
     - 点击"更多" → "导入课表" → "从ICS文件导入"
     - 选择从其他日历应用导出的.ics文件
     - 系统自动解析并导入事件

   - **手动添加**：
     - 点击"更多" → "添加日程"
     - 或直接点击日历上的日期

5. **分享与导出**：

   - 点击"更多" → "分享课表"打开分享面板，提供以下功能：

   - **生成分享链接**（推荐）：
     - 创建公开访问链接，支持设置有效期和导入权限
     - 可在分享详情中查看二维码、访问次数与权限说明
     - 适合发送给好友或在社交媒体分享
   
   - **导出为图片**：
     - 选择"导出图片"选项
     - 下载当前课表的 PNG 截图，适合打印或保存
   
   - **导出为ICS**：
     - 选择"导出ICS"选项
     - 下载 .ics 文件，可导入到苹果日历、Google Calendar等应用

6. **多课表管理**：

   - 支持同时管理多个课表（如不同学期）
   - 通过下拉菜单快速切换活跃课表
   - 每个课表独立管理课程和调休设置

### 🎯 高级调休功能

1. **节假日设置（HOLIDAY类型）**：

   - 在"我的课表"页面点击"更多" → "放假调休"
   - 选择"设置假期"模式
   - 选择需要放假的日期
   - 点击"确认放假"，系统将逻辑隐藏该日期的所有课程

2. **智能换课（SWAP类型）**：

   - 点击"更多" → "放假调休"
   - 选择"对调工作日"模式
   - 设置源日期（需要移动的课程日期）
   - 设置目标日期（课程移动到的日期）
   - 系统自动创建覆盖事件，保持原有课程信息

3. **调休记录管理**：

   - 所有调休操作记录在ScheduleAdjustment表中
   - 支持查看调休历史和影响的事件数量
   - 调休效果立即在课表视图中生效

### 🎯 课表分享功能

1. **创建分享**：

   - 在"我的课表"页面点击"更多" → "分享课表"
   - 设置有效期（1天、7天、30天、永久）
   - 设置访问权限：
     - **仅查看**：访问者只能查看课表，无法进行其他操作
     - **需要登录**：访问者必须登录系统才能查看
     - **允许导入**：访问者可以将课表保存到自己的账户
   - 点击"生成链接"获取分享链接
   - 在手机上打开分享面板时，二维码、权限说明与操作按钮会自动改为更紧凑的纵向布局

2. **管理分享**：

   - 在"分享课表"面板下方查看所有分享历史
   - 实时监控每个链接的访问次数
   - 支持随时撤销（删除）分享链接，链接失效后无法访问

3. **访问分享**：

   - 访问分享链接进入只读课表视图
   - 支持切换周/月视图查看
   - 如果权限允许，点击"导入课表"将课程复制到自己的账户

### 🎯 团队协作系统

#### 1. 创建团队

- 访问"我的团队"页面（导航栏"团队"菜单）
- 点击右上角"创建团队"
- 输入团队名称、团队介绍，并可上传图标或选择预设图标
- 点击"创建团队"按钮
- 系统自动生成8位安全邀请码（避免0O1I等易混淆字符）
- 创建者自动成为团队管理员并加入成员列表
- 页面显示团队代码，可一键复制分享给成员

#### 2. 加入团队

- 向团队创建者获取8位团队邀请码
- 点击"加入团队"并输入邀请码（自动转换为大写）
- 点击"加入团队"按钮
- 系统验证邀请码有效性后自动加入团队
- 成功加入后可立即查看团队课表

#### 3. 团队管理（创建者和团队管理员）

  **基础管理：**

- 点击团队卡片上的"管理团队"按钮
- 打开高级团队管理面板
- 可编辑团队名称、团队介绍和团队图标
- 预设图标抽屉支持直接生成并上传团队图标
- 查看创建的所有团队及成员统计
  **成员管理：**

- **添加成员**：在团队编辑窗口输入学号，系统自动查找并添加用户

- **移除成员**：点击成员列表中的"移除"按钮删除成员
  - 团队管理员可以移除普通成员
  - 不能移除团队创建者和系统管理员

- **查看成员**：查看所有成员的姓名、学号、班级等信息
  **团队管理员管理（仅创建者）：**

- **提升管理员**：
  - 在团队成员列表中选择普通成员
  - 点击"设为管理员"按钮
  - 该成员将获得团队管理权限
  - 团队管理员可以管理成员、编辑团队信息

- **移除管理员**：
  - 在团队管理员列表中选择要降级的管理员
  - 点击"移除管理员"按钮
  - 该用户将降级为普通成员
  **团队转让（仅创建者）：**

- 点击"转让团队"按钮

- 从当前成员列表中选择新的团队创建者

- 确认后，团队所有权和管理权限将转移给新创建者

- 原创建者将变成普通成员
  **解散团队（仅创建者）：**

- 点击"解散团队"按钮

- 输入团队名称进行二次确认

- 确认后团队及所有成员关系将被永久删除

- 此操作不可撤销

#### 4. 退出团队（普通成员）

- 在"我的团队"页面找到要退出的团队
- 点击团队卡片上的"退出团队"按钮
- 在弹出的确认窗口中确认退出
- 退出后将无法再访问该团队的课表

#### 5. 团队课表聚合视图

   **查看团队课表：**

- 点击团队卡片上的"查看课表"按钮

- 进入团队课表聚合视图页面

- 显示所有成员的活跃课表（status="进行"）

- 不同成员的课程用不同颜色标识
  **高级筛选功能：**

- **按成员筛选**：勾选特定成员，只显示其课程

- **按成员搜索**：成员多选下拉支持即时搜索

- **按班级筛选**：选择班级，显示该班级所有成员的课程

- **按年级筛选**：选择年级，显示该年级所有成员的课程

- **关键词搜索**：搜索成员姓名或课程名称

- **移动端支持**：移动端提供侧边筛选抽屉
  **视图模式：**

- **周视图**：查看一周的课程安排，适合查看详细时间

- **月视图**：查看整月的课程分布，适合宏观规划

- **日期导航**：前后翻页或跳转到今天
  **课程冲突识别：**

- 同一时间多个成员有课时，可点击查看详情

- 显示所有冲突的课程列表

- 标识出每门课的授课教师和地点

- 便于协调团队会议时间

#### 6. 管理员团队监控

- 访问管理后台"团队管理"页面
- 查看系统中所有团队的统计信息
- 搜索和筛选特定团队
- 查看任意团队的成员列表
- 必要时删除不活跃或违规的团队

### 🎯 个人资料管理

1. **基本信息**：

   - 查看和编辑个人信息（姓名、学号、班级、年级、学院、个人简介）
   - 上传和更换头像（支持本地存储/AList）
   - 支持选择预设头像，并在本地生成后上传到当前存储
   - 查看账户统计：课表数、课程数、注册时间

2. **邮箱管理**（v2.7.3+）：

   - **绑定邮箱**：在个人资料页面绑定邮箱，用于找回密码
   - **更换邮箱**：输入新邮箱地址，获取验证码后确认更换
   - **验证码冷却**：60秒发送间隔，防止滥用
   - **清空功能**：支持清空输入内容，重新填写

3. **密码安全**（v2.7.3+）：

   - **修改密码**：输入当前密码和新密码
   - **邮箱验证**：已绑定邮箱的用户修改密码时需要输入邮箱验证码
   - **安全提升**：双重验证确保账户安全

4. **登录记录**：

   - 查看最近登录设备、IP地址、浏览器信息
   - 查看完整登录历史记录
   - 监控账户安全状态

### 🎯 界面个性化

1. **侧边栏折叠**（v2.7.3+）：

   - **展开/收起**：点击侧边栏顶部的折叠按钮切换状态
   - **状态持久化**：折叠状态自动保存，刷新页面后保持
   - **节省空间**：折叠后仅显示图标，适合小屏幕或需要更多内容空间的场景
   - **平滑过渡**：主内容区域和页脚自动适应侧边栏宽度变化

2. **主题设置**：

   - 支持浅色/深色主题切换
   - 主题偏好自动保存

3. **课表个性化**：

   - 支持单色/多彩两种日程卡片配色模式
   - 支持自定义当前时间指示线颜色与宽度
   - 支持即将开始课程的高光边框/边框跑马灯颜色设置

### 🎯 空教室查询

   - 访问"空教室查询"页面（导航栏"空教室查询"菜单）
   - 选择查询时间段和校区
   - 系统自动连接教务系统查询空闲教室
   - 支持按教学楼、教室类型等条件筛选
   - 独立会话管理，不影响平台登录状态

### 🎯 管理员功能

1. **用户管理**：

   - 创建、编辑、删除用户账户
   - 可直接维护用户邮箱，后台会自动去重、规范化并持久保存
   - 重置用户密码和角色权限
   - 查看用户的课表和活动统计
   - 用户账户封禁和恢复功能
   - 批量操作：批量删除、封禁、恢复用户
   - 批量导入导出：CSV/Excel/PDF格式导入导出用户数据
   - 高级筛选：按角色、封禁状态等多维度筛选用户
   - 查看用户登录历史和最近登录记录

2. **系统设置**：

   - 配置头像上传方式（本地存储/AList）
   - 设置文件上传限制和存储路径
   - 管理系统全局配置参数

3. **团队监控**：

   - 查看所有团队信息
   - 批量导入导出：CSV/Excel/PDF格式导入导出团队数据
   - 必要时删除团队
   - 监控团队活动和成员状况

## 🛠️ 技术栈

### 前端

- **Astro** - 静态站点生成和路由
- **Vue.ts 3** - 交互式 UI 组件
- **Tailwind CSS** - 响应式样式框架
- **Headless UI** - 无样式 UI 组件
- **Pinia** - 状态管理
- **Axios** - HTTP 客户端

### 后端

- **Python 3.10+** - 编程语言
- **FastAPI** - Web 框架
- **SQLAlchemy** - ORM
- **SQLite** - 数据库
- **JWT** - 用户认证
- **ICS** - 日历导出

## 📁 项目结构

```
SDNUChronoSync/
├── backend/                 # 后端代码
│   ├── main.py             # 应用入口
│   ├── models.py           # 数据模型 (User, Schedule, Event, ScheduleAdjustment, Team, LoginRecord, ScheduleShare)
│   ├── schemas.py          # Pydantic 模式 (包含团队、调休、登录记录相关模式)
│   ├── crud.py             # 数据库操作 (团队CRUD + 调休记录 + 登录记录管理)
│   ├── auth.py             # 认证逻辑
│   ├── database.py         # 数据库配置 (含user_teams_table, team_admins_table关联表)
│   ├── config.py           # 系统配置
│   ├── compat.py           # Python 3.12 / 旧版依赖兼容补丁
│   ├── utils.py            # 工具函数
│   ├── importer.py         # 教务系统导入
│   ├── pyproject.toml      # Python 项目定义（uv）
│   ├── uv.lock             # Python 依赖锁文件（uv）
│   ├── requirements.txt    # 兼容性依赖清单
│   ├── uvicorn_log_config.json  # Uvicorn日志配置
│   ├── scripts/
│   │   └── smoke_httpx_lifespan.py # 后端 API 冒烟脚本（ASGITransport + Lifespan）
│   ├── services/           # 服务层
│   │   ├── email.py        # 邮件发送与验证码管理服务
│   │   └── uploader_service.py  # 文件上传服务（头像/团队图标通用上传管线）
│   ├── tests/
│   │   ├── test_profile_team_metadata.py      # 资料与团队元数据 schema 测试
│   │   └── test_admin_user_update_email.py    # 管理员修改用户邮箱回归测试
│   └── routers/            # API 路由
│       ├── auth.py         # 认证路由（含登录记录、邮箱验证、找回密码）
│       ├── schedule.py     # 个人日程路由
│       ├── schedules.py    # 多课表+调休管理+ICS导入/导出路由
│       ├── team.py         # 完整团队管理路由
│       ├── admin.py        # 管理员路由（含用户封禁、登录记录查询）
│       ├── admin_settings.py # 系统设置路由（含站点配置、代码注入、邮箱配置）
│       ├── import_route.py # 教务系统导入路由
│       ├── profile.py      # 个人资料路由（含登录历史）
│       ├── share.py        # 课表分享路由
│       └── changelog.py    # 更新日志代理路由
├── frontend/               # 前端代码
│   ├── src/
│   │   ├── components/     # Vue 组件
│   │   │   ├── ScheduleAdjuster.vue      # 调休管理组件（节假日+换课）
│   │   │   ├── ScheduleCalendar.vue      # 日历视图组件（支持调休、堆叠事件）
│   │   │   ├── calendar/MonthSplitView.vue # 月视图分栏（日历+当日课表）
│   │   │   ├── ScheduleEditor.vue        # 课表编辑器
│   │   │   ├── ScheduleGanttWeekView.vue # 甘特图周视图
│   │   │   ├── ScheduleDayListView.vue   # 周列表视图
│   │   │   ├── ScheduleImporter.vue      # 教务系统导入
│   │   │   ├── ImportOptionsModal.vue    # 导入选项弹窗（ICS/教务系统）
│   │   │   ├── ExportOptionsModal.vue    # 导出选项弹窗（PNG/ICS）
│   │   │   ├── ShareOptionsModal.vue     # 分享/导出选项弹窗
│   │   │   ├── ShareScheduleView.vue     # 分享管理面板
│   │   │   ├── PublicScheduleView.vue    # 公开课表只读视图
│   │   │   ├── ImportScheduleModal.vue   # 导入分享课表模态框
│   │   │   ├── EmptyClassroomQuery.vue   # 空教室查询组件
│   │   │   ├── MySchedulePage.vue        # 个人课表页面（含调休、分享功能）
│   │   │   ├── MyTeamsPage.vue           # 我的团队管理页面（创建/加入/列表）
│   │   │   ├── TeamViewPage.vue          # 团队课表聚合视图（筛选+冲突识别）
│   │   │   ├── AllTeamsViewPage.vue      # 全团队视图页面
│   │   │   ├── TeamEditorModal.vue       # 团队编辑模态框（成员管理+批量操作）
│   │   │   ├── AvatarPresetDrawer.vue    # 头像/团队图标预设抽屉
│   │   │   ├── CreatorTeamManagement.vue # 创建者高级团队管理面板
│   │   │   ├── TransferTeamModal.vue     # 团队所有权转让模态框
│   │   │   ├── DissolveTeamModal.vue     # 解散团队确认模态框
│   │   │   ├── LeaveTeamModal.vue        # 退出团队确认模态框
│   │   │   ├── TeamEventDetailModal.vue  # 团队课程详情及冲突显示
│   │   │   ├── StackedEventsModal.vue    # 堆叠事件详情显示
│   │   │   ├── FilterSidebar.vue         # 团队课表高级筛选侧边栏
│   │   │   ├── ChangelogModal.vue        # 更新日志显示模态框
│   │   │   ├── BatchActionBar.vue        # 批量操作工具栏
│   │   │   ├── ButtonLoadingSpinner.vue  # 按钮加载指示器
│   │   │   ├── PageHeaderCard.vue        # 页面顶部信息卡片
│   │   │   ├── PageLoadingSpinner.vue    # 页面加载指示器
│   │   │   ├── Navigation.vue            # 导航栏（含团队、空教室查询、更新日志入口）
│   │   │   ├── MobileDrawer.vue          # 移动端菜单
│   │   │   ├── EventModal.vue            # 事件编辑弹窗
│   │   │   ├── PickerPopover.vue         # 通用弹出式日期/时间选择器
│   │   │   ├── CodeEditor.vue            # 代码编辑器（支持代码注入配置）
│   │   │   ├── EmailBindingChecker.vue   # 强制邮箱绑定检查器
│   │   │   ├── ForceBindEmailModal.vue   # 强制绑定邮箱模态框
│   │   │   ├── ForgetPasswordForm.vue    # 找回密码表单
│   │   │   ├── RegisterForm.vue          # 注册表单（含邮箱验证）
│   │   │   ├── LoginForm.vue             # 登录表单
│   │   │   ├── PasswordInput.vue         # 统一密码输入组件（支持显示/隐藏）
│   │   │   ├── OtpInput.vue              # 多格验证码输入组件
│   │   │   ├── SendCodeLabel.vue         # 验证码按钮状态标签
│   │   │   ├── TutorialEntry.vue         # 教程快捷入口组件
│   │   │   ├── LandingNavbar.vue         # 首页导航栏（支持登录态菜单）
│   │   │   ├── HeroTypewriter.vue        # 首页打字机标题组件
│   │   │   ├── PerspectiveSchedule.vue   # 首页3D课表演示组件（含自动课程详情动画）
│   │   │   ├── TeamViewShowcase.vue      # 首页团队协作演示组件
│   │   │   ├── ClassroomShowcase.vue     # 首页空教室演示组件
│   │   │   ├── ShareShowcase.vue         # 首页课表分享演示组件（图片/链接/ICS三标签）
│   │   │   ├── ImportShowcase.vue        # 首页教务系统导入演示组件
│   │   │   ├── TeamManageShowcase.vue    # 首页团队管理演示组件
│   │   │   ├── NavTooltip.vue            # 通用悬停提示组件（支持 top/bottom/right 方向）
│   │   │   ├── FeatureSection.vue        # 首页功能展示区
│   │   │   ├── CTASection.vue            # 首页行动引导区
│   │   │   ├── ToastContainer.vue        # Toast通知容器
│   │   │   ├── ToastItem.vue             # Toast通知项
│   │   │   ├── auth/AuthShell.astro      # 认证页面通用外壳
│   │   │   └── admin/                    # 管理员组件
│   │   │       ├── AdminTeamManagement.vue   # 管理员团队管理组件
│   │   │       ├── UserManagementPage.vue    # 用户管理页面（含登录记录、批量操作）
│   │   │       ├── ConfirmDeleteModal.vue    # 批量删除确认模态框
│   │   │       ├── UserEditModal.vue         # 用户编辑模态框
│   │   │       ├── UserScheduleModal.vue     # 用户课表显示模态框
│   │   │       ├── BanUserModal.vue          # 封禁用户确认模态框
│   │   │       ├── BatchRestoreConfirmToast.vue  # 批量恢复确认模态框
│   │   │       ├── CsvImportModal.vue        # CSV导入模态框
│   │   │       └── SystemSettings.vue        # 系统设置组件（含邮箱配置）
│   │   ├── layouts/        # Astro 布局
│   │   │   ├── BaseLayout.astro          # 基础布局
│   │   │   └── DashboardLayout.astro     # 仪表板布局
│   │   ├── pages/          # 页面路由
│   │   │   ├── index.astro               # 首页
│   │   │   ├── login.astro               # 登录页
│   │   │   ├── register.astro            # 注册页（含邮箱验证）
│   │   │   ├── forget.astro              # 找回密码页
│   │   │   ├── share.astro               # 公开课表分享页
│   │   │   ├── 503.astro                 # 账户封禁错误页面
│   │   │   └── dashboard/                # 仪表板页面
│   │   │       ├── my-schedule.astro     # 个人课表（含调休管理）
│   │   │       ├── my-teams.astro        # 我的团队管理
│   │   │       ├── classroom.astro       # 空教室查询
│   │   │       ├── team-view/            # 团队视图页面
│   │   │       │   └── [teamId].astro    # 团队详情页
│   │   │       ├── team-view.astro       # 团队视图 (兼容)
│   │   │       ├── profile.astro         # 个人资料（含登录历史）
│   │   │       └── admin/                # 管理员页面
│   │   │           ├── user-management.astro  # 用户管理页面
│   │   │           ├── team-management.astro  # 团队管理页面
│   │   │           └── system-settings.astro  # 系统设置页面
│   │   ├── stores/         # Pinia 状态管理
│   │   │   ├── auth.ts                   # 认证状态
│   │   │   ├── schedule.ts               # 课表状态（含调休逻辑）
│   │   │   ├── team.ts                   # 团队状态管理
│   │   │   ├── ui.ts                     # UI状态管理（含更新日志通知）
│   │   │   ├── theme.ts                  # 主题状态管理
│   │   │   └── toast.ts                  # Toast通知全局单例状态
│   │   ├── types/          # TypeScript 类型定义
│   │   │   └── index.ts                  # 包含Team、ScheduleAdjustment、LoginRecord等类型
│   │   ├── constants/      # 前端常量
│   │   │   ├── scheduleDisplay.ts         # 课表显示个性化配置常量
│   │   │   └── tutorialLinks.ts           # 教程入口链接常量
│   │   └── utils/          # 工具函数
│   │       ├── api.ts                    # API 客户端
│   │       ├── avatarPresets.ts          # 头像/团队图标预设数据与生成逻辑
│   │       ├── calendar-grouping.ts      # 日历按天/按课程分组工具
│   │       ├── clipboard.ts              # 剪贴板复制兼容工具
│   │       ├── colors.ts                 # 颜色工具
│   │       ├── date.ts                   # 日期工具
│   │       ├── export.ts                 # 导出工具（CSV/Excel/PDF）
│   │       ├── changelogService.ts       # 更新日志服务
│   │       ├── dropdownBehavior.ts       # 下拉菜单点击外部关闭与高度工具
│   │       ├── pickerPopoverLayout.ts    # 日期/时间选择器布局计算工具
│   │       ├── scheduleView.ts           # 多视图统计与事件筛选工具
│   │       └── schedule-segments.ts      # 课表时间段工具
│   ├── tests/               # Bun 前端单测
│   │   ├── avatar-presets.test.ts       # 预设头像/图标资源测试
│   │   ├── clipboard.test.ts            # 剪贴板回退逻辑测试
│   │   ├── dropdown-behavior.test.ts    # 下拉菜单行为测试
│   │   ├── dropdown-component-guards.test.ts # 下拉组件回归守卫测试
│   │   ├── login-redirect.test.ts       # 登录回跳逻辑测试
│   │   ├── picker-popover-layout.test.ts # 日期时间选择器布局测试
│   │   ├── schedule-editor-modal.test.ts # 课表编辑弹窗动作测试
│   │   └── team-modal-actions.test.ts   # 团队模态框动作测试
│   ├── astro.config.mjs    # Astro 配置
│   ├── tailwind.config.mjs # Tailwind 配置
│   └── package.json        # 依赖管理
├── scripts/                # 脚本目录
│   ├── migrations/         # 数据库迁移脚本
│   │   ├── README.md       # 迁移说明文档
│   │   ├── add_email_and_status_fields.py  # 添加邮箱和状态字段
│   │   ├── add_college_field.py            # 添加学院字段
│   │   ├── add_password_changed_field.py   # 添加密码变更字段
│   │   ├── add_profile_bio_and_team_metadata.py # 添加个人简介与团队元数据字段
│   │   └── add_schedule_share.sh           # 添加课表分享功能
│   └── start_dev.sh        # 开发环境启动脚本
├── .gitignore              # Git 忽略文件
└── README.md               # 项目说明
```

## 🚀 快速开始

### 📋 环境要求

- **Python** 3.10+ 
- **Node.js** 18+（或直接安装 **Bun**，Bun 自带 Node 运行时）
- **Bun**（前端必须使用 Bun，替代 npm/yarn/pnpm）
- **Git** (用于克隆项目)

### 🐳 Docker 部署

使用预构建镜像快速启动。

```bash
# 1. 准备工作：创建挂载目录
# 注意：请确保 config/config.toml 文件存在，否则 Docker 会将其作为目录挂载
mkdir -p data uploads config logs

# 1.1 准备配置文件（首次部署）
# 推荐：从仓库复制默认配置文件（如果你已克隆本仓库）
# cp backend/config.toml ./config/config.toml
# 如果你仅使用预构建镜像且没有源码，也至少创建一个空文件避免被挂载成目录：
touch ./config/config.toml

# 1.2 生产环境必须设置 SECRET_KEY（用于签发登录 token）
# 建议同时设置 APP_ENV=production；不设置会导致重启后 token 全部失效（且不适合生产环境）。
# 示例：export SECRET_KEY="$(openssl rand -hex 32)"

# 2. 拉取镜像
docker pull hevspecu/sdnu-chronosync:latest

# 3. 运行容器 (请根据实际情况修改挂载路径)
docker run -d \
  --name sdnu-chronosync \
  -p 3012:1145 \
  -e APP_ENV=production \
  -e SECRET_KEY="${SECRET_KEY}" \
  -e DATABASE_URL=sqlite:////app/data/schedule_app.db \
  # 可选：配置跨域（逗号分隔多个域名）
  # -e ALLOWED_ORIGINS=https://your-domain.com \
  # 可选：控制管理员初始化行为
  # -e SHOW_INITIAL_ADMIN_PASSWORD=1 \
  # -e DEFAULT_ADMIN_PASSWORD='<set only if you know what you are doing>' \
  -v ./data:/app/data \
  -v ./uploads:/app/uploads \
  -v ./config/config.toml:/app/config.toml \
  -v ./logs:/app/logs \
  --restart unless-stopped \
  hevspecu/sdnu-chronosync:latest
```

访问：`https://localhost:3012`（容器内 Nginx 已启用 **HTTPS + HTTP/2**；默认自签证书，生产环境建议挂载正式证书到 `/etc/nginx/certs/tls.crt` 和 `/etc/nginx/certs/tls.key`）。

#### 常见问题：启动后访问 502，容器日志提示 `--log-config` 路径不存在

如果你在容器日志里看到类似：

- `Error: Invalid value for '--log-config': Path '...' does not exist.`

说明你当前拉到的镜像版本中 `supervisord.conf` 的 `--log-config` 路径与镜像内文件布局不一致。解决方式二选一：

- **方案 A（推荐）**：使用 `docker compose` 从当前仓库源码构建（见下方 “Docker Compose 部署”），保证配置与代码一致。
- **方案 B（兼容旧镜像）**：挂载修正后的 `supervisord.conf` 覆盖容器内配置（不需要重打镜像）：

1) 在宿主机创建 `/config/supervisord.conf`（内容如下）：

```ini
[supervisord]
nodaemon=true
user=root
logfile=/app/logs/supervisord.log
pidfile=/var/run/supervisord.pid

[program:fastapi]
command=uv run uvicorn main:app --host 0.0.0.0 --port 8000 --workers 1 --log-level info --access-log --log-config /app/uvicorn_log_config.json
directory=/app
autostart=true
autorestart=true
user=root
stdout_logfile=/app/logs/fastapi.log
stderr_logfile=/app/logs/fastapi_error.log
redirect_stderr=true

[program:nginx]
command=nginx -g "daemon off;"
autostart=true
autorestart=true
user=root
stdout_logfile=/app/logs/nginx.log
stderr_logfile=/app/logs/nginx_error.log
redirect_stderr=true
```

2) 重新创建容器时加上挂载（其余参数不变）：

```bash
docker run ... \
  -v ./config/supervisord.conf:/etc/supervisor/conf.d/supervisord.conf:ro \
  ...
```

### 🐳 Docker Compose 部署

适合需要自定义构建或管理的场景。

```bash
# 1. 克隆仓库
git clone https://github.com/excniesNIED/SDNUChronoSync.git
cd SDNUChronoSync

# 2. 准备挂载目录（与 docker-compose.yml 默认一致）
# 注意：请确保 data/config/config.toml 文件存在，否则 Docker 会将其作为目录挂载
mkdir -p data/database data/uploads data/config data/logs

# 2.1 准备配置文件（首次部署）
cp backend/config.toml data/config/config.toml

# 2.2 生产环境建议在 docker-compose.yml 的 environment 中增加：
# - APP_ENV=production
# - SECRET_KEY=<a long random string>
# SECRET_KEY 用于签发登录 token；不设置会导致重启后 token 全部失效（且不适合生产环境）。
# 如需通过管理后台保存系统设置，请将 config.toml 挂载改为可写（移除 :ro）。

# 3. 启动服务（首次会构建镜像）
docker compose up -d --build
```

访问：`https://localhost:1145`（HTTP/2）。如需正式证书，可在 `docker-compose.yml` 中增加挂载：`./certs:/etc/nginx/certs:ro`。

## 🌍 跨域（CORS）配置

当前后端使用 FastAPI `CORSMiddleware`。如果你遇到浏览器控制台报错类似：

- `Access to fetch at ... has been blocked by CORS policy`

说明**前端站点域名没有被后端允许**。

后端通过环境变量 `ALLOWED_ORIGINS`（逗号分隔）配置允许的来源（Origin）。例如：

```text
ALLOWED_ORIGINS=http://localhost:4321,https://your-frontend-domain.com
```

注意：

- `ALLOWED_ORIGINS` 属于**环境变量**，不在 `config.toml` 里配置。
- 修改环境变量后需要**重启后端进程/容器**才能生效。

### 方式 1：本地开发（.env）

在 `backend/.env`（或项目根目录 `.env`）添加：

```text
ALLOWED_ORIGINS=http://localhost:4321
```

然后重启后端。

### 方式 2：Docker（docker run）

在启动参数里加入：

```bash
docker run ... \
  -e ALLOWED_ORIGINS=http://localhost:4321,https://your-frontend-domain.com \
  ...
```

### 方式 3：Docker Compose

在 `docker-compose.yml` 的服务 `environment:` 中添加：

```yaml
environment:
  - ALLOWED_ORIGINS=http://localhost:4321,https://your-frontend-domain.com
```

然后重启容器：

```bash
docker compose up -d
```

## 后端稳定性与性能参数（可选）

以下环境变量用于在不同部署规模下调优后端稳定性、内存占用和上游请求行为。

**认证限流（`/api/auth/token`）**

- `AUTH_RATE_LIMIT_WINDOW_SECONDS`（默认 `300`）：统计失败尝试的时间窗口（秒）
- `AUTH_RATE_LIMIT_MAX_ATTEMPTS`（默认 `8`）：窗口内最大失败次数
- `AUTH_RATE_LIMIT_LOCKOUT_SECONDS`（默认 `600`）：触发后锁定时间（秒）
- `AUTH_RATE_LIMIT_MAX_KEYS`（默认 `50000`）：内存中限流键的最大数量
- `AUTH_RATE_LIMIT_CLEANUP_INTERVAL_SECONDS`（默认 `60`）：限流状态清理间隔（秒）

**教务系统导入会话（`/api/import/*`）**

- `JWXT_BASE_URL`（默认 `http://jwxt.sdnu.edu.cn/jwglxt`）：正方教务系统基础地址；如未带协议，后端会自动补全为 `http://`
- `JWXT_SESSION_TTL_SECONDS`（默认 `1800`）：导入会话缓存存活时间（秒）
- `JWXT_SESSION_MAX_ITEMS`（默认 `256`）：导入会话缓存最大条数
- `JWXT_HTTP_TIMEOUT_GET`（默认 `10`）：上游 GET 超时（秒）
- `JWXT_HTTP_TIMEOUT_POST`（默认 `15`）：上游 POST 超时（秒）

**空教室会话（`/api/classroom/*`）**

- `CLASSROOM_SESSION_TTL_SECONDS`（默认 `600`）：空教室会话有效期（秒）
- `CLASSROOM_SESSION_MAX_ITEMS`（默认 `256`）：空教室会话缓存最大条数
- `CLASSROOM_SESSION_CLEANUP_INTERVAL_SECONDS`（默认 `60`）：空教室会话清理间隔（秒）
- `JWXT_MAX_CONCURRENCY`（默认 `3`）：空教室查询访问上游教务系统的并发上限

### ⚡ 一键脚本部署

我们提供了便捷的启动脚本：

```bash
# 克隆项目
git clone https://github.com/excniesNIED/SDNUChronoSync.git
cd SDNUChronoSync

# 使用启动脚本（推荐）
chmod +x scripts/start_dev.sh
./scripts/start_dev.sh
```

### 🔧 手动部署

#### 1. 克隆项目

```bash
git clone https://github.com/excniesNIED/SDNUChronoSync.git
cd SDNUChronoSync
```

#### 2. 后端设置

先安装 uv（参考：https://docs.astral.sh/uv/getting-started/installation/），然后执行：

```bash
cd backend
uv sync
uv run python main.py
```

后端服务将在 http://localhost:8000 启动

如需让后端端口本身支持 **HTTP/2**（需要 TLS），可使用：

```bash
cd backend
ENABLE_HTTP2=1 uv run python main.py
```

然后访问 `https://localhost:8000`（自签证书，浏览器可能提示“不安全”）。生产环境更推荐通过 Nginx 入口启用 HTTPS+HTTP/2（例如 Docker 暴露的 `https://localhost:1145`）。

前端开发服务器会通过代理转发 `/api/*`（以及 `/static/avatars/*`）到后端：
- 若检测到 `backend/.certs/tls.{crt,key}` 存在，会自动使用 `https://localhost:8000`
- 否则默认使用 `http://localhost:8000`
- 可用环境变量覆盖：`BACKEND_URL=https://localhost:8000 bun run dev`

#### 3. 前端设置

```bash
cd frontend
bun install
bun run dev
```

前端应用将在 http://localhost:4321 启动

#### 4. 一键启动（可选）

项目提供一键启动脚本（启动后端 + 前端）：

```bash
./scripts/start_dev.sh
```

如需后端以 HTTPS + HTTP/2 方式启动（需先生成 `backend/.certs/tls.{crt,key}`），可设置：

```bash
ENABLE_HTTP2=1 ./scripts/start_dev.sh
```

### 📱 访问应用

- **前端应用**: http://localhost:4321
- **后端API**: http://localhost:8000
- **API文档**: http://localhost:8000/docs

### 默认账户

系统会自动创建管理员账户；测试账户（学生账号）默认不会创建（避免生产环境出现弱口令）。

**管理员账户：**

- 学号（student_id）：`admin`（也可使用邮箱登录）
- 密码：首次启动时随机生成强口令（仅在初始化时输出一次）
  - 可选：`DEFAULT_ADMIN_PASSWORD` 可指定初始密码（生产环境不建议使用固定弱口令）
  - 可选：`SHOW_INITIAL_ADMIN_PASSWORD=0` 可禁止在日志中打印初始密码（打印为 `<hidden>`）
  - 可选：`AUTO_CREATE_ADMIN=0` 可禁用自动创建管理员账号（不建议，可能导致无法登录管理后台）

**学生测试账户（可选，仅测试环境）：**

如需自动创建示例学生账号，请在启动时设置环境变量：

- `CREATE_SAMPLE_USERS=1`

示例学生账号信息如下（开启后才会创建）：

- 学号（student_id）：`202311001145`
- 密码：`password123`
- 姓名：黄浩二
- 班级：计工本2303

#### 获取管理员初始密码

当系统检测到数据库中不存在管理员账户时，会自动创建 `student_id=admin` 的管理员账号，并在后端启动日志中输出一次：

`[SECURITY] Password: <random_password>`

##### Docker / docker-compose

在首次启动后立即查看容器日志，找到上述 `SECURITY` 输出：

```bash
docker compose logs --no-color sdnu-chronosync | grep "\[SECURITY\]"
```

如果你的服务名不是 `sdnu-chronosync`，请将其替换为 `docker-compose.yml` 中对应的 service 名称。

##### 普通安装（直接运行）

如果你是用 `uv run python main.py` / `uv run uvicorn` 直接启动后端，初始密码会打印在当前终端输出中。请在首次启动时保存该密码。

##### 普通安装（systemd）

如果你用 systemd 托管后端服务，可使用：

```bash
journalctl -u <your-service-name> -b --no-pager | grep "\[SECURITY\]"
```

安全提醒：该初始密码仅会输出一次；请在首次登录后立即在「个人中心」修改管理员密码。

## 🔌 API 接口

### 认证接口

- `POST /api/auth/token` - 用户登录
- `POST /api/auth/register` - 用户注册（支持邮箱验证）
- `GET /api/auth/users/me` - 获取当前用户信息
- `POST /api/auth/send-verification-code` - 发送邮箱验证码（60秒冷却）
- `POST /api/auth/bind-email` - 绑定邮箱到用户账户
- `GET /api/auth/email-required` - 检查邮箱验证是否必填
- `POST /api/auth/reset-password` - 重置密码（需验证码）

### 课表管理接口

- `GET /api/schedules/` - 获取用户所有课表
- `POST /api/schedules/` - 创建新课表
- `GET /api/schedules/{id}` - 获取指定课表详情
- `PUT /api/schedules/{id}` - 更新课表信息
- `DELETE /api/schedules/{id}` - 删除课表
- `GET /api/schedules/{id}/events` - 获取课表事件（含调休逻辑）
- `POST /api/schedules/{id}/events` - 在课表中创建事件
- `PUT /api/schedules/{id}/events/{event_id}` - 更新课表事件
- `DELETE /api/schedules/{id}/events/{event_id}` - 删除课表事件
- `POST /api/schedules/import-ics` - 从ICS文件导入事件到指定课表
- `GET /api/schedules/{id}/export.ics` - 导出课表为ICS文件

### 调休管理接口

- `GET /api/schedules/{id}/adjustments` - 获取课表的所有调休历史记录
- `POST /api/schedules/{id}/adjustments` - 创建调休调整（HOLIDAY/SWAP类型）
  - **HOLIDAY类型**：`{ "adjustment_type": "HOLIDAY", "holiday_date": "2024-10-01" }`
  - **SWAP类型**：`{ "adjustment_type": "SWAP", "source_date": "2024-10-01", "target_date": "2024-10-02" }`

### 课表分享接口

- `POST /api/schedules/{id}/share` - 创建课表分享链接
- `GET /api/schedules/{id}/shares` - 获取课表的所有分享记录
- `DELETE /api/shares/{share_id}` - 撤销（删除）分享
- `GET /api/public/shares/{token}` - 查看分享的课表（公开接口）
- `POST /api/public/shares/{token}/import` - 导入分享的课表到当前账户

### 团队管理接口

**用户团队操作：**

- `POST /api/teams` - 创建新团队（自动生成8位邀请码，创建者自动加入）
- `POST /api/me/teams/join` - 通过邀请码加入团队
- `GET /api/me/teams` - 获取我参与的所有团队列表
- `POST /api/me/teams/{id}/leave` - 退出团队（普通成员）

**团队信息查询：**

- `GET /api/teams/{id}` - 获取团队详细信息（包含成员列表、创建者信息）
- `GET /api/teams/{id}/schedules` - 获取团队聚合课表视图（所有成员的活跃课表）

**团队管理操作（需要创建者或团队管理员权限）：**

- `PUT /api/teams/{id}` - 更新团队名称
- `POST /api/teams/{id}/members` - 添加团队成员（通过学号精确查找）
- `DELETE /api/teams/{id}/members/{user_id}` - 移除团队成员（不能移除创建者和系统管理员）

**团队管理员管理（仅创建者和系统管理员）：**

- `POST /api/teams/{id}/admins/{user_id}` - 提升成员为团队管理员
  - 要求：目标用户必须是团队成员
  - 限制：不能提升创建者（已有隐式权限）和系统管理员
- `DELETE /api/teams/{id}/admins/{user_id}` - 移除团队管理员权限
  - 将团队管理员降级为普通成员
  - 限制：不能降级创建者

**团队所有权管理（仅创建者权限）：**

- `POST /api/teams/{id}/transfer` - 转让团队所有权给其他成员
- `DELETE /api/teams/{id}` - 解散团队（删除团队及所有成员关系）

**管理员专用接口：**

- `GET /api/admin/teams` - 获取系统中所有团队列表（包含统计信息）

### 路由说明

团队管理接口使用统一的路由前缀，遵循 RESTful 设计原则：

- `/api/teams/*` - 团队的增删改查操作
- `/api/me/teams/*` - 当前用户的团队操作
- `/api/admin/teams` - 管理员团队监控

所有接口均需要 JWT 身份验证，通过 `Authorization: Bearer <token>` 请求头传递。

### 个人资料接口

- `GET /api/profile/` - 获取个人资料
- `PUT /api/profile/` - 更新个人资料
- `POST /api/profile/change-password` - 修改密码
- `POST /api/profile/avatar` - 更新头像URL
- `POST /api/profile/upload-avatar` - 上传头像文件
- `GET /api/profile/statistics` - 获取个人统计数据
- `GET /api/profile/recent-login` - 获取最近一次登录记录
- `GET /api/profile/login-history` - 获取登录历史记录（支持分页）

### 管理员接口

**用户管理：**

- `GET /api/admin/users` - 获取所有用户（管理员）
- `POST /api/admin/users` - 创建用户
- `PUT /api/admin/users/{id}` - 更新用户
- `DELETE /api/admin/users/{id}` - 删除用户
- `POST /api/admin/users/{id}/ban` - 封禁用户账户（支持ban_type: ban/ipban/emailban）
- `POST /api/admin/users/{id}/restore` - 恢复用户账户（重置status为normal）

**批量导入导出：**

- `GET /api/admin/users/import-template.csv` - 下载用户CSV导入模板
- `POST /api/admin/users/import-csv` - 批量导入用户（multipart/form-data，file参数）
- `GET /api/admin/teams/import-template.csv` - 下载团队CSV导入模板
- `POST /api/admin/teams/import-csv` - 批量导入/更新团队（multipart/form-data，file参数）

**用户课表管理：**

- `GET /api/admin/users/{id}/schedules-list` - 获取用户的所有课表列表
- `GET /api/admin/users/{id}/schedules` - 获取用户的所有日程事件
- `POST /api/admin/schedule/{user_id}` - 为指定用户创建日程
- `PUT /api/admin/schedule/{event_id}` - 更新任意日程事件
- `DELETE /api/admin/schedule/{event_id}` - 删除任意日程事件

**登录记录查询：**

- `GET /api/admin/users/{id}/recent-login` - 获取指定用户的最近登录记录
- `GET /api/admin/users/{id}/login-history` - 获取指定用户的登录历史记录

**系统设置：**

- `GET /api/admin/settings` - 获取系统设置（含邮箱配置）
- `POST /api/admin/settings` - 更新系统设置（含邮箱配置）
- `POST /api/admin/settings/test-alist` - 测试AList存储连接
- `POST /api/admin/settings/test-email` - 测试邮件连接（发送测试邮件）

**站点配置接口：**

- `GET /api/admin/public/site-config` - 获取公开站点配置（无需认证）
- `GET /api/admin/public-files` - 获取Public目录下的图标文件列表
- `GET /api/admin/settings` - 获取完整系统设置（含站点配置）
- `POST /api/admin/settings` - 更新系统设置（含站点配置 `[site]` 部分）

### 更新日志接口

- `GET /api/changelog/content` - 获取更新日志内容（后端代理，避免CORS问题，返回 `status=success/cached/stale/fallback`）

## 📥 课表导入功能

系统支持两种课表导入方式：从教务系统导入和从ICS文件导入。

### 📚 教务系统课表导入

系统支持从山东师范大学正方教务系统导入课表。导入流程如下：

1. **获取用户课表列表**
   
   - `GET /api/import/schedules`
   - **描述**: 获取当前用户的所有课表列表，用于选择导入目标。
   - **响应**: 返回课表列表数组。

2. **获取会话与验证码**
   
   - `GET /api/import/zfw/session`
   - **描述**: 初始化导入流程，返回一个临时的 `session_id` 和 Base64 编码的验证码图片。
   - **响应**:
     
     ```json
     {
       "session_id": "string",
       "captcha_image": "string (base64)",
       "source": "string ('real' or 'fallback')"
     }
     ```

3. **提交登录信息并导入**
   
   - `POST /api/import/zfw`
   - **描述**: 用户输入学号、密码和验证码后，提交至此接口。服务器将尝试登录教务系统，获取、解析课表，并存入指定的课表。
   - **请求体**:
     
     ```json
     {
       "session_id": "string",
       "username": "string (学号)",
       "password": "string",
       "captcha": "string (验证码)",
       "action": "string ('create_new' 或 'use_existing')",
       "schedule_id": "integer (action为use_existing时必填)",
       "schedule_name": "string (action为create_new时的课表名称)"
     }
     ```
   - **响应**:
     
     ```json
     {
       "success": "boolean",
       "message": "string",
       "imported_count": "integer"
     }
     ```

4. **刷新验证码 (可选)**
   
   - `GET /api/import/zfw/refresh/{session_id}`
   - **描述**: 如果验证码无法识别，可使用此接口刷新验证码。
   - **响应**: 返回与获取会话接口相同的结构，但包含新的验证码图片。

### 📆 ICS文件导入

系统支持从标准ICS文件导入课表事件，兼容各大日历应用（苹果日历、Google Calendar、Outlook等）导出的文件。

#### API端点

- **端点**: `POST /api/schedules/import-ics`
- **描述**: 解析ICS文件并导入事件到指定课表
- **请求格式**: `multipart/form-data`
- **参数**:
  - `file`: ICS文件（必需，只接受.ics格式）
  - `schedule_id`: 目标课表ID（必需）

#### 导入逻辑

1. **时间计算**: 根据课表的开始日期，自动计算每个事件的周数和星期几
2. **日期验证**: 自动跳过早于课表开始日期的事件
3. **事件创建**: 提取事件的标题、描述、地点、开始/结束时间等信息
4. **错误处理**: 记录导入失败的事件及原因

#### 响应示例

```json
{
  "success": true,
  "message": "成功导入 15 个事件，3 个事件导入失败",
  "count": 15,
  "errors": [
    "事件 '早期课程' 时间早于课表开始时间",
    "事件 '无效事件' 缺少时间信息"
  ]
}
```

#### 使用说明

1. 从其他日历应用（如苹果日历、Google Calendar）导出ICS文件
2. 在"我的课表"页面点击"更多" → "导入课表" → "从ICS文件导入"
3. 选择ICS文件上传
4. 系统自动解析文件并导入事件到当前活跃课表
5. 显示导入成功的数量和错误信息

## 🛠️ 开发指南

### 后端开发

1. **数据模型修改**：修改 `models.py` 后需要重启服务
2. **API 路由**：在 `routers/` 目录下添加新的路由文件
3. **数据库操作**：在 `crud.py` 中添加新的数据库操作函数
4. **迁移脚本**：涉及资料字段或团队元数据调整时，同步维护 `scripts/migrations/` 下的迁移脚本与说明

### 前端开发

1. **组件开发**：在 `src/components/` 下创建 Vue 组件
2. **页面路由**：在 `src/pages/` 下创建 Astro 页面
3. **状态管理**：使用 Pinia stores 管理应用状态
4. **样式开发**：使用 Tailwind CSS 类名

### 验证命令

```bash
# 前端
cd frontend
bun run type-check
bun run build
bun test frontend/tests

# 后端
cd backend
uv run python -m compileall .
uv run python -c "import main; assert hasattr(main, 'app'); print('backend smoke: ok')"
uv run python tests/test_profile_team_metadata.py
```

## 🚀 部署说明

### 开发环境

- 后端：直接运行 `uv run python main.py`
- 前端：运行 `bun run dev`

### 生产环境

- 后端：使用 Gunicorn 或 Uvicorn 部署
- 前端：运行 `bun run build` 生成静态文件，使用 Nginx 等服务器部署

## 贡献指南

1. Fork 项目
2. 创建特性分支 (`git checkout -b feature/amazing-feature`)
3. 提交更改 (`git commit -m 'Add amazing feature'`)
4. 推送到分支 (`git push origin feature/amazing-feature`)
5. 创建 Pull Request

## 📚 参考资料

本项目在开发过程中参考了以下开源项目和资源，特此致谢：

### 正方教务系统相关项目

- [openschoolcn/zfn_api](https://github.com/openschoolcn/zfn_api) - 正方教务系统API
- [whliao5am/zfnew](https://github.com/whliao5am/zfnew) - 正方教务系统新版本
- [whx1024/zfn_api12](https://github.com/whx1024/zfn_api12) - 正方教务系统API 1.2
- [zaigie/zfnew_webApi](https://github.com/zaigie/zfnew_webApi) - 正方教务系统Web API
- [dairoot/school-api](https://github.com/dairoot/school-api) - 学校API项目
- [DuskU/zhengfang](https://gitee.com/DuskU/zhengfang) - 正方教务系统Gitee版本
- [FarmerChillax/new-school-sdk](https://github.com/FarmerChillax/new-school-sdk) - 新学校SDK
- [Srpihot/zfapi](https://github.com/Srpihot/zfapi) - 正方教务系统API

### 课表管理相关项目

- [xxyangyoulin/ClassSchedule](https://github.com/xxyangyoulin/ClassSchedule) - 课程表项目
- [YZune/WakeupSchedule_Kotlin](https://github.com/YZune/WakeupSchedule_Kotlin) - WakeUp课程表Kotlin版本
- [qwqVictor/CQUPT-ics](https://github.com/qwqVictor/CQUPT-ics) - 重庆邮电大学ICS课表
- [XiaoNaoWeiSuo/Grade2](https://github.com/XiaoNaoWeiSuo/Grade2) - 成绩管理系统

### 技术文档

- [WakeUp课程表重构说明](https://yzune.github.io/2018/08/15/WakeUp%E8%AF%BE%E7%A8%8B%E8%A1%A8%E9%87%8D%E6%9E%84%E8%AF%B4%E6%98%8E/) - 课程表重构技术文档
- [CSDN博客 - 正方教务系统](https://blog.csdn.net/gitblog_00713/article/details/147225292) - 正方教务系统相关技术文章

### UI组件库

- [satyamchaudharydev/horrible-snake-35](https://uiverse.io/satyamchaudharydev/horrible-snake-35) - 加载动画组件（HTML/CSS）
- [Siyu1017/old-goat-8](https://uiverse.io/Siyu1017/old-goat-8) - Windows 11 风格加载动画组件

## 📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

## 🤝 贡献指南

我们欢迎所有形式的贡献！请遵循以下步骤：

1. **Fork 项目** - 点击右上角的 Fork 按钮
2. **创建特性分支** - `git checkout -b feature/amazing-feature`
3. **提交更改** - `git commit -m 'Add amazing feature'`
4. **推送分支** - `git push origin feature/amazing-feature`
5. **创建 Pull Request** - 在 GitHub 上创建 PR

## 📞 联系我们

- 🌐 **项目主页**：[https://github.com/HevSpecu/SDNUChronoSync](https://github.com/HevSpecu/SDNUChronoSync)
- 📖 **使用教程**：[https://hs.cnies.org/archives/chronosync-user-guide](https://hs.cnies.org/archives/chronosync-user-guide)
- ℹ️ **关于本项目**：[https://hs.cnies.org/archives/chronosync](https://hs.cnies.org/archives/chronosync)
- 💬 **问题反馈**：通过项目 [Issues](https://github.com/excniesNIED/SDNUChronoSync/issues) 提出
- 📧 **邮箱联系**：[hxcn@cnies.org](mailto:hxcn@cnies.org)

## 📝 更新日志

### v3.1.2 (2026-03-23) - 调休稳定性、课表视图细化与 ICS 兼容修复

**调休与教程入口修复**

- 调休请求改为显式校验模型，放假与换课不再因为联合类型解析歧义而触发 422；调休确认步骤也改成模态框内覆盖层，避免嵌套确认弹窗导致焦点丢失和表单状态错乱。
- 教程链接常量同步到最新文章锚点，首页、导入弹窗、调休页和团队页内的教程入口现在会跳到正确章节。

**课表工作台与日程查看体验**

- 登录成功后的默认落点统一改为 `/dashboard/my-schedule`，即使 `redirect=/` 也不会再回到主页。
- 周列表视图重新压缩了头部与卡片排版，教师/地点信息固定到右上角 badge 下方，整张卡片可直接点击查看课表详情。
- 甘特图周视图改为“行是日期、列是时间”的横向布局，支持点击课程查看详情、重叠课程分 lane 展示、横向滚动与更接近单元格占比的课程卡片。
- 甘特图时间轴进一步改为“课内按真实分钟比例、超长空档按压缩比例”显示，像 `10:10-11:45` 会按时间准确落位，而午休和晚间长空档不会再被拉成与一节课等长的巨大空白。

**ICS 导入导出与前端工程化**

- 修复 ICS 导出时中文课表名导致的响应头编码报错，下载文件名改为兼容 RFC 5987 的写法。
- 导出流程显式使用 `calendar.serialize()`，并统一按 `Asia/Shanghai` 时区生成事件；导入流程新增 `utf-8-sig`、`utf-8`、`gb18030` 编码兼容与时区归一化，保证导出后可稳定回导。
- 前端新增可执行的 ESLint 基线与 `bun run lint` 脚本，现有历史 warning 暂保留为非阻塞，但本地质量门槛已补齐为 `lint + type-check + build`。

### v3.1.1 (2026-03-09) - 交互修复、管理员邮箱持久化与 Python 3.12 兼容

**工作台与弹层交互修复**

- 统一课表页、团队视图、管理员页面和分享面板的下拉菜单样式，移动端分享面板重新整理为更紧凑的纵向布局，二维码尺寸与间距同步优化。
- "我的课表"在没有可用课表、课表已过期或当前未激活时，仍会保留新建课表、导入课表和教程入口，不再出现只能返回上一层的空状态。
- 课表设置、团队筛选、分享有效期、系统设置等下拉菜单统一改为基于组件容器的外部点击关闭；带搜索的下拉现在会保持实底搜索区，点击搜索框不会误选下方条目。
- `PickerPopover` 通用日期/时间选择器补充窄屏最小宽度、边缘避让和视口夹取逻辑，竖屏下选中日期的圆形不再被裁剪。
- 预设头像抽屉在手机竖屏下改为贴底显示，整个分类卡片都可直接展开；Profile、系统设置、放假调休等页面的 Tab 外框与内部按钮圆角同步统一。

**认证、模态框与管理员流程**

- 退出登录后返回首页；退出后的下一次登录默认进入 `/dashboard/my-schedule`，普通登录流程仍支持按站内 `redirect` 参数回跳。
- 课表编辑弹窗顶部"创建/保存"按钮重新绑定到底层表单，团队管理和课表删除确认移除原生 `confirm/alert`，统一使用项目确认弹窗和 Toast 提示。
- 管理员在后台创建或编辑用户时填写的邮箱现在会端到端保存，后端会自动做 trim、去重和大小写规范化，避免用户登录后仍被误判为未绑定邮箱。

**后端兼容与开发稳定性**

- 修复 Python 3.12 环境下 ICS 相关路由启动失败的问题：补齐 `rich` 运行时依赖、将 `tatsu` 约束在兼容版本，并在导入 `ics` 前回填旧版依赖所需的 `collections` 别名。
- `CodeEditor` 改用原生 `ResizeObserver` 替代 `@vueuse/core` 的 `useResizeObserver`，降低 Vite 开发态 `Outdated Optimize Dep` 报错概率。
- 为课表弹出选择器、下拉菜单守卫、登录回跳、管理员邮箱保存等场景补充前后端回归测试。

### v3.1.0 (2026-03-07) - 资料增强、团队卡片重构与课表多视图升级

**个人资料与团队元数据**

- 后端新增 `users.bio`、`teams.description`、`teams.cover_image_url` 字段，并补充迁移脚本 `add_profile_bio_and_team_metadata.py` 与 schema 测试。
- 个人中心支持编辑个人简介，头像设置新增预设头像抽屉；团队创建与团队管理支持团队介绍、团队图标上传和预设图标选择。
- 团队图标 URL 新增白名单校验与统一上传管线，兼容本地存储和已配置的 HTTPS 外部存储域名。

**课表工作台与演示体验**

- 我的课表页面重构为顶部信息卡 + 多视图工作区，新增课表周视图、日历日视图、甘特图周视图、周列表视图。
- 个性化设置支持单色/多彩卡片两种模式，当前时间指示线、即将开始课程高亮和提醒样式同步升级。
- 首页 `PerspectiveSchedule` 改为基于真实 demo 课程数据展示三种日程演示，不再只展示空骨架。
- 分享面板新增二维码预览与更清晰的有效期说明；导入、导出、调休、分享等弹窗统一改版。

**统一交互层与稳定性**

- 新增 `PickerPopover` 通用弹出式日期/时间选择器，支持在抽屉、弹窗和移动端视口中自适应定位，统一替换课表、筛选、调休、导入等原生日期时间输入。
- 新增 `PageHeaderCard`，并重构 `ModalTitleCard` 为带吸顶标题栏和操作区的统一弹窗头部组件，覆盖个人中心、团队、系统设置、分享等页面。
- 更新日志代理新增缓存与离线回退机制，前端在 `fallback` 状态下不再误报新版本。
- `astro.config.mjs` 追加 DiceBear 依赖预构建排除，降低开发态组件水合和预构建缓存异常。

### v3.0.0 (2026-02-18) - 首页重构与认证交互统一

**首页与引导体验**

- 首页从登录入口页升级为完整落地页，新增主题 Hero、功能展示区、CTA 区与交互演示模块。
- 新增 `LandingNavbar` 登录态菜单：已登录用户可直接进入工作台/个人中心，退出登录回到首页。
- Hero 区"井然有序"标题下方波浪下划线加粗为单条连续 SVG 波浪（`stroke-width 8.5`，`preserveAspectRatio=none` 全宽拉伸，不再平铺）。
- 教程按钮移至 Hero CTA 行，与注册/登录/特色功能并排展示，移除原独立教程区块。
- `PerspectiveSchedule` 3D 课表演示新增自动轮播课程详情弹窗动画（仿 `EventDetailModal` 样式），当前时间指示线旁新增 11:45 时间标签。
- 新增 `ShareShowcase`：课表分享演示，含图片导出、链接分享、ICS 导出三标签页，ICS 标签页含 Apple 日历与 Google 日历导入进度动画。
- 新增 `ImportShowcase`：教务系统导入演示，含示例账号密码输入动画与导入进度展示。
- 新增 `TeamManageShowcase`：团队创建与管理页面轮换动画，展示 2025ACM集训队、2026环梦工坊编程竞赛组等真实场景团队。
- `FeatureSection` 集成上述三个新演示组件，功能描述更新（分享功能新增 ICS/Apple/Google 日历说明）。
- 核心流程新增教程快捷入口，覆盖导入课表、高级调休、团队协作等场景。

**UI 交互细节**

- 新增 `NavTooltip` 通用悬停提示组件，支持 `top`/`bottom`/`right` 三方向、`disabled` 禁用、`block` 全宽模式，带平滑淡入/淡出动画。
- 侧边栏导航（`Navigation`）折叠状态下所有图标按钮悬停显示 Tooltip（右侧弹出）；展开状态下主题切换与收起按钮悬停显示 Tooltip（底部弹出）。
- 落地页顶部导航栏（`LandingNavbar`）各链接与主题切换按钮均集成 Tooltip。
- `PasswordInput` 显示/隐藏密码按钮悬停显示"显示密码"/"隐藏密码" Tooltip，自动覆盖全部 9 处使用场景（登录、注册、找回密码、个人中心、教务导入、管理员等）。
- 侧边栏折叠时 `overflow` 切换为 `visible`，确保 Tooltip 不被容器裁剪。

**认证与表单体验**

- 登录/注册/找回密码页面统一迁移到 `AuthShell`，保持视觉与交互一致。
- 注册、找回密码、强制绑定邮箱、个人中心邮箱验证统一使用 `OtpInput` 多格验证码输入。
- 认证与空教室登录表单统一为 Toast 校验反馈，发送验证码流程统一空值/格式/冷却/并发提示。
- `PasswordInput` 组件修复显示按钮点击穿透问题，并支持 `revealed` 可选受控模式。

**课表与日历能力**

- 月视图重构为 `MonthSplitView` 分栏布局（左侧月历 + 右侧当日课表），提升浏览与点击效率。
- 新增 `calendar-grouping.ts` 抽离按天取数与课程分组逻辑，减少周/月视图重复实现。
- 修复课表页面 SSR/CSR 水合不一致问题。
- 当前时间指示器支持颜色与粗细配置，并同步应用到个人课表与团队演示视图。

**管理界面与弹层稳定性**

- 管理员用户列表与团队列表操作菜单支持按视口空间自动向上/向下展开。
- 全站下拉菜单、弹窗、抽屉等交互层级统一，减少遮挡和误触。
- 多个管理与编辑弹窗完成布局与信息层级优化，提升桌面与移动端可读性。

**工程与依赖**

- 前端依赖升级：`astro` 更新到 `5.17.2`，`@astrojs/vue` 更新到 `5.1.4`。
- Vite 预构建排除 `@headlessui/vue`，缓解开发态 `Outdated Optimize Dep` 导致的水合异常。
- 前端开发脚本统一为 `astro dev --force`，每次启动强制刷新依赖缓存。
- 后端空教室楼宇映射修正：长清湖校区楼名统一为 `文淙楼信工`、`文淙楼心理`。
- Dockerfile 修复：移除对 `bun.lock` 与 `uv.lock` 的硬依赖（`bun.lock` 已在 `.gitignore` 中排除，原构建命令 `--frozen-lockfile` / `--frozen` 导致 GitHub Actions 持续失败）；前端改为 `bun install`，后端改为 `uv sync --no-dev`，依赖层缓存仍以 `package.json` / `pyproject.toml` 为键。
- Dockerfile 优化：将 6 条独立 `ENV` 指令合并为单条多行声明，减少镜像层数。

**后端安全、性能与稳定性**

- 登录接口增加失败限流与锁定机制，并对限流状态增加周期清理和容量上限，降低暴力破解与高基数请求导致的内存增长风险。
- 教务系统导入与空教室查询链路补充 HTTPS 规范化、请求超时控制、会话缓存 TTL/容量治理与并发安全更新，减少上游异常时的级联影响。
- 课表状态计算抽离为统一工具函数，`/api/schedules` 与 `/api/import/schedules` 读取路径仅在状态变化时写库，减少无效 `commit` 带来的数据库开销。
- 后端运行与部署链路统一迁移到 `uv`（`uv sync` / `uv run`），Docker 构建与 Supervisor 启动命令同步更新。
- 新增后端 API 冒烟脚本 `backend/scripts/smoke_httpx_lifespan.py`，使用 `ASGITransport + Lifespan` 验证启动与基础路由可用性。

### v2.9.4 (2026-01-27) - 页脚链接与密码输入体验统一

**前端体验**

- 页脚新增快捷入口：使用教程、更新日志、关于项目、项目主页（图标复用导航栏风格），放置在版权信息之前。
- 密码输入框统一使用 `PasswordInput` 组件，并确保每个输入框的显示/隐藏状态互不影响（避免“密码”与“确认密码”联动切换）。

### v2.9.3 (2026-01-27) - 安全加固与部署文档完善

**后端安全与健壮性**

- JWT `SECRET_KEY` 机制加固：生产环境（`APP_ENV=production` 或 `ENV=production`）必须显式设置 `SECRET_KEY`，避免默认弱密钥；开发环境自动生成进程级临时密钥并提示（重启会导致 token 失效）。
- OAuth2 tokenUrl 路径统一为 `/api/auth/token`，避免认证流程在不同环境下路径不一致。
- 邮箱相关请求统一使用 `EmailStr` 校验，并对邮箱做规范化（trim + lowercase），登录/绑定/注册查重为大小写不敏感。
- 邮箱验证码改为使用 `secrets` 生成（更安全），并增加过期清理与容量上限，避免内存增长；发送失败不再回传底层异常细节。

**管理后台配置（避免泄露敏感信息）**

- 系统设置接口不再返回已保存的 `email.password`、`alist.token`、`alist.password` 明文，新增 `has_password/has_token` 仅用于提示“已保存但已遮蔽”。
- 保存系统设置时，若前端提交敏感字段为空字符串，后端保留原有值，避免误清空。
- 连接测试接口支持在请求未携带敏感字段时复用已保存的密钥进行测试。

**前端认证与表单体验**

- 修复开放重定向风险：`redirect` 仅允许站内路径（`/path`），拒绝外部 URL 与可疑格式。
- 认证失败/401 跳转统一携带 `redirect=当前路径`，登录后可返回原页面；分享页登录/注册跳转使用“路径+query+hash”作为回跳来源。
- 登录/注册/找回密码表单增强：密码显示/隐藏、补充 `autocomplete`，提交前对输入做 trim/lowercase；验证码倒计时在组件卸载时清理，避免定时器泄漏。
- 系统设置页适配遮蔽密钥字段：显示“已保存，如需修改请重新输入”，并调整“测试连接”可用条件。

**部署与开发文档**

- 部署文档与 README：补充容器部署关键环境变量（`APP_ENV`/`SECRET_KEY`）、统一 `docker compose` 命令示例、修正容器内数据库备份路径为 `/app/data/schedule_app.db`。
- 开发启动脚本 `scripts/start_dev.sh` 前端依赖安装与启动改为 `bun install` / `bun run dev`（不再使用 npm）。

### v2.9.2 (2026-01-26) - 学院字段与资料表单完善

**用户信息**

- 新增“学院”字段：注册、个人中心、管理员编辑用户均为必填下拉选择（仅允许从预置列表选择）
- 个人中心：头像设置卡片高度自适应，避免左右卡片高度差异导致底部空白

**数据库迁移**

- 新增迁移脚本：`scripts/migrations/add_college_field.py`（升级到 v2.9.2+ 需先执行，详见 `scripts/migrations/README.md`）

### v2.9.1 (2026-01-22) - 课表引导与下拉体验修复

**体验修复**

- 我的课表：当用户没有任何课表时，在页面提示中增加《创建你的第一张课表》教程链接，引导完成课表创建
- 个人中心：年级下拉选择的搜索框层级修复，避免被列表选项遮挡

### v2.9.0 (2026-01-03) - 登录与交互体验优化

**登录与认证**

- 🔐 **支持邮箱登录**
  - 后端认证支持使用 `student_id` / `email` 登录
  - 前端登录与错误提示文案同步为“学号/邮箱”

**年级选择体验**

- 🎓 **新增年级下拉选择组件**
  - 新增 `GradeDropdown`，支持搜索/自定义（管理员）/自动从学号推断
  - 注册、个人中心、管理员编辑用户统一使用下拉选择

**课表事件查看体验**

- 🗓️ **新增事件详情弹窗**
  - 点击事件先查看详情，具备权限时可一键进入编辑
  - 适配个人课表、团队事件、管理员查看用户课表
  - 移动端弹窗宽度与间距优化；日历层级（z-index）调整避免遮挡

**后台管理 UI**

- 🛠️ **管理列表交互优化**
  - 用户管理表格勾选列合并头像展示，筛选/操作菜单层级修复
  - 批量恢复确认 Toast 仅在客户端挂载，避免 SSR/水合问题
  - 团队管理列表操作改为菜单，减少按钮拥挤

**开发脚本与日志**

- 🧰 **开发启动脚本增强**
  - `scripts/start_dev.sh` 增加严格模式与输出优化，支持 `ENABLE_HTTP2=1`
- 📜 **初始管理员输出更稳健**
  - 初次创建管理员时额外输出到 stderr，提升在 reload/日志重定向下的可见性

### v2.8.2 (2026-01-03) - 前端首屏性能与部署静态资源优化

**前端性能优化**

- 🖼️ **导出功能按需加载 html2canvas**
  - `MySchedulePage.vue` 导出课表图片时改为动态 `import('html2canvas')`
  - `frontend/src/utils/export.ts` 导出 PDF 时动态加载 html2canvas，减少首屏包体积

- ⚡ **Astro 组件水合策略优化**
  - `ToastContainer`、`EmailBindingChecker` 从 `client:load` 调整为 `client:idle`，延后非关键组件水合
  - `Footer` 从 `client:load` 调整为 `client:visible`，仅进入视口时加载（首页/登录/注册/找回密码/仪表盘等页面）

**侧边栏状态同步优化**

- 🧭 **事件驱动替代轮询**
  - UI Store 在侧边栏状态变更时派发 `sidebar-toggle` 事件
  - `DashboardLayout.astro` 移除 100ms 的 localStorage 轮询回退逻辑，改为事件监听更新布局，降低无意义 CPU 占用

**部署与 Nginx 优化**

- 🌐 **静态资源缓存与压缩**
  - `/assets/`（Vite hash 资源）启用 1 年缓存并标记 `immutable`
  - `.html` 禁用缓存，避免发布后用户命中旧 HTML 指向旧资源
  - 公共图片/图标启用 7 天缓存（无 hash）
  - 启用 gzip（JS/CSS/JSON/SVG 等常见类型）
  - `location ^~ /static/avatars/` 优先匹配，避免被图片正则 location 抢占
  - PID 写入 `/tmp` 且日志输出到 stdout/stderr，便于容器化运行

### v2.8.1 (2025-12-23) - 批量导入导出与日志系统优化

**批量导入导出功能**

- 📥 **CSV批量导入用户**
  - 新增用户CSV模板下载功能（`/api/admin/users/import-template.csv`）
  - 支持从CSV文件批量导入用户，自动创建账户
  - 导入结果详细反馈：成功数、跳过数、失败数及错误详情
  - 前端新增 `CsvImportModal.vue` 组件处理CSV上传和进度显示
  
- 📥 **CSV批量导入/更新团队**
  - 新增团队CSV模板下载功能（`/api/admin/teams/import-template.csv`）
  - 支持创建新团队和更新现有团队（基于团队名称匹配）
  - 自动同步团队成员和管理员列表（通过学号）
  - 导入响应新增 `updated_count` 字段，区分新增和更新操作
  - 前端显示"新增X，更新Y，跳过Z"的详细统计信息

- 📤 **增强的导出功能**
  - 用户/团队管理支持导出为CSV、Excel、PDF三种格式
  - 新增统一的导出工具函数（`frontend/src/utils/export.ts`）
  - 导出文件名包含精确时间戳（年-月-日_时-分格式）
  - 团队导出新增"成员学号列表"和"管理员学号列表"列
  - Excel导出使用xlsx库，PDF导出使用jsPDF+html2canvas
  - CSV导出添加UTF-8 BOM，确保Excel正确显示中文

**空教室查询优化**

- 🏫 **UI简化与体验提升**
  - 移除缓存会话功能，简化登录流程
  - 移除"记住登录"复选框和本地存储交互
  - 导出选项整合为下拉菜单（CSV/Excel/PDF）
  - 优化按钮样式和布局，提升界面一致性
  - 导出文件名包含精确时间戳

**模态框系统重构**

- 🎨 **Headless UI集成**
  - 所有模态框迁移至Headless UI的Dialog组件
  - 统一的过渡动画和可访问性支持
  - 重构组件：`CreatorTeamManagement`、`DissolveTeamModal`、`JoinTeam`、`LeaveTeamModal`、`MyTeamsPage`、`ScheduleAdjuster`、`ScheduleEditor`、`TeamEditorModal`
  - 移除内联成功/错误消息，统一使用Toast通知
  - 模态框宽度优化（`TeamEditorModal` 从 max-w-2xl 扩展至 max-w-4xl）

**用户管理增强**

- 👥 **批量操作与模态框优化**
  - `BanUserModal` 重构为Headless UI组件，支持封禁/解封双模式
  - 新增 `BatchRestoreConfirmToast` 组件用于批量恢复确认
  - 用户管理页面集成批量恢复和封禁功能模态框
  - 表格支持固定表头（sticky headers），大数据量下滚动更流畅
  - Toast通知增强：成功操作和错误处理的详细反馈
  - 下拉菜单z-index优化（z-40/z-50），避免被其他元素遮挡

**后端日志系统升级**

- 📊 **结构化日志集成**
  - 全面替换print语句为logging调用
  - 新增集中式日志配置（`backend/uvicorn_log_config.json`）
  - 实现跨模块的统一日志格式和处理
  - 增强错误追踪和调试能力
  - 改进组件：
    - 配置管理（`config.py`）
    - CRUD操作（`crud.py`）
    - 导入流程（`importer.py`）
    - API路由（`routers/schedules.py`）
    - 邮件服务（`services/email.py`）
    - 服务器启动（`start_server.py`）
  - 数据库初始化和事件导入的详细日志记录
  - ICS导入/导出过程的调试信息优化
  - Docker supervisord配置更新，集成uvicorn日志配置

**技术改进**

- ✅ 新增前端工具：`utils/export.ts` - 统一的导出工具函数
  - `exportToCsv()` - CSV导出（带UTF-8 BOM）
  - `exportToXlsx()` - Excel导出
  - `exportToPdf()` - PDF导出（支持多页分页）
  - `downloadBlob()` - 文件下载辅助函数
- ✅ 新增后端端点：
  - `GET /api/admin/users/import-template.csv` - 用户导入模板
  - `POST /api/admin/users/import-csv` - 批量导入用户
  - `GET /api/admin/teams/import-template.csv` - 团队导入模板
  - `POST /api/admin/teams/import-csv` - 批量导入/更新团队
- ✅ API客户端扩展：
  - `downloadUserImportTemplate()` - 下载用户模板
  - `importUsersFromCsv()` - 导入用户CSV
  - `downloadTeamImportTemplate()` - 下载团队模板
  - `importTeamsFromCsv()` - 导入团队CSV
- ✅ 日志配置文件：`backend/uvicorn_log_config.json`
- ✅ Docker配置更新：supervisord集成日志配置参数

### v2.8.0 (2025-12-22) - 空教室查询与UI体验全面优化

**新增功能**

- 🏫 **空教室查询系统**
  - 新增空教室查询功能，支持查询山东师范大学各校区空闲教室
  - 独立的教务系统会话管理，不影响平台登录状态
  - 支持按时间段、教学楼、教室类型等条件筛选
  - 新增 `/dashboard/classroom` 页面和 `EmptyClassroomQuery.vue` 组件
  - API 请求自动跳过全局错误处理，避免 token 失效误判

**CORS 配置增强**

- 🌍 **动态 CORS 配置**
  - 新增 `ALLOWED_ORIGINS` 环境变量支持动态配置允许的跨域来源
  - 支持逗号分隔多个域名，灵活适配不同部署环境
  - 更新 `docker-compose.yml` 和 `env.example` 配置示例
  - README 新增详细的 CORS 配置指南（本地开发、Docker、Docker Compose）

**管理功能优化**

- 👥 **用户管理增强**
  - 用户角色筛选逻辑重构，支持更精细的筛选条件
  - 新增封禁类型筛选：全部封禁、账号封禁、IP封禁、邮箱封禁
  - 角色显示优化，封禁用户显示具体封禁类型文本
  - 用户管理表格支持固定表头，大数据量下滚动更流畅
  - 新增 `getBanStatusText()` 辅助函数，统一封禁状态显示

- 📊 **批量操作工具栏**
  - 新增 `BatchActionBar.vue` 组件，提供统一的批量操作界面
  - 支持批量删除、批量封禁、批量恢复用户
  - 集成下拉菜单，操作更直观高效
  - 实时显示已选择项数量

**团队管理优化**

- 👥 **团队成员信息增强**
  - 团队编辑模态框显示成员邮箱地址
  - 未绑定邮箱显示"未绑定邮箱"提示
  - 邮箱地址支持截断显示，鼠标悬停查看完整内容

**UI/UX 改进**

- 🎨 **自定义滚动条样式**
  - 新增 `.scrollbar-custom`、`.scrollbar-custom-x`、`.scrollbar-custom-both` 工具类
  - 统一的细滚动条设计（6px 宽度），提升视觉美观度
  - 支持纵向、横向、双向滚动条自定义
  - 滚动条 hover 时颜色加深，交互反馈更明显

- 📋 **固定表头与滚动优化**
  - 用户管理、登录记录等大表格支持固定表头（sticky top-0）
  - 表格内容区域最大高度限制（max-h-[70vh]），超出自动滚动
  - 新增 `.table-container-fixed`、`.table-content-scroll` 等工具类
  - 模态框内表格同样支持固定头部和滚动内容

- 🎯 **模态框布局优化**
  - 新增 `.modal-header-fixed`、`.modal-content-scroll`、`.modal-footer-fixed` 工具类
  - 模态框头部和底部固定，内容区域可滚动
  - 统一的模态框布局规范，提升一致性

**代码质量提升**

- 🧹 **代码清理与优化**
  - 移除未使用的导入（`ArrowDownTrayIcon`、`ClipboardDocumentIcon` 等）
  - 修复 `ProfilePage.vue` 中的函数引用错误（`handleCardFileUpload`）
  - 优化 API 工具类，支持按 URL 跳过全局错误处理
  - 改进类型定义，增强代码可维护性

**技术改进**

- ✅ 新增前端组件：
  - `EmptyClassroomQuery.vue` - 空教室查询组件
  - `BatchActionBar.vue` - 批量操作工具栏
- ✅ 新增页面路由：
  - `/dashboard/classroom.astro` - 空教室查询页面
- ✅ Tailwind 配置扩展：
  - 新增滚动条自定义样式工具类
  - 新增固定表头/模态框布局工具类
- ✅ API 工具优化：
  - `shouldSkipGlobalErrorHandler()` 方法支持按 URL 跳过错误处理
  - 教务系统相关请求不触发平台登出逻辑

### v2.7.4 (2025-12-20) - 代码注入白名单提示完善与Docker环境变量修复

**代码注入体验与可观测性**

- 🚦 **系统设置页告警提示**
  - 后端 `GET /api/admin/settings` 会返回代码注入校验 `warnings`，用于前端展示。
  - 当 `config.toml` 预置的代码注入包含不被允许的域/标签/属性时：
    - 配置仍会正常加载（不影响服务启动）。
    - 系统设置 → 代码注入会展示红色告警并高亮对应（Header/Body）编辑器。

**部署修复**

- 🐳 **Docker 环境变量**
  - Docker 镜像内默认补充 `CODE_INJECTION_ALLOWED_HOSTS=analytics.hxcn.dev`，避免生产环境因未加载本地 `.env` 导致白名单缺失。

### v2.7.3 (2025-12-20) - TypeScript类型安全增强与UI交互优化

**类型系统增强**

- 🔧 **TypeScript类型完善**
  - 扩展 User 类型，新增 `status` 和 `schedules` 可选字段，支持用户状态和课表关联。
  - 导入会话接口新增 `source` 字段（'real' | 'fallback'），标识验证码来源。
  - 导航组件新增 `NavItem` 类型定义，支持外部链接和按钮点击事件。
  - Toast 容器样式函数返回类型明确为 `CSSProperties`，增强类型安全。
  - 事件模态框 `delete` 事件类型从可选改为必需，统一删除逻辑。

- 📝 **表单输入类型安全**
  - 筛选侧边栏输入事件使用 `HTMLInputElement` 类型断言。
  - 事件模态框周数输入使用空值合并运算符（`??`）替代逻辑或（`||`）。
  - 课表编辑器状态选择函数参数类型明确为 `'进行' | '结束' | '隐藏'`。

**UI/UX改进**

- 🎨 **侧边栏折叠功能**
  - 新增可折叠侧边栏，支持展开/收起状态持久化（localStorage）。
  - 折叠状态下显示图标和展开按钮，节省屏幕空间。
  - 主内容区域和页脚自动适应侧边栏宽度（lg:pl-72 ↔ lg:pl-20）。
  - 使用 UI Store 管理折叠状态，支持跨组件同步。
  - 轮询机制确保同标签页内状态实时更新。

- 👤 **个人资料页面重设计**
  - 邮箱绑定/更换功能集成到个人资料页面。
  - 新增邮箱验证码发送功能，支持60秒冷却。
  - 修改密码时，已绑定邮箱的用户需要输入邮箱验证码。
  - 统计卡片重新设计：课表数、课程数、注册时间三列布局。
  - 安全概览卡片展示最近登录设备、IP、浏览器信息。
  - 用户头像支持 2xl 和 3xl 尺寸（w-24/h-24 和 w-32/h-32）。

**管理功能优化**

- 👥 **用户管理界面改进**
  - 用户课表信息显示使用可选链操作符（`?.`），避免空值错误。
  - 封禁状态判断从 `role === 'banned'` 改为 `status !== 'normal'`。
  - 用户课表模态框 API 调用统一使用 `createScheduleEvent` / `updateScheduleEvent` / `deleteScheduleEvent`。

**Bug修复**

- 🐛 **ICS导入修复**
  - 修复从文件导入课表时未携带认证 Token 的问题。
  - 使用 localStorage 获取 access_token 并添加到请求头。
  - 导出函数参数使用空值合并确保类型安全。

- 🔧 **环境变量类型声明**
  - 新增 `env.d.ts` 文件，声明 Vite 环境变量类型。
  - 定义 `ImportMetaEnv` 接口，包含 `VITE_API_BASE_URL` 可选字段。

**技术改进**

- ✅ 新增 UI Store 方法：
  - `initSidebarState()` - 初始化侧边栏状态
  - `toggleSidebar()` - 切换侧边栏展开/收起
  - `setSidebarCollapsed(value)` - 设置侧边栏状态
- ✅ 布局响应式优化：主内容区和页脚支持过渡动画（transition-all duration-300）
- ✅ 类型安全提升：移除类型断言，使用明确的类型定义
- ✅ 代码质量改进：使用现代 TypeScript 语法（可选链、空值合并）

### v2.7.2 (2025-12-20) - 管理员安全增强与UI体验优化

**安全增强**

- 🔐 **管理员密码变更追踪**
  - 新增 `password_changed` 字段追踪管理员是否已修改默认密码。
  - 首次启动的管理员必须修改密码才能解除安全警告。
  - 移除基于 localStorage 的检查，改用数据库字段追踪。
  - 新增迁移脚本：`scripts/migrations/add_password_changed_field.py`

**UI/UX改进**

- 🎨 **个人资料页面重设计**
  - 采用 shadow-sm、ring-1 和 rounded-xl 样式重新设计个人资料卡片。
  - 响应式布局：移动端垂直居中，桌面端水平左对齐。
  - 优化角色徽章样式，添加 ring-1 ring-inset 提升视觉一致性。
  - 使用响应式网格布局重新组织个人信息展示。

- 🎯 **通知系统统一化**
  - `FirstStartAdminModal` 和 `MySchedulePage` 替换 alert 对话框为 Toast 通知。
  - 密码修改成功/失败显示详细的 Toast 提示。
  - ICS 导入功能改用 Toast 显示导入数量或错误详情。

- 📤 **分享功能增强**
  - `ShareOptionsModal` 新增 scheduleId 属性，未选课时禁用链接分享。
  - 重新设计模态框布局：水平标题栏、描述文本、关闭按钮。
  - `ShareScheduleView` 添加撤销确认对话框，防止误操作。
  - 使用统一的 useToastStore 替代分散的 Toast 通知。

**管理界面增强**

- 👥 **用户管理界面优化**
  - `UserEditModal` 新增邮箱输入字段，支持验证。
  - `UserManagementPage` 表格新增邮箱列显示，未绑定显示"未绑定"。
  - 更新 User 和 UpdateUserRequest 类型，添加可选邮箱字段。
  - 表单提交时自动处理邮箱去除首尾空格和 null 转换。

**配置管理优化**

- ⚙️ **配置热重载支持**
  - 新增 CONFIG_TOML_PATH 和 CONFIG_PATH 环境变量支持自定义配置路径。
  - 实现配置文件修改时自动热重载机制。
  - 通过 _last_mtime 追踪文件修改时间，透明地检测配置变更。
  - 使用 pathlib.Path 实现跨平台路径处理。

- 📝 **代码注入配置改进**
  - 空的代码注入字段从 `""` 改为 `''' '''`（多行字符串）。
  - 保持内容为空的同时使用 TOML 多行字符串语法。
  - 提升配置文件可读性和 TOML 规范一致性。

**邮件系统修复**

- 📧 **模板变量语法修复**
  - HTML 模板中替换 `{code}` 和 `{year}` 为 `$CODE` 和 `$year`。
  - 更新 Template.substitute() 调用，使用大写的 CODE 占位符。
  - 确保使用 Template 字符串插值而非 f-string 格式化。

**数据库迁移优化**

- 🗄️ **迁移脚本改进**
  - 修正课表分享迁移脚本的备份文件名格式：`schedule_app.db_backup_`。
  - 修正迁移脚本中的数据库相对路径：从 `backend/` 改为 `../../backend/`。
  - 新增 `add_password_changed_field.py` 迁移脚本，支持 `--db-path` 和 `--skip-backup` 参数。

**文档完善**

- 📚 **部署指南增强**
  - 新增版本特定的迁移需求说明，包含升级路径。
  - 记录 v2.6.0+ 和 v2.7.0+ 升级的必需迁移。
  - 添加每个迁移脚本的版本引入日期。
  - 包含多版本升级的执行顺序说明和备份警告。

### v2.7.1 (2025-12-19) - 安全加固与受控注入升级

**安全增强**

- 🔐 **管理员初始化安全加固**
  - **移除硬编码默认口令**：首次启动（数据库无管理员）自动创建 `student_id=admin` 管理员，并生成一次性随机强口令。
  - **一次性输出**：初始口令仅在后端启动日志中以 `[SECURITY]` 前缀输出一次；请首次启动后立即保存。
  - **强制修改提醒**：默认管理员首次登录会弹出不可跳过的提示，引导尽快修改密码。

- 🧩 **受控代码注入机制升级（统计脚本 / 样式表 / Meta）**
  - **从任意 HTML 注入收敛为结构化条目**：后端解析/校验后输出 `script/link/meta` 结构化数据，前端通过 DOM API 渲染（不再使用任意 HTML 注入）。
  - **外域白名单**：外部资源必须为 `https://` 且 host 必须在环境变量 `CODE_INJECTION_ALLOWED_HOSTS` 中（多个域名逗号分隔）。
  - **失败即关闭（fail-closed）**：校验失败会拒绝保存，公开端点返回空列表。
  - **CSP 同步**：如新增统计域名，需要同步更新反代层 CSP（Docker 示例见 `docker/nginx.conf`）。

- 🪪 **头像 URL 校验**
  - 仅允许本地头像路径（`storage.local.base_url` 下）或 HTTPS 且 host 属于配置存储域名（`storage.alist.url`/`storage.alist.access_domain`），降低 XSS/追踪风险。

- 🧾 **上传日志脱敏（AList/第三方上传）**
  - 结构化日志替换调试输出，对 `Authorization/token/password/cookie` 等敏感字段脱敏。
  - 避免在错误详情中返回第三方响应体，降低凭证泄露风险。

### v2.7.0 (2025-12-18) - 邮箱验证与用户封禁体系升级

**核心功能**

- 📧 **邮箱验证与绑定系统**
  - **注册邮箱验证**：新用户注册时必须验证邮箱，通过SMTP发送验证码。
  - **强制邮箱绑定**：老用户登录后强制补录邮箱（全屏模态框，无法关闭）。
  - **邮箱配置管理**：管理后台支持配置SMTP服务器（用户名、密码、服务器地址、端口、加密方式）。
  - **测试邮件功能**：支持发送测试邮件验证SMTP配置是否正确。
  - **验证码冷却**：60秒发送间隔限制，防止滥用。
  - **邮箱服务**：支持SSL/TLS/Plain三种加密方式，兼容QQ邮箱、163邮箱等主流邮箱服务商。

- 🔐 **找回密码功能**
  - **自助重置密码**：用户可通过学号+邮箱+验证码重置密码。
  - **安全验证流程**：验证学号存在、邮箱已绑定、验证码正确后才能重置。
  - **独立找回页面**：新增 `/forget` 页面，登录页添加"忘记密码"入口。

- 🛡️ **用户封禁体系升级**
  - **多种封禁类型**：支持账号封禁（ban）、IP封禁（ipban）、邮箱封禁（emailban）三种封禁方式。
  - **状态字段重构**：新增 `status` 字段（normal/ban/ipban/emailban）替代原有 `role` 字段的封禁逻辑。
  - **封禁UI优化**：用户管理页面支持下拉选择封禁类型，显示当前封禁状态。
  - **登录拦截增强**：封禁用户无法获取登录Token，返回403错误。
  - **管理员绕过**：系统管理员可绕过IP封禁限制。
  - **邮箱封禁检查**：发送验证码时检查邮箱是否被封禁。

- 🎨 **Toast通知系统**
  - **全局Toast组件**：HeroUI风格的顶部右侧Toast通知系统。
  - **3D堆叠效果**：多个Toast支持3D堆叠显示，hover时展开。
  - **进度条指示**：自动倒计时进度条（默认3000ms）。
  - **多种类型**：支持success/error/warning/info四种通知类型。
  - **全局单例模式**：解决Astro多Vue island状态分裂问题。
  - **SSR兼容**：修复Teleport导致的hydration警告。
  - **全面替换**：所有表单、模态框的成功/错误提示统一使用Toast。

**邮件模板升级**

- 📨 **现代化邮件设计**
  - **品牌化模板**：包含Logo、图标、配色方案的专业邮件模板。
  - **响应式设计**：完美适配桌面和移动端邮件客户端。
  - **中文编码修复**：使用RFC 2047编码正确显示中文发件人名称。
  - **动态年份**：邮件页脚版权信息使用动态年份。
  - **视觉层次**：改进排版、图标、按钮样式，提升专业度。

**系统优化**

- 🗄️ **数据库迁移**
  - **自动迁移脚本**：`add_email_and_status_fields.py` 自动添加email和status字段。
  - **数据迁移**：将现有 `role='banned'` 用户迁移到 `status='ban'`。
  - **自动备份**：迁移前自动备份数据库文件。
  - **幂等性保证**：脚本支持重复执行，跳过已存在的字段。

- ⚙️ **配置管理优化**
  - **移除config.toml**：站点配置、存储配置、代码注入配置改用环境变量。
  - **邮箱配置集成**：系统设置接口新增邮箱配置（EmailConfig）。
  - **配置完整性检查**：`is_email_config_complete()` 辅助函数检查SMTP配置是否完整。

**UI/UX改进**

- ✨ **交互体验提升**
  - **统一通知系统**：所有成功/错误消息使用Toast，移除内联提示。
  - **邮箱绑定检查器**：登录后自动检查邮箱绑定状态，未绑定则强制绑定。
  - **封禁确认弹窗**：BanUserModal支持封禁/解封双模式，替代原生confirm()。
  - **QQ邮箱提示**：系统设置中输入@qq.com时显示授权码申请提示。
  - **163邮箱提示**：提示163/126/yeah.net邮箱需要使用授权码。

**技术改进**

- ✅ 新增后端服务：`services/email.py` - 邮件发送与验证码管理
- ✅ 新增前端组件：
  - `EmailBindingChecker.vue` - 强制邮箱绑定检查器
  - `ForceBindEmailModal.vue` - 强制绑定邮箱模态框
  - `ForgetPasswordForm.vue` - 找回密码表单
  - `BanUserModal.vue` - 封禁用户确认弹窗
  - `ToastContainer.vue` / `ToastItem.vue` - Toast通知组件
- ✅ 新增API端点：
  - `POST /send-verification-code` - 发送邮箱验证码
  - `POST /bind-email` - 绑定邮箱
  - `GET /email-required` - 检查邮箱是否必填
  - `POST /reset-password` - 重置密码
  - `POST /test-email` - 测试邮件连接
- ✅ 新增Schemas：
  - `SendVerificationCodeRequest/Response` - 验证码请求/响应
  - `BindEmailRequest` - 绑定邮箱请求
  - `ResetPasswordRequest` - 重置密码请求
  - `BanUserRequest` - 封禁用户请求（含ban_type）
  - `EmailConfig` - 邮箱配置模型
- ✅ 数据模型更新：
  - User模型新增 `email` 和 `status` 字段
  - UserPublic schema新增 `status` 字段

**安全增强**

- 🔒 **验证码安全**：60秒冷却时间，防止暴力破解
- 🔒 **封禁Token拦截**：封禁用户在authenticate_user阶段被拦截，无法获取JWT
- 🔒 **邮箱封禁检查**：发送验证码前检查邮箱是否被封禁
- 🔒 **管理员保护**：管理员跳过强制邮箱绑定流程
- 🔒 **向后兼容**：使用hasattr()安全检查status字段，兼容旧数据

### v2.6.0 (2025-12-17) - 课表分享与站点配置系统

**核心功能**

- 🔄 **全功能课表分享系统**
  - **分享链接生成**：支持为任意课表生成唯一的公开访问链接。
  - **权限控制**：支持三种权限模式（仅查看、需要登录访问、允许导入副本）。
  - **有效期管理**：可设置 7 天、30 天、半年、永久等多种有效期。
  - **课表导入**：访问者可将分享的课表一键保存到自己的账户中。
  - **分享管理**：独立的分享管理面板，支持查看访问次数、撤销分享。

- ⚙️ **站点配置管理系统**
  - **动态站点信息**：在管理后台直接修改网站名称、描述、SEO 关键词。
  - **品牌个性化**：支持自定义站点 Logo 和 Favicon 图标。
  - **多源图标支持**：支持使用系统预设图标、外部图片 URL 或本地上传图片（需配置 AList）。
  - **代码注入**：支持配置全局统计代码（Analytics Code）。
  - **实时预览**：配置修改即使生效，提供所见即所得的预览功能。

**UI/UX 改进**

- 🎨 **视觉体验升级**：全面使用 Heroicons 图标库替换原有 Emoji，提升界面专业度与一致性。
- 📅 **课表编辑器优化**：统一的输入框与下拉菜单样式，新增自定义状态选择组件，支持"恢复默认"操作。
- 📝 **代码编辑器增强**：配置编辑器支持深色模式与自动换行（Word Wrap）切换。
- 🧩 **模态框优化**：改进模态框层级管理（Z-index），修复连接测试结果显示方式。

**系统与运维**

- 🐳 **Docker 优化**：修复 Docker 构建依赖问题，优化基础镜像，新增自动发布工作流。
- 📂 **脚本规范化**：重组 `scripts` 目录，归档数据库迁移脚本与启动脚本。
- 🛡️ **数据安全**：迁移脚本增加自动数据库备份功能。

### v2.5.4 (2025-11-02) - 团队筛选权限修复与只读成员课表

**问题修复**

- 修复：普通成员/团队管理员在团队视图筛选他人课表时出现 403 或筛选结果为空的问题。现在会在筛选请求中自动携带当前团队 `team_ids` 并在请求前同步视图对应的日期范围；当存在筛选条件时，日历优先使用过滤结果进行渲染。（前端 `TeamViewPage.vue`、`stores/schedule.ts`）

**新增功能**

- 新增：只读的“成员课表查看”面板，供团队创建者/团队管理员使用。支持周/月视图、日期导航，以及从过滤接口汇总生成的“课表选择”下拉；非系统管理员不再调用管理员专用接口。（前端 `UserScheduleViewer.vue`、`TeamEditorModal.vue`）

**其他修复**

- 修复：`UserScheduleViewer.vue` 模板缺失闭合标签导致的编译错误。

### v2.5.3 (2025-11-01) - 团队管理权限与复选框点击修复

**问题修复**

- 修复：以团队创建者身份从 CreatorTeamManagement 打开 TeamEditorModal 无法进行任何操作的问题。通过在模态框挂载时初始化认证状态，确保权限判断生效，与 AdminTeamManagement 行为一致。（前端 `TeamEditorModal.vue`）
- 修复：成员列表与“全选”复选框需要点击视觉中心下方才会触发的问题。调整元素层级与指针事件，确保复选框视觉中心处点击即可正确响应。（前端 `TeamEditorModal.vue`）

**影响范围**

- 仅前端交互与权限判定逻辑，无后端改动。
- 既有管理员入口行为不受影响。

### v2.5.2 (2025-10-31) - 中国大陆网络优化与加载加速

**网络与性能优化**

- 移除 Google Fonts 与 Material Icons 外链，改用本地/系统字体栈，避免在中国大陆网络环境下因 `fonts.googleapis.com` 阻断引发的 `net::ERR_SOCKET_NOT_CONNECTED`。
- 更新 Tailwind `sans` 字体栈为中文友好系统字体（PingFang SC、Microsoft YaHei、Noto Sans SC、Source Han Sans SC 等），提升可读性与加载速度。
- 减少第三方阻塞请求，加快登录页与仪表板首屏渲染，改善部分安卓设备加载过慢问题。
- 在弱网/受限网络环境下提升稳定性，避免外部资源加载失败导致的渲染卡顿。

### v2.5.1 (2025-10-30) - 模态框交互体验优化

**可访问性增强**

- ♿ **模态框焦点管理**：改进用户交互流程
  - EventModal 添加初始焦点管理，自动聚焦到取消按钮
  - UserScheduleModal 增强焦点控制，提升键盘导航体验
  - TeamEditorModal 优化嵌套模态框交互逻辑
- 🎯 **嵌套模态框处理**：防止意外关闭
  - TeamEditorModal 在日程模态框打开时阻止关闭
  - 保护用户操作流程，避免数据丢失
  - 优化模态框层级管理
- ⌨️ **键盘交互优化**：提升无障碍访问
  - 响应式焦点引用管理
  - 改进 ESC 键和点击外部区域的行为
  - 确保焦点始终在可操作元素上

**技术改进**

- ✅ 引入 `initialFocusRef` 响应式引用
- ✅ 重构模态框关闭逻辑，支持条件关闭
- ✅ 统一焦点管理策略，提升用户体验
- ✅ 完善模态框组件的可访问性标准

### v2.5.0 (2025-10-30) - 登录记录管理与用户体验全面优化

**安全增强功能**

- 🔐 **登录记录管理系统**：完整的用户登录追踪功能
  - 新增 LoginRecord 模型，记录用户登录时间、IP地址、用户代理信息
  - 支持查看最近登录记录和完整登录历史
  - 管理员可查看所有用户的登录记录，增强安全监控
- 🛡️ **用户封禁与恢复**：完善的管理员工具
  - 新增用户封禁功能，支持管理员封禁违规用户
  - 用户封禁后无法登录系统，返回503错误页面
  - 支持解封恢复功能，灵活管理用户状态
- 📊 **登录历史集成**：用户管理增强
  - 用户管理页面新增登录记录查看功能
  - 个人资料页面集成登录历史展示
  - 提升用户对账户活动的透明度

**用户体验优化**

- 🎨 **更新日志功能**：新增版本更新追踪
  - 新增 ChangelogModal 组件展示更新内容
  - 后端代理接口避免CORS问题
  - UI状态管理新版本通知
  - 导航栏集成更新日志入口
- 🎯 **模态框系统重构**：统一交互体验
  - 使用 Headless UI 的 Dialog 和 Transition 组件
  - 增强可访问性和动画效果
  - 统一团队管理模态框样式和行为
  - 实现 Teleport 渲染，提升视觉层次
- 📋 **批量操作增强**：管理员效率提升
  - 新增 BatchActionBar 组件支持批量操作
  - 用户管理页面集成批量删除、封禁、恢复功能
  - 团队管理支持批量成员操作
  - 增强确认删除模态框支持批量操作

**界面与交互优化**

- 🎨 **下拉菜单统一设计**：视觉一致性提升
  - 新增统一下拉样式配置
  - 支持搜索过滤功能的下拉菜单
  - 优化选择器交互体验
- 📝 **输入框样式标准化**：表单视觉升级
  - 统一输入框基础样式
  - 增强搜索输入框视觉效果
  - 提升整体表单美观度
- ⏳ **加载状态优化**：更流畅的等待体验
  - 增大加载指示器尺寸，提升可见性
  - 优化字母间距，改善可读性
  - 统一加载动画样式

**日历与事件管理**

- 📅 **堆叠事件处理**：复杂课表场景支持
  - 新增 StackedEventsModal 处理同时间段多课程
  - 支持团队和个人视图的事件堆叠显示
  - 优化事件点击和模态状态管理
- 🔄 **课程时间更新**：课时调整标准化
  - 更新第10-11节课时间设置
  - 前后端时间计算逻辑同步
  - 优化事件重叠检测算法

**团队管理优化**

- 👥 **管理权限细分**：更精细的权限控制
  - 区分创建团队和管理团队权限
  - 支持查看可管理的团队列表
  - 优化团队操作权限判断逻辑
- 🏗️ **团队生命周期管理**：完整流程支持
  - 创建、管理、转让、解散全流程
  - 二次确认机制防止误操作
  - 团队转让和解散的完整记录

**系统优化**

- 🚀 **加载指示器统一**：性能与视觉提升
  - 新增 ButtonLoadingSpinner 和 PageLoadingSpinner 组件
  - 替换所有旧式加载指示器
  - 统一加载状态视觉风格
- 🗂️ **功能结构调整**：简化管理界面
  - 移除日程管理功能模块
  - 用户管理页面整合用户日程显示
  - 简化管理员导航结构
- 📖 **文档清理**：项目结构优化
  - 移除 FEATURE_GUIDE.md 文档
  - 调整文档策略和内容管理方式

### v2.4.0 (2025-10-22) - 团队管理员功能与权限增强

**新增功能**

- ✨ **团队管理员角色系统**：支持团队内部的分层管理
  - 新增团队管理员（Team Admin）角色，区别于系统管理员和团队创建者
  - 团队创建者可以将普通成员提升为团队管理员
  - 团队管理员拥有成员管理、课表管理等权限
  - 支持团队管理员降级为普通成员
- ✨ **团队管理员API接口**：
  - `POST /api/teams/{team_id}/admins/{user_id}` - 提升成员为团队管理员
  - `DELETE /api/teams/{team_id}/admins/{user_id}` - 移除团队管理员权限
- ✨ **增强的权限控制**：
  - 团队管理员可以管理团队成员（添加、移除）
  - 团队管理员可以编辑团队信息
  - 保护机制：不能移除团队创建者和系统管理员
  - 权限层级：系统管理员 > 团队创建者 > 团队管理员 > 普通成员

**后端改进**

- ✅ 新增 `team_admins_table` 关联表，支持多对多的团队管理员关系
- ✅ 新增 CRUD 函数：
  - `is_team_admin()` - 检查用户是否为团队管理员
  - `add_team_admin()` - 添加团队管理员
  - `remove_team_admin()` - 移除团队管理员
- ✅ 优化权限检查函数 `check_team_admin_permission()`
  - 支持系统管理员、团队创建者、团队管理员三种角色
- ✅ 增强成员移除逻辑：
  - 移除成员时自动清除其团队管理员权限
  - 禁止移除团队创建者
  - 禁止移除系统管理员
- ✅ 所有团队查询接口增加 admins 字段加载

**前端优化**

- ✅ 新增 `canAdminManage()` 函数判断管理权限
  - 团队管理员可以看到"管理团队"按钮
  - 普通成员显示"退出团队"按钮
- ✅ 团队响应数据包含管理员列表信息
- ✅ 优化团队管理界面的权限显示

**数据模型变更**

- ✅ Team 模型新增 `admins` 关系字段
- ✅ TeamResponse schema 新增 `admins` 字段
- ✅ 自动数据库迁移支持

### v2.3.0 (2025-10-14) - UI优化与品牌升级

**新增功能**

- ✨ **课表操作菜单重构**：全新的"更多"按钮设计
  - 整合5大核心功能：添加日程、导入课表、导出课表、放假调休、课表设置
  - 统一的模态框交互，提升用户体验
  - 响应式设计，完美适配移动端和桌面端
- ✨ **ICS文件导入增强**：优化导入流程
  - 新增导入选项弹窗，支持ICS文件和教务系统两种导入方式
  - 图标化界面，操作更直观
  - 详细的导入结果反馈
- ✨ **导出选项弹窗**：简化导出操作
  - 统一的导出入口
  - 支持PNG图片和ICS文件两种格式
  - 一键选择，快速操作
- 🎨 **品牌视觉升级**：增强品牌形象
  - 添加多种尺寸的favicon图标（PNG、JPG、SVG）
  - 优化网站图标显示效果
  - 提升浏览器标签页识别度

**UI/UX优化**

- ✅ 使用Heroicons图标库，统一视觉风格
- ✅ 优化按钮布局，减少界面复杂度
- ✅ 改进响应式断点设置
  - 移动端（< 640px）：图标优先显示
  - 桌面端（>= 640px）：图标+文字组合显示
- ✅ 优化操作流程，减少页面跳转

**技术改进**

- ✅ 新增`ImportOptionsModal.vue`组件
- ✅ 新增`ExportOptionsModal.vue`组件
- ✅ 重构`MySchedulePage.vue`操作按钮区域
- ✅ 优化文件上传和下载逻辑

### v2.2.1 (2025-10-07) - 代码清理与优化

**优化改进**

- 🧹 **代码清理**：移除所有测试和废弃代码
  - 删除示例用户创建代码
  - 移除数据库迁移脚本
  - 清理控制台调试日志
  - 删除临时捕获文件和备份文件
- ✅ **功能验证**：完成前后端功能测试
  - 后端API接口测试通过
  - 前端页面加载正常
  - 用户认证功能正常
- 📖 **文档更新**：更新README.md
  - 移除测试账户相关说明
  - 更新项目结构描述
  - 修正API接口文档说明

### v2.2.0 (2025-10-07) - ICS导入功能与UI优化

**新增功能**

- ✅ **ICS文件导入**：支持从标准ICS文件导入课表事件
  - 兼容苹果日历、Google Calendar、Outlook等主流日历应用
  - 自动计算事件的周数和星期几
  - 智能跳过早于课表开始日期的事件
  - 详细的导入结果反馈（成功数量、失败原因）
- ✅ **统一操作菜单**：重构课表页面UI
  - 新增"更多"按钮，整合5大核心功能
  - 添加日程、导入课表、导出课表、放假调休、课表设置
  - 模态框式交互，操作流程更清晰
- ✅ **导入选项弹窗**：新增 `ImportOptionsModal.vue` 组件
  - 支持从ICS文件导入
  - 支持从教务系统导入
  - 图标化界面，操作直观
- ✅ **导出选项弹窗**：新增 `ExportOptionsModal.vue` 组件
  - 导出为PNG图片
  - 导出为ICS文件
  - 一键选择，快速操作

**后端改进**

- ✅ 新增API端点：`POST /api/schedules/import-ics`
- ✅ ICS文件解析与验证逻辑
- ✅ 周数和星期自动计算算法
- ✅ 完善的错误处理和日志记录

**UI/UX优化**

- ✅ 响应式"更多"按钮设计（移动端/桌面端自适应）
- ✅ 使用 Heroicons 图标库统一视觉风格
- ✅ 优化操作流程，减少页面跳转
- ✅ 提升移动端使用体验

### v2.1.1 (2025-09-30) - 品牌升级

**品牌更新**

- ✅ **正式命名**：系统正式命名为"时序同笺 (SDNUChronoSync)"
- ✅ **界面更新**：导航栏、登录页、注册页全面使用新名称
- ✅ **文档完善**：README 更新品牌信息
- ✅ **导航增强**：新增"使用教程"和"关于"外部链接
  - 使用教程：https://hs.cnies.org/archives/chronosync-user-guide
  - 关于本项目：https://hs.cnies.org/archives/chronosync
- ✅ **用户体验**：所有页面统一品牌形象

### v2.1.0 (2025-09-30) - 团队管理系统完整升级

**核心功能增强**

- ✅ **团队所有权转让**：创建者可以安全转让团队管理权限给其他成员
- ✅ **团队解散功能**：带二次确认的团队解散流程，永久删除团队及成员关系
- ✅ **成员退出机制**：普通成员支持自主退出团队
- ✅ **高级筛选系统**：团队课表支持按成员、班级、年级多维度筛选
- ✅ **课程冲突识别**：智能识别和显示同一时间段的课程冲突
- ✅ **创建者管理面板**：专属的高级团队管理界面，统一管理所有创建的团队

**新增组件**

- ✅ `CreatorTeamManagement.vue` - 创建者高级管理面板
- ✅ `TransferTeamModal.vue` - 团队转让确认流程
- ✅ `DissolveTeamModal.vue` - 解散团队二次确认
- ✅ `LeaveTeamModal.vue` - 退出团队确认
- ✅ `TeamEventDetailModal.vue` - 课程冲突详情显示
- ✅ `FilterSidebar.vue` - 多条件组合筛选侧边栏

**后端架构改进**

- ✅ 团队转让接口：`POST /api/teams/{id}/transfer`
- ✅ 权限检查函数：`check_team_admin_permission()` / `check_team_member_permission()`
- ✅ 活跃课表筛选：只聚合 status="进行" 的课表
- ✅ 管理员全局监控：`GET /api/admin/teams` 获取所有团队统计

**UI/UX 优化**

- ✅ 移动端侧边筛选抽屉，完美适配小屏幕
- ✅ 实时状态反馈，所有操作提供即时成功/错误提示
- ✅ 团队卡片重新设计，清晰展示创建者/成员角色
- ✅ 统计卡片展示：我的团队数、创建的团队数、总成员数

### v2.0.0 (2025-09-28) - 高级调休与团队协作系统基础

**重大功能更新**

- ✅ **多课表管理系统**：支持创建和管理多个课表
- ✅ **高级调休功能**：节假日设置与智能换课系统
- ✅ **基础团队协作**：基于邀请码的团队创建和加入
- ✅ **权限分层管理**：系统管理员、团队创建者、普通成员三级权限
- ✅ **团队课表聚合**：查看团队所有成员的课程安排
- ✅ **调休记录管理**：支持撤销和修改调休设置
- ✅ **实时数据同步**：调休和团队变更立即生效
- ✅ **导航系统升级**：新增"我的团队"功能入口
- ✅ **API架构扩展**：新增团队和调休相关接口
- ✅ **数据库模型扩展**：新增 Team、user_teams_table、ScheduleAdjustment 模型

**技术改进**

- ✅ 服务器端调休逻辑处理，确保数据一致性
- ✅ 完善的错误处理和用户反馈机制
- ✅ 响应式UI适配新功能
- ✅ TypeScript类型系统完善
- ✅ 向后兼容性保证

### v1.2.0 (2025-09-27)

- ✅ 个人资料管理系统
- ✅ 头像上传功能（本地存储/AList支持）
- ✅ 密码修改功能
- ✅ 系统设置管理
- ✅ 教务系统课表导入

### v1.1.0 (2025-09-26)

- ✅ 多课表支持
- ✅ 课表导入功能
- ✅ ICS格式导出
- ✅ 课表状态管理
- ✅ 课程详细信息

### v1.0.0 (2025-09-25)

- ✅ 基础功能完成
- ✅ 用户认证系统
- ✅ 个人日程管理
- ✅ 团队视图功能
- ✅ 管理员功能
- ✅ 响应式 UI 设计
- ✅ 多平台支持
