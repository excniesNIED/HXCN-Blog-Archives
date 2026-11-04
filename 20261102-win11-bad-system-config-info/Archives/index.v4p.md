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
description: 一次 Win11 23H2 因 C 盘写满引发的 0x74 BAD_SYSTEM_CONFIG_INFO 抢修记录。从 BitLocker 状态、bcdboot/bootrec 全线失败、DISM 反复 0xd000014c，到定位 SECURITY hive 的脏标志、逐字节比对、受控加载实验，最后靠改两个字段把 hive 修回可加载状态。
---

## 前言

我一直觉得，对大多数人来说，一块硬盘一个分区就够了。有几块硬盘就分几个区，只有一块硬盘的话，顶多再拆一个 D 盘出来。C 盘这东西，如果你是重度用户，起步就该给 200 GB，300 GB 甚至 512 GB 都不算多。

有人会问，软件不能装到别的分区吗。当然能，而且我也建议把游戏、大软件装到 D 盘。问题在于，很多东西你控制不了装在哪：各种缓存、临时文件、下载的更新包，默认全往 C 盘跑。C 盘留小了，剩余空间一紧张，轻则软件报错打不开，重则连开机都成问题。

分区拆得太碎还有另一个坏处。比如你下了一个 60 GB 的游戏，硬盘总剩余空间明明够，但每个分区都只剩三四十 GB，拆开也放不下，最后只能删东补西。

至于「软件装在 D 盘，重装系统数据不会丢」这个说法，我更愿意直接戳穿。重装之后，装在 D 盘的软件九成还是打不开，因为它的注册表、用户配置、运行库全在 C 盘，跟着一起没了。所以真正要做的不是把软件搬到 D 盘，而是把这几样东西备份好：QQ 和微信的聊天记录（默认在 `C:\Users\<用户名>\Documents` 里）、下载目录（`C:\Users\<用户名>\Downloads`）、图片视频、桌面文件、开始菜单，还有一份 `C:\Users\<用户名>\NTUSER.DAT`（对照它能看出你装过哪些软件）。密码和密钥单独记一份。如果开了 BitLocker，重装前记得先解锁或者把恢复密钥导出来。重装完把软件补齐，这些文件拷回去，基本就还原了。

十年前我刚学会折腾电脑的时候，我爸那一辈流行给硬盘分四个区。这习惯多少跟当年那些一键分区的盗版 Ghost 镜像有关，默认就是四个区。现在很多同辈在长辈推荐下买的电脑，硬盘照样被拆成四五个小分区。我隔三差五就遇到同学喊 C 盘满了，每次都得帮他们东挪西凑，把别的盘的文件集中起来给 C 盘腾地方。

要是你觉得我在危言耸听，那这次舍友电脑莫名其妙蓝屏的事，正好是个现成的例子。

## 猜测和尝试

### 基本情况

舍友这台是华硕笔记本，出厂预装 Windows 11 家庭中文版，一路自动更新到 23H2 的 `22631.5768`。硬盘是 1 TB 的固态，被拆成了 C、D、E 三个主分区，C 盘只有 150 GB，里面塞了 MATLAB、SQL Server 2022、Office 2014，还放了个 Steam 库。

那天它突然蓝屏，终止代码是 `BAD_SYSTEM_CONFIG_INFO`。

![蓝屏崩溃界面](bsod-bad-system-config-info.svg)

这个代码我在心里过了一遍：它和注册表配置单元（hive）加载失败高度相关。蓝屏之后机器自动重启，再蓝，再重启，反复几次之后连蓝屏都不给了，直接掉进 Windows 的自动修复。不出意外，启动修复失败了。

![启动修复失败](startup-repair-failed.svg)

启动修复失败之后，常规做法是找还原点回滚。这台机器从来没开过系统保护，加上 C 盘空间紧张，压根没有还原点可用。舍友拿豆包试了一堆检查、修复，也没折腾出结果。

