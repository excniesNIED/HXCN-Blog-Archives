---
title: How I Fixed a 150 GB C: Drive That Filled Itself to Death: Recovering from 0x74 BAD_SYSTEM_CONFIG_INFO
pubDatetime: 2026-11-02T00:00:00.000+08:00
slug: win11-bad-system-config-info-en
tags:
  - Windows 11
  - Registry
  - BSOD
  - WinPE
  - Data Recovery
category: 踩坑日志
description: A first-person account of rescuing a Windows 11 23H2 laptop from a 0x74 BAD_SYSTEM_CONFIG_INFO boot loop caused by a completely full C: drive. Covers BitLocker checks, bcdboot/bootrec failures, repeated DISM 0xd000014c errors, locating the dirty flag in the SECURITY registry hive, byte-level comparison, controlled load experiments, and fixing the hive by changing two fields. Useful for anyone dealing with a full system drive, boot failure, or registry corruption.
---

For most people, I believe a single partition per drive is enough. If you have multiple drives, give each drive one partition. If you only have one drive, at most split it into a C: drive and a D: drive. And the C: drive should never be smaller than 200 to 300 GB; if you install heavy software, even 512 GB is not overkill.

Why am I so insistent? Windows loves to pile things onto the C: drive. Even if you install every program to D: or E:, caches, temp files, Windows Update components, and user profiles will still occupy C:. If C: is too small or runs low on free space, programs start crashing for no apparent reason, and in the worst case the system will not even boot. The opposite extreme is just as bad: I have seen people take a 1 TB drive and slice it into four or five small partitions. Then a 60 GB file or a new AAA game comes along, and even though the total free space across all partitions is more than enough, no single partition can hold it. You end up shuffling files back and forth just to make room.

A common counterargument is: "If you install programs on C:, you lose everything when you reinstall Windows." In practice, it is the other way around. After a reinstall, programs living on D: usually break anyway because their registry entries, runtimes, and configuration files are gone. You still have to reinstall them one by one. What you actually need to back up before a reinstall is just your chat history (usually in `C:\Users\<username>\Documents`), your Downloads folder (`C:\Users\<username>\Downloads`), pictures and videos, desktop files, browser bookmarks and saved passwords, and your Start Menu shortcuts plus `C:\Users\<username>\NTUSER.DAT` (keeping it lets you cross-reference what software was installed). If the drive has BitLocker Device Encryption enabled, unlock it or export the recovery key first. Do that, reinstall, put the files back, and you are done. It is far less painful than resizing partitions.

I picked up computers over a decade ago. Back then, older relatives and family friends loved splitting a drive into four partitions, a habit that came from the era when drive-cloning tools offered one-click "split into four" layouts. A lot of people who buy PCs on their parents' advice still end up with several tiny partitions today. Classmates regularly come to me with "C: drive is full" problems, and every time I end up consolidating files from their other partitions just to give C: some breathing room.

If you want to argue with that, what happened to my roommate's laptop is the perfect counterexample.

## Initial Guesses and Troubleshooting

### The Situation

My roommate's laptop is an ASUS that shipped with Windows 11 Home and has been riding automatic updates all the way to 23H2 (10.0.22631.5768). It has a single 1 TB SSD carved into several pieces: a 150 GB C: drive, two 389 GB data drives (D: and E:), plus a few factory recovery partitions. The C: drive held MATLAB, SQL Server 2022, Office 2014, and an entire Steam library. One day, out of nowhere, the machine bluescreened with `BAD_SYSTEM_CONFIG_INFO` (0x74), restarted, bluescreened again, and fell into a boot loop.

![BSOD screen](bsod-bad-system-config-info-en.svg)

After a few failed boots, Windows automatically kicked into Startup Repair, its built-in diagnostic tool. Predictably, it failed with the message "Startup Repair couldn't repair your PC," pointing to the log at `C:\Windows\System32\Logfiles\Srt\SrtTrail.txt`. Because the C: drive had been chronically low on space, System Protection was never enabled, so there were no restore points to roll back to.

![Startup Repair failed](startup-repair-failed-en.svg)

My roommate first asked a general-purpose AI assistant for help and tried the usual `chkdsk` and `sfc` commands inside the recovery environment. Neither turned up anything. Since both reported the disk and core system files were intact, my first instinct was that the UEFI boot configuration or boot manager had gone bad. I booted into WinPE from a Ventoy USB drive and opened DISM++ to do a boot repair. DISM++ immediately popped up an error saying it was "trying to load an incorrectly formatted file" and could not even read basic offline image information. I assumed the boot chain was completely broken, had DISM++ force-repair the boot files and write to the EFI partition, then rebooted. Instead of a blue screen, we now got a Recovery screen with error `0xc0000001`.

![Recovery error 0xc0000001](recovery-error-0xc0000001-en.svg)

`0xc0000001` is a very generic `STATUS_UNSUCCESSFUL` code. It literally means "something failed to come up during boot" but tells you nothing about what. The DISM++ error about an "incorrectly formatted file" was actually a crucial clue. Tools like DISM++ mount and read registry hives from `C:\Windows\System32\config` when they open an offline Windows installation. If one of those files is corrupt, DISM++ complains about the format. That strongly suggested the original `BAD_SYSTEM_CONFIG_INFO` bluescreen was caused by a broken registry hive.

### Turning Off BitLocker

Before touching any system files inside WinPE, you have to confirm the drive is not locked by BitLocker Device Encryption. ASUS laptops that ship with Windows 11 often have Device Encryption in a pre-provisioned, ready-to-activate state. My roommate signs in with a local account and has never linked a Microsoft account, so the recovery key was never uploaded to the cloud. If we changed boot files or the system partition in WinPE and triggered a TPM integrity check on the next boot, the machine would demand a recovery key we had no way to obtain. C: would be permanently locked.

