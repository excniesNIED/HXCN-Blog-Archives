---
title: 一块 150 GB 的 C 盘写满之后：0x74 BAD_SYSTEM_CONFIG_INFO 抢修实录
pubDatetime: 2026-11-02T00:00:00.000+08:00
slug: win11-bad-system-config-info
tags:
  - Windows 11
  - 注册表
  - 蓝屏
  - WinPE
  - BitLocker
  - AI Agent
category: 踩坑日志
description: Windows 11 蓝屏 0x74 BAD_SYSTEM_CONFIG_INFO 抢修复盘，从 C 盘写满讲起，记录 BitLocker 检查、bcdboot/bootrec/chkdsk/sfc/DISM 常规修复失败、错换 SECURITY 的假修复，到用 Agent 定位注册表脏标志、受控实验、两字节补丁和修复后复查，并附暂停更新 1000 周的注册表。适合遇到注册表损坏蓝屏的 Windows 用户。
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

出事的是舍友的一台华硕笔记本（机器名 `LAPTOP-VQSR6OMV`），出厂预装 Windows 11 家庭中文版，平时跟着系统自动更新一路升到了 23H2（内部版本 `22631.5768`）。这台电脑配了一块 1 TB 的 NVMe 固态硬盘，买来的时候就按老习惯被切成了三个主分区：C 盘只分了可怜的 **150 GB**，剩下的空间被对半切成了两个 **389 GB** 的 D 盘和 E 盘。在这仅有的 150 GB 系统盘里，舍友不仅塞进了日常软件，还装了 MATLAB、SQL Server 2022、Office 2024，甚至还放了一部分 Steam 游戏库。

11 月 1 日傍晚，这台电脑毫无征兆地弹出了蓝屏，终止代码显示为 `BAD_SYSTEM_CONFIG_INFO`。

![蓝屏崩溃界面](bsod-bad-system-config-info.svg)

Windows 蓝屏后会自动重启，重启后接着蓝屏，连续失败几次之后会自动进入“启动修复”。不出意外，修复失败了：

![启动修复失败](startup-repair-failed.svg)

这个界面只给了一个日志路径 `C:\Windows\System32\Logfiles\Srt\SrtTrail.txt`，没写失败原因。正常情况下这时候可以用系统还原退回之前的还原点，但舍友的 C 盘一直很紧张，系统保护没开，一个还原点都没有。

在我接手之前，舍友已经照着豆包的建议，在恢复环境的命令提示符里跑过 `chkdsk` 和 `sfc`，问题依旧。`chkdsk` 检查文件系统和磁盘坏道，`sfc` 检查受保护的系统文件。我当时的想法是：这两样都没查出问题，硬盘本身应该没坏，系统文件大概率也没有大问题，那最可疑的就是引导。

于是我插上 Ventoy 启动盘进了 PE，打开 DISM++ 准备修引导。DISM++ 一打开就弹出“试图加载格式不准确的格式”。我没太在意，直接用 DISM++ 的引导修复重建了一遍启动项，重启后蓝屏确实没了，换成了下面这个恢复界面，错误代码 `0xc0000001`：

![恢复错误界面 0xc0000001](recovery-error-0xc0000001.svg)

`0xc0000001` 对应的是 `STATUS_UNSUCCESSFUL`，意思只是启动过程中某个步骤失败了，不指向任何具体原因。后来回头看，DISM++ 那句报错其实已经是线索：它打开离线系统时要挂载 C 盘里的注册表文件，我猜是其中有一个挂不上才报了格式不对。当时我完全没往这个方向想。

### 关掉 BitLocker

进 PE 之后，我看到 C、D、E 三个分区都显示 BitLocker。这几年的品牌笔记本出厂时大多默认开了“设备加密”，它本质上就是 BitLocker：用户第一次用微软账户登录 Windows，恢复密钥会自动上传到这个账户。以后引导文件或者固件设置发生变化，TPM 校验不通过，开机就会要求输入 48 位的恢复密钥。

需要恢复密钥的时候，一般有两个办法：

1. 用当初登录 Windows 的微软账户，在手机或另一台电脑上打开 <https://account.microsoft.com/devices/recoverykey> 查看；
2. 如果分区现在还能正常读取，在 PE 或者系统里用 `manage-bde` 把密钥导出来，输出里“数字密码”下面那串 48 位数字就是恢复密钥：

```cmd
manage-bde -protectors -get C:
manage-bde -protectors -get C: > D:\BitLocker-C.txt
```

舍友装系统时用的是本地账户，从来没登过微软账户，第一条路走不通。我最担心的是后面要改引导、动注册表，TPM 一旦判断环境变了把盘锁上，到时候找不到密钥，数据就真的拿不回来了。所以动手之前先查状态：

```cmd
X:\Windows\System32>manage-bde -status C:
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

“保护关闭”加“已解锁”说明现在 PE 可以直接读写 C 盘。“密钥保护器：找不到”说明这块盘从来没有生成过 TPM 保护器或者恢复密码，也就没有密钥可以导出。这反而是好消息，设备加密停在了“预备”状态，从来没有真正生效，后来 Agent 读卷头也确认 C 盘是普通的 NTFS。

接着用 `diskpart` 看一眼整块硬盘的分区，确认每个分区是做什么的，后面修引导要用到 EFI 分区：

```cmd
X:\Windows\System32>diskpart

DISKPART> list disk
DISKPART> select disk 0
DISKPART> list partition
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

DISKPART> exit
```

`list disk` 列出物理硬盘，`select disk 0` 选中这块 1 TB 的固态，`list partition` 看它的分区表，`list vol` 看每个卷的盘符、文件系统和大小。这里 260 MB、FAT32、已隐藏的 `SYSTEM` 就是 EFI 系统分区（ESP），UEFI 固件开机时从这里读启动管理器；950 MB 的 `RECOVERY` 放的是 Windows 恢复环境（WinRE）；`RESTORE` 和 `MYASUS` 是华硕自己的出厂恢复和工具分区；`F:` 是我的 Ventoy 启动盘。

虽然现在没有加密，保险起见我还是对三个数据分区都执行了关闭 BitLocker：

```cmd
manage-bde -off C:
manage-bde -off D:
manage-bde -off E:
manage-bde -status C:
```

`manage-bde -off` 会把卷完全解密并删除所有密钥保护器，解密在后台进行，期间可以正常读写，但不要强制断电。用 `manage-bde -status` 看“转换状态”显示“完全解密”就可以放心往下做了。

### 常规手段尝试

既然怀疑引导坏了，第一步就是重建 UEFI 引导。先给 ESP 分配一个盘符，再用 `bcdboot` 把 C 盘系统里的启动文件重新拷进去：

```cmd
DISKPART> select volume 4
DISKPART> assign letter=S
DISKPART> exit

