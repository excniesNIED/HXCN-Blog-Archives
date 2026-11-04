---
title: C 盘只剩 100 MB 的那天：0x74 BAD_SYSTEM_CONFIG_INFO 抢修实录
pubDatetime: 2026-11-02T00:00:00.000+08:00
slug: win11-bad-system-config-info
tags:
  - Windows 11
  - 注册表
  - 蓝屏
  - WinPE
  - 磁盘分区
  - Windows Update
category: 踩坑日志
description: 一次 Windows 11 23H2 因 C 盘写满引发的 0x74 BAD_SYSTEM_CONFIG_INFO 抢修记录，从蓝屏与恢复界面、BitLocker 状态、bcdboot 与 bootrec 失效、DISM 反复 0xd000014c，到 SECURITY 注册表 hive 的脏标志、日志链断裂、受控加载实验和两字节补丁修复，并附分区建议与暂停更新方案。适合被 C 盘空间和 Windows 更新折磨的用户。
---

## 前言

我一直觉得，大多数人一块硬盘一个分区就够了。有多块硬盘，就一块硬盘一个分区；只有一块硬盘，最多分 C、D 两个区。C 盘我建议至少留 200 到 300 GB，重度使用的话直接给 512 GB。

理由很实际。软件可以装到别的盘，但缓存、临时文件、用户配置、更新暂存照样往 C 盘写。C 盘一小，剩余空间一紧，轻则软件报错、更新装不上，重则连系统都起不来。还有一种常见情况：手头有个大文件或者游戏，总分空间明明够，拆成几个区之后每个区都差那么一点。

也有人认为软件装在 D 盘，重装系统就不会丢。实际上重装之后 D 盘那些软件大多也跑不起来，注册表项、服务、运行库、用户配置全没了。真正值得提前备份的是这些东西：QQ 和微信的聊天记录（一般在 `C:\Users\<用户名>\文档`）、下载目录、图片视频、桌面、开始菜单，以及 `C:\Users\<用户名>\NTUSER.DAT`。最后这个文件是用户注册表配置单元，重装后可以拿它对照以前装过哪些软件、桌面摆过什么。再加上重要文档、密码和密钥，就算齐了。机器开着 BitLocker 的，还要先解锁，或者把恢复密钥导出来存好。重装完把软件补齐，把这些文件放回去，才算恢复原状。

十多年前我刚学折腾电脑的时候，父辈装机喜欢把硬盘分成四个区。那会儿流行的一键分区工具默认就是四个，久而久之成了习惯。现在不少在长辈推荐下买电脑的同辈，硬盘照样被切成四个很小的分区。我经常被 C 盘爆满的同学叫去帮忙，每次都是把其他盘的文件挪一挪、凑一凑，给 C 盘腾地方。

如果你觉得把系统盘切得很小、多分几个区挺好，我舍友这台电脑就是现成的反例。

## 猜测和尝试

### 基本情况

舍友的机器是华硕笔记本，出厂预装 Windows 11 家庭中文版，一路自动更新到 22631.5768。1 TB 的固态被切成了 C、D、E 三个数据分区，C 盘只给了 150 GB，D 盘和 E 盘各 389 GB，剩下的空间给了华硕的恢复分区和几个隐藏分区。C 盘里塞了 MATLAB、SQL Server 2022、Office 2014，还有一个 Steam 游戏库。

某天开机，屏幕直接变成蓝屏，报 `BAD_SYSTEM_CONFIG_INFO`，然后自动重启，再次蓝屏，如此循环。

![蓝屏崩溃界面](bsod-bad-system-config-info.svg)

重启到第三次，Windows 判定启动失败，进了自动修复。修复跑完没有任何效果，界面提示“启动修复无法修复你的电脑”，日志落在 `C:\Windows\System32\Logfiles\Srt\SrtTrail.txt`。

![启动修复失败](startup-repair-failed.svg)

这台机器没有开系统保护，也就没有还原点可用，指望“一键回滚”这条路直接堵死。舍友先拿豆包问了一圈，按建议做了检查、修复引导、清理磁盘之类的操作，机器还是起不来。之后他找到了我。

我先问清楚已经做过什么。他跑过 `chkdsk`，五阶段全绿，没有坏扇区；也跑过 `sfc /scannow`，虽然没能完整执行，但没有报出需要替换的系统文件。`chkdsk` 干净说明文件系统没崩，SSD 的闪存单元也没出问题；`sfc` 没有报错至少说明系统文件没有被大面积破坏。这两条加起来，硬件故障和文件大面积损坏的嫌疑可以先放下，矛头指向引导配置或者注册表。

顺着这个思路，我在 PE 里用 DISM++ 打开离线系统，准备修引导。结果 DISM++ 当场弹了一句“试图加载格式不准确的格式”。当时我没细想，换了个思路，直接用 `bcdboot` 重建了引导文件，重启。蓝屏没了，但换成了恢复界面的 `0xc0000001`。

![恢复错误界面 0xc0000001](recovery-error-0xc0000001.svg)

`0xc0000001` 是 `STATUS_UNSUCCESSFUL` 的泛化包装，意思是启动链上某一步没有成功，具体是哪一步它不说。不过 DISM++ 那句“格式不准确”其实已经给了提示：DISM++ 打开离线系统时要挂载注册表配置单元，如果它连挂载都失败，说明 `config` 目录里有文件是坏的。

### 关掉 BitLocker

动手之前得先确认加密状态。现在很多笔记本出厂时“设备加密”是预置启用状态，密钥自动托管到微软账户。舍友这台用的是本地账户，真被锁上了，连恢复密钥都找不到地方导，那时候再想读 C 盘就麻烦了。

进 PE 先看状态：

```cmd
manage-bde -status C:
```

```cmd
保护状态:      保护关闭
锁定状态:      已解锁
标识字段:      无
自动解锁:      已禁用
密钥保护器:    找不到
```