既然 `chkdsk` 和 `sfc` 都查不出问题，我首先排除了硬件故障：固态盘应该没坏，系统文件大概率也没坏。那剩下的最大嫌疑就是引导配置坏了。我用 Ventoy 进了 PE，准备用 DISM++ 做修复，结果 DISM++ 一打开就提示「试图加载不准确的格式」，点修复引导之后重启，机器报了个 `0xc0000001`。

![恢复错误界面 0xc0000001](recovery-error-0xc0000001.svg)

DISM++ 那个提示其实很重要，只是我当时没想透。它本质是 DISM++ 在挂载离线系统的注册表时失败了，也就是说，问题不在引导文件，而在注册表本身。

### 关掉 BitLocker

进 PE 之后第一件事，我先确认 BitLocker 的状态。原因很实在：现在的笔记本出厂默认预置了「设备加密」，密钥托管在微软账户里。如果这机器真锁着，而我又没有密码，那连恢复密钥都导不出来，后面所有操作都白搭，甚至可能一重启就把数据彻底锁死。

先查 C 盘状态：

```cmd
manage-bde -status C:
```

输出是这样的：

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

「密钥保护器：找不到」这句话，我盯着看了两遍才松口气。它说明这台机器的设备加密从来没真正激活过，连保护器都没生成。没有保护器，就没有密钥丢失这回事，C 盘是明文 NTFS，PE 里直接读。舍友这台用的是本地账户，从来没登过微软账号，所以预置加密一直停在「没激活」的状态，反而因祸得福。

接着把磁盘布局看一遍，心里有个数：

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

这张表里我关注的是卷 4：260 MB 的 FAT32 分区，标签 `SYSTEM`，这就是 EFI 系统分区（ESP），引导文件住在这里。引导能不能起来，就看它。

确认完 BitLocker 没锁之后，我还是对 C、D、E 各跑了一遍关闭命令：

```cmd
manage-bde -off C:
manage-bde -off D:
manage-bde -off E:
```

这一步是保险。虽然现在显示「保护关闭」，但保不齐后面改引导、改注册表的时候触发 TPM 重新锁盘。先把加密彻底关掉，后面怎么折腾都不会被意外锁死。

### 常规手段尝试

BitLocker 解除了，开始按标准流程走。第一步是重建引导。我先用 diskpart 给 ESP 分区挂个盘符 S:，再用 `bcdboot` 把引导文件从 `C:\Windows` 复制过去：

```cmd
DISKPART> select volume 4
DISKPART> assign letter=S
DISKPART> exit

X:\Windows\System32>bcdboot C:\Windows /s S: /f UEFI /l zh-cn
已成功创建启动文件。
```

`bcdboot` 的作用是把 Windows 引导管理器（bootmgfw.efi）和语言资源从系统目录复制到 ESP 分区，并生成对应的 BCD 启动配置。这里显示「已成功创建启动文件」，说明引导文件本身能写进去。我又顺手确认了一下：

```cmd
X:\Windows\System32>dir S:\EFI\Boot
 驱动器 S 中的卷是 SYSTEM
 卷的序列号是 8CE7-BD30

 S:\EFI\Boot 的目录

2025/08/15  08:38         1,698,760  bootx64.efi
               1 个文件      1,698,760 字节
```

`bootx64.efi` 是 UEFI 固件默认会去找的引导程序，1.6 MB，大小正常。为了双保险，我还手动把 `bootmgfw.efi` 覆盖成 `bootx64.efi`。这两步都成功了，但问题并没有解决，后面还有更蹊跷的。

接下来跑 `bootrec` 系列：

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

这里有两个地方值得说道。`scanos` 扫出 0 个安装，看着吓人，其实是因为 `bootrec` 判断「这里有没有 Windows」要读离线注册表里的卷映射和控制器配置，读不出来它就一个都不认。而 `fixboot` 报「拒绝访问」，在 UEFI + GPT 的机器上其实是常态，这个命令是给传统 MBR 引导用的，对这台机器本就无意义。这两条报错信息量有限，我当时没敢就此下结论。

再往下查文件系统：

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

`chkdsk /f` 五个阶段全绿，坏扇区是 0。文件系统是干净的，硬件这条线索断了。

再试系统文件检查：

