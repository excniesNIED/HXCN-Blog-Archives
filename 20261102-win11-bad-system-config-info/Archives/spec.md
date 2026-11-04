# 写作规格与全量信息规划（`spec.md`）

## 一、 全量事实与证据盘点（各目录信息汇总）

### 1. 硬件与系统基线（来自 `issue/`、`sessions/`、`_fix/`）
- **机型**：华硕笔记本（计算机名 `LAPTOP-VQSR6OMV`，WinPE 下临时名 `MININT-BIUPGCV` / `MININT-0FKJ8JI`）。
- **操作系统**：出厂预装 Windows 11 家庭中文版（`CoreCountrySpecific`），已通过自动更新升至 23H2 `10.0.22631.5768`，离线服务栈（Servicing Stack）版本为 `10.0.22621.5690`。
- **磁盘与分区布局**（1 TB SSD，GPT + UEFI）：
  - 卷 0（`C:`，标签 `OS`，NTFS，150 GB）：系统盘，安装了 MATLAB、SQL Server 2022、Office 2014、Steam 游戏库等重型软件。事发时剩余空间被挤到**仅剩 100 多 MB**；手动清理桌面不重要大文件后腾出约 **8.9 GB**（`chkdsk` 时为 `15,979,136 KB`）；最终清理 `hiberfil.sys` 与更新暂存目录后恢复至 **16.5 GB**。
  - 卷 1（`D:`，标签 `新加卷`，NTFS，389 GB）：数据盘，存有 `D:\pagefile.sys`（18 GB）及原版镜像 `D:\Win11_23H2_Chinese_Simplified_x64v2.iso`（内部版本 `22631.2861`）。
  - 卷 2（`E:`，标签 `新加卷`，NTFS，389 GB）：数据盘。
  - 卷 3（标签 `RESTORE`，NTFS，24 GB）：华硕出厂恢复分区。
  - 卷 4（标签 `SYSTEM`，FAT32，260 MB，已隐藏）：EFI 系统引导分区（ESP，序列号 `8CE7-BD30`）。
  - 卷 5（标签 `RECOVERY`，NTFS，950 MB，已隐藏）：WinRE 恢复环境分区（内含 `Winre.wim` 873 MB）。
  - 卷 6（`H:`，标签 `MYASUS`，FAT32，260 MB，已隐藏）：华硕工具分区。
  - 卷 7（`F:`，标签 `Ventoy`，exFAT，117 GB）：启动 U 盘（先后使用微 PE 与带网络的 FirPE）。

### 2. 事故时间线与关键物证
1. **2026-10-23 18:36:21–18:36:25（`C:\Windows\Logs\CBS\CBS.log`）**：
   - 连续三次记录 `Info CBS System volume has 0G free disk space`，紧跟 `Maint: incomplete, interruptions: 1`。证明 C 盘在此前更新维护中已被彻底写满到 0 字节可用。