X:\Windows\System32>bcdboot C:\Windows /s S: /f UEFI /l zh-cn
已成功创建启动文件。

X:\Windows\System32>dir S:\EFI\Boot
 S:\EFI\Boot 的目录

2025/08/15  08:38         1,698,760 bootx64.efi
               1 个文件      1,698,760 字节

X:\Windows\System32>copy S:\EFI\Microsoft\Boot\bootmgfw.efi S:\EFI\Boot\bootx64.efi
覆盖 S:\EFI\Boot\bootx64.efi 吗? (Yes/No/All): y
已复制         1 个文件。
```

`bcdboot C:\Windows` 表示以 C 盘的 Windows 为源，`/s S:` 指定写到 ESP，`/f UEFI` 只生成 UEFI 启动文件，`/l zh-cn` 设置启动菜单语言。它会重写 `S:\EFI\Microsoft\Boot` 下的启动管理器和 BCD 启动配置。后面那条 `copy` 是双保险：`\EFI\Boot\bootx64.efi` 是 UEFI 的默认回退路径，主板里的启动项丢了时固件会去找它，我把它换成和 Windows 启动管理器完全一样的文件。

然后用 `bootrec` 再扫一遍：

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

`/scanos` 扫描所有磁盘上的 Windows 安装，`/rebuildbcd` 扫描后把找到的系统加进 BCD，`/fixboot` 往系统分区写新的引导扇区。C 盘明明有一个完整的 Windows，两次扫描结果都是 0；`/fixboot` 直接拒绝访问。`/fixboot` 在 UEFI 机器上报拒绝访问很常见，它本来就是 MBR 时代的工具，有 `bcdboot` 就够了。扫描结果为 0 比较奇怪，我当时猜是 `bootrec` 判断“这是不是一个能用的 Windows”时读了离线系统里的什么东西没读出来，但手上没有证据，只能先放着。

接下来查磁盘和系统文件。我在 PE 里又跑了一遍完整的 `chkdsk`：

```cmd
X:\Windows\System32>chkdsk C: /f /r
...
阶段 4: 在用户文件数据中查找损坏的群集...
  已处理 1327856 个文件。
文件数据验证完成。

阶段 5: 查找损坏的空闲群集...
  已处理 3994784 个可用簇。
已完成可用空间验证。

Windows 已扫描文件系统并且没有发现问题。
无需采取进一步操作。

总共有  157286727 KB 磁盘空间。
坏扇区           0 KB。
```

`/f` 修复文件系统错误，`/r` 在此基础上逐个读一遍已用和空闲的簇，找坏扇区。五个阶段全部通过，坏扇区 0 KB，说明 NTFS 结构和固态本身都没问题。

离线 `sfc` 和 `dism` 就没这么顺利了：

```cmd
X:\Windows\System32>sfc /scannow /offbootdir=C:\ /offwindir=C:\Windows
正在开始系统扫描。此过程将需要一些时间。

正在开始验证 Windows 资源保护完整性。
Windows 资源保护无法执行请求的操作。

X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /RestoreHealth
错误: 87

DISM 未识别命令行选项 "/Image:C:\"。
```

`sfc` 的 `/offbootdir` 和 `/offwindir` 告诉它要检查的是 C 盘上的离线系统。它直接报“无法执行请求的操作”，连扫描都没开始。`dism` 的错误 87 是参数错误，我重新敲了一遍就能识别了。PE 里手敲命令很容易出这种问题，后来翻 `dism.log` 还看到我另一次把 `/Image:C:\` 漏成了 `/Image:C\`，DISM 把它当成了 `X:\Windows\System32\C\` 这个不存在的目录。

引导、磁盘都排除了，只能去翻日志。启动修复的日志 `SrtTrail.txt` 开头是这样的：

```cmd
启动修复诊断和修复日志
---------------------------
上一次成功启动的时间: 2026/11/1 9:32:11 (GMT)
尝试修复次数: 64
```

“上一次成功启动”是格林尼治时间，换算成北京时间是 11 月 1 日 17:32；“尝试修复次数 64”说明启动修复已经自己跑了 64 次。每次会话都会依次跑十来个测试项，检查更新、系统磁盘、磁盘元数据、目标操作系统、卷内容、启动管理器、启动日志、事件日志，结果全是 `0x0`，只有最后一项不一样：

```cmd
会话 1   名称: 检查已安装的 LCU   结果: 成功完成。错误代码 = 0x43
会话 2   根本原因数 = 1
         找到的根本原因:
         启动修复已经尝试多次，但仍无法确定问题的原因。
会话 3   名称: 检查已安装的 LCU   结果: 成功完成。错误代码 = 0x14c
```

LCU 是 Latest Cumulative Update，最新累积更新。同目录下还有一份 `DISMRepairLogFile.txt`，是启动修复调用 DISM 时写的，末尾是这几行：

```cmd
2026-11-02 15:21:12, Info   CBS  Failed to load offline \\?\C:\Windows\System32\config\SYSTEM hive ... [HRESULT = 0xd0000043 - NTSTATUS Error]
2026-11-02 15:21:12, Info   CBS  Failed to load offline SYSTEM hive. [HRESULT = 0xd0000043 - NTSTATUS Error]
2026-11-02 15:21:12, Error  CBS  Failed to load offline store from boot directory: '\\?\C:\' and windows directory: '\\?\C:\Windows\' [HRESULT = 0xd0000043 - NTSTATUS Error]
```

我把这两份日志和截图一起丢给 AI 聊天助手。它的判断是：Windows Update 装累积更新时意外中断，`SYSTEM` 注册表被写了一半，导致蓝屏。顺着这个思路，它给了三条路：回滚挂起的更新、找出最近装的更新包卸载、切换到备用的 ControlSet。

先回滚挂起的更新：

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
```

