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
description: 一次 Win11 23H2 因 C 盘写满引发的 0x74 BAD_SYSTEM_CONFIG_INFO 抢修记录。从 BitLocker 状态、bcdboot/bootrec 全线失败、DISM 反复 0xd000014c，到定位 SECURITY 注册表配置单元的脏标志、逐字节比对、受控加载实验，最后靠改两个字段把 Hive 修回可加载状态。适合遇到 C 盘爆满、系统无法开机或注册表损坏的朋友参考。
---

我一直认为，对于绝大多数普通用户而言，一块硬盘配一个分区足够了；如果有好几块硬盘，那就一个硬盘一个分区；如果机器里只有一块硬盘，顶多切成 C 盘和 D 盘。其中 C 盘至少要留 200 GB 到 300 GB，如果你是重度使用、常年装大型软件，512 GB 都不嫌多。

为什么这么执着？因为 Windows 系统天生往 C 盘塞东西。就算你把软件都装在 D 盘、E 盘，各种缓存、临时文件、Windows Update 更新组件、用户配置文件照样会占用 C 盘。C 盘太小、剩余空间太少，很多软件会莫名其妙崩溃，严重时甚至连系统都无法开机。另一个极端是，有人为了“整洁”把一个 1 TB 硬盘切成四五个小分区，结果碰到一个 60 GB 的大文件或新出的 3A 游戏，几个分区加起来明明有剩余空间，却没有一个分区单独装得下，只能来回挪文件。

总有人反驳我说：“软件装在 C 盘，重装系统数据就全丢了。”实际上恰恰相反，重装系统后装在 D 盘里的那些软件，十有八九会因为注册表丢失、缺少运行库和配置文件而无法正常启动，你照样得挨个重新安装。重装前真正需要备份的，只是微信和 QQ 的聊天记录（通常在 `C:\Users\<用户名>\文档`）、下载文件夹（`C:\Users\<用户名>\下载`）、图片视频、桌面文件、浏览器收藏夹和密码，以及你的开始菜单与用户配置文件 `C:\Users\<用户名>\NTUSER.DAT`（留着它方便对照之前装了哪些软件）。如果系统盘开了 BitLocker 设备加密，记得事先解锁或者把恢复密钥导出备份。做完这些直接重装，补齐软件再把文件还原回去，远比折腾分区扩容省心。

十多年前我刚学会折腾电脑的时候，我爸那一辈人就喜欢把一块硬盘分成四个分区。这个习惯可能源于当年各种盗版 Ghost 一键装机镜像，普遍支持一键把硬盘分成四个区，装完系统直接默认这种布局。如今很多在长辈推荐下买电脑的同辈，拿到的机器同样被分成好几个很小的分区。我经常遇到 C 盘空间不足的同学跑过来求助，每次都只能先帮他们把其他盘里的文件集中一下，腾出空间来给 C 盘续命。

如果你想反驳这套观点，今天舍友这台电脑莫名其妙蓝屏的例子，就是最好的反例。

## 猜测和尝试

### 基本情况

舍友这台笔记本是华硕的，出厂预装 Windows 11 家庭中文版，一路跟着自动更新升到了 23H2（10.0.22631.5768）。这台机器只有一块 1 TB 的 SSD，被切成了好几块：150 GB 的 C 盘，两个 389 GB 的 D 盘和 E 盘，外加几个出厂自带的恢复分区。要命的是，MATLAB、SQL Server 2022、Office 2014 这些重型软件，还有一整个 Steam 游戏库，全都堆在 C 盘里。出事那天毫无征兆，机器突然就蓝屏了，屏幕上显示 `BAD_SYSTEM_CONFIG_INFO`（0x74），自动重启之后接着蓝屏，陷入无限循环。

![蓝屏崩溃界面](bsod-bad-system-config-info.svg)

Windows 连续几次启动失败之后，会自动触发内置的“启动修复”功能。启动修复在后台尝试诊断并修复启动问题，但从截图可以看到，它不出意外地失败了，只提示“启动修复无法修复你的电脑”，并给出日志路径 `C:\Windows\System32\Logfiles\Srt\SrtTrail.txt`。因为这台电脑的 C 盘空间长期不足，系统保护根本没开，也就没有任何可用的系统还原点可以回退。

![启动修复失败](startup-repair-failed.svg)

舍友先用豆包这类通用 AI 助手搜了一圈，在恢复环境里尝试了最常规的 `chkdsk` 和 `sfc` 检查，结果一无所获。既然 `chkdsk` 和 `sfc` 都没查出硬件和核心系统文件的物理损坏，我第一反应是怀疑系统的 UEFI 引导配置或者启动管理器出了问题。于是用 Ventoy U 盘引导进 WinPE，打开 PE 系统里的 DISM++ 准备做一次引导修复。结果 DISM++ 一启动就弹窗提示“试图加载格式不准确的格式”，连最基本的系统镜像信息都没法正常读取。我以为是引导彻底崩了，让 DISM++ 强制修复引导并写入 EFI 分区后重启电脑，结果屏幕上直接弹出恢复错误 `0xc0000001`，蓝屏反倒没了。

![恢复错误界面 0xc0000001](recovery-error-0xc0000001.svg)

`0xc0000001` 是一个非常泛化的 `STATUS_UNSUCCESSFUL` 状态码，字面意思就是“引导阶段有东西没起来”，至于具体是什么，这个错误码本身提供不了任何信息。不过 DISM++ 弹出的那个“试图加载格式不准确的格式”提示，其实是个非常关键的线索。DISM++ 这类系统维护工具在打开离线系统时，需要挂载并读取 `C:\Windows\System32\config` 下的注册表配置单元（Hive），比如 `SYSTEM`、`SOFTWARE`、`SECURITY` 这些文件。如果它们损坏，DISM++ 就会报这种“格式不准确”的错。这也暗示了最初的 `BAD_SYSTEM_CONFIG_INFO` 蓝屏，大概率就是某个注册表文件出了问题。

### 关掉 BitLocker