2. **2026-10-31 21:18（`C:\Windows\System32\config\`）**：
   - `BBI` 配置单元（1,310,720 B）停留在 `seq1=53232, seq2=53231`（脏标志未清，`.LOG1/.LOG2` 均为 0 字节），但因 `BBI` 非内核引导关键 Hive，次日仍可开机。
3. **2026-11-01 09:32:10 UTC / 北京时间 17:32:10（`CorruptBak\SECURITY` 根键 `LastWriteTime`）与 09:32:11 GMT（`SrtTrail.txt`）**：
   - 最后一次成功启动时间。`SECURITY` 配置单元（65,536 B）在写入事务落盘后未完成次序列号同步，停在 `seq1=17965, seq2=17964`（脏标志），头部校验和 `0xb3d51b08` 自洽；而 `SECURITY.LOG1` 停在 2022 年的 `seq=208`，`SECURITY.LOG2` 停在落后的 `seq=17963`，日志链彻底断裂。
4. **2026-11-01 17:35:29 至 2026-11-02 13:55:22（`DISMRepairLogFile.txt`，共 2052 行、1974 行带时间戳）**：
   - 自动修复（`StartRep.exe`）与离线 DISM 共尝试加载离线注册表 12 次，每次均按 `SOFTWARE` → `SYSTEM` → `SECURITY` 顺序加载，前两个成功，第 3 个 `SECURITY` 稳定报错 `HRESULT = 0xd000014c`（即 `0xC000014C STATUS_REGISTRY_CORRUPT`），全文共出现 120 次 `0xd000014c`。
5. **2026-11-02 15:21:12（`DISMRepairLogFile.txt` & `SrtTrail.txt` 会话 1）**：
   - 唯一一次报 `Failed to load offline SYSTEM hive. [HRESULT = 0xd0000043]`（`STATUS_SHARING_VIOLATION` 共享冲突，共 10 行），对应 `SrtTrail.txt` 会话 1“检查已安装的 LCU”错误代码 `0x43`。真实原因是在 PE 下手动执行 `reg load HKLM\TEMP C:\Windows\System32\config\SYSTEM`（或打开 DISM++ 挂载）后未卸载，并非 `SYSTEM` 损坏。
6. **2026-11-02 07:36:19 UTC / 北京时间 15:36:19（`C:\Windows\Minidump\110226-9312-01.dmp`）**：
   - 唯一留存的 64 位内核转储（`PAGEDU64`）：`BugCheck 0x74 (BAD_SYSTEM_CONFIG_INFO)`，`P1=0x2`，`P2=0xffff94869fbd2940`，`P3=0x1`，`P4=0xffffffffc000014c`，内嵌 ASCII `"HiveLoadFromomFile"` + `"status"` 与 UTF-16 `"<SECURITY"`。
7. **2026-11-02 15:46 前后（外来 `SECURITY` 替换实验）**：
   - 将本机损坏的 `SECURITY` 移至 `CorruptBak\SECURITY`，从作者本人的电脑（`HXCN-WIN`）提取了一份结构干净的 `SECURITY`（65,536 B，`seq 210/210`）拷入 C 盘。
   - 随后指定 `/ScratchDir:D:\backup` 运行 `dism /Image:C:\ /ScratchDir:D:\backup /Cleanup-Image /RevertPendingActions` 显示“操作成功完成”，但重启依然报 `0xc0000001`。
   - 原因：外来 `SECURITY` 的 `PolAcDmN = HXCN-WIN`、`PolAcDmS = S-1-5-21-1262172508-...`，与舍友本机 `SAM` 的域 SID `S-1-5-21-4291209427-303460211-4247354471`（计算机名 `LAPTOP-VQSR6OMV`）不匹配，且缺失本机 `DPAPI_SYSTEM` 主密钥，LSA 启动校验直接拒绝。

### 3. Agent 深入排查与受控实验结论（来自 `sessions/` 与 `_fix/`）
- **原件结构走查**：`CorruptBak\SECURITY`（65,536 B，SHA-256 `7590396173dc6ff07a847e59c662570edc2757c19e0b6459a8f06681a55fde67`）含 166 个键（`nk`）、164 个值（`vk`）、33 个子键索引（`lh`）、2 个安全描述符（`sk`），可达单元末尾 `45,056`（在 `53,248` 边界内），父指针错 0、越界 0、孤儿键 0。数据区 100% 完好。
- **受控加载实验矩阵（`mx2`~`mx8`，脚本 `matrix*.cmd`）**：
  - `s1`（脏 `17965/17964`，无日志）→ FAIL
  - `s2`（脏 `17965/17964`，0 字节日志）→ FAIL
  - `s3` / `a`（脏 `17965/17964`，陈旧日志 `208` + `17963`）→ FAIL
  - `h`（脏 `17965/17964`，仅 `LOG2=17963`）→ FAIL
  - `t1`（脏 `17965/17963`，重算校验和，无日志）→ FAIL
  - `t2`（干净 `17964/17964`，重算校验和，无日志）→ OK
  - `i`（补丁后 `17965/17965`，重算校验和 `0xb3d51b09`，无日志）→ OK
  - `j`（补丁后 `17965/17965`，重算校验和，保留陈旧日志 `208`+`17963`）→ OK
  - `s4`（序列号相等 `17965/17965`，但不重算 `0x1FC` 校验和）→ FAIL
  - **核心定律**：只要 `seq1 != seq2` 即拒绝加载，与日志是否存在无关；只要 `seq1 == seq2` 且 `0x1FC` 校验和正确，即使陈旧日志保留在旁也能正常加载。
- **附带发现**：
  1. `BBI`（1,310,720 B）处于 `53232/53231` 脏状态，不可加载，需同样修补 `0x008` 与 `0x1FC` 两个字段。
  2. `HKLM\SYSTEM\ControlSet001\Services\softaal`（`Start=1`, `ErrorControl=0`）指向已不存在的腾讯电脑管家旧目录 `\??\C:\Program Files (x86)\Tencent\QQPCMgr\15.1.22354.301\softaal64_ev.sys`（现版本已升至 `15.6.23169.211`），需改为 `Start=4` 禁用。
  3. 其余 4 个非启动期（`Start >= 2`）孤儿驱动：`ksapi64`（Start=2）、`ROGKB`（Start=3）、`ROGMS`（Start=3）、`TSSKX64`（Start=3，注册表写 `tsskx64_EV.sys`，磁盘实为 `TSSKX64.sys`），以及不生效的 `ControlSet002` 仅存 `Services\kisknl`，均不影响内核引导。
- **近期 Windows 11 更新翻车背景（Tavily 查证）**：
  - `KB5063878`（2025 年 8 月）：引发群联（Phison）/英韧主控 SSD 在大文件写入时掉盘与分区损坏，以及 OBS NDI 推流断流；同月 `KB5063875` 搞崩系统重置与恢复功能。
  - `KB5066835`（2025 年 10 月）：一次性打断 `localhost`（`127.0.0.1`）`HTTP.sys` 本地连接、资源管理器预览窗格误报、智能卡认证失败，更把 **WinRE 恢复环境里的 USB 键鼠驱动搞残**（进了恢复界面鼠标键盘全失灵），迫使微软发带外补丁 `KB5070773`。
  - `KB5074109`（2026 年 1 月）与 `KB5077181`（2026 年 2 月）：导致部分机器报 `UNMOUNTABLE_BOOT_VOLUME` 无法开机、Outlook POP/PST 卡死、无法正常关机睡眠，以及登录界面损坏、DHCP 断网与 `dxgmms2.sys` 蓝屏。

---

## 二、 章节结构与详细写作规划

### 顶层结构（中英文完全对齐）
1. `## 前言` / `## Preface`
2. `## 猜测和尝试` / `## Initial Guesses and Troubleshooting`
   - `### 基本情况` / `### The Situation`
   - `### 关掉 BitLocker` / `### Turning Off BitLocker`
   - `### 常规手段尝试` / `### Trying the Standard Playbook`
