---
title: 一块 150 GB 的 C 盘写满之后：Windows 11 0x74 BAD_SYSTEM_CONFIG_INFO 抢修实录
pubDatetime: 2026-11-02T00:00:00.000+08:00
slug: win11-bad-system-config-info
tags:
  - Windows 11
  - 注册表
  - 蓝屏
  - WinPE
  - 数据恢复
category: 踩坑日志
description: Windows 11 23H2 因 C 盘写满引发 0x74 BAD_SYSTEM_CONFIG_INFO 蓝屏的抢修记录，从关闭 BitLocker、重建 UEFI 引导、排查 DISM 0xd000014c 报错，到分析 SECURITY 注册表脏标志与两字节修补方案，并附暂停更新注册表脚本。适合遭遇系统崩溃与注册表损坏的用户参考。
---

## 前言

我一直认为，对大多数人来说，一块硬盘分一个区就够了。如果机器里装了多块物理硬盘，那就一块硬盘对应一个分区；如果整台电脑只有一块固态硬盘，最多也就是分出 C 盘和 D 盘两个区。在这个前提下，C 盘至少要留出 200 到 300 GB，要是平时重度使用电脑，给 C 盘留 512 GB 也不算多。

很多人习惯把软件安装路径手动改到 D 盘或者 E 盘，觉得这样就能给 C 盘减负。实际上，哪怕把主程序装在其他分区，软件运行时的 AppData 数据、着色器缓存、包管理器缓存、驱动解压包以及 Windows 自身的组件更新文件，还是会源源不断地往 C 盘里塞。一旦 C 盘划分得太小，剩余空间长期见底，轻则大型软件频频闪退，重则系统更新写坏核心文件直接开不了机。更尴尬的是，当你手里有一个上百 GB 的大文件或者大型游戏，整块硬盘加起来的剩余空间明明绰绰有余，却因为被人为切碎成了好几个小分区，导致没有任何一个分区能单独塞下它。

很多人分区的理由是“软件装在 C 盘，重装系统就全没了”。这个说法其实站不住脚。绝大多数现代软件都高度依赖 Windows 注册表项、系统运行库以及用户目录下的配置文件，哪怕你把程序本体装在 D 盘，重装完系统之后，D 盘里那些失去了注册表关联的软件照样跑不起来，最后还是得挨个重装。真正常规、省心的重装备份流程，根本不需要靠分区来维持，你只需要把下面这几类核心个人资产拷出来就够了：

- **即时通讯与社交记录**：QQ 与微信的聊天记录目录（通常默认存放在 `C:\Users\<用户名>\Documents\Tencent Files` 和 `WeChat Files` 中）。
- **个人常用归档目录**：下载目录（`C:\Users\<用户名>\Downloads`）、文档（`Documents`）、图片与视频文件夹，以及桌面（`Desktop`）上的全部文件。
- **软件安装参考对照表**：开始菜单快捷方式目录（`C:\ProgramData\Microsoft\Windows\Start Menu\Programs` 与 `C:\Users\<用户名>\AppData\Roaming\Microsoft\Windows\Start Menu\Programs`），外加用户注册表配置单元 `C:\Users\<用户名>\NTUSER.DAT`。保留这几样东西，重装完就能对照着一眼看出自己原先装过哪些软件、桌面上摆过哪些快捷方式。
- **凭据与安全密钥**：浏览器导出的密码账本、SSH/GPG 私钥、本地开发证书等。如果电脑开启了 BitLocker 驱动器加密，重装或折腾引导前更必须提前关闭加密，或者把 48 位恢复密钥导出备份好。

把这些真正有价值的数据备份到移动硬盘里，重装完干净的系统后再按需把软件补齐、把个人文件拷回来，远比守着一堆残缺不全的旧软件目录靠谱得多。

十多年前我刚开始学着折腾电脑的时候，父辈那代人特别喜欢把一块硬盘平均切成 C、D、E、F 四个分区。这种习惯很大程度上源于早年满天飞的盗版 Ghost 封装镜像，当年的装机光盘和 PE 工具普遍自带“一键分四区”按钮，装机店老板点一下鼠标就能交差。没想到十几年过去了，很多在长辈指导或者电脑城忽悠下买新电脑的同龄人，依然在把 1 TB 甚至 512 GB 的固态硬盘切成四个小得可怜的分区。这几年我隔三差五就会遇到同学抱着 C 盘彻底飘红的电脑来求助，每次我都得花上半天工夫，先把后面几个分区里的零散文件一点点归拢挪走，再缩容合并分区，给快要窒息的 C 盘腾出一口喘气的空间。

要是你看完上面这些还是不服气，觉得给 C 盘只留一百来 GB、把硬盘切得七零八落完全够用，那今天我帮舍友抢修这台莫名其妙蓝屏死机的电脑的完整经历，就是一个结结实实的反例。

## 猜测和尝试

### 基本情况

出事的是舍友的一台华硕笔记本（机器名 `LAPTOP-VQSR6OMV`），出厂预装 Windows 11 家庭中文版，平时跟着系统自动更新一路升到了 23H2（内部版本 `22631.5768`）。这台电脑配了一块 1 TB 的 NVMe 固态硬盘，买来的时候就按老习惯被切成了三个主分区：C 盘只分了可怜的 **150 GB**，剩下的空间被对半切成了两个 **389 GB** 的 D 盘和 E 盘。在这仅有的 150 GB 系统盘里，舍友不仅塞进了日常软件，还装了 MATLAB、SQL Server 2022、Office 2014，甚至还放了一部分 Steam 游戏库。

11 月 1 日傍晚，这台电脑毫无征兆地弹出了蓝屏，终止代码显示为 `BAD_SYSTEM_CONFIG_INFO`。

![蓝屏崩溃界面](bsod-bad-system-config-info.svg)

蓝屏收集完错误信息后自动重启，紧接着又是蓝屏、再重启。连续几次启动失败之后，Windows 11 自动触发了内置的恢复环境（WinRE），试图执行“启动修复”。毫无意外，自动修复转了半天圈之后直接宣告失败，屏幕上停在“启动修复无法修复你的电脑”，提示日志文件写在了 `C:\Windows\System32\Logfiles\Srt\SrtTrail.txt`。

![启动修复失败](startup-repair-failed.svg)

更糟的是，因为 C 盘空间常年捉襟见肘，系统的“系统保护”功能根本没有足够的空间去维护卷影副本（Shadow Copies），机器里连一个可用的系统还原点都没有，想靠自带的系统还原快速回滚是不可能了。

舍友在把电脑交给我之前，已经自己对着手机上的豆包尝试过一轮自救。他在恢复环境的命令提示符里跑了 `chkdsk` 磁盘检查和 `sfc` 系统文件扫描，但折腾完一圈还是原样蓝屏。我接手时先在脑子里做了一轮初步排除：既然 `chkdsk` 和 `sfc` 跑下来都没揪出致命问题，那固态硬盘大概率没有物理坏道或文件系统结构损坏，Windows 的核心二进制系统文件应该也没丢。顺着这个思路，我最先怀疑的是开机引导配置出了岔子。

我插上自己的 Ventoy 启动 U 盘，引导进入微 PE 系统，打开里面的图形化工具 DISM++，打算先用它的“引导修复”功能重构一下启动项。诡异的事情就在这时候发生了：刚点开 DISM++ 准备加载 C 盘的离线系统，软件直接弹窗报错，提示“**试图加载不准确的格式**”。我当时没太往注册表损坏那一层深想，强行点选修复引导之后重启了电脑。

这一重启，连原先的 `BAD_SYSTEM_CONFIG_INFO` 蓝屏界面都进不去了，电脑直接卡死在蓝底白字的 Recovery 恢复报错界面，错误代码变成了 `0xc0000001`。

![恢复错误界面 0xc0000001](recovery-error-0xc0000001.svg)

`0xc0000001` 在 Windows NT 状态码里对应的是 `STATUS_UNSUCCESSFUL`，属于最笼统的“引导设备或系统初始化失败”兜底报错。但结合刚才 DISM++ 报出的“试图加载不准确的格式”，我终于反应过来：问题恐怕根本不在引导分区，而在 `C:\Windows\System32\config\` 目录下的系统注册表配置单元（Hive 文件）。DISM++ 在打开离线系统时需要先挂载目标系统的注册表，如果某个核心注册表文件结构损坏或者在写入时被异常截断，工具就会直接抛出格式错误。

### 关掉 BitLocker

进 PE 之后，我看到 C、D、E 三个分区都显示 BitLocker。近几年的华硕、联想等品牌笔记本，出厂时普遍默认开启了 Windows 11 的“设备加密”（本质上就是简化版的 BitLocker）。如果用户平时登录了微软账户，48 位数字恢复密钥会自动上传托管到微软官网（可以通过手机或另一台电脑访问 `https://account.microsoft.com/devices/recoverykey` 查看并导出）。但舍友这台电脑从买来到现在一直用的是本地账户，从来没绑定过微软账号，手里更没有备份过任何纸质或文本密钥。如果在 PE 下贸然改写引导文件或系统配置，万一重启时触发了主板 TPM 芯片的完整性校验策略，把 C 盘直接锁死并弹出 BitLocker 恢复密钥输入框，那整块盘里的数据就真的神仙难救了。

为了摸清加密状态，我先在 PE 的命令提示符里执行了 `manage-bde` 状态查询与密钥保护器查询命令：

```cmd
X:\Windows\System32>manage-bde -status C:
BitLocker 驱动器加密: 配置工具版本 10.0.22621
版权所有 (C) 2013 Microsoft Corporation。保留所有权利。

卷 C: [OS]
[操作系统卷]

    大小:                 150.00 GB
    BitLocker 版本:       2.0
    转换状态:             完全解密
    已加密百分比:         0.0%
    加密方法:             XTS-AES 128
    保护状态:             保护关闭
    锁定状态:             已解锁
    标识字段:             无
    自动解锁:             已禁用
    密钥保护器:           找不到

X:\Windows\System32>manage-bde -protectors -get C:
BitLocker 驱动器加密: 配置工具版本 10.0.22621
版权所有 (C) 2013 Microsoft Corporation。保留所有权利。

卷 C: [OS]
所有密钥保护器

错误: 找不到密钥保护器。
```

看到 `保护状态: 保护关闭`、`锁定状态: 已解锁` 以及 `错误: 找不到密钥保护器` 这几行字，我悬着的心总算放了下来。这说明这台笔记本虽然出厂预置了 XTS-AES 128 的设备加密框架，但因为一直使用本地账户登录，加密保护器从头到尾就没有真正生成激活过，C 盘底层依然是明文可读的 NTFS 文件系统。自然也就不需要（同样也没办法）去导出根本不存在的恢复密钥了。