“密钥保护器：找不到”其实是好消息。设备加密要真正生效，必须先创建密钥保护器，而创建保护器通常要登录微软账户完成托管。这台机器从来没走过这一步，所以加密只是“预置”状态，并没有真的上锁，C 盘就是明文 NTFS，PE 里可以直接读。

为了确认，又查了一次保护器：

```cmd
manage-bde -protectors -get C:
```

```cmd
卷 C: [OS]
所有密钥保护器

错误: 找不到密钥保护器。
```

没有保护器，就没有密钥丢失的风险。顺手用 `diskpart` 把磁盘布局也列了出来，确认 ESP 和恢复分区的位置：

```cmd
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

卷 4 那个 260 MB 的 FAT32 分区就是 EFI 系统分区（ESP），后面重建引导要往它里面写文件。卷 5 是 WinRE 恢复环境，卷 3 是华硕的出厂恢复镜像。

尽管确认没有加密，我还是把 C、D、E 三个卷各跑了一遍解密：

```cmd
manage-bde -off C:
manage-bde -off D:
manage-bde -off E:
```

这一步不会解密任何现有数据。对一个本来就没加密的卷，`manage-bde -off` 是无害的空操作，作用在于防止后续操作触发 TPM 的完整性校验之后系统自动上锁，保证重启后不会突然弹出恢复密钥界面。

### 常规手段尝试

按标准流程，先挂 ESP、重建引导：

```cmd
DISKPART> select volume 4
DISKPART> assign letter=S
DISKPART> exit

X:\Windows\System32>bcdboot C:\Windows /s S: /f UEFI /l zh-cn
已成功创建启动文件。
```

`bcdboot` 做的是把 `C:\Windows\Boot` 下的引导文件和语言资源复制到 ESP，然后在 BCD 存储里创建对应的启动项。看到“已成功创建启动文件”，说明 ESP 可写、引导文件复制成功。为了保险，又手动把 `bootmgfw.efi` 覆盖成 `bootx64.efi`，保证固件按默认路径也能找到引导器：

```cmd
copy S:\EFI\Microsoft\Boot\bootmgfw.efi S:\EFI\Boot\bootx64.efi
```

然后轮到 `bootrec`，它是传统 BIOS 时代留下来的老工具，很多人修引导第一反应就是它：

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

三个命令全废。`scanos` 扫到 0 个安装，`fixboot` 直接拒绝访问。原因并不神秘：`bootrec` 判断“这里有没有 Windows”，靠的是读取离线注册表里的卷映射和存储控制器配置。注册表读不出来，它就把整块盘当成没有系统。换句话说，`bootrec` 的失败是症状，不是病因。

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

`chkdsk` 五阶段全绿，坏扇区 0。文件系统没问题，这条线索排除。

```cmd
X:\Windows\System32>sfc /scannow /offbootdir=C:\ /offwindir=C:\Windows
正在开始验证 Windows 资源保护完整性。
Windows 资源保护无法执行请求的操作。
```

`sfc` 报“无法执行请求的操作”，在离线环境下这个报错很常见，通常是它需要的组件存储或者服务会话没建起来。它没有告诉我们哪些文件坏了。

```cmd
X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /RestoreHealth
错误: 87

DISM 未识别命令行选项 "/Image:C:\"。
```

错误 87 是参数错误。当时我手打命令时冒号少打了一下，`/Image:C\` 变成了 `C:\` 之外的东西，DISM 的解析器直接不认。这个坑很浪费时间，因为它看起来像工具本身坏了，容易让人转头去查 DISM 版本。重新敲一遍，参数正确之后，真正的错误才浮出来：

```cmd
X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /RevertPendingActions
部署映像服务和管理工具
版本: 10.0.22621.1
映像版本: 10.0.22631.5768

正在从映像中还原挂起的操作...

错误: 0xd000014c
```

`/RevertPendingActions` 的作用是撤销上次没有完成的更新事务。更新在安装中途被打断时，CBS 会把“待处理动作”记在组件存储里，正常开机时由系统完成或者回滚。现在这个操作报 `0xd000014c`。

`0xd000014c` 加上客户位就是 `0xC000014C`，也就是 `STATUS_REGISTRY_CORRUPT`，注册表损坏。DISM 想打开离线系统，第一步就是挂载 `config` 目录里的注册表文件，挂不上，后面全部免谈。

再试列举已安装的更新包：

```cmd
X:\Windows\System32>dism /Image:C:\ /Get-Packages /Format:Table
...
错误: 0xd000014c

DISM 失败。不执行任何操作。
```

同样是 `0xd000014c`。到这一步可以确定，问题不在引导，也不在文件系统，而是某个注册表配置单元坏了。

接着翻启动修复的日志。`SrtTrail.txt` 开头记着：

```cmd
上一次成功启动的时间: 2026/11/1 9:32:11 (GMT)
尝试修复次数: 64
```

每次修复会话会跑十来个检测项，磁盘、卷内容、启动管理器、事件日志全是 `0x0`，只在最后一项翻车：

```cmd
会话 1   名称: 检查已安装的 LCU   结果: 成功完成。错误代码 = 0x43
会话 2   根本原因数 = 1
         找到的根本原因:
         启动修复已经尝试多次，但仍无法确定问题的原因。
