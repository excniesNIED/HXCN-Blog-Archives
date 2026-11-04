---
title: A Full C: Drive and a 0x74 BAD_SYSTEM_CONFIG_INFO Recovery Story
pubDatetime: 2026-11-02T00:00:00.000+08:00
slug: win11-bad-system-config-info-en
tags:
  - Windows 11
  - Registry
  - Blue Screen
  - WinPE
  - Data Recovery
category: 踩坑日志
description: A Windows 11 23H2 recovery log for a 0x74 BAD_SYSTEM_CONFIG_INFO crash caused by a full C: drive. Covers BitLocker state, failed bcdboot/bootrec and DISM 0xd000014c errors, tracing the dirty flag in the SECURITY hive, byte-level comparison, and a controlled load experiment, ending with a two-field fix that brings the hive back.
---

## Preface

I have long believed that for most people, one partition per disk is enough. One disk, one partition. If you only have a single drive, split off a D: drive at most. As for the C: drive, if you actually use your machine, it should start at 200 GB, and 300 GB or even 512 GB is not overkill.

People ask whether they can install software on a different partition. Sure, and I encourage putting games and big applications on D:. The problem is that plenty of things don't ask where to go. Caches, temp files, downloaded update packages all default to C:. Leave C: too small and the remaining space gets tight, at which point apps start throwing errors, and in the worst case the machine won't even boot.

Splitting a disk into too many small partitions has another downside. Say you download a 60 GB game. The drive as a whole has enough free space, but each individual partition only has thirty or forty gigs left, so the game won't fit anywhere. You end up shuffling files around just to make room.

I also want to bury the old claim that installing software on D: protects it from a reinstall. After a reinstall, the programs on D: still won't run in nine cases out of ten, because their registry entries, user profiles, and runtime libraries all lived on C: and got wiped with it. So the real job is not moving software to D:, it's backing up the right things: your QQ and WeChat chat history (usually under `C:\Users\<username>\Documents`), your Downloads folder, photos and videos, the desktop, the Start menu, and a copy of `C:\Users\<username>\NTUSER.DAT` so you can reconstruct which apps you had installed. Keep passwords and keys separately. If BitLocker is on, unlock the drive or export the recovery key before you reinstall. Reinstall the software, copy those files back, and you're mostly restored.

Ten years ago, when I first started tinkering with computers, the generation above me liked to carve hard drives into four partitions. That habit traces back to an era when cloning tools and one-click installers defaulted to four-partition layouts, and it has stubbornly survived. Plenty of my peers bought machines on an older relative's advice and ended up with the same handful of tiny partitions. I routinely hear from classmates whose C: drive is full, and every time it's the same dance of moving files around other drives to scrape together space for C:.

If you think I'm being dramatic, the story of my roommate's mysteriously blue-screening laptop is a ready-made rebuttal.

## Initial Guesses and Troubleshooting

### The Situation

The machine in question is an ASUS laptop, factory-shipped with Windows 11 Home, updated automatically to 23H2 build `22631.5768`. It has a 1 TB SSD split into C:, D:, and E:. C: is only 150 GB, and it's packed with MATLAB, SQL Server 2022, Office 2014, and a Steam library.

One day it blue-screened out of nowhere with the stop code `BAD_SYSTEM_CONFIG_INFO`.

![Blue screen crash](bsod-bad-system-config-info-en.svg)

That code registered in my head immediately: it's strongly tied to a failure loading a registry hive. The machine rebooted, blue-screened again, rebooted again, and after a few cycles it stopped even showing the blue screen and dropped into Windows automatic repair. Unsurprisingly, Startup Repair failed.

![Startup repair failed](startup-repair-failed-en.svg)

The usual next step after a failed repair is to roll back to a restore point. This machine never had System Protection enabled, and with C: this tight there were no restore points to fall back on. My roommate fed the problem to an AI assistant and ran through a bunch of checks and fixes with no luck.

Since `chkdsk` and `sfc` both came back clean, I ruled out hardware first: the SSD was probably fine, and the core system files were probably fine. That left boot configuration as the prime suspect. I booted into a WinPE environment via Ventoy and tried DISM++, but it popped up "attempting to load an invalid format" the moment it opened. Forcing a boot repair and rebooting got me a `0xc0000001`.