```cmd
X:\Windows\System32>sfc /scannow /offbootdir=C:\ /offwindir=C:\Windows
正在开始验证 Windows 资源保护完整性。
Windows 资源保护无法执行请求的操作。
```

`sfc` 也没跑起来。这里要解释一句：离线的 `sfc` 依赖组件存储（CBS），而 CBS 启动前要先把注册表配置单元读进来。它读不动，`sfc` 自然就报「无法执行请求的操作」。这个细节我当时没意识到，后面才串起来。

中间还闹了个小乌龙。我敲 DISM 的时候漏打了冒号，结果：

```cmd
X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /RestoreHealth
错误: 87

DISM 未识别命令行选项 "/Image:C:\"。
```

错误 87 是「参数无效」，纯粹是我手滑把 `/Image:C:\` 敲成了 `/Image:C\`，全角冒号还是半角冒号也容易混。这种小错误最浪费时间，因为第一反应是去查 DISM 是不是坏了，折腾半天才发现是自己打错了字。

自动修复也没给出有效结论。启动修复一共跑了三次，`SrtTrail.txt` 开头记着：

```cmd
上一次成功启动的时间: 2026/11/1 9:32:11 (GMT)
尝试修复次数: 64
```

每次会话跑十来个检测项，前面全是 `0x0`，只有最后一项翻车：

```cmd
会话 1   名称: 检查已安装的 LCU   结果: 成功完成。错误代码 = 0x43
会话 2   根本原因数 = 1
         找到的根本原因:
         启动修复已经尝试多次，但仍无法确定问题的原因。
