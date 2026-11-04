---
title: "When a 150 GB C: Drive Fills Up: A BAD_SYSTEM_CONFIG_INFO Rescue Story"
pubDatetime: 2026-11-02T00:00:00.000+08:00
slug: win11-bad-system-config-info-en
tags:
  - Windows 11
  - Registry
  - BSOD
  - WinPE
  - Data Recovery
category: 踩坑日志
description: A first-person rescue log of a Win11 23H2 machine hit by 0x74 BAD_SYSTEM_CONFIG_INFO after the C: drive filled up, from BitLocker checks and failed bcdboot/bootrec attempts to repeated DISM 0xd000014c errors, then isolating the SECURITY hive's dirty flag with byte-level comparison and controlled load experiments, and finally fixing it by patching two fields. Useful for anyone dealing with Windows registry corruption or boot failures.
---

## Preface

Let me state my position up front: for most people, one partition per drive is plenty. If you have multiple drives, one partition each is fine. If you have a single drive, C: and D: at most. And your C: drive should be at least 200 to 300 GB, or 512 GB if you're a heavy user.

Here's why. You can install software on D: or E:, but Windows and most applications dump their caches, temp files, system components, and user profile data onto C: by default. If C: is too small and running low on space, a lot of software won't run properly, and in the worst case the system won't even boot. There's also the classic scenario where you have a large game installer or a big file, your total free disk space across all partitions is more than enough, but no single partition has enough room on its own. You end up staring at an error message.

A lot of people say you shouldn't install software on C: because you'll lose it when you reinstall Windows. That argument doesn't hold up. After a reinstall, the software you installed on D: will also have lost its registry entries and won't run properly either. You'll have to reinstall it anyway. Instead of spending energy on partitioning, figure out what you actually need to back up before a reinstall: your chat history (usually under `C:\Users\<username>\Documents`), your Downloads folder (`C:\Users\<username>\Downloads`), photos and videos, Desktop files, saved passwords and keys, plus a copy of `C:\Users\<username>\NTUSER.DAT` (this file holds your user profile settings, and after a reinstall you can use it to check what software you had installed and what was on your Desktop). If the machine has BitLocker enabled, unlock it first or back up the recovery key. Once you've backed all that up, reinstall Windows, reinstall your software, and restore your files. Done.

Ten-plus years ago, when I first started messing with computers, my dad's generation loved splitting a hard drive into four partitions. That habit stuck around. Today, a lot of people still buy computers and have the shop or the person setting it up split the drive into four small partitions. The result is a bunch of machines with modest hard drives but way too many partitions, and C: ends up with just a few dozen or hundred GB. I regularly get friends asking for help because their C: drive is full, and every time I have to shuffle files around on the other partitions to free up space on C:.

If you want to argue with me about this, my roommate's laptop randomly blue-screening is a perfect counterexample.

## Initial Guesses and Troubleshooting

### The Situation

My roommate's ASUS laptop came with Windows 11 Home pre-installed and had been auto-updating all the way to `22631.5768`. The SSD is 1 TB, split into C: at 150 GB, D: at 389 GB, E: at 389 GB, plus a 24 GB ASUS recovery partition. C: had MATLAB, SQL Server 2022, Office 2014, and a Steam game library installed on it, so it was always tight on space.

One day it booted straight into a blue screen with `BAD_SYSTEM_CONFIG_INFO`, auto-restarted, and blue-screened again.

![BSOD crash screen](bsod-bad-system-config-info-en.svg)

After a few rounds of this, Windows kicked into Startup Repair automatically, but as expected, Startup Repair couldn't fix the machine:

![Startup Repair failed](startup-repair-failed-en.svg)

Because C: had been stuffed full for a long time, System Protection didn't have much space to work with, and there were no usable restore points. Rolling back via System Restore wasn't an option. My roommate had already spent a while asking an AI chatbot for help, following its suggestions and running several rounds of checks. Nothing worked.

My first reaction after hearing all this: `chkdsk` came back clean, so the SSD itself was probably fine. `sfc` didn't complete, but that didn't necessarily mean system files were the main problem. Since the drive was healthy and system files looked okay, the most likely suspect was a corrupted boot configuration. So the first thing to try was fixing the boot.