会话 3   名称: 检查已安装的 LCU   结果: 成功完成。错误代码 = 0x14c
```

“检查已安装的 LCU”是去读组件存储里的更新包列表，这一步需要加载 CBS store，而 CBS store 又要加载注册表。第三次的 `0x14c` 和 DISM 的报错完全一致；第一次的 `0x43` 是共享冲突，原因后面会讲，是我自己操作留下的。

当时我按网上的常见套路，试过切换控制集。思路是 `SYSTEM` 里通常存着 `ControlSet001` 和 `ControlSet002` 两套配置，`Select\Current` 指向当前使用的那套，如果当前这套坏了，可以把 `LastKnownGood` 指向另一套。我挂载了 `SYSTEM`，查了 `Select`，发现 `Current` 就是 1，`ControlSet002` 几乎被削空，只剩一个键，切过去也没有意义。这条路不通。

真正让方向转变的是一个很不起眼的细节。我让舍友确认 C 盘剩余空间，他打开资源管理器看了一眼，说只剩 100 多 MB。之前清理桌面时他删过几个大文件，删完大概回到 8 GB。这个数字和“更新中途失败、日志链断裂”的故障形态对得上：磁盘写满的时候，写入事务可能只写了一半，数据落了盘，提交标记没写下去。

把 DISM 的日志拉出来看，事情就对上了。`C:\Windows\System32\Logfiles\Srt\DISMRepairLogFile.txt` 里，离线加载的注册表顺序是 `SOFTWARE`、`SYSTEM`、`SECURITY`，前两个都成功，第三个稳定失败：

```cmd
Failed to load offline \\?\C:\Windows\System32\config\SECURITY hive ...
Failed to load offline registry: {...}C:/Windows/System32/config/SECURITY [HRESULT = 0xd000014c - NTSTATUS Error]
Failed to load offline SECURITY hive. [HRESULT = 0xd000014c - NTSTATUS Error]
Failed to load offline store from boot directory: '\\?\C:\' and windows directory: '\\?\C:\Windows\' [HRESULT = 0xd000014c]
```

`SECURITY` 是存放本地安全策略、账户密钥和 DPAPI 主密钥的配置单元。它加载不了，CBS store 就建不起来，所有依赖组件存储的操作，包括 `Get-Packages`、`RevertPendingActions`、`sfc`，全部报同一个错。

结合 C 盘只剩 100 MB 这个事实，我当时的判断是：更新在写 `SECURITY` 的时候磁盘满了，写入被截断，留下一个处于中间状态的配置单元。要救活系统，就得让它重新变得可加载。

问题是本机的 `SECURITY` 已经坏了，手里又没有备份。我想到了一个“聪明”的办法：从我自己的电脑上复制一份 `SECURITY` 过去。两台机器都是 Windows 11，文件大小都是 65536 字节，结构应该兼容。舍友的 `SECURITY` 我移到了 `config\CorruptBak\` 下留底，然后把我的那份拷了进去。

换完之后，DISM 的表现确实变了。同一个 `RevertPendingActions`，之前稳定报 `0xd000014c`，换完之后：

```cmd
X:\Windows\System32>dism /Image:C:\ /ScratchDir:D:\backup /Cleanup-Image /RevertPendingActions
...
正在从映像中还原挂起的操作...
操作已完成。重新启动后将尝试还原挂起的操作。
操作成功完成。
```

顺手删掉了 `WinSxS\pending.xml`，又跑了一遍 `chkdsk C: /f`，重启。结果还是开不了机，错误码从 `0x74` 变成了 `0xc0000001`。

那一刻挺泄气的。DISM 都通了，按说该好了。更麻烦的是，这次“修复”把问题从“文件加载不了”变成了“文件不是这台机器的”，后者更难看出来，因为所有工具都会告诉你一切正常。

到这里，常规手段能试的都试完了。舍友的机器还在 PE 里躺着，我换了个带网络环境的 FirPE，装上 omp，让 AI Agent 接手做只读排查。

## Agent 深入排查

### 0xd000014c 到底在说哪个 hive

排查的第一步是把“哪一步失败了”钉死。之前只知道 DISM 报 `0xd000014c`，但 DISM 会依次加载三个配置单元，具体是哪一个，日志里写得很清楚，只是混在几千行里。

先把 `config` 目录列一遍，确认有没有 0 字节的文件。网上大量教程的第一反应就是“hive 变成 0 字节了”：

```cmd
X:\Windows\System32>dir C:\Windows\System32\config
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
```

一个 0 字节的都没有，`SECURITY` 是标准的 65536 字节。大小正常不代表内容正常，但至少说明它不是被截成空文件那么简单。

然后单独加载 `SYSTEM`，验证它是不是真的坏了：

```cmd
X:\Windows\System32>reg load HKLM\TEMP C:\Windows\System32\config\SYSTEM
操作成功完成。
```

`SYSTEM` 能挂载。这一下就把最常见的怀疑对象排除了。我原本一直以为是 `SYSTEM` 坏了，因为 `BAD_SYSTEM_CONFIG_INFO` 这个蓝屏码在网上几乎都指向 `SYSTEM`，搜出来的案例也全是“`SYSTEM` 损坏怎么修”。

答案在两个地方：内存转储和 DISM 日志。

第一个是内存转储。`C:\Windows\Minidump\110226-9312-01.dmp` 的头部读出来是这样：

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

`P4 = 0xC000014C` 是 `STATUS_REGISTRY_CORRUPT`。转储里还留着一小段内核字符串，UTF-16 那段是 `<SECURITY`，说明内核是在加载 `SECURITY` 时失败的。`HiveLoadFromomFile` 里重复的 `om` 不是我抄错，内核拼接日志字符串本来就会留下这种残留。

第二个是 DISM 的完整日志。把加载失败的记录抽出来，时间跨度从 11 月 1 日 17:35 到 11 月 2 日 13:55：

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

12 次全是 `SECURITY`，全部 `0xd000014c`。最后那条 `SYSTEM` 的 `0xd0000043` 是唯一的例外，它是 `STATUS_SHARING_VIOLATION`，意思是这个文件正被别的句柄占用。成因是我在 PE 里手动 `reg load` 了 `SYSTEM` 去查 `Select`，查完忘了 `reg unload`，下一次 DISM 去加载同一个文件时就冲突了。这条是操作痕迹，不是故障本身。这一点很重要，排查时如果只看到“SYSTEM 也加载失败”就慌了，很容易被带偏。

日志里还能看到 CBS 的加载顺序：

```cmd
Loading offline registry hive: SOFTWARE, into registry key '{bf1a281b-...}C:/Windows/System32/config/SOFTWARE'
Loading offline registry hive: SYSTEM, into registry key '{bf1a281b-...}C:/Windows/System32/config/SYSTEM'
Loading offline registry hive: SECURITY, into registry key '{bf1a281b-...}C:/Windows/System32/config/SECURITY'
Failed to load offline SECURITY hive. [HRESULT = 0xd000014c]
```

前两个成功，卡在第三个。CBS 是串行初始化的，一个失败，整个 store 就建不起来，后面所有命令连带失败。这就解释了为什么 `Get-Packages`、`RevertPendingActions`、`sfc`、`bootrec` 报的错看着五花八门，根子上是同一件事。

### 一次“修好了”的假象

换上去的那份 `SECURITY` 到底有什么问题，得从它里面读出来。

我把这份外来配置单元挂上，读了两项身份信息：

```cmd
计算机名   HXCN-WIN
机器 SID   S-1-5-21-1262172508-...
```

再对比本机 `SAM` 里的域信息：

```cmd
计算机名   LAPTOP-VQSR6OMV
机器 SID   S-1-5-21-4291209427-303460211-4247354471
```

两套身份完全对不上。`SECURITY` 里有两个关键值：`PolAcDmN` 保存计算机名，`PolAcDmS` 保存本机的域 SID。这两个值和 `SYSTEM` 里的 `ComputerName`、`SAM` 里的域 SID 必须是同一套。现在 `PolAcDmS` 指向 `S-1-5-21-1262172508-...`，而 `SAM` 认为本机是 `S-1-5-21-4291209427-...`，LSA 在启动时校验不过，直接拒绝初始化。

更致命的是密钥。`SECURITY\Policy\Secrets` 里存着本机的 LSA 机密，其中最重要的是 `DPAPI_SYSTEM`，它是 DPAPI 的主密钥。浏览器保存的密码、EFS 加密的文件、凭据管理器里的内容，全部由它派生。外来那份的 `Secrets` 里是 `NL$KM`、`M$_MSV1_0_TBAL_PRIMARY_{22BE8E5B-...}`、`DefaultPassword`、`MouseWithoutBorders`，一条 `DPAPI_SYSTEM` 都没有。

这意味着即使 LSA 侥幸放行，机器起来了，所有用本机 DPAPI 加密的数据也永远解不开。换一份“能加载”的配置单元，只是把“文件打不开”换成了“文件不是你的”。

DISM 通不通，取决于文件结构是否合法；系统能不能开机，取决于文件内容和这台机器是否匹配。这两件事根本不是一个层面的检查。DISM 只做前者，所以它会告诉你一切正常。

真正的本机 `SECURITY` 一直躺在 `config\CorruptBak\` 里，65536 字节，10 月 31 日 21:18 的副本。我把它拷贝出来重新分析。

### 序列号 17965 和 17964

注册表配置单元（hive）是一个二进制文件，开头 4 KB 是固定结构的头，后面是按 4 KB 对齐的 `hbin` 数据块。头部前几个字段的位置是固定的：

```cmd
偏移 0x000   "regf"                签名
偏移 0x004   seq1                  主序列号
偏移 0x008   seq2                  次序列号
偏移 0x01C   type                  hive 类型
偏移 0x024   root                  根键 nk 单元的偏移
偏移 0x028   hbins                 bins 区总字节数
偏移 0x1FC   checksum              头部校验和
```

`seq1` 和 `seq2` 是一对事务计数。内核在修改 hive 时，先把 `seq1` 加一，写数据，写完之后再把 `seq2` 加一。两次都完成，说明这次事务提交成功；如果只加了 `seq1`，说明写到一半断电或者写入失败，文件处于中间状态。所以 `seq1 != seq2` 就是所谓的“脏标志”（dirty flag）。

校验和覆盖头部前 0x1F8 字节，算法是把这些字节按 4 字节一组做异或。有两个边界约定：异或结果是 `0xFFFFFFFF` 时写 `0xFFFFFFFE`，结果是 `0` 时写 `1`。

拿原件读一遍：

```cmd
CorruptBak\SECURITY   65,536 B   seq 17965 / 17964   校验和 0xb3d51b08（自洽）
```

`seq1 = 17965`，`seq2 = 17964`，脏。校验和 `0xb3d51b08` 和重新计算的结果一致，说明头部本身没有被改坏，只是事务没收尾。

正路是靠日志重放追平。内核加载脏 hive 时，会去找同名的 `.LOG1` / `.LOG2`，检查日志里的序列号能不能接上，能接上就重放，补完那次没有提交的写入。看看日志：

```cmd
SECURITY.LOG1   49,152 B   seq 208   （2022 年的陈旧日志）
SECURITY.LOG2    8,192 B   seq 17963 （比 hive 落后 2 个事务）
```

hive 是 17965/17964，能重放的日志序列必须是 17965 或者 17964。`LOG1` 停在 208，`LOG2` 停在 17963，两个都对不上。日志链断了，重放这条路走不通。

10 月 23 日 CBS 记录的那三行 `System volume has 0G free disk space` 是最合理的解释：写事务的时候磁盘满了，数据落了盘，提交标记没写下去，日志也没跟上。这一条是推断，不是直接证据。CBS 那三行只证明了磁盘确实满过，没写它当时在写哪个 hive。

到这里问题变成：能不能只清掉脏标志，不重放日志？

为了不拿真实文件冒险，我在 D 盘上把各种组合都跑了一遍。所有实验用的都是副本，C 盘一个字节没动。

| 用例 | hive 状态 | 附带日志 | `reg load` |
|---|---|---|---|
| s1 | 脏 17965/17964 | 无 | 失败 |
| s2 | 脏 17965/17964 | 0 字节 LOG1/LOG2 | 失败 |
| s3 | 脏 17965/17964 | 陈旧 LOG1(208)+LOG2(17963) | 失败 |
| t1 | 脏，seq2 再减 2（17965/17963），校验和已重算 | 无 | 失败 |
| t2 | seq2 改成 seq1（17964/17964），校验和已重算 | 无 | 成功 |
| i | 补丁后 17965/17965 | 无 | 成功 |
| j | 补丁后 17965/17965 | 陈旧 LOG1+LOG2 原样保留 | 成功 |
| s4 | 序列号相等，但校验和不重算 | 无 | 失败 |

结果比预想的干净：只要 `seq1 != seq2`，内核就拒绝加载，跟日志在不在、是不是 0 字节、能不能重放都没有关系。脏标志本身就是致命的。

只要 `seq1 == seq2` 且校验和正确，陈旧日志原样留着也不影响加载。用例 j 就是证明：日志文件还在旁边，但 hive 干净，内核直接接受，连看都不看。

校验和必须重算。用例 s4 序列号已经相等，只差校验和没改，照样失败。这说明内核先校验头部完整性，再看序列号。

所以修复面只有两个字段：

```cmd
源   C:\Windows\System32\config\CorruptBak\SECURITY    65,536 B   17965 / 17964
改   0x008 处写回 17965                                            （清脏标志）
改   0x1FC 处重算校验和   0xb3d51b08  ->  0xb3d51b09
```

两处加起来只改 2 个字节，数据区一个字节不动。在决定动手之前，我又把这份文件完整走了一遍结构：从头部签名、序列号、校验和，到 `hbin` 链是否连续，再到从根键一层层遍历下去，检查每个 `nk` 单元的父指针、`li`/`lf`/`lh`/`ri` 子键索引、值表，最后统计“已分配但从根键不可达”的孤儿单元。结果是 166 个键、164 个值，父指针零错，子键索引全是合法的 `lh`，2 个安全描述符完整，可达单元末尾在声明的 `hbins` 边界内，孤儿键 0。

顺带验证了身份，确认这份文件确实是本机的：

```cmd
PolAcDmN   LAPTOP-VQSR6OMV                        ← 与 SYSTEM\ComputerName 一致
PolAcDmS   S-1-5-21-4291209427-303460211-4247354471  ← 与 SAM 域 SID 一致
Policy\Secrets   8 条，含 DPAPI_SYSTEM、RasDialParams!...-1001#0、6 个 MSSQL/SQL 服务账户
根键 LastWriteTime   2026-11-01 09:32:10 UTC       ← 与“上次成功启动 11/1 17:32 本地”吻合
```

`Policy\Accounts` 里有 `-501`、`-1002`、`-1003`，没有 `-1001`，而 `SAM` 里有 RID 1001 的账户。这不是缺陷。LSA 是按需创建账户项的，某个 SID 第一次被使用时才会写进去。

### 发现了 BBI 和孤儿驱动问题

既然已经写了脚本批量检查，就顺手把九个配置单元全过了一遍。除了 `SECURITY`，还有一个加载不了：`BBI`，1310720 字节，序列号 `53232/53231`，同样脏，`LOG1`/`LOG2` 都是 0 字节。

`BBI` 不是引导配置，它是 Boot Environment Infrastructure 的作业队列，里面存着 `WorkItems`（81 条）、`PackageImportance`（1431 条）、`Events`（136 条）。它脏了不会导致蓝屏，10 月 31 日就已经脏了，11 月 1 日照样开机。但它确实是“结构上不可加载”的，内核每次去读队列都会失败，只是这个失败不影响启动。既然修复方法和 `SECURITY` 完全一样，就顺手一起处理了。

查启动驱动的时候又发现一个真缺陷：

```cmd
HKLM\SYSTEM\ControlSet001\Services\softaal
  ImagePath    = \??\C:\Program Files (x86)\Tencent\QQPCMgr\15.1.22354.301\softaal64_ev.sys
  Start        = 1  (SERVICE_SYSTEM_START)
  ErrorControl = 0