First, I checked the encryption status with `manage-bde -status C:`:

```cmd
X:\Windows\System32>manage-bde -status C:

Protection:      Off
Lock Status:     Unlocked
Identification Field:  None
Automatic Unlock:    Disabled
Key Protectors:  None Found
```

"Key Protectors: None Found" sounds like an error, but it is great news. No key protectors means Device Encryption was never actually activated, the drive is plain NTFS, and we can read and write C: freely inside WinPE. To double-check, I ran `manage-bde -protectors -get C:`:

```cmd
X:\Windows\System32>manage-bde -protectors -get C:
Volume C: [OS]
All Key Protectors

ERROR: No key protectors found.
```

Next, I used `diskpart`'s `list vol` command to look at the partition layout and confirm the drive letters for the ESP boot partition, recovery partition, and data drives:

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

The layout was clear: 150 GB C: for the OS, two 389 GB data drives (D: and E:), a 260 MB FAT32 ESP holding EFI boot files, and a 950 MB NTFS partition with the WinRE recovery image. To eliminate any chance of BitLocker kicking in and locking the drive while we repaired the boot chain or edited the registry, I went ahead and fully turned off encryption on C:, D:, and E: with these commands:

```cmd
manage-bde -off C:
manage-bde -off D:
manage-bde -off E:
```

I ran `manage-bde -status` again afterward until it reported "Fully Decrypted." With that done, no BitLocker key check could interfere with later steps.

### Trying the Standard Playbook

With BitLocker out of the way, I started with a file system check to rule out bad sectors or NTFS metadata corruption:

```cmd
X:\Windows\System32>chkdsk C: /f /r

Windows has scanned the file system and found no problems.
No further action is required.

  157286727 KB total disk space.
  ...
   15979136 KB available on disk.
  4096 bytes in each allocation unit.
  0 KB in bad sectors.
  Total duration: 3.01 minutes (180616 ms).
```

`chkdsk` ran all five stages, came back completely clean, and reported zero bad sectors. The C: drive's NTFS file system was fine. Next up was repairing the boot chain. I used `diskpart` to assign letter `S:` to the 260 MB ESP, then ran `bcdboot` to copy the boot files and Boot Configuration Data (BCD) from the C: drive's Windows installation into the ESP:

```cmd
DISKPART> select volume 4
DISKPART> assign letter=S
DISKPART> exit

X:\Windows\System32>bcdboot C:\Windows /s S: /f UEFI /l zh-cn
Boot files successfully created.
```

`bcdboot` successfully wrote the boot files into the ESP; `S:\EFI\Boot\bootx64.efi` existed at 1,698,760 bytes. To make sure the UEFI firmware could find the default loader, I also manually copied `S:\EFI\Microsoft\Boot\bootmgfw.efi` over `S:\EFI\Boot\bootx64.efi`. With the boot files in place, I moved on to `bootrec` to fix the master boot record and scan for operating systems:

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

This was the first red flag. `bcdboot` had just written boot files successfully, yet `bootrec /scanos` could not find a single Windows installation on the entire disk, and `bootrec /fixboot` returned "Access is denied." When `bootrec` scans for installations, it needs to mount and read the offline registry hives under `C:\Windows\System32\config` to confirm volume mappings and storage controller settings. Finding zero installations usually means those core registry hives are too damaged to mount. I was not ready to conclude that yet, though, because `bootrec /fixboot` failing with "Access is denied" on UEFI systems is notoriously unreliable.

System file checks did not go smoothly either. `sfc /scannow /offbootdir=C:\ /offwindir=C:\Windows` returned "Windows Resource Protection could not perform the requested operation." Offline DISM image repair was even stranger:

```cmd
X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /RestoreHealth
Error: 87

DISM does not recognize the command-line option "/Image:C:\".
```

That "Error 87, does not recognize `/Image:C:\`" turned out to be a simple typo on my part: I had missed a colon when typing the command in the WinPE command prompt. It had nothing to do with system corruption.

At this point I had exhausted the standard playbook. The file system was fine, the boot files were fine, but `bootrec` could not see the installation, and `sfc` and `dism` kept failing. It was time to read the logs. In WinPE, two log files matter here: `C:\Windows\System32\Logfiles\Srt\SrtTrail.txt` records what Startup Repair actually did, and `C:\Windows\System32\Logfiles\Srt\DISMRepairLogFile.txt` records the low-level errors when Startup Repair tried to invoke DISM against the component store.

I started with `SrtTrail.txt`. The UTF-16 log opens with "Last successful boot time: 2026/11/1 9:32:11 (GMT)" and "Number of repair attempts: 64." It ran through a battery of disk, volume content, and boot manager tests, all passing, until it hit "Check for installed LCU" (LCU stands for Latest Cumulative Update), where the first session failed with code `0x43` and the third with `0x14c`:

```cmd
Name: Check for installed LCU
Result: Completed successfully. Error code =  0x43

Name: Check for installed LCU
Result: Completed successfully. Error code =  0x14c
```

Then I looked at the most important line in `DISMRepairLogFile.txt`:

```cmd
Failed to load offline SYSTEM hive from '...SYSTEM' ... [HRESULT = 0xd0000043 - NTSTATUS Error]
```

Seeing that, the AI assistant and I formed an initial theory: a recent Windows cumulative update had been interrupted mid-install, corrupting the current control set inside the `SYSTEM` hive and triggering the bluescreen. The `0xd0000043` code maps to `STATUS_SHARING_VIOLATION`, which made it look like the `SYSTEM` file was locked by another process.

Following this "update broke SYSTEM" theory, I tried rolling back pending updates. First, I manually mounted the `SYSTEM` hive with `reg load` to see if I could read its control set configuration, and to check whether `ControlSet002` or `LastKnownGood` could be swapped in:

