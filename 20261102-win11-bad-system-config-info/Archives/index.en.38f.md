---
title: "When a 150 GB C Drive Runs Out of Space: Rescuing Windows 11 from Error 0x74 BAD_SYSTEM_CONFIG_INFO"
pubDatetime: 2026-11-02T00:00:00.000+08:00
slug: win11-bad-system-config-info-en
tags:
  - Windows 11
  - Registry
  - BSOD
  - WinPE
  - Data Recovery
category: 踩坑日志
description: "Troubleshooting guide for a Windows 11 laptop hit by 0x74 BAD_SYSTEM_CONFIG_INFO and 0xc0000001 boot errors after the C drive ran out of space. Covers BitLocker checks, bcdboot and DISM 0xd000014c failures, isolating the dirty flag in the SECURITY hive, applying a two-byte binary patch, and pausing Windows Update via the registry."
---

## Preface

I have always held a firm view on storage layout: for most everyday users and developers, a single partition per physical drive is plenty. If your system houses multiple physical solid-state drives, giving each drive its own volume keeps things tidy. If your machine runs on a single SSD, carving it into C and D drives at most is the absolute limit. In an era where modern software, runtime libraries, and game assets routinely eat dozens of gigabytes, leaving 200 GB, 300 GB, or even a full 512 GB for the system partition (C:) is the only comfortable safety margin for heavy workloads.

Many people still believe that installing software on drive D will keep their C drive clean, but Windows rarely works that way. Regardless of where you point an installer executable, runtimes, shared dependencies, temporary caches, and user profiles inevitably land in `AppData`, `ProgramData`, and temporary system directories on drive C. When the system drive is squeezed down to a meager slice, leaving available space hovering precariously around a few gigabytes or even a few hundred megabytes, applications begin crashing on unbuffered disk writes. In the worst cases, Windows quietly chokes during an unattended background update, rendering the machine completely unbootable.

Drive fragmentation across volumes makes this worse. Someone might purchase a fast 1 TB NVMe SSD and carve it up into four tiny slices. Months later, when trying to download a 150 GB modern game or unpack a massive dataset, they find themselves stuck. The drive has 300 GB of aggregate free space scattered across different letters, yet no individual volume can fit the payload, leaving that storage practically stranded.

The common belief that installing software on drive C guarantees total data loss during a reinstallation also falls apart under scrutiny. In modern Windows, the vast majority of complex applications installed on secondary partitions—office suites, development environments, databases, and heavy desktop tools—fail to run after a fresh Windows installation anyway. Their system-wide registry keys, Windows services, driver registrations, and COM components are wiped clean during the reinstall. You end up having to run their installers all over again.

What actually needs to be preserved before an operating system refresh is user data, not application binaries. Even when locked out of the desktop, booting into a live WinPE recovery environment lets you grab the essentials in minutes:
1. Chat histories and local archives (typically stored under `C:\Users\<username>\Documents`);
2. Standard user profile directories (`C:\Users\<username>\Downloads`, Desktop, Documents, Pictures, and Videos);
3. Browser bookmarks, exported passwords, and local credentials;
4. The user profile registry hive at `C:\Users\<username>\NTUSER.DAT` (mounting this file later allows you to inspect past software settings, preferences, and shell shortcuts);
5. Active encryption status: if BitLocker is enabled, you must verify you possess the 48-digit recovery key or fully decrypt the volume from PE before making partition modifications.

Once those files are safe on an external drive, laying down a fresh OS installation and restoring your personal files gets you back up and running with minimal downtime.

The lingering habit of chopping drives into multiple small letters dates back to an era of mechanical hard drives and legacy partitioning habits passed down over decades. People grew accustomed to treating partitions as digital file cabinets, and that mindset carried over into the modern NVMe era. I frequently get calls from peers whose laptops are frozen because their 120 GB or 150 GB C drive turned bright red. Every single time, rescuing them requires shuffling files across volumes to clear space for the operating system to breathe.

If anyone doubts how dangerous a starved system drive can be, the troubleshooting session I just ran on my roommate's laptop serves as textbook proof.

## Initial Guesses and Troubleshooting

### The Situation

My roommate uses an ASUS gaming laptop that shipped with Windows 11 Home Edition, kept up to date through standard Windows Update channels up to build 22631.5768. The machine was equipped with a 1 TB NVMe SSD from the factory. Unfortunately, when setting it up, he followed bad advice and carved the system partition down to a measly 150 GB, cramming it with MATLAB, SQL Server 2022, Microsoft Office, and an active Steam library.

One evening, while he was working, the screen went black without warning and kicked over to a Blue Screen of Death showing the stop code `BAD_SYSTEM_CONFIG_INFO`:

![Blue Screen of Death](bsod-bad-system-config-info-en.svg)

The machine attempted to reboot itself, crashed with the exact same blue screen, and looped again. After three consecutive crashes, Windows triggered its built-in recovery mechanism and entered the automatic diagnostic sequence. As is so often the case with automatic recovery, the wizard ran for a few minutes and ended on an unhelpful wall:

![Startup Repair Failed](startup-repair-failed-en.svg)

Because his C drive had been chronically low on space, System Protection had long been disabled to save disk room, meaning there were zero System Restore points available. Panicking over his coursework, he pulled out his phone and asked a commercial AI chatbot for suggestions. Following generic troubleshooting steps, he booted into the advanced recovery menu and tried launching Safe Mode, which promptly crashed with the exact same stop code.

When hardware passes basic checks and file systems scan clean, a failure during early boot typically points toward damaged UEFI boot records or a corrupted BCD (Boot Configuration Data) store.

I grabbed my Ventoy flash drive, booted the laptop into a live WinPE environment, and fired up DISM++ to inspect the offline installation and attempt an automated boot repair. Instead of loading the operating system, DISM++ threw an immediate modal dialogue: "An attempt was made to load an incorrectly formatted program." We brushed it off as a utility compatibility quirk and tried forcing a standard bootloader rebuild through the interface.

Upon rebooting, the blue screen stop code disappeared, but the laptop landed on an even more generic Windows Recovery screen reporting error code `0xc0000001`:

![Recovery Error 0xc0000001](recovery-error-0xc0000001-en.svg)

In the NTSTATUS architecture, `0xc0000001` translates to `STATUS_UNSUCCESSFUL`. It is a catch-all wrapper meaning that an essential kernel subsystem failed to initialize during boot. Surface-level repair tools had hit a dead end, so it was time to drop to the command prompt and work through the stack manually.

### Turning Off BitLocker

Before altering boot partitions or touching core files on an offline volume, the very first step is verifying BitLocker encryption status.

Modern OEM laptops frequently ship with Device Encryption enabled in a pre-provisioned state. Many people set up their machines using an offline local account without linking a Microsoft account. When you boot into a PE environment and modify boot entries or system binaries, the motherboard's TPM chip detects the change in platform integrity metrics on the next reboot. It locks the drive and demands a 48-digit BitLocker recovery key. If that key was never uploaded to an online account or written down, the data on the SSD becomes permanently inaccessible.

If a machine can still boot normally, checking for key protectors is straightforward by opening an administrative terminal and running:

```cmd
manage-bde -protectors -get C:
```

Users with linked Microsoft accounts can log into `https://account.microsoft.com/devices/recoverykey` from another device to locate their recovery keys. In our case, the laptop could not boot, and the account was local.

From the WinPE command line, we queried the status of drive C directly:

```cmd
manage-bde -status C:
```

The terminal returned:

```cmd
Conversion Status:    Fully Decrypted
Percentage Encrypted: 0.0%
Protection Status:    Protection Off
Lock Status:          Unlocked
Identification Field: None
Automatic Unlock:     Disabled
Key Protectors:       None Found

X:\Windows\System32>manage-bde -protectors -get C:
Volume C: [OS]
All Key Protectors

ERROR: No key protectors found.
```

Seeing "No key protectors found" was a huge relief. It confirmed that factory Device Encryption had remained in an unactivated staging phase. It had never generated a cryptographic key protector or locked the volume with TPM measurements. The partition was raw, unencrypted NTFS, meaning our PE environment had direct read and write access to the volume.

Next, we opened `diskpart` to get an exact map of the physical drive layout:

```cmd
DISKPART> list vol

  Volume ###  Ltr  Label        FS     Type        Size     Status     Info
  ----------  ---  -----------  -----  ----------  -------  ---------  --------
  Volume 0     C   OS           NTFS   Partition    150 GB  Healthy
  Volume 1     D   New Volume   NTFS   Partition    389 GB  Healthy
  Volume 2     E   New Volume   NTFS   Partition    389 GB  Healthy
  Volume 3         RESTORE      NTFS   Partition     24 GB  Healthy
  Volume 4         SYSTEM       FAT32  Partition    260 MB  Healthy    Hidden
  Volume 5         RECOVERY     NTFS   Partition    950 MB  Healthy    Hidden
  Volume 6     H   MYASUS       FAT32  Partition    260 MB  Healthy    Hidden
  Volume 7     F   Ventoy       exFAT  Removable    117 GB  Healthy
```