3. `## Agent 深入排查` / `## Deep Dive with an AI Agent`
   - `### 从日志与转储文件锁定真凶` / `### Pinpointing the Culprit from Logs and Crash Dumps`
   - `### 为什么换上我的 SECURITY 还是开不了机` / `### Why Dropping In My Own SECURITY Hive Still Failed to Boot`
   - `### 序列号 17965 与 17964：两字节的脏标志` / `### Sequence Numbers 17965 and 17964: The Two-Byte Dirty Flag`
   - `### 发现了 BBI 和孤儿驱动问题` / `### Uncovering the Dirty BBI Hive and the Orphaned Driver`
4. `## 解决` / `## The Fix`
   - `### 镜像里那份 SYSTEM 只有 9 MB，为什么还是要用原版镜像` / `### Why the ISO's 9 MB SYSTEM Hive Can't Overwrite Yours—and Why You Still Need the ISO`
   - `### 完整备份，然后只改那两个字节` / `### Full Backup, Two-Byte Patch, and Stale Log Quarantine`
   - `### 清理休眠文件与更新残留` / `### Clearing the Hibernation File and Update Leftovers`
   - `### 修复后全量复查` / `### Post-Repair Verification`
5. `## 尾声` / `## Epilogue`
   - `### 清理 InFlight 临时目录与顺利开机` / `### Cleaning Up InFlight Temp Directories and Booting Up`
   - `### 用注册表把自动更新暂停 1000 周` / `### Pausing Windows Update for 1,000 Weeks via the Registry`

---

