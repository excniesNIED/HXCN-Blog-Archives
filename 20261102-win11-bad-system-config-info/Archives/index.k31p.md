---
title: 一块 150 GB 的 C 盘写满之后：0x74 BAD_SYSTEM_CONFIG_INFO 抢修实录
pubDatetime: 2026-11-02T00:00:00.000+08:00
slug: win11-bad-system-config-info
tags:
  - Windows 11
  - 注册表
  - 蓝屏
  - WinPE
  - 数据恢复
category: 踩坑日志
description: 一次 Win11 23H2 因 C 盘写满引发的 0x74 BAD_SYSTEM_CONFIG_INFO 抢修实录，从 BitLocker 状态、bcdboot/bootrec 全线失败、DISM 反复 0xd000014c，到定位 SECURITY hive 的脏标志、逐字节比对、受控加载实验，最后靠改两个字段把 hive 修回可加载状态。适合遇到 Windows 注册表损坏或引导故障的技术爱好者参考。
---

## 前言

先亮明我的观点：对于绝大多数人来说，一块硬盘一个分区足够用了。如果你有多块硬盘，那就一块硬盘一个分区；如果你只有一块硬盘，最多分个 C 盘和 D 盘也就够了。而系统盘 C 盘的容量，重度使用的话最少得留 200 到 300 GB，装个 512 GB 也不算过分。

为什么？你可以把软件装在 D 盘或者 E 盘，但 Windows 和各种软件的缓存、临时文件、系统组件、用户配置数据，绝大部分都会默认往 C 盘塞。C 盘太小、剩余空间不够，很多软件会跑不起来，严重时连系统都开不了机。还有一种很常见的情况：你手头有一个很大的游戏安装包或者一个很大的文件，硬盘上总剩余空间其实足够装下它，但因为分了三四个区，每个分区的剩余空间都单独装不下，最后只能对着报错干瞪眼。

很多人说软件装在 C 盘，重装系统数据就没了，所以要装在别的分区。这句话本身就站不住脚。重装系统之后，你装在 D 盘的那些软件同样会面临注册表丢失的问题，很多根本没法直接跑起来，照样得重装一遍。与其把精力花在分区上，不如搞清楚重装系统到底要备份什么：QQ 和微信的聊天记录（通常在 `C:\Users\<用户名>\文档` 下面）、下载目录里的文件（`C:\Users\<用户名>\下载`）、图片视频、桌面文件、浏览器保存的密码和密钥，再加一份 `C:\Users\<用户名>\NTUSER.DAT`（这个文件里保存着你的用户配置，重装后可以拿来对照原来装了哪些软件，以及桌面都放了些什么）。如果机器开了 BitLocker，还得提前解锁或者把恢复密钥备份出来。把这几样备份好，重装完把软件补齐、文件还原回去，就行了。

十多年前刚开始折腾电脑的时候，我爸那一辈特别喜欢把硬盘分成四个区。一部分原因是当年的 Ghost 装机光盘普遍带一键分四个区的功能，一块硬盘塞进光盘，点一下，C 盘 D 盘 E 盘 F 盘就出来了。这个习惯一直留到了今天，不少长辈帮家里小辈买电脑的时候，商家或者装机的人还是照着这个路子来。结果就是一堆机器硬盘没多大，分区倒是挺多，C 盘分出来就那么几十上百 GB。我也经常遇到 C 盘空间不足的同学来找我求助，每次都要先把别的盘的文件挪一挪、清一清，给 C 盘腾出点地方来。

如果你想反驳我的观点，今天舍友这台电脑莫名其妙蓝屏的事，就是现成的例子。

## 猜测和尝试

### 基本情况

舍友这台华硕笔记本，出厂预装 Windows 11 家庭中文版，一路自动更新到了 `22631.5768`。硬盘是 1 TB 的 SSD，分了 C 盘 150 GB、D 盘 389 GB、E 盘 389 GB，另外还带一个华硕出厂的 24 GB 恢复分区。C 盘里面装了 MATLAB、SQL Server 2022、Office 2014，还塞了一个 Steam 游戏库，平时就一直不太宽裕。

某天开机，直接蓝屏，错误码 `BAD_SYSTEM_CONFIG_INFO`，然后自动重启，接着再蓝屏。

![蓝屏崩溃界面](bsod-bad-system-config-info.svg)

反复几次之后，Windows 自动触发了启动修复，但不出意外，启动修复也修不了这台电脑：