```cmd
X:\Windows\System32>reg load HKLM\TEMP C:\Windows\System32\config\SYSTEM
The operation completed successfully.
```

To my surprise, `SYSTEM` mounted just fine, which meant its header and basic structure were not completely broken. What actually happened was that after mounting it in WinPE, I forgot to unload it with `reg unload`. Later DISM and Startup Repair runs then hit a handle conflict on that file and reported `0xd0000043`. At the time I only saw the sharing violation and never suspected my own mistake. I also checked the sizes of every registry file in `config` to see if any had become zero bytes:

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

None of them were zero bytes; every core hive had a normal size. Next I tried rolling back pending update transactions and listing installed packages for removal:

```cmd
X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /RevertPendingActions
Deployment Image Servicing and Management tool
Version: 10.0.22621.1
Image Version: 10.0.22631.5768

The scratch directory size might be insufficient to perform this operation. This can cause unexpected behavior. Use the /ScratchDir option to point to a folder with sufficient scratch space. The recommended size is at least 1024 MB.
Reverting pending actions from the image...

Error: 0xd000014c

X:\Windows\System32>dism /Image:C:\ /Get-Packages /Format:Table
...
Error: 0xd000014c

DISM failed. No operation was performed.
```

Both commands returned `0xd000014c` along with a warning: "The scratch directory size might be insufficient... please use /ScratchDir to point to a folder with sufficient scratch space. The recommended size is at least 1024 MB." That warning was actually a WinPE environment quirk: PE's RAM disk `X:\windows\TEMP` only has a few dozen megabytes, nowhere near enough for DISM to unpack and roll back update packages.

The error code `0xd000014c` is `0xC000014C` (`STATUS_REGISTRY_CORRUPT`) with the customer bit set. When I checked `X:\windows\Logs\DISM\dism.log`, I saw that DISM initializes its offline registry store by loading three core hives in sequence. The log clearly shows `SOFTWARE` and `SYSTEM` loading successfully, then `SECURITY` failing:

```cmd
CBS  Loading offline registry hive: SOFTWARE ... [OK]
CBS  Loading offline registry hive: SYSTEM ... [OK]
CBS  Loading offline registry hive: SECURITY ...
CBS  Failed to load offline registry: ...SECURITY ... [HRESULT = 0xd000014c - NTSTATUS Error]
CBS  Failed to load offline SECURITY hive. [HRESULT = 0xd000014c - NTSTATUS Error]
```

Now the picture was clear: what was broken was never `SYSTEM`, it was the `SECURITY` hive. Startup Repair wanted to read the list of installed LCUs, which requires opening the CBS component store, and the component store requires loading `SECURITY` first. With that failing, the whole repair pipeline stalled.

Around the same time, I casually checked drive space and suddenly realized I had overlooked something fatal: the C: drive had only a little over **100 MB** of free space left. After deleting a few large, unimportant files from the desktop, I managed to free up about **8.9 GB**.

The causal chain was now mostly clear: this 150 GB C: drive had long been stuffed with heavy software and caches. When Windows Update silently downloaded and unpacked a cumulative update in the background, the physical disk ran completely out of space, truncating or crashing the write transaction to the `SECURITY` hive and corrupting the file. Knowing the culprit was a broken `SECURITY`, the most intuitive fix was: move the damaged `SECURITY` out of the way and copy over a healthy one from my own computer running the same Windows version.

So in the WinPE command line I did the following: moved my roommate's damaged `SECURITY` (65,536 bytes) into `CorruptBak\SECURITY` as a backup, then copied the `SECURITY` file from my own laptop over to take its place. I also pointed DISM's scratch directory to the D: drive, which had plenty of space, and reran the pending-action rollback:

```cmd
X:\Windows\System32\config>move SECURITY CorruptBak\SECURITY
        1 file(s) moved.

X:\Windows\System32\config>copy CorruptBak\SECURITY SECURITY
        1 file(s) copied.

X:\Windows\System32\config>dism /Image:C:\ /ScratchDir:D:\backup /Cleanup-Image /RevertPendingActions

Reverting pending actions from the image...
The operation completed. Revert will be attempted after reboot.
The operation completed successfully.

X:\Windows\System32\config>if exist C:\Windows\WinSxS\pending.xml del /f /q C:\Windows\WinSxS\pending.xml
X:\Windows\System32\config>chkdsk C: /f
The type of the file system is NTFS.
```

Miraculously, after swapping the file, `RevertPendingActions` went from reliably failing with `0xd000014c` to "The operation completed successfully." I was thrilled and thought the problem was solved. I deleted `pending.xml` and rebooted immediately. Reality hit hard: the machine still would not boot into Windows, and the screen showed that familiar Recovery error `0xc0000001`. That moment was genuinely deflating. DISM had worked, so by all logic it should have been fine.

## Deep Dive with an AI Agent

After spending most of the day going in circles, I set up `oh-my-pi` (omp) inside FirPE, a WinPE variant with network access, and let an AI agent run a thorough audit and a series of experiments in a completely read-only environment. The post-reboot `0xc0000001` meant the kernel was still rejecting a hive during early boot, while DISM working only proved that the `SECURITY` file I had dropped in was structurally valid. Two questions needed answers: why did a structurally valid registry file let DISM work but still fail to boot, and what exactly was wrong with the original damaged `SECURITY` file?

### Pinpointing the Culprit from Logs and Crash Dumps

The agent first zeroed in on the crash dump. Every Windows bluescreen leaves a `.dmp` memory dump in `C:\Windows\Minidump`. This machine had exactly one: `110226-9312-01.dmp`, timestamped 2026-11-02 07:36:19 UTC (15:36:19 local time). The agent parsed its header and got this:

```cmd
signature   = PAGE / DU64
major/minor = 15.22621
bugcheck    = 0x74  (BAD_SYSTEM_CONFIG_INFO)
P1 = 0x2
P2 = 0xffff94869fbd2940
P3 = 0x1
P4 = 0xffffffffc000014c
Crash time   = 2026-11-02 07:36:19 UTC (= 15:36 local)
Embedded ASCII  = "HiveLoadFromomFile" + "status"
Embedded UTF-16 = "<SECURITY"
```

`bugcheck 0x74` is `BAD_SYSTEM_CONFIG_INFO`, and the fourth parameter `P4 = 0xC000014C` is `STATUS_REGISTRY_CORRUPT`. The most valuable evidence was the embedded strings: the ASCII `HiveLoadFromomFile` is the kernel's internal function for loading registry hives (the doubled `om` is a kernel log string-concatenation artifact, not a typo), and the UTF-16 `<SECURITY` spelled the answer out in plain sight. The kernel declared the `SECURITY` hive corrupt while loading it during boot.

Next, the agent parsed `DISMRepairLogFile.txt`, which has 1,974 timestamped lines spanning from 2026-11-01 17:35 to 2026-11-02 15:21. Extracting every load failure:

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

Twelve failures in a row, all pointing at `SECURITY`, all `0xd000014c`, spread across nearly 22 hours. The single exception was that `SYSTEM` entry with `0xd0000043` at 15:21:12, which happened right after I had manually mounted `SYSTEM` and forgotten to unload it. That confirmed the earlier `0x43` error was not a `SYSTEM` fault at all; it was a handle conflict left behind by my own actions.

Then the agent pulled up `C:\Windows\Logs\CBS\CBS.log` and found three decisive timestamped lines:

```cmd
2026-10-23 18:36:21, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:23, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:25, Info  CBS  System volume has 0G free disk space
```

On October 23, 2026, at 18:36, the CBS component service logged "System volume has 0G free disk space" three times in a row, followed by `Maint: incomplete, interruptions: 1`. That proved the C: drive had been written down to 0 bytes free during that maintenance window. The timeline matched perfectly: on October 23 the disk filled up, the `SECURITY` hive's write transaction crashed when it ran out of space, leaving a dirty flag behind. For the next eight or nine days the machine booted fine with that hidden flaw, until the reboot on November 1, when the kernel tried to load the dirty `SECURITY`, found it could not replay the logs, and threw the `0x74` bluescreen.

### Why Dropping In My Own SECURITY Hive Still Failed to Boot

Now we had to solve a puzzle: after swapping in my `SECURITY` file, DISM stopped erroring out, so why did the system still refuse to boot?

The answer is that DISM's validation logic and the Windows kernel's boot-time validation logic are completely different things. When DISM mounts a registry hive offline, it mainly checks the file's `regf` signature, the structural integrity of the internal `hbin` data blocks, and the header checksum. It only cares whether the file is a valid registry file. It never compares the contents to see if they belong to this specific machine.

The agent parsed the `SECURITY` file I had dropped in and found the key identity markers did not match:

```cmd
Computer name   HXCN-WIN
Machine SID     S-1-5-21-1262172508-...
```

Meanwhile, the `SAM` (Security Accounts Manager) hive on my roommate's laptop recorded a different identity:

```cmd
Computer name   LAPTOP-VQSR6OMV
Machine SID     S-1-5-21-4291209427-303460211-4247354471
```

Here `PolAcDmS` is the machine domain security identifier and `PolAcDmN` is the computer name. Even worse, the `Policy\Secrets` section of my `SECURITY` file contained my laptop's secret entries, like `NL$KM`, `DefaultPassword`, and `MouseWithoutBorders`, but it was missing `DPAPI_SYSTEM` entirely.

That triggered two fatal boot blockers:

First, during early boot, the LSA (Local Security Authority) subsystem has to compare the machine domain SID stored in the `SECURITY` hive against the one in the `SAM` hive. If they do not match, LSA concludes the security subsystem configuration is corrupt and refuses to continue initialization, bluescreening the system.

Second, `DPAPI_SYSTEM` is the master key for Windows DPAPI (Data Protection API). Every piece of encrypted data on that machine, including browser-saved passwords, Credential Manager entries, and EFS-encrypted files, is encrypted with that `DPAPI_SYSTEM` key. My `SECURITY` file did not contain my roommate's key at all. Even if we had somehow gotten past the SID check and booted into Windows, every saved password and encrypted file would have been unrecoverable.

So that "fix" was a false fix: it only stopped DISM from complaining while upgrading the problem from "corrupt file structure" to "file that does not belong to this machine." Fortunately, the real original `SECURITY` had not been overwritten. It was sitting untouched in `C:\Windows\System32\config\CorruptBak\SECURITY`, 65,536 bytes, last modified October 31 at 21:18.

### Sequence Numbers 17965 and 17964: The Two-Byte Dirty Flag

Knowing we had to save the original `SECURITY` file, the next step was figuring out exactly what was wrong with it. The Windows registry hive format is fixed: the first 4 KB of the file is a `regf` header (Base Block) with a fixed structure, followed by several `hbin` data blocks that hold the actual key and value cells. The agent parsed the header of `CorruptBak\SECURITY` directly:

```cmd
Offset 0x000   "regf"                Signature
Offset 0x004   seq1                  Primary sequence number
Offset 0x008   seq2                  Secondary sequence number
Offset 0x01C   type                  Hive type
Offset 0x024   root                  Offset of the root key nk cell
Offset 0x028   hbins                 Total size of the bins area in bytes
Offset 0x1FC   checksum              Header checksum
```