趁着这个机会，我接着运行 `diskpart` 查看了整块硬盘的分区与卷标分布，确认系统分区、数据分区和 EFI 引导分区的具体编号：

```cmd
X:\Windows\System32>diskpart

Microsoft DiskPart 版本 10.0.22621.1
在计算机上: MININT-BIUPGCV

DISKPART> list vol

  卷 ###      LTR  标签         FS     类型        大小     状态       信息
  ----------  ---  -----------  -----  ----------  -------  ---------  --------
  卷     0     C    OS           NTFS   磁盘分区     150 GB  正常
  卷     1     D    新加卷       NTFS   磁盘分区     389 GB  正常
  卷     2     E    新加卷       NTFS   磁盘分区     389 GB  正常
  卷     3          RESTORE      NTFS   磁盘分区      24 GB  正常
  卷     4          SYSTEM       FAT32  磁盘分区     260 MB  正常       已隐藏
  卷     5          RECOVERY     NTFS   磁盘分区     950 MB  正常       已隐藏
  卷     6     H    MYASUS       FAT32  磁盘分区     260 MB  正常       已隐藏
  卷     7     F    Ventoy       exFAT  可移动       117 GB  正常
```

从卷列表里可以清楚看到：卷 0 是 150 GB 的系统盘 `C:`；卷 1 和卷 2 是两个 389 GB 的数据盘 `D:` 和 `E:`；卷 4 是 260 MB、FAT32 格式的隐藏分区 `SYSTEM`，也就是 UEFI 启动必需的 ESP（EFI 系统分区）；卷 5 是 950 MB 的 `RECOVERY` 恢复环境分区；卷 7 则是我插着的 117 GB Ventoy 启动 U 盘。

为了防止后续反复重启和修改注册表时意外触发 TPM 自动上锁，我决定先把舍友桌面和文档里的重要资料拷到移动硬盘做好冷备份，然后对 C、D、E 三个分区逐一执行 `manage-bde -off` 命令，彻底关闭并清除半成品的 BitLocker 加密状态：

```cmd
X:\Windows\System32>manage-bde -off C:
X:\Windows\System32>manage-bde -off D:
X:\Windows\System32>manage-bde -off E:
```

执行完毕后再跑一次 `manage-bde -status C:`，确认转换状态维持在“完全解密”，BitLocker 这个最大的后顾之忧就算彻底排除了。

### 常规手段尝试

排除了加密锁盘的风险后，我把所有常见、标准的离线修复手段按顺序完整走了一遍，想看看能不能直接把系统拉回来。

第一步是彻底核验 C 盘的文件系统元数据。我运行了带修复参数 `/f` 的 `chkdsk C: /f`，让它跑完完整的五个阶段（基础文件系统结构、文件名链接、安全描述符与 USN 日志、用户文件数据簇、可用空间簇）：

```cmd
X:\Windows\System32>chkdsk C: /f
文件系统的类型是 NTFS。
卷标是 OS。
...
阶段 3: 检查安全描述符...
安全描述符验证完成。
阶段持续时间 (安全描述符验证): 21.64 毫秒。
  已处理 241480 个数据文件。
阶段持续时间 (数据属性验证): 0.26 毫秒。
CHKDSK 正在验证 Usn 日志...
  已处理 5588424 个 USN 字节。
Usn 日志验证完成。
阶段持续时间 (USN 日志验证): 13.72 毫秒。

阶段 4: 在用户文件数据中查找损坏的群集...
  已处理 1327856 个文件。
文件数据验证完成。
阶段持续时间 (用户文件恢复): 2.68 分钟。

阶段 5: 查找损坏的空闲群集...
  已处理 3994784 个可用簇。
已完成可用空间验证。
阶段持续时间 (可用空间恢复): 1.52 秒。

Windows 已扫描文件系统并且没有发现问题。
无需采取进一步操作。

总共有  157286727 KB 磁盘空间。
468801 个文件中有 139439744 KB。
241481 个索引    448468 KB。
坏扇区           0 KB。
系统正在使用     1419379 KB。
日志文件占用了    65536 KB。
磁盘上 15979136 KB 可用。
```

三分钟跑完，坏扇区为 0 KB，NTFS 元数据没有任何错误。既然文件系统本身是干净的，接下来第二步就是标准的手工重建 UEFI 引导。

在 `diskpart` 里，卷 4（260 MB 的 FAT32 ESP 分区）默认是隐藏且没有盘符的。我先选中卷 4，给它分配盘符 `S:`，然后退出 `diskpart`，使用 `bcdboot` 命令把 `C:\Windows` 下的最新引导模板和简体中文语言文件写入 `S:` 盘，并且手动把微软引导管理器 `bootmgfw.efi` 覆盖到固件默认兜底路径 `S:\EFI\Boot\bootx64.efi` 上：

```cmd
DISKPART> select volume 4

卷 4 是所选卷。

DISKPART> assign letter=S

DiskPart 成功地分配了驱动器号或装载点。

DISKPART> exit

退出 DiskPart...

X:\Windows\System32>bcdboot C:\Windows /s S: /f UEFI /l zh-cn
已成功创建启动文件。

X:\Windows\System32>dir S:\EFI\Boot
 驱动器 S 中的卷是 SYSTEM
 卷的序列号是 8CE7-BD30

 S:\EFI\Boot 的目录

2023/05/08  09:39    <DIR>          .
2023/05/08  09:39    <DIR>          ..
2025/08/15  08:38         1,698,760  bootx64.efi
               1 个文件      1,698,760 字节
               2 个目录    199,659,520 可用字节

X:\Windows\System32>copy S:\EFI\Microsoft\Boot\bootmgfw.efi S:\EFI\Boot\bootx64.efi
覆盖 S:\EFI\Boot\bootx64.efi 吗? (Yes/No/All): y
已复制         1 个文件。
```

`bcdboot` 明确提示“已成功创建启动文件”，`bootx64.efi` 的大小也是正常的 1,698,760 字节。但当我紧接着运行传统的 `bootrec` 扫描操作系统安装、尝试离线 `sfc` 和 `dism` 修复时，命令却接二连三地翻车了：

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

X:\Windows\System32>sfc /scannow /offbootdir=C:\ /offwindir=C:\Windows
正在开始系统扫描。此过程将需要一些时间。

正在开始验证 Windows 资源保护完整性。
Windows 资源保护无法执行请求的操作。

X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /RestoreHealth
错误: 87

DISM 未识别命令行选项 "/Image:C:\"。
```

这几条报错里藏着不少容易误导人的坑。首先，`bootrec /fixboot` 在 UEFI + GPT 架构的新版 Windows 10/11 下报“拒绝访问”其实是常态，因为 UEFI 启动靠的是 `bcdboot` 往 FAT32 分区写 `.efi` 文件，不需要老式 MBR 的扇区引导记录；但 `bootrec /scanos` 扫出“已标识的 Windows 安装总数: 0”以及 `sfc` 报“无法执行请求的操作”，就非常反常了——这两个工具在底层都需要先挂载并校验 `C:\Windows\System32\config\` 下的离线注册表，一旦注册表配置单元加载失败，它们就会认为目标分区上根本没有合法的 Windows 安装。至于最后那条 `DISM 未识别命令行选项 "/Image:C:\"`（错误 87），后来查 `dism.log` 才发现是我当时在 PE 里手敲命令太急，少敲了一个冒号，实际执行成了 `dism /Image:C\ /Cleanup-Image /RevertPendingActions`，结果让我白白怀疑了一阵子是不是 PE 自带的 DISM 版本有问题。

命令行连续碰壁后，我把目光转向了之前自动修复留下的诊断日志 `C:\Windows\System32\Logfiles\Srt\SrtTrail.txt` 和同目录下的 `DISMRepairLogFile.txt`。打开 `SrtTrail.txt`，里面的记录很有意思：

```cmd
启动修复诊断和修复日志
---------------------------
上一次成功启动的时间: 2026/11/1 9:32:11 (GMT)
尝试修复次数: 64

会话详细信息
---------------------------
系统磁盘 = \Device\Harddisk0
Windows 目录 = C:\Windows
自动检查运行 = 0
根本原因数 = 0
执行的测试:
---------------------------
名称: 检查更新                         结果: 成功完成。错误代码 = 0x0
名称: 系统磁盘测试                     结果: 成功完成。错误代码 = 0x0
名称: 磁盘故障诊断                     结果: 成功完成。错误代码 = 0x0
名称: 磁盘元数据测试                   结果: 成功完成。错误代码 = 0x0
名称: 目标操作系统测试                 结果: 成功完成。错误代码 = 0x0
名称: 卷内容测试                       结果: 成功完成。错误代码 = 0x0
名称: 启动管理器诊断                   结果: 成功完成。错误代码 = 0x0
名称: 系统启动日志诊断                 结果: 成功完成。错误代码 = 0x0
名称: 事件日志诊断                     结果: 成功完成。错误代码 = 0x0
名称: 内部状态检查                     结果: 成功完成。错误代码 = 0x0
名称: 检查已安装的 LCU                 结果: 成功完成。错误代码 = 0x43
```

在随后的两个自动修复会话里，第 2 次会话直接给出了那句经典的废话：“**启动修复已经尝试多次，但仍无法确定问题的原因**”（当时累计尝试修复次数已经高达 64 次）；而第 3 次会话前面十项硬件与引导测试同样全是 `0x0` 通过，唯独死在最后一项：

```cmd
名称: 检查已安装的 LCU
结果: 成功完成。错误代码 = 0x14c
使用的时间 = 1469 毫秒
```

与此同时，我翻到 `DISMRepairLogFile.txt` 的最末尾（`2026-11-02 15:21:12`），看到了这样一段报错：

```cmd
2026-11-02 15:21:08, Info  CBS  Loading offline registry hive: SOFTWARE, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SOFTWARE' from path '\\?\C:\Windows\System32\config\SOFTWARE'.
2026-11-02 15:21:08, Info  CBS  Loading offline registry hive: SYSTEM, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32\config\SYSTEM' from path '\\?\C:\Windows\System32\config\SYSTEM'.
2026-11-02 15:21:12, Info  CBS  Failed to load offline \\?\C:\Windows\System32\config\SYSTEM hive from '\\?\C:\Windows\System32\config\SYSTEM' into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SYSTEM'. [HRESULT = 0xd0000043 - NTSTATUS Error]
2026-11-02 15:21:12, Info  CBS  Failed to load offline SYSTEM hive. [HRESULT = 0xd0000043 - NTSTATUS Error]
```