在 PE 里进行任何系统文件改动之前，必须先确认磁盘有没有被 BitLocker 设备加密锁住。华硕这种出厂预装 Windows 11 的 OEM 笔记本，普遍默认开启了“设备加密”的预置启用状态，但舍友这台机器登录的是本地账户，从来没有绑定过微软账号，恢复密钥根本没上传到云端。如果此时在 PE 里改动引导文件或系统分区，下一次重启极有可能会触发 TPM 完整性校验失败，要求输入恢复密钥。到时候没有微软账号，密钥无处可寻，C 盘的数据就彻底锁死了。

先用 `manage-bde -status C:` 查看加密状态：

```cmd
X:\Windows\System32>manage-bde -status C:

保护状态:      保护关闭
锁定状态:      已解锁
标识字段:      无
自动解锁:      已禁用
密钥保护器:    找不到
```

“密钥保护器：找不到”听起来像报错，实际上是个天大的好消息。没有密钥保护器，说明这台电脑的设备加密功能从来没有被真正激活过，磁盘数据目前是明文 NTFS 状态，PE 里可以直接读写 C 盘，不存在锁盘风险。如果不放心，还可以用 `manage-bde -protectors -get C:` 专门确认一下：

```cmd
X:\Windows\System32>manage-bde -protectors -get C:
卷 C: [OS]
所有密钥保护器

错误: 找不到密钥保护器。
```

接下来用 `diskpart` 的 `list vol` 命令查看磁盘分区布局，确认 ESP 引导分区、恢复分区、数据盘的分区号和盘符：

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

布局一目了然：C 盘 150 GB 是系统盘，D 盘和 E 盘各 389 GB 是数据盘，260 MB 的 FAT32 分区是存放 EFI 启动文件的 ESP，950 MB 的 NTFS 分区存放 WinRE 恢复镜像。为了防止后续修复引导或修改注册表时 BitLocker 自动接管导致磁盘意外锁死，我索性把 C、D、E 三个分区全部彻底关闭解密：

```cmd
manage-bde -off C:
manage-bde -off D:
manage-bde -off E:
```

跑完之后再次执行 `manage-bde -status`，直到状态显示“完全解密”为止，这样后续任何操作都不会再触发 BitLocker 的密钥校验。

### 常规手段尝试

BitLocker 确认解除后，先跑一遍文件系统检查，排除磁盘坏道和文件系统元数据损坏的可能：

```cmd
X:\Windows\System32>chkdsk C: /f /r

Windows 已扫描文件系统并且没有发现问题。
无需采取进一步操作。

总共有  157286727 KB 磁盘空间。
...
磁盘上 15979136 KB 可用。
每个分配单元中有     4096 字节。
坏扇区           0 KB。
总持续时间: 3.01 分钟 (180616 毫秒)。
```

`chkdsk` 跑完五个阶段，全部正常，0 个坏扇区。这说明 C 盘的 NTFS 文件系统本身没有损坏，接下来就该修复引导。先用 `diskpart` 给 260 MB 的 ESP 分区分配一个盘符 `S:`，然后执行 `bcdboot` 命令，把 C 盘系统里的引导文件和启动配置数据（BCD）重新写入 ESP：

```cmd
DISKPART> select volume 4
DISKPART> assign letter=S
DISKPART> exit

X:\Windows\System32>bcdboot C:\Windows /s S: /f UEFI /l zh-cn
已成功创建启动文件。
```

`bcdboot` 成功把启动文件写进了 ESP，`S:\EFI\Boot\bootx64.efi` 存在，大小 1,698,760 字节。为了确保 UEFI 固件能找到默认引导项，我还手动把 `S:\EFI\Microsoft\Boot\bootmgfw.efi` 复制覆盖到了 `S:\EFI\Boot\bootx64.efi`。引导文件写完之后，再用 `bootrec` 修复主引导记录并扫描操作系统：

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

问题开始显现了。`bcdboot` 明明已经成功写入了引导文件，但 `bootrec /scanos` 扫描整个磁盘，却连一个 Windows 安装都找不到，`bootrec /fixboot` 也直接报“拒绝访问”。`bootrec` 这个工具在扫描磁盘时，需要读取并解析目标系统 `C:\Windows\System32\config` 下的离线注册表，确认卷映射关系和存储控制器配置。它一个安装都识别不出来，往往意味着这些核心的注册表配置单元已经损坏到无法被正常挂载的程度。不过当时我没敢立刻下结论，毕竟在 UEFI 系统上，`bootrec /fixboot` 报“拒绝访问”是出了名的玄学。

系统文件检查也不顺利。`sfc /scannow /offbootdir=C:\ /offwindir=C:\Windows` 直接提示“Windows 资源保护无法执行请求的操作”。而离线 DISM 镜像修复更是离谱：

```cmd
X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /RestoreHealth
错误: 87

DISM 未识别命令行选项 "/Image:C:\"。
```

这个“错误 87，未识别 `/Image:C:\`”后来折腾了半天才发现，是我在 PE 的命令行里输入时漏打了一个冒号，属于纯手误，跟系统损坏无关。

现在常规手段几乎试遍了，文件系统是好的，引导文件是好的，但 `bootrec` 识别不到安装，`sfc` 和 `dism` 又接连报错。这时候必须看日志了。PE 里有两个关键的日志文件：`C:\Windows\System32\Logfiles\Srt\SrtTrail.txt` 记录了 Windows 启动修复的详细过程，`C:\Windows\System32\Logfiles\Srt\DISMRepairLogFile.txt` 记录了启动修复在尝试调用 DISM 修复组件存储时的底层错误。

先分析 `SrtTrail.txt`，这份 UTF-16 格式的日志开头记录着“上一次成功启动的时间: 2026/11/1 9:32:11 (GMT)”，“尝试修复次数: 64”。可以看到启动修复跑了一整套磁盘、卷内容、启动管理器的测试，前面全部通过，最后卡在“检查已安装的 LCU”（LCU 是最新累积更新）上，第一会话报错 `0x43`，第三会话报错 `0x14c`：

```cmd
名称: 检查已安装的 LCU
结果: 成功完成。错误代码 =  0x43