![启动修复失败](startup-repair-failed.svg)

由于 C 盘早就被塞得太满，系统保护占用的空间也有限，机器上没有可用的还原点，想用系统还原直接回退到之前状态这条路走不通。舍友自己用豆包问了半天，跟着建议跑了几轮检查，该试的都试了，还是开不了机。

我听到这些之后的第一反应是：`chkdsk` 跑完没发现问题，说明硬盘本身大概率没坏；`sfc` 虽然没跑通，但也说明系统文件可能不是主要问题。既然硬盘没坏、系统文件看着也没大事，那最有嫌疑的就是引导配置坏了，于是接下来第一件事就是尝试修复引导。

用 Ventoy U 盘进 PE，打开 DISM++，结果它直接弹了个提示："试图加载不准确的格式"。这很不正常，DISM++ 干不了活，说明它连离线系统的注册表配置单元都读不出来。我试着让它修复引导，重启之后，屏幕上的报错变成了 `0xc0000001`：

![恢复错误界面 0xc0000001](recovery-error-0xc0000001.svg)

`0xc0000001` 这个码本身信息量不大，它基本等于"启动阶段有东西没起来"，什么也说不了。真正要看的，是崩溃转储和日志。

### 关掉 BitLocker

进 PE 之后，我先确认了一下 BitLocker 的状态。出厂预装 Windows 11 的机器，很多都有"设备加密"预置启用，密钥一般会托管到微软账户里。但舍友这台用的是本地账户，从来没有登录过微软账号，如果这时候磁盘被锁上了，恢复密钥根本没地方找。

所以先跑：

```cmd
manage-bde -status C:
```

```cmd
保护状态:      保护关闭
锁定状态:      已解锁
标识字段:      无
自动解锁:      已禁用
密钥保护器:    找不到

X:\Windows\System32>manage-bde -protectors -get C:
卷 C: [OS]
所有密钥保护器

错误: 找不到密钥保护器。
```

"密钥保护器：找不到"在这里反而是好消息，说明这台机器的设备加密从来没真正激活过，连保护器都没生成过。没有保护器，就不存在密钥丢失的问题，C 盘是明文 NTFS，PE 里直接就能读。

顺便用 `diskpart` 把磁盘布局也看了一遍：

```cmd
DISKPART> list vol

  卷 ###      LTR  标签         FS     类型        大小     状态       信息
  ----------  ---  -----------  -----  ----------  -------  ---------  --------
  卷     0     C    OS           NTFS   磁盘分区     150 GB  正常
  卷     1     D    新加卷       NTFS   磁盘分区     389 GB  正常
  卷     2     E    新加卷       NTFS   磁盘分区     389 GB  正常
  卷     3          RESTORE      NTFS   磁盘分区      24 GB  正常
  卷     4          SYSTEM       FAT32  磁盘分区     260 MB  正常       已隐藏
  卷     5          RECOVERY     NTFS  磁盘分区     950 MB  正常       已隐藏
  卷     6     H    MYASUS       FAT32  磁盘分区     260 MB  正常       已隐藏
  卷     7     F    Ventoy       exFAT  可移动       117 GB  正常
```

这一步的主要目的是确认卷 4 就是 EFI 引导分区（ESP），等下 `bcdboot` 要用到；同时确认恢复分区和 Ventoy U 盘都在。

为了保险，我把 C、D、E 三个分区各跑了一遍 `manage-bde -off`，防止后面操作或者重启的时候触发 TPM 重新锁定：

```cmd
manage-bde -off C:
manage-bde -off D:
manage-bde -off E:
```