当时我看到 `检查已安装的 LCU`（Latest Cumulative Update，最新累积更新）报错，再加上末尾这行 `Failed to load offline SYSTEM hive [HRESULT = 0xd0000043]`，立刻得出了一个看似顺理成章的推论，**肯定是 Windows Update 在后台安装累积更新补丁时意外中断，把 `SYSTEM` 注册表配置单元写坏或锁死了！**

顺着这个思路，我先去查看了 `C:\Windows\System32\config` 目录下的文件列表，想看看是不是像网上常见教程说的那样，某个注册表文件变成了 0 字节，或者 `RegBack` 自动备份目录里还有救命稻草：

```cmd
X:\Windows\System32>dir C:\Windows\System32\config
 驱动器 C 中的卷是 OS
 卷的序列号是 7AE9-32CB

 C:\Windows\System32\config 的目录

2026/10/25  11:23    <DIR>          .
2026/11/01  17:32    <DIR>          ..
2026/10/31  21:18         1,310,720 BBI
2026/11/02  14:09            28,672 BCD-Template
2022/06/03  08:32    <DIR>          BFS
2026/10/31  17:30        32,768,000 COMPONENTS
2026/11/01  17:32         6,029,312 DEFAULT
2026/10/31  20:29         8,777,728 DRIVERS
2025/05/10  08:51            32,768 ELAM
2022/05/07  13:24    <DIR>          Journal
2022/05/07  13:24    <DIR>          RegBack
2026/10/31  21:18           131,072 SAM
2026/10/31  21:18            65,536 SECURITY
2026/11/02  13:56       117,440,512 SOFTWARE
2026/11/02  13:56        32,243,712 SYSTEM
2022/05/07  13:24    <DIR>          systemprofile
2025/05/16  17:27    <DIR>          TxR
              10 个文件    198,828,032 字节
               7 个目录 10,064,023,552 可用字节
```

自从 Windows 10 1803 之后，微软為了省磁盘空间默认禁用了 `RegBack` 定期备份，所以 `RegBack` 目录里空空如也。但奇怪的是，`config` 目录下的 10 个注册表文件没有一个是 0 字节：`SYSTEM` 有 32.2 MB，`SOFTWARE` 有 117.4 MB，`SECURITY` 是标准的 64 KB（65,536 字节）。

为了验证是不是 `SYSTEM` 文件损坏，我手工执行了 `reg load` 尝试把它挂载到 PE 的注册表树上：

```cmd
X:\Windows\System32>reg load HKLM\TEMP C:\Windows\System32\config\SYSTEM
操作成功完成。
```

居然直接提示“操作成功完成”！我还顺便打开 `regedit` 看了眼挂载出来的 `HKLM\TEMP\Select`，想试试能不能把当前控制集 `Current`（值为 `1`，对应 `ControlSet001`）切换到备用控制集 `ControlSet002`，结果发现 `ControlSet002` 里面几乎是空的，根本没法切。

既然 `SYSTEM` 能正常挂载，那要是能用 DISM 回滚掉卡在一半的“挂起更新”（Pending Actions），或者把最近安装的累积更新包卸载掉，系统是不是就能活过来了？我赶紧重新敲对了命令，先后执行了 `RevertPendingActions`（回滚挂起操作）和 `Get-Packages`（列出已安装更新包）：

```cmd
X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /RevertPendingActions
部署映像服务和管理工具
版本: 10.0.22621.1

映像版本: 10.0.22631.5768

暂存目录大小可能不足以执行该操作。这可能会引起异常行为。
请使用 /ScratchDir 选项指向具有足够暂存空间的文件夹。推荐大小为至少 1024 MB。
正在从映像中还原挂起的操作...

错误: 0xd000014c

从映像中还原挂起的操作时出错。
有关详细信息，请查看日志文件。

可以在 X:\windows\Logs\DISM\dism.log 上找到 DISM 日志文件

X:\Windows\System32>dism /Image:C:\ /Get-Packages /Format:Table
部署映像服务和管理工具
版本: 10.0.22621.1

映像版本: 10.0.22631.5768

暂存目录大小可能不足以执行该操作。这可能会引起异常行为。
请使用 /ScratchDir 选项指向具有足够暂存空间的文件夹。推荐大小为至少 1024 MB。

错误: 0xd000014c

DISM 失败。不执行任何操作。
```

两条命令全部死在同一个错误码：`0xd000014c`（也就是 `SrtTrail.txt` 第三次会话里报的那个 `0x14c`）。

为了搞清楚 `0xd000014c` 到底卡在哪一步，我打开了刚刚生成的 `X:\windows\Logs\DISM\dism.log`，终于在 `15:38:14` 和 `15:38:52` 的日志段里抓到了真正的罪魁祸首：

```cmd
2026-11-02 15:38:14, Info   CBS  Lazy store initialization mode, fully initialize.
2026-11-02 15:38:14, Info   CBS  Offline image is writable
2026-11-02 15:38:14, Info   CBS  Loading offline registry hive: SOFTWARE, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SOFTWARE' from path '\\?\C:\Windows\System32\config\SOFTWARE'.
2026-11-02 15:38:14, Info   CBS  Loading offline registry hive: SYSTEM, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SYSTEM' from path '\\?\C:\Windows\System32\config\SYSTEM'.
2026-11-02 15:38:14, Info   CBS  Loading offline registry hive: SECURITY, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SECURITY' from path '\\?\C:\Windows\System32\config\SECURITY'.
2026-11-02 15:38:14, Info   CBS  Failed to load offline \\?\C:\Windows\System32\config\SECURITY hive from '\\?\C:\Windows\System32\config\SECURITY' into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SECURITY'. [HRESULT = 0xd000014c - NTSTATUS Error]
2026-11-02 15:38:14, Info   CBS  Failed to load offline registry: {bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SECURITY [HRESULT = 0xd000014c - NTSTATUS Error]
2026-11-02 15:38:14, Info   CBS  Failed to load offline SECURITY hive. [HRESULT = 0xd000014c - NTSTATUS Error]
2026-11-02 15:38:14, Info   CBS  Force unloading offline registry hive: {bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SOFTWARE
2026-11-02 15:38:14, Info   CBS  Force unloading offline registry hive: {bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32\config\SYSTEM
2026-11-02 15:38:14, Error  CBS  Failed to load offline store from boot directory: '\\?\C:\' and windows directory: '\\?\C:\Windows\' [HRESULT = 0xd000014c - NTSTATUS Error]
```

看到这段日志的时候，我同时注意到了另一件要命的事：**我刚插上 U 盘进 PE 接手这台电脑的时候，打开资源管理器一看，150 GB 的 C 盘居然只剩下 100 多 MB 的可用空间！** 我是在清理掉了舍友桌面上几个不重要的大文件之后，才勉强腾出了前面 `chkdsk` 和 `dir` 里看到的那 8.9 GB（约 9 GB）空间。

把“**C 盘原本只剩 100 MB 不到**”和 `dism.log` 里的 `Failed to load offline SECURITY hive [HRESULT = 0xd000014c]` 拼在一起，当时的排查逻辑一下子就闭环了：

1. 根本不是 `SYSTEM` 坏了，而是同目录下的 **`SECURITY` 注册表文件坏了**！CBS 组件存储在初始化离线会话时，必须按顺序依次挂载 `SOFTWARE`、`SYSTEM`、`SECURITY` 三个配置单元；前两个都顺利通过，唯独卡在第三个 `SECURITY` 上抛出 `0xd000014c`（即 NTSTATUS `0xC000014C`，代表注册表损坏），随后把前两个也强制卸载并终止退出。
2. 事故的起因极有可能是 C 盘被塞到只剩 100 多 MB 时，Windows Update 仍在后台强行解压并写入更新权限与安全策略，结果磁盘物理空间彻底耗尽，写操作异常中断，把 `SECURITY` 注册表单元弄成了“截断坏死”的状态。
3. 至于 DISM 提示的“暂存目录大小可能不足，请使用 `/ScratchDir` 选项”，是因为微 PE 运行在内存虚拟盘 `X:` 上，默认暂存目录 `X:\windows\TEMP` 只有几十 MB，跑大型离线操作时必须借用空间充裕的 `D:` 盘做暂存目录。

顺着这个思路，我和豆包制定了一个看似完美的“终极免重装修复方案”：既然 `SYSTEM` 和 `SOFTWARE` 都是好的，只有 `SECURITY` 损坏了，那我先把坏掉的 `SECURITY` 挪到备份文件夹 `CorruptBak` 里，再找一份结构完好的 `SECURITY` 文件替上去，然后加上 `/ScratchDir:D:\backup` 重新跑一次 `RevertPendingActions` 撤销挂起的更新，系统不就能正常开机了吗？

正好我自己的笔记本电脑也在手边，我干脆从我自己的电脑里复制了一份完好的 `SECURITY` 注册表文件（同样是 65,536 字节），拷进舍友电脑的 `C:\Windows\System32\config\SECURITY`，接着在命令行里一气呵成地执行了回滚和清理命令：

```cmd
X:\Windows\System32>md D:\backup
X:\Windows\System32>cd C:\Windows\System32\config
X:\Windows\System32\config>md CorruptBak
X:\Windows\System32\config>move SECURITY CorruptBak\SECURITY
已移动         1 个文件。

:: 此处将我本人电脑上的 SECURITY 文件复制到 C:\Windows\System32\config\SECURITY

X:\Windows\System32\config>dism /Image:C:\ /ScratchDir:D:\backup /Cleanup-Image /RevertPendingActions
部署映像服务和管理工具
版本: 10.0.22621.1

映像版本: 10.0.22631.5768

正在从映像中还原挂起的操作...
操作已完成。重新启动后将尝试还原挂起的操作。
操作成功完成。

X:\Windows\System32>if exist C:\Windows\WinSxS\pending.xml del /f /q C:\Windows\WinSxS\pending.xml
X:\Windows\System32>chkdsk C: /f
```

当屏幕上跳出“**操作已完成。重新启动后将尝试还原挂起的操作。操作成功完成。**”的那一刻，我差点以为大功告成了——毕竟之前无论怎么跑都雷打不动报错 `0xd000014c` 的 DISM，换上我的 `SECURITY` 之后居然真的跑通了！

结果拔掉 U 盘一重启，冷水当头浇下：电脑连转圈界面都没进去，直接又跳回了蓝底白字的 `Recovery` 恢复界面，错误代码依然是 `0xc0000001`。

