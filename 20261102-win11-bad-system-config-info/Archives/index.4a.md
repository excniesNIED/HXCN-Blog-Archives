---
title: 一块 150 GB 的 C 盘写满之后：Windows 11 0x74 BAD_SYSTEM_CONFIG_INFO 蓝屏抢修实录
pubDatetime: 2026-11-02T00:00:00.000+08:00
slug: win11-bad-system-config-info
tags:
  - Windows 11
  - 注册表
  - 蓝屏
  - WinPE
  - 数据恢复
category: 踩坑日志
description: 一次 Windows 11 23H2 因 C 盘写满引发 0x74 BAD_SYSTEM_CONFIG_INFO 蓝屏的抢修教程，从关闭 BitLocker、重建 UEFI 引导、排查 DISM 0xd000014c 报错，到分析注册表 Hive 序列号脏标志、修改两字节恢复系统并暂停自动更新。适合遇到注册表损坏或开机蓝屏的用户参考。
---

## 前言

关于电脑硬盘分区，我一直有个很明确的观点：对绝大多数普通用户来说，一块物理硬盘只分一个区就够了。如果机器里装了多块硬盘，每块硬盘各自保留一个分区最省心；哪怕只有一块硬盘、非要把系统和个人资料隔开，最多分成 C 盘和 D 盘两个区也就到头了。至于系统盘的容量，只要日常重度使用电脑，C 盘留出 200 GB 到 300 GB 甚至 512 GB 才算得上稳妥。

很多人习惯给 C 盘只划一百多 GB，觉得只要安装软件时手动把路径改到 D 盘或 E 盘，C 盘就不会满。但用过一段时间就会发现，Windows 下的软件就算把主程序装在别的分区，运行时的各种缓存、AppData 用户配置、包管理器仓库、休眠文件（`hiberfil.sys`），还有 Windows 更新解压出来的数万个组件副本（`C:\Windows\WinSxS`），依然会源源不断地往 C 盘里塞。一旦 C 盘剩余空间见底，轻则大型软件打不开、编译报错，重则连系统更新写注册表都会因为磁盘爆满而中断，直接导致电脑无法开机。把一块硬盘切成三四个碎分区还会带来另一个很尴尬的场面：当你下载一个上百 GB 的游戏或者大型工程数据集时，所有分区的剩余空间加起来明明绰绰有余，却偏偏没有哪一个单独的分区装得下它。

也有人反驳说，把软件装在 D 盘是为了重装系统时不丢软件。这个想法其实站不住脚。在 Windows 下，绝大多数大型软件安装时都会往系统注册表（`SOFTWARE` 和 `NTUSER.DAT`）、`C:\ProgramData` 以及 `C:\Windows\System32` 里写入大量的组件注册信息和运行库依赖。一旦重装了 C 盘，原来留在 D 盘的那些软件目录除了占地方，十有八九会因为丢失注册表项或缺少 DLL 而报错，最后还是得老老实实重装一遍。真到了需要重装系统的时候，唯一值得备份的其实是个人数据：

- **QQ 与微信聊天记录**：通常默认存放在 `C:\Users\<用户名>\Documents\Tencent Files` 和 `WeChat Files` 目录中；
- **个人常用文件夹**：下载目录（`C:\Users\<用户名>\Downloads`）、桌面（`Desktop`）、文档（`Documents`）、图片与视频；
- **用户配置与已装软件参考**：可以把开始菜单目录（`C:\Users\<用户名>\AppData\Roaming\Microsoft\Windows\Start Menu\Programs`）以及用户注册表文件 `C:\Users\<用户名>\NTUSER.DAT` 一并拷出来，重装后对照着看一眼，就能快速想起之前装过哪些软件、桌面上摆了什么文件；
- **密钥与凭据**：浏览器里保存的账号密码、SSH 私钥、各类激活码与证书。如果电脑开启了 BitLocker 磁盘加密，在动系统或重装之前，还必须提前解锁驱动器或者把 48 位恢复密钥导出存好。

把这些真正有价值的文件拷到移动硬盘里，重装完干净的系统再把软件补齐、把文件拷回来，远比守着一堆半残的 D 盘软件目录要靠谱得多。

回想十多年前我刚开始学着折腾电脑那会儿，父辈那一代人特别喜欢把一块硬盘分出 C、D、E、F 四个区。这种习惯多半来自当年满大街流行的盗版 Ghost 系统盘，那时候的装机工具里普遍带着一个“一键分四区”的按钮，不管硬盘多大都按比例切四刀。没想到十多年过去了，如今不少在长辈指导下买电脑的同龄人，拿到新笔记本依然习惯性地把硬盘切成四个小分区。在学校里我隔三差五就会遇到同学抱着电脑来求助，说 C 盘红了、微信连图片都加载不出来；每次我帮他们处理，都得花老大劲把 E 盘、F 盘里零散的文件往一块儿挪，删掉空分区再拿分区工具一点点把空间并回 C 盘。

如果你还是觉得给 C 盘留个一百来 GB、把硬盘切成好几个区没什么问题，那今天我帮舍友抢修电脑的这次经历，就是一个现成的反例。

---

## 猜测和尝试

### 基本情况

出事的是我舍友的华硕笔记本（机器名 `LAPTOP-VQSR6OMV`），出厂预装 Windows 11 家庭中文版，平时跟随着系统推送一路自动更新到了 23H2（内部版本号 `10.0.22631.5768`）。这台电脑配了一块 1 TB 的固态硬盘，但正是前面说的那种典型分法：C 盘只给了 150 GB，剩下的空间对半切成了两个 389 GB 的 D 盘和 E 盘。偏偏舍友平时要跑代码、做实验，C 盘里塞满了 MATLAB、SQL Server 2022、Office 2014，外加一部分 Steam 游戏库和运行环境。

11 月 1 日傍晚，这台电脑毫无征兆地突然蓝屏，屏幕下方给出的终止代码是 `BAD_SYSTEM_CONFIG_INFO`。

![蓝屏崩溃界面](bsod-bad-system-config-info.svg)

蓝屏之后电脑自动重启，刚转完圈又再次蓝屏。连续几次启动失败后，Windows 自动进入了恢复环境（WinRE）尝试“启动修复”。不出所料，自动修复折腾了一会儿就直接缴械投降，弹出蓝底白字的提示：“启动修复无法修复你的电脑”，并给出了一行日志路径 `C:\Windows\System32\Logfiles\Srt\SrtTrail.txt`。

![启动修复失败](startup-repair-failed.svg)

因为他的 C 盘常年吃紧，系统保护功能早就关了，盘里没有任何系统还原点（Restore Point）可以用来一键回退。在把电脑交给我之前，舍友已经自己对着手机上的豆包折腾了好几个小时，在恢复环境的命令提示符里挨个试了 `chkdsk` 磁盘检查和 `sfc /scannow` 系统文件扫描，但全都无济于事。

电脑拿到我手里时，我的第一反应是：既然 `chkdsk` 没扫出坏道，`sfc` 也没法直接解决问题，说明固态硬盘没有物理损坏，系统核心的二进制文件大概率也是完好的；开不了机很有可能是 UEFI 引导配置（BCD）在某次异常关机时写坏了。于是我插上装好 Ventoy 的启动 U 盘，引导进入微 PE，打开桌面上的 DISM++ 准备直接用图形界面做一次引导修复。

奇怪的事情发生了：DISM++ 刚选定 C 盘的离线系统，就弹窗报错“**试图加载格式不准确的格式**”（对应底层 `STATUS_BAD_FORMAT` 或注册表挂载失败），连系统镜像都识别不出来。我硬着头皮点了引导修复并重启电脑，结果这次连 `BAD_SYSTEM_CONFIG_INFO` 的蓝屏界面都进不去了，开机直接卡死在恢复报错界面，错误代码变成了 `0xc0000001`。

![恢复错误界面 0xc0000001](recovery-error-0xc0000001.svg)

`0xc0000001` 在 Windows NT 状态码里对应 `STATUS_UNSUCCESSFUL`，是一个非常宽泛的兜底错误码，意思仅仅是“引导阶段有核心组件没能成功跑起来”。至于到底是哪个组件挂了，光看这个蓝屏界面根本无从得知。而 DISM++ 那句“试图加载格式不准确的格式”反倒给了我一个提醒：DISM++ 打开离线系统时需要挂载目标系统的注册表配置单元（Hive 文件），它报格式错误，说明 `C:\Windows\System32\config\` 下的某个核心注册表文件很可能已经损坏了。

### 关掉 BitLocker

在 PE 里准备深入动手术之前，有一件必须优先确认的大事：**BitLocker 驱动器加密**。

近几年的华硕、联想等品牌笔记本在出厂预装 Windows 11 家庭版时，默认都会预置开启“设备加密”（Device Encryption，底层就是 BitLocker）。很多用户一旦在首次开机联网登录了微软账号，BitLocker 就会在后台静默激活，把恢复密钥悄悄上传到微软云端；更麻烦的是，我舍友平时一直用的是本地账户，压根没绑过微软账号。如果在 PE 下修改了引导扇区、动了系统分区或者主板的 TPM 安全芯片检测到启动环境变化，一旦触发 BitLocker 锁盘，手里没有 48 位恢复密钥，整块硬盘的数据就会当场永久报废。

哪怕在 PE 的资源管理器里能看到 C 盘的文件，也不能掉以轻心，必须先用命令行工具 `manage-bde` 摸清 BitLocker 的真实底层状态，顺便尝试能不能把恢复密钥导出来。在 PE 命令提示符下执行：

```cmd
X:\Windows\System32>manage-bde -status C:
```

终端返回的状态信息如下：

```cmd
保护状态:      保护关闭
锁定状态:      已解锁
标识字段:      无
自动解锁:      已禁用
密钥保护器:    找不到
```

接着我又试了导出 C 盘密钥保护器的命令（如果盘上有恢复密码或数值密钥，这条命令会把那串 48 位恢复密钥打印出来）：

```cmd
X:\Windows\System32>manage-bde -protectors -get C:
BitLocker 驱动器加密: 配置工具版本 10.0.22621
版权所有 (C) 2013 Microsoft Corporation。保留所有权利。