Volume 4 was the 260 MB FAT32 partition housing the UEFI boot files (ESP), while Volume 5 was the 950 MB OEM recovery partition containing `Winre.wim`.

To prevent any background mechanism from attempting to seal the volumes during our recovery work, we explicitly disabled BitLocker protection across every partition:

```cmd
manage-bde -off C:
manage-bde -off D:
manage-bde -off E:
```

### Trying the Standard Playbook

With encryption risks off the table, we walked through the standard triage sequence used by system administrators.

We started by checking the physical volume and file system integrity using `chkdsk`:

```cmd
X:\Windows\System32>chkdsk C: /f /r
The type of the file system is NTFS.
Volume label is OS.
...
Windows has scanned the file system and found no problems.
No further action is required.

  157286727 KB total disk space.
   15979136 KB are available.
```

The scan passed all five verification stages without a hitch, reporting 0 KB in bad sectors. The physical drive was completely sound, and NTFS metadata was clean.

Next, we rebuilt the UEFI boot environment from scratch. We selected Volume 4 in `diskpart` and assigned it temporary drive letter `S:`:

```cmd
DISKPART> select volume 4
DISKPART> assign letter=S
DISKPART> exit

X:\Windows\System32>bcdboot C:\Windows /s S: /f UEFI /l en-us
Boot files successfully created.
```

The bootloader files were generated properly, and `S:\EFI\Boot\bootx64.efi` sat at 1,698,760 bytes. To ensure fussy motherboard firmware wouldn't miss the entry point, we copied `S:\EFI\Microsoft\Boot\bootmgfw.efi` over `bootx64.efi` as well.

Then came the legacy `bootrec` commands:

```cmd
X:\Windows\System32>bootrec /scanos
Scanning all disks for Windows installations.
Total identified Windows installations: 0
The operation completed successfully.

X:\Windows\System32>bootrec /rebuildbcd
Scanning all disks for Windows installations.
Total identified Windows installations: 0

X:\Windows\System32>bootrec /fixboot
Access is denied.
```

Finding zero installations looks alarming at first glance, but on modern UEFI/GPT installations, this is expected behavior. `bootrec /fixboot` returns access denied on modern Windows builds by design, and `scanos` returns zero because it attempts to load and parse offline registry hives under `C:\Windows\System32\config\`. If those hives fail to load, `bootrec` simply ignores the installation.

We moved on to System File Checker and DISM:

```cmd
X:\Windows\System32>sfc /scannow /offbootdir=C:\ /offwindir=C:\Windows
Beginning system scan. This process will take some time.
Windows Resource Protection could not perform the requested operation.
```

SFC refused to initialize.

When running DISM to roll back pending updates, a typing mistake cropped up in the console:

```cmd
X:\Windows\System32>dism /Image:C\ /Cleanup-Image /RevertPendingActions
Error: 87
The /image option that is specified points to a directory that does not exist.
```

Missing the colon after `C` produced Error 87, a reminder that console typos in PE can easily mimic broken tools.

Correcting the syntax revealed the actual underlying failure:

```cmd
X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /RevertPendingActions
Deployment Image Servicing and Management tool
Version: 10.0.22621.1
Image Version: 10.0.22631.5768

The scratch directory size might be insufficient to perform this operation.
Reverting pending actions from the image...

Error: 0xd000014c

X:\Windows\System32>dism /Image:C:\ /Get-Packages /Format:Table
...
Error: 0xd000014c
DISM failed. No operation was performed.
```

Both package enumeration and action rollbacks crashed with error code `0xd000014c`.

We opened `C:\Windows\System32\Logfiles\Srt\SrtTrail.txt` to see what Startup Repair had documented across its 64 attempts. Tests for the system disk, partition integrity, boot manager, and event logs had all passed with error code `0x0`. The failure hit at the very end of the diagnostics pass:

```cmd
Session 1   Name: Check for installed LCU   Result: Completed successfully. Error code = 0x43
Session 2   Number of root causes = 1
            Root cause found: Startup Repair has tried several times but still cannot determine the cause of the problem.
