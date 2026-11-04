# 故障现场截图 OCR 笔记(一次性记录,后续复用)

13 张 jpg 已全部识别,结果如下。命令原样保留,后续直接查这份文件,不再重复识图。

---

## 1a1abe56 — chkdsk 五阶段

```
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

每个分配单元中有     4096 字节。
磁盘上共有  39321681 个分配单元。
磁盘上有    3994784 个可用的分配单元。
总持续时间: 3.01 分钟 (180616 毫秒)。
无法获得事件日志的句柄。
```

## d9269603 — config 目录清单(关键:大小全部正常)

```
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

**没有一个 hive 是 0 字节。SECURITY 65,536 就是正常大小。**

## 51f4a0c6 — BitLocker 状态 + diskpart 卷表

```
保护状态:      保护关闭
锁定状态:      已解锁
标识字段:      无
自动解锁:      已禁用
密钥保护器:    找不到

X:\Windows\System32>manage-bde -protectors -get C:
BitLocker 驱动器加密: 配置工具版本 10.0.22621
版权所有 (C) 2013 Microsoft Corporation。保留所有权利。

卷 C: [OS]
所有密钥保护器

错误: 找不到密钥保护器。

X:\Windows\System32>cd C:
C:\

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

## 2789cbf5 — 给 ESP 分配盘符并重建引导

```
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

## 927452b9 — bootrec / sfc / dism 连环失败

```
X:\Windows\System32>bcdboot C:\Windows /s S: /f UEFI
已成功创建启动文件。

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

## a4f160f0 — RevertPendingActions 与 Get-Packages 双双 0xd000014c

```
X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /RevertPendingActions
部署映像服务和管理工具
版本: 10.0.22621.1

映像版本: 10.0.22631.5768

暂存目录大小可能不足以执行该操作。这可能会引起异常行为。
请使用 /ScratchDir 选项指向具有足够暂存空间的文件夹。推荐大小为至少 1024 MB。
正在从映像中还原挂起的操作...

错误: 0xd000014c

从映像中还原挂起的操作时出错。
有关详细信息,请查看日志文件。

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

## f9ab15a4 — reg load SYSTEM 成功

```
Microsoft Windows [版本 10.0.22621.3]
(c) Microsoft Corporation。保留所有权利。

X:\Windows\System32>reg load HKLM\TEMP C:\Windows\System32\config\SYSTEM
操作成功完成。
```

**关键点:SYSTEM 能加载。** 怀疑对象从此不再是 SYSTEM。

## 70c2ebb8 — 换 SECURITY 之后 DISM 变"成功"

```
X:\Windows\System32>md D:\backup

X:\Windows\System32>cd C:\Windows\System32\config

X:\Windows\System32\config>move SECURITY CorruptBak\SECURITY
已移动        1 个文件。

X:\Windows\System32\config>copy CorruptBak\SECURITY SECURITY
已复制        1 个文件。

X:\Windows\System32\config>reg copy HKLM\SECURITY C:\Windows\System32\config\SECURITY
'reg' 不是内部或外部命令,也不是可运行的程序或批处理文件。

X:\Windows\System32\config>copy CorruptBak\SECURITY SECURITY
已复制        1 个文件。

X:\Windows\System32\config>dism /Image:C:\ /ScratchDir:D:\backup /Cleanup-Image /RevertPendingActions
部署映像服务和管理工具
版本: 10.0.22621.1

映像版本: 10.0.22631.5768

正在从映像中还原挂起的操作...
操作已完成。重新启动后将尝试还原挂起的操作。
操作成功完成。

X:\Windows\System32>if exist C:\Windows\WinSxS\pending.xml del /f /q C:\Windows\WinSxS\pending.xml

X:\Windows\System32>chkdsk C: /f
文件系统的类型是 NTFS。
```

## 82d1a586 — chkdsk 结论行

```
Windows 已扫描文件系统并且没有发现问题。
无需采取进一步操作。
```

## 960c4e13 / e2220c15 — 重启后 0xc0000001

```
Recovery

Your PC couldn't start properly

After multiple tries, the operating system on your PC failed to start, so it needs to be
repaired.

Error code: 0xc0000001

You'll need to use recovery tools. If you don't have any installation media (like a disc or
USB device), contact your PC administrator or PC/Device manufacturer.

