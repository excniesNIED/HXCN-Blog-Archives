# Win11 0x74 BAD_SYSTEM_CONFIG_INFO 抢修工具包

一次真实的抢修记录：C 盘写满 → SECURITY 注册表 hive 脏标志未清 → 内核拒绝加载 → `0x74 BAD_SYSTEM_CONFIG_INFO`。最终只改了 **2 个字节** 就恢复了。

机器：华硕笔记本，`LAPTOP-VQSR6OMV`，Windows 11 23H2 `22631.5768`，C 盘 150 GB。

---

## 目录结构

```
F:\bakup\_fix\
├── README.md                 本文件
├── scripts\                  排查用的批处理脚本
├── hives\
│   ├── original_broken\      原始损坏的 SECURITY（脏标志未清）
│   ├── repaired\             修复后的 SECURITY（可直接放回）
│   └── pre_repair_full\      修复前 config 目录完整快照（回滚用，238 MB）
├── experiments\              受控实验用的 hive 副本（mx2~mx8）
└── logs\                     排查过程中产生的证据
```

| 文件 | 大小 | 说明 |
|---|---|---|
| `hives\original_broken\SECURITY` | 64 KB | **本机的原始 hive**，`seq 17965/17964`（脏），机器 SID 与 SAM 一致 |
| `hives\repaired\SECURITY` | 64 KB | 补丁后的成品，`seq 17970/17970`（干净），可直接拷回 `C:\Windows\System32\config\SECURITY` |
| `hives\pre_repair_full\` | 238 MB | 修复前 9 个 hive + 全部日志的完整备份 |
| `experiments\quarantine\SECURITY.LOG1` | 48 KB | 原始日志，`seq 208`（2022 年的陈旧日志） |
| `experiments\quarantine\SECURITY.LOG2` | 8 KB | 原始日志，`seq 17963`（比 hive 落后 2 个事务） |

---

## 故障机理

注册表 hive 的前 4 KB 是固定结构的头：

```
偏移 0x000   "regf"        签名
偏移 0x004   seq1          主序列号
偏移 0x008   seq2          次序列号
偏移 0x01C   type          hive 类型
偏移 0x024   root          根键 nk 单元偏移
偏移 0x028   hbins         bins 区总字节数
偏移 0x1FC   checksum      头部校验和
```

**校验和算法**：`dword[0x000..0x1F8]` 每 4 字节异或。边界约定：结果为 `0xFFFFFFFF` 时写 `0xFFFFFFFE`，为 `0` 时写 `1`。

**脏标志**：`seq1 != seq2` 表示上一次事务没提交完。受控实验证明（见下表）：**只要 `seq1 != seq2` 就拒绝加载**，跟日志在不在、能不能重放都没有关系。

| 用例 | hive 状态 | 附带日志 | `reg load` |
|---|---|---|---|
| s1 | 脏 17965/17964 | 无 | **失败** |
| s2 | 脏 17965/17964 | 0 字节 LOG1/LOG2 | **失败** |
| s3 | 脏 17965/17964 | 陈旧 LOG1(208)+LOG2(17963) | **失败** |
| t1 | 脏，seq2 再减 2 | 无 | **失败** |
| t2 | seq2 := seq1 | 无 | 成功 |
| i | 补丁后 17965/17965 | 无 | 成功 |
| j | 补丁后 17965/17965 | 陈旧日志原样保留 | 成功 |
| s4 | seq 相等但校验和不重算 | 无 | **失败** |

---

## 修复步骤

```cmd
源   C:\Windows\System32\config\CorruptBak\SECURITY    65,536 B   17965 / 17964
改   0x008 处写回 17965                                            (清脏标志)
改   0x1FC 处重算校验和   0xb3d51b08  ->  0xb3d51b09
```

改完只差 2 个字节。166 个键、164 个值，键名/值名/值类型/值数据逐项一致，0 处差异。

---

## 脚本用法

所有脚本都在 `scripts\` 下。用法统一：

```cmd
D:\_fix\scripts\脚本名.cmd
```

| 脚本 | 作用 |
|---|---|
| `verify_final.cmd` | 9 个 hive 逐个 `reg load` 检查是否都能加载 |
| `verify_setup.cmd` | 检查 Setup 状态（SetupType、SystemSetupInProgress、PendingFileRenameOperations、BootExecute） |
| `final_check.cmd` | 收尾检查：挂载残留、Select、SECURITY 是否就位、hiberfil 是否删除、引导链、空间 |
| `snapshot.cmd` | 拍一份 config 目录清单 + 九个 hive 头部摘要 |
| `id_check.cmd` | 身份一致性：SECURITY 机器 SID vs SAM 域 SID，SAM 账户 RID，ProfileList |
| `mem_check.cmd` | 读 `Control\Power` 的分页/休眠设置 |
| `audit_bootdrv.cmd` | 启动驱动审计：Start 0/1、Type 1/2 的驱动，镜像文件是否缺失 |
| `audit_thirdparty.cmd` / `audit_tp2.cmd` / `audit_tp3.cmd` | 第三方驱动服务排查 |
| `audit_filters.cmd` | 存储类 Upper/Lower 过滤器检查 |
| `audit_components.cmd` | config 目录清单 |
| `cbs_pending.cmd` | CBS 挂起状态：RebootPending / PackagesPending |
| `matrix.cmd` / `matrix2.cmd` / `matrix3.cmd` / `matrix4.cmd` / `matrix_aj.cmd` | 受控加载实验矩阵（脏/干净 × 日志组合） |

> 脚本里的路径写的是 `D:\_fix\...`，换机器时改路径即可。`experiments\mx2~mx8` 是实验用的 hive 副本，脚本会往里写，不要指向真实的 `C:\Windows\System32\config`。

---

## 在 WinPE 里配合原版镜像排查

### 1. 挂载原版 ISO

假设 ISO 是 `D:\Win11_23H2_Chinese_Simplified_x64v2.iso`。PE 里没有 PowerShell 的话用 DISM 挂载 `install.wim`：

```cmd
md D:\_fix\mount