顺带提一句：如果你的机器 BitLocker 已经真正启用，并且密钥托管在微软账户里，可以在另一台设备上访问 [https://aka.ms/myrecoverykey](https://aka.ms/myrecoverykey)，登录之后就能找到恢复密钥。这台机器没绑定微软账号，所以这条路用不上。

### 常规手段尝试

BitLocker 这个坑排除之后，我开始按标准的修复流程往下走。

先挂 ESP、重建引导：

```cmd
DISKPART> select volume 4
DISKPART> assign letter=S
DISKPART> exit

X:\Windows\System32>bcdboot C:\Windows /s S: /f UEFI /l zh-cn
已成功创建启动文件。
```

引导文件确实写进去了，`S:\EFI\Boot\bootx64.efi` 存在，1698760 字节。为了双保险，我还手动把 `S:\EFI\Microsoft\Boot\bootmgfw.efi` 覆盖成了 `S:\EFI\Boot\bootx64.efi`。

接下来轮到 `bootrec`：

```cmd
X:\Windows\System32>bootrec /scanos
扫描所有磁盘以查找与 Windows 兼容的安装...
已标识的 Windows 安装总数: 0
操作成功完成。

X:\Windows\System32>bootrec /rebuildbcd
扫描所有磁盘以查找与 Windows 兼容的安装...
已标识的 Windows 安装总数: 0

X:\Windows\System32>bootrec /fixboot
拒绝访问。
```

`scanos` 扫到 0 个安装，`fixboot` 直接拒绝访问。`bootrec` 判断"这里有没有 Windows"要读离线注册表里的卷映射和控制器配置，读不出来就会一个都不认。不过这两条报错本身信息量有限，当时我没敢就此下结论。

再往下是文件系统和组件存储：

```cmd
X:\Windows\System32>chkdsk C: /f
文件系统的类型是 NTFS。
卷标是 OS。
...
Windows 已扫描文件系统并且没有发现问题。
无需采取进一步操作。

  157286727 KB 磁盘空间。
  15979136 KB 可用。
```

`/f` 跑完五阶段全绿，连坏扇区都是 0。文件系统是干净的，硬盘没坏这个判断站住了。

```cmd
X:\Windows\System32>sfc /scannow /offbootdir=C:\ /offwindir=C:\Windows
正在开始验证 Windows 资源保护完整性。
Windows 资源保护无法执行请求的操作。
```

```cmd
X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /RestoreHealth
错误: 87

DISM 未识别命令行选项 "/Image:C:\"。
```

DISM 报"未识别 `/Image:C:\`"是命令行解析层面的问题，跟镜像本身无关。后来去 `dism.log` 里查了一下，发现那次输入的实际上是 `/Image:C\`，少打了个冒号。这种小插曲最费时间，因为会让人以为 DISM 本身坏了，转头去查工具版本。

真正有用的是这两条：

```cmd
X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /RevertPendingActions
部署映像服务和管理工具
版本: 10.0.22621.1
映像版本: 10.0.22631.5768

正在从映像中还原挂起的操作...

错误: 0xd000014c
```

```cmd
X:\Windows\System32>dism /Image:C:\ /Get-Packages /Format:Table
...
错误: 0xd000014c

DISM 失败。不执行任何操作。
```

`0xd000014c` 就是 `0xC000014C` 带上客户位，和转储里的 P4 完全一致。也就是说，DISM 和内核死在同一件事上。

这时候我又翻出启动修复生成的 `SrtTrail.txt` 来看：

```cmd
上一次成功启动的时间: 2026/11/1 9:32:11 (GMT)
尝试修复次数: 64
```

每次会话要跑十来个测试项，前面全是 `0x0`，只在最后一项翻车：

```cmd
会话 1   名称: 检查已安装的 LCU   结果: 成功完成。错误代码 = 0x43
会话 2   根本原因数 = 1
         找到的根本原因:
         启动修复已经尝试多次，但仍无法确定问题的原因。
会话 3   名称: 检查已安装的 LCU   结果: 成功完成。错误代码 = 0x14c
```

第三次那个 `0x14c` 和 DISM、和转储里的 P4 完全一致。启动修复想读"已安装的 LCU"列表，这需要打开 CBS store，而 CBS store 需要加载离线注册表配置单元，又绕回同一个地方。至于会话 2 里那句"无法确定问题的原因"，64 次尝试之后的原话，读起来相当无力。

到这里"引导坏了"这个假设可以排除了。ESP 是好的，BCD 是好的，`winload.efi` 也在，启动修复跑的十几个检测项全部通过。

按照豆包给的建议，我又试了回滚挂起的更新、清理挂起的更新事务、检查并卸载最近安装的更新包、测试 ControlSet 备用控制集，全都没有用。其中"检查已安装的 LCU"和"检查更新"本质上都要先加载注册表，所以自然都会失败。

然后我注意到一件事：C 盘只剩下 100 多 MB 可用空间。我帮舍友清掉了桌面上一些不重要的大文件之后，才腾出来 8.9 GB 左右。

结合 `dism.log` 里的日志和这个磁盘空间数据，我猜测是极度缺盘诱发的注册表损坏：Windows 更新或者 CBS 在写注册表配置单元的时候，磁盘满到写不进去，导致某个 hive 文件损坏，进而引发后面这一连串连锁反应。

既然 `0xd000014c` 明确指向注册表损坏，而 `DISMRepairLogFile.txt` 里反复出现"Failed to load offline SECURITY hive"，我就把目标锁定在了 `SECURITY` 这个配置单元上。我从自己电脑上复制了一份结构正常的 `SECURITY` 文件，准备替换上去试试。

## Agent 深入排查

替换之后，DISM 的报错确实消失了，但重启之后依然开不了机，还是 `0xc0000001`。我让豆包列了一下哪些组件还有可能损坏，它建议我替换 `SAM`、`COMPONENTS`，甚至继续用镜像里的 hive 覆盖。但这条路的危险性很高，我没有贸然执行。

我在 FirPE 里联网装了 oh-my-pi，开始用 AI Agent 系统地排查这个问题。Agent 没有像豆包那样直接给替换建议，而是先把所有日志、转储文件、注册表配置单元都拉出来分析了一遍。

### 从日志与转储文件锁定真凶

Agent 先帮我确认了 CBS 日志里的关键记录：

```cmd
2026-10-23 18:36:21, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:23, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:25, Info  CBS  System volume has 0G free disk space
```

后面紧跟一句 `Maint: incomplete, interruptions: 1`。这说明 10 月 23 日那天，C 盘是真的被写满到 0 字节可用了。舍友当时清掉几 GB 就继续用了，之后八九天确实一切正常。

分界点在 11 月 1 日。`SrtTrail.txt` 开头记着最后一次正常启动是 `2026/11/1 9:32:11 (GMT)`，换算成本地时间 11 月 1 日 17:32。DISM 的修复日志从 11 月 1 日 17:35 开始出现"SECURITY 加载失败"，一直记到 11 月 2 日 15:21；最后一份崩溃转储的时间戳是 11 月 2 日 15:36。

Agent 把 `C:\Windows\Minidump\110226-9312-01.dmp` 的头部读了出来：

```cmd
signature   = PAGE / DU64
major/minor = 15.22621
bugcheck    = 0x74  (BAD_SYSTEM_CONFIG_INFO)
P1 = 0x2
P2 = 0xffff94869fbd2940
P3 = 0x1
P4 = 0xffffffffc000014c
崩溃时间     = 2026-11-02 07:36:19 UTC（= 15:36 本地）
内嵌 ASCII  = "HiveLoadFromomFile" + "status"
内嵌 UTF-16 = "<SECURITY"
```

P4 是 `0xC000014C`，即 STATUS_REGISTRY_CORRUPT。最后那行 UTF-16 字符串已经把答案写在脸上了：**加载 SECURITY 的时候判定注册表损坏**。`P1 = 0x2` 我一开始也去查了含义，查到的说法互相矛盾，所以只看 P4 和字符串就够了，不用猜。

顺带说一句，`HiveLoadFromomFile` 那个重复的 `om` 不是我抄错，内核日志字符串拼接本来就是这个样子。

Agent 把 `DISMRepairLogFile.txt` 里加载失败的记录全部抽了出来：

```cmd
2026-11-01 17:35:29  SECURITY  0xd000014c
2026-11-01 17:37:01  SECURITY  0xd000014c
2026-11-01 21:45:55  SECURITY  0xd000014c
2026-11-01 21:47:30  SECURITY  0xd000014c
2026-11-01 21:48:30  SECURITY  0xd000014c
2026-11-01 22:13:43  SECURITY  0xd000014c
2026-11-01 22:16:57  SECURITY  0xd000014c
2026-11-02 11:05:03  SECURITY  0xd000014c
2026-11-02 11:13:58  SECURITY  0xd000014c
2026-11-02 11:42:04  SECURITY  0xd000014c
2026-11-02 12:50:55  SECURITY  0xd000014c
2026-11-02 13:55:22  SECURITY  0xd000014c
2026-11-02 15:21:12  SYSTEM    0xd0000043
```

12 次 SECURITY 失败，全是 `0xd000014c`，前后跨了将近 22 小时。最后那条 SYSTEM 的 `0xd0000043` 是唯一的例外。`0xd0000043` 是 STATUS_SHARING_VIOLATION，意思是这个 hive 文件正被别的句柄占着，最常见的成因是之前 `reg load` 过、忘了 `reg unload`。它只出现这一次，前面 12 次 SYSTEM 都加载得好好的。这条是我自己操作留下的痕迹，不是故障本身。

原文长这样：

```cmd
Failed to load offline \\?\C:\Windows\System32\config\SECURITY hive from '\\?\C:\Windows\System32\config\SECURITY' into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SECURITY'
Failed to load offline registry: {bf1a281b-...}C:/Windows/System32/config/SECURITY [HRESULT = 0xd000014c - NTSTATUS Error]
Failed to load offline SECURITY hive. [HRESULT = 0xd000014c - NTSTATUS Error]
Failed to load offline store from boot directory: '\\?\C:\' and windows directory: '\\?\C:\Windows\' [HRESULT = 0xd000014c]
```

CBS 是串行加载的：SOFTWARE → SYSTEM → SECURITY。前两个成功了，卡在第三个，然后整个 store 初始化失败，后面所有命令连带失败。这就是为什么 `Get-Packages`、`RevertPendingActions`、`sfc`、`bootrec` 全部报同一个错，它们都要先建这个 store。

### 为什么换上我的 SECURITY 还是开不了机

DISM 通了，说明文件结构合法；内核开不了机，说明这份文件还有别的问题。这两件事不矛盾，因为**结构合法**和**属于这台机器**完全是两码事。

Agent 把顶上去的那份 SECURITY 读出来：

```cmd
计算机名   HXCN-WIN
机器 SID   S-1-5-21-1262172508-...
```

本机 SAM 里是：

```cmd
计算机名   LAPTOP-VQSR6OMV
机器 SID   S-1-5-21-4291209427-303460211-4247354471
```

`PolAcDmS` 对不上 SAM 的域 SID，`PolAcDmN` 对不上 SYSTEM 的 `ComputerName`。更致命的是 `Policy\Secrets`：里面是 `NL$KM`、`M$_MSV1_0_TBAL_PRIMARY_{22BE8E5B-...}`、`DefaultPassword`、`MouseWithoutBorders`，**没有 `DPAPI_SYSTEM`**。本机的 DPAPI 主密钥不在里面。

这么开机会怎样：LSA 初始化时发现 SECURITY 和 SAM 的域 SID 不一致，大概率直接拒绝；就算侥幸过了，本机所有 DPAPI 数据——浏览器保存的密码、EFS 证书、凭据管理器——全部解不开，因为这些密文是用本机 `DPAPI_SYSTEM` 加密的，而那份主密钥只存在于原始的 SECURITY 里。

所以这次"修复"是个纯粹的假象：它只解决了 DISM 的报错，把问题从"文件加载不了"变成了"文件不是这台机器的"。后者更难看出来，因为所有工具都会告诉你一切正常。

真正的本机 SECURITY 一直躺在 `CorruptBak\SECURITY` 里，65536 字节，10 月 31 日 21:18 的副本。回到它，重新查。

### 序列号 17965 与 17964：两字节的脏标志

注册表 hive 的头是固定结构，前 4 KB 是头，之后是 hbin 块：

```cmd
偏移 0x000   "regf"                签名
偏移 0x004   seq1                  主序列号
偏移 0x008   seq2                  次序列号
偏移 0x01C   type                  hive 类型
偏移 0x024   root                  根键 nk 单元的偏移
偏移 0x028   hbins                 bins 区总字节数
偏移 0x1FC   checksum              头部校验和
```

校验和的算法很朴素：`dword[0x000..0x1F8]` 每 4 字节异或起来。有个边界约定，异或结果是 `0xFFFFFFFF` 时写 `0xFFFFFFFE`，是 `0` 时写 `1`。

读出来：

```cmd
CorruptBak\SECURITY   65,536 B   seq 17965 / 17964   校验和 0xb3d51b08（自洽）
```

`seq1 != seq2`，这就是"脏标志"（dirty flag）。它的语义是：上一次事务没提交完，这个 hive 处于中间状态，内核不能直接用。

按常理应该靠日志重放来追平。看看日志：

```cmd
SECURITY.LOG1   49,152 B   seq 208   （2022 年的陈旧日志）
SECURITY.LOG2    8,192 B   seq 17963 （比 hive 落后 2 个事务）
```

hive 是 17965/17964，能重放的日志序列必须是 17965 或 17965-1=17964。LOG1 停在 208，LOG2 停在 17963，**两个都对不上**。日志链断了，重放不可能。

10 月 23 日那次"0G free disk space"是最合理的解释：写事务时磁盘满了，数据落了盘，序列号没提交，日志也没跟上。这条属于推断，不是直接证据，CBS 那三行只证明了磁盘确实满过，没写它当时在写哪个 hive。

问题变成：能不能只清掉脏标志，不重放日志？

Agent 在 `D:` 上把所有组合都跑了一遍。全部用副本，没碰 C 盘一个字节。

| 用例 | hive 状态 | 附带日志 | `reg load` |
|---|---|---|---|
| s1 | 脏 17965/17964 | 无 | **失败** |
| s2 | 脏 17965/17964 | 0 字节 LOG1/LOG2 | **失败** |
| s3 | 脏 17965/17964 | 陈旧 LOG1(208)+LOG2(17963) | **失败** |
| t1 | 脏，seq2 再减 2（17965/17963） | 无 | **失败** |
| t2 | seq2 := seq1（17964/17964） | 无 | 成功 |
| i | 补丁后 17965/17965，无日志 | 无 | 成功 |
| j | 补丁后 17965/17965 | 陈旧 LOG1+LOG2 原样保留 | 成功 |
| s4 | seq 相等但校验和不重算 | 无 | **失败** |

结论比预想的干净：

- **只要 `seq1 != seq2` 就拒绝加载**，跟日志在不在、是不是 0 字节、能不能重放都没有关系。脏标志本身即致命。
- 只要 `seq1 == seq2` 且校验和正确，陈旧日志原样留着也不影响。
- 校验和必须重算，只改序列号不改校验和一样失败。

所以修复面只有两个字段：

```cmd
源   C:\Windows\System32\config\CorruptBak\SECURITY    65,536 B   17965 / 17964
改   0x008 处写回 17965                                            （清脏标志）
改   0x1FC 处重算校验和   0xb3d51b08  ->  0xb3d51b09
```

改完只差 2 个字节。

为了确认没改坏东西，Agent 把修好的文件和原件做了完整语义比对：两边都是 166 个键、164 个值，键名、值名、值类型、值数据逐项一致，0 处差异。结构走查也干净：166 个 nk 单元的父指针全对（非根键 165 个，零错配），33 个子键索引单元全是合法的 `lh`，2 个安全描述符单元完整，可达单元没有越界。

顺便验证了这份 hive 确实属于本机：

```cmd
PolAcDmN   LAPTOP-VQSR6OMV                        ← 与 SYSTEM\ComputerName 一致
PolAcDmS   S-1-5-21-4291209427-303460211-4247354471  ← 与 SAM 域 SID 一致
Policy\Secrets   8 条，含 DPAPI_SYSTEM、RasDialParams!...-1001#0、6 个 MSSQL/SQL 服务账户
根键 LastWriteTime   2026-11-01 09:32:10 UTC       ← 与"上次成功启动 11/1 17:32 本地"完全吻合
```

`Policy\Accounts` 里有 `-501/-1002/-1003` 但没有 `-1001`，而 SAM 里有 RID 1001 的账户。这个不用管，LSA 是按需创建账户项的，第一次用这个 SID 才会写进去。

### 发现了 BBI 和孤儿驱动问题

九个 hive 里还有一个不可加载的：`BBI`，1310720 字节，`53232/53231`，同样脏，同样 LOG1/LOG2 都是 0 字节。同样的两个字段处理掉就好。

BBI 不是引导配置，里面是 `WorkItems`（81 条）、`PackageImportance`（1431 条）、`Events`（136 条），属于 Boot Environment Infrastructure 的作业队列。它脏了不会蓝屏，10 月 31 日就脏了，11 月 1 日照样开机。但既然是唯一另一个"结构上不可加载"的 hive，顺手清掉。

另外查启动驱动时发现一个真缺陷：

```cmd
HKLM\SYSTEM\ControlSet001\Services\softaal
  ImagePath    = \??\C:\Program Files (x86)\Tencent\QQPCMgr\15.1.22354.301\softaal64_ev.sys
  Start        = 1  (SERVICE_SYSTEM_START)
  ErrorControl = 0
```

QQPCMgr 升级到 15.6 之后旧目录没了，`softaal` 还指着 15.1 的路径。`ErrorControl=0` 意味着加载失败会被忽略，所以它不会造成蓝屏，但每次开机都白试一次。改成 `Start=4` 禁用。

## 解决

### 镜像里那份 SYSTEM 只有 9 MB，为什么还是要用原版镜像

我手上有 `Win11_23H2_Chinese_Simplified_x64v2.iso`，版本 22631.2861。本来想直接从里面取一份干净的 hive 覆盖，试过之后确认这条路走不通。

镜像里的 `Windows\System32\config\` 是**通用安装态**，跟具体机器无关：

| hive | 镜像内 | 本机 | 覆盖后果 |
|---|---|---|---|
| SYSTEM | 9175040 B / 661 个服务 / `MINWINPC` | 32243712 B / 846 个服务 / `LAPTOP-VQSR6OMV` | 全部驱动服务和 Enum 设备树丢失，必然 INACCESSIBLE_BOOT_DEVICE |
| SAM | 8192 B（空库） | 131072 B / 5 个账户 | 账户全丢 |
| SECURITY | 8192 B（空） | 65536 B | LSA 机密全丢，DPAPI 数据永久打不开 |
| SOFTWARE | 66584576 B | 117440512 B | 所有已装软件的注册信息丢失 |
| BBI | 8192 B（空队列） | 1310720 B | 这个可以用 |

就地升级修复也不行。镜像 22631.2861 **低于**已装的 22631.5768，setup 会以"版本更低"直接拒绝。

所以镜像在这台机器上的正确用途是当**比对基线**：服务数量、驱动清单、SYSTEM 关键键、BBI 结构，全部拿镜像里的值来对照本机，确认哪些差异是正常的、哪些是缺陷。它不能当零件库。

### 完整备份，然后只改那两个字节

先把 `config` 整个目录备份到 D 盘，43 个文件、238.1 MB，含 9 个 hive 加全部 `.LOG1/.LOG2/.TM.blf/.regtrans-ms`，逐文件 SHA-256 比对确认字节一致。

然后：

```cmd
1) SECURITY   CorruptBak\SECURITY -> 改 0x008 / 0x1FC -> reg load 自检 -> 写回 C:
2) SECURITY.LOG1 / LOG2 -> D:\_fix\quarantine\   （隔离，消除歧义）
3) BBI        同 SECURITY 处理，53232/53231 -> 53232/53232
4) SYSTEM     挂载后把 softaal 的 Start 改成 4
5) 删除 C:\hiberfil.sys
6) 清理 $WinREAgent / $Windows.~BT / $SysReset / SoftwareDistribution\Download
```

`hiberfil.sys` 6715396096 字节（6.25 GiB），前 4 KB 全 0。头部已经废了，`winresume` 不可能从里面恢复任何东西，BCD 里四个 `resumeobject` 指向它只会让引导器白试一次。

这个文件就是纯占地方的。删掉之后 C 盘可用空间从 8.9 GB 变成 16.5 GB。

如果一开始就清干净，后面这些事可能压根不会发生。

这一步之后 `DISM /Get-Packages` 的输出是：

```cmd
部署映像服务和管理工具
版本: 10.0.22621.1

