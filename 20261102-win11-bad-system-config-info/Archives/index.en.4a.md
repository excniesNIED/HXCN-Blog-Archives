---
title: "When a 150 GB C: Drive Hits Zero Bytes Free: Rescuing Windows 11 from a 0x74 BAD_SYSTEM_CONFIG_INFO Boot Loop"
pubDatetime: 2026-11-02T00:00:00.000+08:00
slug: win11-bad-system-config-info-en
tags:
  - Windows 11
  - Registry
  - BSOD
  - WinPE
  - Data Recovery
category: 踩坑日志
description: A hands-on Windows 11 23H2 recovery walkthrough after a full 150 GB C: drive triggered a 0x74 BAD_SYSTEM_CONFIG_INFO boot loop, covering BitLocker checks, UEFI boot repair, DISM 0xd000014c diagnostics, registry hive dirty-flag patching, and pausing Windows Update for 1,000 weeks. Suitable for users troubleshooting unbootable Windows systems or registry corruption.
---

## Preface

I have held a firm opinion on disk partitioning for years: for almost everyone, one partition per physical drive is plenty. If your machine has multiple SSDs, giving each drive a single partition is the cleanest setup you can run. Even if you only have a single drive and insist on separating the OS from personal files, splitting it into `C:` and `D:` is as far as you should ever go. And if you use your computer heavily, giving the `C:` drive at least 200 to 300 GB, or better yet 512 GB, is the bare minimum for a trouble-free life.

Plenty of people still carve out a tiny 100-something GB `C:` partition, assuming that as long as they change the installation path to `D:` or `E:` in every installer wizard, the system drive will stay roomy. Anyone who has actually lived with that layout knows what happens next. Even when you install applications on another partition, runtime caches, `%AppData%` profiles, package manager stores, the hibernation file (`hiberfil.sys`), and tens of thousands of side-by-side component copies unpacked by Windows Update (`C:\Windows\WinSxS`) all pile straight onto `C:`. Once free space on `C:` dries up, heavy software starts crashing, builds fail halfway through, and in the worst case a background Windows Update runs out of disk space mid-transaction while writing to the system registry, leaving the machine completely unbootable. Slicing one drive into three or four cramped partitions also creates a classic headache: when you try to download a 120 GB game or unpack a large dataset, your drive might have 200 GB of combined free space across all partitions, yet not a single volume has enough contiguous room to hold the file.

A common counterargument is that installing programs on `D:` protects them when you reinstall Windows. In practice, that almost never works. Most desktop software scatters COM registrations, configuration keys, and shared runtimes across the system registry (`SOFTWARE` and `NTUSER.DAT`), `C:\ProgramData`, and `C:\Windows\System32`. Once you wipe and reinstall `C:`, those leftover program folders on `D:` are mostly dead weight that throw missing-DLL or licensing errors until you run their installers again anyway. When you actually need to reinstall Windows, the only things worth backing up are your personal data and state:

- **Local chat and messaging archives**: desktop messaging databases and local folders that often default to `C:\Users\<username>\Documents` or `%AppData%`;
- **Standard user folders**: `Downloads` (`C:\Users\<username>\Downloads`), `Desktop`, `Documents`, `Pictures`, and `Videos`;
- **User configuration and an inventory of installed apps**: copying out the Start Menu shortcuts folder (`C:\Users\<username>\AppData\Roaming\Microsoft\Windows\Start Menu\Programs`) along with your user registry hive `C:\Users\<username>\NTUSER.DAT` gives you a complete reference list of what you had installed and what sat on your desktop;
- **Passwords, keys, and credentials**: browser password vaults, SSH keys, software licenses, and certificates. And if BitLocker is enabled on the machine, you must either unlock and decrypt the drives beforehand or export the 48-digit recovery key to a safe place before touching the OS.

Backing up those files to an external SSD, doing a clean install, and putting your apps and data back is far cleaner than babysitting broken program folders on a secondary partition.

Back when I first started tinkering with PCs more than a decade ago, my parents' generation loved carving every hard drive into four partitions (`C:`, `D:`, `E:`, and `F:`). That habit carried over from old disk-setup wizards and early imaging tools that defaulted to a four-way split regardless of drive size. Even today, plenty of students around my age who bought their laptops on advice from older relatives still slice a 1 TB SSD into four cramped volumes on day one. Every few weeks at school, someone brings me a laptop with a bright-red `C:` drive bar that can no longer even load chat attachments. Every single time, I end up consolidating their scattered files off `E:` and `F:`, deleting the extra volumes, and merging the free space back into `C:`.

If you still think a 150 GB `C:` partition on a multi-partition drive is harmless, what happened to my roommate's laptop this week is a textbook counterexample.

---

## Initial Guesses and Troubleshooting

### The Situation

The patient was my roommate's ASUS laptop (`LAPTOP-VQSR6OMV`), which shipped with Windows 11 Home (Chinese Edition) and had automatically updated itself over time to version 23H2 (OS Build `10.0.22631.5768`). It had a 1 TB NVMe SSD partitioned the exact way I just described: `C:` was given only 150 GB, while the rest of the drive was split evenly into two 389 GB partitions (`D:` and `E:`). Because he uses the machine for coursework and development, that 150 GB `C:` drive was packed with MATLAB, SQL Server 2022, Office 2014, visual runtimes, and part of his Steam library.

On the evening of November 1, the laptop suddenly threw a Blue Screen of Death with the stop code `BAD_SYSTEM_CONFIG_INFO`.

![BSOD BAD_SYSTEM_CONFIG_INFO](bsod-bad-system-config-info-en.svg)

The machine rebooted, spun the loading circle for two seconds, and blue-screened again. After several failed boot attempts in a row, Windows automatically launched the Windows Recovery Environment (WinRE) and ran Startup Repair. Predictably, Startup Repair gave up after a few minutes and dropped him on the blue failure screen: "Startup Repair couldn't repair your PC," pointing to the log file `C:\Windows\System32\Logfiles\Srt\SrtTrail.txt`.

![Startup Repair Failed](startup-repair-failed-en.svg)

Because `C:` had been running low on space for months, System Protection was turned off and there were zero System Restore points available. Before handing the laptop over to me, my roommate spent a few hours following troubleshooting steps from an AI chatbot on his phone, running `chkdsk` and `sfc /scannow` from the WinRE Command Prompt without any luck.

When I sat down with the laptop, my initial reasoning was straightforward: since `chkdsk` found no bad sectors and `sfc` did not fix the boot loop, the SSD hardware was healthy and the core system binaries were probably intact. The most likely culprit was a corrupted UEFI Boot Configuration Data (BCD) store from an unclean shutdown. I plugged in my Ventoy USB drive, booted into a Windows PE (WinPE) environment, and opened the GUI tool DISM++ to run a quick boot repair.

Right away, DISM++ threw a strange error dialog as soon as I selected the offline Windows installation on `C:`: **"An attempt was made to load a program with an incorrect format"** (the Win32 translation of `STATUS_BAD_FORMAT` or an offline hive mount failure). It refused to even open the servicing session for `C:\Windows`. I forced a boot record repair anyway and rebooted. This time, the machine didn't even reach the `BAD_SYSTEM_CONFIG_INFO` blue screen; it halted immediately at the Windows Boot Manager recovery screen with error code `0xc0000001`.

![Recovery Error 0xc0000001](recovery-error-0xc0000001-en.svg)

In Windows NT status codes, `0xc0000001` is `STATUS_UNSUCCESSFUL`, a generic catch-all error meaning a required boot component failed to initialize. The screen itself tells you nothing about which component failed. However, that earlier DISM++ error about "an incorrect format" was a major clue: to open an offline Windows image, DISM++ has to mount the offline registry hives in `C:\Windows\System32\config\`. Failing at that step meant one of the core registry hive files was corrupted.

### Turning Off BitLocker

Before touching anything else inside WinPE, I had to check **BitLocker Drive Encryption**.

Most modern OEM laptops from ASUS, Lenovo, and Dell ship with Windows 11 Home configured for automatic **Device Encryption** (which uses BitLocker under the hood). If a user signs in with a Microsoft Account, Windows silently activates protection and backs up the 48-digit recovery key to their Microsoft account online. My roommate, however, had been using a local account since day one and never linked a Microsoft account. If modifying the boot sector or system hives in WinPE tripped the TPM's platform integrity check and locked the volume, there would be nowhere to retrieve a recovery key, and the entire drive's data would be lost for good.

Even though `C:` was readable in the WinPE file manager, I needed to verify the exact encryption state via `manage-bde` and check whether any key protectors existed. From the WinPE command prompt, I ran:

```cmd
X:\Windows\System32>manage-bde -status C:
```

The output (translated from the Chinese console) showed:

```cmd
Protection Status:    Protection Off
Lock Status:          Unlocked
Identification Field: None
Automatic Unlock:     Disabled
Key Protectors:       None Found
```

I also ran the command to list and export any key protectors on `C:` (if a numerical recovery password exists, this command prints the 48-digit key):

```cmd
X:\Windows\System32>manage-bde -protectors -get C:
BitLocker Drive Encryption: Configuration Tool version 10.0.22621
Copyright (C) 2013 Microsoft Corporation. All rights reserved.