卷 C: [OS]
所有密钥保护器

错误: 找不到密钥保护器。
```

看到“保护状态：保护关闭”和“错误：找不到密钥保护器”这两行字，我心里悬着的大石头终于落了地。这说明出厂预置的设备加密一直处于“已用空间预加密但未激活保护器”的挂起状态。因为舍友从来没登录过微软账户，系统始终没有生成过任何密钥保护器，所以目前 C 盘完全是明文可读的，也不存在需要导出的恢复码。

为了摸清整块硬盘的分区结构，确定 EFI 引导分区（ESP）和各个数据盘的卷号，我紧接着启动了 `diskpart` 工具查看卷列表：

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

从卷列表里可以清楚看到整台机器的分区全貌：卷 0 是 150 GB 的系统盘 `C:`；卷 1 和卷 2 是两个 389 GB 的数据盘 `D:` 和 `E:`；卷 4 是 260 MB 的 FAT32 格式 `SYSTEM` 隐藏分区，也就是 UEFI 启动必需的 ESP 分区；卷 5 是 950 MB 的 WinRE 恢复环境分区；卷 3 和卷 6 则是华硕出厂自带的恢复与工具分区。

为了彻底杜绝后续反复重启和修改注册表时触发 TPM 意外锁盘的隐患，我在开始修复前先把重要个人资料拷到了移动硬盘里，然后对 C、D、E 三个分区全部执行了一次强制关闭 BitLocker 并完全解密的操作：

```cmd
X:\Windows\System32>manage-bde -off C:
X:\Windows\System32>manage-bde -off D:
X:\Windows\System32>manage-bde -off E:
```

执行完后再跑一次 `manage-bde -status C:`，确认转换状态变成“完全解密”，BitLocker 这个最大的后顾之忧就算彻底排除了。

### 常规手段尝试

解除了 BitLocker 之后，我开始把急救 Windows 启动故障的常规手段从头到尾扎实走一遍，看看问题到底出在文件系统、UEFI 引导还是系统更新组件上。

第一步是彻底检查 C 盘的文件系统元数据与坏簇，排除 NTFS 索引损坏导致内核读不出注册表的可能：

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
...
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

`chkdsk` 五个阶段完整跑下来耗时 3 分钟，坏扇区为 0 KB，文件系统干干净净。

第二步是手动挂载 ESP 引导分区并重建全套 UEFI 引导文件。前面 `diskpart` 里看到卷 4 是 260 MB 的 ESP 分区，默认处于隐藏且无盘符状态，因此需要先给它分配一个临时盘符 `S:`，再用 `bcdboot` 命令把 `C:\Windows` 下的启动固件与中文语言包重新写入 `S:` 盘，同时手动把 `bootmgfw.efi` 覆盖到默认的 `S:\EFI\Boot\bootx64.efi` 兜底路径上：

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

`bcdboot` 明确提示“已成功创建启动文件”，`bootx64.efi` 的大小（1,698,760 字节）也完全正常。接着我又顺手试了传统的 `bootrec` 引导修复三件套、离线 `sfc` 完整性校验以及 `dism` 修复命令：

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

这一串命令跑下来全是闭门羹：`bootrec /scanos` 和 `/rebuildbcd` 扫描出来的 Windows 安装总数居然是 `0`；`/fixboot` 在新版 UEFI 系统上照例报“拒绝访问”；`sfc` 扫完进度条直接甩出一句“Windows 资源保护无法执行请求的操作”；而 `dism` 更是莫名其妙地报了“错误 87”。后来翻看 `X:\windows\Logs\DISM\dism.log` 才发现，那次报 87 是因为我在 PE 里手敲命令时不小心漏打或混入了字符（日志里记录当时敲成了 `dism /Image:C\ /Cleanup-Image /RevertPendingActions`，把路径解析成了 `X:\Windows\System32\C\`），重敲一遍格式就正常了。但 `bootrec` 扫不到系统、`sfc` 无法执行操作这两个现象非常反常，因为它们在底层都需要先挂载目标系统的离线注册表来确认系统状态，连系统都认不出来，说明问题一定出在注册表配置单元上。

为了搞清楚启动修复到底卡在哪一步，我打开了 `C:\Windows\System32\Logfiles\Srt\` 目录，把文本格式的 `SrtTrail.txt` 和同目录下的 `DISMRepairLogFile.txt` 翻了出来。`SrtTrail.txt` 清晰地记录了最后一次正常启动时间和三次自动修复会话的结果：

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
名称: 检查更新               结果: 成功完成。错误代码 = 0x0
名称: 系统磁盘测试           结果: 成功完成。错误代码 = 0x0
名称: 磁盘故障诊断           结果: 成功完成。错误代码 = 0x0
名称: 磁盘元数据测试         结果: 成功完成。错误代码 = 0x0
名称: 目标操作系统测试       结果: 成功完成。错误代码 = 0x0
名称: 卷内容测试             结果: 成功完成。错误代码 = 0x0
名称: 启动管理器诊断         结果: 成功完成。错误代码 = 0x0
名称: 系统启动日志诊断       结果: 成功完成。错误代码 = 0x0
名称: 事件日志诊断           结果: 成功完成。错误代码 = 0x0
名称: 内部状态检查           结果: 成功完成。错误代码 = 0x0
名称: 检查已安装的 LCU       结果: 成功完成。错误代码 = 0x43
```

而在后续的自动修复会话里，前面十项硬件、分区、引导管理器和启动日志测试同样全部是 `0x0` 通过，唯独会话 2 给出了“启动修复已经尝试多次，但仍无法确定问题的原因”，会话 3 则在最后一项“检查已安装的 LCU（最新累积更新）”上再次翻车，错误代码变成了 `0x14c`：

```cmd
名称: 检查已安装的 LCU
结果: 成功完成。错误代码 = 0x14c
使用的时间 = 1469 毫秒
```

当时我先盯着会话 1 的 `0x43` 和 `DISMRepairLogFile.txt` 末尾的一段报错看。日志末尾最后一次会话（15:21:12）写着：

```cmd
2026-11-02 15:21:08, Info  CBS  Loading offline registry hive: SOFTWARE, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SOFTWARE' from path '\\?\C:\Windows\System32\config\SOFTWARE'.
2026-11-02 15:21:08, Info  CBS  Loading offline registry hive: SYSTEM, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SYSTEM' from path '\\?\C:\Windows\System32\config\SYSTEM'.
2026-11-02 15:21:12, Info  CBS  Failed to load offline \\?\C:\Windows\System32\config\SYSTEM hive from '\\?\C:\Windows\System32\config\SYSTEM' into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SYSTEM'. [HRESULT = 0xd0000043 - NTSTATUS Error]
2026-11-02 15:21:12, Info  CBS  Failed to load offline SYSTEM hive. [HRESULT = 0xd0000043 - NTSTATUS Error]
2026-11-02 15:21:12, Error CBS  Failed to load offline store from boot directory: '\\?\C:\' and windows directory: '\\?\C:\Windows\' [HRESULT = 0xd0000043 - NTSTATUS Error]
```

看到 `Failed to load offline SYSTEM hive` 和 `检查已安装的 LCU`，我和豆包当时都被带偏了：以为是 Windows Update 在后台安装累积更新补丁时意外中断，把 `SYSTEM` 注册表控制集写坏或者锁死了。沿着这个猜测，我立刻去检查 `C:\Windows\System32\config` 目录下的文件大小，想看看是不是哪个注册表文件变成了 0 字节，同时尝试手动挂载 `SYSTEM` 配置单元：

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