![Recovery error 0xc0000001](recovery-error-0xc0000001-en.svg)

That DISM++ message actually mattered a lot, I just didn't piece it together at the time. It means DISM++ failed while mounting the offline system's registry. In other words, the problem wasn't the boot files, it was the registry itself.

### Turning Off BitLocker

The first thing I did in WinPE was check BitLocker. The reason is concrete: modern laptops ship with "Device Encryption" pre-provisioned, and the key is escrowed to a Microsoft account. If the drive was actually locked and I had no credentials, I couldn't even export a recovery key, every later step would be pointless, and a single reboot could seal the data forever.

First I checked the C: drive state:

```cmd
manage-bde -status C:
```

The output looked like this:

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

I stared at "No key protectors found" twice before I let myself relax. It means Device Encryption was never actually activated on this machine; no protector was ever generated. With no protector, there is no key to lose, and C: is plain NTFS that WinPE can read directly. My roommate used a local account and never signed in with a Microsoft account, so the pre-provisioned encryption stayed in its "not activated" state the whole time. In this particular case, that worked in our favor.

Then I mapped the disk layout to get my bearings:

```cmd
DISKPART> list vol

  Volume ###  Ltr  Label        Fs     Type        Size     Status     Info
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

The one I cared about was Volume 4: a 260 MB FAT32 partition labeled `SYSTEM`. That's the EFI System Partition (ESP), where the boot files live. Whether this machine could boot at all came down to it.

Even after confirming BitLocker wasn't locked, I ran the disable command on C:, D:, and E: anyway:

```cmd
manage-bde -off C:
manage-bde -off D:
manage-bde -off E:
```

This is insurance. Even though it showed "Protection Off," fiddling with the boot configuration and registry later could theoretically trip the TPM into re-locking the drive. Turning encryption off completely first means nothing can accidentally lock it later.

### Trying the Standard Playbook

With BitLocker out of the way, I walked the standard flow. First, rebuild the boot files. I assigned the ESP a drive letter with diskpart, then used `bcdboot` to copy the boot files over from `C:\Windows`:

```cmd
DISKPART> select volume 4
DISKPART> assign letter=S
DISKPART> exit

X:\Windows\System32>bcdboot C:\Windows /s S: /f UEFI /l zh-cn
Boot files successfully created.
```

What `bcdboot` does is copy the Windows boot manager (`bootmgfw.efi`) and its language resources from the system directory into the ESP, and generate the matching BCD boot configuration. "Boot files successfully created" meant the files themselves could be written. I double-checked:

```cmd
X:\Windows\System32>dir S:\EFI\Boot
 Volume in drive S is SYSTEM
 Volume Serial Number is 8CE7-BD30

 Directory of S:\EFI\Boot

2025/08/15  08:38         1,698,760  bootx64.efi
               1 File(s)      1,698,760 bytes
```

`bootx64.efi` is the bootloader the UEFI firmware looks for by default, and 1.6 MB is a normal size. For good measure I manually overwrote it with `bootmgfw.efi`. Both steps succeeded, but the problem didn't go away. Something stranger was still waiting.

Next came the `bootrec` family:

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

Two things worth explaining here. `scanos` reporting zero installations looks alarming, but `bootrec` decides "is there a Windows here" by reading the offline registry's volume mapping and controller configuration. If it can't read them, it reports nothing. And `fixboot` returning "Access is denied" is practically the norm on UEFI/GPT machines; that command targets legacy MBR boot and is irrelevant here. Neither error carried much signal, and I didn't want to draw conclusions from them.

On to the filesystem:

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

`chkdsk /f` came back green through all five stages with zero bad sectors. The filesystem was clean; that lead was a dead end.

Then the system file check:

```cmd
X:\Windows\System32>sfc /scannow /offbootdir=C:\ /offwindir=C:\Windows
Beginning system scan.
Windows Resource Protection could not perform the requested operation.
```

`sfc` didn't run either. Worth explaining: offline `sfc` depends on the component store (CBS), and CBS has to load the registry hives before it starts. It couldn't load them, so `sfc` reported "could not perform the requested operation." I didn't connect that dot at the time; it fell into place later.

There was also a small self-inflicted hiccup. I mistyped the DISM image path, and got:

```cmd
X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /RestoreHealth
Error: 87