Session 3   Name: Check for installed LCU   Result: Completed successfully. Error code = 0x14c
```

LCU stands for Latest Cumulative Update. Startup Repair was attempting to verify whether a recently applied monthly update was healthy. To check update state, it had to parse the offline registry. Error `0x14c` translates directly to hexadecimal `0xC000014C`—the exact same `0xd000014c` error thrown by DISM.

At this point, we checked the free space on drive C in File Explorer.

The 150 GB partition had **a little over 100 megabytes of free space remaining**.

My roommate had not paid attention to storage warnings, keeping the laptop running while the disk was completely suffocated. We immediately deleted a couple of massive, unneeded archives from his desktop and cleaned out temporary download caches, bringing available space up to roughly 8.9 GB (the free space later reflected during our `chkdsk` run).

With disk headroom restored, we opened `X:\windows\Logs\DISM\dism.log` to track down which file was choking the loader:

```cmd
CBS  Loading offline registry hive: SOFTWARE, into registry key '{bf1a281b-...}C:/Windows/System32/config/SOFTWARE'
CBS  Loading offline registry hive: SYSTEM, into registry key '{bf1a281b-...}C:/Windows/System32/config/SYSTEM'
CBS  Loading offline registry hive: SECURITY, into registry key '{bf1a281b-...}C:/Windows/System32/config/SECURITY'
CBS  Failed to load offline \\?\C:\Windows\System32\config\SECURITY hive from '...' [HRESULT = 0xd000014c - NTSTATUS Error]
CBS  Failed to load offline SECURITY hive. [HRESULT = 0xd000014c - NTSTATUS Error]
CBS  Force unloading offline registry hive: ... SOFTWARE
CBS  Force unloading offline registry hive: ... SYSTEM
CBS  Failed to load offline store from boot directory: '\\?\C:\' [HRESULT = 0xd000014c]
```

CBS (Component Based Servicing) loads registry hives sequentially: `SOFTWARE`, then `SYSTEM`, then `SECURITY`. The first two loaded cleanly. The third one, `SECURITY`, triggered status `0xd000014c`, forcing CBS to unload the other two and abort.

Seeing this, I had an idea that seemed logical at the time: if the `SECURITY` hive was simply corrupted, why not replace it with the clean `SECURITY` hive from my own Windows 11 laptop?

We backed up his original file:

```cmd
md C:\Windows\System32\config\CorruptBak
move C:\Windows\System32\config\SECURITY* C:\Windows\System32\config\CorruptBak\
```

I copied the `SECURITY` hive from my laptop onto a thumb drive, pasted it into `C:\Windows\System32\config\`, created a scratch folder on drive D (`D:\backup`), and reran DISM:

```cmd
X:\Windows\System32\config>dism /Image:C:\ /ScratchDir:D:\backup /Cleanup-Image /RevertPendingActions
Deployment Image Servicing and Management tool
Version: 10.0.22621.1
Image Version: 10.0.22631.5768

Reverting pending actions from the image...
The operation completed. The changes will be reverted when the computer is restarted.
The operation completed successfully.
```

DISM returned "The operation completed successfully." We removed `C:\Windows\WinSxS\pending.xml`, ran `chkdsk C: /f`, and pulled the USB drive out, confident the machine was saved.

We powered it on.

The laptop spun its loading wheels for three seconds, flashed black, and dropped right back into the blue `0xc0000001` recovery screen.

Replacing the file had satisfied DISM, but the kernel still refused to boot.

## Deep Dive with an AI Agent

Basic recovery tools had run their course. To dig deeper, I switched from our basic WinPE image to FirPE, which provides full network support and a complete scriptable runtime. We connected the laptop to Wi-Fi, installed `oh-my-pi` (omp), and brought in an AI agent equipped with systems debugging skills to inspect the operating system from the ground up.

### Pinpointing the Culprit from Logs and Crash Dumps

We began by inspecting the sole kernel crash dump on the machine: `C:\Windows\Minidump\110226-9312-01.dmp`. Running an inspection script against the dump header produced definitive output:

```cmd
signature   = PAGE / DU64
major/minor = 15.22621
bugcheck    = 0x74  (BAD_SYSTEM_CONFIG_INFO)
P1 = 0x2
P2 = 0xffff94869fbd2940
P3 = 0x1
P4 = 0xffffffffc000014c
crash_time  = 2026-11-02 07:36:19 UTC (15:36:19 local time)
ascii_str   = "HiveLoadFromomFile" + "status"
utf16_str   = "<SECURITY"
```

Bugcheck `0x74` parameter `P4` was explicitly `0xffffffffc000014c` (`STATUS_REGISTRY_CORRUPT`). The embedded strings confirmed that the crash occurred inside `HiveLoadFromFile` while processing the `<SECURITY` hive path.

We cross-referenced this against `C:\Windows\Logs\CBS\CBS.log` and found the initial failure recorded on the evening of October 23:

```cmd
2026-10-23 18:36:21, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:23, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:25, Info  CBS  System volume has 0G free disk space
```

Following those entries was `Maint: incomplete, interruptions: 1`. Days prior to the hard crash, Windows Update had already stalled midway through writing data because the disk hit zero bytes of available space.

Examining `C:\Windows\System32\Logfiles\Srt\DISMRepairLogFile.txt` showed 12 separate attempts where `SECURITY` failed to load with `0xd000014c` between November 1 at 17:35 and November 2 at 13:55.

There was only a single entry mentioning `SYSTEM` on November 2 at 15:21:12:
`Failed to load offline ... SYSTEM hive ... [HRESULT = 0xd0000043 - NTSTATUS Error]`

Status `0xd0000043` is `STATUS_SHARING_VIOLATION`. This happened because earlier in the afternoon, I had manually run `reg load HKLM\TEMP C:\Windows\System32\config\SYSTEM` in the PE terminal to test the hive and forgot to run `reg unload`. The open handle locked DISM out. This reinforced a crucial troubleshooting lesson: always distinguish true system faults from the artifacts of your own investigation.

### Why Dropping In My Own SECURITY Hive Still Failed to Boot

Why did DISM report success with my borrowed `SECURITY` hive while the kernel refused to boot?

Because structural validity is not machine identity.

DISM parses hives as an offline file system engine. As long as a hive's B-Tree branches are internally consistent and block checksums validate, DISM accepts it. But when the Windows kernel takes over during boot, the Local Security Authority Subsystem Service (LSASS) validates the security identifiers and secrets bound to the physical hardware.

Parsing the foreign `SECURITY` hive alongside my roommate's `SAM` hive laid the problem bare:

```cmd
Foreign SECURITY hive:
ComputerName:   HXCN-WIN
Machine SID:    S-1-5-21-1262172508-...