X:\Windows\System32>reg load HKLM\TEMP C:\Windows\System32\config\SYSTEM
操作成功完成。
```

结果令人意外：`config` 目录下没有任何一个文件是 0 字节（当然 Windows 10 1803 之后 `RegBack` 目录默认就是空的，没法指望自动备份），而且 `reg load HKLM\TEMP C:\Windows\System32\config\SYSTEM` 居然干净利落地提示“操作成功完成”。我挂载上去看了 `Select` 键下的 `Current` 控制集（值为 `1`），尝试切换 `ControlSet002` 备用控制集也根本不起作用。

那既然是 LCU 更新出了问题，能不能直接用 DISM 撤销挂起的更新事务（`RevertPendingActions`），或者列出最近安装的更新包（`Get-Packages`）把它卸载掉？我接着执行了这两条命令：

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

两条命令双双报错 `0xd000014c`，和前面 `SrtTrail.txt` 会话 3 的错误代码 `0x14c` 完全吻合。我马上打开 `X:\windows\Logs\DISM\dism.log` 往下翻，终于在 `RevertPendingActions` 和 `Get-Packages` 的执行记录里抓到了真正的报错现场：

```cmd
2026-11-02 15:38:14, Info   CBS  Lazy store initialization mode, fully initialize.
2026-11-02 15:38:14, Info   CBS  Offline image is writable
2026-11-02 15:38:14, Info   CBS  Loading offline registry hive: SOFTWARE, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SOFTWARE' from path '\\?\C:\Windows\System32\config\SOFTWARE'.
2026-11-02 15:38:14, Info   CBS  Loading offline registry hive: SYSTEM, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SYSTEM' from path '\\?\C:\Windows\System32\config/SYSTEM'.
2026-11-02 15:38:14, Info   CBS  Loading offline registry hive: SECURITY, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SECURITY' from path '\\?\C:\Windows\System32\config\SECURITY'.
2026-11-02 15:38:14, Info   CBS  Failed to load offline \\?\C:\Windows\System32\config\SECURITY hive from '\\?\C:\Windows\System32\config\SECURITY' into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SECURITY'. [HRESULT = 0xd000014c - NTSTATUS Error]
2026-11-02 15:38:14, Info   CBS  Failed to load offline registry: {bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SECURITY [HRESULT = 0xd000014c - NTSTATUS Error]
2026-11-02 15:38:14, Info   CBS  Failed to load offline SECURITY hive. [HRESULT = 0xd000014c - NTSTATUS Error]
2026-11-02 15:38:14, Info   CBS  Force unloading offline registry hive: {bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SOFTWARE
2026-11-02 15:38:14, Info   CBS  Force unloading offline registry hive: {bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SYSTEM
2026-11-02 15:38:14, Error  CBS  Failed to load offline store from boot directory: '\\?\C:\' and windows directory: '\\?\C:\Windows\' [HRESULT = 0xd000014c - NTSTATUS Error]
```

真相大白：CBS 服务栈在初始化离线组件库时，会按顺序依次挂载 `SOFTWARE`、`SYSTEM` 和 `SECURITY` 三个注册表配置单元。前两个 `SOFTWARE` 和 `SYSTEM` 其实每次都加载成功了，真正挂掉的是第三个 **`SECURITY` 配置单元**！一旦 `SECURITY` 抛出 `0xd000014c`（即 NTSTATUS `0xC000014C`，代表注册表损坏 `STATUS_REGISTRY_CORRUPT`），CBS 就会强制卸载前两个已经挂载好的注册表并终止会话。

也正是在这时候，我突然意识到一个之前被忽略的细节：刚进 PE 接手这台机器时，我扫了一眼这台 150 GB 的 C 盘，当时可用空间居然**只剩下 100 多 MB**！我是顺手帮他把桌面上几个不重要的大文件清理掉之后，C 盘才腾出了大概 8.9 GB 的空间（也就是前面 `chkdsk` 和 `dir` 里看到的十来个 GB 可用空间）。

把“C 盘只剩 100 多 MB”和“`SECURITY` 注册表损坏”这两条线索拼在一起，事故的轮廓一下就清晰了：C 盘被塞到只剩 100 多 MB 时，Windows Update 还在后台静默解压更新并尝试修改安全策略与权限；结果磁盘空间彻底耗尽，写操作异常中断，把 `SECURITY` 注册表配置单元弄坏了。

当时我想到了一个自以为能免重装的“终极偷懒方案”：既然 `SYSTEM` 和 `SOFTWARE` 都是好的，只是 `SECURITY` 坏了导致 DISM 和开机过不去校验，那我把坏掉的 `SECURITY` 挪走备份，从我自己的 Windows 11 电脑（或者正常镜像）里拷一份完好的 `SECURITY` 顶上去，再借用空间充裕的 D 盘作为暂存目录（`/ScratchDir:D:\backup`）跑一次 `RevertPendingActions` 撤销挂起的更新，岂不是就能起死回生？

说干就干。我先在 `config` 下建了个 `CorruptBak` 文件夹把原有的 `SECURITY` 移进去保存好，再把从我电脑上提取出来的 `SECURITY` 文件拷进 `C:\Windows\System32\config\`，随后带上了 `/ScratchDir:D:\backup` 重新执行回滚命令：

```cmd
X:\Windows\System32>md D:\backup
X:\Windows\System32>cd C:\Windows\System32\config
X:\Windows\System32\config>md CorruptBak
X:\Windows\System32\config>move SECURITY CorruptBak\SECURITY
已移动         1 个文件。

X:\Windows\System32\config>dism /Image:C:\ /ScratchDir:D:\backup /Cleanup-Image /RevertPendingActions
部署映像服务和管理工具
版本: 10.0.22621.1

映像版本: 10.0.22631.5768

正在从映像中还原挂起的操作...
操作已完成。重新启动后将尝试还原挂起的操作。
操作成功完成。

X:\Windows\System32\config>if exist C:\Windows\WinSxS\pending.xml del /f /q C:\Windows\WinSxS\pending.xml
X:\Windows\System32\config>chkdsk C: /f
```

当屏幕上跳出“操作成功完成”五个字的时候，我差点以为大功告成了。为了保险，我还顺手检查并清理了可能残留在 `WinSxS\pending.xml` 的挂起锁，打开 DISM++ 也不再弹窗报格式错误了。然而拔掉 U 盘一重启，屏幕上熟悉的蓝底白字 `0xc0000001` 再次跳了出来，系统依然死活进不去。

我回去再问 AI 还有哪些组件可能被写满的磁盘截断损坏，得到的建议是把 `SAM`（本地账户数据库）和 `COMPONENTS`（组件存储树）也从安装镜像里提取出来覆盖掉，再检查 `C:\Windows\System32\drivers\*.sys` 下有没有 0 字节的驱动文件并重构 DISM 镜像。但稍微冷静下来一想，我就果断踩了刹车：如果真拿通用镜像里的空白 `SAM` 去覆盖本机，舍友电脑上的所有本地用户账户和密码哈希就全没了。不能再这么盲目替换下去了，必须换个能直接剖析底层二进制数据的环境把病因查透。

---

## Agent 深入排查

为了彻底查清为什么换了 `SECURITY`、跑通了 DISM 还是开不了机，我换用带网络支持的 FirPE 重新引导电脑，联网配置好 `oh-my-pi`（omp）命令行环境，同时把 D 盘里那份官方原版镜像 `D:\Win11_23H2_Chinese_Simplified_x64v2.iso` 以只读方式挂载好，让 AI Agent 直接在 PE 下调用脚本与底层解析代码对整套系统做地毯式审计。

### 从日志与转储文件锁定真凶

Agent 上手后的第一件事，是去翻阅 `C:\Windows\Logs\CBS\CBS.log` 历史日志和 `C:\Windows\Minidump\` 下的蓝屏转储文件，把事故的时间线还原成确凿的证据链。

在 `CBS.log` 里，早在出事八天前的 **10 月 23 日晚上**，系统更新服务就已经连续三次拉响了磁盘空间清零的警报：

```cmd
2026-10-23 18:36:21, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:23, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:25, Info  CBS  System volume has 0G free disk space
```

紧接着这三行下面就是一句 `Maint: incomplete, interruptions: 1`。也就是说，这块 150 GB 的 C 盘在 10 月下旬就已经被后台更新真正撑爆到 `0G` 可用空间了。在极度缺盘的状态下，系统硬撑着又跑了八天，直到 11 月 1 日 17:32（UTC 时间 `09:32:11`）完成最后一次正常启动。

接着解析 `C:\Windows\System32\Logfiles\Srt\DISMRepairLogFile.txt`。这份日志总共有 2052 行（其中 1974 行带有时间戳），完整记录了从 11 月 1 日 17:35 到 11 月 2 日 15:21 期间全部 13 次离线修复尝试。把每次尝试加载注册表的失败记录抽出来，排列得整整齐齐：

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

这张表把之前困扰我的一个大疑惑彻底解开了：前面连续 12 次跨越近 22 小时的自动修复，毫无例外全部死在加载 `SECURITY` 配置单元上（报 `0xd000014c`）；唯独最后一次（11 月 2 日 15:21:12）变成了 `SYSTEM` 报错 `0xd0000043`。

为什么偏偏在 15:21 冒出一次 `SYSTEM` 失败？因为 `0xC0000043` 在 NTSTATUS 里代表 `STATUS_SHARING_VIOLATION`（文件共享冲突）。回想一下当时的操作顺序就明白了：我在 15:21 之前恰好在命令行里执行了 `reg load HKLM\TEMP C:\Windows\System32\config\SYSTEM` 来检查 `SYSTEM` 有没有坏，查完之后**忘了执行 `reg unload HKLM\TEMP`**（或者当时还开着 DISM++ 占用了句柄）！在 `SYSTEM` 文件还被挂载占用的情况下去跑修复程序，CBS 当然打不开独占文件锁，只能报共享冲突 `0xd0000043`。这是一处纯粹由我自己排查操作留下的干扰项，`SYSTEM` 本身从头到尾都是完好的。

再看唯一留存下来的那份 64 位内核崩溃转储文件 `C:\Windows\Minidump\110226-9312-01.dmp`（6,662,433 字节）。直接读取它的文件头与内嵌异常上下文：

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

转储文件里的证据和 DISM 日志严丝合缝：蓝屏代码 `0x74`（`BAD_SYSTEM_CONFIG_INFO`），第 4 个参数 `P4 = 0xffffffffc000014c` 正是 `STATUS_REGISTRY_CORRUPT`，而内嵌的内核函数名 `HiveLoadFromomFile`（内核编译拼接字符串时留下的重复 `om`）和宽字符 `<SECURITY` 直接指明：**Windows 内核在启动早期调用 `HiveLoadFromFile` 加载 `SECURITY` 注册表时判定文件损坏，当场触发 `0x74` 蓝屏保护性停机**。

### 为什么换上我的 SECURITY 还是开不了机

既然真凶只有 `SECURITY` 一个，为什么前面我从自己电脑上拷了一份完好的 `SECURITY` 顶上去，连 `DISM /RevertPendingActions` 都显示“操作成功完成”了，重启却还是报 `0xc0000001` 进不去系统？

Agent 把当时 C 盘上那份由我拷进去的 `SECURITY`（序列号 `210/210`）和舍友本机的 `SAM`、`SYSTEM`、`SOFTWARE` 放在一起做了一次跨配置单元的身份一致性比对（脚本见 `_fix/scripts/id_check.cmd`），结果一眼就看出了致命冲突：

```cmd
[外来 SECURITY 配置单元（来自我的电脑）]
PolAcDmN (计算机名)  = HXCN-WIN
PolAcDmS (机器域 SID) = S-1-5-21-1262172508-...
Policy\Secrets       = NL$KM, M$_MSV1_0_TBAL_PRIMARY_{22BE8E5B-...}, DefaultPassword, MouseWithoutBorders
                       （缺失本机 DPAPI_SYSTEM 主密钥！）

[舍友本机 SAM 与 SYSTEM 配置单元]
ComputerName         = LAPTOP-VQSR6OMV
SAM 机器域 SID       = S-1-5-21-4291209427-303460211-4247354471
ProfileList 用户 SID = S-1-5-21-4291209427-303460211-4247354471-1001 -> C:\Users\admin
```

问题就出在这里：**注册表文件在二进制结构上合法，和它在逻辑身份上属于这台机器，完全是两码事。**

DISM 在离线初始化组件库时，只关心 `SECURITY` 文件能不能被注册表引擎正常挂载、里面的权限表结构对不对。我从自己电脑（`HXCN-WIN`）上拷过去的那份 `SECURITY` 头尾干净、结构合法，所以 DISM 自然一路绿灯。

但是当电脑真正重启、Windows 内核把控制权交给本地安全机构子系统（`lsass.exe` / LSA）时，LSA 会在启动阶段严格核对 `SECURITY\Policy\PolAcDmS` 里记录的机器主域 SID 与 `SAM\SAM\Domains\Account` 里的本机域 SID 是否一致。我电脑的域 SID 是 `S-1-5-21-1262172508-...`，而舍友电脑的域 SID 是 `S-1-5-21-4291209427-303460211-4247354471`，两边完全对不上，LSA 初始化当场崩溃，系统直接抛 `0xc0000001` 拒绝启动！

更要命的是，`SECURITY\Policy\Secrets` 下存放着整台机器的数据保护主密钥 `DPAPI_SYSTEM`。Windows 下所有用 DPAPI 加密的用户凭据、Chrome 和 Edge 浏览器里保存的登录密码、无线网密码以及 EFS 加密证书，全都要靠本机独一无二的 `DPAPI_SYSTEM` 配合 `SYSTEM` 里的 `Lsa` 启动密钥（SYSKEY）才能解开。如果强行拿别人的或者空白的 `SECURITY` 混过去，就算能进桌面，本机原有的全部加密凭据和浏览器密码也会永久报废。

所以前面那次替换完全是个“假修复”：它只是拿另一台电脑的合法文件骗过了 DISM 的格式检查，却在开机安全校验上撞了墙。要想真正无损救回这台电脑，唯一的出路就是回到被我挪进 `C:\Windows\System32\config\CorruptBak\SECURITY` 的那份**舍友本机原始 `SECURITY` 文件**，搞清楚它到底坏在了哪里。

### 序列号 17965 与 17964：两字节的脏标志

把 `CorruptBak\SECURITY`（65,536 字节，SHA-256 为 `7590396173dc6ff07a847e59c662570edc2757c19e0b6459a8f06681a55fde67`）拿出来按 Windows 注册表 Hive 二进制规范拆解，真相终于浮出水面。

一个标准的 Windows 注册表配置单元文件，前 4096 字节（`0x000`–`0xFFF`）是固定格式的头部块（Base Block，签名 `"regf"`），从 `0x1000` 开始则是一个个 4 KB 对齐的数据桶（`hbin` 块），里面存放着键节点（`nk`）、值节点（`vk`）、子键索引列表（`li`/`lf`/`lh`/`ri`）和安全描述符（`sk`）。头部最关键的几个字段布局如下：

```cmd
偏移 0x000 (4 B) : "regf"                固定签名 (0x66676572)
偏移 0x004 (4 B) : PrimarySeq (seq1)     主序列号
偏移 0x008 (4 B) : SecondarySeq (seq2)   次序列号
偏移 0x00C (8 B) : LastWriteTime         最后写入时间戳 (FILETIME)
偏移 0x01C (4 B) : Type                  Hive 类型 (0 = 主文件)
偏移 0x024 (4 B) : RootCellOffset        根键 nk 单元在 hbins 区内的偏移 (0x20)
偏移 0x028 (4 B) : HiveBinsDataSize      hbins 数据区总字节数 (49,152 B)
偏移 0x1FC (4 B) : Checksum              前 0x1F8 字节共 126 个 32 位整数的按位异或（XOR）校验和
```

Windows 内核在修改注册表 Hive 文件时，靠 `seq1` 和 `seq2` 这两个 32 位序列号来保证事务原子性：开始往磁盘写数据前，内核先把偏移 `0x004` 处的主序列号 `seq1` 加 1 并更新头校验和；等所有 `hbin` 数据块都安全落盘之后，再把偏移 `0x008` 处的次序列号 `seq2` 也加 1 追平 `seq1`，重算一次校验和。如果写到一半发生断电、崩溃或磁盘写满导致事务没能完成收尾，文件头上就会留下 `seq1 != seq2` 的状态，也就是注册表配置单元的**脏标志（Dirty Flag）**。

读取舍友那份原始损坏的 `CorruptBak\SECURITY` 及其同目录下的事务日志文件 `.LOG1`、`.LOG2`，得到的数据如下：

```cmd
CorruptBak\SECURITY   65,536 B   seq1 = 17965 (0x0000462d), seq2 = 17964 (0x0000462c)   Checksum = 0xb3d51b08（自洽）
SECURITY.LOG1         49,152 B   seq  = 208 / 208                                       （2022 年遗留的陈旧日志）
SECURITY.LOG2          8,192 B   seq  = 17963 / 17963                                   （比主文件落后 2 个事务）
```

那 `CorruptBak\SECURITY` 内部的数据区到底有没有因为 C 盘写满而被截断或写花？Agent 写了一段解析脚本，对这份 65,536 字节的文件做了四层完整结构走查：

1. **头部与桶链校验**：`hbins` 声明总长度为 49,152 字节（文件偏移 `0x1000` 到 `0xD000`，即 53,248 字节处），所有 `hbin` 块头签名与尺寸严丝合缝，尾部 12,288 字节为空闲留白（Slack）；
2. **全树遍历**：从根键偏移 `0x20` 出发递归遍历整棵注册表树，共找到 **166 个键节点（`nk`）**、**164 个值节点（`vk`）**、**33 个子键索引单元（全部为合法的 `lh` 哈希列表）** 和 **2 个安全描述符单元（`sk`）**。非根键的 165 个父指针 100% 指向正确的父节点，可达单元的最大末尾偏移停在 `45,056` 字节处，没有任何一个指针越界，已分配但不可达的孤儿键数量为 **0**；
3. **本机身份与机密核对**：从数据区直接解析出的机器信息与舍友的 `SYSTEM`、`SAM` 完全一致：

```cmd
PolAcDmN (计算机名)    = LAPTOP-VQSR6OMV                        （与 SYSTEM\ComputerName 完全一致）
PolAcDmS (机器域 SID)  = S-1-5-21-4291209427-303460211-4247354471 （与 SAM 域 SID 完全一致）
Policy\Secrets         = 共 8 条机密，包含本机 DPAPI_SYSTEM、RasDialParams!S-1-5-21-...-1001#0 及 6 个 MSSQL/SQL 服务账户机密
根键 LastWriteTime     = 2026-11-01 09:32:10 UTC                （与 SrtTrail 记录的上次成功启动 09:32:11 GMT 完全吻合）
```

> 顺带提一个细节：`SECURITY\Policy\Accounts` 下有 RID `-501`、`-1002`、`-1003` 的记录，但没有 `-1001`（尽管 `SAM` 里有 RID 1001 的 `admin` 账户）。这是正常现象，因为 LSA 只有在某个 SID 首次被赋予特殊本地安全权限时才会按需在 `Accounts` 下建项，并非数据缺失。

看到这里，整个故障的底层机理已经没有半点悬念了：**舍友原本的 `SECURITY` 文件内部数据区（166 个键、164 个值）连一个字节都没坏！** 之所以内核和 DISM 死活加载不了它、反复报 `0xC000014C`（注册表损坏），仅仅是因为它上一次写入落盘后还没来得及把次序列号 `seq2`（`17964`）更新成 `seq1`（`17965`），头部的脏标志没清掉；当内核发现 `seq1 != seq2` 试图去重放旁边的事务日志自愈时，又发现 `SECURITY.LOG1` 停在 2022 年的 `208`、`SECURITY.LOG2` 停在落后的 `17963`，两个日志的序列号都接不上 `17964` 这一棒。**脏标志未清 + 事务日志链断裂**，直接把内核逼进了死胡同。

为了彻底验证 Windows 内核挂载注册表的判定边界，我们在 `D:\_fix\experiments\` 目录下用文件副本设计了 10 组受控加载实验（见 `_fix/scripts/matrix.cmd` ~ `matrix_aj.cmd`），全程不碰 C 盘原件：

```cmd
@echo off
chcp 936 >nul
echo == s1: DIRTY, no log files ==
reg load HKLM\KS1 D:\_fix\mx6\s1_dirty_nolog >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KS1 >nul 2>&1)

echo == s2: DIRTY, zero-length LOG1/LOG2 ==
reg load HKLM\KS2 D:\_fix\mx6\s2_dirty_zerolog >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KS2 >nul 2>&1)

echo == s3: DIRTY + stale LOG1(208)/LOG2(17963) ==
reg load HKLM\KS3 D:\_fix\mx6\s3_dirty_stalelog >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KS3 >nul 2>&1)