映像版本: 10.0.22631.5768

...
操作成功完成。
```

83 条包，状态全部"已安装"，没有 Pending。同一个命令，修复前是 `0xd000014c` 直接失败。这是"SECURITY 修好了"最硬的证据，比任何 `reg load` 自检都有说服力，因为它是完整走了一遍 CBS 的 store 初始化。

### 修复后全量复查

修完把九个 hive 逐个做了四层检查：头签名、序列号、校验和，hbin 链完整性，从根键一层层遍历下去（父指针、`li`/`lf`/`lh`/`ri` 子键表、值表），最后统计已分配但不可达的孤儿键。

```cmd
hive         字节         序列            脏  校验和  键        值
SYSTEM       32243712     395834/395834   否  OK      91,391    194,730
SOFTWARE     117440512    937587/937587   否  OK      372,888   640,232
SAM          131072       3911/3911       否  OK      80        100
SECURITY     65536        17970/17970     否  OK      166       164
DEFAULT      6029312      238433/238433   否  OK      8,201     10,937
DRIVERS      8777728      4850/4850       否  OK      36,424    52,954
COMPONENTS   32768000     9216/9216       否  OK      61,793    197,776
ELAM         32768        13/13           否  OK      1         0
BBI          1310720      53233/53233     否  OK      1,652     10,129
```

父指针错 0、子键表错 0、值表错 0、hbin 链断 0、孤儿键 0。九个 hive 全部 `reg load` 成功。

这一遍跑下来才敢确认：修的是脏标志，没碰任何数据。

有一个单元差点被误判成孤儿键：SYSTEM 里 `0xd1a718` 处、长度 72 字节，以 `6e 6b`（`nk`）开头。但 nk 单元最小长度是 `0x4C` = 76 字节，它不够，是一段恰好以 `nk` 开头的数据。差点为一个不存在的问题动手。

身份一致性也逐项对了一遍：

```cmd
PolAcDmN   LAPTOP-VQSR6OMV
PolAcDmS   S-1-5-21-4291209427-303460211-4247354471
ProfileList  S-1-5-21-...-1001  ->  C:\Users\admin
SAM 账户     admin / Administrator / DefaultAccount / Guest / WDAGUtilityAccount
Lsa boot key  TC463EF4966D8796     （由 JD+Skew1+GBG+Data 四个类名拼出）
```

`ControlSet001\Control\Lsa` 下 `JD`/`Skew1`/`GBG`/`Data` 四个键的值都是空的，真正的 SYSKEY 存在**类名**里，这也是为什么很多工具读不出来。

其余：

```cmd
DISM /Cleanup-Image /ScanHealth   未检测到组件存储损坏
DISM /Get-MountedImageInfo        无挂载残留
WinSxS\pending.xml                不存在
COMPONENTS\...\PackagesPending    空
Session Manager\BootExecute       autocheck autochk *
bcdedit {default}                 partition=C:  \Windows\system32\winload.efi
L:\Recovery\WindowsRE\Winre.wim   存在，BCD recoverysequence 指向它
启动驱动（Start 0/1，Type 1/2）   131 个，镜像文件缺失 0
存储类过滤器                       partmgr / volsnap / fvevol+iorate+rdyboost，全部系统默认
fsutil dirty query C:             没有损坏
```

## 尾声

**`WinSxS\Temp\InFlight` 堆了 5336 个目录、1498.9 MB**，时间戳从 2023-10-11 一直到 2026-11-02，是 DISM 和更新组件没回收的暂存副本。不占关键路径，但白吃 1.5 GB 空间。

顺带一件小事：排查过程中我自己跑了几次 `DISM /ScanHealth` 和 `/Get-Packages`，它们在 `InFlight` 下留了 7335 个目录、1393 MB 临时文件。查完删掉，C 盘可用空间从 16.0 GB 回到 16.5 GB。给下次留点余量，这次故障的起点就是 C 盘写满。

九个 hive 现在全干净、全部可加载，组件存储无损坏，引导链完整，没有任何挂起操作。重启之后能不能进系统，就看 LSA 认不认这份 SECURITY 了。

成功开机。

顺带说一句，最近 Windows 更新虽然修了不少重大问题，但每次修复都容易给用户带来新的问题。微软的工程质量这些年肉眼可见地下降，很难保证用户拿到手的系统质量。这次舍友的电脑，虽然直接诱因是 C 盘写满，但 Windows 更新在后台反复尝试写入、维护，也是把系统推向崩溃的重要因素之一。

因此我推荐用注册表禁用 Windows 更新。做法是创建一个 `.txt` 文件，把后缀改成 `.reg`，内容如下：

```reg
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings]
"FlightSettingsMaxPauseDays"=dword:00001b58
"PauseFeatureUpdatesStartTime"="2023-07-07T10:00:52Z"
"PauseFeatureUpdatesEndTime"="2042-09-05T09:59:52Z"
"PauseQualityUpdatesStartTime"="2023-07-07T10:00:52Z"
"PauseQualityUpdatesEndTime"="2042-09-05T09:59:52Z"
"PauseUpdatesStartTime"="2023-07-07T09:59:52Z"
"PauseUpdatesExpiryTime"="2042-09-05T09:59:52Z"
```

双击导入，就能把 Windows 更新暂停 1000 周。如果想恢复更新，再导入下面这个：

```reg
Windows Registry Editor Version 5.00

[HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings]
"FlightSettingsMaxPauseDays"=-
"PauseFeatureUpdatesStartTime"=-
"PauseFeatureUpdatesEndTime"=-
"PauseQualityUpdatesStartTime"=-
"PauseQualityUpdatesEndTime"=-
"PauseUpdatesStartTime"=-
"PauseUpdatesExpiryTime"=-
```

这样处理之后，系统不会再被后台更新反复折腾，C 盘也能省下不少空间。