I booted into PE from a Ventoy USB drive and opened DISM++. It immediately threw an error: "attempting to load an incorrect format." That was abnormal. DISM++ couldn't do its job, which meant it couldn't even read the offline system's registry hives. I tried having it repair the boot anyway, and after a restart, the error on screen changed to `0xc0000001`:

![Recovery error screen 0xc0000001](recovery-error-0xc0000001-en.svg)

`0xc0000001` doesn't carry much information on its own. It basically means "something failed during boot," which tells you nothing. The real answers are in the crash dump and the logs.

### Turning Off BitLocker

Once I was in PE, the first thing I checked was BitLocker status. Factory-installed Windows 11 machines often have Device Encryption pre-enabled, with the key backed up to a Microsoft account. But my roommate's machine uses a local account and has never been signed into a Microsoft account. If the drive got locked at this point, there'd be nowhere to find the recovery key.

So I ran:

```cmd
manage-bde -status C:
```

```cmd
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

"Key Protectors: None Found" is actually good news here. It means Device Encryption was never fully activated on this machine, and no protectors were ever generated. Without protectors, there's no key to lose. C: is plain NTFS, and PE can read it directly.

I also checked the disk layout with `diskpart`:

```cmd
DISKPART> list vol

  Volume ###  LTR  Label        FS     Type        Size     Status     Info
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

The main point of this step was to confirm that Volume 4 is the EFI boot partition (ESP), which `bcdboot` would need later, and to verify that the recovery partition and the Ventoy USB drive were both present.

To be safe, I ran `manage-bde -off` on C:, D:, and E: to prevent TPM from re-locking the drives during later operations or reboots:

```cmd
manage-bde -off C:
manage-bde -off D:
manage-bde -off E:
```