echo == s4: CLEAN but wrong header checksum ==
reg load HKLM\KS4 D:\_fix\mx6\s4_clean_badcsum >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KS4 >nul 2>&1)
```

把 `mx4` 到 `mx8` 的全部实验结果汇总成表，内核的脾气一目了然：

| 实验代号 | Hive 序列号状态 (`seq1 / seq2`) | 头部 `0x1FC` 校验和 | 附带的 `.LOG1` / `.LOG2` 状态 | `reg load` 结果 | 实验结论 |
|---|---|---|---|---|---|
| `s1` / `g` | 脏（`17965 / 17964`） | 正确 (`0xb3d51b08`) | 无日志文件 | **加载失败** | 没有可重放的日志时，脏标志本身直接致命 |
| `s2` | 脏（`17965 / 17964`） | 正确 (`0xb3d51b08`) | 0 字节空日志文件 | **加载失败** | 空日志无法消除脏标志 |
| `s3` / `a` | 脏（`17965 / 17964`） | 正确 (`0xb3d51b08`) | 原始陈旧日志 (`208` + `17963`) | **加载失败** | 完整复现开机蓝屏与 DISM `0xd000014c` |
| `h` | 脏（`17965 / 17964`） | 正确 (`0xb3d51b08`) | 仅保留 `LOG2` (`17963`) | **加载失败** | 落后 2 个事务的日志不可重放 |
| `t1` | 脏（`17965 / 17963`，差距拉大） | 重算后正确 | 无日志文件 | **加载失败** | 只要 `seq1 != seq2` 一律拒绝加载 |
| `t2` | 干净（`17964 / 17964`，回调 `seq1`） | 重算后正确 | 无日志文件 | **加载成功** | 序列号对齐即可正常挂载 |
| `i` | 干净（`17965 / 17965`，追平 `seq2`） | 重算后正确 (`0xb3d51b09`) | 无日志文件 | **加载成功** | 仅改 2 个字节即可无损恢复 |
| `j` | 干净（`17965 / 17965`，追平 `seq2`） | 重算后正确 (`0xb3d51b09`) | 保留陈旧日志 (`208` + `17963`) | **加载成功** | 主文件干净时，内核完全忽略旁边的陈旧日志 |
| `s4` | 干净（`17965 / 17965`） | **未重算（保持旧值）** | 无日志文件 | **加载失败** | 只改序列号不更新异或校验和同样会被拒绝 |

实验结论非常干净：

1. **只要 `seq1 != seq2` 且旁边的日志无法完成重放，内核和 `reg load` 就会无条件拒绝加载**；
2. **只要把偏移 `0x008` 处的 `seq2` 改成与 `seq1` 相等（`17964` → `17965`），并把偏移 `0x1FC` 处的头部异或校验和重算一遍（`0xb3d51b08` → `0xb3d51b09`），哪怕陈旧日志原样留在旁边，配置单元也能立即正常加载**；
3. 因为 `17964`（`0x0000462c`）和 `17965`（`0x0000462d`）只在最低字节相差 `1`，异或校验和也只跟着翻转最低位，所以**整个修复补丁在 65,536 字节的文件里实际上只改动了 2 个字节**！

### 发现了 BBI 和孤儿驱动问题

本着“既然进了一次 PE，就把所有隐患一次性查清”的原则，我们没有立刻重启，而是编写了全套审计脚本（`_fix/scripts/verify_final.cmd`、`audit_bootdrv.cmd`、`audit_thirdparty.cmd`、`audit_filters.cmd`、`cbs_pending.cmd`），把 `C:\Windows\System32\config\` 下的全部 9 个注册表配置单元、138 个开机启动驱动以及存储类上下层过滤器挨个筛了一遍。

这一查，果然又揪出了两个隐藏的次生问题：

**第一个问题是 `BBI` 配置单元同样带着脏标志且无法加载。**

在对全部 9 个 Hive 做结构扫描时，`SYSTEM`、`SOFTWARE`、`SAM`、`DEFAULT`、`DRIVERS`、`COMPONENTS`、`ELAM` 全部处于 `seq1 == seq2` 的干净状态，唯独 1,310,720 字节（1.25 MB）的 **`BBI`** 文件报了 `LOAD_FAIL`：

```cmd
文件 : C:\Windows\System32\config\BBI (1,310,720 B)
序列 : seq1 = 53232 (0x0000cfef+1 = 0x0000cff0), seq2 = 53231 (0x0000cfef)  [DIRTY]
日志 : BBI.LOG1 = 0 B, BBI.LOG2 = 0 B
内容 : 1,652 个键 / 10,129 个值（含 WorkItems 81 条、PackageImportance 1,431 条、Events 136 条）
```

`BBI` 是 Windows 后台代理基础设施（Background Broker Infrastructure / Boot Environment Infrastructure）使用的专用配置单元，挂载在内核 `\Registry\A\...` 命名空间下，用来记录后台任务队列（`WorkItems`）和包优先级状态。从文件时间戳来看，它在 10 月 31 日 21:18 就已经因为磁盘空间紧张留下了 `53232 / 53231` 的脏标志，旁边的 `.LOG1` 和 `.LOG2` 全是 0 字节。虽然 `BBI` 加载失败本身不会触发 `0x74` 蓝屏（11 月 1 日它带着脏标志照样开过机），但既然它是全盘唯一另一个结构性不可加载的配置单元，修复时自然要顺手用同样的两字节补丁把它一并清干净。

**第二个问题是 `SYSTEM` 里残留了一个指向不存在文件的内核启动驱动 `softaal`。**

为了防止注册表修好后重启又因为缺失开机驱动撞上 `0x7B INACCESSIBLE_BOOT_DEVICE` 蓝屏，我们用 `_fix/scripts/audit_bootdrv.cmd` 和 `audit_tp2.cmd` 遍历了 `HKLM\SYSTEM\ControlSet001\Services` 下所有 `Start = 0`（Boot 阶段加载）和 `Start = 1`（System 阶段加载）的内核驱动服务，逐一核对它们的 `.sys` 镜像文件在 C 盘上是否存在：

```cmd
@echo off
setlocal enabledelayedexpansion
chcp 936 >nul
reg load HKLM\VFSYS C:\Windows\System32\config\SYSTEM >nul 2>&1
for /f "tokens=*" %%K in ('reg query HKLM\VFSYS\ControlSet001\Services 2^>nul') do (
  set "SVC=%%K"
  set "ST="
  for /f "tokens=3" %%V in ('reg query "!SVC!" /v Start 2^>nul ^| findstr /i "REG_DWORD"') do set "ST=%%V"
  if defined ST (
    if "!ST!"=="0x0" call :check "!SVC!"
    if "!ST!"=="0x1" call :check "!SVC!"
  )
)
```

在全部 138 个开机启动驱动中，有 6 个系统内置虚拟驱动（`wof`、`null`、`npfs`、`msfs`、`cimfs`、`beep`）原本就不设 `ImagePath`（与原版 ISO 镜像基线完全一致），131 个驱动的 `.sys` 文件完好无损，唯独揪出了一个名叫 **`softaal`** 的第三方驱动服务，它的目标文件已经彻底消失了：

```cmd
HKLM\SYSTEM\ControlSet001\Services\softaal
  Type         = 0x1  (SERVICE_KERNEL_DRIVER)
  Start        = 0x1  (SERVICE_SYSTEM_START，系统内核初始化阶段自动加载)
  ErrorControl = 0x0  (SERVICE_ERROR_IGNORE)
  ImagePath    = \??\C:\Program Files (x86)\Tencent\QQPCMgr\15.1.22354.301\softaal64_ev.sys