名称: 检查已安装的 LCU
结果: 成功完成。错误代码 =  0x14c
```

再结合 `DISMRepairLogFile.txt` 里最关键的一条报错：

```cmd
Failed to load offline SYSTEM hive from '...SYSTEM' ... [HRESULT = 0xd0000043 - NTSTATUS Error]
```

看到这条日志，我和豆包当时的第一判断是：最近一次 Windows 累积更新在安装过程中被打断，导致 `SYSTEM` 注册表单元里的当前控制集发生了逻辑冲突，进而引发蓝屏。而 `0xd0000043` 对应的 NTSTATUS 状态码是 `STATUS_SHARING_VIOLATION`（共享冲突），看起来像是 `SYSTEM` 文件被其他进程占用了。

顺着这个“更新损坏 `SYSTEM`”的猜想，开始尝试回滚挂起的更新。先用 `reg load` 手动挂载 `SYSTEM` 单元，看看能不能读取里面的控制集配置，顺便检查 `ControlSet002` 和 `LastKnownGood`（上一次正确启动）能否切换：

```cmd
X:\Windows\System32>reg load HKLM\TEMP C:\Windows\System32\config\SYSTEM
操作成功完成。
```

结果 `SYSTEM` 居然能正常挂载，这说明文件头和基本结构并没有彻底损坏。当时的真实原因是，我在 PE 里挂载了 `SYSTEM` 之后忘了用 `reg unload` 卸载，导致后续 DISM 和启动修复在尝试读取这个文件时遇到了句柄占用冲突，报错 `0xd0000043`。但当时我只看到了共享冲突，压根没往自己操作失误的方向想。同时，我也检查了一下 `config` 目录下所有注册表文件的体积，看有没有变成 0 字节：

```cmd
X:\Windows\System32>dir C:\Windows\System32\config

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
```

没有一个文件是 0 字节，几个核心的注册表单元大小都很正常。接下来直接回滚挂起的更新事务，并列出已安装的更新包准备卸载：

```cmd
X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /RevertPendingActions
部署映像服务和管理工具
版本: 10.0.22621.1
映像版本: 10.0.22631.5768

暂存目录大小可能不足以执行该操作。这可能会引起异常行为。
请使用 /ScratchDir 选项指向具有足够暂存空间的文件夹。推荐大小为至少 1024 MB。
正在从映像中还原挂起的操作...

错误: 0xd000014c

X:\Windows\System32>dism /Image:C:\ /Get-Packages /Format:Table
...
错误: 0xd000014c

DISM 失败。不执行任何操作。
```

两条命令都报 `0xd000014c`，同时还给出了一个警告：“暂存目录大小可能不足，请使用 `/ScratchDir` 指向其他分区，推荐至少 1024 MB。”这个警告其实是 WinPE 环境的锅，因为 PE 系统的内存虚拟盘 `X:\windows\TEMP` 只有几十 MB，根本不够 DISM 解压和回滚更新包。

`0xd000014c` 这个错误码其实就是 `0xC000014C`（`STATUS_REGISTRY_CORRUPT`，注册表已损坏）带上客户端位的包装。于是查看了 `X:\windows\Logs\DISM\dism.log`，发现 DISM 在初始化离线注册表仓库时，会按顺序加载三个核心的配置单元。从日志里能清楚看到，`SOFTWARE` 和 `SYSTEM` 都成功加载了，轮到第三个 `SECURITY` 时，稳定报错：

```cmd
CBS  Loading offline registry hive: SOFTWARE ... [成功]
CBS  Loading offline registry hive: SYSTEM ... [成功]
CBS  Loading offline registry hive: SECURITY ... 
CBS  Failed to load offline registry: ...SECURITY ... [HRESULT = 0xd000014c - NTSTATUS Error]
CBS  Failed to load offline SECURITY hive. [HRESULT = 0xd000014c - NTSTATUS Error]
```

到这里，问题已经非常明确了：损坏的根本不是 `SYSTEM`，而是 `SECURITY` 这个注册表配置单元。启动修复想读取“已安装的 LCU”列表，需要先打开 CBS 组件存储，而组件存储必须先加载 `SECURITY`，结果加载失败，整个修复流程全部卡死。

与此同时，我在盘符里随手查了一下空间，突然意识到一个被忽略的致命问题：C 盘只剩下 **100 多 MB** 的可用空间了。删除桌面上几个不重要的大文件之后，才勉强腾出 **8.9 GB** 左右。

现在整个事故的因果链基本清晰了：这台 150 GB 的 C 盘早就被大型软件和缓存塞满，Windows Update 在后台静默解压累积更新包时，因为物理空间彻底耗尽，写入 `SECURITY` 注册表配置单元的事务发生了截断或崩溃，直接把文件写坏了。既然知道了是 `SECURITY` 损坏，那最直观的思路就是：把损坏的 `SECURITY` 文件挪出来，然后从我自己的电脑上复制一份同版本的、结构完好的 `SECURITY` 文件顶上去。

于是我在 PE 命令行里执行了以下操作：把舍友电脑上那份损坏的 `SECURITY`（65,536 字节）移到 `CorruptBak\SECURITY` 里备份，然后把我自己电脑上的 `SECURITY` 文件复制过来顶替。接着指定空间充足的 D 盘作为 DISM 的暂存目录，重新执行回滚挂起更新的命令：

```cmd
X:\Windows\System32\config>move SECURITY CorruptBak\SECURITY
已移动        1 个文件。

X:\Windows\System32\config>copy CorruptBak\SECURITY SECURITY
已复制        1 个文件。

X:\Windows\System32\config>dism /Image:C:\ /ScratchDir:D:\backup /Cleanup-Image /RevertPendingActions

正在从映像中还原挂起的操作...
操作已完成。重新启动后将尝试还原挂起的操作。
操作成功完成。