```

腾讯电脑管家升级到 15.6 之后，15.1 的目录被删了，但服务项还指着旧路径。`Start = 1` 表示内核启动阶段就要加载它，`ErrorControl = 0` 表示加载失败可以忽略。这两个值凑在一起的结果是：每次开机内核都去那个已经不存在的路径找一个 `.sys`，找不到，记一笔，然后继续。不会蓝屏，但白白拖慢启动。

修复方法是把 `Start` 改成 `4`（禁用）。改了之后内核启动阶段就不会再尝试加载它，`ImagePath` 保持原样，以后想恢复也方便。

另外还有几个指向不存在文件的驱动服务：`ksapi64`（Start=2）、`ROGKB`（Start=3）、`ROGMS`（Start=3）、`TSSKX64`（Start=3）。它们的 `Start` 都大于等于 2，属于内核启动完成之后才加载的类型，不影响这次开机。其中 `TSSKX64` 比较典型，注册表里写的是 `tsskx64_EV.sys`，磁盘上只有 `TSSKX64.sys`，大小写和下划线后缀都不对，明显是安装程序留下的半成品。

还有一个 `ControlSet002` 几乎是空的，只剩一个 `Services\kisknl`，指向不存在的 `kisknl.sys`。`Select\Current = 1`，`ControlSet002` 当前不生效。正常机器上它是上一次启动的配置副本，这里被削到只剩一个键，成因不明，但和本次故障无关。

## 解决

### 镜像里那份 SYSTEM 只有 9 MB

手上有一份 `Win11_23H2_Chinese_Simplified_x64v2.iso`，版本 22631.2861。最直接的想法是从镜像里取一份干净的 hive 覆盖。试过之后确认这条路走不通。

把镜像里的 `install.wim` 挂载起来，看 `Windows\System32\config\` 目录：

| hive | 镜像内 | 本机 | 覆盖后果 |
|---|---|---|---|
| SYSTEM | 9,175,040 B / 661 个服务 / `MINWINPC` | 32,243,712 B / 846 个服务 / `LAPTOP-VQSR6OMV` | 驱动服务和设备树全丢，必然 INACCESSIBLE_BOOT_DEVICE |
| SAM | 8,192 B（空库） | 131,072 B / 5 个账户 | 账户全丢 |
| SECURITY | 8,192 B（空） | 65,536 B | LSA 机密全丢，DPAPI 数据永久打不开 |
| SOFTWARE | 66,584,576 B | 117,440,512 B | 已装软件的注册信息全丢 |
| BBI | 8,192 B（空队列） | 1,310,720 B | 这个可以用 |

镜像里的配置目录是“通用安装态”，也就是刚装完系统、还没经过 OOBE 的那份模板，跟具体机器无关。它的 `SYSTEM` 只有 9 MB，计算机名是 `MINWINPC`，服务项只有 661 个；本机的 `SYSTEM` 有 32 MB、846 个服务，里面存着这块主板、这个存储控制器、这个显卡的设备树和驱动配置。把镜像的 `SYSTEM` 盖过去，等于让系统去猜自己的硬件，猜错就是 `INACCESSIBLE_BOOT_DEVICE`。

`SAM` 和 `SECURITY` 更不用说。镜像里那份 `SAM` 只有 8 KB，是个空库，盖过去账户全没；`SECURITY` 也是 8 KB 空文件，盖过去 LSA 机密和 DPAPI 主密钥全没。

就地升级修复也不行。镜像版本 22631.2861 低于已装的 22631.5768，setup 会直接以“版本更低”拒绝。

所以这份镜像在这台机器上的正确用途是当比对基线：服务数量、驱动清单、`SYSTEM` 关键键、`BBI` 结构，都拿镜像里的值来对照，确认哪些差异是正常的、哪些是缺陷。它不能当零件库。

举一个实际用到的例子。审计启动驱动时，脚本发现 `wof`、`null`、`npfs`、`msfs`、`cimfs`、`beep` 这几个服务没有 `ImagePath`，一开始以为坏了。后来拿镜像的 `SYSTEM` 对照，发现镜像里这几项同样没有 `ImagePath`，说明它们是内核内置驱动，本来就不需要路径。如果没有基线，很容易在这里浪费半天。

唯一的例外是 `BBI`。它不绑定机器身份，镜像里那份 8,192 字节的空队列和本机的 GUID 一致，加载正常。如果本机那份脏得没法修，用镜像的 `BBI` 覆盖是可行的，代价是丢掉 81 条待处理作业，功能上等价。不过我们后来把本机那份修好了，队列也保住了。

另外做了一次受控验证：把镜像的 `BBI` 拷到 D 盘，再把本机的 `BBI{a2332f30-...}.TM.blf` 和两个 `.regtrans-ms` 事务容器一起放过去，`reg load` 依然成功，加载后还是 8,192 字节、0 个键。这说明旧的事务容器不会把内容“回放”进一个干净的空 hive，覆盖操作是安全的。

### 备份，然后只改那两个字节

真正动手之前，先把整个 `config` 目录备份到 D 盘：

```cmd
xcopy C:\Windows\System32\config D:\_fix\backup_20261102120607\config\ /E /H /Y
```

备份结果是 43 个文件、249,708,544 字节（238.1 MB），包含 9 个配置单元和全部 `.LOG1`、`.LOG2`、`.TM.blf`、`.regtrans-ms`。逐文件算了 SHA-256，和源文件比对，全部一致。这一步的意义在于，后面任何一步出错，都能原样退回去。

然后是补丁本身。先在 D 盘的工作副本上改，确认能加载再写回 C 盘：

```cmd
copy C:\Windows\System32\config\CorruptBak\SECURITY D:\_fix\stage\SECURITY
```

用十六进制工具打开这份副本，做两处修改：

```cmd
偏移 0x008   2c 46 00 00  ->  2d 46 00 00     seq2 = 17964 -> 17965
偏移 0x1FC   b3 d5 1b 08  ->  b3 d5 1b 09     重算头部校验和
```

`0x008` 处写回和 `0x004` 相同的值，让 `seq1 == seq2`，脏标志就清了。`0x1FC` 处按异或算法重算，因为 `0x008` 这个字节从 `0x2c` 变成 `0x2d`，异或结果跟着变，从 `0xb3d51b08` 变成 `0xb3d51b09`。

改完先 `reg load` 自检：

```cmd
reg load HKLM\CHK D:\_fix\stage\SECURITY
操作成功完成。
```

能加载，再读里面的身份信息，确认没改坏数据：

```cmd
PolAcDmN   LAPTOP-VQSR6OMV
PolAcDmS   S-1-5-21-4291209427-303460211-4247354471
Policy\Secrets   8 条，含 DPAPI_SYSTEM
```

身份对得上，机密在，键值数量和原件一致，才写回 C 盘：

```cmd
copy /y D:\_fix\stage\SECURITY C:\Windows\System32\config\SECURITY
```

写回之后，把那两个陈旧的日志文件隔离掉：

```cmd
move C:\Windows\System32\config\SECURITY.LOG1 D:\_fix\quarantine\
move C:\Windows\System32\config\SECURITY.LOG2 D:\_fix\quarantine\
```

这一步严格来说不是必需的。用例 j 已经证明，hive 干净的时候内核根本不看日志。但把日志移走有两个好处：一是消除歧义，后面任何人再看到这个目录，不会误以为系统正在等日志重放；二是让内核在下次挂载时自己重建干净的日志文件，日志序列从当前 hive 序列开始，以后的事务记录就是连续的。写回后第一次挂载，C 盘上会重新出现 `SECURITY.LOG1`（36,864 字节）和 `SECURITY.LOG2`（0 字节），那是内核新建的，不是原来的。

`BBI` 用同样的方法处理。它原来停在 `53232/53231`，把 `0x008` 处改成 `53232`，重算 `0x1FC` 的校验和，`reg load` 验证通过，再写回。修完之后 81 条 `WorkItems`、1431 条 `PackageImportance`、136 条 `Events` 全部还在。

`softaal` 的 `Start` 改成 4，需要挂载 `SYSTEM`，改完再卸载：

```cmd
reg load HKLM\SYS C:\Windows\System32\config\SYSTEM
reg add "HKLM\SYS\ControlSet001\Services\softaal" /v Start /t REG_DWORD /d 4 /f
reg unload HKLM\SYS
```

`reg unload` 这一步千万别忘。前面那个 `0xd0000043` 就是忘了一次留下的。

### 删除休眠文件，清掉更新残留

补丁打完，系统已经能加载了，但 C 盘还是紧。舍友这台机器上有一个 6.25 GiB 的休眠文件：

```cmd
C:\hiberfil.sys   6,715,396,096 字节
```

休眠文件的作用是把内存内容写到磁盘，下次开机从它恢复现场。正常关机时系统会把头部标记为“无效”，只有休眠关机才会写有效头。这个文件的前 4 KB 全是 0，头部早就废了，`winresume` 不可能从里面恢复任何东西。BCD 里还有四个 `resumeobject` 指向它，引导器每次启动都要白试一次。

删掉它：

```cmd
del /f /q C:\hiberfil.sys
```

顺手把 `HibernateEnabled` 关掉，避免系统再生成一个：

```cmd
reg load HKLM\SYS C:\Windows\System32\config\SYSTEM
reg add "HKLM\SYS\ControlSet001\Control\Power" /v HibernateEnabled /t REG_DWORD /d 0 /f
reg unload HKLM\SYS
```

注意 `hiberfil.sys` 是受保护的系统文件，在 PE 里直接删没有问题，在正常系统里需要先 `powercfg -h off`。

接下来清理更新和重置留下的目录：

```cmd
rmdir /s /q C:\$WinREAgent
rmdir /s /q C:\$Windows.~BT
rmdir /s /q C:\$SysReset
rmdir /s /q C:\Windows\SoftwareDistribution\Download
```

这四个目录分别是 WinRE 更新回滚数据（1,771 MB）、就地升级暂存（56.7 MB）、重置系统日志（0.3 MB）、更新下载缓存（65.5 MB），加起来约 1.9 GB。删之前确认过没有正在进行的安装：`SetupType = 0`、`SystemSetupInProgress = 0`、`OOBEInProgress = 0`，`WinSxS\pending.xml` 不存在，`PackagesPending` 为空。没有挂起操作，这些目录就是纯垃圾。

清理完，`fsutil volume diskfree C:` 显示可用空间 16.5 GB。从接手时的 100 多 MB，到清理桌面后的 8 GB 出头，再到这里，才算真正有了余量。

### 复查

修完不能只看“能加载”，得确认没改坏东西。九个配置单元逐个做了四层检查：头签名、序列号、校验和，`hbin` 链完整性，从根键深度遍历（父指针、子键索引、值表），最后统计孤儿键。

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

父指针错 0、子键表错 0、值表错 0、`hbin` 链断 0、孤儿键 0。九个全部 `reg load` 成功。

`SECURITY` 的序列号是 17970，比我们改完的 17965 大。文件没有再次损坏，是 `reg load` 自检把序列号推了上去。内核每次挂载都会把 `seq1`/`seq2` 加一，同时给每个 `nk` 单元打上挂载标记。所以每做一次自检，序列号就涨一点。内容有没有变，得看语义比对，不能看序列号。

把当前文件和 `CorruptBak` 里的原件做了逐项比对：两边都是 166 个键、164 个值，键名、值名、值类型、值数据完全一致，0 处差异。字节层面有 182 处不同，逐字段归类之后只有这些：根 `nk` 的 `Parent`（1 字节）、`VolatileSubKeyCount`（1 字节）、`VolatileSubKeyList`（4 字节），以及全部 166 个 `nk` 的 `AccessBits`（各 1 字节，从 `0x1` 变成 `0x3`、从 `0x0` 变成 `0x2`）。这些是内核挂载时写的 `KEY_VOLATILE` 标记，不涉及任何键名、值名和值数据。

结构走查里有一个单元差点被误判。`SYSTEM` 里 `0xd1a718` 处有一个 72 字节的已分配单元，开头两个字节是 `6e 6b`，也就是 `nk`。按字面看像个孤儿键。但 `nk` 单元的最小长度是 `0x4C`，也就是 76 字节，72 字节不够，它只是一段恰好以 `nk` 开头的数据。差一点为一个不存在的问题动手。

身份一致性也逐项对了一遍：

```cmd
PolAcDmN   LAPTOP-VQSR6OMV
PolAcDmS   S-1-5-21-4291209427-303460211-4247354471
ProfileList  S-1-5-21-...-1001  ->  C:\Users\admin
SAM 账户     admin / Administrator / DefaultAccount / Guest / WDAGUtilityAccount
Lsa boot key  TC463EF4966D8796
```

`Lsa boot key` 是从 `SYSTEM\ControlSet001\Control\Lsa` 下的 `JD`、`Skew1`、`GBG`、`Data` 四个键拼出来的。这四个键的值都是空的，真正的 SYSKEY 存在类名里，所以很多工具读不出来。

最后是组件存储和引导链：

```cmd
DISM /Cleanup-Image /ScanHealth   未检测到组件存储损坏
DISM /Get-MountedImageInfo        无挂载残留
WinSxS\pending.xml                不存在
COMPONENTS\...\PackagesPending    空
Session Manager\BootExecute       autocheck autochk *
bcdedit {default}                 partition=C:  \Windows\system32\winload.efi
L:\Recovery\WindowsRE\Winre.wim   存在，BCD recoverysequence 指向它
启动驱动（Start 0/1，Type 1/2）   131 个，镜像文件缺失 0
存储类过滤器                       partmgr / volsnap / fvevol+iorate+rdyboost，系统默认
fsutil dirty query C:             没有损坏
```

最硬的一条证据是 `DISM /Get-Packages`。修复前它直接报 `0xd000014c`，现在：

```cmd
部署映像服务和管理工具
版本: 10.0.22621.1