会话 3   名称: 检查已安装的 LCU   结果: 成功完成。错误代码 = 0x14c
```

「检查已安装的 LCU」要打开 CBS 组件存储，这一步报错，说明组件存储加载失败。会话 3 那个 `0x14c` 我盯着看了很久，它和后面 DISM 报的错一模一样，这是同一条病根在不同工具里反复冒头。

到这里我把「引导坏了」这个假设排除了：ESP 是好的，BCD 是好的，`winload.efi` 也在，启动修复跑的十几个检测项全部通过。问题在更下面的地方。

于是我开始查日志。`SrtTrail.txt` 之外，还有一个 `DISMRepairLogFile.txt`，它记录了自动修复和离线 DISM 的每一次注册表加载。里面最关键的是这几行：

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

12 次加载失败，对象全是 `SECURITY`，错误码全是 `0xd000014c`，时间横跨 11 月 1 日下午到 11 月 2 日下午，将近 22 个小时。最后一条 `SYSTEM` 的 `0xd0000043` 是唯一的例外，那是共享冲突，我后面会解释它是我自己操作留下的痕迹。

结合这份日志和另一个惊人发现，我做了第一版判断。那个发现是：**C 盘只剩 100 多 MB 空间了**。我清掉桌面上一些不重要的大文件之后，才回到 8.9 GB 左右。

把「C 盘被写满」和「SECURITY 加载失败」放到一起，我当时的猜测是：Windows 更新在后台写 SECURITY 的时候磁盘空间耗尽，写操作被截断，导致这个 hive 损坏。顺着这个思路，最直接的「免重装」方案，就是把损坏的 SECURITY 换掉。我从自己电脑的 `C:\Windows\System32\config\` 里复制了一份结构正常的 SECURITY 过来顶替。

这一步后来被证明方向只对了一半。文件确实该修，但「换一份」恰恰是最错的做法。

## Agent 深入排查

换掉 SECURITY 之后，`RevertPendingActions` 居然显示「操作成功完成」，但重启依然报 `0xc0000001`。我意识到事情没这么简单，于是用一个带网络的 FirPE 环境，装上 AI 编程助手，让它帮我做了一次彻底排查。下面这些结论，是它和我一起逐条核对出来的。

### 从日志与转储文件锁定真凶

先说时间线。10 月 23 日那天，CBS 日志里连写了三行：

```cmd
2026-10-23 18:36:21, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:23, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:25, Info  CBS  System volume has 0G free disk space
```

后面紧跟一句 `Maint: incomplete, interruptions: 1`。这是确凿证据：10 月 23 日那次更新维护，C 盘被写到 0 字节可用，事务没跑完就中断了。当时舍友没当回事，清掉几 GB 继续用，之后八九天一切正常，直到 11 月 1 日。

再往下，答案几乎写在崩溃转储里。`C:\Windows\Minidump\110226-9312-01.dmp` 的头部是这么读出来的：

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

`P4 = 0xC000014C`，这是 `STATUS_REGISTRY_CORRUPT`，注册表损坏。最后那行 UTF-16 字符串 `<SECURITY` 直接把目标指出来了：内核在启动阶段加载 SECURITY 配置单元的时候，判定它损坏，于是抛了 `0x74`。

顺带解释一句，`HiveLoadFromomFile` 里那个重复的 `om` 不是我抄错。那是内核日志字符串拼接留下的样子，原件就是这样。

到这里，DISM 日志里那 12 次 `0xd000014c` 也对上了。`0xd000014c` 就是 `0xC000014C` 带上客户端位，和转储里的 P4 是同一个错误。自动修复、DISM、内核，全都死在同一件事上：加载 SECURITY 失败。

### 为什么换上我的 SECURITY 还是开不了机

这里我要坦诚一个错误。之前我从自己电脑复制 SECURITY 顶上去，`RevertPendingActions` 确实显示成功了，我还一度以为修好了。结果重启还是 `0xc0000001`。

为什么 DISM 能过、内核却过不了？因为 DISM 只检查文件结构合不合法，它不检查这份文件是不是这台机器的。而内核启动时要做的检查严格得多。

把顶上去的那份 SECURITY 读出来看：

```cmd
计算机名   HXCN-WIN
机器 SID   S-1-5-21-1262172508-...
```

`HXCN-WIN` 是我自己电脑的计算机名。而舍友本机 SAM 里写的是：

```cmd
计算机名   LAPTOP-VQSR6OMV
机器 SID   S-1-5-21-4291209427-303460211-4247354471
```

两份文件对不上。Windows 的本地安全机构（LSA）在开机时会把 SECURITY 和 SAM 的机器 SID 拿出来比对，要求它们一致，不一致就直接拒绝。更致命的是，我那份 SECURITY 的 `Policy\Secrets` 里是 `NL$KM`、`MouseWithoutBorders` 之类我自己的东西，**没有舍友机器的 `DPAPI_SYSTEM`**。

`DPAPI_SYSTEM` 是这台机器的主加密密钥，浏览器保存的密码、EFS 证书、凭据管理器里的东西，全是用它加密的。换了没有它的 SECURITY，就算侥幸过了 SID 校验，这些数据也永久解不开了。

所以那次「修复」是彻头彻尾的假象。它把问题从「文件加载不了」换成了「文件不是这台机器的」，而后者更难发现，因为所有工具都会告诉你一切正常。真正该做的是把舍友自己的 SECURITY 修好，而不是用别人的顶替。

好消息是，舍友自己那份 SECURITY 一直躺在 `C:\Windows\System32\config\CorruptBak\` 里，65,536 字节，10 月 31 日的副本。绕了一圈，还是得回到它。

### 序列号 17965 与 17964：两字节的脏标志

注册表不是一个单独的文件，它被拆成好几个「配置单元」（hive），放在 `C:\Windows\System32\config\` 下：`SYSTEM`（引导配置、驱动、服务）、`SOFTWARE`（已装软件）、`SECURITY`（LSA 机密、SID）、`SAM`（本地账户）、`DEFAULT`、`DRIVERS`、`COMPONENTS`（组件存储）、`ELAM`、`BBI`。每个 hive 的头部是一段固定结构：

```cmd
偏移 0x000   "regf"                签名
偏移 0x004   seq1                  主序列号
偏移 0x008   seq2                  次序列号
偏移 0x01C   type                  hive 类型
偏移 0x024   root                  根键 nk 单元的偏移
偏移 0x028   hbins                 bins 区总字节数
偏移 0x1FC   checksum              头部校验和
```

其中 `seq1` 和 `seq2` 是一对序列号，负责保证写入的一致性。正常关闭时，两次写会同步，`seq1 == seq2`。如果写入事务没跑完就断电或磁盘写满，就会留下 `seq1 != seq2`，这个状态叫「脏标志」，等于告诉内核「这个 hive 上次没写完」。

读舍友的原始 SECURITY：

```cmd
CorruptBak\SECURITY   65,536 B   seq 17965 / 17964   校验和 0xb3d51b08（自洽）
```

`17965 / 17964`，脏的。按常理，内核遇到脏 hive 会去重放事务日志来追平序列号。看看日志：

```cmd
SECURITY.LOG1   49,152 B   seq 208   （2022 年的陈旧日志）
SECURITY.LOG2    8,192 B   seq 17963 （比 hive 落后 2 个事务）
```

hive 是 17965/17964，能重放的日志序列必须是 17965 或 17964。可 `LOG1` 停在 208，`LOG2` 停在 17963，两个都对不上。日志链断了，重放不可能。于是内核只能报 `STATUS_REGISTRY_CORRUPT`，蓝屏。

这里有个关键点必须验证：到底是「脏标志」本身致命，还是「日志不能重放」致命？为了搞清楚，我在 D 盘上用副本把各种组合都试了一遍，全程没碰 C 盘一个字节：

| 用例 | hive 状态 | 附带日志 | `reg load` |
|---|---|---|---|
| s1 | 脏 17965/17964 | 无 | **失败** |
| s2 | 脏 17965/17964 | 0 字节 LOG1/LOG2 | **失败** |
| s3 | 脏 17965/17964 | 陈旧 LOG1(208)+LOG2(17963) | **失败** |
| t1 | 脏，seq2 再减 2（17965/17963） | 无 | **失败** |
| t2 | seq2 := seq1（17964/17964） | 无 | 成功 |
| i | 补丁后 17965/17965 | 无 | 成功 |
| j | 补丁后 17965/17965 | 陈旧 LOG1+LOG2 原样保留 | 成功 |
| s4 | seq 相等但校验和不重算 | 无 | **失败** |

结论干净得让人意外：

- 只要 `seq1 != seq2`，加载就失败，跟日志在不在、是不是 0 字节、能不能重放都没关系。脏标志本身即致命。
- 只要 `seq1 == seq2` 且头部校验和正确，陈旧日志原样留着也不影响。
- 校验和必须重算，只改序列号不改校验和一样失败。

所以修复面只有两个字段：

```cmd
源   C:\Windows\System32\config\CorruptBak\SECURITY    65,536 B   17965 / 17964
改   0x008 处写回 17965                                            （清脏标志）
改   0x1FC 处重算校验和   0xb3d51b08  ->  0xb3d51b09
```

为了确认没改坏东西，我把修好的文件和原件做了逐项比对：两边都是 166 个键、164 个值，键名、值名、值类型、值数据完全一致，0 处差异。结构走查也干净：166 个 nk 单元的父指针全对，33 个子键索引单元都是合法的 `lh`，2 个安全描述符完整，没有越界。

而且这份 hive 确实是舍友本机的：

```cmd
PolAcDmN   LAPTOP-VQSR6OMV                        ← 与 SYSTEM\ComputerName 一致
PolAcDmS   S-1-5-21-4291209427-303460211-4247354471  ← 与 SAM 域 SID 一致
Policy\Secrets   8 条，含 DPAPI_SYSTEM、RasDialParams!...-1001#0、6 个 MSSQL/SQL 服务账户
根键 LastWriteTime   2026-11-01 09:32:10 UTC       ← 与"上次成功启动 11/1 17:32 本地"完全吻合
```

根键的 LastWriteTime 和 `SrtTrail.txt` 里记录的最后一次成功启动时间完全吻合，这进一步说明 SECURITY 的数据区根本没坏，坏的只是头部那两个字节。

### 发现了 BBI 和孤儿驱动问题

排查到这里，SECURITY 的问题清楚了。但九个 hive 里还有一个也是「结构上不可加载」的：`BBI`，1,310,720 字节，序列号 `53232/53231`，同样脏，`LOG1/LOG2` 同样都是 0 字节。

`BBI` 是 Boot Environment Infrastructure 的作业队列，里面是 `WorkItems`（81 条）、`PackageImportance`（1431 条）、`Events`（136 条）。它不参与内核引导，10 月 31 日就已经脏了，11 月 1 日照样开机。但它既然和 SECURITY 一样带着脏标志，就顺手用同样的方法清掉。

查启动驱动的时候，还翻出一个真缺陷：

```cmd
HKLM\SYSTEM\ControlSet001\Services\softaal
  ImagePath    = \??\C:\Program Files (x86)\Tencent\QQPCMgr\15.1.22354.301\softaal64_ev.sys
  Start        = 1  (SERVICE_SYSTEM_START)
  ErrorControl = 0