X:\Windows\System32\config>if exist C:\Windows\WinSxS\pending.xml del /f /q C:\Windows\WinSxS\pending.xml
X:\Windows\System32\config>chkdsk C: /f
文件系统的类型是 NTFS。
```

神奇的是，换了文件之后，`RevertPendingActions` 从之前稳定报错的 `0xd000014c` 变成了“操作成功完成”。我心里一阵狂喜，觉得问题肯定解决了，删掉 `pending.xml` 后立刻重启电脑。结果现实泼了一盆冷水，电脑还是没能进入系统，重启之后屏幕上显示的依然是那个熟悉的恢复错误 `0xc0000001`。那一刻确实挺泄气的，DISM 明明已经能跑通了，按常理该好了。

## Agent 深入排查

既然自己折腾了大半天没有结果，我在带网络的 FirPE 环境里安装了 `oh-my-pi`（omp），决定让 AI Agent 在这个只读的环境里跑一遍彻底的审计和实验。重启后的 `0xc0000001` 意味着内核在启动早期加载配置单元时依然判定失败，而 DISM 能跑通只说明我换上去的那份 `SECURITY` 文件结构是合法的。现在需要回答的问题是：为什么一份结构完好的注册表文件，能让 DISM 正常工作，却无法让系统开机？以及，真正损坏的原始 `SECURITY` 文件，到底坏在哪里？

### 从日志与转储文件锁定真凶

Agent 首先把注意力放在了崩溃转储文件上。每次 Windows 蓝屏，内核都会在 `C:\Windows\Minidump` 里留下一份 `.dmp` 格式的内存转储文件。这台电脑只保留了一份转储：`110226-9312-01.dmp`，时间戳是 2026-11-02 07:36:19 UTC（换算成北京时间正好是 15:36:19）。Agent 用调试器读取了文件头，解析结果如下：

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

`bugcheck 0x74` 对应 `BAD_SYSTEM_CONFIG_INFO`，第四个参数 `P4 = 0xC000014C` 就是 `STATUS_REGISTRY_CORRUPT`（注册表已损坏）。最有价值的信息是转储文件里内嵌的字符串：ASCII 的 `HiveLoadFromomFile` 是内核加载注册表配置单元的内部函数名（那个重复的 `om` 是内核日志字符串拼接的残留，并不是抄错了），而 UTF-16 的 `<SECURITY` 直接把答案写在脸上了——内核在启动阶段加载 `SECURITY` 配置单元时判定其损坏。

接着 Agent 解析了 `DISMRepairLogFile.txt`，这份日志有 1974 行带时间戳的记录，横跨 2026 年 11 月 1 日 17:35 到 11 月 2 日 15:21。把所有加载失败的记录抽出来看：

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

整整 12 次失败，全部指向 `SECURITY`，错误码全部是 `0xd000014c`，前后跨度接近 22 个小时。最后那条针对 `SYSTEM` 的 `0xd0000043` 是唯一的例外，恰好发生在我手动挂载 `SYSTEM` 忘记卸载之后。这也证实了之前 `0x43` 的报错并不是 `SYSTEM` 本身的故障，而是我的操作留下的句柄占用痕迹。

然后 Agent 翻出了系统盘上的 `C:\Windows\Logs\CBS\CBS.log`，在里面找到了三条决定性的时间戳记录：

```cmd
2026-10-23 18:36:21, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:23, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:25, Info  CBS  System volume has 0G free disk space
```

2026 年 10 月 23 日 18 点 36 分，CBS 组件服务连续三次记录“系统盘可用空间为 0G”，后面紧跟一句 `Maint: incomplete, interruptions: 1`。这证明在那次 Windows 更新维护期间，C 盘确实被写满到了 0 字节可用。时间线完全对上了：10 月 23 日磁盘写满，`SECURITY` 配置单元在写入事务时因为空间耗尽而崩溃，留下了脏标志；此后的八九天，电脑一直带着这个隐患正常开机，直到 11 月 1 日那次重启，内核尝试加载这个有脏标志的 `SECURITY`，发现无法重放日志，直接抛出 `0x74` 蓝屏。

### 为什么换上我的 SECURITY 还是开不了机

现在需要解开一个谜题：为什么换成我的 `SECURITY` 文件后，DISM 的报错消失了，系统却依然无法启动？

答案是：**DISM 的检测逻辑，和 Windows 内核启动时的检测逻辑，根本不是一回事。** DISM 在离线挂载注册表配置单元时，主要检查的是文件的头签名（`regf`）、内部数据块（`hbin`）的结构完整性，以及头部校验和是否正确。它只关心这个文件“是不是一个合法的注册表文件”，完全不会去比对文件里面的内容是否属于这台具体的电脑。

Agent 把我顶上去的那份 `SECURITY` 文件解析了一遍，里面的关键身份标识对不上：

```cmd
计算机名   HXCN-WIN
机器 SID   S-1-5-21-1262172508-...
```

而舍友这台电脑的 `SAM`（安全账户管理器）配置单元里，记录的本机身份是：

```cmd
计算机名   LAPTOP-VQSR6OMV
机器 SID   S-1-5-21-4291209427-303460211-4247354471
```

这里的 `PolAcDmS` 是机器域安全标识符，`PolAcDmN` 是计算机名。更致命的是，我那份 `SECURITY` 文件的 `Policy\Secrets` 目录里，存的是我电脑上的机密项，比如 `NL$KM`、`DefaultPassword`、`MouseWithoutBorders`，但唯独**没有 `DPAPI_SYSTEM`**。

这就触发了两个致命的启动阻断：

第一，LSA（本地安全授权）子系统在启动阶段初始化时，必须比对 `SECURITY` 配置单元和 `SAM` 配置单元里的机器域 SID。如果发现两者不一致，LSA 会判定安全子系统配置损坏，直接拒绝继续初始化，系统随之蓝屏。

第二，`DPAPI_SYSTEM` 是 Windows DPAPI（数据保护 API）的主密钥。这台电脑上所有被加密的数据，比如浏览器保存的密码、凭据管理器里的账号密码、EFS 加密文件，全部都是用这个 `DPAPI_SYSTEM` 密钥加密的。而我那份 `SECURITY` 文件里根本没有舍友电脑的这个密钥。就算侥幸绕过 SID 校验开进系统，浏览器保存的所有密码和加密文件也都解不开了。

所以那次“修复”本质上是个假修复：它只是让 DISM 不再报错，却把问题从“文件结构损坏”升级成了“文件不属于这台机器”。好在舍友电脑真正的 `SECURITY` 原件并没有被覆盖，一直完好地躺在 `C:\Windows\System32\config\CorruptBak\SECURITY` 里，大小 65,536 字节，最后的修改时间是 10 月 31 日 21:18。

### 序列号 17965 与 17964：两字节的脏标志

既然知道了必须救回原始的 `SECURITY` 文件，接下来就要弄清楚它到底哪里坏了。Windows 注册表配置单元的文件格式是固定的，文件最前面的 4 KB 是一个固定结构的 `regf` 头部（Base Block），后面跟着若干个 `hbin` 数据块，每个 `hbin` 里存放实际的键值单元。Agent 直接解析了 `CorruptBak\SECURITY` 的文件头：

```cmd
偏移 0x000   "regf"                签名
偏移 0x004   seq1                  主序列号
偏移 0x008   seq2                  次序列号
偏移 0x01C   type                  hive 类型
偏移 0x024   root                  根键 nk 单元的偏移
偏移 0x028   hbins                 bins 区总字节数
偏移 0x1FC   checksum              头部校验和
```

文件头里有两个非常关键的四字节整数字段：`seq1`（主序列号）和 `seq2`（次序列号）。这两个序列号的作用是保障注册表数据的一致性：Windows 内核每次要写注册表时，会先把当前内存里的修改写入事务日志（`.LOG1` 或 `.LOG2`），然后把 `seq1` 加 1 写入文件头，再提交 `hbin` 数据块的修改，最后把 `seq2` 更新成和 `seq1` 相同。如果一次写入顺利完成，`seq1` 和 `seq2` 就是相等的。

文件头最后的 `0x1FC` 偏移处是一个校验和，算法很简单：把文件头从 `0x000` 到 `0x1F8` 的这 512 个字节，每 4 个字节当成一个 32 位无符号整数，全部异或起来。有个边界约定，如果异或结果是 `0xFFFFFFFF`，就写 `0xFFFFFFFE`；如果是 `0`，就写 `1`。

解析舍友电脑原始的 `SECURITY` 文件头，结果如下：

```cmd
CorruptBak\SECURITY   65,536 B   seq 17965 / 17964   校验和 0xb3d51b08（自洽）
```

`seq1 = 17965`，`seq2 = 17964`，两者相差 1。这就是所谓的“脏标志”（Dirty Flag）：它表示上一次注册表写入事务没有提交完，这个文件正处于数据不一致的中间状态。内核在启动时一旦发现 `seq1 != seq2`，就不能直接使用这个文件，必须先尝试通过事务日志进行重放（Replay），把数据追平到一致状态。

那事务日志去哪了？接着看 `SECURITY.LOG1` 和 `SECURITY.LOG2`：

```cmd
SECURITY.LOG1   49,152 B   seq 208   （2022 年的陈旧日志）
SECURITY.LOG2    8,192 B   seq 17963 （比 hive 落后 2 个事务）
```

`SECURITY.LOG1` 还停留在 2022 年，`SECURITY.LOG2` 落后当前版本 2 个事务。现在 `SECURITY` 文件的 `seq1` 是 17965，日志重放的规则是，日志文件的序列号必须正好等于 `seq1`（17965），或者 `seq1 - 1`（17964）。但这两份日志一个停在 208，一个停在 17963，**全都对不上**。日志链断了，重放根本不可能。这就是 10 月 23 日那次磁盘写满留下的后遗症：写入事务落盘了，但序列号同步和日志更新都失败了。

问题的本质已经很清楚了：`SECURITY` 文件的数据区其实没有被写坏，只是文件头里留下了一个没有清掉的脏标志，导致内核不敢用。

为了彻底确认这个猜想，Agent 在 D 盘上做了一组受控加载实验，用 `reg load` 命令测试了 10 种不同的组合，全程只操作副本，没有碰 C 盘一个字节：

| 用例 | hive 状态 | 附带日志 | `reg load` 结果 |
|---|---|---|---|
| s1 | 脏 17965/17964 | 无 | **失败** |
| s2 | 脏 17965/17964 | 0 字节 LOG1/LOG2 | **失败** |
| s3 | 脏 17965/17964 | 陈旧 LOG1(208)+LOG2(17963) | **失败** |
| t1 | 脏，seq2 再减 2（17965/17963） | 无 | **失败** |
| t2 | seq2 := seq1（17964/17964），重算校验和 | 无 | 成功 |
| i | 补丁后 17965/17965，重算校验和，无日志 | 无 | 成功 |
| j | 补丁后 17965/17965，重算校验和，保留陈旧 LOG1/LOG2 | 成功 |
| s4 | seq 相等（17965/17965），但不重算 `0x1FC` 校验和 | 无 | **失败** |

实验结论非常干净：

- 只要 `seq1 != seq2`，内核就拒绝加载，跟旁边有没有日志、日志是不是 0 字节、日志能不能重放，都没有任何关系。脏标志本身即致命。
- 只要 `seq1 == seq2` 且文件头校验和正确，就算把 2022 年的陈旧日志原封不动留在旁边，也完全不影响加载。
- 校验和必须跟着序列号一起重算，只改序列号不改校验和，一样失败。

### 发现了 BBI 和孤儿驱动问题

在审计所有注册表配置单元时，Agent 发现除了 `SECURITY` 之外，还有一个文件同样带着脏标志：`BBI`。`BBI` 是 Background Broker Infrastructure 的缩写，存放 Windows 后台任务和 UWP 应用的包状态队列，这个文件不是内核启动的必需组件。舍友这台电脑的 `BBI` 大小 1,310,720 字节，序列号停在 `53232/53231`，同样存在 `seq1 != seq2` 的脏标志，旁边的 `BBI.LOG1` 和 `BBI.LOG2` 都是 0 字节。

`BBI` 里面存有 `WorkItems`（81 条）、`PackageImportance`（1431 条）和 `Events`（136 条）。从文件时间戳看，这个文件在 10 月 31 日就已经脏了，但 11 月 1 日系统照样能开机，因为它的损坏不会导致蓝屏。不过既然这是除 `SECURITY` 之外唯一另一个结构上无法加载的配置单元，顺手把它修掉是最稳妥的。

除了 `BBI`，Agent 还排查了所有会在内核启动阶段加载的驱动。方法是遍历 `HKLM\SYSTEM\ControlSet001\Services` 下所有 `Start=0`（启动型）和 `Start=1`（系统型）的驱动服务，逐个核对它们指向的 `.sys` 文件是否存在。共检查了 131 个启动驱动，文件缺失 0 个。但是发现了一个真实的缺陷：

```cmd
HKLM\SYSTEM\ControlSet001\Services\softaal
  ImagePath    = \??\C:\Program Files (x86)\Tencent\QQPCMgr\15.1.22354.301\softaal64_ev.sys
  Start        = 1  (SERVICE_SYSTEM_START)
  ErrorControl = 0