映像版本: 10.0.22631.5768

...
操作成功完成。
```

83 条包，状态全部“已安装”，没有 Pending。这个命令要完整走一遍 CBS store 初始化，也就是依次加载 `SOFTWARE`、`SYSTEM`、`SECURITY`。它能跑通，说明 `SECURITY` 是真的修好了，比任何单文件自检都有说服力。

## 尾声

### 开机之后

`WinSxS\Temp\InFlight` 里堆着 5336 个目录、1498.9 MB，时间戳从 2023 年 10 月 11 日一直到 2026 年 11 月 2 日。这是 DISM 和更新组件做暂存时留下的副本，正常应该由组件存储回收，但有些清理失败的就一直留着。它们不占关键路径，只是白吃 1.5 GB。

另外，我这次排查自己跑了几次 `DISM /ScanHealth` 和 `/Get-Packages`，每跑一次都在 `InFlight` 下留一批临时目录，累计 7335 个、1393 MB。这些是纯垃圾，清掉之后 C 盘可用空间从 16.0 GB 回到 16.5 GB。

九个配置单元现在全部干净、全部可加载，组件存储无损坏，引导链完整，没有任何挂起操作。剩下的就看重启之后 LSA 认不认这份 `SECURITY` 了。

舍友按了重启。Windows 的启动动画转了几圈，进了锁屏界面。密码输进去，桌面出来了。

从我接手到机器重新开机，前后六个小时上下。真正改动的数据只有 `SECURITY` 和 `BBI` 的头各两个字节，外加一条驱动的 `Start` 值和几个临时目录。剩下的时间全花在确认“到底哪里坏了”上。

### 把自动更新暂停 1000 周

这次故障的直接起因是磁盘写满，而把磁盘写满的是 Windows 更新和它的暂存文件。C 盘 150 GB，装完那些软件之后本来就没多少余量，更新一摊开，WinSxS 再加一份，很快就见底了。

更何况，最近的 Windows 更新本身也不太让人省心。2025 年 8 月的 `KB5063878` 被大量报告会在写入大文件时导致采用群联、英韧主控的 SSD 掉盘，分区直接消失；同月的 `KB5063875` 把系统重置和恢复功能弄坏，微软事后发了带外补丁。2025 年 10 月的 `KB5066835` 更离谱，除了打断 `localhost`（`127.0.0.1`）的本地连接、让资源管理器预览窗格误报“文件可能危害你的电脑”，还把 WinRE 恢复环境里的 USB 键鼠驱动搞失灵，进了恢复界面鼠标键盘全没反应，微软只好在 10 月 20 日补发 `KB5070773`。2026 年 1 月的 `KB5074109` 让一部分机器报 `UNMOUNTABLE_BOOT_VOLUME` 无法开机，Outlook 的 POP/PST 也跟着出问题；2 月的 `KB5077181` 又带来启动循环、登录界面损坏、DHCP 拿不到地址，以及 `dxgmms2.sys` 的 `KERNEL_SECURITY_CHECK_FAILURE`。

这些不是我编的，微软自己的 release health 页面和几家科技媒体的追踪都能查到（[Windows Latest 的汇总](https://www.windowslatest.com/2026/01/21/windows-11-had-20-major-update-problems-in-2025-and-and-2026-started-badly-too-what-are-you-doing-microsoft)、[BleepingComputer 关于 KB5070773](https://www.bleepingcomputer.com/news/microsoft/microsoft-fixes-usb-issue-that-made-windows-recovery-unusable)、[ZDNet 的 2026 年 1 月问题清单](https://www.zdnet.com/article/windows-11-bug-roundup)）。我的看法是，Windows 11 的更新已经不能默认当成“修 bug 的补丁”来装了，尤其是那种装完必须重启、重启前不给你任何回退机会的累积更新。系统盘的剩余空间不足的时候，风险还会再放大一层，因为写入中断的概率更高。

所以我给舍友的方案是把自动更新暂停掉。不是删更新组件，也不是用第三方工具阉割 Windows Update，那些做法会破坏组件存储，真出问题时连修都没法修。这里用的是系统自带的“暂停更新”功能，只是把暂停上限从默认的 5 周改成 7000 天。

系统把这个上限存在注册表里：

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

`0x1b58` 是十进制的 7000，单位是天，正好 1000 周。下面六项分别是功能更新和质量更新的暂停起止时间，终点写到 2042 年 9 月 5 日，覆盖了这个上限。

用法很简单：新建一个文本文件，把上面的内容粘进去，保存，然后把后缀从 `.txt` 改成 `.reg`，双击，系统会弹 UAC，点“是”。导入之后打开“设置 → Windows 更新”，能看到暂停日期已经推到 2042 年。

哪天想恢复更新，用这个反向文件：

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

减号在 `.reg` 文件里的意思是删除这个值，不是赋一个负值。删除之后，系统回到默认的 5 周上限，更新也会恢复正常检查。

需要说明的是，这只是一种暂停，不是永久屏蔽。微软随时可能改掉这个上限的读取方式，或者在某些版本里忽略这些值。真到了必须打补丁的时候，手动点“检查更新”或者先导入恢复文件就行。对一个 C 盘只剩 100 MB 的机器来说，先让它安稳跑一段时间，比每个月赌一次更新不出事要划算得多。