Volume C: [OS]
All Key Protectors

ERROR: No key protectors found.
```

Seeing `Protection Off` and `No key protectors found` was a huge relief. It meant OEM Device Encryption was sitting in its pre-provisioned, dormant state: because a Microsoft account was never linked, Windows never generated a key protector or sealed the volume to the TPM.

Next, I opened `diskpart` to inspect the partition layout across the disk and identify the volume numbers for the EFI System Partition (ESP), recovery partition, and data volumes:

```cmd
X:\Windows\System32>diskpart

Microsoft DiskPart version 10.0.22621.1
On computer: MININT-BIUPGCV

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

That gave me the full map of the disk: Volume 0 was the 150 GB `C:` OS partition; Volumes 1 and 2 were the two 389 GB data partitions (`D:` and `E:`); Volume 4 was the hidden 260 MB FAT32 EFI System Partition (`SYSTEM`); Volume 5 was the 950 MB WinRE recovery partition; and Volumes 3 and 6 were ASUS factory recovery partitions.

After backing up my roommate's critical personal files to an external drive, I explicitly turned off BitLocker and decrypted `C:`, `D:`, and `E:` so that nothing could accidentally lock the volumes while I worked on the boot chain and registry:

```cmd
X:\Windows\System32>manage-bde -off C:
X:\Windows\System32>manage-bde -off D:
X:\Windows\System32>manage-bde -off E:
```

Running `manage-bde -status C:` again confirmed that the conversion status was `Fully Decrypted`.

### Trying the Standard Playbook

With BitLocker out of the way, I walked through the standard Windows recovery playbook step by step to rule out file system corruption, broken EFI boot files, and pending update transactions.

First, I ran a full five-stage `chkdsk` pass on `C:` to make sure the NTFS Master File Table (MFT), security descriptors, and cluster allocation bitmaps were clean:

```cmd
X:\Windows\System32>chkdsk C: /f
The type of the file system is NTFS.
Volume label is OS.
...
Stage 3: Examining security descriptors ...
Security descriptor verification completed.
Phase duration (Security descriptor verification): 21.64 milliseconds.
  241480 data files processed.
Phase duration (Data attribute verification): 0.26 milliseconds.
CHKDSK is verifying Usn Journal...
  5588424 USN bytes processed.
Usn Journal verification completed.
...
Stage 4: Looking for bad clusters in user file data ...
  1327856 files processed.
File data verification completed.
Phase duration (User file recovery): 2.68 minutes.

Stage 5: Looking for bad, free clusters ...
  3994784 free clusters processed.
Free space verification is complete.
Phase duration (Free space recovery): 1.52 seconds.

Windows has scanned the file system and found no problems.
No further action is required.

 157286727 KB total disk space.
 139439744 KB in 468801 files.
    448468 KB in 241481 indexes.
         0 KB in bad sectors.
   1419379 KB in use by the system.
     65536 KB occupied by the log file.
  15979136 KB available on disk.
```

All five stages finished in three minutes with `0 KB in bad sectors` and zero file system errors.

Second, I mounted the hidden 260 MB EFI System Partition (Volume 4) to drive letter `S:` and rebuilt the UEFI boot files using `bcdboot`, then copied `bootmgfw.efi` over `S:\EFI\Boot\bootx64.efi` so the default UEFI fallback path was guaranteed to match:

```cmd
DISKPART> select volume 4

Volume 4 is the selected volume.

DISKPART> assign letter=S

DiskPart successfully assigned the drive letter or mount point.

DISKPART> exit

Leaving DiskPart...

X:\Windows\System32>bcdboot C:\Windows /s S: /f UEFI /l zh-cn
Boot files successfully created.

X:\Windows\System32>dir S:\EFI\Boot
 Volume in drive S is SYSTEM
 Volume Serial Number is 8CE7-BD30

 Directory of S:\EFI\Boot

2023/05/08  09:39    <DIR>          .
2023/05/08  09:39    <DIR>          ..
2025/08/15  08:38         1,698,760  bootx64.efi
               1 File(s)      1,698,760 bytes
               2 Dir(s)     199,659,520 bytes free

X:\Windows\System32>copy S:\EFI\Microsoft\Boot\bootmgfw.efi S:\EFI\Boot\bootx64.efi
Overwrite S:\EFI\Boot\bootx64.efi? (Yes/No/All): y
        1 file(s) copied.
```

`bcdboot` succeeded cleanly. Next, I tried `bootrec`, offline `sfc /scannow`, and `dism`:

```cmd
X:\Windows\System32>bootrec /scanos
Scanning all disks for Windows installations.
Please wait, since this may take a while...
Successfully scanned Windows installations.
Total identified Windows installations: 0
The operation completed successfully.

X:\Windows\System32>bootrec /rebuildbcd
Scanning all disks for Windows installations.
Total identified Windows installations: 0

X:\Windows\System32>bootrec /fixboot
Access is denied.

X:\Windows\System32>sfc /scannow /offbootdir=C:\ /offwindir=C:\Windows
Beginning system scan. This process will take some time.

Beginning verification phase of system scan.
Windows Resource Protection could not perform the requested operation.

X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /RestoreHealth
Error: 87

DISM does not recognize the command-line option "/Image:C:\".
```