dism /Mount-Image /ImageFile:D:\Win11_23H2_Chinese_Simplified_x64v2.iso /Index:1 /MountDir:D:\_fix\mount /ReadOnly
```

如果提示找不到 `install.wim`，先确认镜像里的实际文件名：

```cmd
dir /s D:\sources\install.*
```

### 2. 拿镜像里的 hive 当**比对基线**（不要直接覆盖）

镜像里的 `Windows\System32\config\` 是**通用安装态**，跟具体机器无关：

| hive | 镜像内 | 本机 | 覆盖后果 |
|---|---|---|---|
| SYSTEM | 9,175,040 B / 661 个服务 / `MINWINPC` | 32,243,712 B / 846 个服务 / `LAPTOP-VQSR6OMV` | 驱动服务和设备树全丢，必然 INACCESSIBLE_BOOT_DEVICE |
| SAM | 8,192 B（空库） | 131,072 B / 5 个账户 | 账户全丢 |
| SECURITY | 8,192 B（空） | 65,536 B | LSA 机密全丢，DPAPI 数据永久打不开 |
| SOFTWARE | 66,584,576 B | 117,440,512 B | 已装软件注册信息全丢 |

**唯一能安全用的是 `BBI`**（镜像里是 8,192 B 空队列）。

### 3. 就地升级修复不可行

镜像 `22631.2861` **低于**已装的 `22631.5768`，setup 会以「版本更低」直接拒绝。

### 4. 卸载挂载

```cmd
dism /Unmount-Image /MountDir:D:\_fix\mount /Discard
dism /Cleanup-Mountpoints
```

---

## 验证清单

修复后按顺序跑一遍，全绿才算完：

```cmd
:: 1) 九个 hive 全部能加载
D:\_fix\scripts\verify_final.cmd

:: 2) 身份一致性
D:\_fix\scripts\id_check.cmd

:: 3) 启动驱动无缺失
D:\_fix\scripts\audit_bootdrv.cmd

:: 4) 无挂起安装
D:\_fix\scripts\cbs_pending.cmd
D:\_fix\scripts\verify_setup.cmd

:: 5) 组件存储 —— 这是最硬的证据
dism /Image:C:\ /Cleanup-Image /ScanHealth
dism /Image:C:\ /Get-Packages /Format:Table
```

`Get-Packages` 从 `0xd000014c` 直接失败 → 退出码 0、83 条包全部「已安装」，就是 SECURITY 修好了。

其余该查的：

```cmd
dism /Image:C:\ /Get-MountedImageInfo        :: 应为空
dir C:\Windows\WinSxS\pending.xml            :: 不应存在
bcdedit /enum {default}                      :: partition=C:  \Windows\system32\winload.efi
fsutil dirty query C:                        :: 没有损坏
```

---

## 回滚

把 `hives\pre_repair_full\` 里的文件拷回 `C:\Windows\System32\config\` 即可。

注意：`pre_repair_full\SECURITY` 是当时盘上那份**外来 hive**（`seq 210/210`，机器名 `HXCN-WIN`），不是本机原件。要回到本机原件用 `hives\original_broken\SECURITY`（`seq 17965/17964`）——但它带着脏标志，直接用会开不了机，得先按上面的方法清脏标志。

---

## 几个坑

1. **`0xd0000043` 不是损坏，是共享冲突**。自己 `reg load` 过忘了 `reg unload`，下次 DISM 就会报这个错。日志里只出现过一次，就是这么来的。
2. **DISM 报「未识别 `/Image:C:\`」（错误 87）** 是命令行解析问题，换个顺序重敲就好，别去查 DISM 版本。
3. **换一个「能加载」的 hive 顶上去是假修复**。DISM 会通，但 LSA 发现 SECURITY 和 SAM 的域 SID 不一致，照样开不了机，`DPAPI_SYSTEM` 也不在里面。
4. **排查本身会产生垃圾**。我跑的几次 `DISM /ScanHealth` 和 `/Get-Packages` 在 `WinSxS\Temp\InFlight` 下留了 7335 个目录、1393 MB。查完记得删，`logs\inflight_mine.txt` 是当时的目录清单。