## Agent 深入排查

换上完好的 `SECURITY`、成功跑通 `RevertPendingActions` 之后还是开不了机，我当时怀疑是不是 C 盘写满到 100 MB 的那次事故还波及了其他组件。我去让 AI 继续判断还有哪些核心组件可能损坏，它给我列了一张表，建议我把 `C:\Windows\System32\config\SAM`（本地账户数据库）和 `COMPONENTS`（组件存储映射树）也从安装镜像或 PE 里提取出来替换掉，再去扫描 `C:\Windows\System32\drivers\*.sys` 里有没有 0 字节的驱动文件，最后用 Windows 11 原版镜像跑一遍 `DISM /RestoreHealth` 重构整个镜像。

这个方案我没敢照做。稍微懂一点 Windows 安全机制就知道，一旦把 `SAM` 换成安装镜像里的空模板，舍友电脑上原有的本地管理员账户、用户 SID 和密码哈希就会被彻底抹平，哪怕侥幸能开机，原来的用户配置目录和个人权限也会废掉。盲目听信通用大模型的猜测去挨个替换系统核心文件，跟直接格盘重装已经没什么区别了。

为了彻底查清到底是哪个字节、哪个组件在阻断开机，我换上了支持联网的 **FirPE** 启动盘，在 PE 环境里联网装好了上 [oh-my-pi](https://github.com/can1357/oh-my-pi)，并把下载好的 Windows 11 23H2 官方原版镜像（`D:\Win11_23H2_Chinese_Simplified_x64v2.iso`）挂载在旁作为参考，让 Agent 直接在 PE 的命令行与脚本环境里对整台机器做一次只读的拉网式取证审计，要求它在动任何文件之前先把证据链和修复清单完整列出来。

### 从日志与转储文件锁定真凶

Agent 接手后没有急着跑修复命令，而是先用脚本把散落在 C 盘各处的底层日志和崩溃转储文件（Minidump）翻了个底朝天。这一查，直接把整起事故从 10 月下旬到 11 月 2 日的真实时间线完整拼了出来。

第一份关键物证藏在 `C:\Windows\Logs\CBS\CBS.log` 里。早在事发前九天的 **2026 年 10 月 23 日晚上 18:36**，Windows 组件服务（CBS）就已经在日志里连着发出了三次 0 字节可用空间的告警：

```cmd
2026-10-23 18:36:21, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:23, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:25, Info  CBS  System volume has 0G free disk space
```

紧接着后面就是一句 `Maint: incomplete, interruptions: 1`（维护未完成，中断次数：1）。也就是说，这块 150 GB 的 C 盘在 10 月底就已经被后台更新和日常缓存顶到了物理极限，连 1 MB 的富余都没剩下。

第二份铁证是 `C:\Windows\Minidump\110226-9312-01.dmp`。之前在 PE 里我们只盯着文本日志看，忽略了这份 6.66 MB 的内核崩溃转储文件。Agent 直接用二进制解析脚本把这份转储文件的头部参数和内嵌字符串扒了出来：

```cmd
signature   = PAGE / DU64
major/minor = 15.22621
bugcheck    = 0x74  (BAD_SYSTEM_CONFIG_INFO)
P1 = 0x2
P2 = 0xffff94869fbd2940
P3 = 0x1
P4 = 0xffffffffc000014c
崩溃时间     = 2026-11-02 07:36:19 UTC（北京时间 15:36:19）
内嵌 ASCII  = "HiveLoadFromomFile" + "status"
内嵌 UTF-16 = "<SECURITY"
```

在 Windows 内核的 `0x74 (BAD_SYSTEM_CONFIG_INFO)` 蓝屏参数中，第 4 个参数 `P4 = 0xffffffffc000014c` 就是最底层的 NTSTATUS 错误码 `0xC000014C`（`STATUS_REGISTRY_CORRUPT`，注册表损坏）；而转储文件里内嵌的内核函数名 `"HiveLoadFromomFile"`（内核拼接字符串时原本就这样多带了一个 `om`）和宽字符字符串 `"<SECURITY"`，更是把死因写在了明面上：**Windows 内核在启动早期调用 `CmpLoadHive` 加载 `SECURITY` 注册表配置单元时，判定该配置单元损坏，当场抛出 `0x74` 蓝屏自杀。**

第三份证据则是对 `C:\Windows\System32\Logfiles\Srt\DISMRepairLogFile.txt` 全文 2,052 行（其中 1,974 行带时间戳）的统计分析。把横跨 11 月 1 日 17:35 到 11 月 2 日 15:21 的全部 13 次离线注册表加载失败记录抽出来后，真相一目了然：

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

前面整整 12 次尝试，跨越近 22 个小时，`SOFTWARE` 和 `SYSTEM` 每次都能顺利加载，无一例外全死在 `SECURITY` 的 `0xd000014c`（即 `0xC000014C` 加上 HRESULT 的客户位 `0x10000000`）上，全文一共留下了 120 处 `0xd000014c`。

那为什么唯独最后一次（`2026-11-02 15:21:12`）变成了 `SYSTEM` 报错 `0xd0000043`，还把我和 AI 都带偏了呢？因为 `0xC0000043` 对应的 NTSTATUS 是 `STATUS_SHARING_VIOLATION`（文件共享冲突）。当时我在 PE 命令提示符里手工执行了 `reg load HKLM\TEMP C:\Windows\System32\config\SYSTEM` 去测试 `SYSTEM` 好坏（或者打开着 DISM++ 挂载了离线注册表），结果测试完忘了执行 `reg unload HKLM\TEMP` 把它卸载掉！文件句柄还被 PE 内核占着，紧接着跑的恢复检查自然就报了共享冲突。这个乌龙说明：**在排查离线系统时，如果不把文件锁导致的 `0xd0000043` 和注册表损坏导致的 `0xd000014c` 区分开，只看日志最后几行就下结论，极容易在错误的方向上白费力气。**

### 为什么更换 SECURITY 还是开不了机

既然从头到尾坏掉的只有 `SECURITY` 这一个文件，那为什么上一节里我把我自己电脑上完好无损的 `SECURITY` 复制过去之后，DISM 明明已经不报错了，电脑重启却还是弹 `0xc0000001` 进不去系统？

Agent 把我拷进去的那份外来 `SECURITY`、舍友本机的 `SAM` 以及 `SYSTEM` 挂载起来做了一次交叉身份比对，答案立刻水落石出：**对于离线工具 DISM 来说，它只关心 `SECURITY` 是不是一个语法合法的注册表文件；但对于正在启动的 Windows 内核与本地安全机构（LSA，`lsass.exe`）来说，这份 `SECURITY` 还必须与本机的机器身份厳格绑定！**

具体来看，我从自己电脑拷过去的那份 `SECURITY` 里记录的机器身份是：

```cmd
PolAcDmN（主域/计算机名） = HXCN-WIN
PolAcDmS（机器域 SID）   = S-1-5-21-1262172508-...
Policy\Secrets（LSA 机密）= NL$KM、M$_MSV1_0_TBAL_PRIMARY_{22BE8E5B-...}、DefaultPassword、MouseWithoutBorders
```

而舍友这台华硕笔记本的 `SYSTEM` 和 `SAM` 注册表里记录的真实本机身份是：

```cmd
ComputerName（计算机名） = LAPTOP-VQSR6OMV
SAM 机器域 SID          = S-1-5-21-4291209427-...
SAM 本地用户账户         = admin (RID 1001) / Administrator (500) / Guest (501) / DefaultAccount (503) / WDAGUtilityAccount (504)
```

这两相对比，问题大得没边了：

1. **域 SID 与计算机名严重冲突**：Windows 启动到安全子系统初始化阶段时，LSA 会同时读取 `SECURITY\Policy\PolAcDmS` 和 `SAM\SAM\Domains\Account` 里的机器域 SID。发现一边是 `1262172508`，另一边是 `4291209427`，两边根本对不上号，LSA 会直接判定安全数据库遭到篡改或不一致，拒绝完成启动并抛出致命错误。
2. **丢失本机 `DPAPI_SYSTEM` 主密钥**：在我拷过去的那份 `SECURITY\Policy\Secrets` 下面，根本没有舍友这台电脑的 `DPAPI_SYSTEM` 机密项，更没有他机器上 SQL Server 2022 的 6 个服务账户机密（`MSSQL$...`）。就算通过某种手段强行跳过 SID 校验进了桌面，舍友电脑上所有用 Windows 数据保护 API（DPAPI）加密保存的数据——包括 Chrome/Edge 浏览器里保存的所有网站密码、Windows 凭据管理器、Wi-Fi 密钥、EFS 加密文件——都会因为丢失本机主密钥而永久无法解密。

换句话说，拿另一台电脑（或者 PE 镜像）里的 `SECURITY` 顶替上去，制造出来的只是一个“骗过了 DISM，但骗不过 Windows 内核”的假修复。想要真正无损救回这台电脑，唯一的出路就是回到我备份在 `C:\Windows\System32\config\CorruptBak\SECURITY` 里的那份**舍友本机原件**，弄清楚它到底坏在了哪里，并把它修好。

### 序列号 17965 和 17964 两字节的脏标志

为了查明 `CorruptBak\SECURITY`（65,536 字节）为什么会被内核和 DISM 判定为 `STATUS_REGISTRY_CORRUPT`，我们需要先了解 Windows 注册表配置单元（`regf` 文件）的底层二进制结构。

每一个注册表 Hive 文件由两部分组成：最开头固定 **4 KB（4,096 字节）的基础块头部（Base Block，以 `"regf"` 签名开头）**，以及后面按 4 KB 对齐排列的数据块区（**hbin bins**，存放实际的键节点 `nk`、值节点 `vk`、子键索引列表 `lh`/`lf`/`li`/`ri` 和安全描述符 `sk`）。在开头的 4 KB 头部中，有几个决定生死的关键偏移字段：

```cmd
偏移 0x000 (4 B) : "regf"                固定签名（0x66676572）
偏移 0x004 (4 B) : PrimarySeq (seq1)     主序列号
偏移 0x008 (4 B) : SecondarySeq (seq2)   次序列号
偏移 0x00C (8 B) : LastWriteTime         根键最后写入时间戳（FILETIME）
偏移 0x01C (4 B) : Type                  配置单元类型（0 为主文件）
偏移 0x024 (4 B) : RootCellOffset        根键 nk 单元在 hbin 区内的偏移（通常为 0x20）
偏移 0x028 (4 B) : HiveBinsDataSize      hbin 数据区总字节数
偏移 0x1FC (4 B) : CheckSum              前 508 字节（0x000..0x1F8 共 127 个 DWORD）的异或校验和
```

头部的校验和（`CheckSum`）算法非常直接：把偏移 `0x000` 到 `0x1F8` 之间共 127 个 32 位无符号整数（DWORD）逐一做按位异或（XOR）；如果异或结果恰好为 `0xFFFFFFFF` 则取 `0xFFFFFFFE`，如果恰好为 `0` 则取 `1`。

那么 `PrimarySeq (seq1)` 和 `SecondarySeq (seq2)` 这两个序列号是干什么用的？它们就是 Windows 注册表的**事务一致性锁（俗称“脏标志”，Dirty Flag）**。当内核准备往注册表 Hive 主文件落盘写入一批更改时，它会遵循一套严格的顺序：

1. 先把头部偏移 `0x004` 的主序列号 `seq1` 加 1，重算头部校验和并写回头部（此时 `seq1 = seq2 + 1`，代表文件处于“正在写入/未完成提交”的**脏状态**）。
2. 将修改后的数据块写入后面的 `hbin` 数据区。
3. 等所有数据块安全落盘后，再把偏移 `0x008` 的次序列号 `seq2` 也加 1，使 `seq1 == seq2`，再次重算头部校验和并写回磁盘，宣告本次事务干净提交。

理解了这个机制，再来看 Agent 对舍友本机原件 `CorruptBak\SECURITY` 以及同目录下两个事务日志文件（`SECURITY.LOG1`、`SECURITY.LOG2`）读出的头部数据，真相瞬间大白：

```cmd
文件                    大小       主序列号 / 次序列号   头部校验和    状态判定
CorruptBak\SECURITY     65,536 B   17965 / 17964       0xb3d51b08   脏（seq1 != seq2，校验和自洽）
SECURITY.LOG1           49,152 B   208 / 208           —            2022 年遗留的陈旧日志
SECURITY.LOG2            8,192 B   17963 / 17963       —            比主文件落后 2 个事务
外来 SECURITY (HXCN-WIN) 65,536 B   210 / 210           0xeb6b4d27   干净，但属于另一台电脑
```

原来，舍友本机的 `CorruptBak\SECURITY` 停在了 **`seq1 = 17965`、`seq2 = 17964`** 的状态！

在正常情况下，如果内核加载一个注册表 Hive 时发现 `seq1 != seq2`（带有脏标志），它不会立刻蓝屏，而是会去找旁边的事务日志文件 `.LOG1` 或 `.LOG2`，试图通过重放日志（Log Replay）把未提交完的事务追平修复。但重放日志有一个硬前提：**日志文件的序列号必须与主文件匹配（即等于 `17964` 或 `17965`）**。而在舍友这台因为 C 盘写满而发生过 I/O 中断的机器上，`SECURITY.LOG1` 居然还停留在 2022 年的序列号 `208`，`SECURITY.LOG2` 则停留在序列号 `17963`（比主文件落后了整整两个事务）。两个日志文件没有一个能接得上 `17965/17964` 的账本！

那 `CorruptBak\SECURITY` 里面的实际数据到底坏没坏？Agent 写了一段专门的二进制结构走查脚本，对这份原件的 `hbin` 数据区做了四层完整性遍历。结果令人惊喜：

- **结构100%完整**：全文件声明的 `hbin` 数据区大小为 `49,152` 字节（文件总长 65,536 字节），所有可达单元的最大末尾偏移落在 `45,056` 字节处，完全在合法边界内，尾部 `12,288` 字节只是未使用的空白区（Slack），**没有任何越界、截断或坏块**。
- **键值节点零错误**：从根键出发递归遍历，共扫出 **166 个键节点（`nk`）和 164 个值节点（`vk`）**。165 个非根键的父指针（`Parent`）100% 准确，33 个子键索引单元（`lh`）与 2 个安全描述符单元（`sk`）全部合法，孤儿键数量为 **0**。
- **本机身份与机密分毫不差**：
  - `Policy\PolAcDmN` = `LAPTOP-VQSR6OMV`（与 `SYSTEM` 的计算机名一致）。
  - `Policy\PolAcDmS` = `S-1-5-21-4291209427-303460211-4247354471`（与 `SAM` 的机器域 SID 完全吻合）。
  - `Policy\Secrets` 下完整保存着全部 **8 条本机核心机密**，包括最关键的 `DPAPI_SYSTEM`、`RasDialParams!S-1-5-21-...-1001#0` 以及 6 个 MSSQL/SQL Server 服务账户密钥。
  - 根键的最后写入时间 `LastWriteTime` 是 `2026-11-01 09:32:10 UTC`（即北京时间 11 月 1 日 17:32:10），与 `SrtTrail.txt` 里记录的“上一次成功启动的时间：`2026/11/1 9:32:11 (GMT)`”严丝合缝，只差 1 秒！

也就是说，在 11 月 1 日 17:32 那次最后成功启动的末尾，内核已经把 `SECURITY` 的数据区完整写完了，仅仅是因为最后一步把 `seq2` 从 `17964` 更新成 `17965` 的操作没能落盘，加上 `.LOG1/.LOG2` 日志链早已断掉，才导致每次开机和运行 DISM 时，内核看到 `17965 != 17964` 且日志无法重放，直接一票否决报 `0xC000014C`！

为了验证这个判断，Agent 在 `D:\_fix\experiments\` 目录下用文件副本搭建了一套受控加载实验矩阵（不动 C 盘一分一毫），编写批处理脚本 `matrix.cmd`、`matrix2.cmd`、`matrix3.cmd` 逐一调用 `reg load` 测试 Windows 内核的真实判定边界：

```cmd
@echo off
chcp 936 >nul
echo == s1: DIRTY (17965/17964), no log files ==
reg load HKLM\KS1 D:\_fix\mx6\s1_dirty_nolog >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KS1 >nul 2>&1)