`/RevertPendingActions` 会撤销所有还没装完、等待重启的更新操作，是更新装坏以后最常用的补救命令。它失败了。再列出已安装的更新包，准备手动卸载最近的累积更新：

```cmd
X:\Windows\System32>dism /Image:C:\ /Get-Packages /Format:Table
...
错误: 0xd000014c

DISM 失败。不执行任何操作。
```

连包列表都列不出来，卸载更新包也就无从谈起。`0xd000014c` 是 NTSTATUS `0xC000014C` 被 DISM 包了一层，`0xC000014C` 的含义是 `STATUS_REGISTRY_CORRUPT`，注册表损坏。

切换 ControlSet 的思路是：`SYSTEM` 注册表里通常有两套控制集，`ControlSet001` 和 `ControlSet002`，`Select` 键记录当前用哪一套，可以手动改成另一套试试。我在 PE 里挂载了 C 盘的 `SYSTEM`：

```cmd
X:\Windows\System32>reg load HKLM\TEMP C:\Windows\System32\config\SYSTEM
操作成功完成。
```

`SYSTEM` 能正常挂载。`Select\Current` 是 1，当前用的就是 `ControlSet001`；而 `ControlSet002` 几乎是空的，下面只有一个服务项，根本不是一套能用的备份。这条路也走不通。

这里我还埋了一个坑：挂载完 `SYSTEM` 没有执行 `reg unload HKLM\TEMP`，DISM++ 也一直开着。前面 `DISMRepairLogFile.txt` 里那条 `0xd0000043` 是 `STATUS_SHARING_VIOLATION`，共享冲突，意思是这个文件正被别的程序占用，跟文件损不损坏没有关系。占用的来源我没完全确认，最可能就是我自己挂载过没卸载，或者 DISM++ 还占着。后来翻完整份日志，`SYSTEM` 报错只有这一次，前面十几次 `SYSTEM` 都加载成功了。AI 拿这一条推断“`SYSTEM` 坏了”，方向从一开始就偏了。

`dir` 一下 `config` 目录，看看注册表文件有没有变成 0 字节，这是网上教程里最常见的损坏形态：

```cmd
X:\Windows\System32>dir C:\Windows\System32\config
 驱动器 C 中的卷是 OS
 卷的序列号是 7AE9-32CB

 C:\Windows\System32\config 的目录

2026/10/31  21:18         1,310,720 BBI
2026/11/02  14:09            28,672 BCD-Template
2026/10/31  17:30        32,768,000 COMPONENTS
2026/11/01  17:32         6,029,312 DEFAULT
2026/10/31  20:29         8,777,728 DRIVERS
2025/05/10  08:51            32,768 ELAM
2026/10/31  21:18           131,072 SAM
2026/10/31  21:18            65,536 SECURITY
2026/11/02  13:56       117,440,512 SOFTWARE
2026/11/02  13:56        32,243,712 SYSTEM
              10 个文件    198,828,032 字节
               7 个目录 10,064,023,552 可用字节
```

没有一个是 0 字节，`SECURITY` 是 64 KB，也是正常大小。

就在这时我才反应过来，DISM 两次都在提醒暂存空间不足，而这块 C 盘的空间一直有问题。我接手的时候 C 盘只剩 100 多 MB，当时顺手删了桌面上几个不重要的大文件，剩下八九个 GB，就没再管。上面 `dir` 最后一行的 `10,064,023,552 可用字节` 就是清理之后的结果。

再去翻 PE 自己的 DISM 日志 `X:\windows\Logs\DISM\dism.log`，刚才那次 `RevertPendingActions` 写得很清楚：

```cmd
2026-11-02 15:38:14, Info   CBS  Loading offline registry hive: SOFTWARE, into registry key '{bf1a281b-...}C:/Windows/System32/config/SOFTWARE' ...
2026-11-02 15:38:14, Info   CBS  Loading offline registry hive: SYSTEM, into registry key '{bf1a281b-...}C:/Windows/System32/config/SYSTEM' ...
2026-11-02 15:38:14, Info   CBS  Loading offline registry hive: SECURITY, into registry key '{bf1a281b-...}C:/Windows/System32/config/SECURITY' ...
2026-11-02 15:38:14, Info   CBS  Failed to load offline \\?\C:\Windows\System32\config\SECURITY hive ... [HRESULT = 0xd000014c - NTSTATUS Error]
2026-11-02 15:38:14, Info   CBS  Failed to load offline SECURITY hive. [HRESULT = 0xd000014c - NTSTATUS Error]
2026-11-02 15:38:14, Error  CBS  Failed to load offline store from boot directory: '\\?\C:\' and windows directory: '\\?\C:\Windows\' [HRESULT = 0xd000014c - NTSTATUS Error]
```

DISM 处理离线系统前，要依次挂载 C 盘的 `SOFTWARE`、`SYSTEM`、`SECURITY` 三个注册表文件。前两个都成功了，卡在第三个 `SECURITY` 上。坏的根本不是 `SYSTEM`。

把磁盘空间和这条日志放在一起，我的猜测是：C 盘被挤到只剩 100 多 MB 时，Windows Update 还在后台解压、写入更新，写到 `SECURITY` 的时候空间耗尽，文件被写坏，然后引发了后面一连串的蓝屏和修复失败。

既然只坏了 `SECURITY`，那换一个好的 `SECURITY` 进去是不是就行了？我先把原来的文件挪到 `CorruptBak` 目录留底，然后从我自己的电脑上拷了一份 `SECURITY` 放进 C 盘的 `config` 目录：

```cmd
X:\Windows\System32>md D:\backup
X:\Windows\System32>cd C:\Windows\System32\config
X:\Windows\System32\config>md CorruptBak
X:\Windows\System32\config>move SECURITY CorruptBak\SECURITY
已移动        1 个文件。
```

换好之后再跑一遍回滚，这次用 `/ScratchDir` 把暂存目录指到空间充足的 D 盘，避开 PE 内存盘只有几十 MB 的问题：