```

检查 `C:\Program Files (x86)\Tencent\QQPCMgr\` 目录发现，舍友电脑上的腾讯电脑管家早就自动升级到了 `15.6.23169.211` 版本，旧版 `15.1.22354.301` 目录已经被删得一干二净，但卸载升级程序却忘了更新或清理 `softaal` 驱动服务的注册表路径！万幸的是，这个驱动的 `ErrorControl` 设为了 `0`（忽略错误），否则要是设成 `3`（`SERVICE_ERROR_CRITICAL`），每次开机都会直接蓝屏。即便如此，留着一个 `Start = 1` 的孤儿驱动每次开机让内核白白去找一个不存在的路径终归是个隐患，改成 `Start = 4`（禁用）最稳妥。

此外，脚本还扫出了另外 4 个指向缺失文件的非启动期（`Start >= 2`）第三方驱动服务，以及 `ControlSet002` 的一处异常：

- `ksapi64`（`Start = 2` 自启动）、华硕外设驱动 `ROGKB`（`Start = 3` 手动）与 `ROGMS`（`Start = 3` 手动）：对应的 `.sys` 文件均已不存在；
- `TSSKX64`（腾讯游戏安全/电脑管家驱动，`Start = 3`，`ErrorControl = 1`）：这个最让人哭笑不得，注册表 `ImagePath` 里写的是 `C:\Windows\System32\drivers\tsskx64_EV.sys`，但磁盘 `drivers` 目录下实际躺着的文件名叫 `TSSKX64.sys`，不仅大小写不同，还少了个 `_EV` 后缀，显然是腾讯安装程序留下的半成品；
- `ControlSet002` 几乎是个空壳：正常机器上 `ControlSet002` 会保留一份控制集备份，但这台机器的 `ControlSet002` 下只孤零零地剩下一个 `Services\kisknl`（金山毒霸残留驱动，`Start = 2`，对应的 `kisknl.sys` 也不存在）。不过由于 `Select\Current = 1`，系统开机只用 `ControlSet001`，而且上述几个驱动全部是 `Start >= 2`（内核启动阶段完全不加载），不会对本次开机造成任何阻断，记录在案即可。

---

## 解决

### 镜像里那份 SYSTEM 只有 9 MB，为什么还是要用原版镜像

在动手修补之前，我想先回答一个很多人在遇到注册表损坏时都会问的问题：**既然手里有官方原版的 `Win11_23H2_Chinese_Simplified_x64v2.iso` 镜像，为什么不能直接从镜像的 `sources\install.wim` 里把干净的注册表文件提取出来覆盖到 C 盘？既然不能覆盖，为什么我们排查时还要挂载这份原版镜像？**

在 PE 里把这份 ISO 里的 `install.wim`（Index 1，家庭中文版，版本 `10.0.22631.2861`）用 DISM 只读挂载到 `D:\_fix\mount` 之后，只要把镜像里 `Windows\System32\config\` 下的配置单元和舍友本机的文件做个对比，原因就一清二楚了：

```cmd
md D:\_fix\mount
dism /Mount-Image /ImageFile:D:\Win11_23H2_Chinese_Simplified_x64v2.iso /Index:1 /MountDir:D:\_fix\mount /ReadOnly
```

| 注册表配置单元 | 原版安装镜像内 (`22631.2861`) | 舍友本机实测 (`22631.5768`) | 强行用镜像文件覆盖本机的后果 |
|---|---|---|---|
| `SYSTEM` | **9,175,040 B (9.17 MB)** / 661 个服务 / 计算机名 `MINWINPC` | **32,243,712 B (30.8 MB)** / 846 个服务 / `LAPTOP-VQSR6OMV` | 丢失全部本机硬件驱动服务、PCI/NVMe/VMD 控制器绑定与 `Enum` 设备树，开机必报 `INACCESSIBLE_BOOT_DEVICE` |
| `SAM` | **8,192 B (8 KB 空库)** | **131,072 B (128 KB)** / 5 个用户账户 (含 `admin`) | 本机所有用户账户、RID 与密码哈希全部清空，无法登录 |
| `SECURITY` | **8,192 B (8 KB 空库)** | **65,536 B (64 KB)** / 166 键 / 8 条 LSA 机密 | 丢失机器域 SID 与 `DPAPI_SYSTEM` 主密钥，LSA 校验失败且加密数据永久作废 |
| `SOFTWARE` | **66,584,576 B (63.5 MB)** | **117,440,512 B (112.0 MB)** / 372,888 键 | 所有已安装软件、COM 组件、`ProfileList` 用户配置目录映射全部丢失 |
| `DEFAULT` | **32,768 B (32 KB)** | **6,029,312 B (5.75 MB)** | 默认用户配置模板丢失 |
| `BBI` | **8,192 B (8 KB 空队列)**，GUID 相同 | **1,310,720 B (1.25 MB)** / 81 条 `WorkItems` | **唯一可以安全直接替换的配置单元**（仅清空后台作业队列，不影响开机） |

可以看到，安装镜像里的注册表文件只是系统尚未经过硬件检测与 OOBE 初始化的**通用样板**。拿只有 9.17 MB、计算机名叫 `MINWINPC` 的空白 `SYSTEM` 去覆盖已经装了 846 个服务的本机 `SYSTEM`，无异于把整台电脑的硬件神经直接切断；至于想用这份镜像做“保留文件的就地升级修复（In-place Upgrade）”也同样走不通，因为镜像版本 `22631.2861` 低于本机已安装的 `22631.5768`，安装程序会以版本低于当前系统为由直接拒绝。

那挂载原版镜像有什么用？它最大的价值是作为**只读比对基线（Baseline）**和**组件修复源**：

1. 当我们在本机 `SYSTEM` 里发现 `wof`、`null`、`npfs` 等 6 个启动驱动没有 `ImagePath` 字段时，对照镜像里的 `SYSTEM` 一看也是这样，就能立刻排除“驱动注册表项被截断”的怀疑，避免误删误改；
2. 对照镜像的存储类过滤器（`UpperFilters` / `LowerFilters`）和 `Session Manager` 键值，可以快速确认本机的 `partmgr`、`volsnap`、`fvevol`、`iorate`、`rdyboost` 及 `BootExecute = autocheck autochk *` 是否被第三方软件篡改；
3. 如果 `BBI` 真的彻底损坏无法修补，镜像里那份 8 KB 的干净 `BBI`（内部 Hive GUID `{a2332f2f-cdbf-11ec-8680-002248483d79}` 与本机完全一致）就可以随时拿来救急；如果 `DISM /ScanHealth` 扫出系统文件损坏，挂载出来的 `D:\_fix\mount\Windows\WinSxS` 也是现成的离线修复源。

### 完整备份，然后只改那两个字节

摸清所有底牌后，正式进入修复执行阶段（对应时间 11 月 2 日 20:06–20:20）。

在改动 C 盘任何一个字节之前，第一步是给 `C:\Windows\System32\config\` 做一次**全量字节级备份**。我们将该目录下的全部 43 个文件（包含 9 个核心 Hive、1 个 `BCD-Template` 以及所有的 `.LOG1`、`.LOG2`、`.TM.blf`、`.regtrans-ms` 事务日志与容器，总计 `249,708,544` 字节 / `238.1 MB`）完整拷贝到了 `D:\_fix\backup_20261102120607\config\`（并在 U 盘归档为 `_fix/hives/pre_repair_full/`），逐一计算并核对了源文件和备份文件的 SHA-256 哈希值（完整哈希表存档于 `_fix/MANIFEST.md`），确保万一出现任何意外都可以 100% 原样回滚。

备份校验通过后，依次执行四项核心修复操作：

**1. 修补本机原始 `SECURITY` 的脏标志与校验和（仅改 2 字节）**

以 `C:\Windows\System32\config\CorruptBak\SECURITY`（65,536 字节）为源文件，在暂存副本上修改两个 32 位小端序字段：

- 将偏移 `0x008`（`SecondarySeq`）从 `17964`（十六进制字节 `2c 46 00 00`）改为与 `0x004`（`PrimarySeq`）相同的 **`17965`**（十六进制字节 `2d 46 00 00`），清除脏标志；
- 重新计算偏移 `0x000` 至 `0x1F8` 共 126 个 32 位整数的按位异或值，将偏移 `0x1FC`（`Checksum`）从 `0xb3d51b08`（字节 `08 1b d5 b3`）更新为 **`0xb3d51b09`**（字节 `09 1b d5 b3`）。

```python
import struct