One side note: if your machine has BitLocker fully enabled and the key is backed up to a Microsoft account, you can visit [https://aka.ms/myrecoverykey](https://aka.ms/myrecoverykey) from another device, sign in, and find your recovery key there. This machine wasn't tied to a Microsoft account, so that option wasn't available.

### Trying the Standard Playbook

With BitLocker ruled out, I started working through the standard repair process.

First, mount the ESP and rebuild the boot files:

```cmd
DISKPART> select volume 4
DISKPART> assign letter=S
DISKPART> exit

X:\Windows\System32>bcdboot C:\Windows /s S: /f UEFI /l zh-cn
Boot files successfully created.
```

The boot files were indeed written. `S:\EFI\Boot\bootx64.efi` existed at 1,698,760 bytes. As a double precaution, I also manually copied `S:\EFI\Microsoft\Boot\bootmgfw.efi` over `S:\EFI\Boot\bootx64.efi`.

Next up was `bootrec`:

```cmd
X:\Windows\System32>bootrec /scanos
Scanning all disks for Windows installations...
Total identified Windows installations: 0
The operation completed successfully.

X:\Windows\System32>bootrec /rebuildbcd
Scanning all disks for Windows installations...
Total identified Windows installations: 0

X:\Windows\System32>bootrec /fixboot
Access is denied.
```

`scanos` found 0 installations, and `fixboot` straight-up denied access. `bootrec` determines whether Windows is present by reading volume mappings and controller configs from the offline registry, and if it can't read those, it won't recognize anything. But those two errors alone didn't carry enough information for me to draw a conclusion at the time.

Then came the file system and component store:

```cmd
X:\Windows\System32>chkdsk C: /f
The type of the file system is NTFS.
Volume label is OS.
...
Windows has scanned the file system and found no problems.
No further action is required.

  157286727 KB total disk space.
   15979136 KB available.
```

All five stages of `/f` passed, and even the bad sector count was 0. The file system was clean. The "bad hard drive" theory held up as ruled out.

```cmd
X:\Windows\System32>sfc /scannow /offbootdir=C:\ /offwindir=C:\Windows
Beginning verification phase of system scan.
Windows Resource Protection could not perform the requested operation.
```

```cmd
X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /RestoreHealth
Error: 87

DISM does not recognize the command-line option "/Image:C:\".
```

DISM saying it doesn't recognize `/Image:C:\` is a command-line parsing issue, not a problem with the image itself. I later checked `dism.log` and found that the actual input was `/Image:C\`, missing a colon. These little detours waste the most time because they make you think DISM itself is broken, and you go off checking tool versions instead.

The two commands that actually mattered:

```cmd
X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /RevertPendingActions
Deployment Image Servicing and Management tool
Version: 10.0.22621.1
Image Version: 10.0.22631.5768

Reverting pending actions from the image...

Error: 0xd000014c
```

```cmd
X:\Windows\System32>dism /Image:C:\ /Get-Packages /Format:Table
...
Error: 0xd000014c

DISM failed. No operation was performed.
```

`0xd000014c` is `0xC000014C` with the customer bit set, which matches P4 from the crash dump exactly. In other words, DISM and the kernel were dying on the same thing.

At this point I pulled up the `SrtTrail.txt` generated by Startup Repair:

```cmd
Last successful boot time: 2026/11/1 9:32:11 (GMT)
Number of repair attempts: 64
```

Each session runs a dozen or so tests, and everything before the last one shows `0x0`. Only the final test fails:

```cmd
Session 1   Name: Check for installed LCU   Result: Completed. Error code = 0x43
Session 2   Root cause count = 1
            Root cause found:
            Startup Repair has tried several times but still cannot determine the cause.
Session 3   Name: Check for installed LCU   Result: Completed. Error code = 0x14c
```

That `0x14c` in session 3 matches DISM and P4 from the crash dump exactly. Startup Repair tries to read the "installed LCU" list, which requires opening the CBS store, and the CBS store needs to load offline registry hives, so it circles back to the same problem. As for session 2's "cannot determine the cause," that's the literal output after 64 attempts, and it reads pretty helplessly.

At this point, the "corrupted boot" theory could be ruled out. The ESP was fine, BCD was fine, `winload.efi` was present, and all dozen-plus Startup Repair checks passed.

Following the AI chatbot's suggestions, I also tried rolling back pending updates, clearing pending update transactions, checking and uninstalling recently installed update packages, and testing the ControlSet backup control set. None of it helped. Both "check for installed LCU" and "check for updates" fundamentally require loading the registry first, so they were bound to fail.

Then I noticed something: C: had only about 100 MB of free space left. I helped my roommate delete some unimportant large files from the Desktop, which freed up about 8.9 GB.

Combining the logs in `dism.log` with this disk space data, my guess was that extreme disk exhaustion had caused registry corruption: Windows Update or CBS tried to write to a registry hive while the disk was too full to write, corrupting a hive file and triggering this whole chain of failures.

Since `0xd000014c` clearly pointed to registry corruption, and `DISMRepairLogFile.txt` repeatedly showed "Failed to load offline SECURITY hive," I zeroed in on the `SECURITY` hive. I copied a structurally sound `SECURITY` file from my own computer, ready to swap it in and see what happened.

## Deep Dive with an AI Agent

After the swap, DISM's errors did go away, but the machine still wouldn't boot after a restart, same `0xc0000001`. I asked the AI chatbot to list which other components might be corrupted, and it suggested replacing `SAM`, `COMPONENTS`, and even continuing to overwrite hives from the ISO. But that path was dangerous, and I didn't want to rush into it.

I installed oh-my-pi in FirPE with network access and started using an AI agent to systematically investigate the problem. Instead of jumping straight to replacement suggestions like the chatbot did, the agent pulled together all the logs, crash dumps, and registry hives and analyzed them first.

### Pinpointing the Culprit from Logs and Crash Dumps

The agent first confirmed the key entries in the CBS log:

```cmd
2026-10-23 18:36:21, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:23, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:25, Info  CBS  System volume has 0G free disk space
```

Right after those came `Maint: incomplete, interruptions: 1`. This proved that on October 23, C: was genuinely written full to 0 bytes free. My roommate cleared a few GB at the time and kept using the machine, and for the next eight or nine days everything worked fine.

The dividing line was November 1. `SrtTrail.txt` records the last successful boot as `2026/11/1 9:32:11 (GMT)`, which converts to 17:32 local time on November 1. DISM's repair log starts showing "SECURITY load failed" at 17:35 on November 1 and continues until 15:21 on November 2. The last crash dump timestamp is 15:36 on November 2.

The agent read out the header of `C:\Windows\Minidump\110226-9312-01.dmp`:

```cmd
signature   = PAGE / DU64
major/minor = 15.22621
bugcheck    = 0x74  (BAD_SYSTEM_CONFIG_INFO)
P1 = 0x2
P2 = 0xffff94869fbd2940
P3 = 0x1
P4 = 0xffffffffc000014c
Crash time  = 2026-11-02 07:36:19 UTC (= 15:36 local)
Embedded ASCII  = "HiveLoadFromomFile" + "status"
Embedded UTF-16 = "<SECURITY"
```

P4 is `0xC000014C`, which is STATUS_REGISTRY_CORRUPT. That last UTF-16 string spells out the answer: **registry corruption was detected while loading SECURITY**. I looked up what `P1 = 0x2` means at first, but the explanations I found contradicted each other, so just looking at P4 and the string was enough. No guessing needed.

Side note: the doubled `om` in `HiveLoadFromomFile` isn't a typo on my part. That's just how the kernel's log string concatenation looks.

The agent extracted all the load failure entries from `DISMRepairLogFile.txt`:

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

Twelve SECURITY failures, all `0xd000014c`, spanning nearly 22 hours. That last SYSTEM `0xd0000043` is the only exception. `0xd0000043` is STATUS_SHARING_VIOLATION, meaning the hive file is being held open by another handle. The most common cause is a previous `reg load` that was never followed by `reg unload`. It appeared only this once, and SYSTEM loaded fine in all twelve preceding attempts. This entry was a trace of my own operation, not the fault itself.

The raw text looks like this:

```cmd
Failed to load offline \\?\C:\Windows\System32\config\SECURITY hive from '\\?\C:\Windows\System32\config\SECURITY' into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SECURITY'
Failed to load offline registry: {bf1a281b-...}C:/Windows/System32/config/SECURITY [HRESULT = 0xd000014c - NTSTATUS Error]
Failed to load offline SECURITY hive. [HRESULT = 0xd000014c - NTSTATUS Error]
Failed to load offline store from boot directory: '\\?\C:\' and windows directory: '\\?\C:\Windows\' [HRESULT = 0xd000014c]
```

CBS loads serially: SOFTWARE, then SYSTEM, then SECURITY. The first two succeeded, it got stuck on the third, and then the entire store initialization failed, causing all subsequent commands to fail too. That's why `Get-Packages`, `RevertPendingActions`, `sfc`, and `bootrec` all reported the same error. They all need to build this store first.

### Why Dropping In My Own SECURITY Hive Still Failed to Boot

DISM working means the file structure is valid. The kernel failing to boot means the file has other problems. These two things aren't contradictory, because **structurally valid** and **belonging to this machine** are completely different things.

The agent read out the SECURITY hive that had been swapped in:

```cmd
Computer name  HXCN-WIN
Machine SID    S-1-5-21-1262172508-...
```

The local SAM says:

```cmd
Computer name  LAPTOP-VQSR6OMV
Machine SID    S-1-5-21-4291209427-303460211-4247354471
```

`PolAcDmS` doesn't match SAM's domain SID, and `PolAcDmN` doesn't match SYSTEM's `ComputerName`. Even more critically, `Policy\Secrets` contains `NL$KM`, `M$_MSV1_0_TBAL_PRIMARY_{22BE8E5B-...}`, `DefaultPassword`, and `MouseWithoutBorders`, but **no `DPAPI_SYSTEM`**. This machine's DPAPI master key isn't in there.

What happens if you boot like this: LSA initialization detects that SECURITY and SAM have mismatched domain SIDs and most likely refuses to proceed. Even if it somehow got through, all of this machine's DPAPI data, saved browser passwords, EFS certificates, Credential Manager entries, would be undecryptable, because that ciphertext was encrypted with this machine's `DPAPI_SYSTEM`, and that master key only exists in the original SECURITY hive.

So this "fix" was a pure illusion: it only resolved DISM's error, turning the problem from "file can't load" into "file doesn't belong to this machine." The latter is harder to spot because every tool will tell you everything is fine.

The real local SECURITY had been sitting in `CorruptBak\SECURITY` the whole time, 65,536 bytes, a copy from 21:18 on October 31. Back to it, and start over.

### Sequence Numbers 17965 and 17964: The Two-Byte Dirty Flag

A registry hive header has a fixed structure. The first 4 KB is the header, followed by hbin blocks:

```cmd
Offset 0x000   "regf"                Signature
Offset 0x004   seq1                  Primary sequence number
Offset 0x008   seq2                  Secondary sequence number
Offset 0x01C   type                  Hive type
Offset 0x024   root                  Root key nk cell offset
Offset 0x028   hbins                 Total bytes in bins area
Offset 0x1FC   checksum              Header checksum
```

The checksum algorithm is straightforward: XOR every 4 bytes of `dword[0x000..0x1F8]` together. There's a boundary convention: if the XOR result is `0xFFFFFFFF`, write `0xFFFFFFFE`; if it's `0`, write `1`.

Reading it out:

```cmd
CorruptBak\SECURITY   65,536 B   seq 17965 / 17964   checksum 0xb3d51b08 (self-consistent)
```

`seq1 != seq2`, and that's the "dirty flag." What it means: the last transaction didn't finish committing, this hive is in an intermediate state, and the kernel can't use it directly.

Normally you'd rely on log replay to catch up. Let's look at the logs:

```cmd
SECURITY.LOG1   49,152 B   seq 208   (stale log from 2022)
SECURITY.LOG2    8,192 B   seq 17963 (2 transactions behind the hive)
```

The hive is at 17965/17964, so a replayable log sequence must be 17965 or 17965-1=17964. LOG1 is stuck at 208, LOG2 is stuck at 17963, **neither matches**. The log chain is broken, and replay is impossible.

The October 23 "0G free disk space" event is the most reasonable explanation: the disk was full during a write transaction, data hit the platter, but the sequence number never committed, and the logs didn't keep up. This is an inference, not direct evidence. Those three CBS lines only prove the disk was full at some point; they don't say which hive was being written.

So the question became: can I just clear the dirty flag without replaying the logs?

The agent ran every combination on `D:`. All using copies, without touching a single byte on C:.

| Case | Hive state | Accompanying logs | `reg load` |
|---|---|---|---|
| s1 | Dirty 17965/17964 | None | **Failed** |
| s2 | Dirty 17965/17964 | 0-byte LOG1/LOG2 | **Failed** |
| s3 | Dirty 17965/17964 | Stale LOG1(208)+LOG2(17963) | **Failed** |
| t1 | Dirty, seq2 reduced by 2 more (17965/17963) | None | **Failed** |
| t2 | seq2 := seq1 (17964/17964) | None | Success |
| i | Patched 17965/17965, no logs | None | Success |
| j | Patched 17965/17965 | Stale LOG1+LOG2 kept as-is | Success |
| s4 | seq equal but checksum not recalculated | None | **Failed** |

The conclusions were cleaner than expected:

- **As long as `seq1 != seq2`, loading is refused**, regardless of whether logs exist, are 0 bytes, or can be replayed. The dirty flag itself is fatal.
- As long as `seq1 == seq2` and the checksum is correct, stale logs left in place don't matter.
- The checksum must be recalculated. Changing only the sequence number without fixing the checksum still fails.

So the fix touches only two fields:

```cmd
Source  C:\Windows\System32\config\CorruptBak\SECURITY    65,536 B   17965 / 17964
Edit    Write 17965 at 0x008                                      (clear dirty flag)
Edit    Recalculate checksum at 0x1FC   0xb3d51b08 -> 0xb3d51b09
```

Only 2 bytes changed.

To confirm nothing was broken, the agent did a full semantic comparison between the patched file and the original: both sides have 166 keys and 164 values, with key names, value names, value types, and value data matching item by item, 0 differences. The structural walkthrough was also clean: all 166 nk cells had correct parent pointers (165 non-root keys, zero mismatches), all 33 subkey index cells were valid `lh`, both security descriptor cells were intact, and no reachable cells went out of bounds.

I also verified that this hive genuinely belongs to this machine:

```cmd
PolAcDmN   LAPTOP-VQSR6OMV                        <- matches SYSTEM\ComputerName
PolAcDmS   S-1-5-21-4291209427-303460211-4247354471  <- matches SAM domain SID
Policy\Secrets   8 entries, including DPAPI_SYSTEM, RasDialParams!...-1001#0, 6 MSSQL/SQL service accounts
Root key LastWriteTime   2026-11-01 09:32:10 UTC       <- exactly matches "last successful boot 11/1 17:32 local"
```

`Policy\Accounts` has `-501/-1002/-1003` but no `-1001`, while SAM has an account with RID 1001. Don't worry about this. LSA creates account entries on demand, writing them in the first time that SID is used.

### Uncovering the Dirty BBI Hive and the Orphaned Driver

Of the nine hives, one more couldn't load: `BBI`, 1,310,720 bytes, `53232/53231`, also dirty, also with 0-byte LOG1/LOG2. Same two-field fix handles it.

BBI isn't boot configuration. It contains `WorkItems` (81 entries), `PackageImportance` (1431 entries), and `Events` (136 entries), and belongs to Boot Environment Infrastructure's job queue. A dirty BBI won't cause a blue screen. It was already dirty on October 31, and the machine still booted on November 1. But since it's the only other "structurally unloadable" hive, might as well clean it up.

While checking boot drivers, I also found a real defect:

```cmd
HKLM\SYSTEM\ControlSet001\Services\softaal
  ImagePath    = \??\C:\Program Files (x86)\Tencent\QQPCMgr\15.1.22354.301\softaal64_ev.sys
  Start        = 1  (SERVICE_SYSTEM_START)
  ErrorControl = 0
```

After QQPCMgr upgraded to 15.6, the old directory was gone, but `softaal` still pointed to the 15.1 path. `ErrorControl=0` means load failures get ignored, so it won't cause a blue screen, but every boot wastes a try on it. Changed to `Start=4` to disable it.

## The Fix

### Why the ISO's 9 MB SYSTEM Hive Can't Overwrite Yours—and Why You Still Need the ISO

I had `Win11_23H2_Chinese_Simplified_x64v2.iso` on hand, version 22631.2861. My original plan was to pull a clean hive from it and overwrite. After trying, I confirmed that path doesn't work.

The `Windows\System32\config\` inside the ISO is **generic installation state**, unrelated to any specific machine:

| Hive | In ISO | This machine | Consequence of overwriting |
|---|---|---|---|
| SYSTEM | 9175040 B / 661 services / `MINWINPC` | 32243712 B / 846 services / `LAPTOP-VQSR6OMV` | All driver services and Enum device tree lost, guaranteed INACCESSIBLE_BOOT_DEVICE |
| SAM | 8192 B (empty database) | 131072 B / 5 accounts | All accounts lost |
| SECURITY | 8192 B (empty) | 65536 B | All LSA secrets lost, DPAPI data permanently undecryptable |
| SOFTWARE | 66584576 B | 117440512 B | All installed software registration info lost |
| BBI | 8192 B (empty queue) | 1310720 B | This one is usable |

In-place upgrade repair won't work either. ISO 22631.2861 is **lower than** the installed 22631.5768, and setup will refuse outright with "lower version."

So the ISO's proper role on this machine is as a **comparison baseline**: service counts, driver lists, SYSTEM key entries, BBI structure, all compared against the ISO's values to confirm which differences are normal and which are defects. It can't serve as a parts bin.

### Full Backup, Two-Byte Patch, and Stale Log Quarantine

First, back up the entire `config` directory to D:, 43 files totaling 238.1 MB, including all 9 hives plus every `.LOG1/.LOG2/.TM.blf/.regtrans-ms`, with per-file SHA-256 comparison to confirm byte-for-byte consistency.

Then:

```cmd
1) SECURITY   CorruptBak\SECURITY -> patch 0x008 / 0x1FC -> reg load self-test -> write back to C:
2) SECURITY.LOG1 / LOG2 -> D:\_fix\quarantine\   (quarantine to eliminate ambiguity)
3) BBI        Same treatment as SECURITY, 53232/53231 -> 53232/53232
4) SYSTEM     Mount, change softaal's Start to 4
5) Delete C:\hiberfil.sys
6) Clean up $WinREAgent / $Windows.~BT / $SysReset / SoftwareDistribution\Download
```

`hiberfil.sys` was 6,715,396,096 bytes (6.25 GiB), with the first 4 KB all zeros. The header was already dead, and `winresume` couldn't possibly recover anything from it. The four `resumeobject` entries in BCD pointing to it would just make the bootloader waste a try.

This file was pure wasted space. After deleting it, C: free space went from 8.9 GB to 16.5 GB.

If it had been cleaned out from the start, none of this might have happened.

After this step, `DISM /Get-Packages` output:

```cmd
Deployment Image Servicing and Management tool
Version: 10.0.22621.1