Press Enter to try again
Press F1 to enter Recovery Environment
Press F8 for Startup Settings
Press Esc for UEFI Firmware Settings
```

## c2e41fc6 — 启动修复失败

```
启动修复
启动修复无法修复你的电脑。

按"高级选项"以尝试使用其他选项来修复你的电脑,或者按"关机"来关闭你的电脑。

日志文件: C:\Windows\System32\Logfiles\Srt\SrtTrail.txt
```

---

# 日志文件补到的证据(非图片)

## DISMRepairLogFile.txt

1,973 行带时间戳,2026-11-01 17:35:28 → 2026-11-02 15:21:12。

- `0xd000014c` 出现 120 次,全部指向 **SECURITY** 加载失败,共 12 次尝试:
  11-01 17:35:29 / 17:37:01 / 21:45:55 / 21:47:30 / 21:48:30 / 22:13:43 / 22:16:57;
  11-02 11:05:03 / 11:13:58 / 11:42:04 / 12:50:55 / 13:55:22。
- `0xd0000043` 出现 10 次,**只有 1 次**,发生在 2026-11-02 15:21:12,对象是 **SYSTEM**。

```
Failed to load offline \\?\C:\Windows\System32\config\SECURITY hive from '\\?\C:\Windows\System32\config\SECURITY' into registry key '{bf1a281b-...}C:/Windows/System32/config/SECURITY'
Failed to load offline registry: {bf1a281b-...}C:/Windows/System32/config/SECURITY [HRESULT = 0xd000014c - NTSTATUS Error]
Failed to load offline SECURITY hive. [HRESULT = 0xd000014c - NTSTATUS Error]
Failed to load offline store from boot directory: '\\?\C:\' and windows directory: '\\?\C:\Windows\' [HRESULT = 0xd000014c]
```

```
Failed to load offline \\?\C:\Windows\System32\config\SYSTEM hive ...
Failed to load offline registry: {...}C:/Windows/System32/config/SYSTEM [HRESULT = 0xd0000043]
Failed to load offline SYSTEM hive. [HRESULT = 0xd0000043 - NTSTATUS Error]
```

## C:\Windows\Logs\CBS\CBS.log

```
2026-10-23 18:36:21, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:23, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:25, Info  CBS  System volume has 0G free disk space
```

## SrtTrail.txt(最后一次会话)

```
上一次成功启动的时间: 2026/11/1 9:32:11 (GMT)
尝试修复次数: 64
系统磁盘 = \Device\Harddisk0
Windows 目录 = C:\Windows

操作: 检查已安装的 LCU
结果: 成功完成。错误代码 = 0x43
```

## minidump 110226-9312-01.dmp

```
signature   = PAGE / DU64
major/minor = 15.22621
bugcheck    = 0x74  (BAD_SYSTEM_CONFIG_INFO)
P1 = 0x2
P2 = 0xffff94869fbd2940
P3 = 0x1
P4 = 0xffffffffc000014c
崩溃时间     = 2026-11-02 07:36:19 UTC (= 15:36 +08)
内嵌 ASCII  = "HiveLoadFromomFile" + "status"
内嵌 UTF-16 = "<SECURITY"
```

---

# 最终结论数据(修复后复核)

| hive | 字节 | 序列 | 键 | 值 |
|---|---|---|---|---|
| SYSTEM | 32,243,712 | 395834/395834 | 91,391 | 194,730 |
| SOFTWARE | 117,440,512 | 937587/937587 | 372,888 | 640,232 |
| SAM | 131,072 | 3911/3911 | 80 | 100 |
| SECURITY | 65,536 | 17970/17970 | 166 | 164 |
| DEFAULT | 6,029,312 | 238433/238433 | 8,201 | 10,937 |
| DRIVERS | 8,777,728 | 4850/4850 | 36,424 | 52,954 |
| COMPONENTS | 32,768,000 | 9216/9216 | 61,793 | 197,776 |
| ELAM | 32,768 | 13/13 | 1 | 0 |
| BBI | 1,310,720 | 53233/53233 | 1,652 | 10,129 |

身份:SECURITY `PolAcDmN = LAPTOP-VQSR6OMV`,`PolAcDmS = S-1-5-21-4291209427-303460211-4247354471`(与 SAM 一致);LSA boot key = `TC463EF4966D8796`。