Two four-byte integer fields in the header are critical: `seq1` (primary sequence number) and `seq2` (secondary sequence number). These two numbers exist to guarantee registry consistency. Every time the Windows kernel writes to the registry, it first writes the in-memory changes to the transaction log (`.LOG1` or `.LOG2`), then increments `seq1` in the file header, commits the `hbin` data block changes, and finally updates `seq2` to match `seq1`. If a write completes cleanly, `seq1` and `seq2` are equal.

At offset `0x1FC`, at the end of the header, sits a checksum. The algorithm is simple: take the first 512 bytes of the header, from `0x000` to `0x1F8`, treat every 4 bytes as a 32-bit unsigned integer, and XOR them all together. There is an edge-case convention: if the XOR result is `0xFFFFFFFF`, write `0xFFFFFFFE`; if it is `0`, write `1`.

Parsing my roommate's original `SECURITY` header gave this:

```cmd
CorruptBak\SECURITY   65,536 B   seq 17965 / 17964   checksum 0xb3d51b08 (self-consistent)
```

`seq1 = 17965`, `seq2 = 17964`, off by one. That is the dirty flag: it means the last registry write transaction never finished committing, leaving the file in an inconsistent intermediate state. When the kernel sees `seq1 != seq2` at boot, it cannot use the file directly. It first has to try replaying the transaction log to bring the data back to a consistent state.

So where were the transaction logs? Looking at `SECURITY.LOG1` and `SECURITY.LOG2`:

```cmd
SECURITY.LOG1   49,152 B   seq 208   (stale log from 2022)
SECURITY.LOG2    8,192 B   seq 17963 (2 transactions behind the hive)
```

`SECURITY.LOG1` was still stuck in 2022, and `SECURITY.LOG2` was two transactions behind the current version. The hive's `seq1` was 17965, and the log replay rule requires the log's sequence number to be exactly `seq1` (17965) or `seq1 - 1` (17964). But one log was at 208 and the other at 17963. Neither matched. The log chain was broken, and replay was impossible. This was the aftermath of the October 23 disk-full incident: the write transaction hit the disk, but the sequence number sync and log update both failed.

The essence of the problem was now clear: the `SECURITY` file's data area was not actually corrupted. The header just carried a dirty flag that never got cleared, and the kernel did not dare to use it.

To confirm this theory beyond doubt, the agent ran a controlled load experiment on the D: drive, using `reg load` to test 10 different combinations, working only on copies and never touching C::

| Case | Hive state | Accompanying logs | `reg load` result |
|---|---|---|---|
| s1 | Dirty 17965/17964 | None | **FAIL** |
| s2 | Dirty 17965/17964 | 0-byte LOG1/LOG2 | **FAIL** |
| s3 | Dirty 17965/17964 | Stale LOG1(208)+LOG2(17963) | **FAIL** |
| t1 | Dirty, seq2 reduced by 2 (17965/17963) | None | **FAIL** |
| t2 | seq2 := seq1 (17964/17964), checksum recalculated | None | OK |
| i | Patched 17965/17965, checksum recalculated, no logs | None | OK |
| j | Patched 17965/17965, checksum recalculated, stale LOG1/LOG2 kept | OK |
| s4 | seq equal (17965/17965) but `0x1FC` checksum not recalculated | None | **FAIL** |

The conclusion was remarkably clean:

- As long as `seq1 != seq2`, the kernel refuses to load the hive, regardless of whether logs are present, whether they are zero bytes, or whether they can be replayed. The dirty flag alone is fatal.
- As long as `seq1 == seq2` and the header checksum is correct, even a stale 2022 log sitting right next to the file does not affect loading at all.
- The checksum must be recalculated along with the sequence number; changing only the sequence number without updating the checksum still fails.

### Uncovering the Dirty BBI Hive and the Orphaned Driver

While auditing all the registry hives, the agent found one more file carrying a dirty flag besides `SECURITY`: `BBI`. BBI stands for Background Broker Infrastructure; it holds the queue for Windows background tasks and UWP app package states, and it is not a hive the kernel needs for booting. My roommate's `BBI` was 1,310,720 bytes, stuck at sequence numbers `53232/53231`, again with `seq1 != seq2`, and the accompanying `BBI.LOG1` and `BBI.LOG2` were both zero bytes.

`BBI` contained `WorkItems` (81 entries), `PackageImportance` (1,431 entries), and `Events` (136 entries). Judging by the file timestamp, it had been dirty since October 31, yet the machine still booted on November 1 because its corruption does not cause a bluescreen. Still, since it was the only other hive besides `SECURITY` that was structurally unloadable, fixing it at the same time was the safest move.

Beyond `BBI`, the agent also audited every driver that loads during kernel boot. The method was to walk through `HKLM\SYSTEM\ControlSet001\Services` and check every driver service with `Start=0` (boot start) or `Start=1` (system start), verifying that the `.sys` file each one points to actually exists. Of the 131 boot drivers checked, zero had missing files. But one real defect turned up:

```cmd
HKLM\SYSTEM\ControlSet001\Services\softaal
  ImagePath    = \??\C:\Program Files (x86)\Tencent\QQPCMgr\15.1.22354.301\softaal64_ev.sys
  Start        = 1  (SERVICE_SYSTEM_START)
  ErrorControl = 0
```

`softaal` is a kernel driver for Tencent PC Manager (QQPCMgr). The problem is that after QQPCMgr upgraded to version 15.6, the old `15.1.22354.301` directory was removed by the uninstaller, but the `softaal` service entry was left behind in the registry, still pointing at `softaal64_ev.sys` in the old directory. That meant every boot, the Windows kernel tried to load a driver file that no longer existed.

Fortunately, its `ErrorControl = 0`, so a load failure is ignored and does not cause a bluescreen. But since we found the leftover, we should clean it up. The fix is to change `Start` from `1` to `4`, disabling the driver service.