```

`softaal` 是腾讯电脑管家的驱动。电脑管家升级到 15.6 之后，旧的 15.1 目录已经没了，这个服务还指着旧路径。`Start=1` 意味着每次开机都会尝试加载，而 `ErrorControl=0` 意味着加载失败会被静默忽略。所以它不会导致蓝屏，只是每次开机白试一次。改成 `Start=4` 禁用掉。

顺带还发现几个 `Start >= 2` 的孤儿驱动：`ksapi64`、`ROGKB`、`ROGMS`、`TSSKX64`。它们都在用户态起来之后才加载，不影响这次开机，其中 `TSSKX64` 挺典型：注册表里写的是 `tsskx64_EV.sys`，磁盘上只有 `TSSKX64.sys`，大小写和 `_EV` 后缀都不对，腾讯的安装程序留了个半成品。这些我先记下来，不着急动。

## 解决

### 镜像里那份 SYSTEM 只有 9 MB，为什么还是要用原版镜像

我手上有一份 `Win11_23H2_Chinese_Simplified_x64v2.iso`，版本 22631.2861。一开始我想当然地觉得，直接从镜像里取一份干净的 hive 覆盖不就完了。试过之后发现这条路走不通，而且走通了反而会闯祸。

镜像里的 `Windows\System32\config\` 是「通用安装态」，跟任何具体机器都没关系：

| hive | 镜像内 | 本机 | 覆盖后果 |
|---|---|---|---|
| SYSTEM | 9175040 B / 661 个服务 / `MINWINPC` | 32243712 B / 846 个服务 / `LAPTOP-VQSR6OMV` | 全部驱动服务和 Enum 设备树丢失，必然 INACCESSIBLE_BOOT_DEVICE |
| SAM | 8192 B（空库） | 131072 B / 5 个账户 | 账户全丢 |
| SECURITY | 8192 B（空） | 65536 B | LSA 机密全丢，DPAPI 数据永久打不开 |
| SOFTWARE | 66584576 B | 117440512 B | 所有已装软件的注册信息丢失 |
| BBI | 8192 B（空队列） | 1310720 B | 这个可以用 |

镜像里的 SYSTEM 只有 9 MB、661 个服务、计算机名还是 `MINWINPC`，这是给全新安装用的空壳，里面根本没有这台机器的硬件驱动和设备树。拿它覆盖，开机直接 `INACCESSIBLE_BOOT_DEVICE`，因为存储控制器驱动全没了。SAM 和 SECURITY 更是 8 KB 的空库，覆盖等于账户全丢、DPAPI 数据永久打不开。

就地升级修复也不行。镜像 22631.2861 比已装的 22631.5768 版本更低，setup 会直接以「版本更低」拒绝。

那镜像就没用了吗？有用，但要换个用法。它的正确价值是当「比对基线」：拿镜像里那些通用配置来对照本机，确认哪些差异是正常的、哪些是缺陷。比如有些内核驱动（`wof`、`null` 这类）在镜像里就没有 `ImagePath`，本机也没有，这就不是损坏，是正常现象。有了这个基线，排查时才不会把正常差异误判成损坏。

### 完整备份，然后只改那两个字节

动手之前，先把 `config` 整个目录备份到 D 盘：43 个文件、238.1 MB，包含 9 个 hive 和全部 `.LOG1/.LOG2/.TM.blf/.regtrans-ms`，逐文件做了 SHA-256 比对确认字节一致。这样万一改坏了，还能原样滚回来。

然后按顺序执行：

```cmd
1) SECURITY   CorruptBak\SECURITY -> 改 0x008 / 0x1FC -> reg load 自检 -> 写回 C:
2) SECURITY.LOG1 / LOG2 -> D:\_fix\quarantine\   （隔离，消除歧义）
3) BBI        同 SECURITY 处理，53232/53231 -> 53232/53232
4) SYSTEM     挂载后把 softaal 的 Start 改成 4
```

关于第 2 步，隔离日志有必要吗？严格说不是必须的。前面实验用例 `j` 已经证明，hive 干净时内核根本不看那些陈旧日志。但把 `SECURITY.LOG1`（seq 208）和 `SECURITY.LOG2`（seq 17963）移走，能消除一个隐患：以后任何工具读到这些日志，都可能产生歧义。移走之后，内核重新挂载时会自己重建一对干净的日志。所以这是「图个干净」的步骤，不是「不隔离就开不了机」的步骤。

### 清理休眠文件与更新残留

还有几样纯占地方的东西要清。

`C:\hiberfil.sys` 有 6,715,396,096 字节（6.25 GiB），前 4 KB 全是 0。这意味着它的头部已经废了，`winresume` 不可能从里面恢复任何休眠状态，BCD 里四个 `resumeobject` 指向它只会让引导器白试一次。这文件删掉没有任何代价：

```cmd
del C:\hiberfil.sys
```

再清掉几个更新和重置的遗留目录：`$WinREAgent`（约 1771 MB）、`$Windows.~BT`（56.7 MB）、`$SysReset`（0.3 MB）、`SoftwareDistribution\Download`（65.5 MB）。删之前我确认过没有挂起的安装事务（`SetupType=0`、`WinSxS\pending.xml` 不存在），这些目录删了不会影响启动。

到这里，C 盘可用空间从 8.9 GB 回到了约 16.5 GB。如果一开始就清干净，后面这些破事可能压根不会发生。

### 修复后全量复查

修完不能拍脑袋说好了，我做了四层复查。

第一层，九个 hive 逐个做结构走查：头签名、序列号、校验和，hbin 链完整性，从根键一层层遍历（父指针、`li`/`lf`/`lh`/`ri` 子键表、值表），最后统计孤儿键：

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

父指针错 0、子键表错 0、值表错 0、hbin 链断 0、孤儿键 0，九个 hive 全部能 `reg load`。看到这一排数字，我才敢确认：修的是脏标志，没碰任何数据。

这里要补一句，复查时 `SECURITY` 的序列号显示 `17970/17970`，比我刚修完的 `17965/17965` 又涨了几位。这是正常的：`reg load` / `reg unload` 自检本身也会让内核把序列号 +1，并给每个 `nk` 单元打上挂载标志位。我做过字节级比对，除了这些挂载标志和序列号，键名、值名、值数据一个字节都没变。

第二层，身份一致性。确认这份 SECURITY 就是本机的：

```cmd
PolAcDmN   LAPTOP-VQSR6OMV
PolAcDmS   S-1-5-21-4291209427-303460211-4247354471
ProfileList  S-1-5-21-...-1001  ->  C:\Users\admin
SAM 账户     admin / Administrator / DefaultAccount / Guest / WDAGUtilityAccount
Lsa boot key  TC463EF4966D8796     （由 JD+Skew1+GBG+Data 四个类名拼出）
```

这里有个有意思的细节：`ControlSet001\Control\Lsa` 下 `JD`/`Skew1`/`GBG`/`Data` 四个键的值都是空的，真正的系统密钥（SYSKEY）存在**类名**里。这也是为什么很多第三方工具读不出这个 boot key。

第三层，最硬的一条证据。修复前，`dism /Image:C:\ /Get-Packages` 会因为加载 SECURITY 失败直接报 `0xd000014c`；修复后：

```cmd
部署映像服务和管理工具
版本: 10.0.22621.1
映像版本: 10.0.22631.5768
...
操作成功完成。
```

83 条包，状态全部「已安装」，没有 Pending。同一条命令，从「直接失败」变成「完整走完」，因为它完整跑了一遍 CBS 组件存储的初始化，而 CBS 初始化就是要按顺序加载 SOFTWARE、SYSTEM、SECURITY。这一步通了，比任何 `reg load` 自检都有说服力。`dism /Cleanup-Image /ScanHealth` 也返回「未检测到组件存储损坏」。

第四层，引导链和运行环境：

```cmd
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