```cmd
X:\Windows\System32\config>dism /Image:C:\ /ScratchDir:D:\backup /Cleanup-Image /RevertPendingActions
部署映像服务和管理工具
版本: 10.0.22621.1

映像版本: 10.0.22631.5768

正在从映像中还原挂起的操作...
操作已完成。重新启动后将尝试还原挂起的操作。
操作成功完成。

X:\Windows\System32>if exist C:\Windows\WinSxS\pending.xml del /f /q C:\Windows\WinSxS\pending.xml

X:\Windows\System32>chkdsk C: /f
...
Windows 已扫描文件系统并且没有发现问题。
无需采取进一步操作。
```

之前稳定报 `0xd000014c` 的命令，第一次显示“操作成功完成”。我顺手删了记录待处理更新的 `WinSxS\pending.xml`，又跑了一遍 `chkdsk`，满怀期待地重启。

还是那个 `0xc0000001`。

## Agent 深入排查

`SECURITY` 换了，DISM 也通了，系统还是起不来。我回去问 AI 还有哪些组件可能坏了，它列了一张表：`SAM`、`COMPONENTS`、`SYSTEM` 内部逻辑损坏、0 字节的驱动文件。建议是把 PE 里的 `SAM` 直接拷到 C 盘，再从安装镜像里提取 `COMPONENTS` 覆盖，最后用镜像跑一遍 `RestoreHealth`。

这个方案我没敢照做。`SAM` 存的是这台电脑的本地账户和密码，PE 里那份 `SAM` 是 PE 自己的，拷过去等于把舍友的账户全删了；`COMPONENTS` 记录的是这台机器装过的所有组件和更新，拿安装镜像里那份覆盖，系统的更新记录就对不上了。每一步都不可逆，而且我已经被“换个好文件”坑过一次。