with open("SECURITY", "rb") as f:
    buf = bytearray(f.read())

seq1 = struct.unpack_from("<I", buf, 0x004)[0]  # 17965 (0x0000462d)
struct.pack_into("<I", buf, 0x008, seq1)        # seq2 := seq1 (17964 -> 17965)

xor_sum = 0
for offset in range(0, 0x1F8, 4):
    xor_sum ^= struct.unpack_from("<I", buf, offset)[0]
if xor_sum == 0xFFFFFFFF:
    xor_sum = 0xFFFFFFFE
elif xor_sum == 0:
    xor_sum = 1

struct.pack_into("<I", buf, 0x1FC, xor_sum)     # 0xb3d51b08 -> 0xb3d51b09

with open("SECURITY_patched", "wb") as f:
    f.write(buf)
```

打好补丁后，先在 `D:` 盘暂存路径下用 `reg load` 做挂载自检，确认 166 个键、164 个值、`PolAcDmS`（`S-1-5-21-4291209427-303460211-4247354471`）、`PolAcDmN`（`LAPTOP-VQSR6OMV`）以及 `Policy\Secrets\DPAPI_SYSTEM` 全部可读且与原件逐项一致，随后将修补后的文件正式写回 `C:\Windows\System32\config\SECURITY`，替换掉之前那份来自我电脑的外来文件。

**2. 隔离陈旧的 `SECURITY.LOG1` 与 `SECURITY.LOG2`**

虽然前面的实验 `j` 已经证明当主文件干净时内核会忽略陈旧日志，但为了彻底消除任何工具或内核组件对断裂日志链（`208` 和 `17963`）产生歧义，我们将 `C:\Windows\System32\config\SECURITY.LOG1`（49,152 字节）和 `SECURITY.LOG2`（8,192 字节）移入 `D:\_fix\quarantine\` 隔离保存。挂载自检时，内核自动在 C 盘重建了全新的 `SECURITY.LOG1`（36,864 字节）。

**3. 修补 `BBI` 配置单元的脏标志（同样只改 2 字节）**

对 `C:\Windows\System32\config\BBI`（1,310,720 字节）执行完全相同的头修补流程：

- 将偏移 `0x008` 处的次序列号 `seq2` 从 `53231` 改为与主序列号一致的 **`53232`**；
- 重新计算前 `0x1F8` 字节的异或值并写入偏移 `0x1FC`。

修补后执行 `reg load HKLM\VFBBI C:\Windows\System32\config\BBI`，一次挂载成功，里面的 81 条 `WorkItems`、1,431 条 `PackageImportance` 和 136 条 `Events` 队列数据完好保留。

**4. 禁用孤儿启动驱动服务 `softaal`**

挂载 `SYSTEM` 配置单元，将指向已删除腾讯电脑管家旧目录的 `softaal` 服务从 `Start = 1` 改为 `Start = 4`（禁用），验证生效后立即执行 `reg unload` 卸载（吸取前面的教训，绝不留下挂载句柄）：

```cmd
reg load HKLM\VFSYS C:\Windows\System32\config\SYSTEM
reg add "HKLM\VFSYS\ControlSet001\Services\softaal" /v Start /t REG_DWORD /d 4 /f
reg query "HKLM\VFSYS\ControlSet001\Services\softaal"
reg unload HKLM\VFSYS
```

### 清理休眠文件与更新残留

注册表修好之后，必须解决引发整场灾难的源头：**C 盘可用空间不足**。如果还让 C 盘维持在捉襟见肘的状态，开机后后台服务一写日志、休眠文件一占空间，悲剧随时可能重演。

我们在 C 盘根目录下发现了两个吃空间的大户：

第一个是 **`C:\hiberfil.sys`（休眠文件，高达 6,715,396,096 字节 / 6.25 GiB）**。用脚本读取它的文件头发现，前 4 KB 全部是 `0x00` 零字节。这说明休眠镜像头早就已经失效了，开机时引导加载器（`winresume.efi`）根本不可能从里面恢复任何内存状态，而 BCD 引导库里还有 4 个 `resumeobject` 条目指向它，留着除了让引导器白白浪费一次尝试，就只是纯占 6.25 GiB 空间。我们在 PE 下直接用 `del /f /q /a C:\hiberfil.sys` 将它彻底删除（同时检查了 `ControlSet001\Control\Session Manager\Power\HiberbootEnabled` 已为 `0`）。

第二个是历史更新与重置留下的四个临时目录。在删除它们之前，我们先运行了 `_fix/scripts/verify_setup.cmd` 和 `cbs_pending.cmd`，确认系统当前没有任何正在进行的安装或挂起事务：

```cmd
==== Setup state ====
HKEY_LOCAL_MACHINE\VFSYS\ControlSet001\Control\Session Manager
    SetupType              REG_DWORD    0x0
    SystemSetupInProgress  REG_DWORD    0x0
    BootExecute            REG_MULTI_SZ autocheck autochk *