```

`softaal` 是腾讯电脑管家（QQPCMgr）的一个内核驱动。问题是，腾讯电脑管家升级到了 15.6 版本之后，旧的 `15.1.22354.301` 目录已经被卸载程序删除了，但注册表里的 `softaal` 服务项还残留着，仍然指向旧目录里的 `softaal64_ev.sys`。这意味着每次开机，Windows 内核都会尝试加载一个根本不存在的驱动文件。

好在它的 `ErrorControl = 0`，表示加载失败会被忽略，不会导致蓝屏。但既然找到了这个残留，就应该把它清掉。处理方法是把 `Start` 的值从 `1` 改成 `4`，也就是禁用这个驱动服务。

另外还有几个不在启动阶段加载的孤儿驱动，比如 `ksapi64`（金山毒霸残留，`Start=2`）、`ROGKB` 和 `ROGMS`（华硕自带工具，`Start=3`）、`TSSKX64`（腾讯电脑管家另一个残留，`Start=3`）。特别值得一提的是 `TSSKX64`，注册表里写的文件名是 `tsskx64_EV.sys`，但磁盘上实际的文件是 `TSSKX64.sys`，大小写和 `_EV` 后缀都对不上，是腾讯卸载程序留下的半成品。这些驱动的 `Start` 都大于等于 2，内核启动时不会加载，不会影响这次开机。

## 解决

### 镜像里那份 SYSTEM 只有 9 MB，为什么还是要用原版镜像

在讨论如何修复 `SECURITY` 之前，需要先排除一个很多人都会想到的方案：直接用 Windows 官方安装镜像里的注册表文件覆盖掉损坏的文件。舍友电脑上正好有一份 `Win11_23H2_Chinese_Simplified_x64v2.iso` 镜像，版本是 22631.2861。我用 DISM 把这个镜像以只读模式挂载到了 D 盘，准备对比里面的内容。

挂载之后，我立刻发现这条路走不通。官方镜像里的 `Windows\System32\config` 目录，存放的是一份**通用安装态**的注册表，它不包含任何这台具体电脑的硬件和账户信息：

| 配置单元 | 镜像内 | 舍友电脑 | 直接覆盖的后果 |
|---|---|---|---|
| SYSTEM | 9,175,040 B / 661 个服务 / 计算机名 `MINWINPC` | 32,243,712 B / 846 个服务 / `LAPTOP-VQSR6OMV` | 全部驱动服务和设备树丢失，必然蓝屏 `INACCESSIBLE_BOOT_DEVICE` |
| SAM | 8,192 B（空账户库） | 131,072 B / 5 个账户 | 所有本地账户全丢，无法登录 |
| SECURITY | 8,192 B（空安全策略） | 65,536 B | LSA 机密和 DPAPI 主密钥全丢，所有加密数据永久打不开 |
| SOFTWARE | 66,584,576 B | 117,440,512 B | 所有已安装软件的注册信息丢失 |
| BBI | 8,192 B（空队列） | 1,310,720 B | 这个可以用 |

拿镜像里的 `SYSTEM` 覆盖本机，相当于让一台装着 MATLAB 和 SQL Server 的电脑，去用全新安装 Windows 时的默认驱动列表，100% 会报 `INACCESSIBLE_BOOT_DEVICE` 蓝屏。至于镜像里的 `SAM` 和 `SECURITY`，本来就是空的，覆盖过去等于把所有账户和密钥清空。镜像版本 22631.2861 低于已安装的 22631.5768，想做就地升级修复也会被安装程序直接拒绝。

那这份镜像还有用吗？有。它的正确用法是当**比对基线**。比如，我在排查启动驱动时发现，舍友电脑的 `SYSTEM` 里有几个基础内核服务（如 `wof`、`null`、`npfs`、`msfs`、`cimfs`、`beep`）没有 `ImagePath` 字段。我一开始以为这是注册表损坏，结果拿镜像里的 `SYSTEM` 一对比，发现全新安装的 Windows 里这几个服务同样没有 `ImagePath`，这属于正常现象，不是故障。再比如，如果 `BBI` 实在修不好，镜像里那个 8 KB 的空 `BBI` 是唯一可以安全覆盖到本机的文件。所以镜像不能当零件库，只能当参照物。

### 完整备份，然后只改那两个字节

既然明确了修复方案，接下来就是动手执行。在对任何系统文件进行修改之前，必须先做一份完整的备份，以防改坏了还能回滚。我把 `C:\Windows\System32\config` 目录下的所有文件，包括 9 个注册表配置单元和全部的 `.LOG1`、`.LOG2`、`.TM.blf`、`.regtrans-ms` 事务日志，一共 43 个文件、249,708,544 字节（238.1 MB），全部复制到了 D 盘的 `D:\_fix\backup_20261102120607\config\` 目录。复制完成后，用 SHA-256 逐文件比对，确认每一个字节都和源文件一致。

接下来的修复操作，只针对 `CorruptBak\SECURITY` 这份 65,536 字节的原始文件：

```cmd
源   C:\Windows\System32\config\CorruptBak\SECURITY    65,536 B   17965 / 17964
改   0x008 处写回 17965                                            （清脏标志）
改   0x1FC 处重算校验和   0xb3d51b08  ->  0xb3d51b09
```

具体来说，就是在文件的 `0x008` 偏移处，把次序列号 `seq2` 从 17964 改成和主序列号 `seq1` 相同的 17965，这样就清掉了脏标志。然后重新计算文件头前 512 字节的异或校验和，把结果从 `0xb3d51b08` 改成 `0xb3d51b09`，写回 `0x1FC` 偏移处。

改完之后，整个文件和原件只差了 2 个字节。为了确保没有改坏数据，Agent 把修补后的文件和原件做了一次完整的语义比对：两边都是 166 个键、164 个值，键名、值名、值类型、值数据逐项完全一致，0 处差异。结构走查也干干净净，166 个 `nk` 单元的父指针全对，33 个子键索引单元全是合法的 `lh`，2 个安全描述符单元完整，所有可达单元都没有越界。

顺手还验证了这份文件确实属于舍友这台电脑：

```cmd
PolAcDmN   LAPTOP-VQSR6OMV                        ← 与 SYSTEM\ComputerName 一致
PolAcDmS   S-1-5-21-4291209427-303460211-4247354471  ← 与 SAM 域 SID 一致
Policy\Secrets   8 条，含 DPAPI_SYSTEM、RasDialParams!...-1001#0、6 个 MSSQL/SQL 服务账户
根键 LastWriteTime   2026-11-01 09:32:10 UTC       ← 与"上次成功启动 11/1 17:32 本地"完全吻合
```

`PolAcDmN` 和 `PolAcDmS` 与 `SYSTEM`、`SAM` 完全匹配，`Policy\Secrets` 里包含 8 条机密项，`DPAPI_SYSTEM` 主密钥也在。根键的最后修改时间 2026-11-01 09:32:10 UTC，和 `SrtTrail.txt` 里记录的“上一次成功启动 11 月 1 日 9:32:11”完全吻合。

修补好的 `SECURITY` 写回 `C:\Windows\System32\config\SECURITY` 之前，还需要处理一下旁边那两份陈旧的日志文件 `SECURITY.LOG1` 和 `SECURITY.LOG2`。之前的受控实验已经证明，只要 `SECURITY` 文件本身干净了，这两份老日志留在旁边也不影响加载。但为了彻底消除歧义，避免以后其他排查工具误读，我把它们移动到了 D 盘的隔离目录 `D:\_fix\quarantine\` 里。文件移走后，内核在下次挂载时会自动重建一份干净的日志文件。

同样的方法也用于修复 `BBI`：在 `0x008` 偏移处把 `seq2` 从 53231 改成 53232，重算校验和写回 `0x1FC`。修补后 `reg load` 测试通过，里面的 81 条 `WorkItems`、1431 条 `PackageImportance` 和 136 条 `Events` 全部保留。

最后处理那个孤儿驱动。用 `reg load` 挂载 `SYSTEM` 配置单元，找到 `HKLM\SYSTEM\ControlSet001\Services\softaal`，把 `Start` 的值从 `1` 改成 `4`（禁用），然后 `reg unload` 卸载。以后内核启动就不会再尝试加载那个已经不存在的 `softaal64_ev.sys` 了。

### 清理休眠文件与更新残留

修复完注册表，接下来要解决这起事故的罪魁祸首：磁盘空间。首先删掉的是 `C:\hiberfil.sys`，这个文件是 Windows 休眠功能的专用文件，大小 6,715,396,096 字节（6.25 GiB）。我用十六进制工具读取了它的前 4 KB，发现全部内容都是 0。这说明休眠文件的头部已经损坏，就算现在系统还能开机，`winresume` 也不可能从这个文件里恢复任何休眠状态。它现在就是纯占空间的垃圾。

删掉 `hiberfil.sys` 之后，C 盘的可用空间立刻从 8.9 GB 变成了 16.5 GB。顺带说一句，启动配置数据（BCD）里有 4 个 `resumeobject` 指向这个文件，删除它之后，引导器下次就不会再白费力气去尝试从休眠恢复了。

除了休眠文件，还有几个系统更新和重置残留目录也占用了不少空间。清理之前，我先确认了系统没有任何挂起的安装或更新事务（`SetupType=0`、`SystemSetupInProgress=0`、`pending.xml` 不存在），避免误删正在使用的文件。确认安全后，删掉了这些目录：

```cmd
C:\$WinREAgent（1,771 MB，WinRE 更新的回滚数据）
C:\$Windows.~BT（56.7 MB，Windows 升级临时文件）
C:\$SysReset（0.3 MB，系统重置残留）
C:\Windows\SoftwareDistribution\Download（65.5 MB，Windows Update 下载缓存）
```

再加上清理 `InFlight` 目录里我自己跑 DISM 诊断时产生的临时文件，C 盘的已用空间从 135.2 GB 降到了 127.6 GB，可用空间稳定在了 16.5 GB。最后卸载掉之前挂载的 ISO 镜像，释放挂载点：

```cmd
dism /Unmount-Image /MountDir:D:\_fix\mount /Discard
dism /Cleanup-Mountpoints
```

### 修复后全量复查

所有的修改都完成了，但还不能直接重启，必须先做一次全面的验证，确保所有的修复都生效了，而且没有引入新的问题。

第一项验证，也是最有说服力的一项：重新在 PE 里运行 `dism /Image:C:\ /Cleanup-Image /Get-Packages`。这个命令在修复前会直接报 `0xd000014c` 失败，因为它需要先加载 `SECURITY` 配置单元来初始化 CBS 组件存储。修复后的输出是：

```cmd
部署映像服务和管理工具
版本: 10.0.22621.1