## 三、 写作风格与去 AI 味铁律

1. **视角与人设**：第一人称（“我”）复盘帮舍友修电脑的真实经历，严禁出现“根据 issue 文档”“在报告第几节”等上帝视角表述。
2. **把原理和步骤讲透**：
   - 每执行一条命令前，先交代**为什么要执行它、想验证什么假设**；
   - 命令贴出后，逐条解释**输出里的关键指标和错误码是什么意思**（兼顾新手可读性与硬核技术深度）；
   - 把自己和豆包当时踩的坑、走过的弯路（如漏打冒号报 87、挂载 `SYSTEM` 忘了卸载导致 `0xd0000043`、拿自己电脑的 `SECURITY` 顶替制造假修复）坦诚写出来。
3. **严格执行去 AI 味规则（`de-ai-writing` / `humanizer-zh` / `chinese-ai-humanizer` / `humanizer`）**：
   - 禁用“不是 X，而是 Y”“这不仅仅是……更是……”等假对比句式；
   - 禁用单句成段的故作深沉收尾（如“这条线索断了。”“改完只差 2 个字节。”）；
   - 中文正文统一使用全角标点，不滥用破折号 `——`，不给普通名词乱加引号或粗体；
   - 英文版（`index.en.md`）禁用 em-dash `—`，去掉中国特有的盗版 Ghost 一键分四区表述并保持上下文自然衔接，贴近美国母语工程师博客文风。


---

## 四、 补充信息（二次检索 sessions 得到）

- **镜像提取与只读挂载**（Agent 实际执行）：
  - `7z e -y -oD:\_fix\wim D:\Win11_23H2_Chinese_Simplified_x64v2.iso sources\install.wim`
  - `dism /Mount-Image /ImageFile:D:\_fix\wim\install.wim /Index:1 /MountDir:D:\_fix\mount /ReadOnly`
  - 用完 `dism /Unmount-Image /MountDir:D:\_fix\mount /Discard` + `dism /Cleanup-Mountpoints`。
- **补丁代码**：Agent 在 PE 里用 Node.js 改字节：`writeUInt32LE(readUInt32LE(4), 8)` 让 seq2 = seq1；对 0x000–0x1F8 共 127 个 DWORD 异或，结果为 0xFFFFFFFF 写 0xFFFFFFFE、为 0 写 1，写回 0x1FC。偏移 0x08 字节 `2c 46 00 00` → `2d 46 00 00`。
- **Get-Packages**：83 个包全部“已安装”，最新累积更新 `Package_for_RollupFix~…~22621.5768.1.15` 安装于 2025/8/15，服务栈 5690 同日。说明之后一年多没有新的累积更新装上（原因未证实，只作猜测）。
- **DISMRepairLogFile.txt**：2052 行，带时间戳 1974 行（旧稿写 1973 是错的）。
- **dir config 末行**：`10,064,023,552 可用字节`，即清理桌面后约 9 GB；fsutil 口径为 8.9 GB。

## 五、 写作决策

1. **空间数字**：接手时 C 盘只剩 100 多 MB，我当时顺手清过桌面到 9 GB 左右，但没把空间和故障联系起来；直到 DISM 报暂存空间不足、日志指向 SECURITY，才把两件事连上。按用户脉络放在“常规手段尝试”末尾，并如实说明“其实早就清过一次”。最终 16.0 GB（清休眠文件与残留后）→ 16.5 GB（删掉自己 DISM 产生的 InFlight）。
2. **隐私**：机器 SID 只保留第一段子授权（`S-1-5-21-4291209427-…`），LSA boot key 不写；用户目录统一写 `<用户名>`。
3. **NTUSER.DAT 纠正**：用户原话把开始菜单和 `NTUSER.DAT` 写在一起。开始菜单快捷方式在 `C:\ProgramData\Microsoft\Windows\Start Menu\Programs` 与 `%AppData%\Microsoft\Windows\Start Menu\Programs`；`NTUSER.DAT` 是用户注册表配置单元，单独列出“留一份备查”。
4. **DISM 87**：截图里 `/Image:C:\` 报 87 的原因没查清，不编造“不可见字符”；另写 dism.log 里确有的一次漏冒号（`/Image:C\` 被解析为 `X:\Windows\System32\C\`）。
5. **bootrec /scanos = 0**：只写“我猜和注册表读不出来有关，没有直接证据”。
6. **ControlSet**：`Select\Current = 1`，`ControlSet002` 只剩 `Services\kisknl`，不是可用备份。
7. **BBI 全称**：来源说法不一，正文不展开缩写，只写里面装了什么。
8. **AI 角色**：舍友先用豆包；我把截图和日志贴给聊天 AI 拿到的方案（回滚挂起更新、换 SECURITY、换 SAM/COMPONENTS）；之后在 FirPE 联网装 oh-my-pi 让 Agent 做只读审计、副本实验，批准后才写 C 盘。
9. **尾声**：成功开机，只写“进了系统”，不补未经证实的细节。更新批评引用 Microsoft Learn、BleepingComputer、Windows Latest、ZDNET 的具体 KB。
10. **写入方式**：按用户要求用 eval Python 写文件。

## 附件：用户需求

```
优化 @index.md，按照我给的脉络和你对项目的理解重写：