==== CbsTemp / pending ====
no pending.xml
0
```

确认 `SetupType = 0`、`SystemSetupInProgress = 0`、无 `PendingFileRenameOperations`、无 `WinSxS\pending.xml` 且 `COMPONENTS` 下的 `PackagesPending` / `RebootPending` 均为空后，安全清理了以下四个残留目录（合计释放约 1.89 GB）：

- `C:\$WinREAgent`（1,771 MB，WinRE 更新回滚暂存目录）
- `C:\Windows\SoftwareDistribution\Download`（65.5 MB，Windows Update 下载缓存）
- `C:\$Windows.~BT`（56.7 MB，旧的安装暂存目录）
- `C:\$SysReset`（0.3 MB，此前自动修复/重置尝试留下的日志目录）

接着卸载并清理了此前挂载在 `D:\_fix\mount` 的只读 ISO 镜像：

```cmd
dism /Unmount-Image /MountDir:D:\_fix\mount /Discard
dism /Cleanup-Mountpoints
```

这一套清理做完，C 盘的已用空间从 135.2 GB 降到了 127.6 GB，**可用空间从 8.9 GB 一举回升到了 16.5 GB**。

### 修复后全量复查

在拔掉 U 盘重启之前，我们用编写好的验证脚本（`_fix/scripts/verify_final.cmd`、`id_check.cmd`、`final_check.cmd`）以及离线 DISM 工具做了一次全量复查，用硬指标确认修复是否真正生效。

最有说服力的证据是重新运行之前连续 12 次报错 `0xd000014c` 的 `DISM /Get-Packages` 和 `/ScanHealth` 命令（完整输出保存在 `_fix/logs/getpkgs.txt` 与 `scanhealth.txt`）：

```cmd
X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /ScanHealth

部署映像服务和管理工具
版本: 10.0.22621.1

映像版本: 10.0.22631.5768

[==========================100.0%==========================]
未检测到组件存储损坏。
操作成功完成。

X:\Windows\System32>dism /Image:C:\ /Get-Packages /Format:Table
...
程序包标识符 : Package_for_RollupFix~31bf3856ad364e35~amd64~~22621.5768.1.15
状态 : 已安装
发行类型 : Security Update
安装时间 : 2025/8/15 14:10

程序包标识符 : Package_for_ServicingStack_5690~31bf3856ad364e35~amd64~~22621.5690.1.2
状态 : 已安装
发行类型 : Update
安装时间 : 2025/8/15 0:37