The DISM image path option is not recognized.
```

Error 87 means "invalid parameter," and it was entirely my own typo, a missing or full-width colon in `/Image:C:\`. These little mistakes waste the most time, because the first instinct is to suspect DISM itself is broken, when really you just fat-fingered the command.

Automatic repair didn't offer a verdict either. Startup Repair ran three sessions, and `SrtTrail.txt` opened with:

```cmd
Last successful boot time: 2026/11/1 9:32:11 (GMT)
Number of repair attempts: 64
```

Each session runs a dozen or so checks, all of which came back `0x0`, and only the last one failed:

```cmd
Session 1   Name: Check for installed LCU    Result: Completed successfully. Error code = 0x43
Session 2   Root cause count = 1
            Root cause found:
            Startup Repair has tried several times but still cannot determine the cause of the problem.
Session 3   Name: Check for installed LCU    Result: Completed successfully. Error code = 0x14c
```

"Check for installed LCU" has to open the CBS component store, and that step failed, which told me the component store couldn't load. That `0x14c` in session 3 caught my eye and held it: it matched the DISM error exactly. Same root cause, surfacing through different tools.

At that point I ruled out the "boot is broken" hypothesis: the ESP was fine, the BCD was fine, `winload.efi` was present, and every one of Startup Repair's checks passed. The problem was further down.

So I started reading logs. Besides `SrtTrail.txt` there's `DISMRepairLogFile.txt`, which records every registry load from automatic repair and offline DISM. The crucial lines:

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

Twelve failed loads, all targeting `SECURITY`, all with `0xd000014c`, spanning from the afternoon of November 1 to the afternoon of November 2, nearly 22 hours. The lone `SYSTEM` entry with `0xd0000043` is the exception, and it's a sharing violation I'll explain as my own doing.

Combined with another startling discovery, that log gave me my first theory. The discovery: **C: had only a little over 100 MB of free space left.** After deleting some non-essential large files from the desktop, I got it back to about 8.9 GB.

Put "C: drive full" next to "SECURITY failed to load," and my first guess was: a background Windows update ran out of disk while writing SECURITY, the write got truncated, and the hive ended up corrupted. Following that logic, the most direct "no-reinstall" fix was to replace the broken SECURITY. I copied a structurally intact SECURITY from my own machine's `C:\Windows\System32\config\` and dropped it in.

That step turned out to be half right. The file did need fixing, but "swap in a different one" was exactly the wrong way to do it.

## Deep Dive with an AI Agent

After the swap, `RevertPendingActions` actually reported success, but the reboot still landed on `0xc0000001`. I realized this was deeper than I thought, so I set up a networked FirPE environment, installed an AI coding assistant, and had it do a thorough audit. The conclusions below are what we pinned down together, line by line.

### Pinpointing the Culprit from Logs and Crash Dumps

Start with the timeline. On October 23, the CBS log wrote three lines in a row:

```cmd
2026-10-23 18:36:21, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:23, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:25, Info  CBS  System volume has 0G free disk space
```

Followed by `Maint: incomplete, interruptions: 1`. That's hard evidence: during that maintenance run on October 23, C: was written down to zero bytes free, and the transaction was interrupted mid-flight. My roommate shrugged it off, cleared a few gigs, and kept going. Everything looked normal for the next eight or nine days, until November 1.

The answer was almost written out in the crash dump. The header of `C:\Windows\Minidump\110226-9312-01.dmp` reads:

```cmd
signature   = PAGE / DU64
major/minor = 15.22621
bugcheck    = 0x74  (BAD_SYSTEM_CONFIG_INFO)
P1 = 0x2
P2 = 0xffff94869fbd2940
P3 = 0x1
P4 = 0xffffffffc000014c
Crash time  = 2026-11-02 07:36:19 UTC (= 15:36 local)
ASCII in dump = "HiveLoadFromomFile" + "status"
UTF-16 in dump = "<SECURITY"
```

`P4 = 0xC000014C` is `STATUS_REGISTRY_CORRUPT`, registry corruption. That trailing UTF-16 string `<SECURITY` points straight at the target: the kernel tried to load the SECURITY hive during boot, decided it was corrupt, and threw `0x74`.

One aside: that duplicated `om` in `HiveLoadFromomFile` is not a typo on my part. It's what the kernel's log-string concatenation actually looks like.

Now the twelve `0xd000014c` failures in the DISM log line up too. `0xd000014c` is `0xC000014C` with the client bit set, the same error as P4 in the dump. Automatic repair, DISM, and the kernel all died on the same thing: loading SECURITY.

### Why Dropping In My Own SECURITY Hive Still Failed to Boot

I have to own a mistake here. When I copied my own SECURITY over earlier, `RevertPendingActions` reported success and I briefly thought I'd fixed it. The reboot still hit `0xc0000001`.

Why would DISM pass but the kernel fail? Because DISM only checks whether the file structure is valid. It does not check whether the file belongs to this machine. The kernel's boot-time checks are far stricter.

Read the SECURITY I dropped in:

```cmd
Computer name   HXCN-WIN
Machine SID     S-1-5-21-1262172508-...
```

`HXCN-WIN` is my own computer's name. But the roommate's SAM hive says:

```cmd
Computer name   LAPTOP-VQSR6OMV
Machine SID     S-1-5-21-4291209427-303460211-4247354471
```

The two don't match. During boot, the Local Security Authority (LSA) compares the machine SID in SECURITY against the one in SAM and requires them to be identical. A mismatch is an instant refusal. Worse, my SECURITY's `Policy\Secrets` contains `NL$KM`, `MouseWithoutBorders`, and the like, my own stuff, and crucially it does not contain the roommate's `DPAPI_SYSTEM`.

`DPAPI_SYSTEM` is the machine's master encryption key. Saved browser passwords, EFS certificates, everything in Credential Manager is encrypted with it. Swap in a SECURITY hive that lacks it, and even if you somehow slipped past the SID check, all that data is permanently unrecoverable.

So that "fix" was a pure illusion. It turned "the file can't load" into "the file isn't this machine's," and the latter is harder to spot because every tool tells you everything is fine. The right move was to repair the roommate's own SECURITY, not paper over it with someone else's.

The good news: the real SECURITY had been sitting in `C:\Windows\System32\config\CorruptBak\` the whole time, 65,536 bytes, a copy from October 31. After all that circling, we had to come back to it.

### Sequence Numbers 17965 and 17964: The Two-Byte Dirty Flag

The registry is not a single file. It's split into several "hives" stored under `C:\Windows\System32\config\`: `SYSTEM` (boot config, drivers, services), `SOFTWARE` (installed apps), `SECURITY` (LSA secrets and SIDs), `SAM` (local accounts), `DEFAULT`, `DRIVERS`, `COMPONENTS` (the component store), `ELAM`, and `BBI`. Each hive starts with a fixed header:

```cmd
Offset 0x000   "regf"                signature
Offset 0x004   seq1                  primary sequence number
Offset 0x008   seq2                  secondary sequence number
Offset 0x01C   type                  hive type
Offset 0x024   root                  offset of the root key's nk cell
Offset 0x028   hbins                 total size of the bins area
Offset 0x1FC   checksum              header checksum
```

`seq1` and `seq2` are a pair of sequence numbers that guard write consistency. On a clean shutdown the two writes stay in sync, so `seq1 == seq2`. If a write transaction is interrupted by a power loss or a full disk, you're left with `seq1 != seq2`. That state is the "dirty flag," and it tells the kernel "this hive didn't finish its last write."

Read the roommate's original SECURITY:

```cmd
CorruptBak\SECURITY   65,536 B   seq 17965 / 17964   checksum 0xb3d51b08 (self-consistent)
```

`17965 / 17964`, dirty. Normally, when the kernel sees a dirty hive it replays the transaction logs to reconcile the sequence numbers. Look at the logs:

```cmd
SECURITY.LOG1   49,152 B   seq 208   (stale log from 2022)
SECURITY.LOG2    8,192 B   seq 17963 (two transactions behind the hive)
```

The hive is 17965/17964, so a replayable log would have to be 17965 or 17964. But `LOG1` sits at 208 and `LOG2` at 17963, neither one a match. The log chain is broken and replay is impossible, so the kernel reports `STATUS_REGISTRY_CORRUPT` and blue-screens.

One thing had to be settled: is it the dirty flag itself that's fatal, or the inability to replay logs? To find out, I ran every combination on copies in the D: drive, without touching a single byte on C::

| Case | hive state | attached logs | `reg load` |
|---|---|---|---|
| s1 | dirty 17965/17964 | none | **failed** |
| s2 | dirty 17965/17964 | zero-byte LOG1/LOG2 | **failed** |
| s3 | dirty 17965/17964 | stale LOG1(208)+LOG2(17963) | **failed** |
| t1 | dirty, seq2 lowered by 2 (17965/17963) | none | **failed** |
| t2 | seq2 := seq1 (17964/17964) | none | success |
| i | patched 17965/17965 | none | success |
| j | patched 17965/17965 | stale LOG1+LOG2 left in place | success |
| s4 | equal seq but checksum not recomputed | none | **failed** |

The conclusion was almost too clean:

- Whenever `seq1 != seq2`, loading fails, regardless of whether logs exist, whether they're zero bytes, or whether they could replay. The dirty flag alone is fatal.
- Whenever `seq1 == seq2` and the header checksum is correct, stale logs sitting next to the hive make no difference.
- The checksum must be recomputed; changing the sequence numbers without fixing it still fails.

So the entire repair surface is two fields:

```cmd
Source C:\Windows\System32\config\CorruptBak\SECURITY    65,536 B   17965 / 17964
Edit   0x008 write back 17965                                        (clear the dirty flag)
Edit   0x1FC recompute checksum   0xb3d51b08  ->  0xb3d51b09
```

To make sure I hadn't broken anything, I compared the patched file against the original item by item: both have 166 keys and 164 values, with key names, value names, value types, and value data all identical, zero differences. The structural walk was clean too: all 166 nk cells have correct parent pointers, all 33 child-key indexes are valid `lh` cells, the 2 security descriptors are intact, and nothing runs past its bounds.

And this hive really is the roommate's machine:

```cmd
PolAcDmN   LAPTOP-VQSR6OMV                        <- matches SYSTEM\ComputerName
PolAcDmS   S-1-5-21-4291209427-303460211-4247354471  <- matches the SAM domain SID
Policy\Secrets   8 entries, including DPAPI_SYSTEM, RasDialParams!...-1001#0, and 6 MSSQL/SQL service accounts
Root key LastWriteTime   2026-11-01 09:32:10 UTC       <- matches "last successful boot 11/1 17:32 local" exactly
```

The root key's LastWriteTime matches the last successful boot recorded in `SrtTrail.txt` to the second. That's further confirmation that the SECURITY data area was never damaged, only those two header bytes.

### Uncovering the Dirty BBI Hive and the Orphaned Driver

With SECURITY explained, one more hive was still "structurally unloadable": `BBI`, 1,310,720 bytes, with sequence numbers `53232/53231`, also dirty, also with zero-byte `LOG1/LOG2`.

`BBI` is the Boot Environment Infrastructure's job queue, holding `WorkItems` (81 entries), `PackageImportance` (1431 entries), and `Events` (136 entries). It doesn't take part in kernel boot, which is why it was already dirty on October 31 yet the machine still booted on November 1. But since it carried the same dirty flag as SECURITY, I cleaned it up the same way.

While auditing boot drivers, I also turned up a genuine defect:

```cmd
HKLM\SYSTEM\ControlSet001\Services\softaal
  ImagePath    = \??\C:\Program Files (x86)\Tencent\QQPCMgr\15.1.22354.301\softaal64_ev.sys
  Start        = 1  (SERVICE_SYSTEM_START)
  ErrorControl = 0