按照前言、猜测和尝试、Agent深入排查、解决、尾声五个二级标题，现有标题进一步划分三级标题

我会把每部分写个大概，具体内容请进行扩展，参考 ../20251113-academic-edu-refund、20250324-ubuntu2404-optimize、20250323-dual-boot-ubuntu2404-win11、20250513-conda-win、20250511-vscodium-migrate 这些爆款文章。本文类似与第一人称复盘。很多依赖 @issue/ @sessions/ @_fix/ 来写。我写的标题也仅供参考，按需编写。禁止按照issue相关文档的写法来，避免上帝视角。图片已经在截图OCR笔记.md列出关键代码

使用相关去ai味skills禁止ai句式、行文和用词。现在的很别扭，即不专业，小白也看不懂

## 前言

先是陈述我的观点

我一直认为，对于大多数而言，一块硬盘一个分区足够了，如果有多个硬盘，一个硬盘一个分区足矣，如果只有一个硬盘，最多分CD两个分区足够了，我认为C盘留200-300甚至512是最少的（如果你重度使用的话）。

软件可以安装在其他分区，但是各种缓存、临时文件都会占用C盘。如果C盘太小了，剩余空间小，很多软件无法正常运行甚至无法开机。此外如果你有一个很大的文件或者游戏但是分了很多个区，剩余总空间足够装下但是每个分区都无法容纳。

很多人说软件装在c盘重装系统数据会丢失，事实上重装系统后安装在D盘中其他分区的软件也会因为注册表等丢失无法正常运行。你只需要备份QQ微信聊天记录（通常位于C:\Users\\\<用户名>\\文档中）、下载的文件（C:\Users\\\<用户名>\\下载）、图片视频、桌面、开始菜单（"C:\Users\\\<用户名>\NTUSER.DAT"方便对照安装了哪些软件和桌面文件）、重要文件、密码和密钥等，如果有BitLocker锁还需要事先解锁或者备份密钥，重装后补齐软件并还原这些文件即可

10多年前刚开始学会折腾电脑的时候，我爸一辈喜欢为硬盘分四个分区，可能源于当年各种盗版Ghost镜像，普遍支持一键分区的功能（一般是4个），如今很多在长辈推荐下买电脑的同辈同样将硬盘分成四个很小的分区。我经常遇到C盘空间不足的同学求助，每次都要挪一下其他盘的文件集中起来，给c盘腾地方用

如果你想反驳，今天这次舍友的电脑莫名其妙蓝屏的例子就是反例堵住你的嘴

## 猜测和尝试

### 基本情况

(这里主要搬运 issue.md的问题排除和解决过程)

舍友电脑莫名其妙蓝屏（放蓝屏图）。蓝屏多次重启触发windows修复，但是不出意外修复失败（startup-repair-failed.svg）由于内存不够没有恢复点可以快速恢复。舍友使用豆包尝试了各种检查和修复也无济于事。

既然chkdsk和sfc尝试无效果必然没有硬件上的损坏，系统文件大概率没有大问题，首先想到修复引导。ventory进入PE使用dism++准备尝试，dism＋＋提示试图加载格式不准确的格式，尝试修复引导后重启，报错0xc0000001。（图片recovery-error-0xc0000001.svg）