Image Version: 10.0.22631.5768

...
The operation completed successfully.
```

83 packages, all "Installed," no Pending. The same command that failed outright with `0xd000014c` before the fix. This is the hardest evidence that "SECURITY is fixed," more convincing than any `reg load` self-test, because it went through the complete CBS store initialization.

### Post-Repair Verification

After the fix, I ran four layers of checks on each of the nine hives: header signature, sequence numbers, checksum, hbin chain integrity, then a layer-by-layer traversal from the root key (parent pointers, `li`/`lf`/`lh`/`ri` subkey tables, value tables), and finally a count of allocated-but-unreachable orphan keys.

```cmd
hive         bytes        sequence          dirty  checksum  keys     values
SYSTEM       32243712     395834/395834     no     OK        91,391   194,730
SOFTWARE     117440512    937587/937587     no     OK        372,888  640,232
SAM          131072       3911/3911         no     OK        80       100
SECURITY     65536        17970/17970       no     OK        166      164
DEFAULT      6029312      238433/238433     no     OK        8,201    10,937
DRIVERS      8777728      4850/4850         no     OK        36,424   52,954
COMPONENTS   32768000     9216/9216         no     OK        61,793   197,776
ELAM         32768        13/13             no     OK        1        0
BBI          1310720      53233/53233       no     OK        1,652    10,129
```

Parent pointer errors: 0. Subkey table errors: 0. Value table errors: 0. Hbin chain breaks: 0. Orphan keys: 0. All nine hives passed `reg load`.

Only after this full pass did I dare confirm: I fixed the dirty flag without touching any data.

One cell was almost misidentified as an orphan key: at `0xd1a718` in SYSTEM, 72 bytes long, starting with `6e 6b` (`nk`). But the minimum size of an nk cell is `0x4C` = 76 bytes, and this one fell short. It was a piece of data that happened to start with `nk`. Almost acted on a problem that didn't exist.

Identity consistency was also checked item by item:

```cmd
PolAcDmN   LAPTOP-VQSR6OMV
PolAcDmS   S-1-5-21-4291209427-303460211-4247354471
ProfileList  S-1-5-21-...-1001  ->  C:\Users\admin
SAM accounts   admin / Administrator / DefaultAccount / Guest / WDAGUtilityAccount
Lsa boot key   TC463EF4966D8796     (assembled from the four class names JD+Skew1+GBG+Data)
```

Under `ControlSet001\Control\Lsa`, the values of `JD`/`Skew1`/`GBG`/`Data` are all empty. The real SYSKEY is stored in the **class names**, which is why many tools can't read it.

The rest:

```cmd
DISM /Cleanup-Image /ScanHealth   No component store corruption detected
DISM /Get-MountedImageInfo        No mount leftovers
WinSxS\pending.xml                Does not exist
COMPONENTS\...\PackagesPending    Empty
Session Manager\BootExecute       autocheck autochk *
bcdedit {default}                 partition=C:  \Windows\system32\winload.efi
L:\Recovery\WindowsRE\Winre.wim   Exists, BCD recoverysequence points to it
Boot drivers (Start 0/1, Type 1/2)   131 total, 0 missing image files
Storage class filters             partmgr / volsnap / fvevol+iorate+rdyboost, all system defaults
fsutil dirty query C:             Not dirty
```

## Epilogue

**`WinSxS\Temp\InFlight` had accumulated 5336 directories totaling 1498.9 MB**, with timestamps from 2023-10-11 all the way to 2026-11-02. These are staging copies that DISM and update components never cleaned up. Not on any critical path, but eating 1.5 GB of space for nothing.

One small side note: during troubleshooting, I ran `DISM /ScanHealth` and `/Get-Packages` several times myself, and they left 7335 directories totaling 1393 MB of temp files under `InFlight`. After cleaning those up, C: free space went from 16.0 GB back to 16.5 GB. Leaving some headroom for next time, since this whole incident started with C: filling up.

All nine hives are now clean and loadable, the component store has no corruption, the boot chain is intact, and there are no pending operations. Whether the machine boots after a restart comes down to whether LSA accepts this SECURITY hive.

It booted successfully.

One more thing: recent Windows updates have fixed plenty of major issues, but each fix tends to introduce new problems for users. Microsoft's engineering quality has visibly declined over the years, and it's hard to count on them to deliver a system of consistent quality. In my roommate's case, the direct trigger was C: filling up, but Windows Update repeatedly trying to write and maintain things in the background was also a major factor pushing the system toward collapse.

So I recommend disabling Windows Update via the registry. Create a `.txt` file, rename it to `.reg`, and put this in it:

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

Double-click to import, and Windows Update gets paused for 1000 weeks. If you want to re-enable updates, import this one:

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

After this, the system won't get repeatedly messed with by background updates, and C: will save a good chunk of space too.