echo == s2: DIRTY (17965/17964), zero-length LOG1/LOG2 ==
reg load HKLM\KS2 D:\_fix\mx6\s2_dirty_zerolog >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KS2 >nul 2>&1)

echo == s3: DIRTY (17965/17964) + stale LOG1(208)/LOG2(17963) ==
reg load HKLM\KS3 D:\_fix\mx6\s3_dirty_stalelog >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KS3 >nul 2>&1)

echo == s4: CLEAN (17965/17965) but wrong header checksum ==
reg load HKLM\KS4 D:\_fix\mx6\s4_clean_badcsum >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KS4 >nul 2>&1)
```

把全部 8 组关键受控实验的结果汇总起来，内核的加载脾气被摸得一清二楚：

| 实验代号 | Hive 序列号状态 | 头部校验和 (`0x1FC`) | 同目录附带日志 | `reg load` 结果 | 实验结论 |
|---|---|---|---|---|---|
| `s1` / `g` | 脏 `17965 / 17964` | 原值 `0xb3d51b08` | 无任何日志 | **失败 (FAIL)** | 脏标志本身即致命，删掉日志也没用 |
| `s2` | 脏 `17965 / 17964` | 原值 `0xb3d51b08` | 0 字节 `LOG1` / `LOG2` | **失败 (FAIL)** | 空日志无法消除脏标志错误 |
| `s3` / `a` | 脏 `17965 / 17964` | 原值 `0xb3d51b08` | 原始陈旧 `LOG1(208)` + `LOG2(17963)` | **失败 (FAIL)** | 精确复现开机蓝屏与 DISM `0xd000014c` |
| `h` | 脏 `17965 / 17964` | 原值 `0xb3d51b08` | 仅保留 `LOG2(17963)` | **失败 (FAIL)** | 落后 2 个事务的日志不可重放 |
| `t1` | 脏 `17965 / 17963` | 重算正确 | 无日志 | **失败 (FAIL)** | 只要 `seq1 != seq2` 一律拒绝加载 |
| `t2` | 干净 `17964 / 17964` | 重算正确 | 无日志 | **成功 (OK)** | 将 `seq1` 退回 `17964` 可正常挂载 |
| `i` | 干净 `17965 / 17965` | 重算为 `0xb3d51b09` | 无日志 | **成功 (OK)** | **将 `seq2` 追平为 `17965` 并重算校验和即可修复** |
| `j` | 干净 `17965 / 17965` | 重算为 `0xb3d51b09` | 原始陈旧 `LOG1(208)` + `LOG2(17963)` | **成功 (OK)** | 主文件干净时，内核直接忽略旁边的陈旧日志 |
| `s4` | 干净 `17965 / 17965` | 保持旧值未重算 | 无日志 | **失败 (FAIL)** | 改完序列号不重算 `0x1FC` 校验和同样会被拒 |

这组实验把问题彻底简化了：我们根本不需要改动 `SECURITY` 数据区里的任何一个键值，只需要把偏移 `0x008` 处的次序列号从 `17964`（小端序字节 `2c 46 00 00`）改成 `17965`（`2d 46 00 00`），再把偏移 `0x1FC` 处的头部校验和从 `0xb3d51b08` 更新为 `0xb3d51b09`。**前前后后一共只改两个字节**，这份属于舍友本机的 `SECURITY` 就能完美复活。

### 发现了 BBI 和孤儿驱动问题

为了确保重启后万无一失，Agent 没有停留在 `SECURITY` 一个文件上，转而开始对 `C:\Windows\System32\config\` 下的全部九个注册表配置单元、所有启动期内核驱动、存储控制器过滤器以及 CBS 更新挂起项做了一次全盘扫描。这一查，还真又揪出了两个隐藏的独立缺陷。

第一个缺陷是 **`BBI` 注册表配置单元同样带有脏标志，无法加载**。

在对全部九个 Hive 逐一测试加载时，除了 `SECURITY` 之外，`C:\Windows\System32\config\BBI`（大小 `1,310,720` 字节，约 1.25 MB）也报了加载失败。读取它的 `regf` 头部可以看到，它的主次序列号停在 **`53232 / 53231`**（`seq1 != seq2`），而同目录下的 `BBI.LOG1` 和 `BBI.LOG2` 全部是 0 字节，同样无法重放日志。

`BBI` 是 Windows 后台代理基础设施（Background Broker Infrastructure）使用的配置单元，里面存放的是 `WorkItems`（81 条后台任务项）、`PackageImportance`（1,431 条包优先级记录）和 `Events`（136 条事件触发器），总共包含 1,652 个键和 10,129 个值。它在文件修改时间上停留在 10 月 31 日 21:18，说明早在 10 月 31 日那天它就已经变脏了；因为 `BBI` 挂载在应用配置命名空间（`\Registry\A\...`）下，不属于内核启动早期的致命 Hive，所以 11 月 1 日那天电脑还能勉强开机。但既然它是整台机器上唯一另一个因为脏标志而无法加载的注册表文件，修复时自然要顺手用同样的两字节补丁把它一并修好。

第二个缺陷是 **启动期驱动列表里残留了一个指向无效路径的孤儿驱动 `softaal`**。

Agent 编写了 `audit_bootdrv.cmd` 和 `audit_thirdparty.cmd` 脚本，专门遍历 `HKLM\SYSTEM\ControlSet001\Services` 下所有启动类型为 `Start = 0`（`SERVICE_BOOT_START`，由引导加载器 `winload.efi` 加载）和 `Start = 1`（`SERVICE_SYSTEM_START`，由内核初始化阶段加载）的驱动程序，逐一核对它们的 `.sys` 镜像文件在磁盘上是否存在：

```cmd
@echo off
setlocal enabledelayedexpansion
chcp 936 >nul
reg load HKLM\VFSYS C:\Windows\System32\config\SYSTEM >nul 2>&1
if errorlevel 1 (echo SYSTEM LOAD FAIL & exit /b 1)
set MISSING=0
set COUNT=0
for /f "tokens=*" %%K in ('reg query HKLM\VFSYS\ControlSet001\Services 2^>nul') do (
  set "SVC=%%K"
  set "ST="
  for /f "tokens=3" %%V in ('reg query "!SVC!" /v Start 2^>nul ^| findstr /i "REG_DWORD"') do set "ST=%%V"
  if defined ST (
    if "!ST!"=="0x0" call :check "!SVC!"
    if "!ST!"=="0x1" call :check "!SVC!"
  )
)
echo.
echo Boot/System-start drivers checked: !COUNT!   missing image: !MISSING!
reg unload HKLM\VFSYS >nul 2>&1
exit /b 0
```

扫描结果显示，全系统共有 138 个启动期驱动服务（其中 6 个内置虚拟驱动 `wof`、`null`、`npfs`、`msfs`、`cimfs`、`beep` 默认不带 `ImagePath`，与原版镜像基线一致；131 个驱动的 `.sys` 文件完好无损），唯独揪出了 1 个文件缺失的启动驱动 `softaal`：

```cmd
HKLM\SYSTEM\ControlSet001\Services\softaal
  Type         = 0x1 (SERVICE_KERNEL_DRIVER)
  Start        = 0x1 (SERVICE_SYSTEM_START)
  ErrorControl = 0x0 (SERVICE_ERROR_IGNORE)
  ImagePath    = \??\C:\Program Files (x86)\Tencent\QQPCMgr\15.1.22354.301\softaal64_ev.sys