### 关掉bitlocker（全部驼峰命名）

pe下看到有bitlocker，没有微软账号登录，无法从ms官网获取恢复码（附上操作方法）

附上diskpart排查方法

使用manage-bde -off关闭全部 BitLocker（防止后续被意外锁死）

### 常规手段尝试

解除了bl。尝试chkdsk 、dism重建uefi，注册表加载和自动修复依旧不行，附上代码（截图转换命令和报错不要放图），把相关日志的关键信息写出来

分析了SrtTrail.log，尝试回滚“挂起的更新”，清理挂起的更新事务，检查并卸载最近安装的更新包，测试 ControlSet 备用控制集都无济于事

然后突然发现，C盘只剩下100M空间，清理了桌面上一些不重要文件后剩余8G（现有Index.md直接写剩8G是不对的）

附上命令和执行结果（注意隐私处理和抽取重要日志

结合日志 `dism.log` 和磁盘空间，猜测是极度缺盘诱发的“截断坏死”并引发连锁反应，然后尝试针对 `SECURITY` 损坏的终极免重装修复方案。我从我的电脑复制了疑似损坏的SERURITY注册表

## Agent深入排查

替换后依旧报错我列出一下哪些组件还有可能损坏，给出尝试修复替换一下然后重构dism镜像

我在firpe联网安装oh-my-pi后使用ai分析

上面都从issue/index.md最后的部分找，下面开始使用修复清单报告、 index.md 和_fix中的内容去写

### 来一个标题，日志分析啥的

10 月 23 日，C 盘真的满了

0xd000014c 到底在说哪个 hive

当然index.md标题ai味很重，在我现有基础上润色就行，符合技术博客特征

一次“修好了”的假象 换上去的那份不是这台机器的 序列号 17965 和 17964 脏标志：两个字节的事 我的电脑替换上去的无法正常使用，导致一次替换没有成功，根本原因是脏标志

### 发现了BBI 和孤儿驱动问题

BBI 和那个孤儿驱动，这段可以按照修复清单报告、 index.md 和_fix中的内容去写写更详细一点

## 解决

参考index.md _fix session中的内容，写详细一些

分2-3个子章节或者不分？你看着分

镜像里那份 SYSTEM 只有 9 MB，为什么可以用镜像

备份，然后改那两个字节

瓷碗P2 —— 可选清理(约 1.9 GB)

P1-2 删除 `C:\hiberfil.sys`(6.7 GB)

**P1-1 隔离陈旧日志 `SECURITY.LOG1` / `SECURITY.LOG2`**

复查

## 尾声

**`WinSxS\Temp\InFlight` 堆了 5336 个目录、1498.9 MB**，时间戳从 2023-10-11 一直到 2026-11-02，是 DISM 和更新组件没回收的暂存副本。不占关键路径，但白吃 1.5 GB 空间。

顺带一件小事：排查过程中我自己跑了几次 `DISM /ScanHealth` 和 `/Get-Packages`，它们在 `InFlight` 下留了 7335 个目录、1393 MB 临时文件。查完删掉，C 盘可用空间从 16.0 GB 回到 16.5 GB。给下次留点余量，这次故障的起点就是 C 盘写满。

九个 hive 现在全干净、全部可加载，组件存储无损坏，引导链完整，没有任何挂起操作。重启之后能不能进系统，就看 LSA 认不认这份 SECURITY 了。

成功开机

tavily搜索罗列近期windows更新虽然带来很多重大修复，但是每次修复都为用户引入新的问题。此外鞭笞微软工程质量下降无法保证用户使用的系统的质量

因此推荐注册表禁用更新。。创建txt改reg后缀，给出推荐的应用1000周禁用和解除方法

windows-1000weeks-update-blocker.reg windows-1000weeks-update-blocker-recovery.reg

---

英文版 index.en.md，使用-en结尾的svg插图，标题划分同中文版

前言去掉中国特有的盗版系统相关句子，但是要确保段落内句子连续

翻译要贴近英语母语（美国为主）特征
```