引导链完整，131 个启动期驱动一个不缺，存储类过滤器全是系统默认值，卷没标脏。到这里，静态能查的全查完了。

## 尾声

### 清理 InFlight 临时目录与顺利开机

复查的时候还发现一个白白吃空间的角落。`C:\Windows\WinSxS\Temp\InFlight` 堆了 5,336 个目录、约 1.5 GB，时间戳从 2023 年一直延续到 2026 年 11 月 2 日，全是 DISM 和更新组件没回收的暂存副本。不占关键路径，但白吃空间。

更哭笑不得的是，我自己排查过程中跑的那几次 `DISM /ScanHealth` 和 `/Get-Packages`，又在这个目录下留了 7,335 个目录、约 1.4 GB 的临时文件，把刚腾出来的空间又吃回去一块。查完把这批删掉，C 盘可用空间从 16.0 GB 回到了 16.5 GB。

给下次留点余量，这次故障的起点就是 C 盘写满。

九个 hive 全干净、全部可加载，组件存储无损坏，引导链完整，没有任何挂起操作。重启之后，机器顺利进了系统，一路到桌面。

复盘一下：真正的修复动作，其实只有两个字段、几个字节。SECURITY 的 `0x008` 写回序列号，`0x1FC` 重算校验和；BBI 同样处理。剩下全是排查和验证。但这几个字节背后，是把「脏标志」这个机理吃透才敢动的。