There were also a few orphaned drivers that do not load during boot, such as `ksapi64` (Kingsoft Antivirus remnant, `Start=2`), `ROGKB` and `ROGMS` (ASUS utilities, `Start=3`), and `TSSKX64` (another Tencent PC Manager remnant, `Start=3`). `TSSKX64` deserves a special mention: the registry says the file is `tsskx64_EV.sys`, but the actual file on disk is `TSSKX64.sys`, with a case mismatch and a wrong `_EV` suffix. It is a half-finished job left by Tencent's uninstaller. All of these drivers have `Start >= 2`, so the kernel does not load them during boot, and they had no effect on this startup failure.

## The Fix

### Why the ISO's 9 MB SYSTEM Hive Can't Overwrite Yours—and Why You Still Need the ISO

Before discussing how to repair `SECURITY`, we need to rule out a solution many people think of first: just overwrite the damaged registry files with the ones from a Windows installation ISO. My roommate happened to have a `Win11_23H2_Chinese_Simplified_x64v2.iso` image, version 22631.2861. I mounted it read-only with DISM to the D: drive to compare its contents.

As soon as it was mounted, I could see this approach would not work. The `Windows\System32\config` directory inside the official image holds a generic installation-state registry that contains none of this specific machine's hardware or account information:

| Hive | Inside the ISO | My roommate's machine | Consequence of overwriting |
|---|---|---|---|
| SYSTEM | 9,175,040 B / 661 services / computer name `MINWINPC` | 32,243,712 B / 846 services / `LAPTOP-VQSR6OMV` | All driver services and the device tree are lost; guaranteed `INACCESSIBLE_BOOT_DEVICE` bluescreen |
| SAM | 8,192 B (empty account database) | 131,072 B / 5 accounts | All local accounts wiped; no login possible |
| SECURITY | 8,192 B (empty security policy) | 65,536 B | LSA secrets and the DPAPI master key wiped; all encrypted data permanently unreadable |
| SOFTWARE | 66,584,576 B | 117,440,512 B | Registration info for every installed program lost |
| BBI | 8,192 B (empty queue) | 1,310,720 B | This one is safe to use |

Overwriting the machine's `SYSTEM` with the ISO's version is like asking a computer running MATLAB and SQL Server to boot with the default driver list from a fresh Windows install; it will bluescreen with `INACCESSIBLE_BOOT_DEVICE` every single time. The ISO's `SAM` and `SECURITY` are empty to begin with, so copying them over is equivalent to wiping every account and key. The ISO version 22631.2861 is also older than the installed 22631.5768, so an in-place upgrade repair would be rejected by the setup program outright.

So is the ISO useless? Not at all. Its proper role is as a comparison baseline. For example, while auditing boot drivers I noticed that several basic kernel services on my roommate's `SYSTEM` hive (like `wof`, `null`, `npfs`, `msfs`, `cimfs`, `beep`) had no `ImagePath` field. At first I thought that was registry corruption, but comparing against the ISO's `SYSTEM` showed that a fresh Windows install has no `ImagePath` for those services either. That is normal, not a fault. Similarly, if `BBI` turned out to be unfixable, the ISO's 8 KB empty `BBI` is the only file that could be safely copied over. The ISO cannot be used as a parts bin; it can only be used as a reference.

### Full Backup, Two-Byte Patch, and Stale Log Quarantine