映像版本: 10.0.22631.5768

...
操作成功完成。
```

命令成功列出了全部 83 个更新包，状态全部是“已安装”，没有任何挂起的操作。这个输出比任何 `reg load` 的自检都更有说服力，因为它完整走了一遍 CBS 存储的初始化流程，证明 `SECURITY` 已经能被系统正常识别和使用。

紧接着运行 `dism /Image:C:\ /Cleanup-Image /ScanHealth`，检查组件存储的完整性。结果显示“未检测到组件存储损坏”，说明除了那两个脏标志之外，系统组件本身没有受到任何损坏。

第二项验证是对 9 个注册表配置单元做一次四层结构检查：文件头签名、序列号、校验和；`hbin` 数据块链完整性；从根键一层层遍历下去，检查父指针、`li`/`lf`/`lh`/`ri` 子键表和值表；最后统计有没有分配了但无法访问的“孤儿键”。

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

9 个配置单元的序列号全部相等，脏标志全部清除，父指针错 0、子键表错 0、值表错 0、`hbin` 链断 0、孤儿键 0。9 个文件全部通过了 `reg load` 测试。

有一个小插曲值得一提：在遍历 `SYSTEM` 配置单元时，Agent 在 `0xd1a718` 偏移处发现了一个 72 字节的已分配单元，开头恰好是 `6e 6b`（`nk`）这两个字节。乍一看像是某个被遗漏的孤儿键，但查了一下规范，`nk` 单元的最小长度是 `0x4C`（76 字节），这个单元只有 72 字节，不符合规范，所以它只是一段恰好以 `nk` 开头的普通数据，差点因为一个不存在的问题去改文件。

第三项验证是身份一致性。再次确认 `SECURITY` 里的 `PolAcDmN`、`PolAcDmS`、`ProfileList`、`SAM` 账户列表和 LSA 引导密钥全部正确匹配：

```cmd
PolAcDmN   LAPTOP-VQSR6OMV
PolAcDmS   S-1-5-21-4291209427-303460211-4247354471
ProfileList  S-1-5-21-...-1001  ->  C:\Users\admin
SAM 账户     admin / Administrator / DefaultAccount / Guest / WDAGUtilityAccount
Lsa boot key  TC463EF4966D8796     （由 JD+Skew1+GBG+Data 四个类名拼出）
```

`ControlSet001\Control\Lsa` 下的 `JD`、`Skew1`、`GBG`、`Data` 四个键的值都是空的，真正的 SYSKEY 引导密钥是藏在这四个键的**类名**里的。这也是为什么很多第三方注册表工具读不出这个密钥。

最后确认一遍整体状态：没有残留的挂载配置单元，`bcdedit` 的 `{default}` 启动项指向 `C:\Windows\system32\winload.efi`，WinRE 恢复镜像 `Winre.wim` 存在，存储类过滤器全部是系统默认值，`fsutil dirty query C:` 显示卷没有损坏。

## 尾声

### 清理 InFlight 临时目录与顺利开机

重启之前，还顺手清理了一个容易被忽略的“空间刺客”：`C:\Windows\WinSxS\Temp\InFlight` 目录。这个目录是 DISM 和 Windows 更新组件在解压和替换系统文件时使用的暂存区，正常情况下用完应该自动清理。但这台电脑上，这个目录里堆了 5,336 个子目录，占用了 1,498.9 MB 的空间，时间戳从 2023 年 10 月 11 日一直排到 2026 年 11 月 2 日，全是历次更新没有回收的残留。

更有意思的是，我在排查过程中自己跑的几次 `dism /ScanHealth` 和 `/Get-Packages`，也在 `InFlight` 下留下了 7,335 个目录、1,393 MB 的临时文件，C 盘可用空间一度从 16.5 GB 掉到了 16.0 GB。查完之后把这些新产生的临时文件也一并删掉，空间又回到了 16.5 GB。这个插曲也印证了这起事故的起点就是 C 盘写满，任何一点空间都不能浪费。

所有的修复、清理和验证都完成了。现在，9 个注册表配置单元全部干净、全部可加载，组件存储没有损坏，引导链完整，没有任何挂起的更新操作，C 盘也重新有了足够的空间。重启之后能不能顺利进入系统，就看 LSA 子系统认不认这份修补后的 `SECURITY` 了。

拔下 U 盘，按下电源键。这一次，电脑没有再蓝屏，也没有再进恢复界面，屏幕亮起之后，熟悉的 Windows 11 锁屏界面终于出现了。输入密码，成功进入桌面。修复完成。

### 用注册表把自动更新暂停 1000 周

这起事故的根因是 C 盘太小，但直接的导火索是 Windows 11 的后台自动更新。如果不是 Windows Update 在磁盘只剩 100 MB 的时候还在后台静默下载和写入更新包，`SECURITY` 配置单元根本不会被写坏。说起 Windows 更新，最近一两年微软的工程质量下滑得厉害，几乎每次累积更新都会给一部分用户带来新的麻烦：

- **2025 年 8 月（KB5063878）**：不少用户反馈安装后，群联和英韧主控的固态硬盘在写入大文件时会突然掉盘，导致分区损坏；同月的 KB5063875 还搞崩了系统自带的重置和恢复功能，微软最后不得不发带外补丁修复。
- **2025 年 10 月（KB5066835）**：这个更新一次性惹出了好几个乱子：本地回环地址 `127.0.0.1` 的 `HTTP.sys` 连接被掐断，搞崩了一堆本地开发环境；资源管理器的预览窗格误报安全警告；智能卡认证失败；最离谱的是把 WinRE 恢复环境里的 USB 键盘鼠标驱动搞残了，用户进了恢复界面之后鼠标键盘全部失灵，根本无法操作，只能等微软一周后紧急发布 KB5070773 补丁。
- **2026 年 1 月（KB5074109）和 2 月（KB5077181）**：这两个月的累积更新导致部分机器开机直接报 `UNMOUNTABLE_BOOT_VOLUME` 无法启动，Outlook 经典版打开 PST 文件卡死，无法正常关机和睡眠，登录界面损坏，还有 DHCP 断网和 `dxgmms2.sys` 蓝屏。

Windows 更新修复旧漏洞的同时，几乎每次都会引入一批新的问题。对于这台 C 盘只有 150 GB 的电脑来说，最好的办法就是彻底关掉 Windows 自动更新，至少不要让它在后台自己折腾。微软自带的“暂停更新”最多只能暂停 5 周，之后会自动恢复。网上也有一些第三方工具，比如 Windows Update Blocker，可以通过直接删除或破坏 Windows 更新服务组件的方式来禁用更新。但这种做法太粗暴了，删掉系统组件后想恢复很麻烦，还可能影响其他依赖更新服务的功能。

更安全、更可逆的方法是直接修改注册表，把暂停更新的时间手动延长到 1000 周（大约 19 年）。这样既不破坏任何系统文件，又能让 Windows Update 在后台保持安静，以后想恢复更新了，一键撤销就行。操作很简单：新建一个文本文件，把下面的内容粘贴进去，然后把文件后缀名从 `.txt` 改成 `.reg`，双击导入即可：

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

这段注册表的作用是告诉 Windows 更新，功能更新和质量更新都被暂停到了 2042 年 9 月 5 日，而允许的最大暂停天数被设置成了 7000 天（`0x1b58` 的十进制）。导入之后，打开“设置 → Windows 更新”，会看到“暂停更新”的选项已经变成了一个很长的时间，实际上就等于永久关闭了自动更新。

如果以后想恢复正常的 Windows 更新，只需要再导入一个恢复文件，把刚才写入的那些值全部删掉。同样新建一个文本文件，粘贴下面的内容，改后缀为 `.reg` 双击导入：

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

导入恢复文件后，Windows 更新会回到默认状态，可以正常接收微软推送的补丁。这套方法的好处是完全可控，随时想关就关，想开就开，不会在系统里留下任何垃圾。