Roommate's local SAM hive:
ComputerName:   LAPTOP-VQSR6OMV
Machine SID:    S-1-5-21-4291209427-303460211-4247354471
```

The domain SID inside the foreign file belonged to my desktop (`HXCN-WIN`). It conflicted directly with the domain SID stored in his machine's `SAM` hive. During early boot, LSASS detects this identity mismatch and aborts initialization immediately.

Worse, the `Policy\Secrets` subkey contained credentials exclusive to my machine. The critical `DPAPI_SYSTEM` master secret belonging to his laptop was completely missing. Had the system somehow bypassed the SID check and booted with my hive, all of his local DPAPI-encrypted data—saved passwords in Chrome and Edge, credential manager entries, Wi-Fi profiles, and EFS private keys—would have been permanently destroyed.

Copying a foreign hive had simply substituted an unreadable file for an identity conflict. The genuine original hive sitting in `CorruptBak\SECURITY` was the only viable path forward.

### Sequence Numbers 17965 and 17964: The Two-Byte Dirty Flag

To understand why Windows flagged the original `CorruptBak\SECURITY` as corrupted, we inspected its binary layout according to the Windows Registry File (`regf`) format specification.

Every standard registry hive begins with a 4,096-byte (4 KB) Base Block, followed by data allocated in 4 KB `hbin` chunks:

```
Offset 0x000   4 bytes   Magic ASCII "regf" signature
Offset 0x004   4 bytes   Primary sequence number (seq1)
Offset 0x008   4 bytes   Secondary sequence number (seq2)
Offset 0x01C   4 bytes   Hive type (0 = standard primary hive file)
Offset 0x024   4 bytes   Relative offset of root cell (nk) in data area
Offset 0x028   4 bytes   Total size of hbins data area
Offset 0x1FC   4 bytes   Header checksum
```

The checksum covers the first 504 bytes (from offset `0x000` to `0x1F8`), calculated via a bitwise XOR of every 32-bit DWORD. If the XOR sum equals `0xFFFFFFFF`, it normalizes to `0xFFFFFFFE`; if it equals `0`, it normalizes to `1`.

Reading the header of `CorruptBak\SECURITY` yielded:
Length: 65,536 bytes; `seq1 = 17965`; `seq2 = 17964`; Header Checksum: `0xb3d51b08`. The internal checksum was mathematically valid.

The condition `seq1 != seq2` is the registry's **dirty flag**.

The Windows kernel uses a two-phase commit model when flushing registry modifications to disk. Before writing altered pages, the kernel updates `seq1` to `seq2 + 1`. Once all modified pages are committed to storage, it updates `seq2` to match `seq1`. If disk space runs out or power cuts out mid-transaction, `seq2` remains one step behind.

Under normal circumstances, if Windows encounters a dirty hive at boot, it replays matching transaction logs (`SECURITY.LOG1` / `SECURITY.LOG2`) to finish the transaction and sync the sequence counters.

Looking at the log files on disk revealed why auto-recovery failed:
`SECURITY.LOG1` was 48 KB, but its sequence counter was stuck at `208` (an unpurged log from initial factory setup in 2022).
`SECURITY.LOG2` was 8 KB, but its sequence counter was stuck at `17963`, trailing the main hive's transaction state by two steps.

The log chain was severed. With no valid log records to replay, the kernel had no choice but to declare the dirty hive `STATUS_REGISTRY_CORRUPT`.

To test how the kernel evaluates this condition, we constructed ten controlled test cases on drive D using copies of the hives (`scripts\matrix*.cmd`):

| Test Case | Hive Sequence State | Accompanying Logs | `reg load` Result |
|---|---|---|---|
| `s1` | Dirty `17965/17964` | No logs present | **Failed** |
| `s2` | Dirty `17965/17964` | Zero-byte dummy logs | **Failed** |
| `s3` / `a` | Dirty `17965/17964` | Stale logs `LOG1(208) + LOG2(17963)` | **Failed** |
| `h` | Dirty `17965/17964` | Stale `LOG2(17963)` only | **Failed** |
| `t1` | Dirty `17965/17963` (seq2 - 2, checksum updated) | No logs | **Failed** |
| `t2` | Clean `17964/17964` (seq1 rolled back, checksum updated) | No logs | Passed |
| `i` | Clean `17965/17965` (seq2 advanced, checksum updated) | No logs | Passed |
| `j` | Clean `17965/17965` (seq2 advanced, checksum updated) | **Stale logs left in directory** | Passed |
| `s4` | Sequence numbers matched (`17965/17965`), **checksum not updated** | No logs | **Failed** |

These tests established an absolute rule:
**The kernel refuses to load a hive purely because the dirty flag is set. As long as `seq1 != seq2`, the load fails regardless of log presence. As long as `seq1 == seq2` and the header checksum at `0x1FC` is recalculated correctly, the hive loads cleanly even if outdated logs sit right next to it.**

We ran a full B-Tree traversal across the data cells of `CorruptBak\SECURITY`. All 166 key cells, 164 value cells, and 33 subkey index arrays were structurally sound. Pointers resolved cleanly within the declared 53,248-byte allocation boundary, with zero orphan cells and zero parent pointer mismatches. The underlying data had reached the disk safely; the system simply ran out of space before updating `seq2`.

### Uncovering the Dirty BBI Hive and the Orphaned Driver

A complete scan of all registry hives revealed two additional issues.

The first was `C:\Windows\System32\config\BBI`, a 1,310,720-byte (1.25 MB) hive used by the Boot Environment Infrastructure to track background servicing priorities and UWP package queues. It sat in an identical dirty state: `seq1 = 53232, seq2 = 53231`, with 0-byte transaction logs. It was not critical enough to halt the kernel—it had been dirty since October 31, yet the machine booted on November 1—but leaving a known-broken hive in place invites future crashes.

The second issue surfaced during our driver audit. We scripted an inspection of all boot-start (`Start=0`) and system-start (`Start=1`) drivers under `ControlSet001\Services` in the `SYSTEM` hive, verifying each binary on disk:

```cmd
HKLM\SYSTEM\ControlSet001\Services\softaal
  ImagePath    = \??\C:\Program Files (x86)\Tencent\QQPCMgr\15.1.22354.301\softaal64_ev.sys
  Start        = 1  (SERVICE_SYSTEM_START)
  ErrorControl = 0  (IGNORE)