With the repair plan settled, it was time to execute. Before modifying any system file, a complete backup is mandatory, so we could roll back if anything went wrong. I copied the entire `C:\Windows\System32\config` directory, including all 9 registry hives and every `.LOG1`, `.LOG2`, `.TM.blf`, and `.regtrans-ms` transaction log, 43 files totaling 249,708,544 bytes (238.1 MB), to `D:\_fix\backup_20261102120607\config\` on the D: drive. After copying, I compared SHA-256 hashes file by file to confirm every byte matched the source.

The repair operation targeted only the original `CorruptBak\SECURITY`, 65,536 bytes:

```cmd
Source   C:\Windows\System32\config\CorruptBak\SECURITY    65,536 B   17965 / 17964
Change   Offset 0x008: write back 17965                                (clear dirty flag)
Change   Offset 0x1FC: recalculate checksum   0xb3d51b08 -> 0xb3d51b09
```

Specifically, at offset `0x008` I changed the secondary sequence number `seq2` from 17964 to 17965 to match the primary sequence number `seq1`, clearing the dirty flag. Then I recalculated the XOR checksum of the first 512 bytes of the header and wrote the new value, changing `0xb3d51b08` to `0xb3d51b09` at offset `0x1FC`.

After the patch, the entire file differed from the original by only 2 bytes. To make sure nothing was broken, the agent ran a full semantic comparison between the patched file and the original: both had 166 keys and 164 values, and every key name, value name, value type, and value data matched exactly, with 0 differences. The structural walkthrough was equally clean: all 166 `nk` cells had correct parent pointers, all 33 subkey index cells were valid `lh` types, both security descriptor cells were intact, and no reachable cell was out of bounds.

I also verified that this file really belonged to my roommate's machine:

```cmd
PolAcDmN   LAPTOP-VQSR6OMV                        <- matches SYSTEM\ComputerName
PolAcDmS   S-1-5-21-4291209427-303460211-4247354471  <- matches SAM domain SID
Policy\Secrets   8 entries, including DPAPI_SYSTEM, RasDialParams!...-1001#0, and 6 MSSQL/SQL service accounts
Root key LastWriteTime   2026-11-01 09:32:10 UTC       <- exactly matches "last successful boot 11/1 17:32 local"
```

`PolAcDmN` and `PolAcDmS` matched `SYSTEM` and `SAM` perfectly, `Policy\Secrets` contained 8 secret entries, and the `DPAPI_SYSTEM` master key was there. The root key's last write time, 2026-11-01 09:32:10 UTC, lined up exactly with `SrtTrail.txt`'s "last successful boot 11/1 9:32:11."

Before writing the patched `SECURITY` back to `C:\Windows\System32\config\SECURITY`, I needed to deal with the two stale log files sitting next to it, `SECURITY.LOG1` and `SECURITY.LOG2`. The controlled experiments had already proven that as long as the `SECURITY` file itself is clean, those old logs do not affect loading. But to eliminate any ambiguity and prevent other diagnostic tools from misreading them later, I moved them to a quarantine directory on the D: drive at `D:\_fix\quarantine\`. Once they were gone, the kernel would automatically rebuild a fresh, clean log file on the next mount.

The same method was used to repair `BBI`: at offset `0x008`, change `seq2` from 53231 to 53232, recalculate the checksum, and write it back to `0x1FC`. The patched hive passed the `reg load` test, and all 81 `WorkItems`, 1,431 `PackageImportance` entries, and 136 `Events` were preserved.

Last came the orphaned driver. I mounted the `SYSTEM` hive with `reg load`, navigated to `HKLM\SYSTEM\ControlSet001\Services\softaal`, changed `Start` from `1` to `4` (disabled), then unloaded it with `reg unload`. From then on, the kernel would no longer try to load the nonexistent `softaal64_ev.sys` at boot.

### Clearing the Hibernation File and Update Leftovers

With the registry repaired, the next step was addressing the root cause of the whole incident: disk space. First to go was `C:\hiberfil.sys`, the file Windows uses for hibernation, weighing in at 6,715,396,096 bytes (6.25 GiB). I read its first 4 KB with a hex tool and found every byte was 0. That meant the hibernation file's header was already destroyed, so even if the system could boot, `winresume` could never restore any hibernation state from it. It was nothing but wasted space now.

Deleting `hiberfil.sys` instantly raised C:'s free space from 8.9 GB to 16.5 GB. As a side note, the Boot Configuration Data (BCD) had four `resumeobject` entries pointing at this file; deleting it meant the bootloader would no longer waste time trying to resume from hibernation on the next boot.

Besides the hibernation file, several leftover directories from system updates and resets were eating space. Before cleaning them, I confirmed there were no pending installations or update transactions (`SetupType=0`, `SystemSetupInProgress=0`, and no `pending.xml`), to avoid deleting anything still in use. Once that was confirmed safe, I removed these directories:

```cmd
C:\$WinREAgent (1,771 MB, WinRE update rollback data)
C:\$Windows.~BT (56.7 MB, Windows upgrade temp files)
C:\$SysReset (0.3 MB, system reset leftovers)
C:\Windows\SoftwareDistribution\Download (65.5 MB, Windows Update download cache)
```

On top of that, I cleaned up the temporary files my own DISM diagnostic runs had created in the `InFlight` directory. C:'s used space dropped from 135.2 GB to 127.6 GB, and free space settled at 16.5 GB. Finally, I unmounted the ISO image and released the mount point:

```cmd
dism /Unmount-Image /MountDir:D:\_fix\mount /Discard
dism /Cleanup-Mountpoints
```

### Post-Repair Verification

All the modifications were done, but it was not time to reboot yet. A full verification pass was necessary to make sure every fix had taken effect and nothing new had been broken.

The first verification, and the most convincing one: rerunning `dism /Image:C:\ /Cleanup-Image /Get-Packages` inside WinPE. Before the repair, this command failed outright with `0xd000014c` because it needs to load the `SECURITY` hive to initialize the CBS component store. After the repair, the output was:

```cmd
Deployment Image Servicing and Management tool
Version: 10.0.22621.1

Image Version: 10.0.22631.5768