```

去 `C:\Program Files (x86)\Tencent\QQPCMgr\` 目录下一看，舍友电脑上的腾讯电脑管家早就自动升级到了 `15.6.23169.211` 版本，旧版 `15.1.22354.301` 的目录已经被删得一干二净，但注册表里的 `softaal` 内核驱动服务却还指着旧目录的 `softaal64_ev.sys`。所幸它的 `ErrorControl` 设为了 `0`（加载失败时忽略并继续启动），否则单凭这一个路径失效的 `Start=1` 驱动就足够触发 `0x7B (INACCESSIBLE_BOOT_DEVICE)` 蓝屏了。饶是如此，每次开机让内核去抓一个不存在的驱动文件也是隐患，应当将它的 `Start` 改为 `4`（`SERVICE_DISABLED`，禁用）。

除此之外，脚本还顺带扫出了另外 4 个指向缺失文件的非启动期（`Start >= 2`）第三方驱动服务：`ksapi64`（`Start=2`）、华硕外设驱动 `ROGKB`（`Start=3`）与 `ROGMS`（`Start=3`），以及腾讯的 `TSSKX64`（`Start=3`，注册表里写的路径是 `tsskx64_EV.sys`，而 `C:\Windows\System32\drivers\` 下实际存在的文件名叫 `TSSKX64.sys`，连文件名后缀都对不上）。因为它们的启动级别都在 `2` 及以上，不参与内核引导阶段，为了保持最小改动原则，这些留到进系统后再处理即可。

## 解决

### 镜像里那份 SYSTEM 只有 9 MB，为什么还是要用原版镜像

在动手修补之前，得先交代清楚一个很多人都会问的问题：**既然我们手里已经挂载了微软官方的 `Win11_23H2_Chinese_Simplified_x64v2.iso` 原版镜像，为什么不能直接从镜像的 `sources\install.wim` 里提取现成的干净注册表文件，覆盖掉 C 盘上的文件？既然不能覆盖，挂载这个原版镜像又有什么用？**

我们先用 DISM 以只读方式挂载了原版 ISO 里的 `install.wim`（索引 1，家庭中文版，内部版本 `10.0.22631.2861`），把镜像内部 `Windows\System32\config\` 下的初始注册表文件与舍友本机的注册表文件做了一次正面对比：

```cmd
md D:\_fix\mount
dism /Mount-Image /ImageFile:D:\Win11_23H2_Chinese_Simplified_x64v2.iso /Index:1 /MountDir:D:\_fix\mount /ReadOnly
```

这一比对，两边的数据量差距极其悬殊：

| 注册表配置单元 | 原版 ISO 镜像内（通用初始态） | 舍友本机（`LAPTOP-VQSR6OMV`） | 若直接拿镜像文件覆盖本机的后果 |
|---|---|---|---|
| `SYSTEM` | `9,175,040 B`（9.17 MB）/ 661 个服务 / 计算机名 `MINWINPC` | `32,243,712 B`（30.75 MB）/ 846 个服务 / `LAPTOP-VQSR6OMV` | 丢失全部本机硬件驱动服务（含 `iaStorVD` 存储驱动）与 `Enum` 设备树，开机必报 `INACCESSIBLE_BOOT_DEVICE` |
| `SOFTWARE` | `66,584,576 B`（63.5 MB） | `117,440,512 B`（112.0 MB） | 所有已安装软件（MATLAB、SQL Server、Office 等）与系统更新注册信息全部丢失 |
| `SAM` | `8,192 B`（8 KB 空库） | `131,072 B`（128 KB）/ 5 个账户（含 `admin`） | 本机所有用户账户、SID 与登录密码全部清零 |
| `SECURITY` | `8,192 B`（8 KB 空库） | `65,536 B`（64 KB）/ 166 键 164 值 | 机器域 SID 与 LSA 机密（`DPAPI_SYSTEM`）全部丢失，无法通过 LSA 校验且加密数据永久报废 |
| `DEFAULT` | `32,768 B`（32 KB） | `6,029,312 B`（5.75 MB） | 默认用户配置模板丢失 |
| `BBI` | `8,192 B`（8 KB 空队列） | `1,310,720 B`（1.25 MB）/ 1,652 键 | **唯一可以安全借用的文件**（会清空后台作业队列，但头部 GUID 与格式完全一致） |

从这张表就能看明白：安装镜像里的 `config` 目录只是一个还没经历过硬件检测、还没跑过 OOBE（开箱体验初始化）的**通用空壳模板**，里面的计算机名叫 `MINWINPC`，`SAM` 和 `SECURITY` 更是只有 8 KB 的空架子。拿它们去覆盖一台已经用了几年的真实电脑，无异于给病人换脑子。而且，这份 ISO 的版本号是 `22631.2861`，低于舍友电脑已经更新到的 `22631.5768`，所以也没法用它执行保留数据的“就地升级安装（In-place Upgrade）”，安装程序会因为目标系统版本更高而直接拒绝。

那么挂载这份原版镜像真正的价值在哪里？

1. **作为绝对干净的“比对基线（Baseline）”**：当我们不确定本机注册表里的某些现象到底是“系统损坏”还是“Windows 11 本来就这样”时，原版镜像就是最好的标尺。比如前面审计启动驱动时发现 `wof`、`null`、`npfs`、`msfs`、`cimfs`、`beep` 这 6 个核心服务居然没有 `ImagePath` 键值，一开始很容易误判成注册表键值丢失；但去挂载出来的原版镜像 `SYSTEM` 里一查，这 6 个服务在原版镜像里同样没有 `ImagePath`（由内核直接按固定规则加载），当场排除了误判。
2. **提供 `BBI` 的兜底替换件与 `RestoreHealth` 的本地组件源**：镜像里的 `BBI` 虽然只有 8 KB，但它的内部 Hive GUID（`{a2332f2f-cdbf-11ec-8680-002248483d79}`）与本机完全相同；万一本机 `BBI` 数据区真坏了，可以直接拿镜像里的空 `BBI` 救急。同时，如果离线扫描发现系统二进制文件有损坏，挂载出来的 `D:\_fix\mount\Windows\WinSxS` 就是现成的离线修复源。

### 完整备份，然后只改那两个字节

摸清所有底牌后，我们在 11 月 2 日晚上 20:06 正式开始执行修复。所有步骤严格遵循“先全量冷备、再最小化修改、每步做完立刻自检”的顺序。

**第 0 步：全量备份 `config` 目录并做 SHA-256 校验。**

在改动 C 盘任何一个字节之前，先把 `C:\Windows\System32\config\` 下的全部 43 个文件（包含 9 个主 Hive、1 个 `BCD-Template` 以及所有的 `.LOG1`、`.LOG2`、`.TM.blf`、`.regtrans-ms` 事务容器，共计 `249,708,544` 字节 / `238.1 MB`）原封不动地备份到 `D:\_fix\backup_20261102120607\config\`（随后又在 `F:\bakup\_fix\hives\pre_repair_full\` 存了一份），并逐个文件比对 SHA-256 哈希值，确保万一出现意外可以逐字节无损回滚。

**第 1 步：对本机原件 `CorruptBak\SECURITY` 实施两字节修补并写回 `C:\Windows\System32\config\SECURITY`。**

我们读取 `C:\Windows\System32\config\CorruptBak\SECURITY`（65,536 字节，SHA-256 为 `7590396173dc6ff07a847e59c662570edc2757c19e0b6459a8f0b681a55fde67`），只修改头部偏移 `0x008` 和 `0x1FC` 两处：

```cmd
源文件 : C:\Windows\System32\config\CorruptBak\SECURITY (65,536 B, seq 17965 / 17964)
修改 1 : 偏移 0x008 (SecondarySeq)  2c 46 00 00 (17964)  ->  2d 46 00 00 (17965)   [清除脏标志]
修改 2 : 偏移 0x1FC (CheckSum)      08 1b d5 b3          ->  09 1b d5 b3           [重算头部异或校验和 0xb3d51b09]
目标   : C:\Windows\System32\config\SECURITY
```

用 Python 还原这段修补逻辑，核心代码其实只有寥寥十几行：

```python
import struct