```

This service belonged to Tencent PC Manager. The software had auto-updated to version 15.6 months earlier, purging the old `15.1.22354.301` directory from disk, but its installer had failed to clean up the startup service pointer. Because `ErrorControl` was set to 0, the kernel logged the missing driver and continued, but fixing it meant one less point of failure during startup. Setting `Start` to `4` (Disabled) eliminated the error.

## The Fix

### Why the ISO's 9 MB SYSTEM Hive Can't Overwrite Yours—and Why You Still Need the ISO

When faced with registry corruption, a common suggestion online is to pull fresh hives from a clean Windows installation ISO. Comparing the hives from our mounted `Win11_23H2_Chinese_Simplified_x64v2.iso` against the laptop's actual installation explains why this is disastrous:

| Registry Hive | Pristine Template in ISO Image | Live System Hive on Laptop | Consequence of Overwriting with Image Template |
|---|---|---|---|
| `SYSTEM` | 9,175,040 bytes, 661 services, computer name `MINWINPC` | 32,243,712 bytes, 846 services, computer name `LAPTOP-VQSR6OMV` | Erases all OEM storage drivers (such as Intel RST / iaStorVD), chipset drivers, and Plug-and-Play device trees. Booting immediately halts with an unrecoverable `INACCESSIBLE_BOOT_DEVICE` blue screen. |
| `SAM` | 8,192 bytes, completely blank database | 131,072 bytes, 5 local user accounts | Destroys all user profiles and security accounts. |
| `SECURITY` | 8,192 bytes, blank template | 65,536 bytes, contains machine SID and local secrets | Wipes out LSA encryption keys and destroys all DPAPI-encrypted user credentials. |
| `SOFTWARE` | 66,584,576 bytes, baseline defaults | 117,440,512 bytes, complex state | Breaks all installed desktop applications, file associations, and environment settings. |
| `BBI` | 8,192 bytes, empty queue | 1,310,720 bytes, historical records | **The only hive that can safely be replaced from an image**, as an empty queue simply resets background task history without impacting boot. |

Furthermore, the ISO image build was `22631.2861`, whereas the laptop was running build `22631.5768`. Windows Setup blocks in-place repair upgrades when the installation media is older than the installed operating system.

The original ISO served two specific purposes: providing a clean reference baseline to confirm which system drivers lack an `ImagePath` by design, and standing by as installation media if low-level repair failed. It could not be used as a drop-in file source.

### Full Backup, Two-Byte Patch, and Stale Log Quarantine

With the scope of the problem isolated, we executed the repair using targeted byte-level edits.

We began by creating a full, timestamped backup of all 43 files inside `C:\Windows\System32\config\` (238.1 MB) to `D:\_fix\backup_20261102120607\config\`, verifying every file with SHA-256 hashes to guarantee complete rollback capability.

Then we patched the hives:

**1. Patching the `SECURITY` Hive**
Working on `CorruptBak\SECURITY` (65,536 bytes), we modified two fields:
- At offset `0x008`, we changed `seq2` from `17964` (`2c 46 00 00`) to `17965` (`2d 46 00 00`), matching `seq1` and clearing the dirty flag.
- At offset `0x1FC`, we recalculated the 32-bit XOR sum across the first 504 bytes, updating the header checksum from `0xb3d51b08` to `0xb3d51b09`.

We tested the patched file by loading it into the registry in PE:

```cmd
reg load HKLM\TEST C:\Windows\System32\config\CorruptBak\SECURITY
reg unload HKLM\TEST
```

It mounted without error, after which we copied it back to `C:\Windows\System32\config\SECURITY`.

**2. Quarantining Severed Logs**
To prevent the kernel from attempting to reconcile mismatched transaction chains on startup, we moved `SECURITY.LOG1` (48 KB, seq 208) and `SECURITY.LOG2` (8 KB, seq 17963) out of the config directory into `D:\_fix\quarantine\`. On the next clean boot, Windows generates fresh transaction logs automatically.

**3. Patching the `BBI` Hive**
We repeated the patch on `C:\Windows\System32\config\BBI`: updating `seq2` at offset `0x008` from `53231` to `53232` and writing the recalculated checksum to offset `0x1FC`. The hive loaded cleanly, preserving all 81 queued items.

**4. Disabling the Orphaned `softaal` Driver**
We mounted the live system hive and updated the service start type:

```cmd
reg load HKLM\OFFLINESYS C:\Windows\System32\config\SYSTEM
reg add "HKLM\OFFLINESYS\ControlSet001\Services\softaal" /v Start /t REG_DWORD /d 4 /f
reg unload HKLM\OFFLINESYS
```

Setting `Start` to 4 disabled the non-existent service permanently.

### Clearing the Hibernation File and Update Leftovers

With the registry repaired, we turned to the issue that started the chain reaction: storage exhaustion.

We inspected `C:\hiberfil.sys`, which took up 6,715,396,096 bytes (6.25 GB). Reading the first 4,096 bytes revealed nothing but zeroed memory (`0x00`). The hibernation header had been invalidated during previous hard crashes, meaning `winresume.efi` could never restore from it. It was consuming over six gigabytes of space for nothing. We removed it immediately:

```cmd
del /f /a /q C:\hiberfil.sys
```

Next, after verifying through the registry that no Windows Setup tasks were pending (`SetupType = 0`, `SystemSetupInProgress = 0`), we cleaned out abandoned update staging folders:
- `C:\$WinREAgent`: 1.77 GB of cached recovery update packages.
- `C:\$Windows.~BT`: 56.7 MB of update remnants.
- `C:\$SysReset`: 0.3 MB of aborted reset logs.
- `C:\Windows\SoftwareDistribution\Download`: 65.5 MB of failed update downloads.

These removals expanded free space on the C drive from roughly 100 MB to well over **16 GB**.

### Post-Repair Verification

Before restarting the machine, we ran our verification scripts across the offline installation:

1. **All Nine Registry Hives Healthy**:
   Running `verify_final.cmd` tested `SYSTEM`, `SOFTWARE`, `SAM`, `SECURITY`, `DEFAULT`, `DRIVERS`, `COMPONENTS`, `ELAM`, and `BBI`. Every single hive reported `seq1 == seq2` and mounted cleanly.
2. **Identity and Secret Validation**:
   Checking the patched `SECURITY` hive confirmed `PolAcDmN` matched `LAPTOP-VQSR6OMV` and `PolAcDmS` matched the local SAM domain SID `S-1-5-21-4291209427-303460211-4247354471`. All eight entries under `Policy\Secrets`, including `DPAPI_SYSTEM`, were intact.
3. **Component Store Verification**:
   We ran package enumeration from PE:
   
   ```cmd
   dism /Image:C:\ /Get-Packages /Format:Table
   ```
   
   Instead of crashing with `0xd000014c`, DISM returned error code 0, listing all 83 installed update packages with state `Installed` and zero packages pending.
   
   We followed up with a component store health scan:
   
   ```cmd
   dism /Image:C:\ /Cleanup-Image /ScanHealth
   ```
   
   The scan completed at 100%, reporting: "No component store corruption detected. The operation completed successfully."

With the boot configuration intact, drivers validated, and all registry hives accessible, the system was ready for reboot.

## Epilogue

### Cleaning Up InFlight Temp Directories and Booting Up

During our final sweep, we encountered one last quirk of the Windows servicing stack.

Running offline DISM commands like `/ScanHealth` and `/Get-Packages` creates temporary working files. Checking `C:\Windows\WinSxS\Temp\InFlight` revealed 7,335 newly generated working folders consuming 1,393 MB of space. Clearing those transient directories brought final free space on drive C to **16.5 GB**.

We unmounted our tools, removed the USB drive, and hit the power button.

The screen lit up, fans spun, and the red ASUS logo appeared. The progress spinner completed two smooth rotations, the recovery screen never appeared, and Windows 11 dropped straight into the user login screen.

My roommate typed in his PIN, hit enter, and arrived at his familiar desktop. His IDE workspaces, local database servers, browser profiles, and personal files were completely untouched. The machine had been recovered without a single byte of data loss.

### Pausing Windows Update for 1,000 Weeks via the Registry

Once the system was running, we addressed the underlying trigger.

While a cramped 150 GB partition set the stage for disk exhaustion, the spark was **Windows Update** downloading and committing patches in the background without checking available headroom.

Recent Windows 11 quality updates have introduced well-documented regressions:
- **August 2025 Updates (KB5063878 / KB5063875)**: Caused certain NVMe drives using Phison and InnoGrit controllers to drop off the PCI bus during sustained writes, while breaking the built-in "Reset this PC" feature and forcing an emergency out-of-band patch.
- **October 2025 Security Update (KB5066835)**: Broke local loopback (`127.0.0.1`) connections for developers and stripped USB mouse and keyboard drivers inside the Windows Recovery Environment (WinRE), locking users out of recovery menus until Microsoft released emergency patch KB5070773.
- **January 2026 Update (KB5074109) and February Update (KB5077181)**: Introduced `UNMOUNTABLE_BOOT_VOLUME` boot loops, froze classic Outlook PST operations, broke shutdown handling, and triggered DHCP failures on specific network adapters.

Third-party debloating utilities that aggressively rip out the Windows Update service often create more problems than they solve. Stripping the service breaks CBS dependencies, preventing the installation of optional features like .NET Framework 3.5, language packs, and WSL2.

A much cleaner approach is extending the update pause duration through the registry to 1,000 weeks (roughly 19 years). This leaves servicing binaries intact while preventing Windows from downloading or staging updates in the background.

Save the following text as a `.reg` file (for example, `windows-1000weeks-update-blocker.reg`) and double-click to import it:

```ini
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

The keys configure explicit pauses:
- `FlightSettingsMaxPauseDays` sets the pause window to `0x1b58` (7,000 days in decimal).
- The remaining timestamps pin the pause window for feature and quality updates all the way to **September 2042**.

After importing, opening Windows Update in Settings will display the pause active through 2042.

If you ever want to resume normal updates, save the following as `windows-1000weeks-update-blocker-recovery.reg` and import it to clear the overrides:

```ini
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

Before finishing up, I sat down with my roommate, backed up his secondary partitions, and repartitioned the 1 TB SSD into a single spacious C drive with 350 GB allocated to the system partition.

Computers should work for you, not keep you on edge. Giving your operating system enough room to breathe and taking manual control of update cycles is the best way to keep Windows stable over the long haul.