操作成功完成。
```

此前只要一跑就会在加载 `SECURITY` 那一步崩溃退出（`0xd000014c`）的离线 DISM，现在不仅顺利走完了 `SOFTWARE` → `SYSTEM` → `SECURITY` 的全套 CBS 存储初始化，还一次性完整枚举出了全部 **83 个已安装程序包**（状态全部为“已安装”，0 个挂起），组件存储扫描也给出了“未检测到组件存储损坏”的结论。

接着我们对 `C:\Windows\System32\config\` 下的全部 9 个注册表配置单元做了一次二次全结构走查（核对头签名、序列号、异或校验和、`hbin` 链完整性、全树父子指针与孤儿单元）：

| 配置单元 | 文件大小 (字节) | 修复复查后序列号 (`seq1 / seq2`) | 脏标志 | 头校验和 | 键数量 (`nk`) | 值数量 (`vk`) | 父指针/子键表/值表/hbin 链错误 |
|---|---|---|---|---|---|---|---|
| `SYSTEM` | 32,243,712 | `395834 / 395834` | 否 | OK (`0x532ee7a9`*) | 91,391 | 194,730 | 0 / 0 / 0 / 0 |
| `SOFTWARE` | 117,440,512 | `937587 / 937587` | 否 | OK | 372,888 | 640,232 | 0 / 0 / 0 / 0 |
| `SAM` | 131,072 | `3911 / 3911` | 否 | OK | 80 | 100 | 0 / 0 / 0 / 0 |
| `SECURITY` | 65,536 | `17970 / 17970` | 否 | OK (`0xb3d11b0b`) | 166 | 164 | 0 / 0 / 0 / 0 |
| `DEFAULT` | 6,029,312 | `238433 / 238433` | 否 | OK | 8,201 | 10,937 | 0 / 0 / 0 / 0 |
| `DRIVERS` | 8,777,728 | `4850 / 4850` | 否 | OK | 36,424 | 52,954 | 0 / 0 / 0 / 0 |
| `COMPONENTS` | 32,768,000 | `9216 / 9216` | 否 | OK | 61,793 | 197,776 | 0 / 0 / 0 / 0 |
| `ELAM` | 32,768 | `13 / 13` | 否 | OK | 1 | 0 | 0 / 0 / 0 / 0 |
| `BBI` | 1,310,720 | `53233 / 53233` | 否 | OK | 1,652 | 10,129 | 0 / 0 / 0 / 0 |

细心的读者可能会注意到：前面打补丁时我们把 `SECURITY` 的序列号设成了 `17965 / 17965`，怎么复查表里变成了 `17970 / 17970`（其它几个 Hive 的序列号也增加了 1 到 6）？这是因为在 Windows 下，哪怕只执行只读性质的 `reg load` 和 `reg unload` 挂载自检，内核注册表引擎在卸载时也会自动把序列号加 1 并更新头校验和。我们把 `17970 / 17970` 状态的 `SECURITY` 与 `CorruptBak\SECURITY` 原始文件做了逐字节对比：全文件共 182 字节存在差异（10 个头部字段字节 + 172 个 `hbin` 区字节），而这 172 个数据区字节拆开看，仅仅是根键的 `Parent`（1 B）、`VolatileSubKeyCount`（1 B）、`VolatileSubKeyList`（4 B）以及全部 166 个 `nk` 键节点的 `AccessBits` 访问标志位（每个键 1 字节，由内核挂载时自动置位 `0x1 -> 0x3` 或 `0x0 -> 0x2`）。166 个键名、164 个值名与值数据**零变化**。

在扫描 `SYSTEM` 的孤儿单元时，还遇到过一个挺有意思的小插曲：脚本起初在偏移 `0xd1a718` 处报告发现了一个长度为 72 字节、以十六进制 `6e 6b`（即 ASCII 字符 `"nk"`）开头的已分配单元，不在根键可达树内，看起来特别像一个断链的孤儿键。但对照注册表底层格式规范一查，标准的 `nk` 键节点结构体固定头部至少需要 `0x4C`（76 字节）才能容下必选字段，72 字节根本装不下一个 `nk` 节点，它只是一段恰好以 `"nk"` 两个字母开头的普通二进制值数据。幸亏多核对了一眼规范，没有闹出误修正常数据的乌龙。

最后运行 `_fix/scripts/id_check.cmd` 与 `final_check.cmd`，确认机器身份、LSA 启动密钥（SYSKEY）以及引导链全部闭合：

```cmd
PolAcDmN (SECURITY)   = LAPTOP-VQSR6OMV
PolAcDmS (SECURITY)   = S-1-5-21-4291209427-303460211-4247354471
ProfileList (SOFTWARE)= S-1-5-21-4291209427-303460211-4247354471-1001 -> C:\Users\admin
SAM 账户列表          = admin (0x3E9) / Administrator (0x1F4) / Guest (0x1F5) / DefaultAccount (0x1F7) / WDAGUtilityAccount (0x1F8)
Lsa Boot Key (SYSTEM) = TC463EF4966D8796（由 ControlSet001\Control\Lsa 下 JD、Skew1、GBG、Data 四个键的 Class 类名拼出）
启动驱动缺失数        = 0（共 131 个 Start 0/1 驱动文件全部在位，softaal 已设为 Start=4）
存储类过滤器          = 磁盘 Upper: partmgr | 卷 Upper: volsnap | 卷 Lower: fvevol, iorate, rdyboost
挂载残留检查          = 空（无任何 VF* / TEMP 挂载句柄残留）
bcdedit {default}     = device partition=C:, path \Windows\system32\winload.efi
fsutil dirty query C: = 卷 C: 没有损坏
```

（顺带一提，很多人在注册表编辑器里点开 `ControlSet001\Control\Lsa` 下的 `JD`、`Skew1`、`GBG`、`Data` 四个键，会发现它们右边的值全是空的，以为系统密钥丢了；其实 Windows 从 NT 时代起就把这 16 字节的 SYSKEY 藏在这四个键的 **Class 类名属性**里，必须调底层 API 或导出注册表文本才能看到。）

---

## 尾声

### 清理 InFlight 临时目录与顺利开机

在做最后的磁盘空间盘点时，我们还注意到了 `C:\Windows\WinSxS\Temp\InFlight\` 这个目录。这里面密密麻麻堆了 **5,336 个历史文件夹**，占用了 **1,498.9 MB（约 1.5 GB）** 空间，时间戳从 2023 年 10 月 11 日一路跨到 2026 年 11 月 2 日，全是历次 Windows 更新与组件维护没能及时回收的暂存目录。

更有意思的是，刚才我们在 PE 里为了验证修复效果跑的那几次 `DISM /ScanHealth` 和 `DISM /Get-Packages`，短短半小时内自己又往 `WinSxS\Temp\InFlight\` 下新塞了 **7,334 个临时目录**（清单保存在 `_fix/logs/inflight_mine.txt`），白白吃掉了 **1,393.4 MB** 空间，把 C 盘可用空间从 16.5 GB 又拉低到了 16.0 GB。我们只把自己刚才排查期间新产生的这 7,334 个目录清理掉（早先那 5,336 个历史目录留待进系统后再由组件清理处理），C 盘可用空间立刻回到了 **16.5 GB**。这也再次印证了文章开头说的那句话：Windows 维护和更新对 C 盘空间的胃口远比普通用户想象的大得多，随便跑几次离线扫描都能瞬间吐出上千兆临时文件。

至此，九个注册表配置单元全部干净可加载，组件存储零损坏，引导链完整，没有任何挂起事务，所有排查工具句柄全部卸载，全套排查脚本与修补前后的注册表样本也一并归档到了 U 盘的 `F:\bakup\_fix\` 目录下。

拔掉 Ventoy U 盘，按下电源键重启。华硕 LOGO 转圈过后，没有再出现 `BAD_SYSTEM_CONFIG_INFO` 蓝屏，也没有再跳进 `0xc0000001` 恢复界面，屏幕直接亮起了熟悉的 Windows 11 锁屏壁纸。输入密码进入桌面，舍友的桌面文件、MATLAB、SQL Server 数据库乃至浏览器里用 DPAPI 加密保存的所有登录状态完好如初。整场抢修最终只靠修改 `SECURITY` 和 `BBI` 头部的各 **2 个字节**，就实现了真正的零数据丢失恢复。

### 用注册表把自动更新暂停 1000 周

电脑虽然救回来了，但复盘整起事故的起因，除了 150 GB 的 C 盘分得太小之外，另一个让人火大的罪魁祸首就是 **Windows 11 停不下来的后台自动更新**。

平心而论，微软每个月的累积更新确实包含不少安全补丁和底层修复，但最近这一年多以来，Windows 11 更新的工程质量实在让人不敢恭维，几乎每隔一两个月就会上演一出“修好旧 Bug、顺手埋进更致命的新雷”的闹剧：

- **2025 年 8 月累积更新（`KB5063878` / `KB5063875`）**：不少搭载群联（Phison）与英韧主控 SSD 的 24H2 用户在更新后遭遇大文件连续写入时掉盘、分区无法识别甚至数据损坏，同时 OBS 等软件使用的 NDI 局域网推流也出现严重断流；同月的 `KB5063875` 更是直接把系统自带的“重置此电脑”与恢复功能搞崩，逼得微软紧急下发带外补丁（OOB）救火。
- **2025 年 10 月累积更新（`KB5066835`）**：堪称灾难级的一版更新。它先是打断了系统的 `HTTP.sys` 本地环回连接，导致大量开发者电脑上的 `localhost`（`127.0.0.1`）服务与 IIS 直接瘫痪，顺带让文件资源管理器的预览窗格频繁误报安全警告、智能卡（SmartCard）认证失效；最离谱的是，**这版更新居然把 WinRE（Windows 恢复环境）里的 USB 键鼠驱动搞废了**：用户一旦遇到系统故障掉进恢复界面，插在电脑上的 USB 鼠标和键盘全部失灵，连点“高级选项”自救的机会都没有，微软不得不紧急推送 `KB5070773` 擦屁股。
- **2026 年 1 月与 2 月累积更新（`KB5074109` / `KB5077181`）**：开年第一波更新就让部分机器在重启后直接陷入 `UNMOUNTABLE_BOOT_VOLUME` 黑屏死循环无法开机，同时引发经典版 Outlook（POP/PST 账户）卡死、云盘文件无法打开以及老机型无法正常休眠与关机，逼得微软在 1 月底连续发了两版紧急更新（`KB5077744`、`KB5078127`）；紧接着 2 月的 `KB5077181` 又被曝出无限重启循环、登录界面损坏、DHCP 无法自动获取 IP 断网以及 `dxgmms2.sys` 触发 `KERNEL_SECURITY_CHECK_FAILURE` 蓝屏。

在微软如今高度依赖裁员降本、把大量测试压力转嫁给普通用户的开发模式下，让一台主力生产电脑（尤其是 C 盘空间本就不宽裕的笔记本）毫无防备地开启自动更新，无异于在系统里装了一颗定时炸弹。

对于 Windows 11 家庭版用户来说，系统设置界面里默认最多只允许把更新暂停 5 周，而且没有本地组策略编辑器（`gpedit.msc`）可用；如果直接用第三方工具暴力阉割、删除 Windows Update 系统服务，日后需要装驱动、用微软商店或者手动打补丁时又很容易引发组件损坏。最干净、最安全的做法，是通过修改 `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings` 注册表项，**将系统暂停更新的上限天数拉长并把暂停截止时间直接定到 2042 年（约 1000 周）**。这样既不会破坏系统原有的更新组件，又能彻底堵死后台静默下载更新把 C 盘撑爆的可能。

操作方法非常简单：在桌面上新建一个文本文档（`.txt`），把下面这段内容完整复制进去，保存后将文件名和后缀改为 **`windows-1000weeks-update-blocker.reg`**，双击导入注册表即可生效：

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

这里顺带解释一下这几行键值的作用：`FlightSettingsMaxPauseDays` 的十六进制值 `00001b58` 换算成十进制就是 `7000` 天（正好 1000 周），用来突破系统设置界面的天数上限；下面六行则把功能更新（Feature Updates）和质量更新（Quality Updates）的暂停起止时间直接锁定到了 `2042-09-05`。导入之后打开“设置 → Windows 更新”，就会看到系统更新已经安静地显示为“暂停至 2042 年 9 月 5 日”。

如果日后清理或扩容了 C 盘，想恢复正常的系统更新功能，也完全不需要重装什么服务。只需同样新建一个文本文档，填入以下内容并改名为 **`windows-1000weeks-update-blocker-recovery.reg`**，双击导入即可一键清除这几条暂停配置，恢复系统默认状态：

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