with open(r"C:\Windows\System32\config\CorruptBak\SECURITY", "rb") as f:
    buf = bytearray(f.read())

seq1, seq2 = struct.unpack_from("<II", buf, 0x004)
assert seq1 == 17965 and seq2 == 17964

# 1. 将偏移 0x008 的次序列号 seq2 追平为主序列号 seq1 (17965)
struct.pack_into("<I", buf, 0x008, seq1)

# 2. 重新计算 0x000..0x1F8 共 127 个 DWORD 的异或校验和并写入 0x1FC
csum = 0
for offset in range(0, 0x1F8, 4):
    csum ^= struct.unpack_from("<I", buf, offset)[0]
if csum == 0xFFFFFFFF:
    csum = 0xFFFFFFFE
elif csum == 0:
    csum = 1
struct.pack_into("<I", buf, 0x1FC, csum)

with open(r"D:\_fix\stage\SECURITY", "wb") as f:
    f.write(buf)
```

把生成的补丁文件先放在暂存目录 `D:\_fix\stage\SECURITY`，用 `reg load` 挂载自检通过、确认 166 个键和 164 个值与原件逐项一致后，正式覆盖回 `C:\Windows\System32\config\SECURITY`（把之前临时顶替上去的那份 `HXCN-WIN` 外来文件彻底换掉）。

**第 2 步：隔离陈旧的 `SECURITY.LOG1` 与 `SECURITY.LOG2` 事务日志。**

虽然前面的受控实验用例 `j` 已经证明，当 `SECURITY` 主文件处于干净状态（`seq1 == seq2`）时，内核会直接忽略旁边的陈旧日志；但为了彻底消除任何潜在的歧义，我们还是把 `C:\Windows\System32\config\SECURITY.LOG1`（49,152 字节，`seq=208`）和 `SECURITY.LOG2`（8,192 字节，`seq=17963`）移动到了隔离目录 `D:\_fix\quarantine\` 下保存。在随后挂载自检 `SECURITY` 时，内核自动在 `config` 目录下重建了干净的 `SECURITY.LOG1`（36,864 字节）。

**第 3 步：用同样的两字节补丁修复 `BBI` 配置单元。**

读取 `C:\Windows\System32\config\BBI`（1,310,720 字节，`seq 53232 / 53231`），同样将偏移 `0x008` 的 `seq2` 从 `53231` 改为 `53232`，重算偏移 `0x1FC` 的头部校验和并写回。挂载测试一次通过，原有的 81 条 `WorkItems`、1,431 条 `PackageImportance` 和 136 条 `Events` 队列数据完整保留。

**第 4 步：禁用孤儿启动驱动服务 `softaal`。**

挂载 `SYSTEM` 配置单元，将指向已删除腾讯电脑管家旧目录的 `softaal` 驱动从 `Start = 1` 改为 `Start = 4`（禁用），然后干净卸载配置单元：

```cmd
reg load HKLM\VFSYS C:\Windows\System32\config\SYSTEM
reg add "HKLM\VFSYS\ControlSet001\Services\softaal" /v Start /t REG_DWORD /d 4 /f
reg unload HKLM\VFSYS
```

### 清理休眠文件与更新残留

注册表的病根除掉之后，接下来必须解决引发整场灾难的源头也就是 **C 盘空间不足**。如果还让 C 盘停留在只有 8.9 GB 可用空间的状态，开机后 Windows 随便跑个更新或者写点缓存，随时可能再次把磁盘塞爆。

在盘点 C 盘根目录的隐藏大文件时，我们首先盯上了体积高达 **`6,715,396,096` 字节（6.25 GiB）的休眠镜像文件 `C:\hiberfil.sys`**。用脚本读取它的前 4 KB 头部一看，里面全都是 `0x00` 零字节——这意味着休眠文件头部早已被清空失效，Windows 唤醒加载器（`winresume.efi`）不可能从它里面恢复出任何内存状态；而 BCD 引导库里还有 4 个 `resumeobject` 条目指向它，留着它不仅白白占掉 6.25 GiB 空间，还会让引导器在开机时白白尝试一次休眠唤醒。

紧接着，我们运行了 `verify_setup.cmd` 和 `cbs_pending.cmd` 脚本，检查系统是否存在未完成的安装升级事务或挂起的文件重命名操作：

```cmd
@echo off
chcp 936 >nul
echo ==== Setup state ====
reg load HKLM\VFSYS C:\Windows\System32\config\SYSTEM >nul 2>&1
reg query "HKLM\VFSYS\ControlSet001\Control\Session Manager" /v SetupType
reg query "HKLM\VFSYS\ControlSet001\Control\Session Manager" /v SystemSetupInProgress
reg query "HKLM\VFSYS\ControlSet001\Control\Session Manager" /v PendingFileRenameOperations
reg query "HKLM\VFSYS\ControlSet001\Control\Session Manager" /v BootExecute
reg unload HKLM\VFSYS >nul 2>&1
```

查询结果确认：`SetupType = 0`、`SystemSetupInProgress = 0`、无 `PendingFileRenameOperations`、`BootExecute = autocheck autochk *`，且 `C:\Windows\WinSxS\pending.xml` 不存在，`COMPONENTS` 下的 `PackagesPending` 与 `RebootPending` 均为空。这说明系统当前没有任何正在半途执行的升级或重置任务。

确认安全后，我们动手清理了 `C:\hiberfil.sys` 以及四个历史更新与重置留下的孤儿暂存目录：

- 删除 `C:\hiberfil.sys`：立刻释放 **6.25 GiB（6,715 MB）**。
- 删除 `C:\$WinREAgent`（WinRE 更新回滚暂存）：释放 **1,771 MB**。
- 删除 `C:\Windows\SoftwareDistribution\Download`（Windows Update 下载缓存）：释放 **65.5 MB**。
- 删除 `C:\$Windows.~BT`（56.7 MB）与 `C:\$SysReset`（0.3 MB）：释放 **57.0 MB**。
- 卸载之前只读挂载的原版 ISO 映像并清理挂载点：
  ```cmd
  dism /Unmount-Image /MountDir:D:\_fix\mount /Discard
  dism /Cleanup-Mountpoints
  ```

这一轮清理做完，150 GB 的 C 盘可用空间直接从 **8.9 GB 暴涨到了 16.5 GB**（已用空间从 135.2 GB 降到 127.6 GB），系统盘终于有了充足的呼吸空间。

### 修复后全量复查

所有修复操作落地后，我们没有急着立刻重启，而是编写并运行了 `verify_final.cmd`、`id_check.cmd`、`final_check.cmd` 等一整套复查脚本，对整台机器做了一次严格的闭环检验。

首先是最硬核的试金石——**重新运行此前连续报错 12 次 `0xd000014c` 的 `DISM /Get-Packages` 与 `/ScanHealth`**：

```cmd
X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /ScanHealth

部署映像服务和管理工具
版本: 10.0.22621.1

映像版本: 10.0.22631.5768

[==========================100.0%==========================]
未检测到组件存储损坏。
操作成功完成。

X:\Windows\System32>dism /Image:C:\ /Get-Packages /Format:Table

部署映像服务和管理工具
版本: 10.0.22621.1

映像版本: 10.0.22631.5768

映像中的程序包:

---------------------------------------------------------------------------------------------------
程序包标识符                                                                 | 状态   | 发行类型        | 安装时间
-----------------------------------------------------------------------------+--------+-----------------+----------------
...
Package_for_RollupFix~31bf3856ad364e35~amd64~~22621.5768.1.15                | 已安装 | Security Update | 2025/8/15 14:10
Package_for_ServicingStack_5690~31bf3856ad364e35~amd64~~22621.5690.1.2       | 已安装 | Update          | 2025/8/15 0:37