```

`softaal` is a Tencent PC Manager driver. After PC Manager upgraded to 15.6, the old 15.1 directory was gone, but this service still pointed at the old path. `Start=1` means it tries to load on every boot, while `ErrorControl=0` means a load failure is silently ignored. So it can't cause a blue screen, it just wastes a load attempt each boot. I set it to `Start=4` (disabled).

I also noticed a few orphaned drivers with `Start >= 2`: `ksapi64`, `ROGKB`, `ROGMS`, and `TSSKX64`. These only load after the user session starts, so they don't affect this boot. `TSSKX64` is a classic example: the registry lists `tsskx64_EV.sys`, but the disk only has `TSSKX64.sys`, with the case and the `_EV` suffix both wrong. Tencent's installer left a half-finished entry. I noted these but didn't touch them.

## The Fix

### Why the ISO's 9 MB SYSTEM Hive Can't Overwrite Yours, and Why You Still Need the ISO

I had a `Win11_23H2_Chinese_Simplified_x64v2.iso`, build 22631.2861. My first instinct was that I could just grab a clean hive from the image and overwrite the broken one. Testing showed that route doesn't work, and forcing it would have made things worse.

The `Windows\System32\config\` inside the image is a generic install state, tied to no specific machine:

| hive | in the ISO | on this machine | result of overwriting |
|---|---|---|---|
| SYSTEM | 9,175,040 B / 661 services / `MINWINPC` | 32,243,712 B / 846 services / `LAPTOP-VQSR6OMV` | all driver services and the Enum device tree gone, guaranteed INACCESSIBLE_BOOT_DEVICE |
| SAM | 8,192 B (empty) | 131,072 B / 5 accounts | all accounts gone |
| SECURITY | 8,192 B (empty) | 65,536 B | all LSA secrets gone, DPAPI data permanently unreadable |
| SOFTWARE | 66,584,576 B | 117,440,512 B | all installed-software registry entries gone |
| BBI | 8,192 B (empty queue) | 1,310,720 B | this one is usable |

The SYSTEM hive in the image is only 9 MB with 661 services and a computer name of `MINWINPC`. It's the empty shell meant for a fresh install, and it contains none of this machine's hardware drivers or device tree. Overwrite it and you boot straight into `INACCESSIBLE_BOOT_DEVICE`, because the storage controller driver is gone. SAM and SECURITY are 8 KB empty databases; overwriting them means losing every account and permanently breaking DPAPI.

An in-place upgrade repair doesn't work either. The image is 22631.2861, which is lower than the installed 22631.5768, so setup refuses it outright as "a lower version."

So is the image useless? No, it just needs a different role. Its real value is as a comparison baseline: use the generic configuration inside to check which differences are normal and which are defects. For example, some kernel drivers (like `wof` and `null`) have no `ImagePath` in the image, and the machine's copy matches, which means that's normal rather than corruption. With that baseline, you don't mistake a normal difference for damage while troubleshooting.

### Full Backup, Two-Byte Patch, and Stale Log Quarantine

Before touching anything, I backed up the entire `config` directory to D:: 43 files, 238.1 MB, containing all 9 hives plus every `.LOG1/.LOG2/.TM.blf/.regtrans-ms`, with a per-file SHA-256 comparison confirming byte-identical copies. If anything went wrong, I could roll back exactly.

Then I executed in order:

```cmd
1) SECURITY   CorruptBak\SECURITY -> patch 0x008 / 0x1FC -> reg load self-check -> write back to C:
2) SECURITY.LOG1 / LOG2 -> D:\_fix\quarantine\   (quarantine, remove ambiguity)
3) BBI        same treatment as SECURITY, 53232/53231 -> 53232/53232
4) SYSTEM     mount, change softaal's Start to 4
```

Was step 2, quarantining the logs, actually necessary? Strictly speaking, no. Experiment case `j` already proved the kernel ignores stale logs when the hive is clean. But moving `SECURITY.LOG1` (seq 208) and `SECURITY.LOG2` (seq 17963) out of the way removes one ambiguity: any tool reading those logs later might draw the wrong conclusion. Once moved, the kernel rebuilds a clean pair of logs the next time it mounts the hive. So this step is about keeping things tidy, not about being able to boot.

### Clearing the Hibernation File and Update Leftovers

A few more things were just taking up space.

`C:\hiberfil.sys` was 6,715,396,096 bytes (6.25 GiB), and its first 4 KB were all zeros. That means the header was already dead; `winresume` could never restore any hibernation state from it, and the four `resumeobject` entries in the BCD pointing at it only made the bootloader waste a try. Deleting it costs nothing:

```cmd
del C:\hiberfil.sys
```

Then I removed the leftover update and reset directories: `$WinREAgent` (about 1,771 MB), `$Windows.~BT` (56.7 MB), `$SysReset` (0.3 MB), and `SoftwareDistribution\Download` (65.5 MB). Before deleting, I confirmed there was no pending install transaction (`SetupType=0`, `WinSxS\pending.xml` absent), so removing these wouldn't affect boot.

At this point C: went from 8.9 GB free back up to about 16.5 GB. If it had been cleaned out in the first place, none of this mess would have happened.

### Post-Repair Verification

After the fix I wasn't about to declare victory on gut feeling, so I ran four layers of verification.

Layer one: a structural walk of all nine hives. Header signature, sequence numbers, checksum, hbin chain integrity, a full depth-first traversal from the root (parent pointers, `li`/`lf`/`lh`/`ri` child-key tables, value tables), and a count of allocated-but-unreachable orphan keys:

```cmd
hive         bytes        sequence          dirty  checksum  keys      values
SYSTEM       32243712     395834/395834     no     OK        91,391    194,730
SOFTWARE     117440512    937587/937587     no     OK        372,888   640,232
SAM          131072       3911/3911         no     OK        80        100
SECURITY     65536        17970/17970       no     OK        166       164
DEFAULT      6029312      238433/238433     no     OK        8,201     10,937
DRIVERS      8777728      4850/4850         no     OK        36,424    52,954
COMPONENTS   32768000     9216/9216         no     OK        61,793    197,776
ELAM         32768        13/13            no     OK        1         0
BBI          1310720      53233/53233       no     OK        1,652     10,129
```

Zero parent-pointer errors, zero child-table errors, zero value-table errors, zero broken hbin chains, zero orphan keys, and all nine hives load cleanly. Only after seeing that table did I trust that I'd fixed the dirty flag and touched no data.

One note: during this recheck, SECURITY showed `17970/17970`, a few ticks higher than the `17965/17965` right after the patch. That's expected. Even a `reg load` / `reg unload` self-check makes the kernel bump the sequence number and set mount flags on each `nk` cell. I did a byte-level comparison, and apart from those mount flags and sequence numbers, not a single key name, value name, or value datum changed.

Layer two: identity consistency. Confirm this SECURITY belongs to the machine:

```cmd
PolAcDmN   LAPTOP-VQSR6OMV
PolAcDmS   S-1-5-21-4291209427-303460211-4247354471
ProfileList  S-1-5-21-...-1001  ->  C:\Users\admin
SAM accounts admin / Administrator / DefaultAccount / Guest / WDAGUtilityAccount
Lsa boot key  TC463EF4966D8796     (assembled from the JD+Skew1+GBG+Data class names)
```

There's a nice detail here: under `ControlSet001\Control\Lsa`, the four values `JD`/`Skew1`/`GBG`/`Data` are all empty, and the real system key (SYSKEY) lives in their class names. That's why a lot of third-party tools can't read this boot key.

Layer three: the hardest piece of evidence. Before the fix, `dism /Image:C:\ /Get-Packages` failed immediately with `0xd000014c` because it couldn't load SECURITY. After the fix:

```cmd
Deployment Image Servicing and Management tool
Version: 10.0.22621.1
Image Version: 10.0.22631.5768
...
The operation completed successfully.
```

83 packages, all "Installed," none pending. The same command went from "fails immediately" to "runs to completion," because it fully walked the CBS component-store initialization, and that initialization loads SOFTWARE, SYSTEM, and SECURITY in order. Getting through it is more convincing than any `reg load` self-check. `dism /Cleanup-Image /ScanHealth` also came back "No component store corruption detected."

Layer four: the boot chain and runtime environment:

```cmd
DISM /Get-MountedImageInfo        no leftover mounts
WinSxS\pending.xml                does not exist
COMPONENTS\...\PackagesPending    empty
Session Manager\BootExecute       autocheck autochk *
bcdedit {default}                 partition=C:  \Windows\system32\winload.efi
L:\Recovery\WindowsRE\Winre.wim   present, BCD recoverysequence points to it
Boot drivers (Start 0/1, Type 1/2) 131, missing image files 0
Storage class filters             partmgr / volsnap / fvevol+iorate+rdyboost, all system defaults
fsutil dirty query C:             not dirty
```

Boot chain intact, 131 boot-time drivers all present, storage filters all at system defaults, volume not marked dirty. At that point, everything statically checkable had been checked.

## Epilogue

### Cleaning Up InFlight Temp Directories and Booting Up

The recheck also surfaced a corner that was quietly eating space. `C:\Windows\WinSxS\Temp\InFlight` held 5,336 directories, about 1.5 GB, with timestamps running from 2023 all the way to November 2, 2026, all temporary copies that DISM and the update components never reclaimed. Not on any critical path, just wasted space.

Even more irritating: my own troubleshooting runs of `DISM /ScanHealth` and `/Get-Packages` left another 7,335 directories, about 1.4 GB, in that same folder, clawing back some of the space I'd just freed. After clearing those, C: went from 16.0 GB back to 16.5 GB.

Leave some headroom next time. The whole incident started with a full C: drive.

All nine hives are clean and loadable, the component store is intact, the boot chain is complete, and there are no pending operations. The machine rebooted and came up clean to the desktop.

Stepping back: the actual repair was two fields, a handful of bytes. Write the sequence number back at `0x008` and recompute the checksum at `0x1FC` in SECURITY, and do the same for BBI. Everything else was diagnosis and verification. But behind those few bytes was a mechanism I had to fully understand before I dared touch it.

### Pausing Windows Update for 1,000 Weeks via the Registry

One final thought, and the advice I ultimately gave my roommate.

The direct cause of the blue screen was a full C: drive. But why did C: fill up? Besides being small to begin with, because of Windows 11's relentless automatic updates.

Over the past year, Windows 11 update failures stopped being news. August 2025's `KB5063878` caused a batch of Phison and Innogrit SSDs to drop offline during large file writes, and even damaged partitions; that same month `KB5063875` broke system reset and recovery outright. October's `KB5066835` was even worse, simultaneously breaking `localhost` connections, the File Explorer preview pane, and smart-card authentication, and disabling USB keyboard and mouse input inside WinRE, forcing an emergency out-of-band patch. January 2026's `KB5074109` left some machines unable to boot with `UNMOUNTABLE_BOOT_VOLUME`, and February's `KB5077181` brought boot loops, broken login screens, and DHCP failures.

Every update claims to fix things and quietly introduces new ones. On a machine with a tight C: drive, the silent download, extraction, and disk writes of automatic updates are a blade hanging over your head.

So my recommendation: pause automatic updates through the registry, not with a third-party tool that strips out update components. Those tools often remove Windows Update components outright, which can break system components in the process. A registry pause just stretches the "pause updates" window out to 1,000 weeks and leaves the components untouched, so you can restore at any time.

The steps are simple. Create a text file, paste the following, rename it to `.reg`, and double-click to import:

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

`FlightSettingsMaxPauseDays` is `0x1b58`, which is 7,000 days in decimal, about 19 years. The `StartTime` / `EndTime` pairs stretch the feature-update, quality-update, and overall-update pause windows out to 2042.

When you want updates again, import this to undo it:

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

The `=-` after each value deletes it, so importing this clears the pause and Windows Update returns to normal.

That said, pausing updates treats the symptom. The real disease is the undersized C: drive. The last thing I told my roommate was blunt: either move your data and repartition with a bigger C:, or learn to clean up regularly. Otherwise, this time it was SECURITY that got written to death, and next time it'll be some other hive.