### 用注册表把自动更新暂停 1000 周

最后说一句题外话，也是我给舍友的最终建议。

这台机器会蓝屏，直接原因是 C 盘被写满。但 C 盘为什么会被写满？除了空间本来就不大，还因为 Windows 11 那套停不下来的自动更新。

过去一年里，Windows 11 的更新翻车已经不是新闻。2025 年 8 月的 `KB5063878` 让一批群联、英韧主控的 SSD 在大文件写入时掉盘，甚至分区损坏；同月的 `KB5063875` 直接搞崩了系统重置和恢复功能。10 月的 `KB5066835` 更离谱，一次性打断了 `localhost` 本地连接、资源管理器预览窗格、智能卡认证，还把 WinRE 恢复环境里的 USB 键鼠驱动弄残了，逼得微软发带外补丁。2026 年 1 月的 `KB5074109` 让部分机器报 `UNMOUNTABLE_BOOT_VOLUME` 无法开机，2 月的 `KB5077181` 又带来启动循环、登录界面损坏和 DHCP 断网。

每一次更新都号称修复问题，又顺手引入新的问题。对于一台 C 盘本就不宽裕的机器，自动更新在后台静默下载、解压、写盘，就是悬在头上的一把刀。

所以我建议：用注册表把自动更新暂停掉，而不是用第三方工具去删更新组件。第三方工具往往直接移除 Windows Update 组件，容易把系统组件一起搞坏；注册表暂停只是把更新的「暂停」期限拉长到 1000 周，组件原封不动，想恢复随时可以恢复。

做法很简单，新建一个 txt 文件，把下面内容粘进去，改后缀名为 `.reg`，双击导入：

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

`FlightSettingsMaxPauseDays` 是 `0x1b58`，十进制就是 7000 天，约 19 年。那几组 `StartTime` / `EndTime` 把功能更新、质量更新、总更新的暂停窗口都拉到了 2042 年。

哪天想恢复更新了，再导入下面这份解除文件就行：

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

值后面的 `=-` 是删除该键值的意思，导入后暂停状态清空，Windows 更新恢复默认。

不过话说回来，暂停更新是治标。真正的病根是 C 盘太小。我最后给舍友留了句实在话：要么把数据挪一挪重新分个更大的 C 盘，要么以后勤清理。否则这次是 SECURITY 被写坏，下次不定是哪个 hive。