操作成功完成。
```

之前一碰就报 `0xd000014c` 的两条 DISM 命令，现在一路绿灯跑完：`ScanHealth` 100% 通过，报“未检测到组件存储损坏”；`Get-Packages` 完整枚举出了全部 **83 个已安装程序包**，状态清一色为“已安装”，0 个挂起（Pending）。因为 DISM 离线会话在底层必须完整走通 `SOFTWARE` → `SYSTEM` → `SECURITY` 的 CBS 存储初始化，这两条命令跑通，就是本机 `SECURITY` 彻底修好的最有力证据。

接着，我们对 `C:\Windows\System32\config\` 下的全部九个注册表配置单元做了一次四层结构走查（头部签名与校验和、`hbin` 链完整性、从根键深度递归遍历父指针与子键表/值表、统计已分配但不可达的孤儿键）：

| 配置单元 (Hive) | 文件大小 (字节) | 主/次序列号 (`seq1/seq2`) | 脏标志 | 头部校验和 | 键总数 (`nk`) | 值总数 (`vk`) | 父指针/子键表/值表/hbin 错误 | 孤儿键 |
|---|---|---|---|---|---|---|---|---|
| `SYSTEM` | 32,243,712 | `395834 / 395834` | 否 | OK | 91,391 | 194,730 | 0 | 0 |
| `SOFTWARE` | 117,440,512 | `937587 / 937587` | 否 | OK | 372,888 | 640,232 | 0 | 0 |
| `SAM` | 131,072 | `3911 / 3911` | 否 | OK | 80 | 100 | 0 | 0 |
| `SECURITY` | 65,536 | `17970 / 17970` | 否 | OK | 166 | 164 | 0 | 0 |
| `DEFAULT` | 6,029,312 | `238433 / 238433` | 否 | OK | 8,201 | 10,937 | 0 | 0 |
| `DRIVERS` | 8,777,728 | `4850 / 4850` | 否 | OK | 36,424 | 52,954 | 0 | 0 |
| `COMPONENTS` | 32,768,000 | `9216 / 9216` | 否 | OK | 61,793 | 197,776 | 0 | 0 |
| `ELAM` | 32,768 | `13 / 13` | 否 | OK | 1 | 0 | 0 | 0 |
| `BBI` | 1,310,720 | `53233 / 53233` | 否 | OK | 1,652 | 10,129 | 0 | 0 |

九个注册表配置单元全部处于干净状态（`seq1 == seq2`），结构错误全部为 0，孤儿键全部为 0。

细心的读者可能会发现一个细节：前面我们给 `SECURITY` 打补丁时序列号明明写的是 `17965 / 17965`，怎么到了复查表里变成了 `17970 / 17970`？这是因为在 Windows 下，哪怕你只是用 `reg load` 和 `reg unload` 做一次纯只读的挂载自检，内核在卸载 Hive 时也会自动把序列号加 1，并在所有键节点（`nk`）的 `AccessBits` 字段置上挂载标记位。我们把 `17970 / 17970` 状态的 `SECURITY` 与 `CorruptBak\SECURITY` 原件做了逐字节比对：全文件 65,536 个字节里只有 182 个字节发生变化（其中 10 个字节在头部序列号与校验和，166 个字节是全部 166 个 `nk` 键节点的 `AccessBits` 从 `0x1/0x0` 变为 `0x3/0x2`，外加根键的 6 个字节易失性子键计数复位），而 **166 个键名、164 个值名与值数据 100% 零差异**。

在扫描 `SYSTEM` 的孤儿键时，还有一个挺有意思的小插曲：脚本在 `SYSTEM` 偏移 `0xd1a718` 处扫到了一个已分配但不可达的 72 字节单元，开头两个字节恰好是 `6e 6b`（即 ASCII 的 `"nk"`），猛一看特别像一个断裂的孤儿键节点。但核对注册表 `nk` 单元的规范结构后发现，一个合法的 `nk` 键节点头部固定字段就有 76 字节（`0x4C`），72 字节根本装不下一个 `nk` 节点——它其实只是一段内容恰好以 `6e 6b` 开头的值数据单元。幸亏多核对了一眼长度下限，才没为了一个根本不存在的“孤儿键”去乱动 `SYSTEM`。

最后，运行 `id_check.cmd` 与 `final_check.cmd` 完成本机身份一致性与引导收尾检查：

```cmd
PolAcDmN（计算机名） : LAPTOP-VQSR6OMV                        （与 SYSTEM\ComputerName 完全一致）
PolAcDmS（机器域 SID）: S-1-5-21-4291209427-303460211-4247354471 （与 SAM 域 SID 完全一致）
ProfileList 用户目录 : S-1-5-21-...-1001 -> C:\Users\admin     （目录存在且与 SAM RID 1001 匹配）
SAM 账户列表         : admin / Administrator / DefaultAccount / Guest / WDAGUtilityAccount
LSA SYSKEY 启动密钥  : TC463EF4966D8796                       （由 Lsa 下 JD、Skew1、GBG、Data 四个键的类名拼出，完好）
启动期驱动检查       : 131 个 Start 0/1 驱动文件 100% 存在       （softaal 已禁用）
存储类过滤器         : partmgr (磁盘 Upper) / volsnap (卷 Upper) / fvevol+iorate+rdyboost (卷 Lower) 均为系统默认
默认引导项 {default} : partition=C: -> \Windows\system32\winload.efi
卷脏标志查询         : fsutil dirty query C: -> 卷 C: 没有损坏
注册表临时挂载残留   : HKLM 下无任何 VFSEC / VFSYS / VFSAM / TEMP 残留挂载项
```

这里顺带提一个冷知识：很多工具去读 `HKLM\SYSTEM\ControlSet001\Control\Lsa` 下面的 `JD`、`Skew1`、`GBG`、`Data` 四个键时，看到它们的默认键值是空的，就以为用来加密 `SAM` 和 `SECURITY` 的 SYSKEY（系统启动密钥）丢了。实际上，Windows 从设计之初就把这四段各 8 个十六进制字符的密钥藏在注册表键的 **Class Name（类名元数据）** 里，而不是键值（Value）里。用脚本读取这四个键的 Class Name，拼出来的 16 字节启动密钥 `TC463EF4966D8796` 完好无损。

## 尾声

### 清理 InFlight，顺利开机

在准备重启前做最后一次磁盘空间盘点时，我们发现，前面清理完 `hiberfil.sys` 和 `$WinREAgent` 之后，C 盘可用空间明明已经涨到了 16.5 GB，怎么跑完几轮 `DISM /ScanHealth` 和 `DISM /Get-Packages` 复查之后，可用空间又掉回了 16.0 GB？

顺着目录体积一查，罪魁祸首全在 `C:\Windows\WinSxS\Temp\InFlight\` 这个目录下：

1. 该目录里原本就常年堆积着 **5,336 个历史残留子目录，白白占用了 1,498.9 MB（约 1.5 GB）空间**，时间戳从 2023 年 10 月 11 日一直跨度到 2026 年 11 月 2 日。这些全都是过去三年里 Windows Update 和 DISM 在做组件事务时创建、事后却没有回收干净的暂存副本。
2. 更离谱的是，光是我们自己在 PE 里为了验证修复效果而跑的那几次只读命令 `DISM /ScanHealth` 和 `DISM /Get-Packages`，居然就在 `WinSxS\Temp\InFlight\` 下新拉出了 **7,334 个临时目录，瞬间又吃掉了 1,393.4 MB（近 1.4 GB）的 C 盘空间**！

也就是说，**在离线环境里用 DISM 排查磁盘写满故障这个动作本身，就会往 C 盘里疯狂倾倒上千兆的临时垃圾**。如果排查完不顺手清理，本来就没剩多少空间的 C 盘立刻又会被填上一大截。我们把本次排查新产生的这 7,334 个目录清单记录归档到 `inflight_mine.txt` 后全部删除，C 盘可用空间重新回到了 **16.5 GB**。同时我们也把全套排查脚本、修复前后的 `SECURITY` 样本以及 238 MB 的完整注册表快照打包备份到了 U 盘的 `F:\bakup\_fix\` 目录下留档。

做完这一切，九个注册表配置单元全部干净可加载，本机 SID 与 `DPAPI_SYSTEM` 机密严丝合缝，组件存储零损坏，引导链完整，没有任何挂起事务。拔掉 U 盘按下电源键重启，熟悉的华硕 Logo 闪过之后，没有再跳出 `BAD_SYSTEM_CONFIG_INFO`，也没有再掉进 `0xc0000001` 的恢复蓝屏。屏幕顺利亮起了 Windows 11 的锁屏壁纸，输入密码进入桌面，舍友的 MATLAB、SQL Server、浏览器密码和桌面文件全部完好如初。

前前后后折腾了大半天，真正修好这个致命蓝屏的核心动作，其实只是改对了 `SECURITY` 注册表头部的两个字节。

### 用注册表把自动更新暂停 1000 周

电脑虽然救回来了，但只要想到这台机器是因为 Windows 11 在后台没完没了地静默下载更新、硬生生把小容量 C 盘撑爆才闹出这一出，我就实在忍不住想骂娘。

这几年微软在 Windows 11 上的工程质量下滑已经到了让人瞠目结舌的地步。每次月度累积更新（Patch Tuesday）打着“修复重要安全漏洞”的旗号强制塞给用户，结果总是按下葫芦浮起瓢，修好一个旧 Bug 的同时顺手引爆三个更要命的新雷。光看最近这一年多微软自己承认的翻车事故，就足够写满一整页耻辱柱：

- **2025 年 8 月更新（`KB5063878` / `KB5063875`）**：一边引起群联（Phison）、英韧（InnoGrit）等主控的 NVMe 固态硬盘在大文件连续写入时直接掉盘消失、甚至损坏分区表，另一边 `KB5063875` 直接把系统内置的“重置此电脑”与恢复功能搞崩，逼得微软紧急下发带外补丁修补。
- **2025 年 10 月更新（`KB5066835`）**：这一个补丁简直是全方位的灾难——它不仅把 `HTTP.sys` 本地环回地址（`localhost` / `127.0.0.1`）搞断导致大批开发者的本地调试服务全部瘫痪、触发资源管理器预览窗格大面积误报安全警告、弄坏智能卡认证，最荒诞的是它居然**把 WinRE 恢复环境里的 USB 键鼠驱动给搞失效了**！这意味着一旦你的电脑因为更新蓝屏掉进了恢复环境，插着的 USB 键盘和鼠标完全动不了，连点一下“高级选项”或者敲命令自救的机会都没有，微软不得不在一周后狼狈不堪地推出紧急带外更新 `KB5070773` 来救火。
- **2026 年 1 月与 2 月更新（`KB5074109` / `KB5077181`）**：开年第一个大补丁 `KB5074109` 直接导致部分电脑开机黑屏并抛出 `UNMOUNTABLE_BOOT_VOLUME` 无法挂载引导卷死循环，顺带把经典版 Outlook 的 POP/PST 邮件文件搞到卡死、让老机器无法正常睡眠和关机；到了 2 月的 `KB5077181`，又接力爆出无限重启循环、登录界面失效、DHCP 自动获取 IP 断网以及 `dxgmms2.sys` 引发的 `KERNEL_SECURITY_CHECK_FAILURE` 蓝屏。

在微软内部裁撤专职 QA 测试团队、越来越依赖自动化遥测和让普通家庭版用户当免费小白鼠的今天，指望 Windows Update 自己保持克制和稳定完全是痴人说梦。对于 C 盘空间本来就不宽裕、或者正在跑关键科研与生产任务的电脑，最稳妥的自保手段就是**直接把 Windows 自动更新彻底按死**。

不过，我不建议使用某些第三方流氓工具去强行暴力删除 Windows Update 系统服务或系统组件——那种做法很容易把 CBS 组件存储本身破坏掉，日后你想装个 `.NET` 运行库或者微软商店应用都会报错。最干净、最安全、随时可逆的做法，是通过修改 `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings` 下的注册表项，直接把系统自带的“暂停更新”上限拉长到 **1000 周（直达 2042 年）**。

具体操作非常简单：在桌面上新建一个文本文档（`.txt`），把下面的内容完整复制进去，保存后将文件后缀名从 `.txt` 改为 `.reg`（即命名为 `windows-1000weeks-update-blocker.reg`），然后双击导入注册表即可：

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

导入完成后打开“设置 -> Windows 更新”，你会看到更新已经被稳稳当当地暂停到了 2042 年 9 月，后台再也不会偷偷下载几个 GB 的累积更新包来塞满你的 C 盘了。

如果日后某个时刻你确实需要安装新版本更新，只需要点击设置界面里的“继续更新”，或者同样新建一个 `.txt` 文件并改名为 `windows-1000weeks-update-blocker-recovery.reg`，写入下面这几行双击导入，即可一键清除暂停策略、恢复系统默认状态：

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

这个办法只是让 Windows 自己暂停更新，系统组件一个都没删，比那些直接禁用或删除 Windows Update 服务的工具安全得多，想更新的时候随时能恢复。暂停期间收不到安全补丁，隔几个月可以手动打开更新，挑一个口碑稳定的版本装上，装之前先看一眼 C 盘还剩多少空间。