我决定换个办法。重新做了一个带网络的 FirPE 启动盘，进 PE 后联网装上 [oh-my-pi](https://github.com/can1357/oh-my-pi)，让 AI Agent 直接在这台电脑上读文件、跑命令。我给它的要求是：先做只读审计，所有实验都在 D 盘的副本上做，写一份修复清单给我看，我批准之前不准往 C 盘写任何东西。

Agent 能做的事比聊天 AI 多得多。它可以逐字节读注册表文件，可以写脚本批量挂载、比对、统计，还可以把 Windows 安装镜像解开当作参照。后面这些排查用到的批处理脚本，最后都整理进了 `_fix\scripts` 目录，方便以后复盘。

### 翻日志：十天前 C 盘就写满过

Agent 第一件事是把 C 盘上所有相关日志都翻了一遍。在 Windows 更新引擎的日志 `C:\Windows\Logs\CBS\CBS.log` 里，它找到了这三行：

```cmd
2026-10-23 18:36:21, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:23, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:25, Info  CBS  System volume has 0G free disk space
```

CBS 是 Component Based Servicing，Windows 安装更新、启用功能都靠它。10 月 23 日傍晚，它连续三次记录系统盘剩余 0 GB，后面紧跟一句 `Maint: incomplete, interruptions: 1`，说明当时的维护任务没做完就被打断了。也就是说，C 盘在出事前八九天就已经被彻底写满过一次。舍友后来清了点空间继续用，这几天电脑一切正常，直到 11 月 1 日。

接下来是崩溃转储。C 盘的 `Minidump` 目录里只留下一份 `110226-9312-01.dmp`，Agent 直接读了它的文件头：

```cmd
signature   = PAGE / DU64
major/minor = 15.22621
bugcheck    = 0x74  (BAD_SYSTEM_CONFIG_INFO)
P1 = 0x2
P2 = 0xffff94869fbd2940
P3 = 0x1
P4 = 0xffffffffc000014c
崩溃时间     = 2026-11-02 07:36:19 UTC（北京时间 15:36）
内嵌 ASCII  = "HiveLoadFromomFile" + "status"
内嵌 UTF-16 = "<SECURITY"
```

`0x74` 就是蓝屏上的 `BAD_SYSTEM_CONFIG_INFO`，表示注册表出了问题。第四个参数 P4 是 `0xC000014C`，和 DISM 报的是同一个错误：注册表损坏。转储里还残留着内核在出事时用到的字符串，一个是加载注册表文件的函数名，一个是 `SECURITY`。`HiveLoadFromomFile` 中间重复的 `om` 不是我抄错，转储里原样就是这样。P1 的含义我查到的资料说法不一，看 P4 和这两段字符串就足够了：**内核开机时加载 `SECURITY` 注册表，发现它损坏，直接蓝屏。**

DISM 的修复日志 `DISMRepairLogFile.txt` 一共 2052 行，其中 1974 行带时间戳，从 11 月 1 日 17:35 一直记到 11 月 2 日 15:21。Agent 把所有加载失败的记录抽了出来：

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

12 次 `SECURITY` 加载失败，全是 `0xd000014c`，从上一次成功启动三分钟后就开始了，前后跨了将近 22 个小时。唯一一次 `SYSTEM` 报错就是我自己挂载没卸载造成的那次共享冲突。我交给 AI 的恰好是最后那一段日志，看到的又恰好是这唯一的例外。

这也解释了为什么前面所有工具都报同一个错。DISM、`sfc`、启动修复里的“检查已安装的 LCU”，处理离线系统之前都要先挂载这三个注册表文件，挂载失败，后面什么都做不了。

### 换上去的 SECURITY 不属于这台电脑

那为什么换上我电脑的 `SECURITY` 之后，DISM 能通过，系统还是开不了机？

`SECURITY` 注册表存的是本地安全机构（LSA）的数据：这台电脑的计算机名和机器 SID、本地安全策略，以及一组叫 LSA Secrets 的机密。机器 SID 是 Windows 安装时随机生成的一串编号，每个本地账户的 SID 都以它为前缀；LSA Secrets 里最重要的是 `DPAPI_SYSTEM`，Windows 用它保护浏览器保存的密码、凭据管理器里的凭据、EFS 加密文件的证书。另一个注册表 `SAM` 存的是本地账户，它记录的机器 SID 必须和 `SECURITY` 里的一致。

Agent 把 C 盘上那份 `SECURITY` 读了出来：

```cmd
计算机名   HXCN-WIN
机器 SID   S-1-5-21-1262172508-...
```

再看舍友本机的 `SAM` 和 `SYSTEM`：

```cmd
计算机名   LAPTOP-VQSR6OMV
机器 SID   S-1-5-21-4291209427-...
```

`HXCN-WIN` 是我自己的电脑。`SECURITY` 里记录计算机名的 `PolAcDmN` 对不上 `SYSTEM` 里的 `ComputerName`，记录机器 SID 的 `PolAcDmS` 对不上 `SAM` 的域 SID。机密列表里装的是 `NL$KM`、`DefaultPassword`、`MouseWithoutBorders` 这些我电脑上的东西，没有舍友这台机器的 `DPAPI_SYSTEM`。

DISM 只关心注册表文件能不能挂载，文件格式是对的它就能继续往下走，所以“修好了”。但 Windows 开机时，LSA 初始化会核对 `SECURITY` 和 `SAM` 是不是同一台机器的，两边 SID 对不上，大概率直接拒绝启动。就算侥幸进了系统，舍友所有用 DPAPI 加密过的数据都解不开了，因为解密要用的主密钥只存在于他自己那份 `SECURITY` 里。

那份真正属于这台电脑的 `SECURITY`，一直躺在我前面挪出去的 `CorruptBak\SECURITY` 里，64 KB，修改时间是 10 月 31 日 21:18。问题就变成了：它到底坏在哪？

### 序列号 17965 和 17964 两字节的脏标志

Windows 的每个注册表配置单元（hive）都是一个独立的二进制文件，前 4 KB 是文件头，后面是一块块 4 KB 对齐的数据块（hbin），所有的键和值都存在数据块里。文件头里和这次故障有关的字段是这几个：

```cmd
偏移 0x000   "regf"     文件签名
偏移 0x004   seq1       主序列号
偏移 0x008   seq2       次序列号
偏移 0x00C   lastWrite  最后写入时间
偏移 0x024   root       根键所在单元的偏移
偏移 0x028   hbins      数据块区域总大小
偏移 0x1FC   checksum   文件头校验和
```

内核每次往注册表写数据，会先把主序列号 `seq1` 加 1，写完数据，最后把次序列号 `seq2` 改成和 `seq1` 一样。正常关机后的注册表文件，两个序列号永远相等。如果两者不等，就说明上一次写入没有走完，文件可能处在写到一半的状态，这就是所谓的“脏标志”。

为了能从这种状态恢复，每个注册表旁边都有 `.LOG1`、`.LOG2` 两个事务日志，记录最近的修改。内核挂载一个脏的注册表时，会去日志里找能接上的记录，把没写完的修改重放进去，补齐之后再用。

校验和的算法很简单：把文件头 `0x000` 到 `0x1F8` 每 4 个字节当成一个整数，全部异或起来；结果是 `0xFFFFFFFF` 时写 `0xFFFFFFFE`，是 `0` 时写 `1`。

Agent 读出来的结果：

```cmd
CorruptBak\SECURITY   65,536 B   seq 17965 / 17964   校验和 0xb3d51b08（与计算值一致）
SECURITY.LOG1         49,152 B   seq 208             （2022 年的旧日志）
SECURITY.LOG2          8,192 B   seq 17963           （比主文件落后两次）
```

主文件是 17965 / 17964，脏了。要把它补齐，需要一份序列号是 17964 或 17965 的日志，而 `LOG1` 还停在 2022 年的 208，`LOG2` 停在 17963，哪一个都接不上。能重放的日志不存在，内核只能把它判定为损坏，这就是 `0xC000014C` 的直接来源。

那数据本身坏了没有？Agent 从根键开始，把整个文件的键、值、子键索引、安全描述符逐层走了一遍：166 个键、164 个值，每个键的父指针都对，没有任何单元指到文件末尾以外，也没有找不到父亲的孤儿键。机器身份也全部对得上：

```cmd
PolAcDmN         LAPTOP-VQSR6OMV                    与 SYSTEM 里的计算机名一致
PolAcDmS         S-1-5-21-4291209427-...            与 SAM 的域 SID 一致
Policy\Secrets   8 条，含 DPAPI_SYSTEM、RasDialParams 和 6 个 SQL Server 服务账户
根键 LastWriteTime  2026-11-01 09:32:10 UTC            比 SrtTrail 记录的上次成功启动早 1 秒
```

数据完好，只是文件头上的脏标志没清掉。最合理的解释是：10 月 23 日那次 C 盘写满，注册表事务和日志的提交出了问题，从那以后日志就再也没跟上主文件；11 月 1 日最后一次写入时，数据落了盘，次序列号没来得及更新。这一段是推断，CBS 的日志只能证明 C 盘满过，没有记录当时具体在写哪个文件。

问题变成：能不能不重放日志，直接清掉脏标志？会不会有别的检查？Agent 在 D 盘上用原件的副本做了一组受控实验，每组用 `reg load` 挂载一次，看能不能成功：

| 用例 | 注册表状态 | 旁边放的日志 | `reg load` |
|---|---|---|---|
| s1 | 原件，脏 17965 / 17964 | 无 | 失败 |
| s2 | 原件，脏 17965 / 17964 | 0 字节的 LOG1 / LOG2 | 失败 |
| s3 | 原件，脏 17965 / 17964 | 原来的旧日志 208 + 17963 | 失败 |
| h | 原件，脏 17965 / 17964 | 只有 LOG2（17963） | 失败 |
| t1 | 仍然脏，seq2 改成 17963，重算校验和 | 无 | 失败 |
| t2 | seq1 改成 17964，和 seq2 相等，重算校验和 | 无 | 成功 |
| i | seq2 改成 17965，和 seq1 相等，重算校验和 | 无 | 成功 |
| j | 同 i | 原来的旧日志 208 + 17963 原样保留 | 成功 |
| s4 | 两个序列号相等，但不重算校验和 | 无 | 失败 |

结论很干净。只要两个序列号不相等，无论日志存不存在、是不是 0 字节，内核都拒绝挂载，脏标志本身就是致命的。只要序列号相等、校验和正确，旁边留着旧日志也不影响，内核不会去重放它们。校验和必须重算，只改序列号会因为文件头校验失败照样挂不上。

所以修复只需要动文件头的两个字段：把 `0x008` 的次序列号从 17964 改成 17965，再把 `0x1FC` 的校验和从 `0xb3d51b08` 重算成 `0xb3d51b09`。整个 64 KB 的文件只变了 2 个字节。

### 发现了 BBI 和孤儿驱动问题

只修 `SECURITY` 还不够放心。Agent 把 `config` 目录下九个注册表文件逐个挂载测试，又发现了一个不能加载的：`BBI`。

`BBI` 大小 1,310,720 字节，序列号 53232 / 53231，同样是脏的，旁边的 `LOG1`、`LOG2` 都是 0 字节。它不是开机必需的注册表，里面装的是后台任务和应用包的队列：81 条 `WorkItems`、1431 条 `PackageImportance`、136 条 `Events`。它的修改时间停在 10 月 31 日，可 11 月 1 日电脑照样能开机，说明它坏了不会蓝屏。不过它是九个里唯一另一个结构上挂不上的，放着迟早是隐患，用同样的方法清掉脏标志就行。

接着 Agent 查了开机时加载的驱动。Windows 每个驱动在 `HKLM\SYSTEM\ControlSet001\Services` 下有一个键，`Start` 值决定它什么时候加载：0 是引导阶段，1 是内核初始化阶段，2 是系统启动后自动加载，3 是按需手动加载，4 是禁用。0 和 1 这两类如果文件找不到，轻则拖慢开机，重则直接起不来。`ErrorControl` 决定加载失败怎么处理，0 是忽略，1 是记一条日志继续启动，再往上就会触发回退甚至蓝屏。

脚本 `audit_bootdrv.cmd` 把 C 盘 `SYSTEM` 里 `Start` 为 0 或 1 的驱动全部列出来，逐个检查驱动文件在不在。138 个驱动里，131 个文件都在；`wof`、`null`、`npfs`、`msfs`、`cimfs`、`beep` 这 6 个没有写文件路径，和安装镜像里的完全一样，是正常现象；剩下一个真有问题：

```cmd
HKLM\SYSTEM\ControlSet001\Services\softaal
  ImagePath    = \??\C:\Program Files (x86)\Tencent\QQPCMgr\15.1.22354.301\softaal64_ev.sys
  Start        = 1
  ErrorControl = 0
```

`softaal` 是腾讯电脑管家的驱动。电脑管家已经升级到 15.6.23169.211，15.1 的旧目录早就没了，这个驱动还指着旧路径。`ErrorControl` 是 0，加载失败会被忽略，所以它不是这次蓝屏的原因，但每次开机都会白找一次，把 `Start` 改成 4 禁用掉。

另外还有四个驱动指向不存在的文件：`ksapi64`（Start=2）、华硕的 `ROGKB` 和 `ROGMS`（Start=3）、腾讯的 `TSSKX64`（Start=3）。`TSSKX64` 在注册表里写的文件名是 `tsskx64_EV.sys`，磁盘上只有一个 `TSSKX64.sys`，像是安装程序留下的半成品。它们都在系统启动后才加载，不影响开机，这次没动。那个几乎为空的 `ControlSet002` 里唯一的服务 `kisknl` 对应的驱动文件也不存在，但 `ControlSet002` 当前不生效，同样不影响。

## 解决

### 镜像里的 SYSTEM 只有 9 MB，为什么还要用镜像

我手上有一份 `Win11_23H2_Chinese_Simplified_x64v2.iso`，版本 22631.2861。一开始我想当然地觉得，直接从镜像里取一份干净的 hive 覆盖不就完了。试过之后发现这条路走不通，而且走通了反而会闯祸。所以 Agent 先把镜像解开，看看里面的注册表到底长什么样：

```cmd
7z e -y -oD:\_fix\wim D:\Win11_23H2_Chinese_Simplified_x64v2.iso sources\install.wim
md D:\_fix\mount
dism /Mount-Image /ImageFile:D:\_fix\wim\install.wim /Index:1 /MountDir:D:\_fix\mount /ReadOnly
```

第一条用 7-Zip 从 ISO 里取出系统映像 `install.wim`；第二条以只读方式把第 1 个版本（家庭中文版）挂载到 `D:\_fix\mount`，挂载后可以像普通文件夹一样浏览，但不会改动镜像本身。镜像里 `Windows\System32\config` 下的注册表和舍友本机的对比如下：

| 注册表 | 镜像里 | 舍友本机 | 用镜像覆盖的后果 |
|---|---|---|---|
| SYSTEM | 9,175,040 B，661 个服务，计算机名 `MINWINPC` | 32,243,712 B，846 个服务，`LAPTOP-VQSR6OMV` | 所有硬件驱动配置和设备记录丢失，开机报 INACCESSIBLE_BOOT_DEVICE |
| SAM | 8,192 B，空库 | 131,072 B，5 个账户 | 账户全部丢失 |
| SECURITY | 8,192 B，空 | 65,536 B | LSA 机密全丢，DPAPI 加密的数据永久打不开 |
| SOFTWARE | 66,584,576 B | 117,440,512 B | 所有已装软件的注册信息丢失 |
| DEFAULT | 32,768 B | 6,029,312 B | 新用户的默认配置丢失 |
| BBI | 8,192 B，空队列 | 1,310,720 B | 可以用，只是会清空后台任务队列 |

安装镜像里的注册表是“刚装完、还没开过机”的通用模板，和具体哪台电脑无关。真用它覆盖，相当于把这台电脑的配置全部清零，后果比重装系统还麻烦。

用镜像做就地升级修复也不行。镜像的版本是 22631.2861，比舍友已装的 22631.5768 还老，安装程序会以“版本更低”直接拒绝。

镜像真正的用处是做参照。比如前面那 6 个没写路径的驱动，就是对照镜像里的 `SYSTEM` 才确认是正常现象；镜像里的 `BBI` 和本机 `BBI` 的文件头 GUID 完全一样，格式版本也一样，说明万一修不好 `BBI`，可以拿镜像那份空队列顶上，代价只是丢掉 81 条后台任务。用完以后卸载挂载，并清理残留的挂载记录：

```cmd
dism /Unmount-Image /MountDir:D:\_fix\mount /Discard
dism /Cleanup-Mountpoints
```

### 完整备份，然后只改那两个字节

Agent 把审计结果和修复清单写成报告给我，我确认之后，它才开始动 C 盘。

第一步是整目录备份。`C:\Windows\System32\config` 下的 9 个注册表，加上所有 `.LOG1`、`.LOG2` 和事务文件 `.TM.blf`、`.regtrans-ms`，一共 43 个文件、238.1 MB，全部拷到 `D:\_fix\backup_20261102120607\config\`，逐个算 SHA-256 和原文件比对，确认一个字节都没差。后面任何一步出问题，把这个目录拷回去就能回到修复前的状态。

然后修 `SECURITY`。PE 里装了 Node.js，Agent 先在 D 盘的副本上打补丁，代码就几行：

```js
const b = fs.readFileSync(src);                  // src = CorruptBak\SECURITY
b.writeUInt32LE(b.readUInt32LE(4), 8);           // seq2 = seq1，清掉脏标志
let x = 0;
for (let i = 0; i < 0x1FC; i += 4) x = (x ^ b.readUInt32LE(i)) >>> 0;
const csum = x === 0xffffffff ? 0xfffffffe : (x === 0 ? 1 : x);
b.writeUInt32LE(csum, 0x1FC);                    // 重算文件头校验和
fs.writeFileSync(dst, b);
```

从十六进制看，改动就是这两处：

```cmd
偏移 0x008   2c 46 00 00  ->  2d 46 00 00   次序列号 17964 -> 17965
偏移 0x1FC   08 1b d5 b3  ->  09 1b d5 b3   校验和 0xb3d51b08 -> 0xb3d51b09
```

打完补丁的副本先 `reg load` 挂载自检：能挂载，166 个键、164 个值和原件逐项一致，`PolAcDmN`、`PolAcDmS`、8 条机密都在。确认无误后，才把它拷回 `C:\Windows\System32\config\SECURITY`。

原来那两个旧日志 `SECURITY.LOG1`、`SECURITY.LOG2`，挪到了 `D:\_fix\quarantine\` 隔离。实验 j 已经证明，注册表干净时内核根本不看旧日志，留着也没事；挪走是为了不留歧义，以后谁再来排查，不会被两个序列号对不上的日志误导。挪走之后，内核第一次挂载 `SECURITY` 时会自己重建新的空日志。

`BBI` 用同样的方法处理，次序列号从 53231 改成 53232，重算校验和。挂载测试通过，81 条 `WorkItems`、1431 条 `PackageImportance`、136 条 `Events` 全部保留。

最后禁用孤儿驱动 `softaal`。离线改注册表的方法是先把 C 盘的 `SYSTEM` 挂到 PE 的注册表里，改完立刻卸载：

```cmd
reg load HKLM\OFFSYS C:\Windows\System32\config\SYSTEM
reg add "HKLM\OFFSYS\ControlSet001\Services\softaal" /v Start /t REG_DWORD /d 4 /f
reg unload HKLM\OFFSYS
```

这次记得 `unload` 了。

### 清理休眠文件与更新残留

C 盘根目录有一个 6,715,396,096 字节（6.25 GB）的 `hiberfil.sys`。它是休眠文件，电脑休眠时把内存内容写进去，下次开机由 `winresume` 读回来恢复现场。Agent 读了它的前 4 KB，全是 0，文件头已经废了，不可能再从里面恢复任何东西。BCD 里还有四个恢复项指着它，留着只会让启动管理器每次开机白试一次。这个文件纯粹在占地方，删掉。

```cmd
del /f /a C:\hiberfil.sys
```

另外几个更新和重置留下的目录也一起清掉：

```cmd
rd /s /q C:\$WinREAgent
rd /s /q C:\$Windows.~BT
rd /s /q C:\$SysReset
rd /s /q C:\Windows\SoftwareDistribution\Download
```

`$WinREAgent` 是更新恢复环境时留下的回滚数据，1,771 MB；`$Windows.~BT` 是系统升级的临时目录，56.7 MB；`$SysReset` 是“重置此电脑”留下的，0.3 MB；`SoftwareDistribution\Download` 是 Windows Update 下载的更新包缓存，65.5 MB。删之前 Agent 先确认了 `SYSTEM` 里的 `SetupType` 和 `SystemSetupInProgress` 都是 0，也没有 `pending.xml`，说明没有任何正在进行的安装，这些目录删了不影响启动。

两项加起来，C 盘可用空间从 8.9 GB 变成了 16.0 GB。如果舍友一开始就把这些清掉，后面这些事可能压根不会发生。

### 复查

改完以后，最有说服力的检查是重新跑一遍之前失败的那条命令：

```cmd
X:\Windows\System32>dism /Image:C:\ /Get-Packages /Format:Table
部署映像服务和管理工具
版本: 10.0.22621.1

映像版本: 10.0.22631.5768

...
操作成功完成。
```

83 个包，状态全部是“已安装”，没有挂起的操作。同一条命令，修复前直接死在 `0xd000014c`。DISM 要成功列出包，必须先按顺序挂载 `SOFTWARE`、`SYSTEM`、`SECURITY`，所以这条比任何单独的 `reg load` 都更能说明 `SECURITY` 修好了。再跑一遍组件存储检查：

```cmd
X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /ScanHealth
...
未检测到组件存储损坏。
操作成功完成。
```

然后九个注册表逐个做四层检查：文件头的签名、序列号和校验和；数据块链有没有断；从根键往下逐层遍历，检查父指针、子键表、值表；最后统计已分配但找不到父亲的孤儿键：

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

父指针错误、子键表错误、值表错误、数据块链断裂、孤儿键，全部是 0，九个注册表都能正常挂载。

你可能注意到 `SECURITY` 的序列号从补丁后的 17965 变成了 17970。这是因为每次 `reg load` 再 `reg unload`，即使只读不写，内核也会把序列号推进一次，并给每个键打上挂载标记。Agent 把 17970 这份和原件逐字节比对，差异只在文件头字段、根键的父指针和易失子键字段，以及每个键的访问标志位，键名、值名、值数据一个都没变。

还有一个小插曲。扫描 `SYSTEM` 时，在偏移 `0xd1a718` 处有一个 72 字节、以 `6e 6b`（也就是 `nk`，键单元的标记）开头的已分配单元，乍一看像孤儿键。但键单元最小也有 `0x4C` 即 76 字节，它不够长，只是一段恰好以这两个字节开头的数据。差点为一个不存在的问题动手。

身份和其他状态也都对了一遍：

```cmd
PolAcDmN        LAPTOP-VQSR6OMV
PolAcDmS        S-1-5-21-4291209427-...
ProfileList     S-1-5-21-...-1001  ->  C:\Users\admin
SAM 账户        admin / Administrator / DefaultAccount / Guest / WDAGUtilityAccount
Lsa 启动密钥     由 JD、Skew1、GBG、Data 四个键的类名拼出，完整

DISM /Get-MountedImageInfo        无挂载残留
WinSxS\pending.xml                不存在
CBS PackagesPending               空
Session Manager\BootExecute       autocheck autochk *
bcdedit {default}                 partition=C:  \Windows\system32\winload.efi
Winre.wim                         存在，BCD 的 recoverysequence 指向它
启动驱动（Start 0/1）              131 个，文件缺失 0
存储类过滤器                       partmgr / volsnap / fvevol / iorate / rdyboost，全部系统默认
fsutil dirty query C:             没有损坏
```

`ControlSet001\Control\Lsa` 下面 `JD`、`Skew1`、`GBG`、`Data` 四个键的值都是空的，真正的启动密钥藏在它们的类名里，很多工具只读值不读类名，所以会误以为它丢了。

## 尾声

### 清理 InFlight，顺利开机

复查时 Agent 还发现 `C:\Windows\WinSxS\Temp\InFlight` 下堆了 5336 个目录、1498.9 MB，时间从 2023 年 10 月一直到 2026 年 11 月，是 DISM 和更新组件用完没回收的暂存副本。它不在启动的关键路径上，只是白白占着 1.5 GB，这次没动。

顺带一件小事：排查过程中 Agent 自己跑的几次 `DISM /ScanHealth` 和 `/Get-Packages`，又在 `InFlight` 下留了 7334 个目录、1393 MB 临时文件，C 盘可用空间被它们吃掉了一截。确认是这几次排查产生的之后删掉，C 盘可用空间从 16.0 GB 回到 16.5 GB。这次故障的起点就是 C 盘写满，总得给下次留点余量。

九个注册表全部干净、全部可以挂载，组件存储没有损坏，引导链完整，没有挂起的操作。剩下的就看 LSA 认不认这份清掉脏标志的 `SECURITY` 了。

拔掉 U 盘重启，舍友的电脑顺利进了系统。从头到尾，真正对这台电脑做的修复，就是在两个注册表文件头上各改了 2 个字节。

### 用注册表把自动更新暂停 1000 周

C 盘太小是根子，但直接把它写满的，是 Windows Update 在后台悄无声息地解压和安装更新。舍友装的最后一个累积更新是 2025 年 8 月的 22621.5768，之后一年多再没有新的累积更新装上，我猜很可能就是 C 盘空间一直不够，更新反复下载、反复失败，最后把空间耗尽。这一点没有直接证据。

就算空间够，最近一年多的 Windows 11 更新质量也很难让人放心。随便数几个：

- 2025 年 8 月的 KB5063878，被报告在部分固态硬盘上大量写入时掉盘，还导致 OBS、NDI 推流出问题；同月的 KB5063875 把“重置此电脑”和恢复功能搞坏了，微软只能发紧急补丁（[BleepingComputer](https://www.bleepingcomputer.com/news/microsoft/microsoft-august-windows-updates-cause-severe-ndi-streaming-issues)）。
- 2025 年 10 月的 KB5066835，弄坏了 `localhost` 本地连接、资源管理器预览和智能卡认证，最离谱的是让恢复环境 WinRE 里的 USB 键盘鼠标全部失灵。电脑坏了要进恢复环境，结果恢复环境里什么都点不了，微软一周后发了带外更新 KB5070773 才修好（[Microsoft Learn](https://learn.microsoft.com/en-us/windows/release-health/resolved-issues-windows-11-24h2)）。
- 2026 年 1 月的 KB5074109，让部分电脑开机报 `UNMOUNTABLE_BOOT_VOLUME` 直接起不来，同时搞坏了经典版 Outlook 和关机、睡眠（[Windows Latest](https://www.windowslatest.com/2026/01/29/microsoft-confirms-windows-11-kb5074109-january-2026-update-causes-bsod-boot-issues-on-some-pcs-commerical)，[ZDNET](https://www.zdnet.com/article/windows-11-bug-roundup)）。
- 2026 年 2 月的 KB5077181，又有用户报告开机循环、登录界面异常和断网。

Windows Latest 统计过，Windows 11 在 2025 年一年就出了二十多次严重的更新事故（[Windows Latest](https://www.windowslatest.com/2026/01/21/windows-11-had-20-major-update-problems-in-2025-and-and-2026-started-badly-too-what-are-you-doing-microsoft)）。每个月的补丁修掉一批问题，又带来一批新问题，测试显然没跟上，最后承担后果的是普通用户。对于不需要第一时间拿到安全补丁的个人电脑，我更推荐把自动更新暂停掉，自己挑时间手动更新。

Windows 设置里自带的“暂停更新”最多只能选 5 周。改几个注册表值，就能把它延长到 1000 周左右。新建一个文本文档，粘贴下面的内容，另存为 `windows-1000weeks-update-blocker.reg`：

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

`FlightSettingsMaxPauseDays` 是设置里允许暂停的最大天数，`0x1b58` 换成十进制是 7000 天，正好 1000 周；后面几项分别设置功能更新、质量更新和整体暂停的开始和结束时间，结束时间都定在 2042 年。保存时注意文件扩展名要真的是 `.reg`，不是 `.reg.txt`。双击导入，确认提示后打开“设置 → Windows 更新”，可以看到更新已经暂停到 2042 年。

想恢复更新时，可以直接在设置里点“继续更新”，也可以导入下面这个 `windows-1000weeks-update-blocker-recovery.reg`，它会删掉上面写入的所有值：

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