Every single command hit a wall: `bootrec /scanos` found `0` Windows installations, `sfc` aborted with `Windows Resource Protection could not perform the requested operation`, and `dism` threw Error 87. Checking `X:\windows\Logs\DISM\dism.log` later explained Error 87: I had accidentally mistyped the colon in one of my manual attempts (`dism /Image:C\ ...`, which resolved to `X:\Windows\System32\C\`), and retyping it fixed the command-line parser error. However, `bootrec` finding zero installations and `sfc` refusing to run pointed to the same underlying problem: both utilities have to load the offline registry hives in `C:\Windows\System32\config\` to validate the target OS, and something in `config\` was refusing to mount.

To see what WinRE's own Startup Repair had encountered, I opened `C:\Windows\System32\Logfiles\Srt\SrtTrail.txt` and `DISMRepairLogFile.txt`. `SrtTrail.txt` recorded the last good boot time and three Startup Repair sessions:

```cmd
Startup Repair diagnosis and repair log
---------------------------
Last successful boot time: 2026/11/1 9:32:11 (GMT)
Number of repair attempts: 64

Session details
---------------------------
System Disk = \Device\Harddisk0
Windows directory = C:\Windows
AutoChk Run = 0
Number of root causes = 0

Test Performed:
---------------------------
Name: Check for updates              Result: Completed successfully. Error code = 0x0
Name: System disk test               Result: Completed successfully. Error code = 0x0
Name: Disk failure diagnosis         Result: Completed successfully. Error code = 0x0
Name: Disk metadata test             Result: Completed successfully. Error code = 0x0
Name: Target OS test                 Result: Completed successfully. Error code = 0x0
Name: Volume content check           Result: Completed successfully. Error code = 0x0
Name: Boot manager diagnosis         Result: Completed successfully. Error code = 0x0
Name: System boot log diagnosis      Result: Completed successfully. Error code = 0x0
Name: Event log diagnosis            Result: Completed successfully. Error code = 0x0
Name: Internal state check           Result: Completed successfully. Error code = 0x0
Name: Check for installed LCU        Result: Completed successfully. Error code = 0x43
```

In Session 2, all ten hardware and boot manager checks passed with `0x0`, ending with the unhelpful root cause: `Startup Repair has tried several times, but still cannot determine the cause of the problem.` In Session 3, it failed once again on the final test, `Check for installed LCU` (Latest Cumulative Update), this time with error code `0x14c`:

```cmd
Name: Check for installed LCU
Result: Completed successfully. Error code = 0x14c
Time taken = 1469 milliseconds
```

At first, I focused on `0x43` from Session 1 and the very last block of `DISMRepairLogFile.txt` (logged at `15:21:12` on November 2):

```cmd
2026-11-02 15:21:08, Info  CBS  Loading offline registry hive: SOFTWARE, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SOFTWARE' from path '\\?\C:\Windows\System32\config\SOFTWARE'.
2026-11-02 15:21:08, Info  CBS  Loading offline registry hive: SYSTEM, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SYSTEM' from path '\\?\C:\Windows\System32\config\SYSTEM'.
2026-11-02 15:21:12, Info  CBS  Failed to load offline \\?\C:\Windows\System32\config\SYSTEM hive from '\\?\C:\Windows\System32\config\SYSTEM' into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SYSTEM'. [HRESULT = 0xd0000043 - NTSTATUS Error]
2026-11-02 15:21:12, Info  CBS  Failed to load offline SYSTEM hive. [HRESULT = 0xd0000043 - NTSTATUS Error]
2026-11-02 15:21:12, Error CBS  Failed to load offline store from boot directory: '\\?\C:\' and windows directory: '\\?\C:\Windows\' [HRESULT = 0xd0000043 - NTSTATUS Error]
```

Seeing `Failed to load offline SYSTEM hive` right next to `Check for installed LCU` sent both me and the AI assistant I was consulting down the wrong track: we assumed an interrupted cumulative update had corrupted or locked the `SYSTEM` hive. To check whether any registry hive had been truncated to 0 bytes, I listed `C:\Windows\System32\config` and tried loading `SYSTEM` manually with `reg load`:

```cmd
X:\Windows\System32>dir C:\Windows\System32\config
 Volume in drive C is OS
 Volume Serial Number is 7AE9-32CB

 Directory of C:\Windows\System32\config

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
              10 File(s)    198,828,032 bytes
               7 Dir(s)  10,064,023,552 bytes free

X:\Windows\System32>reg load HKLM\TEMP C:\Windows\System32\config\SYSTEM
The operation completed successfully.
```

Not a single hive file was 0 bytes (`RegBack` was empty, as expected on Windows 10 1803 and later), and `reg load HKLM\TEMP C:\Windows\System32\config\SYSTEM` succeeded immediately. Checking the `Select` key inside `SYSTEM` showed `Current = 1`, and trying to switch to `ControlSet002` didn't help either.

Still thinking a half-installed cumulative update was blocking boot, I ran `dism /Image:C:\ /Cleanup-Image /RevertPendingActions` to roll back pending update transactions, followed by `dism /Image:C:\ /Get-Packages /Format:Table`:

```cmd
X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /RevertPendingActions
Deployment Image Servicing and Management tool
Version: 10.0.22621.1

Image Version: 10.0.22631.5768

The scratch directory size might be insufficient to perform this operation. This can cause unexpected behavior.
Use the /ScratchDir option to point to a folder with sufficient scratch space. The recommended size is at least 1024 MB.
Reverting pending actions from the image...

Error: 0xd000014c

An error occurred reverting pending actions from the image.
For more information, review the log file.

The DISM log file can be found at X:\windows\Logs\DISM\dism.log

X:\Windows\System32>dism /Image:C:\ /Get-Packages /Format:Table
Deployment Image Servicing and Management tool
Version: 10.0.22621.1

Image Version: 10.0.22631.5768

The scratch directory size might be insufficient to perform this operation. This can cause unexpected behavior.
Use the /ScratchDir option to point to a folder with sufficient scratch space. The recommended size is at least 1024 MB.

Error: 0xd000014c

DISM failed. No operation was performed.
```

Both commands failed with `0xd000014c`, matching the `0x14c` code from `SrtTrail.txt` Session 3. I opened `X:\windows\Logs\DISM\dism.log` to see what `RevertPendingActions` and `Get-Packages` were actually choking on:

```cmd
2026-11-02 15:38:14, Info   CBS  Lazy store initialization mode, fully initialize.
2026-11-02 15:38:14, Info   CBS  Offline image is writable
2026-11-02 15:38:14, Info   CBS  Loading offline registry hive: SOFTWARE, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SOFTWARE' from path '\\?\C:\Windows\System32\config\SOFTWARE'.
2026-11-02 15:38:14, Info   CBS  Loading offline registry hive: SYSTEM, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SYSTEM' from path '\\?\C:\Windows\System32\config\SYSTEM'.
2026-11-02 15:38:14, Info   CBS  Loading offline registry hive: SECURITY, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SECURITY' from path '\\?\C:\Windows\System32\config\SECURITY'.
2026-11-02 15:38:14, Info   CBS  Failed to load offline \\?\C:\Windows\System32\config\SECURITY hive from '\\?\C:\Windows\System32\config\SECURITY' into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SECURITY'. [HRESULT = 0xd000014c - NTSTATUS Error]
2026-11-02 15:38:14, Info   CBS  Failed to load offline registry: {bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SECURITY [HRESULT = 0xd000014c - NTSTATUS Error]
2026-11-02 15:38:14, Info   CBS  Failed to load offline SECURITY hive. [HRESULT = 0xd000014c - NTSTATUS Error]
2026-11-02 15:38:14, Info   CBS  Force unloading offline registry hive: {bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SOFTWARE
2026-11-02 15:38:14, Info   CBS  Force unloading offline registry hive: {bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SYSTEM
2026-11-02 15:38:14, Error  CBS  Failed to load offline store from boot directory: '\\?\C:\' and windows directory: '\\?\C:\Windows\' [HRESULT = 0xd000014c - NTSTATUS Error]
```

There it was in plain sight: when the Component-Based Servicing (CBS) stack initializes an offline image, it mounts `SOFTWARE`, `SYSTEM`, and `SECURITY` in sequence. `SOFTWARE` and `SYSTEM` mounted fine; the failure was on **`SECURITY`**, which threw `HRESULT = 0xd000014c` (the HRESULT wrapper for NTSTATUS `0xC000014C`, `STATUS_REGISTRY_CORRUPT`). As soon as `SECURITY` failed to mount, CBS force-unloaded `SOFTWARE` and `SYSTEM` and aborted the session.

That was also when I connected a detail I had glossed over earlier: when I first booted into WinPE and looked at `C:`, the 150 GB partition had **barely 100+ MB of free space left**. I had deleted several gigs of non-essential files off my roommate's desktop right away, which is why `chkdsk` and `dir` later showed around 8.9 GB free.

Putting "100 MB free on `C:`" together with "`SECURITY` hive corruption" gave a very plausible theory: Windows Update had been unpacking an update in the background when `C:` hit zero free space, causing a registry write to `SECURITY` to fail mid-flight.

At that point, I came up with what seemed like a clever shortcut: since `SYSTEM` and `SOFTWARE` were healthy and only `SECURITY` was blocking DISM and boot, what if I backed up the broken `SECURITY` hive into `CorruptBak\SECURITY`, copied over a clean `SECURITY` hive from my own Windows 11 laptop, pointed DISM at `D:\backup` for scratch space, and ran `RevertPendingActions`?

I created `CorruptBak`, moved the original `SECURITY` hive into it, dropped in the `SECURITY` file from my own PC, and re-ran DISM:

```cmd
X:\Windows\System32>md D:\backup
X:\Windows\System32>cd C:\Windows\System32\config
X:\Windows\System32\config>md CorruptBak
X:\Windows\System32\config>move SECURITY CorruptBak\SECURITY
        1 file(s) moved.

X:\Windows\System32\config>dism /Image:C:\ /ScratchDir:D:\backup /Cleanup-Image /RevertPendingActions
Deployment Image Servicing and Management tool
Version: 10.0.22621.1

Image Version: 10.0.22631.5768

Reverting pending actions from the image...
The operation completed. Revert of pending actions will be attempted after the reboot.
The operation completed successfully.

X:\Windows\System32\config>if exist C:\Windows\WinSxS\pending.xml del /f /q C:\Windows\WinSxS\pending.xml
X:\Windows\System32\config>chkdsk C: /f
```

When `The operation completed successfully` printed on screen and DISM++ opened the image without complaints, I thought I had won. I deleted any leftover `WinSxS\pending.xml`, ran `chkdsk C: /f`, and rebooted.

It still refused to boot, landing right back on the `0xc0000001` Recovery screen.

When I asked the chatbot what else could be broken, it suggested overwriting `SAM` and `COMPONENTS` with copies from a Windows 11 ISO and checking `C:\Windows\System32\drivers\*.sys` for zero-byte drivers. I stopped right there: overwriting `SAM` with a blank template from an ISO would wipe out all local user accounts on my roommate's machine. Blindly swapping files was a dead end. It was time to bring in a proper coding agent that could inspect the binary hive structures directly inside WinPE.

---

## Deep Dive with an AI Agent

I rebooted the laptop into FirPE (a WinPE build with networking support), connected to Wi-Fi, set up `oh-my-pi` (`omp`), and mounted the official `D:\Win11_23H2_Chinese_Simplified_x64v2.iso` image read-only so the agent could audit every hive, log, crash dump, and driver against a known-good baseline.

### Pinpointing the Culprit from Logs and Crash Dumps

The agent started by pulling the historical servicing logs in `C:\Windows\Logs\CBS\CBS.log` and the kernel minidump in `C:\Windows\Minidump\`.

In `CBS.log`, eight days before the crash on **October 23**, CBS had logged three consecutive zero-disk-space warnings:

```cmd
2026-10-23 18:36:21, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:23, Info  CBS  System volume has 0G free disk space
2026-10-23 18:36:25, Info  CBS  System volume has 0G free disk space
```

Right below those three lines was `Maint: incomplete, interruptions: 1`. That proved the 150 GB `C:` volume had genuinely hit 0 bytes free during background servicing in late October. The machine limped along for another week until its last successful boot at `09:32:11 UTC` (17:32 local time) on November 1.

Next, the agent parsed all 2,052 lines (1,974 timestamped entries) of `C:\Windows\System32\Logfiles\Srt\DISMRepairLogFile.txt`, spanning November 1 at 17:35 to November 2 at 15:21. Extracting every offline hive load failure across all 13 repair sessions produced a crystal-clear timeline:

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

That table immediately explained the red herring that had fooled us earlier. The first 12 sessions across nearly 22 hours all failed on `SECURITY` with `0xd000014c` (`STATUS_REGISTRY_CORRUPT`). Only the 13th entry at `15:21:12` on November 2 failed on `SYSTEM` with `0xd0000043`.

And what is `0xC0000043`? It is `STATUS_SHARING_VIOLATION`. At `15:21`, I had just run `reg load HKLM\TEMP C:\Windows\System32\config\SYSTEM` from the command prompt to test `SYSTEM` and **forgot to run `reg unload HKLM\TEMP`** (or had DISM++ holding the hive open) before Startup Repair ran! Because `HKLM\TEMP` still held an exclusive file lock on `SYSTEM`, CBS couldn't open it and logged `0xd0000043`. The `SYSTEM` failure was 100% self-inflicted during troubleshooting; `SYSTEM` itself was never corrupt.

Next, the agent inspected the sole kernel crash dump on disk, `C:\Windows\Minidump\110226-9312-01.dmp` (6,662,433 bytes):

```cmd
signature   = PAGE / DU64
major/minor = 15.22621
bugcheck    = 0x74  (BAD_SYSTEM_CONFIG_INFO)
P1 = 0x2
P2 = 0xffff94869fbd2940
P3 = 0x1
P4 = 0xffffffffc000014c
Crash time   = 2026-11-02 07:36:19 UTC (15:36:19 local time)
ASCII bytes  = "HiveLoadFromomFile" + "status"
UTF-16 bytes = "<SECURITY"
```

The minidump confirmed the exact same story: BugCheck `0x74` (`BAD_SYSTEM_CONFIG_INFO`), Parameter 4 `0xffffffffc000014c` (`STATUS_REGISTRY_CORRUPT`), and the embedded kernel strings `HiveLoadFromomFile` (the doubled `om` is a real quirk in the kernel binary's string concatenation) plus `<SECURITY`. During boot initialization, `ntoskrnl.exe` tried to load the `SECURITY` hive, got `STATUS_REGISTRY_CORRUPT`, and bugchecked with `0x74`.

### Why Dropping In My Own SECURITY Hive Still Failed to Boot

If `SECURITY` was the only broken hive, why did copying over a clean `SECURITY` hive from my own PC fix DISM yet still fail to boot with `0xc0000001`?

The agent wrote an identity-check script (`_fix/scripts/id_check.cmd`) and parsed the binary contents of the replacement `SECURITY` hive sitting on `C:` (sequence number `210/210`) alongside my roommate's `SAM`, `SYSTEM`, and `SOFTWARE` hives:

```cmd
[Foreign SECURITY hive (copied from my laptop)]
PolAcDmN (Computer Name)      = HXCN-WIN
PolAcDmS (Machine Domain SID) = S-1-5-21-1262172508-...
Policy\Secrets                = NL$KM, M$_MSV1_0_TBAL_PRIMARY_{22BE8E5B-...}, DefaultPassword, MouseWithoutBorders
                                (Missing the local machine's DPAPI_SYSTEM master secret!)

[Roommate's native SAM & SYSTEM hives]
ComputerName                  = LAPTOP-VQSR6OMV
SAM Machine Domain SID        = S-1-5-21-4291209427-303460211-4247354471
ProfileList User SID          = S-1-5-21-4291209427-303460211-4247354471-1001 -> C:\Users\admin
```

That comparison made the problem obvious: **a registry hive being structurally valid is completely different from it belonging to this machine.**

When DISM opens an offline image, it only checks that the `SECURITY` file has a valid `regf` header and intact `hbin` cells. My laptop's `SECURITY` hive (`HXCN-WIN`, sequence `210/210`) was structurally clean, so DISM mounted it without complaint.

During an actual Windows boot, however, the Local Security Authority (`lsass.exe` / LSA) cross-checks the machine domain SID in `SECURITY\Policy\PolAcDmS` against the domain SID in `SAM\SAM\Domains\Account`. My hive had `S-1-5-21-1262172508-...`, while my roommate's `SAM` had `S-1-5-21-4291209427-303460211-4247354471`. Seeing a domain SID mismatch between `SECURITY` and `SAM`, LSA aborted initialization during boot and threw `0xc0000001`.

Even worse, `SECURITY\Policy\Secrets` holds the machine-specific `DPAPI_SYSTEM` master key. Everything protected by Windows DPAPI on the system (saved browser passwords in Chrome and Edge, Wi-Fi credentials, Credential Manager entries, and EFS certificates) requires the original `DPAPI_SYSTEM` secret combined with the `Lsa` boot key (SYSKEY) in `SYSTEM`. Booting with a foreign or blank `SECURITY` hive would permanently orphan all DPAPI-encrypted data on the laptop.

Fortunately, my roommate's real, original `SECURITY` hive was still sitting safely in `C:\Windows\System32\config\CorruptBak\SECURITY` where I had moved it earlier. The only real fix was to repair that original file.

### Sequence Numbers 17965 and 17964: The Two-Byte Dirty Flag

The agent inspected the raw bytes of `CorruptBak\SECURITY` (65,536 bytes, SHA-256 `7590396173dc6ff07a847e59c662570edc2757c19e0b6459a8f06681a55fde67`) according to the Windows NT registry hive specification.

Every registry hive file starts with a 4,096-byte base block (`0x000` to `0xFFF`, signature `"regf"`), followed by 4 KB-aligned hive bins (`hbin` blocks starting at `0x1000`) containing key nodes (`nk`), value nodes (`vk`), subkey index lists (`li`/`lf`/`lh`/`ri`), and security descriptors (`sk`). The critical header fields are:

```cmd
Offset 0x000 (4 B) : "regf"                Signature (0x66676572)
Offset 0x004 (4 B) : PrimarySeq (seq1)     Primary sequence number
Offset 0x008 (4 B) : SecondarySeq (seq2)   Secondary sequence number
Offset 0x00C (8 B) : LastWriteTime         Last write timestamp (FILETIME)
Offset 0x01C (4 B) : Type                  Hive type (0 = primary hive file)
Offset 0x024 (4 B) : RootCellOffset        Offset of root nk cell within hbins (0x20)
Offset 0x028 (4 B) : HiveBinsDataSize      Total byte size of the hbins region (49,152 B)
Offset 0x1FC (4 B) : Checksum              XOR checksum of the first 126 DWORDs (0x000..0x1F8)
```

To guarantee transactional consistency during writes, the Windows kernel uses `seq1` and `seq2` as a two-phase commit marker: before flushing dirty `hbin` pages to the main hive file, the kernel increments `seq1` at `0x004` and updates the header checksum; once all data blocks hit the disk, it increments `seq2` at `0x008` to match `seq1` and recalculates the checksum. If a write transaction is interrupted by power loss, a crash, or a full disk before that final header flush completes, the file is left with `seq1 != seq2`, which serves as the hive's **dirty flag**.

Reading the headers of `CorruptBak\SECURITY` and its companion transaction logs `.LOG1` and `.LOG2` revealed the exact state:

```cmd
CorruptBak\SECURITY   65,536 B   seq1 = 17965 (0x0000462d), seq2 = 17964 (0x0000462c)   Checksum = 0xb3d51b08 (valid)
SECURITY.LOG1         49,152 B   seq  = 208 / 208                                       (stale log from 2022)
SECURITY.LOG2          8,192 B   seq  = 17963 / 17963                                   (2 transactions behind the hive)
```

Was any of the actual key/value data inside `CorruptBak\SECURITY` truncated or corrupted when `C:` ran out of space? The agent ran a four-layer structural walk across the entire 65,536-byte file:

1. **Header and `hbin` chain integrity**: `HiveBinsDataSize` was 49,152 bytes (`0x1000` to `0xD000`, ending at byte 53,248), followed by 12,288 bytes of zero-filled slack space up to 65,536 bytes. Every `hbin` header signature and size was valid.
2. **Full tree traversal**: Starting from the root key cell at `0x20`, the parser walked **166 key nodes (`nk`)**, **164 value nodes (`vk`)**, **33 subkey index lists (all valid `lh` hash lists)**, and **2 security descriptor cells (`sk`)**. All 165 non-root parent pointers matched their parent keys, the highest reachable cell ended at offset `45,056` (well inside the `53,248` boundary), zero pointers were out of bounds, and there were **0 allocated-but-unreachable orphan cells**.
3. **Machine identity and secrets verification**: Every machine-specific value inside `CorruptBak\SECURITY` matched my roommate's `SYSTEM` and `SAM` hives:

```cmd
PolAcDmN (Computer Name)      = LAPTOP-VQSR6OMV                        (matches SYSTEM\ComputerName)
PolAcDmS (Machine Domain SID) = S-1-5-21-4291209427-303460211-4247354471 (matches SAM domain SID)
Policy\Secrets                = 8 secrets intact, including DPAPI_SYSTEM, RasDialParams!S-1-5-21-...-1001#0, and 6 MSSQL/SQL service secrets
Root nk LastWriteTime         = 2026-11-01 09:32:10 UTC                (1 second before SrtTrail's last good boot 09:32:11 GMT)
```

> Note: `SECURITY\Policy\Accounts` contained RIDs `-501`, `-1002`, and `-1003` without `-1001` (even though `SAM` has the `admin` user at RID `1001`). That is completely normal: LSA only creates an `Accounts` entry for a SID when special LSA privileges or system access rights are explicitly assigned to it.

That settled the root cause beyond a shadow of a doubt: **not a single byte of data inside my roommate's original `SECURITY` hive was corrupted.** The `hbin` blocks had already been written to disk at `09:32:10 UTC` on November 1, right before the secondary sequence number `seq2` (`17964`) could be bumped to match `seq1` (`17965`). When the kernel tried to mount `SECURITY` on the next boot, it saw `seq1 != seq2` and attempted to replay `.LOG1` or `.LOG2` to reconcile the dirty hive. Because `SECURITY.LOG1` was stuck at sequence `208` from 2022 and `SECURITY.LOG2` was at `17963` (behind `17964`), neither log could be replayed, forcing the kernel to return `0xC000014C` (`STATUS_REGISTRY_CORRUPT`) and crash with `0x74`.

To prove how the Windows kernel handles dirty flags and transaction logs, we built a 10-case controlled experiment matrix in `D:\_fix\experiments\` (`mx4` through `mx8`, driven by `_fix/scripts/matrix.cmd` through `matrix_aj.cmd`) using copies of the hive without touching `C:`:

```cmd
@echo off
chcp 936 >nul
echo == s1: DIRTY, no log files ==
reg load HKLM\KS1 D:\_fix\mx6\s1_dirty_nolog >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KS1 >nul 2>&1)

echo == s2: DIRTY, zero-length LOG1/LOG2 ==
reg load HKLM\KS2 D:\_fix\mx6\s2_dirty_zerolog >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KS2 >nul 2>&1)

echo == s3: DIRTY + stale LOG1(208)/LOG2(17963) ==
reg load HKLM\KS3 D:\_fix\mx6\s3_dirty_stalelog >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KS3 >nul 2>&1)

echo == s4: CLEAN but wrong header checksum ==
reg load HKLM\KS4 D:\_fix\mx6\s4_clean_badcsum >nul 2>&1
if errorlevel 1 (echo   RESULT=FAIL) else (echo   RESULT=OK& reg unload HKLM\KS4 >nul 2>&1)
```

Here are the results across all test cases:

| Case ID | Hive Sequence State (`seq1 / seq2`) | Header `0x1FC` Checksum | Companion `.LOG1` / `.LOG2` State | `reg load` Result | Takeaway |
|---|---|---|---|---|---|
| `s1` / `g` | Dirty (`17965 / 17964`) | Valid (`0xb3d51b08`) | No log files | **FAIL** | Without replayable logs, `seq1 != seq2` is an unconditional hard failure |
| `s2` | Dirty (`17965 / 17964`) | Valid (`0xb3d51b08`) | 0-byte empty `.LOG1` / `.LOG2` | **FAIL** | Empty logs cannot heal a dirty hive |
| `s3` / `a` | Dirty (`17965 / 17964`) | Valid (`0xb3d51b08`) | Original stale logs (`208` + `17963`) | **FAIL** | Exact reproduction of the boot BSOD and DISM `0xd000014c` |
| `h` | Dirty (`17965 / 17964`) | Valid (`0xb3d51b08`) | Only `LOG2` (`17963`) present | **FAIL** | A log 2 transactions behind cannot be replayed |
| `t1` | Dirty (`17965 / 17963`) | Recalculated (valid) | No log files | **FAIL** | Any `seq1 != seq2` mismatch is rejected |
| `t2` | Clean (`17964 / 17964`, `seq1` lowered) | Recalculated (valid) | No log files | **OK** | Matching sequence numbers + valid checksum mounts cleanly |
| `i` | Clean (`17965 / 17965`, `seq2` bumped) | Recalculated (`0xb3d51b09`) | No log files | **OK** | Patching just 2 fields restores the hive with zero data loss |
| `j` | Clean (`17965 / 17965`, `seq2` bumped) | Recalculated (`0xb3d51b09`) | Original stale logs (`208` + `17963`) kept | **OK** | When the primary hive is clean (`seq1 == seq2`), stale logs are ignored |
| `s4` | Clean (`17965 / 17965`) | **Unchanged (`0xb3d51b08`, invalid)** | No log files | **FAIL** | Both `seq1 == seq2` AND a valid header XOR checksum are required |

The rules enforced by the kernel registry loader are strict and predictable:

1. **Whenever `seq1 != seq2` and no matching transaction log can be replayed, the hive is rejected outright.**
2. **Setting `seq2 = seq1` (`17964` -> `17965`) at offset `0x008` and recalculating the header XOR checksum at offset `0x1FC` (`0xb3d51b08` -> `0xb3d51b09`) makes the hive mount cleanly, even if the stale `.LOG` files remain in the directory.**
3. Because `17964` (`0x0000462c`) and `17965` (`0x0000462d`) differ in only one byte, and the XOR checksum also changes in only one byte, **the entire fix touches just 2 bytes out of 65,536.**

### Uncovering the Dirty BBI Hive and the Orphaned Driver

Rather than rebooting immediately after diagnosing `SECURITY`, we ran a full suite of audit scripts (`_fix/scripts/verify_final.cmd`, `audit_bootdrv.cmd`, `audit_thirdparty.cmd`, `audit_filters.cmd`, and `cbs_pending.cmd`) across all nine registry hives, all boot-start drivers, and storage filter drivers.

That sweep uncovered two additional issues:

**First, the `BBI` hive was also dirty and unmountable.**

While `SYSTEM`, `SOFTWARE`, `SAM`, `DEFAULT`, `DRIVERS`, `COMPONENTS`, and `ELAM` all had `seq1 == seq2` and mounted cleanly, the 1,310,720-byte (1.25 MB) **`BBI`** hive failed `reg load`:

```cmd
File     : C:\Windows\System32\config\BBI (1,310,720 B)
Sequence : seq1 = 53232, seq2 = 53231  [DIRTY]
Logs     : BBI.LOG1 = 0 B, BBI.LOG2 = 0 B
Contents : 1,652 keys / 10,129 values (81 WorkItems, 1,431 PackageImportance entries, 136 Events)
```

`BBI` belongs to the Windows Background Broker Infrastructure (mounted under `\Registry\A\...`), which tracks background work items and package importance queues. Its timestamp showed it had been sitting in a dirty `53232 / 53231` state with 0-byte log files since October 31 at 21:18. While a dirty `BBI` hive does not cause a `0x74` boot crash on its own (the machine had booted on November 1 despite `BBI` being dirty), it was the only other unmountable hive on the disk and needed the exact same two-byte header fix.

**Second, an orphaned kernel boot driver (`softaal`) in `SYSTEM` pointed to a deleted file.**

To make sure the machine wouldn't hit a `0x7B INACCESSIBLE_BOOT_DEVICE` crash after the registry was fixed, `_fix/scripts/audit_bootdrv.cmd` and `audit_tp2.cmd` scanned every kernel driver service in `HKLM\SYSTEM\ControlSet001\Services` with `Start = 0` (`SERVICE_BOOT_START`) or `Start = 1` (`SERVICE_SYSTEM_START`) and verified that its `.sys` binary existed on `C:`:

```cmd
@echo off
setlocal enabledelayedexpansion
chcp 936 >nul
reg load HKLM\VFSYS C:\Windows\System32\config\SYSTEM >nul 2>&1
for /f "tokens=*" %%K in ('reg query HKLM\VFSYS\ControlSet001\Services 2^>nul') do (
  set "SVC=%%K"
  set "ST="
  for /f "tokens=3" %%V in ('reg query "!SVC!" /v Start 2^>nul ^| findstr /i "REG_DWORD"') do set "ST=%%V"
  if defined ST (
    if "!ST!"=="0x0" call :check "!SVC!"
    if "!ST!"=="0x1" call :check "!SVC!"
  )
)
```

Out of 138 boot/system-start drivers, 6 built-in virtual drivers (`wof`, `null`, `npfs`, `msfs`, `cimfs`, and `beep`) normally omit `ImagePath` (verified against the Windows 11 ISO baseline), and 131 drivers had intact `.sys` binaries on disk. One third-party `Start = 1` driver, **`softaal`**, pointed to a file that no longer existed:

```cmd
HKLM\SYSTEM\ControlSet001\Services\softaal
  Type         = 0x1  (SERVICE_KERNEL_DRIVER)
  Start        = 0x1  (SERVICE_SYSTEM_START)
  ErrorControl = 0x0  (SERVICE_ERROR_IGNORE)
  ImagePath    = \??\C:\Program Files (x86)\Tencent\QQPCMgr\15.1.22354.301\softaal64_ev.sys
```

Inspecting `C:\Program Files (x86)\Tencent\QQPCMgr\` showed that Tencent PC Manager had updated itself to `15.6.23169.211` and deleted the old `15.1.22354.301` folder, leaving the `softaal` service pointing to a dead path. Because `ErrorControl` was `0` (`SERVICE_ERROR_IGNORE`), the missing `.sys` file didn't trigger a BSOD, but leaving a `Start = 1` kernel driver pointing to a deleted directory on every boot is sloppy. Changing `softaal` to `Start = 4` (`SERVICE_DISABLED`) cleanly disables it.

Our third-party driver audit also noted four non-boot (`Start >= 2`) services with missing files (`ksapi64` at `Start = 2`, ASUS `ROGKB` and `ROGMS` at `Start = 3`, and Tencent `TSSKX64` at `Start = 3` where the registry asked for `tsskx64_EV.sys` while the file on disk was named `TSSKX64.sys`), plus a nearly empty `ControlSet002` containing only an old Kingsoft `Services\kisknl` entry (`Start = 2`). Because `Select\Current = 1` and all of those services have `Start >= 2`, none of them are loaded by the boot loader, so we left them untouched and documented them.

---

## The Fix

### Why the ISO's 9 MB SYSTEM Hive Can't Overwrite Yours (and Why You Still Need the ISO)

A natural question when troubleshooting registry corruption is: **if you have an official Windows 11 ISO (`Win11_23H2_Chinese_Simplified_x64v2.iso`), why can't you just extract the clean registry hives from `sources\install.wim` and copy them over `C:\Windows\System32\config\`? And if you can't overwrite your hives with them, why mount the ISO at all?**

Mounting `install.wim` (Index 1, Windows 11 Home Chinese Edition, build `10.0.22631.2861`) read-only to `D:\_fix\mount` via DISM and comparing its `Windows\System32\config\` directory against my roommate's machine (`10.0.22631.5768`) makes the answer obvious:

```cmd
md D:\_fix\mount
dism /Mount-Image /ImageFile:D:\Win11_23H2_Chinese_Simplified_x64v2.iso /Index:1 /MountDir:D:\_fix\mount /ReadOnly
```

| Registry Hive | Inside Official ISO (`22631.2861`) | Roommate's Laptop (`22631.5768`) | Result of Overwriting Local Hive with ISO Hive |
|---|---|---|---|
| `SYSTEM` | **9,175,040 B (9.17 MB)** / 661 services / `MINWINPC` | **32,243,712 B (30.8 MB)** / 846 services / `LAPTOP-VQSR6OMV` | Loses all hardware driver bindings, NVMe/VMD storage controllers, and the `Enum` device tree -> instant `INACCESSIBLE_BOOT_DEVICE` |
| `SAM` | **8,192 B (8 KB empty template)** | **131,072 B (128 KB)** / 5 user accounts (incl. `admin`) | Wipes out all local user accounts, RIDs, and password hashes |
| `SECURITY` | **8,192 B (8 KB empty template)** | **65,536 B (64 KB)** / 166 keys / 8 LSA secrets | Loses machine domain SID and `DPAPI_SYSTEM` master secret -> LSA boot failure and permanent loss of encrypted credentials |
| `SOFTWARE` | **66,584,576 B (63.5 MB)** | **117,440,512 B (112.0 MB)** / 372,888 keys | Loses all installed application registrations, COM classes, and `ProfileList` user profile mappings |
| `DEFAULT` | **32,768 B (32 KB)** | **6,029,312 B (5.75 MB)** | Loses default user profile configuration |
| `BBI` | **8,192 B (8 KB empty queue)**, identical GUID | **1,310,720 B (1.25 MB)** / 81 `WorkItems` | **The only hive safe to replace directly** (merely clears background broker queues without affecting boot) |

The hives inside `install.wim` are unspecialized pre-OOBE templates. Overwriting a 30.8 MB machine-specific `SYSTEM` hive with a 9.17 MB generic `MINWINPC` template strips away the machine's entire hardware configuration. Nor could this ISO be used for an in-place upgrade repair, because the ISO build (`22631.2861`) is older than the installed OS (`22631.5768`), and Windows Setup blocks downgrades while preserving apps.

So why mount the ISO? Because it is an invaluable **read-only reference baseline** and **component source**:

1. Comparing against the ISO's `SYSTEM` hive confirmed that the 6 boot services without an `ImagePath` (`wof`, `null`, `npfs`, `msfs`, `cimfs`, `beep`) are supposed to look like that, preventing false-positive edits.
2. Comparing storage class filters (`UpperFilters` / `LowerFilters`) and `Session Manager` values against the ISO verified that `partmgr`, `volsnap`, `fvevol`, `iorate`, `rdyboost`, and `BootExecute = autocheck autochk *` were clean and unmodified.
3. If `BBI` had been genuinely damaged beyond repair, the ISO's 8 KB `BBI` template (which shares the exact same hive GUID `{a2332f2f-cdbf-11ec-8680-002248483d79}`) was verified to mount cleanly even alongside the existing `BBI{...}.TM.blf` transaction containers.

### Full Backup, Two-Byte Patch, and Stale Log Quarantine

Before modifying a single byte on `C:`, we made a complete byte-for-byte backup of `C:\Windows\System32\config\` (all 43 files, including the 9 hives, `BCD-Template`, and every `.LOG1`, `.LOG2`, `.TM.blf`, and `.regtrans-ms` file, totaling `249,708,544` bytes / `238.1 MB`) into `D:\_fix\backup_20261102120607\config\` (and archived to `_fix/hives/pre_repair_full/`). We verified the SHA-256 hash of every copied file against the source (`_fix/MANIFEST.md`) so we could roll back 100% cleanly if needed.

With the backup verified, we executed the four core repairs:

**1. Patching the dirty flag and checksum on the original `SECURITY` hive (2 bytes changed)**

Starting from `C:\Windows\System32\config\CorruptBak\SECURITY` (65,536 bytes), we updated two 32-bit little-endian header fields on a staged copy:

- At offset `0x008` (`SecondarySeq`), we changed `17964` (`2c 46 00 00`) to **`17965`** (`2d 46 00 00`) to match `PrimarySeq` at `0x004`, clearing the dirty flag;
- We recomputed the XOR checksum across the first 126 DWORDs (`0x000`..`0x1F8`) and updated offset `0x1FC` (`Checksum`) from `0xb3d51b08` (`08 1b d5 b3`) to **`0xb3d51b09`** (`09 1b d5 b3`).

```python
import struct

with open("SECURITY", "rb") as f:
    buf = bytearray(f.read())

seq1 = struct.unpack_from("<I", buf, 0x004)[0]  # 17965 (0x0000462d)
struct.pack_into("<I", buf, 0x008, seq1)        # seq2 := seq1 (17964 -> 17965)

xor_sum = 0
for offset in range(0, 0x1F8, 4):
    xor_sum ^= struct.unpack_from("<I", buf, offset)[0]
if xor_sum == 0xFFFFFFFF:
    xor_sum = 0xFFFFFFFE
elif xor_sum == 0:
    xor_sum = 1

struct.pack_into("<I", buf, 0x1FC, xor_sum)     # 0xb3d51b08 -> 0xb3d51b09

with open("SECURITY_patched", "wb") as f:
    f.write(buf)
```

We tested the patched hive in staging with `reg load`, verified that all 166 keys, 164 values, `PolAcDmS` (`S-1-5-21-4291209427-303460211-4247354471`), `PolAcDmN` (`LAPTOP-VQSR6OMV`), and `Policy\Secrets\DPAPI_SYSTEM` were intact, and then wrote the patched file back to `C:\Windows\System32\config\SECURITY`, replacing the foreign hive from my laptop.

**2. Quarantining the stale `SECURITY.LOG1` and `SECURITY.LOG2` files**

Even though test case `j` proved that the kernel ignores stale logs when the main hive is clean, we moved `C:\Windows\System32\config\SECURITY.LOG1` (49,152 B, sequence `208`) and `SECURITY.LOG2` (8,192 B, sequence `17963`) into `D:\_fix\quarantine\` so no tool could ever trip over them. On the next mount, the kernel generated a fresh `SECURITY.LOG1` (36,864 B) on `C:`.

**3. Patching the dirty flag on `BBI` (2 bytes changed)**

We applied the exact same two-field patch to `C:\Windows\System32\config\BBI` (1,310,720 bytes):

- Set `seq2` at `0x008` from `53231` to **`53232`** to match `seq1`;
- Recomputed and updated the header XOR checksum at `0x1FC`.

Running `reg load HKLM\VFBBI C:\Windows\System32\config\BBI` succeeded immediately, preserving all 81 `WorkItems`, 1,431 `PackageImportance` entries, and 136 `Events`.

**4. Disabling the orphaned `softaal` boot driver**

We mounted `SYSTEM`, changed `ControlSet001\Services\softaal` from `Start = 1` to `Start = 4` (`SERVICE_DISABLED`), verified the value, and immediately unloaded `SYSTEM`:

```cmd
reg load HKLM\VFSYS C:\Windows\System32\config\SYSTEM
reg add "HKLM\VFSYS\ControlSet001\Services\softaal" /v Start /t REG_DWORD /d 4 /f
reg query "HKLM\VFSYS\ControlSet001\Services\softaal"
reg unload HKLM\VFSYS
```

### Clearing the Hibernation File and Update Leftovers

Next, we had to fix the low-disk-space condition on `C:` that caused the disaster in the first place.

Two major space hogs stood out on the root of `C:`:

First was **`C:\hiberfil.sys` (6,715,396,096 bytes / 6.25 GiB)**. Inspecting the first 4 KB of `hiberfil.sys` showed all zeroes (`0x00`), meaning the hibernation header was already blank and `winresume.efi` had nothing to resume from, while four `resumeobject` entries in BCD still pointed to it. Deleting `C:\hiberfil.sys` via `del /f /q /a C:\hiberfil.sys` immediately freed 6.25 GiB (`HiberbootEnabled` was already `0`).

Second were four leftover setup and update staging folders. Before touching them, we ran `_fix/scripts/verify_setup.cmd` and `cbs_pending.cmd` to confirm no setup or servicing operation was actually in progress:

```cmd
==== Setup state ====
HKEY_LOCAL_MACHINE\VFSYS\ControlSet001\Control\Session Manager
    SetupType              REG_DWORD    0x0
    SystemSetupInProgress  REG_DWORD    0x0
    BootExecute            REG_MULTI_SZ autocheck autochk *

==== CbsTemp / pending ====
no pending.xml
0
```

After confirming `SetupType = 0`, `SystemSetupInProgress = 0`, no `PendingFileRenameOperations`, no `WinSxS\pending.xml`, and empty `PackagesPending` / `RebootPending` keys in `COMPONENTS`, we removed:

- `C:\$WinREAgent` (1,771 MB)
- `C:\Windows\SoftwareDistribution\Download` (65.5 MB)
- `C:\$Windows.~BT` (56.7 MB)
- `C:\$SysReset` (0.3 MB)

We also unmounted and cleaned up the read-only ISO mount at `D:\_fix\mount`:

```cmd
dism /Unmount-Image /MountDir:D:\_fix\mount /Discard
dism /Cleanup-Mountpoints
```

Used space on `C:` dropped from 135.2 GB to 127.6 GB, and **free space jumped from 8.9 GB to 16.5 GB**.

### Post-Repair Verification

Before rebooting, we ran our verification scripts (`_fix/scripts/verify_final.cmd`, `id_check.cmd`, `final_check.cmd`) and re-ran the offline DISM commands that had failed 12 times in a row earlier (`_fix/logs/getpkgs.txt` and `scanhealth.txt`):

```cmd
X:\Windows\System32>dism /Image:C:\ /Cleanup-Image /ScanHealth

Deployment Image Servicing and Management tool
Version: 10.0.22621.1

Image Version: 10.0.22631.5768

[==========================100.0%==========================]
No component store corruption detected.
The operation completed successfully.

X:\Windows\System32>dism /Image:C:\ /Get-Packages /Format:Table
...
Package Identity : Package_for_RollupFix~31bf3856ad364e35~amd64~~22621.5768.1.15
State : Installed
Release Type : Security Update
Install Time : 2025/8/15 14:10

Package Identity : Package_for_ServicingStack_5690~31bf3856ad364e35~amd64~~22621.5690.1.2
State : Installed
Release Type : Update
Install Time : 2025/8/15 0:37

The operation completed successfully.
```

Both commands succeeded with exit code `0`. DISM loaded `SOFTWARE`, `SYSTEM`, and `SECURITY` cleanly, enumerated all **83 installed packages** (all in the `Installed` state, zero pending), and reported `No component store corruption detected`.

We then ran a second four-layer structural walk across all nine hives on `C:` (checking `regf` headers, sequence numbers, XOR checksums, `hbin` chains, parent/subkey/value pointers, and orphan cells):

| Hive | Size (Bytes) | Post-Audit Sequence (`seq1 / seq2`) | Dirty | Header Checksum | Keys (`nk`) | Values (`vk`) | Parent / Subkey / Value / hbin Errors |
|---|---|---|---|---|---|---|---|
| `SYSTEM` | 32,243,712 | `395834 / 395834` | No | OK | 91,391 | 194,730 | 0 / 0 / 0 / 0 |
| `SOFTWARE` | 117,440,512 | `937587 / 937587` | No | OK | 372,888 | 640,232 | 0 / 0 / 0 / 0 |
| `SAM` | 131,072 | `3911 / 3911` | No | OK | 80 | 100 | 0 / 0 / 0 / 0 |
| `SECURITY` | 65,536 | `17970 / 17970` | No | OK (`0xb3d11b0b`) | 166 | 164 | 0 / 0 / 0 / 0 |
| `DEFAULT` | 6,029,312 | `238433 / 238433` | No | OK | 8,201 | 10,937 | 0 / 0 / 0 / 0 |
| `DRIVERS` | 8,777,728 | `4850 / 4850` | No | OK | 36,424 | 52,954 | 0 / 0 / 0 / 0 |
| `COMPONENTS` | 32,768,000 | `9216 / 9216` | No | OK | 61,793 | 197,776 | 0 / 0 / 0 / 0 |
| `ELAM` | 32,768 | `13 / 13` | No | OK | 1 | 0 | 0 / 0 / 0 / 0 |
| `BBI` | 1,310,720 | `53233 / 53233` | No | OK | 1,652 | 10,129 | 0 / 0 / 0 / 0 |

Why did `SECURITY` advance from `17965 / 17965` to `17970 / 17970` during our verification passes? Because in Windows, even a read-only `reg load` followed by `reg unload` increments the hive's sequence number and updates volatile state bits on unmount. A byte-by-byte diff between the final `17970 / 17970` `SECURITY` file and the original `CorruptBak\SECURITY` showed 182 changed bytes across the entire 65,536-byte file: 10 header bytes plus 172 bytes in the `hbin` region, consisting solely of the root `nk` cell's `Parent` (1 B), `VolatileSubKeyCount` (1 B), and `VolatileSubKeyList` (4 B), plus the 1-byte `AccessBits` field on each of the 166 `nk` cells (`0x1 -> 0x3` or `0x0 -> 0x2`, set when the kernel mounts a hive). All 166 key names and 164 value names and payloads had **zero differences**.

One fun detail came up during the orphan-cell scan on `SYSTEM`: the scanner initially flagged a 72-byte allocated cell at offset `0xd1a718` that started with the bytes `6e 6b` (ASCII `"nk"`) but wasn't reachable from the root key. Checking the `nk` cell specification showed why: the fixed header of a valid `nk` key node is `0x4C` (76 bytes) minimum, so a 72-byte cell cannot be an `nk` node. It was just a value data cell whose binary payload happened to begin with the bytes `6e 6b`.

Finally, `_fix/scripts/id_check.cmd` and `final_check.cmd` confirmed that identity, boot keys, and boot entries were all consistent:

```cmd
PolAcDmN (SECURITY)   = LAPTOP-VQSR6OMV
PolAcDmS (SECURITY)   = S-1-5-21-4291209427-303460211-4247354471
ProfileList (SOFTWARE)= S-1-5-21-4291209427-303460211-4247354471-1001 -> C:\Users\admin
SAM User Accounts     = admin (0x3E9) / Administrator (0x1F4) / Guest (0x1F5) / DefaultAccount (0x1F7) / WDAGUtilityAccount (0x1F8)
Lsa Boot Key (SYSTEM) = TC463EF4966D8796 (assembled from the Class attributes of JD, Skew1, GBG, and Data under ControlSet001\Control\Lsa)
Missing Boot Drivers  = 0 (all 131 Start 0/1 driver binaries present; softaal set to Start=4)
Storage Class Filters = Disk Upper: partmgr | Volume Upper: volsnap | Volume Lower: fvevol, iorate, rdyboost
Stale Mount Handles   = None
bcdedit {default}     = device partition=C:, path \Windows\system32\winload.efi
fsutil dirty query C: = Volume - C: is NOT Dirty
```

(If you ever inspect `ControlSet001\Control\Lsa\JD`, `Skew1`, `GBG`, and `Data` in Regedit and wonder why their values appear empty, that is by design: Windows stores the 16-byte SYSKEY across the **Class name metadata** of those four keys rather than in their value data.)

---

## Epilogue

### Cleaning Up InFlight Temp Directories and Booting Up

During our final disk-space audit, we noticed `C:\Windows\WinSxS\Temp\InFlight\`, which held **5,336 leftover directories** totaling **1,498.9 MB (1.5 GB)** dated between October 2023 and November 2, 2026, left behind by past servicing transactions.

Even more telling: the offline `DISM /ScanHealth` and `DISM /Get-Packages` commands we ran during our own verification had created **7,334 new temporary directories** (`1,393.4 MB`, listed in `_fix/logs/inflight_mine.txt`) inside `WinSxS\Temp\InFlight\`, pulling free space on `C:` down from 16.5 GB to 16.0 GB in under half an hour. We deleted the 7,334 temporary folders created by our own DISM runs (leaving the older 5,336 folders for online component cleanup), restoring free space on `C:` to **16.5 GB**. It was a vivid demonstration of why a small `C:` drive is so dangerous on Windows 11: even read-only servicing checks can chew through more than a gigabyte of scratch space on the system volume.

With all nine registry hives clean, zero mounted test handles left behind, and our scripts and hive backups archived to `F:\bakup\_fix\`, we unplugged the USB drive and hit the power button.

The ASUS logo spun once and went straight to the Windows 11 lock screen. No `BAD_SYSTEM_CONFIG_INFO`, no `0xc0000001`. My roommate logged in, and everything (his desktop files, MATLAB, SQL Server databases, and all DPAPI-encrypted browser passwords and sessions) worked as if nothing had happened. Patching two bytes in `SECURITY` and two bytes in `BBI` brought the entire system back without losing a single file.

### Pausing Windows Update for 1,000 Weeks via the Registry

While the cramped 150 GB `C:` partition set the stage for this failure, the trigger was Windows 11's relentless background automatic updates.

Yes, monthly cumulative updates carry security patches, but Microsoft's software quality control over the past year has been rough. Time after time, mandatory updates meant to fix bugs have introduced severe regressions of their own:

- **August 2025 updates (`KB5063878` / `KB5063875`)**: Users on Windows 11 24H2 reported SSDs with Phison and InnoGrit controllers dropping offline or suffering partition corruption during sustained large writes after installing `KB5063878`, alongside broken NDI streaming in OBS. That same month, `KB5063875` broke Windows Reset and Recovery operations outright, forcing Microsoft to ship an emergency out-of-band patch.
- **October 2025 update (`KB5066835`)**: This mandatory update broke `HTTP.sys` loopback connections on `localhost` (`127.0.0.1`) for developers, triggered false security warnings in the File Explorer preview pane, broke SmartCard authentication, and, most ironic of all, **broke USB keyboard and mouse input inside the Windows Recovery Environment (WinRE)**. Users who got dropped into WinRE couldn't even click "Advanced options" or use their keyboard to repair their PC until Microsoft pushed the emergency `KB5070773` out-of-band update.
- **January and February 2026 updates (`KB5074109` / `KB5077181`)**: The January 2026 update left a number of PCs stuck in `UNMOUNTABLE_BOOT_VOLUME` boot loops, froze classic Outlook (POP/PST profiles), broke cloud file saving, and prevented S3 sleep and shutdown on older hardware, requiring two emergency patches (`KB5077744` and `KB5078127`). Then February's `KB5077181` brought reports of boot loops, broken login screens, DHCP networking failures, and `dxgmms2.sys` `KERNEL_SECURITY_CHECK_FAILURE` blue screens.

When Microsoft treats production PCs like an unpaid QA ring, leaving automatic updates running unchecked on a laptop with tight disk space is asking for trouble.

On Windows 11 Home, the Settings UI only lets you pause updates for up to 5 weeks, and `gpedit.msc` is not included. Third-party tools that rip out the Windows Update service can break the Microsoft Store or driver installations later. A much cleaner approach is to set the `HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings` registry values to **extend the pause limit and pause updates until September 2042 (1,000 weeks)**. That stops background update downloads from filling up `C:` without breaking any system components.

To apply it, create a new `.txt` file on your desktop, paste the following content, rename the file to **`windows-1000weeks-update-blocker.reg`**, and double-click it to merge it into the registry:

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

Here `FlightSettingsMaxPauseDays` is set to `0x00001b58` (`7,000` days, or `1,000` weeks), and the six timestamp values lock both feature updates and quality updates in a paused state until `2042-09-05`. Once imported, opening **Settings -> Windows Update** will show updates paused through September 5, 2042.

Whenever you want to re-enable normal Windows Updates in the future, create another text file with the following contents, rename it to **`windows-1000weeks-update-blocker-recovery.reg`**, and double-click it to remove the pause keys and restore default behavior:

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