...
The operation completed successfully.
```

The command successfully listed all 83 update packages, every one marked "Installed," with no pending operations. That output is far more convincing than any `reg load` self-check, because it walks through the entire CBS store initialization process, proving that `SECURITY` can now be recognized and used by the system.

Immediately after, I ran `dism /Image:C:\ /Cleanup-Image /ScanHealth` to check component store integrity. The result was "No component store corruption detected," confirming that aside from those two dirty flags, the system components themselves had not been damaged.

The second verification was a four-layer structural check on all 9 registry hives: file signature, sequence numbers, and checksum; `hbin` data block chain integrity; a full traversal from the root key down, checking parent pointers, `li`/`lf`/`lh`/`ri` subkey tables, and value tables; and finally a count of any allocated but unreachable "orphan keys."

```cmd
Hive         Bytes        Sequence        Dirty  Checksum  Keys      Values
SYSTEM       32243712     395834/395834   No     OK        91,391    194,730
SOFTWARE     117440512    937587/937587   No     OK        372,888   640,232
SAM          131072       3911/3911       No     OK        80        100
SECURITY     65536        17970/17970     No     OK        166       164
DEFAULT      6029312      238433/238433   No     OK        8,201     10,937
DRIVERS      8777728      4850/4850       No     OK        36,424    52,954
COMPONENTS   32768000     9216/9216       No     OK        61,793    197,776
ELAM         32768        13/13           No     OK        1         0
BBI          1310720      53233/53233     No     OK        1,652     10,129
```

All 9 hives had matching sequence numbers, all dirty flags cleared, 0 parent pointer errors, 0 subkey table errors, 0 value table errors, 0 `hbin` chain breaks, and 0 orphan keys. All 9 files passed the `reg load` test.

One small episode is worth mentioning: while walking the `SYSTEM` hive, the agent found a 72-byte allocated cell at offset `0xd1a718` that happened to start with the bytes `6e 6b` (`nk`). At first glance it looked like an overlooked orphan key, but checking the specification showed that the minimum size of an `nk` cell is `0x4C` (76 bytes). This cell was only 72 bytes, so it did not meet the spec; it was just a piece of ordinary data that happened to start with `nk`. I almost modified a file over a problem that did not exist.

The third verification was identity consistency. I double-checked that `SECURITY`'s `PolAcDmN`, `PolAcDmS`, `ProfileList`, the `SAM` account list, and the LSA boot key all matched correctly:

```cmd
PolAcDmN   LAPTOP-VQSR6OMV
PolAcDmS   S-1-5-21-4291209427-303460211-4247354471
ProfileList  S-1-5-21-...-1001  ->  C:\Users\admin
SAM accounts     admin / Administrator / DefaultAccount / Guest / WDAGUtilityAccount
Lsa boot key  TC463EF4966D8796     (assembled from the four class names JD+Skew1+GBG+Data)
```

Under `ControlSet001\Control\Lsa`, the values of the four keys `JD`, `Skew1`, `GBG`, and `Data` are all empty. The real SYSKEY boot key is hidden in the class names of those four keys. That is why many third-party registry tools cannot read it.

Finally, I confirmed the overall state one more time: no leftover mounted hives, `bcdedit`'s `{default}` boot entry pointing to `C:\Windows\system32\winload.efi`, the WinRE recovery image `Winre.wim` present, storage class filters all set to system defaults, and `fsutil dirty query C:` reporting the volume was not dirty.

## Epilogue

### Cleaning Up InFlight Temp Directories and Booting Up

Before rebooting, I also cleaned up an easily overlooked "space assassin": the `C:\Windows\WinSxS\Temp\InFlight` directory. This is the staging area DISM and Windows Update components use when unpacking and replacing system files, and under normal circumstances it should be cleaned up automatically after use. On this machine, the directory had accumulated 5,336 subdirectories taking up 1,498.9 MB, with timestamps ranging from October 11, 2023 all the way to November 2, 2026, all leftovers from past updates that were never reclaimed.

What made it more interesting was that the several `dism /ScanHealth` and `/Get-Packages` runs I did during troubleshooting also left behind 7,335 directories and 1,393 MB of temporary files under `InFlight`, dropping C:'s free space from 16.5 GB to 16.0 GB. After finishing the audit, I deleted those newly created temp files too, bringing the space back to 16.5 GB. That little episode also confirmed that the starting point of this whole incident was a full C: drive, and every bit of space matters.

All repairs, cleanup, and verification were complete. Now, all 9 registry hives were clean and loadable, the component store had no corruption, the boot chain was intact, there were no pending update operations, and the C: drive had enough room again. Whether the machine would boot into Windows came down to whether the LSA subsystem would accept this patched `SECURITY`.

I pulled out the USB drive and pressed the power button. This time there was no bluescreen and no Recovery screen. The display lit up, and the familiar Windows 11 lock screen finally appeared. I typed in the password and reached the desktop. The repair was done.

### Pausing Windows Update for 1,000 Weeks via the Registry

The root cause of this incident was the tiny C: drive, but the direct trigger was Windows 11's background automatic updates. If Windows Update had not been silently downloading and writing update packages while the disk had only 100 MB left, the `SECURITY` hive would never have been corrupted. Speaking of Windows updates, Microsoft's engineering quality has been slipping badly over the past year or two. Nearly every cumulative update introduces a fresh batch of problems for some users:

- **August 2025 (KB5063878)**: Many users reported that after installing it, SSDs with Phison or InnoGrit controllers would suddenly disappear during large file writes, causing partition corruption. The same month's KB5063875 broke the built-in system reset and recovery features, forcing Microsoft to issue an out-of-band patch.
- **October 2025 (KB5066835)**: This update caused a whole string of problems at once: localhost (`127.0.0.1`) `HTTP.sys` connections were severed, breaking local development environments; File Explorer's preview pane threw false security warnings; smart card authentication failed; and most absurdly, it broke USB keyboard and mouse drivers inside the WinRE recovery environment, leaving users staring at a recovery screen with no way to click anything until Microsoft rushed out KB5070773 a week later.
- **January 2026 (KB5074109) and February 2026 (KB5077181)**: These two cumulative updates caused some machines to hit `UNMOUNTABLE_BOOT_VOLUME` on startup, made classic Outlook freeze when opening PST files, broke normal shutdown and sleep, damaged the login screen, and caused DHCP network drops plus `dxgmms2.sys` bluescreens.

Windows Update fixes old vulnerabilities while almost always introducing new problems. For a computer with a 150 GB C: drive, the best move is to turn off automatic updates entirely, or at least stop it from messing around in the background. Microsoft's built-in "Pause updates" only lets you pause for up to 5 weeks before it automatically resumes. There are third-party tools like Windows Update Blocker that disable updates by directly deleting or breaking Windows Update service components, but that approach is too heavy-handed. Deleting system components makes recovery painful later and can break other features that depend on the update service.

A safer, fully reversible method is to modify the registry directly and manually extend the update pause to 1,000 weeks (roughly 19 years). This does not break any system files, keeps Windows Update quiet in the background, and if you ever want updates back, you can undo it with one click. The steps are simple: create a new text file, paste the content below, rename the file extension from `.txt` to `.reg`, and double-click to import:

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

What this registry file does is tell Windows Update that feature updates and quality updates are paused until September 5, 2042, and that the maximum allowed pause duration is set to 7,000 days (`0x1b58` in decimal). After importing, open Settings > Windows Update and you will see the "Pause updates" option has turned into a very long time, which effectively means automatic updates are permanently off.

If you ever want to restore normal Windows Update behavior, just import a recovery file that deletes all the values written above. Again, create a new text file, paste the content below, rename the extension to `.reg`, and double-click to import:

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

After importing the recovery file, Windows Update returns to its default state and can receive Microsoft's patches normally again. The beauty of this method is that it is fully controllable: turn it off whenever you want, turn it back on whenever you want, and it leaves no junk behind in the system.
