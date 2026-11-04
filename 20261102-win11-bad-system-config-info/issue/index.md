> win11 反复蓝屏重启了bad system config info，有bitlocker，进入pe，dism＋＋提示试图加载格式不准确的格式。regback为0，出厂的bitlocker没有恢复码（给一下导出命令），dism加加尝试修复引导报错0xc0000001。没有微软账号登录，无法重构引导
> ![2ad236e1-14fc-44c7-9b35-89ec9b3fdd60](.\2ad236e1-14fc-44c7-9b35-89ec9b3fdd60.jpg)![51f4a0c6-f119-42e7-a02b-bbcc2bd0db64](.\51f4a0c6-f119-42e7-a02b-bbcc2bd0db64.jpg)![927452b9-65ab-4186-abde-05cd69fa996a](.\927452b9-65ab-4186-abde-05cd69fa996a.jpg)

从提供的终端画面与诊断信息来看，当前处于非常关键的状态：

1. **BitLocker 实际状态**：图中显示 C 盘为“**保护关闭，锁定状态：已解锁，密钥保护器：找不到**”。这是出厂设备加密处于预置启用（未激活/未绑定微软账户）的状态。因为保护已挂起/关闭且当前已解锁，**在 PE 下可以直接访问 C 盘读取所有个人文件**。由于没有生成过密钥保护器（密码/恢复密钥），无法使用命令导出不存在的恢复密钥。   
2. **核心故障根源**：蓝屏提示 `BAD_SYSTEM_CONFIG_INFO`，结合 DISM++ 提示“试图加载格式不准确的格式”，表明 **Windows 注册表核心配置单元（Hive 文件，如 `SYSTEM` 或 `SOFTWARE`）已严重损坏或变成 0 字节**。
3. **修复引导失败与扫描为 0**：引导其实已经成功创建（第一张图 `bcdboot C:\Windows /s S: /f UEFI` 已显示“已成功创建启动文件”）；而 `bootrec /scanos` 报 0 是因为在已存在 BCD 项或注册表 Hive 无法加载时常无法被视作有效安装。之后开机报 `0xc0000001`，本质上依然是底层注册表损坏导致 Windows 内核加载失败。   

### 第一步：立即备份重要数据（首要任务）

在 PE 中打开文件资源管理器，检查 `C:\Users\<你的用户名>`（包括桌面、文档、下载等）以及 D/E 盘，**立即插上移动硬盘或 U 盘，将所有重要个人资料全部复制备份**。

### 第二步：彻底关闭并解密 BitLocker（防止后续被意外锁死）

为了避免重启或后续操作中触发 TPM 重新锁定导致数据永久无法读取，在 PE 命令提示符中执行以下命令对驱动器进行完全解密：

DOS

```
manage-bde -off C:
manage-bde -off D:
manage-bde -off E:
```

*检验方式*：运行 `manage-bde -status C:` 查看进度，直到“转换状态”显示为**完全解密**。

### 第三步：检查与尝试修复注册表 Hive 文件

`BAD_SYSTEM_CONFIG_INFO` 导致系统无法启动，需要定位损坏的注册表文件：

1. 在命令提示符中运行文件检查与修复：

   DOS

   ```
   chkdsk C: /f /r
   ```

   *说明：若存在文件系统元数据损坏，此命令会自动尝试修复。*

2. 检查系统 Hive 文件的实际大小：

   DOS

   ```
   dir C:\Windows\System32\config
   ```

   观察其中的 `SYSTEM`、`SOFTWARE`、`SAM`、`SECURITY`、`DEFAULT`：

   - 如果大小为 **0 KB** 或异常小，说明对应注册表文件已经损坏。

3. **检查是否存在卷影副本（Shadow Copies）**：

   虽然 Windows 10/11 的 `RegBack` 默认已不再自动备份，但系统保护还原点中可能存有快照：

   DOS

   ```
   vssadmin list shadows
   ```

   - 如果有输出快照，可以使用影子副本提取出健康版本的 `SYSTEM` 文件替换回 `C:\Windows\System32\config\`。
   - 如果没有卷影副本且文件已损坏，由于注册表配置单元无法凭空生成，任何工具都无法无损恢复该 Windows 系统。

### 第四步：若注册表无法还原，执行保留数据/全新重装

由于你的所有个人文件当前都可以完整读取并已备份：

1. 使用微 PE 或 Ventoy U 盘内的 Windows 11 官方镜像文件。
2. 双击挂载 ISO，或直接使用安装工具（如 WinNTSetup）对 C 盘执行重装。
3. 重装完成后，将备份好的数据还原回新系统即可。

> 没有开还原点，执行chkdsk C: /f /r后重启依旧报错。使用manage-bde -off C:
>
> manage-bde -off D:
>
> manage-bde -off E:解除了bl。尝试重建uefi，注册表加载和自动修复依旧不行
>
> DISMRepairLogFile.txt
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1236 DismApi.dll:                      - DismInitializeInternal
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1236 DismApi.dll: <----- Starting DismApi.dll session -----> - DismInitializeInternal
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1236 DismApi.dll:                      - DismInitializeInternal
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1236 DismApi.dll: Host machine information: OS Version=10.0.22621, Running architecture=amd64, Number of processors=20 - DismInitializeInternal
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1236 DismApi.dll: API Version 10.0.22621.1 - DismInitializeInternal
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1236 DismApi.dll: Parent process command line: StartRep.exe - DismInitializeInternal
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1236 Input parameters: LogLevel: 2, LogFilePath: C:\Windows\System32\Logfiles\Srt\DISMRepairLogFile.txt, ScratchDirectory: (null) - DismInitializeInternal
>
> 2026-11-02 15:21:07, Info         DISM  Initialized Panther logging at C:\Windows\System32\Logfiles\Srt\DISMRepairLogFile.txt
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1236 Initialized GlobalConfig - DismInitializeInternal
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1236 Initialized SessionTable - DismInitializeInternal
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1236 Lookup in table by path failed for: DummyPath-2BA51B78-C7F7-4910-B99D-BB7345357CDC - CTransactionalImageTable::LookupImagePath
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1236 Waiting for m_pInternalThread to start - CCommandThread::Start
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1056 Enter CCommandThread::CommandThreadProcedureStub - CCommandThread::CommandThreadProcedureStub
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1056 Enter CCommandThread::ExecuteLoop - CCommandThread::ExecuteLoop
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1236 CommandThread StartupEvent signaled - CCommandThread::WaitForStartup
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1236 m_pInternalThread started - CCommandThread::Start
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1236 Created g_internalDismSession - DismInitializeInternal
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1236 Input parameters: ImagePath: C:\, WindowsDirectory: (null), SystemDrive: (null) - DismOpenSessionInternal
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1236 Lookup in table by path failed for: DRIVE_C - CTransactionalImageTable::LookupImagePath
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1236 Waiting for m_pInternalThread to start - CCommandThread::Start
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1984 Enter CCommandThread::CommandThreadProcedureStub - CCommandThread::CommandThreadProcedureStub
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1984 Enter CCommandThread::ExecuteLoop - CCommandThread::ExecuteLoop
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1236 CommandThread StartupEvent signaled - CCommandThread::WaitForStartup
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1236 m_pInternalThread started - CCommandThread::Start
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1236 Successfully enqueued command object - CCommandThread::EnqueueCommandObject
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1984 ExecuteLoop: CommandQueue signaled - CCommandThread::ExecuteLoop
>
> 2026-11-02 15:21:07, Info         DISM  API: PID=1776 TID=1984 Successfully dequeued command object - CCommandThread::DequeueCommandObject
>
> 2026-11-02 15:21:07, Info         DISM  PID=1776 TID=1984 Scratch directory set to 'X:\windows\TEMP\'. - CDISMManager::put_ScratchDir
>
> 2026-11-02 15:21:07, Info         DISM  PID=1776 TID=1984 DismCore.dll version: 10.0.22621.1 - CDISMManager::FinalConstruct
>
> 2026-11-02 15:21:07, Info         DISM  Initialized Panther logging at C:\Windows\System32\Logfiles\Srt\DISMRepairLogFile.txt
>
> 2026-11-02 15:21:07, Info         DISM  PID=1776 TID=1984 Successfully loaded the ImageSession at "X:\windows\SYSTEM32\Dism" - CDISMManager::LoadLocalImageSession
>
> 2026-11-02 15:21:07, Info         DISM  Initialized Panther logging at C:\Windows\System32\Logfiles\Srt\DISMRepairLogFile.txt
>
> 2026-11-02 15:21:07, Info         DISM  DISM Provider Store: PID=1776 TID=1984 Found and Initialized the DISM Logger. - CDISMProviderStore::Internal_InitializeLogger
>
> 2026-11-02 15:21:07, Info         DISM  Initialized Panther logging at C:\Windows\System32\Logfiles\Srt\DISMRepairLogFile.txt
>
> 2026-11-02 15:21:07, Info         DISM  DISM Manager: PID=1776 TID=1984 Successfully created the local image session and provider store. - CDISMManager::CreateLocalImageSession
>
> 2026-11-02 15:21:07, Info         DISM  DISM FFU Provider: PID=1776 TID=1984 [C:\] is not recognized by the DISM FFU provider. - CFfuImage::Initialize
>
> 2026-11-02 15:21:07, Info         DISM  DISM Imaging Provider: PID=1776 TID=1984 The provider FfuManager does not support CreateDismImage on C:\ - CGenericImagingManager::CreateDismImage
>
> 2026-11-02 15:21:07, Info         DISM  DISM VHD Provider: PID=1776 TID=1984 [C:\] is not recognized by the DISM VHD provider. - CVhdImage::Initialize
>
> 2026-11-02 15:21:07, Info         DISM  DISM Imaging Provider: PID=1776 TID=1984 The provider VHDManager does not support CreateDismImage on C:\ - CGenericImagingManager::CreateDismImage
>
> [1776.1984] [0x80070002] FIOReadFileIntoBuffer:(1456): 系统找不到指定的文件。
>
> [1776.1984] [0xc142011c] UnmarshallImageHandleFromDirectory:(641)
>
> [1776.1984] [0xc142011c] WIMGetMountedImageHandle:(2910)
>
> 2026-11-02 15:21:07, Info         DISM  DISM WIM Provider: PID=1776 TID=1984 [C:\] is not a WIM mount point. - CWimMountedImageInfo::Initialize
>
> 2026-11-02 15:21:07, Info         DISM  DISM Imaging Provider: PID=1776 TID=1984 The provider WimManager does not support CreateDismImage on C:\ - CGenericImagingManager::CreateDismImage
>
> 2026-11-02 15:21:07, Info         DISM  DISM Imaging Provider: PID=1776 TID=1984 No imaging provider supported CreateDismImage for this path - CGenericImagingManager::CreateDismImage
>
> [1776.1984] [0x80070002] FIOReadFileIntoBuffer:(1456): 系统找不到指定的文件。
>
> [1776.1984] [0xc142011c] UnmarshallImageHandleFromDirectory:(641)
>
> [1776.1984] [0xc142011c] WIMGetMountedImageHandle:(2910)
>
> 2026-11-02 15:21:07, Info         DISM  DISM WIM Provider: PID=1776 TID=1984 [C:\] is not a WIM mount point. - CWimMountedImageInfo::Initialize
>
> 2026-11-02 15:21:07, Info         DISM  DISM FFU Provider: PID=1776 TID=1984 [C:\] is not recognized by the DISM FFU provider. - CFfuImage::Initialize
>
> 2026-11-02 15:21:07, Info         DISM  DISM VHD Provider: PID=1776 TID=1984 [C:\] is not recognized by the DISM VHD provider. - CVhdImage::Initialize
>
> 2026-11-02 15:21:07, Info         DISM  DISM Manager: PID=1776 TID=1984 physical location path: C:\ - CDISMManager::CreateImageSession
>
> 2026-11-02 15:21:07, Info         DISM  DISM Manager: PID=1776 TID=1984 Event name for current DISM session is Global\__?_Volume{9508512a-c61f-41bc-bae8-64b14d710d06}__2062103243_65536_58365 - CDISMManager::CheckSessionAndLock
>
> 2026-11-02 15:21:07, Info         DISM  DISM Manager: PID=1776 TID=1984 Create session event 0xac for current DISM session and event name is Global\__?_Volume{9508512a-c61f-41bc-bae8-64b14d710d06}__2062103243_65536_58365 - CDISMManager::CheckSessionAndLock
>
> 2026-11-02 15:21:07, Info         DISM  DISM Manager: PID=1776 TID=1984 Copying DISM from "C:\Windows\System32\Dism" - CDISMManager::CreateImageSessionFromLocation
>
> 2026-11-02 15:21:07, Info         DISM  DISM Manager: PID=1776 TID=1984 Successfully loaded the ImageSession at "X:\windows\TEMP\693671C4-0C9A-4064-895F-FBBCC1211507" - CDISMManager::LoadRemoteImageSession
>
> 2026-11-02 15:21:07, Info         DISM  DISM Image Session: PID=2044 TID=864 Instantiating the Provider Store. - CDISMImageSession::get_ProviderStore
>
> 2026-11-02 15:21:07, Info         DISM  DISM OS Provider: PID=2044 TID=864 Defaulting SystemPath to C:\ - CDISMOSServiceManager::Final_OnConnect
>
> 2026-11-02 15:21:07, Info         DISM  DISM OS Provider: PID=2044 TID=864 Defaulting Windows folder to C:\Windows - CDISMOSServiceManager::Final_OnConnect
>
> 2026-11-02 15:21:07, Info         DISM  DISM Provider Store: PID=2044 TID=864 Attempting to initialize the logger from the Image Session. - CDISMProviderStore::Final_OnConnect
>
> 2026-11-02 15:21:07, Info         DISM  Initialized Panther logging at C:\Windows\System32\Logfiles\Srt\DISMRepairLogFile.txt
>
> 2026-11-02 15:21:07, Info         DISM  DISM Provider Store: PID=2044 TID=864 Found and Initialized the DISM Logger. - CDISMProviderStore::Internal_InitializeLogger
>
> 2026-11-02 15:21:07, Info         DISM  Initialized Panther logging at C:\Windows\System32\Logfiles\Srt\DISMRepairLogFile.txt
>
> 2026-11-02 15:21:07, Info         DISM  Initialized Panther logging at C:\Windows\System32\Logfiles\Srt\DISMRepairLogFile.txt
>
> 2026-11-02 15:21:07, Info         DISM  DISM Manager: PID=1776 TID=1984 Image session successfully loaded from location: X:\windows\TEMP\693671C4-0C9A-4064-895F-FBBCC1211507 - CDISMManager::CreateImageSession
>
> 2026-11-02 15:21:08, Info         DISM  API: PID=1776 TID=1984 Target image information: OS Version=10.0.22631.5768, Image architecture=amd64 - CDismCore::LogImageSessionDetails
>
> 2026-11-02 15:21:08, Info         DISM  API: PID=1776 TID=1236 Session id is: 2 - DismOpenSessionInternal
>
> 2026-11-02 15:21:08, Info         DISM  API: PID=1776 TID=1236 Input parameter: Session: 2 - DismGetPackagesInternal
>
> 2026-11-02 15:21:08, Info         DISM  API: PID=1776 TID=1236 Successfully enqueued command object - CCommandThread::EnqueueCommandObject
>
> 2026-11-02 15:21:08, Info         DISM  API: PID=1776 TID=1984 ExecuteLoop: CommandQueue signaled - CCommandThread::ExecuteLoop
>
> 2026-11-02 15:21:08, Info         DISM  API: PID=1776 TID=1984 Successfully dequeued command object - CCommandThread::DequeueCommandObject
>
> 2026-11-02 15:21:08, Info         DISM  DISM Package Manager: PID=2044 TID=864 Finished initializing the CbsConUI Handler. - CCbsConUIHandler::Initialize
>
> 2026-11-02 15:21:08, Info         DISM  DISM OS Provider: PID=2044 TID=864 Determined System directory to be C:\Windows\System32 - CDISMOSServiceManager::get_SystemDirectory
>
> 2026-11-02 15:21:08, Info         CSI  00000001 Shim considered [l:126]'\??\C:\Windows\Servicing\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\wcp.dll' : got STATUS_OBJECT_PATH_NOT_FOUND
>
> 2026-11-02 15:21:08, Info         CSI  00000002 Shim considered [l:123]'\??\C:\Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\wcp.dll' : got STATUS_SUCCESS
>
> 2026-11-02 15:21:08, Info         CBS  Universal Time is: 2026-11-02 07:21:08.116
>
> 2026-11-02 15:21:08, Info         CBS  Failed to find a matching version for servicing stack: C:\Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\ [HRESULT = 0x80070490 - ERROR_NOT_FOUND]
>
> 2026-11-02 15:21:08, Info         CBS  Failed to find servicing stack directory in online store. [HRESULT = 0x80070490 - ERROR_NOT_FOUND]
>
> 2026-11-02 15:21:08, Info         CBS  Offline servicing, using stack version from: C:\Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\cbscore.dll
>
> 2026-11-02 15:21:08, Info         CBS  Loaded Servicing Stack v10.0.22621.5690 with Core: C:\Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\cbscore.dll
>
> 2026-11-02 15:21:08, Info         CBS  Setting core mode: CbsCoreModeOffline
>
> 2026-11-02 15:21:08, Info         CSI  00000001@2026/11/2:07:21:08.116 WcpInitialize: wcp.dll version 10.0.22621.5690 (WinBuild.160101.0800)
>
> 2026-11-02 15:21:08, Info         CBS  TurboContainer load Successful
>
> 2026-11-02 15:21:08, Info         CBS  Lock: New lock added: CCbsSessionManager, level: 11, total lock:9
>
> 2026-11-02 15:21:08, Info         CBS  Lock: New lock added: CSIInventoryCriticalSection, level: 64, total lock:10
>
> 2026-11-02 15:21:08, Info         DISM  DISM Package Manager: PID=2044 TID=864 Loaded servicing stack for offline use only. - CDISMPackageManager::CreateCbsSession
>
> 2026-11-02 15:21:08, Info         CBS  Lazy store initialization mode
>
> 2026-11-02 15:21:08, Info         CSI  00000001 Shim considered [l:126]'\??\C:\Windows\Servicing\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\wcp.dll' : got STATUS_OBJECT_PATH_NOT_FOUND
>
> 2026-11-02 15:21:08, Info         CSI  00000002 Shim considered [l:123]'\??\C:\Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\wcp.dll' : got STATUS_SUCCESS
>
> 2026-11-02 15:21:08, Info         CBS  Lazy store initialization mode, fully initialize.
>
> 2026-11-02 15:21:08, Info         CBS  Offline image is writable
>
> 2026-11-02 15:21:08, Info         CBS  Loading offline registry hive: SOFTWARE, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SOFTWARE' from path '\\?\C:\Windows\System32\config\SOFTWARE'.
>
> 2026-11-02 15:21:08, Info         CBS  Loading offline registry hive: SYSTEM, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SYSTEM' from path '\\?\C:\Windows\System32\config\SYSTEM'.
>
> 2026-11-02 15:21:12, Info         CBS  Failed to load offline \\?\C:\Windows\System32\config\SYSTEM hive from '\\?\C:\Windows\System32\config\SYSTEM' into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SYSTEM'. [HRESULT = 0xd0000043 - NTSTATUS Error]
>
> 2026-11-02 15:21:12, Info         CBS  Failed to load offline registry: {bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SYSTEM [HRESULT = 0xd0000043 - NTSTATUS Error]
>
> 2026-11-02 15:21:12, Info         CBS  Failed to load offline SYSTEM hive. [HRESULT = 0xd0000043 - NTSTATUS Error]
>
> 2026-11-02 15:21:12, Info         CBS  Force unloading offline registry hive: {bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SOFTWARE
>
> 2026-11-02 15:21:12, Error         CBS  Failed to load offline store from boot directory: '\\?\C:\' and windows directory: '\\?\C:\Windows\' [HRESULT = 0xd0000043 - NTSTATUS Error]
>
> 2026-11-02 15:21:12, Error         CBS  Failed to initialize store parameters with boot drive: C:\, windows directory C:\Windows, and external directory: [HRESULT = 0xd0000043 - NTSTATUS Error]
>
> 2026-11-02 15:21:12, Error         CBS  Cannot enumerate packages in a session that has not been initialized. [HRESULT = 0xd0000043 - NTSTATUS Error]
>
> 2026-11-02 15:21:12, Error         DISM  DISM Package Manager: PID=2044 TID=864 Failed to create the CBS Package enumeration. - CDISMPackageManager::GetPackageCollection(hr:0xd0000043)
>
> 2026-11-02 15:21:12, Error         DISM  API: PID=1776 TID=1984 Failed to get package collection - CGetPackagesCommandObject::InternalExecute(hr:0xd0000043)
>
> 2026-11-02 15:21:12, Error         DISM  API: PID=1776 TID=1984 InternalExecute failed - CBaseCommandObject::Execute(hr:0xd0000043)
>
> 2026-11-02 15:21:12, Error         DISM  API: PID=1776 TID=1236 CGetPackagesCommandObject internal execution failed - DismGetPackagesInternal(hr:0xd0000043)
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1236 Input parameters: Session: 2 - DismCloseSessionInternal
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1236 GetReferenceCount hr: 0x0 - CSessionTable::RemoveSession
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1236 Refcount for DismSession= 2s 0 - CSessionTable::RemoveSession
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1236 Successfully enqueued command object - CCommandThread::EnqueueCommandObject
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1984 ExecuteLoop: CommandQueue signaled - CCommandThread::ExecuteLoop
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1984 Successfully dequeued command object - CCommandThread::DequeueCommandObject
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1984 ExecuteLoop: Cancel signaled - CCommandThread::ExecuteLoop
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1984 Leave CCommandThread::ExecuteLoop - CCommandThread::ExecuteLoop
>
> 2026-11-02 15:21:12, Info         DISM  DISM Package Manager: PID=2044 TID=864 Finalizing CBS core. - CDISMPackageManager::Finalize
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: ExecutionEngineFinalize
>
> 2026-11-02 15:21:12, Info         CBS  Execution Engine Finalize
>
> 2026-11-02 15:21:12, Info         CBS  Execution Engine Finalize
>
> 2026-11-02 15:21:12, Info         CBS  Execution Engine Finalize
>
> 2026-11-02 15:21:12, Info         CBS  Execution Engine Finalize
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: ComponentAnalyzerFinalize
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: PackageTrackerFinalize
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: CoreResourcesUnload
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: SessionManagerFinalize
>
> 2026-11-02 15:21:12, Info         CBS  Lock: Lock removed: CSIInventoryCriticalSection, level: 64, total lock:10
>
> 2026-11-02 15:21:12, Info         CBS  Lock: Lock removed: CCbsSessionManager, level: 11, total lock:9
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: CapabilityManagerFinalize
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: GetPublicObjectMonitor::Audit
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: PublicObjectMonitorFinalize
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: Enter vCoreInitializeLock
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: WcpUnload
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: DrupUnload
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: CfgMgr32Unload
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: DpxUnload
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: SrUnload
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: TurboStackUnload
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: TurboContainerUnload
>
> 2026-11-02 15:21:12, Info         CBS  TurboContainer unload Successful
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: CbsEsdUnload
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: CbsOneSettingsFinalize
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: CbsEventUnregister
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: AppContainerUnload
>
> 2026-11-02 15:21:12, Info         CBS  CbsCoreFinalize: WdsUnload, logging from cbscore will end.
>
> 2026-11-02 15:21:12, Info         DISM  DISM Manager: PID=1776 TID=1984 Closing session event handle 0xac - CDISMManager::CleanupImageSessionEntry
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1984 Leave CCommandThread::CommandThreadProcedureStub - CCommandThread::CommandThreadProcedureStub
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1236 GetReferenceCount hr: 0x0 - CSessionTable::RemoveSession
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1236 Refcount for DismSession= 1s 0 - CSessionTable::RemoveSession
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1236 Successfully enqueued command object - CCommandThread::EnqueueCommandObject
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1056 ExecuteLoop: CommandQueue signaled - CCommandThread::ExecuteLoop
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1056 Successfully dequeued command object - CCommandThread::DequeueCommandObject
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1056 ExecuteLoop: Cancel signaled - CCommandThread::ExecuteLoop
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1056 Leave CCommandThread::ExecuteLoop - CCommandThread::ExecuteLoop
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1056 Leave CCommandThread::CommandThreadProcedureStub - CCommandThread::CommandThreadProcedureStub
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1236 Deleted g_internalDismSession - DismShutdownInternal
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1236 Shutdown SessionTable - DismShutdownInternal
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1236 DismApi.dll:                     - DismShutdownInternal
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1236 DismApi.dll: <----- Ending DismApi.dll session -----> - DismShutdownInternal
>
> 2026-11-02 15:21:12, Info         DISM  API: PID=1776 TID=1236 DismA
>
> SrtTrail.log
>
>  @ ፧�槣ǝ    AutoFailover                                                                                                                           
>
> 塝 
>
> 塝                                                                                                                                  泾Ń AutoFailover                                                                                                                          TooManyAttempts                                                                                                                               ፧�槣ǝ    ⽩룻檚ǝᕌ뵿檚ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 醼憥획ᇱ슿懲㥴ี     渶渶检查更新                                                                                                                                   渶渶系统磁盘测试                                                                                                                                  渶渶磁盘故障诊断                                                                                                                                  渶溄磁盘元数据测试                                                                                                                                 溄溄磁盘元数据测试                                                                                                                                 溄溄目标操作系统测试                                                                                                                                 溄溳卷内容测试                                                                                                                                  溳溳启动管理器诊断                                                                                                                                 溳溳系统启动日志诊断                                                                                                                                 溳溳事件日志诊断                                                                                                                                  溳溳内部状态检查                                                                                                                                 C 溳蓚检查已安装的 LCU                                                                                                                                 ፧�槣ǝ    氻⓪檏ǝ⳨☋檏ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⚓ ⚓ 检查更新                                                                                                                                   ⚓ ⚓ 系统磁盘测试                                                                                                                                  ⚓ ⚢ 磁盘故障诊断                                                                                                                                  ⚢ ⛰ 磁盘元数据测试                                                                                                                                 ⛰ ⛰ 磁盘元数据测试                                                                                                                                 ⛰ ⛰ 目标操作系统测试                                                                                                                                 ⛰ ✟ 卷内容测试                                                                                                                                  ✟ ✟ 启动管理器诊断                                                                                                                                 ✟ ✟ 系统启动日志诊断                                                                                                                                 ✟ ✟ 事件日志诊断                                                                                                                                  ✟ ✟ 内部状态检查                                                                                                                                       ፧�槣ǝ    泥붐檎ǝ坌뾃檎ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     誌 誌 检查更新                                                                                                                                   誌 誌 系统磁盘测试                                                                                                                                  誌 誜 磁盘故障诊断                                                                                                                                  誜 説 磁盘元数据测试                                                                                                                                 説 説 磁盘元数据测试                                                                                                                                 説 説 目标操作系统测试                                                                                                                                 説 誻 卷内容测试                                                                                                                                  誻 誻 启动管理器诊断                                                                                                                                 誻 誻 系统启动日志诊断                                                                                                                                 誻 誻 事件日志诊断                                                                                                                                  誻 誻 内部状态检查                                                                                                                                 Ō 誻 選 检查已安装的 LCU                                                                                                                                 ፧�槣ǝ    ㅩ깃檎ǝ叢꽦檎ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ♄ ♄ 检查更新                                                                                                                                   ♄ ♄ 系统磁盘测试                                                                                                                                  ♄ ♔ 磁盘故障诊断                                                                                                                                  ♔ ⚲ 磁盘元数据测试                                                                                                                                 ⚲ ⚲ 磁盘元数据测试                                                                                                                                 ⚲ ⚲ 目标操作系统测试                                                                                                                                 ⚲ ⛡ 卷内容测试                                                                                                                                  ⛡ ⛡ 启动管理器诊断                                                                                                                                 ⛡ ⛡ 系统启动日志诊断                                                                                                                                 ⛡ ⛡ 事件日志诊断                                                                                                                                  ⛡ ⛡ 内部状态检查                                                                                                                                       ፧�槣ǝ    撯૤檍ǝ⛲అ檍ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⟪ ⟪ 检查更新                                                                                                                                   ⟪ ⟪ 系统磁盘测试                                                                                                                                  ⟪ ⟺ 磁盘故障诊断                                                                                                                                  ⟺ ⡈ 磁盘元数据测试                                                                                                                                 ⡈ ⡈ 磁盘元数据测试                                                                                                                                 ⡈ ⡈ 目标操作系统测试                                                                                                                                 ⡈ ⡷ 卷内容测试                                                                                                                                  ⡷ ⡷ 启动管理器诊断                                                                                                                                 ⡷ ⡷ 系统启动日志诊断                                                                                                                                 ⡷ ⡷ 事件日志诊断                                                                                                                                  ⡷ ⡷ 内部状态检查                                                                                                                                       ፧�槣ǝ    瞫�檌ǝ襽�檌ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ❎ ❎ 检查更新                                                                                                                                   ❎ ❎ 系统磁盘测试                                                                                                                                  ❎ ❞ 磁盘故障诊断                                                                                                                                  ❞ ➬ 磁盘元数据测试                                                                                                                                 ➬ ➬ 磁盘元数据测试                                                                                                                                 ➬ ➬ 目标操作系统测试                                                                                                                                 ➬ ⟛ 卷内容测试                                                                                                                                  ⟛ ⟛ 启动管理器诊断                                                                                                                                 ⟛ ⟛ 系统启动日志诊断                                                                                                                                 ⟛ ⟛ 事件日志诊断                                                                                                                                  ⟛ ⟛ 内部状态检查                                                                                                                                       ፧�槣ǝ    ሳ⽞檊ǝ�ま檊ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⪚ ⪚ 检查更新                                                                                                                                   ⪚ ⪚ 系统磁盘测试                                                                                                                                  ⪚ ⪩ 磁盘故障诊断                                                                                                                                  ⪩ ⫸ 磁盘元数据测试                                                                                                                                 ⫸ ⫸ 磁盘元数据测试                                                                                                                                 ⫸ ⫸ 目标操作系统测试                                                                                                                                 ⫸ ⬦ 卷内容测试                                                                                                                                  ⬦ ⬦ 启动管理器诊断                                                                                                                                 ⬦ ⬦ 系统启动日志诊断                                                                                                                                 ⬦ ⬦ 事件日志诊断                                                                                                                                  ⬦ ⬦ 内部状态检查                                                                                                                                       ፧�槣ǝ    镕࠴檊ǝΐॕ檊ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⟛ ⟛ 检查更新                                                                                                                                   ⟛ ⟛ 系统磁盘测试                                                                                                                                  ⟛ ⟪ 磁盘故障诊断                                                                                                                                  ⟪ ⠸ 磁盘元数据测试                                                                                                                                 ⠸ ⠸ 磁盘元数据测试                                                                                                                                 ⠸ ⠸ 目标操作系统测试                                                                                                                                 ⠸ ⡧ 卷内容测试                                                                                                                                  ⡧ ⡧ 启动管理器诊断                                                                                                                                 ⡧ ⡧ 系统启动日志诊断                                                                                                                                 ⡧ ⡧ 事件日志诊断                                                                                                                                  ⡧ ⡧ 内部状态检查                                                                                                                                       ፧�槣ǝ    륱檉ǝ萞檉ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ➻ ➻ 检查更新                                                                                                                                   ➻ ➻ 系统磁盘测试                                                                                                                                  ➻ ⟋ 磁盘故障诊断                                                                                                                                  ⟋ ⠊ 磁盘元数据测试                                                                                                                                 ⠊ ⠙ 磁盘元数据测试                                                                                                                                 ⠙ ⠙ 目标操作系统测试                                                                                                                                 ⠙ ⡈ 卷内容测试                                                                                                                                  ⡈ ⡈ 启动管理器诊断                                                                                                                                 ⡈ ⡈ 系统启动日志诊断                                                                                                                                 ⡈ ⡈ 事件日志诊断                                                                                                                                  ⡈ ⡈ 内部状态检查                                                                                                                                       ፧�槣ǝ    Ի퇬檉ǝ흯파檉ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ➜ ➜ 检查更新                                                                                                                                   ➜ ➜ 系统磁盘测试                                                                                                                                  ➜ ➬ 磁盘故障诊断                                                                                                                                  ➬ ⟪ 磁盘元数据测试                                                                                                                                 ⟪ ⟺ 磁盘元数据测试                                                                                                                                 ⟺ ⟺ 目标操作系统测试                                                                                                                                 ⟺ ⠩ 卷内容测试                                                                                                                                  ⠩ ⠩ 启动管理器诊断                                                                                                                                 ⠩ ⠩ 系统启动日志诊断                                                                                                                                 ⠩ ⠩ 事件日志诊断                                                                                                                                  ⠩ ⠩ 内部状态检查                                                                                                                                       ፧�槣ǝ    ␠∓檉ǝ柨⌶檉ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ➍ ➍ 检查更新                                                                                                                                   ➍ ➍ 系统磁盘测试                                                                                                                                  ➍ ➜ 磁盘故障诊断                                                                                                                                  ➜ ⟪ 磁盘元数据测试                                                                                                                                 ⟪ ⟪ 磁盘元数据测试                                                                                                                                 ⟪ ⟪ 目标操作系统测试                                                                                                                                 ⟪ ⠙ 卷内容测试                                                                                                                                  ⠙ ⠙ 启动管理器诊断                                                                                                                                 ⠙ ⠙ 系统启动日志诊断                                                                                                                                 ⠙ ⠙ 事件日志诊断                                                                                                                                  ⠙ ⠙ 内部状态检查                                                                                                                                       ፧�槣ǝ    ⌒檈ǝፐ檈ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⤣ ⤣ 检查更新                                                                                                                                   ⤣ ⤣ 系统磁盘测试                                                                                                                                  ⤣ ⤲ 磁盘故障诊断                                                                                                                                  ⤲ ⦁ 磁盘元数据测试                                                                                                                                 ⦁ ⦁ 磁盘元数据测试                                                                                                                                 ⦁ ⦁ 目标操作系统测试                                                                                                                                 ⦁ ⦯ 卷内容测试                                                                                                                                  ⦯ ⦯ 启动管理器诊断                                                                                                                                 ⦯ ⦯ 系统启动日志诊断                                                                                                                                 ⦯ ⦯ 事件日志诊断                                                                                                                                  ⦯ ⦯ 内部状态检查                                                                                                                                       ፧�槣ǝ    떶苫檈ǝﶠ萎檈ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ❽ ❽ 检查更新                                                                                                                                   ❽ ❽ 系统磁盘测试                                                                                                                                  ❽ ➍ 磁盘故障诊断                                                                                                                                  ➍ ⟋ 磁盘元数据测试                                                                                                                                 ⟋ ⟛ 磁盘元数据测试                                                                                                                                 ⟛ ⟛ 目标操作系统测试                                                                                                                                 ⟛ ⠊ 卷内容测试                                                                                                                                  ⠊ ⠊ 启动管理器诊断                                                                                                                                 ⠊ ⠊ 系统启动日志诊断                                                                                                                                 ⠊ ⠊ 事件日志诊断                                                                                                                                  ⠊ ⠊ 内部状态检查                                                                                                                                       ፧�槣ǝ    穠榏檇ǝ酸檲檇ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ❎ ❎ 检查更新                                                                                                                                   ❎ ❎ 系统磁盘测试                                                                                                                                  ❎ ❞ 磁盘故障诊断                                                                                                                                  ❞ ➜ 磁盘元数据测试                                                                                                                                 ➜ ➬ 磁盘元数据测试                                                                                                                                 ➬ ➬ 目标操作系统测试                                                                                                                                 ➬ ⟛ 卷内容测试                                                                                                                                  ⟛ ⟛ 启动管理器诊断                                                                                                                                 ⟛ ⟛ 系统启动日志诊断                                                                                                                                 ⟛ ⟛ 事件日志诊断                                                                                                                                  ⟛ ⟛ 内部状态检查                                                                                                                                       ፧�槣ǝ    ベ䨀檇ǝ䬠檇ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ❭ ❭ 检查更新                                                                                                                                   ❭ ❭ 系统磁盘测试                                                                                                                                  ❭ ❽ 磁盘故障诊断                                                                                                                                  ❽ ⟋ 磁盘元数据测试                                                                                                                                 ⟋ ⟋ 磁盘元数据测试                                                                                                                                 ⟋ ⟋ 目标操作系统测试                                                                                                                                 ⟋ ⟺ 卷内容测试                                                                                                                                  ⟺ ⟺ 启动管理器诊断                                                                                                                                 ⟺ ⟺ 系统启动日志诊断                                                                                                                                 ⟺ ⟺ 事件日志诊断                                                                                                                                  ⟺ ⟺ 内部状态检查                                                                                                                                       ፧�槣ǝ    噀Ō檇ǝℭɭ檇ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ➍ ➍ 检查更新                                                                                                                                   ➍ ➍ 系统磁盘测试                                                                                                                                  ➍ ➜ 磁盘故障诊断                                                                                                                                  ➜ ⟛ 磁盘元数据测试                                                                                                                                 ⟛ ⟪ 磁盘元数据测试                                                                                                                                 ⟪ ⟪ 目标操作系统测试                                                                                                                                 ⟪ ⠙ 卷内容测试                                                                                                                                  ⠙ ⠙ 启动管理器诊断                                                                                                                                 ⠙ ⠙ 系统启动日志诊断                                                                                                                                 ⠙ ⠙ 事件日志诊断                                                                                                                                  ⠙ ⠙ 内部状态检查                                                                                                                                       ፧�槣ǝ    ᣒ�檆ǝ��檆ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⟺ ⟺ 检查更新                                                                                                                                   ⟺ ⟺ 系统磁盘测试                                                                                                                                  ⟺ ⠊ 磁盘故障诊断                                                                                                                                  ⠊ ⡷ 磁盘元数据测试                                                                                                                                 ⡷ ⡷ 磁盘元数据测试                                                                                                                                 ⡷ ⡷ 目标操作系统测试                                                                                                                                 ⡷ ⢦ 卷内容测试                                                                                                                                  ⢦ ⢦ 启动管理器诊断                                                                                                                                 ⢦ ⢦ 系统启动日志诊断                                                                                                                                 ⢦ ⢵ 事件日志诊断                                                                                                                                  ⢵ ⢵ 内部状态检查                                                                                                                                       ፧�槣ǝ    Η鳠檆ǝ쬬鸀檆ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⦐ ⦐ 检查更新                                                                                                                                   ⦐ ⦐ 系统磁盘测试                                                                                                                                  ⦐ ⦠ 磁盘故障诊断                                                                                                                                  ⦠ ⧮ 磁盘元数据测试                                                                                                                                 ⧮ ⧮ 磁盘元数据测试                                                                                                                                 ⧮ ⧮ 目标操作系统测试                                                                                                                                 ⧮ ⨝ 卷内容测试                                                                                                                                  ⨝ ⨝ 启动管理器诊断                                                                                                                                 ⨝ ⨝ 系统启动日志诊断                                                                                                                                 ⨝ ⨝ 事件日志诊断                                                                                                                                  ⨝ ⨝ 内部状态检查                                                                                                                                       ፧�槣ǝ    뀖볏檅ǝ㑴뺽檅ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     墾 墾 检查更新                                                                                                                                   墾 墾 系统磁盘测试                                                                                                                                  墾 壎 磁盘故障诊断                                                                                                                                  壎 壞 磁盘元数据测试                                                                                                                                 壞 壞 磁盘元数据测试                                                                                                                                 壞 壞 目标操作系统测试                                                                                                                                 壞 壞 卷内容测试                                                                                                                                  壞 壞 启动管理器诊断                                                                                                                                 壞 壞 系统启动日志诊断                                                                                                                                 壞 壭 事件日志诊断                                                                                                                                  壭 壭 内部状态检查                                                                                                                                 Ō 壭 庋 检查已安装的 LCU                                                                                                                                 ፧�槣ǝ    鷱땼檅ǝ瘾뚝檅ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⣅ ⣅ 检查更新                                                                                                                                   ⣅ ⣅ 系统磁盘测试                                                                                                                                  ⣅ ⣕ 磁盘故障诊断                                                                                                                                  ⣕ ⤣ 磁盘元数据测试                                                                                                                                 ⤣ ⤣ 磁盘元数据测试                                                                                                                                 ⤣ ⤣ 目标操作系统测试                                                                                                                                 ⤣ ⥒ 卷内容测试                                                                                                                                  ⥒ ⥒ 启动管理器诊断                                                                                                                                 ⥒ ⥒ 系统启动日志诊断                                                                                                                                 ⥒ ⥒ 事件日志诊断                                                                                                                                  ⥒ ⥒ 内部状态检查                                                                                                                                       ፧�槣ǝ    鄉閱檅ǝ礕雒檅ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ❭ ❭ 检查更新                                                                                                                                   ❭ ❭ 系统磁盘测试                                                                                                                                  ❭ ❽ 磁盘故障诊断                                                                                                                                  ❽ ⟋ 磁盘元数据测试                                                                                                                                 ⟋ ⟋ 磁盘元数据测试                                                                                                                                 ⟋ ⟋ 目标操作系统测试                                                                                                                                 ⟋ ⟺ 卷内容测试                                                                                                                                  ⟺ ⟺ 启动管理器诊断                                                                                                                                 ⟺ ⟺ 系统启动日志诊断                                                                                                                                 ⟺ ⟺ 事件日志诊断                                                                                                                                  ⟺ ⟺ 内部状态检查                                                                                                                                       ፧�槣ǝ    ᙨ橾ǝ왬橾ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ➻ ➻ 检查更新                                                                                                                                   ➻ ⟋ 系统磁盘测试                                                                                                                                  ⟋ ⟋ 磁盘故障诊断                                                                                                                                  ⟋ ⠩ 磁盘元数据测试                                                                                                                                 ⠩ ⠩ 磁盘元数据测试                                                                                                                                 ⠩ ⠩ 目标操作系统测试                                                                                                                                 ⠩ ⡘ 卷内容测试                                                                                                                                  ⡘ ⡘ 启动管理器诊断                                                                                                                                 ⡘ ⡘ 系统启动日志诊断                                                                                                                                 ⡘ ⡧ 事件日志诊断                                                                                                                                  ⡧ ⡧ 内部状态检查                                                                                                                                       ፧�槣ǝ    楈臺橾ǝ黝茘橾ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⤣ ⤣ 检查更新                                                                                                                                   ⤣ ⤣ 系统磁盘测试                                                                                                                                  ⤣ ⤲ 磁盘故障诊断                                                                                                                                  ⤲ ⦁ 磁盘元数据测试                                                                                                                                 ⦁ ⦁ 磁盘元数据测试                                                                                                                                 ⦁ ⦁ 目标操作系统测试                                                                                                                                 ⦁ ⦯ 卷内容测试                                                                                                                                  ⦯ ⦯ 启动管理器诊断                                                                                                                                 ⦯ ⦯ 系统启动日志诊断                                                                                                                                 ⦯ ⦯ 事件日志诊断                                                                                                                                  ⦯ ⦯ 内部状态检查                                                                                                                                       ፧�槣ǝ    祈嘛橾ǝ캶圼橾ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⛑ ⛑ 检查更新                                                                                                                                   ⛑ ⛑ 系统磁盘测试                                                                                                                                  ⛑ ⛡ 磁盘故障诊断                                                                                                                                  ⛡ ✯ 磁盘元数据测试                                                                                                                                 ✯ ✯ 磁盘元数据测试                                                                                                                                 ✯ ✯ 目标操作系统测试                                                                                                                                 ✯ ❞ 卷内容测试                                                                                                                                  ❞ ❞ 启动管理器诊断                                                                                                                                 ❞ ❞ 系统启动日志诊断                                                                                                                                 ❞ ❞ 事件日志诊断                                                                                                                                  ❞ ❞ 内部状态检查                                                                                                                                       ፧�槣ǝ    ꫃糇橽ǝ韏緪橽ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⡧ ⡧ 检查更新                                                                                                                                   ⡧ ⡧ 系统磁盘测试                                                                                                                                  ⡧ ⡷ 磁盘故障诊断                                                                                                                                  ⡷ ⢵ 磁盘元数据测试                                                                                                                                 ⢵ ⣅ 磁盘元数据测试                                                                                                                                 ⣅ ⣅ 目标操作系统测试                                                                                                                                 ⣅ ⣴ 卷内容测试                                                                                                                                  ⣴ ⣴ 启动管理器诊断                                                                                                                                 ⣴ ⣴ 系统启动日志诊断                                                                                                                                 ⣴ ⣴ 事件日志诊断                                                                                                                                  ⣴ ⣴ 内部状态检查                                                                                                                                       ፧�槣ǝ    ❅䘺橽ǝﶈ䝚橽ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ♄ ♄ 检查更新                                                                                                                                   ♄ ♄ 系统磁盘测试                                                                                                                                  ♄ ♔ 磁盘故障诊断                                                                                                                                  ♔ ⚓ 磁盘元数据测试                                                                                                                                 ⚓ ⚓ 磁盘元数据测试                                                                                                                                 ⚓ ⚓ 目标操作系统测试                                                                                                                                 ⚓ ⛑ 卷内容测试                                                                                                                                  ⛑ ⛑ 启动管理器诊断                                                                                                                                 ⛑ ⛑ 系统启动日志诊断                                                                                                                                 ⛑ ⛑ 事件日志诊断                                                                                                                                  ⛑ ⛑ 内部状态检查                                                                                                                                       ፧�槣ǝ    橼ǝ�橼ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ❽ ❽ 检查更新                                                                                                                                   ❽ ➍ 系统磁盘测试                                                                                                                                  ➍ ➍ 磁盘故障诊断                                                                                                                                  ➍ ⟪ 磁盘元数据测试                                                                                                                                 ⟪ ⟪ 磁盘元数据测试                                                                                                                                 ⟪ ⟪ 目标操作系统测试                                                                                                                                 ⟪ ⠙ 卷内容测试                                                                                                                                  ⠙ ⠙ 启动管理器诊断                                                                                                                                 ⠙ ⠙ 系统启动日志诊断                                                                                                                                 ⠙ ⠩ 事件日志诊断                                                                                                                                  ⠩ ⠩ 内部状态检查                                                                                                                                       ፧�槣ǝ    뭎斧橼ǝ⾭曍橼ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ✾ ✾ 检查更新                                                                                                                                   ✾ ✾ 系统磁盘测试                                                                                                                                  ✾ ❎ 磁盘故障诊断                                                                                                                                  ❎ ➬ 磁盘元数据测试                                                                                                                                 ➬ ➬ 磁盘元数据测试                                                                                                                                 ➬ ➬ 目标操作系统测试                                                                                                                                 ➬ ⟛ 卷内容测试                                                                                                                                  ⟛ ⟛ 启动管理器诊断                                                                                                                                 ⟛ ⟛ 系统启动日志诊断                                                                                                                                 ⟛ ⟪ 事件日志诊断                                                                                                                                  ⟪ ⟪ 内部状态检查                                                                                                                                       ፧�槣ǝ    ᔂỗ橼ǝꥏ⃗橼ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     鼊鼊检查更新                                                                                                                                   鼊鼊系统磁盘测试                                                                                                                                  鼊鼙磁盘故障诊断                                                                                                                                  鼙鼸磁盘元数据测试                                                                                                                                 鼸鼸磁盘元数据测试                                                                                                                                 鼸齈目标操作系统测试                                                                                                                                 齈齈卷内容测试                                                                                                                                  齈齈启动管理器诊断                                                                                                                                 齈齈系统启动日志诊断                                                                                                                                 齈齈事件日志诊断                                                                                                                                  齈齈内部状态检查                                                                                                                                 Ō 齈ꕃ检查已安装的 LCU                                                                                                                                 ፧�槣ǝ    橻ǝ뭦橻ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⷵ ⷵ 检查更新                                                                                                                                   ⷵ ⷵ 系统磁盘测试                                                                                                                                  ⷵ ⸅ 磁盘故障诊断                                                                                                                                  ⸅ ⹓ 磁盘元数据测试                                                                                                                                 ⹓ ⹓ 磁盘元数据测试                                                                                                                                 ⹓ ⹓ 目标操作系统测试                                                                                                                                 ⹓ ⺂ 卷内容测试                                                                                                                                  ⺂ ⺂ 启动管理器诊断                                                                                                                                 ⺂ ⺂ 系统启动日志诊断                                                                                                                                 ⺂ ⺂ 事件日志诊断                                                                                                                                  ⺂ ⺂ 内部状态检查                                                                                                                                       ፧�槣ǝ    표穚橻ǝ逑筻橻ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⿹ ⿹ 检查更新                                                                                                                                   ⿹ ⿹ 系统磁盘测试                                                                                                                                  ⿹ 〈 磁盘故障诊断                                                                                                                                  〈 ぇ 磁盘元数据测试                                                                                                                                 ぇ し 磁盘元数据测试                                                                                                                                 し し 目标操作系统测试                                                                                                                                 し ゅ 卷内容测试                                                                                                                                  ゅ ゅ 启动管理器诊断                                                                                                                                 ゅ ゅ 系统启动日志诊断                                                                                                                                 ゅ ゅ 事件日志诊断                                                                                                                                  ゅ ゅ 内部状态检查                                                                                                                                       ፧�槣ǝ    㪴䯂橻ǝ�䳢橻ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ❭ ❭ 检查更新                                                                                                                                   ❭ ❭ 系统磁盘测试                                                                                                                                  ❭ ❽ 磁盘故障诊断                                                                                                                                  ❽ ➻ 磁盘元数据测试                                                                                                                                 ➻ ⟋ 磁盘元数据测试                                                                                                                                 ⟋ ⟋ 目标操作系统测试                                                                                                                                 ⟋ ⟺ 卷内容测试                                                                                                                                  ⟺ ⟺ 启动管理器诊断                                                                                                                                 ⟺ ⟺ 系统启动日志诊断                                                                                                                                 ⟺ ⟺ 事件日志诊断                                                                                                                                  ⟺ ⟺ 内部状态检查                                                                                                                                       ፧�槣ǝ    䝸䤣橻ǝ힕䩃橻ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ◶ ◶ 检查更新                                                                                                                                   ◶ ◶ 系统磁盘测试                                                                                                                                  ◶ ☆ 磁盘故障诊断                                                                                                                                  ☆ ♔ 磁盘元数据测试                                                                                                                                 ♔ ♔ 磁盘元数据测试                                                                                                                                 ♔ ♔ 目标操作系统测试                                                                                                                                 ♔ ⚃ 卷内容测试                                                                                                                                  ⚃ ⚃ 启动管理器诊断                                                                                                                                 ⚃ ⚃ 系统启动日志诊断                                                                                                                                 ⚃ ⚃ 事件日志诊断                                                                                                                                  ⚃ ⚃ 内部状态检查                                                                                                                                       ፧�槣ǝ    ꌗ�橺ǝ榐橺ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ❎ ❎ 检查更新                                                                                                                                   ❎ ❎ 系统磁盘测试                                                                                                                                  ❎ ❞ 磁盘故障诊断                                                                                                                                  ❞ ➬ 磁盘元数据测试                                                                                                                                 ➬ ➬ 磁盘元数据测试                                                                                                                                 ➬ ➬ 目标操作系统测试                                                                                                                                 ➬ ⟛ 卷内容测试                                                                                                                                  ⟛ ⟛ 启动管理器诊断                                                                                                                                 ⟛ ⟛ 系统启动日志诊断                                                                                                                                 ⟛ ⟛ 事件日志诊断                                                                                                                                  ⟛ ⟛ 内部状态检查                                                                                                                                       ፧�槣ǝ    䪭炀橺ǝ熠橺ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⟺ ⟺ 检查更新                                                                                                                                   ⟺ ⟺ 系统磁盘测试                                                                                                                                  ⟺ ⠊ 磁盘故障诊断                                                                                                                                  ⠊ ⡘ 磁盘元数据测试                                                                                                                                 ⡘ ⡘ 磁盘元数据测试                                                                                                                                 ⡘ ⡘ 目标操作系统测试                                                                                                                                 ⡘ ⢇ 卷内容测试                                                                                                                                  ⢇ ⢇ 启动管理器诊断                                                                                                                                 ⢇ ⢇ 系统启动日志诊断                                                                                                                                 ⢇ ⢇ 事件日志诊断                                                                                                                                  ⢇ ⢇ 内部状态检查                                                                                                                                       ፧�槣ǝ    镩㇞橺ǝ뢤㌈橺ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⟛ ⟛ 检查更新                                                                                                                                   ⟛ ⟛ 系统磁盘测试                                                                                                                                  ⟛ ⟪ 磁盘故障诊断                                                                                                                                  ⟪ ⡈ 磁盘元数据测试                                                                                                                                 ⡈ ⡈ 磁盘元数据测试                                                                                                                                 ⡈ ⡈ 目标操作系统测试                                                                                                                                 ⡈ ⡷ 卷内容测试                                                                                                                                  ⡷ ⡷ 启动管理器诊断                                                                                                                                 ⡷ ⡷ 系统启动日志诊断                                                                                                                                 ⡷ ⢇ 事件日志诊断                                                                                                                                  ⢇ ⢇ 内部状态检查                                                                                                                                       ፧�槣ǝ    ↫০橺ǝଆ橺ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ❭ ❭ 检查更新                                                                                                                                   ❭ ❭ 系统磁盘测试                                                                                                                                  ❭ ❽ 磁盘故障诊断                                                                                                                                  ❽ ➻ 磁盘元数据测试                                                                                                                                 ➻ ⟋ 磁盘元数据测试                                                                                                                                 ⟋ ⟋ 目标操作系统测试                                                                                                                                 ⟋ ⟺ 卷内容测试                                                                                                                                  ⟺ ⟺ 启动管理器诊断                                                                                                                                 ⟺ ⟺ 系统启动日志诊断                                                                                                                                 ⟺ ⟺ 事件日志诊断                                                                                                                                  ⟺ ⟺ 内部状态检查                                                                                                                                       ፧�槣ǝ    螖쉼橹ǝ閁쎟橹ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⡈ ⡈ 检查更新                                                                                                                                   ⡈ ⡈ 系统磁盘测试                                                                                                                                  ⡈ ⡘ 磁盘故障诊断                                                                                                                                  ⡘ ⢖ 磁盘元数据测试                                                                                                                                 ⢖ ⢦ 磁盘元数据测试                                                                                                                                 ⢦ ⢦ 目标操作系统测试                                                                                                                                 ⢦ ⣕ 卷内容测试                                                                                                                                  ⣕ ⣕ 启动管理器诊断                                                                                                                                 ⣕ ⣕ 系统启动日志诊断                                                                                                                                 ⣕ ⣕ 事件日志诊断                                                                                                                                  ⣕ ⣕ 内部状态检查                                                                                                                                       ፧�槣ǝ    웒懚橹ǝ봠拻橹ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ➻ ➻ 检查更新                                                                                                                                   ➻ ➻ 系统磁盘测试                                                                                                                                  ➻ ⟋ 磁盘故障诊断                                                                                                                                  ⟋ ⠙ 磁盘元数据测试                                                                                                                                 ⠙ ⠙ 磁盘元数据测试                                                                                                                                 ⠙ ⠙ 目标操作系统测试                                                                                                                                 ⠙ ⡈ 卷内容测试                                                                                                                                  ⡈ ⡈ 启动管理器诊断                                                                                                                                 ⡈ ⡈ 系统启动日志诊断                                                                                                                                 ⡈ ⡈ 事件日志诊断                                                                                                                                  ⡈ ⡈ 内部状态检查                                                                                                                                       ፧�槣ǝ    땸㇭橸ǝ㑧㏛橸ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     뒹 뒹 检查更新                                                                                                                                   뒹 뒹 系统磁盘测试                                                                                                                                  뒹 듉 磁盘故障诊断                                                                                                                                  듉 듘 磁盘元数据测试                                                                                                                                 듘 듘 磁盘元数据测试                                                                                                                                 듘 듘 目标操作系统测试                                                                                                                                 듘 듘 卷内容测试                                                                                                                                  듘 듘 启动管理器诊断                                                                                                                                 듘 듨 系统启动日志诊断                                                                                                                                 듨 듨 事件日志诊断                                                                                                                                  듨 듨 内部状态检查                                                                                                                                 Ō 듨 몆 检查已安装的 LCU                                                                                                                                 ፧�槣ǝ    毷ᱥ橸ǝ㐸ᶆ橸ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ➜ ➜ 检查更新                                                                                                                                   ➜ ➜ 系统磁盘测试                                                                                                                                  ➜ ➬ 磁盘故障诊断                                                                                                                                  ➬ ⟪ 磁盘元数据测试                                                                                                                                 ⟪ ⟺ 磁盘元数据测试                                                                                                                                 ⟺ ⟺ 目标操作系统测试                                                                                                                                 ⟺ ⠩ 卷内容测试                                                                                                                                  ⠩ ⠩ 启动管理器诊断                                                                                                                                 ⠩ ⠩ 系统启动日志诊断                                                                                                                                 ⠩ ⠩ 事件日志诊断                                                                                                                                  ⠩ ⠩ 内部状态检查                                                                                                                                       ፧�槣ǝ    ࣽ橷ǝ뽕橷ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ❽ ❽ 检查更新                                                                                                                                   ❽ ❽ 系统磁盘测试                                                                                                                                  ❽ ➍ 磁盘故障诊断                                                                                                                                  ➍ ⟛ 磁盘元数据测试                                                                                                                                 ⟛ ⟛ 磁盘元数据测试                                                                                                                                 ⟛ ⟛ 目标操作系统测试                                                                                                                                 ⟛ ⠊ 卷内容测试                                                                                                                                  ⠊ ⠊ 启动管理器诊断                                                                                                                                 ⠊ ⠊ 系统启动日志诊断                                                                                                                                 ⠊ ⠊ 事件日志诊断                                                                                                                                  ⠊ ⠊ 内部状态检查                                                                                                                                       ፧�槣ǝ    憩橶ǝꡧ橶ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     鸤 鸤 检查更新                                                                                                                                   鸤 鸤 系统磁盘测试                                                                                                                                  鸤 鸴 磁盘故障诊断                                                                                                                                  鸴 鹃 磁盘元数据测试                                                                                                                                 鹃 鹃 磁盘元数据测试                                                                                                                                 鹃 鹃 目标操作系统测试                                                                                                                                 鹃 鹃 卷内容测试                                                                                                                                  鹃 鹃 启动管理器诊断                                                                                                                                 鹃 鹃 系统启动日志诊断                                                                                                                                 鹃 鹓 事件日志诊断                                                                                                                                  鹓 鹓 内部状态检查                                                                                                                                 Ō 鹓 ꏡ 检查已安装的 LCU                                                                                                                                 ፧�槣ǝ    ᚹ橶ǝﷰ橶ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⟪ ⟪ 检查更新                                                                                                                                   ⟪ ⟪ 系统磁盘测试                                                                                                                                  ⟪ ⟺ 磁盘故障诊断                                                                                                                                  ⟺ ⡈ 磁盘元数据测试                                                                                                                                 ⡈ ⡈ 磁盘元数据测试                                                                                                                                 ⡈ ⡈ 目标操作系统测试                                                                                                                                 ⡈ ⡷ 卷内容测试                                                                                                                                  ⡷ ⡷ 启动管理器诊断                                                                                                                                 ⡷ ⡷ 系统启动日志诊断                                                                                                                                 ⡷ ⡷ 事件日志诊断                                                                                                                                  ⡷ ⡷ 内部状态检查                                                                                                                                       ፧�槣ǝ    ਤ띵橜ǝ뢕橜ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⢇ ⢇ 检查更新                                                                                                                                   ⢇ ⢇ 系统磁盘测试                                                                                                                                  ⢇ ⢖ 磁盘故障诊断                                                                                                                                  ⢖ ⣕ 磁盘元数据测试                                                                                                                                 ⣕ ⣤ 磁盘元数据测试                                                                                                                                 ⣤ ⣤ 目标操作系统测试                                                                                                                                 ⣤ ⤓ 卷内容测试                                                                                                                                  ⤓ ⤓ 启动管理器诊断                                                                                                                                 ⤓ ⤓ 系统启动日志诊断                                                                                                                                 ⤓ ⤓ 事件日志诊断                                                                                                                                  ⤓ ⤓ 内部状态检查                                                                                                                                       ፧�槣ǝ    싰ᘴ樒ǝ㕆᝟樒ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ❭ ❭ 检查更新                                                                                                                                   ❭ ❭ 系统磁盘测试                                                                                                                                  ❭ ❽ 磁盘故障诊断                                                                                                                                  ❽ ⟪ 磁盘元数据测试                                                                                                                                 ⟪ ⟪ 磁盘元数据测试                                                                                                                                 ⟪ ⟪ 目标操作系统测试                                                                                                                                 ⟪ ⠙ 卷内容测试                                                                                                                                  ⠙ ⠙ 启动管理器诊断                                                                                                                                 ⠙ ⠙ 系统启动日志诊断                                                                                                                                 ⠙ ⠩ 事件日志诊断                                                                                                                                  ⠩ ⠩ 内部状态检查                                                                                                                                       ፧�槣ǝ    ﲛ닂樑ǝ돣樑ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⠊ ⠊ 检查更新                                                                                                                                   ⠊ ⠊ 系统磁盘测试                                                                                                                                  ⠊ ⠙ 磁盘故障诊断                                                                                                                                  ⠙ ⡧ 磁盘元数据测试                                                                                                                                 ⡧ ⡧ 磁盘元数据测试                                                                                                                                 ⡧ ⡧ 目标操作系统测试                                                                                                                                 ⡧ ⢇ 卷内容测试                                                                                                                                  ⢇ ⢇ 启动管理器诊断                                                                                                                                 ⢇ ⢇ 系统启动日志诊断                                                                                                                                 ⢇ ⢖ 事件日志诊断                                                                                                                                  ⢖ ⢖ 内部状态检查                                                                                                                                       ፧�槣ǝ    ᵋ樎ǝ膕Ṭ樎ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ✀ ✀ 检查更新                                                                                                                                   ✀ ✀ 系统磁盘测试                                                                                                                                  ✀ ✐ 磁盘故障诊断                                                                                                                                  ✐ ❞ 磁盘元数据测试                                                                                                                                 ❞ ❞ 磁盘元数据测试                                                                                                                                 ❞ ❞ 目标操作系统测试                                                                                                                                 ❞ ❽ 卷内容测试                                                                                                                                  ❽ ❽ 启动管理器诊断                                                                                                                                 ❽ ❽ 系统启动日志诊断                                                                                                                                 ❽ ➍ 事件日志诊断                                                                                                                                  ➍ ➍ 内部状态检查                                                                                                                                       ፧�槣ǝ    懋ㄝ樌ǝ崒㉀樌ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⠊ ⠊ 检查更新                                                                                                                                   ⠊ ⠊ 系统磁盘测试                                                                                                                                  ⠊ ⠙ 磁盘故障诊断                                                                                                                                  ⠙ ⡷ 磁盘元数据测试                                                                                                                                 ⡷ ⡷ 磁盘元数据测试                                                                                                                                 ⡷ ⡷ 目标操作系统测试                                                                                                                                 ⡷ ⢦ 卷内容测试                                                                                                                                  ⢦ ⢦ 启动管理器诊断                                                                                                                                 ⢦ ⢦ 系统启动日志诊断                                                                                                                                 ⢦ ⢦ 事件日志诊断                                                                                                                                  ⢦ ⢦ 内部状态检查                                                                                                                                       ፧�槣ǝ    鏪ꕄ樋ǝ⻨Ꜳ樋ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     搙 搙 检查更新                                                                                                                                   搙 搙 系统磁盘测试                                                                                                                                  搙 搨 磁盘故障诊断                                                                                                                                  搨 搸 磁盘元数据测试                                                                                                                                 搸 搸 磁盘元数据测试                                                                                                                                 搸 搸 目标操作系统测试                                                                                                                                 搸 搸 卷内容测试                                                                                                                                  搸 搸 启动管理器诊断                                                                                                                                 搸 搸 系统启动日志诊断                                                                                                                                 搸 搸 事件日志诊断                                                                                                                                  搸 摇 内部状态检查                                                                                                                                 Ō 摇 槥 检查已安装的 LCU                                                                                                                                 ፧�槣ǝ    ྷ鰡樋ǝꐑ鵁樋ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⠸ ⠸ 检查更新                                                                                                                                   ⠸ ⠸ 系统磁盘测试                                                                                                                                  ⠸ ⡈ 磁盘故障诊断                                                                                                                                  ⡈ ⢖ 磁盘元数据测试                                                                                                                                 ⢖ ⢖ 磁盘元数据测试                                                                                                                                 ⢖ ⢖ 目标操作系统测试                                                                                                                                 ⢖ ⢵ 卷内容测试                                                                                                                                  ⢵ ⢵ 启动管理器诊断                                                                                                                                 ⢵ ⢵ 系统启动日志诊断                                                                                                                                 ⢵ ⣅ 事件日志诊断                                                                                                                                  ⣅ ⣅ 内部状态检查                                                                                                                                       ፧�槣ǝ    貺床樋ǝ襘徭樋ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ✀ ✀ 检查更新                                                                                                                                   ✀ ✀ 系统磁盘测试                                                                                                                                  ✀ ✐ 磁盘故障诊断                                                                                                                                  ✐ ❞ 磁盘元数据测试                                                                                                                                 ❞ ❞ 磁盘元数据测试                                                                                                                                 ❞ ❞ 目标操作系统测试                                                                                                                                 ❞ ❽ 卷内容测试                                                                                                                                  ❽ ❽ 启动管理器诊断                                                                                                                                 ❽ ❽ 系统启动日志诊断                                                                                                                                 ❽ ➍ 事件日志诊断                                                                                                                                  ➍ ➍ 内部状态检查                                                                                                                                       ፧�槣ǝ    ꝱㆻ樋ǝⶭ㎩樋ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     瑕 瑕 检查更新                                                                                                                                   瑕 瑕 系统磁盘测试                                                                                                                                  瑕 瑤 磁盘故障诊断                                                                                                                                  瑤 瑴 磁盘元数据测试                                                                                                                                 瑴 瑴 磁盘元数据测试                                                                                                                                 瑴 瑴 目标操作系统测试                                                                                                                                 瑴 瑴 卷内容测试                                                                                                                                  瑴 瑴 启动管理器诊断                                                                                                                                 瑴 璄 系统启动日志诊断                                                                                                                                 璄 璄 事件日志诊断                                                                                                                                  璄 璄 内部状态检查                                                                                                                                 Ō 璄 稡 检查已安装的 LCU                                                                                                                                 ፧�槣ǝ    ☂樋ǝ껭✣樋ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ➍ ➍ 检查更新                                                                                                                                   ➍ ➍ 系统磁盘测试                                                                                                                                  ➍ ➜ 磁盘故障诊断                                                                                                                                  ➜ ⟛ 磁盘元数据测试                                                                                                                                 ⟛ ⟪ 磁盘元数据测试                                                                                                                                 ⟪ ⟪ 目标操作系统测试                                                                                                                                 ⟪ ⠊ 卷内容测试                                                                                                                                  ⠊ ⠊ 启动管理器诊断                                                                                                                                 ⠊ ⠊ 系统启动日志诊断                                                                                                                                 ⠊ ⠙ 事件日志诊断                                                                                                                                  ⠙ ⠙ 内部状态检查                                                                                                                                       ፧�槣ǝ    䞦樉ǝ筋䣇樉ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⵉ ⵉ 检查更新                                                                                                                                   ⵉ ⵉ 系统磁盘测试                                                                                                                                  ⵉ ⵙ 磁盘故障诊断                                                                                                                                  ⵙ ⶧ 磁盘元数据测试                                                                                                                                 ⶧ ⶧ 磁盘元数据测试                                                                                                                                 ⶧ ⶧ 目标操作系统测试                                                                                                                                 ⶧ ⷆ 卷内容测试                                                                                                                                  ⷆ ⷆ 启动管理器诊断                                                                                                                                 ⷆ ⷆ 系统启动日志诊断                                                                                                                                 ⷆ ⷖ 事件日志诊断                                                                                                                                  ⷖ ⷖ 内部状态检查                                                                                                                                       ፧�槣ǝ    밪ᄺ樉ǝ힞ቝ樉ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⠸ ⠸ 检查更新                                                                                                                                   ⠸ ⠸ 系统磁盘测试                                                                                                                                  ⠸ ⡈ 磁盘故障诊断                                                                                                                                  ⡈ ⢖ 磁盘元数据测试                                                                                                                                 ⢖ ⢖ 磁盘元数据测试                                                                                                                                 ⢖ ⢖ 目标操作系统测试                                                                                                                                 ⢖ ⢵ 卷内容测试                                                                                                                                  ⢵ ⢵ 启动管理器诊断                                                                                                                                 ⢵ ⢵ 系统启动日志诊断                                                                                                                                 ⢵ ⣅ 事件日志诊断                                                                                                                                  ⣅ ⣅ 内部状态检查                                                                                                                                       ፧�槣ǝ    韂싚樈ǝ�쏽樈ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ☵ ☵ 检查更新                                                                                                                                   ☵ ☵ 系统磁盘测试                                                                                                                                  ☵ ♄ 磁盘故障诊断                                                                                                                                  ♄ ⚢ 磁盘元数据测试                                                                                                                                 ⚢ ⚢ 磁盘元数据测试                                                                                                                                 ⚢ ⚢ 目标操作系统测试                                                                                                                                 ⚢ ⛑ 卷内容测试                                                                                                                                  ⛑ ⛑ 启动管理器诊断                                                                                                                                 ⛑ ⛑ 系统启动日志诊断                                                                                                                                 ⛑ ⛑ 事件日志诊断                                                                                                                                  ⛑ ⛑ 内部状态检查                                                                                                                                       ፧�槣ǝ    閶樈ǝ뾬雗樈ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ❎ ❎ 检查更新                                                                                                                                   ❎ ❎ 系统磁盘测试                                                                                                                                  ❎ ❞ 磁盘故障诊断                                                                                                                                  ❞ ➬ 磁盘元数据测试                                                                                                                                 ➬ ➬ 磁盘元数据测试                                                                                                                                 ➬ ➬ 目标操作系统测试                                                                                                                                 ➬ ⟋ 卷内容测试                                                                                                                                  ⟋ ⟋ 启动管理器诊断                                                                                                                                 ⟋ ⟋ 系统启动日志诊断                                                                                                                                 ⟋ ⟛ 事件日志诊断                                                                                                                                  ⟛ ⟛ 内部状态检查                                                                                                                                       ፧�槣ǝ    븇禥樈ǝ繅竆樈ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⛰ ⛰ 检查更新                                                                                                                                   ⛰ ⛰ 系统磁盘测试                                                                                                                                  ⛰ ✀ 磁盘故障诊断                                                                                                                                  ✀ ❎ 磁盘元数据测试                                                                                                                                 ❎ ❎ 磁盘元数据测试                                                                                                                                 ❎ ❎ 目标操作系统测试                                                                                                                                 ❎ ❭ 卷内容测试                                                                                                                                  ❭ ❭ 启动管理器诊断                                                                                                                                 ❭ ❭ 系统启动日志诊断                                                                                                                                 ❭ ❽ 事件日志诊断                                                                                                                                  ❽ ❽ 内部状态检查                                                                                                                                       ፧�槣ǝ    꼰값樇ǝ펧긕樇ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ✾ ✾ 检查更新                                                                                                                                   ✾ ✾ 系统磁盘测试                                                                                                                                  ✾ ❎ 磁盘故障诊断                                                                                                                                  ❎ ➍ 磁盘元数据测试                                                                                                                                 ➍ ➜ 磁盘元数据测试                                                                                                                                 ➜ ➜ 目标操作系统测试                                                                                                                                 ➜ ➻ 卷内容测试                                                                                                                                  ➻ ➻ 启动管理器诊断                                                                                                                                 ➻ ➻ 系统启动日志诊断                                                                                                                                 ➻ ⟋ 事件日志诊断                                                                                                                                  ⟋ ⟋ 内部状态检查                                                                                                                                 Ō ⟋ ⶧ 检查已安装的 LCU                                                                                                                                 ፧�槣ǝ    衜樇ǝ䇅詠樇ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ➬ ➬ 检查更新                                                                                                                                   ➬ ➬ 系统磁盘测试                                                                                                                                  ➬ ➻ 磁盘故障诊断                                                                                                                                  ➻ ⠊ 磁盘元数据测试                                                                                                                                 ⠊ ⠊ 磁盘元数据测试                                                                                                                                 ⠊ ⠊ 目标操作系统测试                                                                                                                                 ⠊ ⠩ 卷内容测试                                                                                                                                  ⠩ ⠩ 启动管理器诊断                                                                                                                                 ⠩ ⠩ 系统启动日志诊断                                                                                                                                 ⠩ ⠸ 事件日志诊断                                                                                                                                  ⠸ ⠸ 内部状态检查                                                                                                                                 Ō ⠸ ⸅ 检查已安装的 LCU                                                                                                                                 ፧�槣ǝ    糵侾樇ǝ꺠凁樇ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ➬ ➬ 检查更新                                                                                                                                   ➬ ➬ 系统磁盘测试                                                                                                                                  ➬ ➻ 磁盘故障诊断                                                                                                                                  ➻ ⠊ 磁盘元数据测试                                                                                                                                 ⠊ ⠊ 磁盘元数据测试                                                                                                                                 ⠊ ⠊ 目标操作系统测试                                                                                                                                 ⠊ ⠩ 卷内容测试                                                                                                                                  ⠩ ⠩ 启动管理器诊断                                                                                                                                 ⠩ ⠩ 系统启动日志诊断                                                                                                                                 ⠩ ⠸ 事件日志诊断                                                                                                                                  ⠸ ⠸ 内部状态检查                                                                                                                                 Ō ⠸ ⸅ 检查已安装的 LCU                                                                                                                                 ፧�槣ǝ    訷槤ǝㄩ谻槤ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ⚓ ⚓ 检查更新                                                                                                                                   ⚓ ⚓ 系统磁盘测试                                                                                                                                  ⚓ ⚢ 磁盘故障诊断                                                                                                                                  ⚢ ⛰ 磁盘元数据测试                                                                                                                                 ⛰ ⛰ 磁盘元数据测试                                                                                                                                 ⛰ ⛰ 目标操作系统测试                                                                                                                                 ⛰ ✐ 卷内容测试                                                                                                                                  ✐ ✐ 启动管理器诊断                                                                                                                                 ✐ ✐ 系统启动日志诊断                                                                                                                                 ✐ ✟ 事件日志诊断                                                                                                                                  ✟ ✟ 内部状态检查                                                                                                                                 Ō ✟ ⳬ 检查已安装的 LCU                                                                                                                                 ፧�槣ǝ    ꀏ勮槤ǝ솂唄槤ǝ\Device\Harddisk0                                                                                                                          C:\Windows                                                                                                                             \\?\GLOBALROOT\Device\HarddiskVolume3\                                                                                                                                                                                                                                                 ፌ䖸ᇭ疿覭㊒쑠     ➜ ➜ 检查更新                                                                                                                                   ➜ ➜ 系统磁盘测试                                                                                                                                  ➜ ➬ 磁盘故障诊断                                                                                                                                  ➬ ⟪ 磁盘元数据测试                                                                                                                                 ⟪ ⟺ 磁盘元数据测试                                                                                                                                 ⟺ ⟺ 目标操作系统测试                                                                                                                                 ⟺ ⠙ 卷内容测试                                                                                                                                  ⠙ ⠙ 启动管理器诊断                                                                                                                                 ⠙ ⠙ 系统启动日志诊断                                                                                                                                 ⠙ ⡈ 事件日志诊断                                                                                                                                  ⡈ ⡈ 内部状态检查                                                                                                                                 Ō ⡈ ⹣ 检查已安装的 LCU                                                                                                                             
>
> SrtTrail.txt
>
> 启动修复诊断和修复日志
>
> \---------------------------
>
> 上一次成功启动的时间:‎2026/‎11/‎1 9:32:11 (GMT)
>
> 尝试修复次数:64
>
> 会话详细信息
>
> \---------------------------
>
> 系统磁盘 = \Device\Harddisk0
>
> Windows 目录 = C:\Windows
>
> 自动检查运行 = 0
>
> 根本原因数 = 0
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 检查更新
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 系统磁盘测试
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 磁盘故障诊断
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 磁盘元数据测试
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 78 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 磁盘元数据测试
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 目标操作系统测试
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 卷内容测试
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 47 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 启动管理器诊断
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 系统启动日志诊断
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 事件日志诊断
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 内部状态检查
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 检查已安装的 LCU
>
> 结果: 成功完成。错误代码 = 0x43
>
> 使用的时间 = 5671 毫秒
>
> \---------------------------
>
> \---------------------------
>
> 会话详细信息
>
> \---------------------------
>
> 系统磁盘 = \Device\Harddisk0
>
> Windows 目录 = C:\Windows
>
> 自动检查运行 = 0
>
> 根本原因数 = 1
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 检查更新
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 系统磁盘测试
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 磁盘故障诊断
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 15 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 磁盘元数据测试
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 78 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 磁盘元数据测试
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 目标操作系统测试
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 卷内容测试
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 47 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 启动管理器诊断
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 系统启动日志诊断
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 事件日志诊断
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 内部状态检查
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 找到的根本原因: 
>
> \---------------------------
>
> 启动修复已经尝试多次，但仍无法确定问题的原因。
>
> \---------------------------
>
> \---------------------------
>
> 会话详细信息
>
> \---------------------------
>
> 系统磁盘 = \Device\Harddisk0
>
> Windows 目录 = C:\Windows
>
> 自动检查运行 = 0
>
> 根本原因数 = 0
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 检查更新
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 系统磁盘测试
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 磁盘故障诊断
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 16 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 磁盘元数据测试
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 16 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 磁盘元数据测试
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 目标操作系统测试
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 卷内容测试
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 15 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 启动管理器诊断
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 系统启动日志诊断
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 事件日志诊断
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 内部状态检查
>
> 结果: 成功完成。错误代码 = 0x0
>
> 使用的时间 = 0 毫秒
>
> 执行的测试: 
>
> \---------------------------
>
> 名称: 检查已安装的 LCU
>
> 结果: 成功完成。错误代码 = 0x14c
>
> 使用的时间 = 1469 毫秒
>
> \---------------------------
>
> \---------------------------
>
>  ![2789cbf5-4bfc-4ac7-a04b-f09917bddb5d](.\2789cbf5-4bfc-4ac7-a04b-f09917bddb5d.jpg)![f9ab15a4-f2ac-449e-9e3b-89430c599fab](.\f9ab15a4-f2ac-449e-9e3b-89430c599fab.jpg)![960c4e13-0baf-4a1b-9716-f7566ef398ff](.\960c4e13-0baf-4a1b-9716-f7566ef398ff.jpg)![d9269603-61d9-4c8e-b99a-c7eabb08067c](.\d9269603-61d9-4c8e-b99a-c7eabb08067c.jpg)![1a1abe56-a882-44ec-ae6e-7b3b26f7d6ac](.\1a1abe56-a882-44ec-ae6e-7b3b26f7d6ac.jpg)![c2e41fc6-0cd7-4e32-a0a0-7ce26591579b](.\c2e41fc6-0cd7-4e32-a0a0-7ce26591579b.jpg)

结合你提供的两份日志与最新操作截图，根本原因已经彻底明确：

### 核心病根解析

1. **DISM 离线加载失败的致命报错**：

   在 `DISMRepairLogFile.txt` 中：

   > `Failed to load offline ... SYSTEM hive ... [HRESULT = 0xd0000043 - NTSTATUS Error]`

   NTSTATUS `0xC0000043`（即 `STATUS_SHARING_VIOLATION`，共享冲突）。这说明当 DISM 或系统自动修复尝试挂载并修复 `C:\Windows\System32\config\SYSTEM` 时，该文件被锁死、被系统底层标记异常，或内部 B-Tree 索引发生了逻辑死锁，导致 DISM 根本无法对其执行任何包检查与更新替换。

2. **LCU（最新累积更新）安装崩溃**：

   `SrtTrail.txt` 中启动修复执行到最后一步：

   > `名称: 检查已安装的 LCU，结果: 成功完成。错误代码 = 0x43 / 0x14c`

   这正是 Windows Update 在后台执行驱动或累积更新打补丁时，系统意外断电、强行关机或崩溃，导致新的驱动/服务配置刚写入一半，原有的注册表控制集（ControlSet）状态冲突，诱发了经典的 `BAD_SYSTEM_CONFIG_INFO`。

3. **为什么引导修复无效**： 你执行的 `bcdboot` 和 EFI 启动项重建没有任何问题，EFI 引导文件是完全完好的。开机弹出的蓝屏/恢复界面 `0xc0000001`，是引导管理器把控制权移交给 Windows 内核（`ntoskrnl.exe`）后，内核在解析 `SYSTEM` 注册表单元时因损坏直接中断抛出的异常。   

由于 BitLocker 已经解密完成，且在 PE 下各盘符数据均能直接访问，建议按照以下两种方案处理：

### 方案 A：尝试回滚“挂起的更新”（免重装的唯一机会）

既然是 LCU 挂起导致的注册表死锁，可以在 PE 命令提示符中执行以下命令，强制清理挂起的更新操作：

1. **清理挂起的更新事务**：

   DOS

   ```
   dism /Image:C:\ /Cleanup-Image /RevertPendingActions
   ```

   *注意：如果执行成功，它会自动撤销那次失败的累积更新，修复注册表中的 Pending 标记。*

2. **检查并卸载最近安装的更新包（如果步骤 1 仍无法开机）**：

   查询最近安装的更新补丁名称：

   DOS

   ```
   dism /Image:C:\ /Get-Packages /Format:Table
   ```

   找到状态为 `Install Pending`（安装挂起）或最近日期安装的更新包（形如 `Package_for_RollupFix~...`），记下完整的“程序包标识”，执行卸载：

   DOS

   ```
   dism /Image:C:\ /Remove-Package /PackageName:<完整的更新包标识>
   ```

3. **测试 ControlSet 备用控制集（系统注册表自救）**： 虽然你的 `SYSTEM` 文件通过命令 `reg load HKLM\TEMP C:\Windows\System32\config\SYSTEM` 提示成功，说明文件头还在，但里面的当前启动配置很可能是错乱的。 在 PE 中打开注册表编辑器 `regedit`：   

   - 选中 `HKEY_LOCAL_MACHINE`，点击菜单栏“文件” -> “加载配置单元”，选中 `C:\Windows\System32\config\SYSTEM`，命名为 `OFFLINE_SYS`。
   - 展开 `OFFLINE_SYS\Select`，查看右侧的几个数值：
     - `Current`：当前使用的配置集编号（通常是 1，对应 `ControlSet001`）。
     - `LastKnownGood`：上一次成功启动的配置集编号（通常是 2）。
     - `Failed`：失败的配置集编号。
   - 如果 `LastKnownGood` 存在（例如值为 2），且 `OFFLINE_SYS` 下存在 `ControlSet002`，可以将 `Current` 的数值修改为 `LastKnownGood` 的数值（例如将 1 改为 2）。
   - 选中 `OFFLINE_SYS`，点击“文件” -> “卸载配置单元”。
   - 重启电脑尝试开机。

### 方案 B：直接在 PE 内快速覆盖安装（最彻底、最稳妥）

如果上述 DISM 撤销更新命令依旧报 `0xd0000043` 或提示拒绝访问，说明该注册表文件的物理块/内部逻辑已经不可逆损坏。由于没有还原点和备份，无法凭空推导硬件驱动配置。**最节省时间且 100% 解决问题的方法是直接重装 C 盘**。

**操作步骤**：

1. **备份 C 盘个人数据**：

   在 PE 中打开资源管理器，将 `C:\Users\<你的用户名>` 下的 **桌面、下载、文档、微信记录（Documents\WeChat Files）** 等拷贝到 D 盘或外接移动硬盘。

2. **使用 WinNTSetup 安装**：

   - 打开 PE 桌面上的 **WinNTSetup** 工具。
   - **安装源**：选择 Windows 11 安装镜像（ISO 挂载后的 `sources\install.wim`）。
   - **引导驱动器**：选择 `S:`（即你前面挂载的 260MB FAT32 ESP 分区）。   
   - **安装驱动器**：选择 `C:`。   
   - 点击右下角“安装”，勾选“格式化安装驱动器”（确保重要数据已拷出）。

3. 安装完成后直接拔掉 U 盘重启，几分钟内即可进入全新的正常 Windows 11 系统。

> 2026-11-02 15:37:38, Info         DISM  PID=1964 TID=1960 Scratch directory set to 'X:\windows\TEMP\'. - CDISMManager::put_ScratchDir
>
> 2026-11-02 15:37:38, Info         DISM  PID=1964 TID=1960 DismCore.dll version: 10.0.22621.1 - CDISMManager::FinalConstruct
>
> 2026-11-02 15:37:38, Info         DISM  Initialized Panther logging at X:\windows\Logs\DISM\dism.log
>
> 2026-11-02 15:37:38, Warning        DISM  PID=1964 TID=1960 Failed to archive the log file. Continuing with existing log file. - CDISMManager::CreateLocalImageSession(hr:0x80070002)
>
> 2026-11-02 15:37:38, Info         DISM  PID=1964 TID=1960 Successfully loaded the ImageSession at "X:\Windows\System32\Dism" - CDISMManager::LoadLocalImageSession
>
> 2026-11-02 15:37:38, Info         DISM  Initialized Panther logging at X:\windows\Logs\DISM\dism.log
>
> 2026-11-02 15:37:38, Info         DISM  DISM Provider Store: PID=1964 TID=1960 Found and Initialized the DISM Logger. - CDISMProviderStore::Internal_InitializeLogger
>
> 2026-11-02 15:37:38, Info         DISM  Initialized Panther logging at X:\windows\Logs\DISM\dism.log
>
> 2026-11-02 15:37:38, Info         DISM  DISM Manager: PID=1964 TID=1960 Successfully created the local image session and provider store. - CDISMManager::CreateLocalImageSession
>
> 2026-11-02 15:37:38, Info         DISM  DISM.EXE: 
>
> 2026-11-02 15:37:38, Info         DISM  DISM.EXE: <----- Starting Dism.exe session ----->
>
> 2026-11-02 15:37:38, Info         DISM  DISM.EXE: 
>
> 2026-11-02 15:37:38, Info         DISM  DISM.EXE: Host machine information: OS Version=10.0.22621, Running architecture=amd64, Number of processors=20
>
> 2026-11-02 15:37:38, Info         DISM  DISM.EXE: Dism.exe version: 10.0.22621.1
>
> 2026-11-02 15:37:38, Info         DISM  DISM.EXE: Executing command line: dism /Image:C\ /Cleanup-Image /RevertPendingActions
>
> 2026-11-02 15:37:38, Info         DISM  DISM FFU Provider: PID=1964 TID=1960 [X:\Windows\System32\C\] is not recognized by the DISM FFU provider. - CFfuImage::Initialize
>
> 2026-11-02 15:37:38, Info         DISM  DISM Imaging Provider: PID=1964 TID=1960 The provider FfuManager does not support CreateDismImage on X:\Windows\System32\C\ - CGenericImagingManager::CreateDismImage
>
> 2026-11-02 15:37:38, Info         DISM  DISM VHD Provider: PID=1964 TID=1960 [X:\Windows\System32\C\] is not recognized by the DISM VHD provider. - CVhdImage::Initialize
>
> 2026-11-02 15:37:38, Info         DISM  DISM Imaging Provider: PID=1964 TID=1960 The provider VHDManager does not support CreateDismImage on X:\Windows\System32\C\ - CGenericImagingManager::CreateDismImage
>
> 2026-11-02 15:37:38, Info         DISM  DISM WIM Provider: PID=1964 TID=1960 [X:\Windows\System32\C\] does not exist and is not a WIM mount point. - CWimMountedImageInfo::Initialize
>
> 2026-11-02 15:37:38, Info         DISM  DISM Imaging Provider: PID=1964 TID=1960 The provider WimManager does not support CreateDismImage on X:\Windows\System32\C\ - CGenericImagingManager::CreateDismImage
>
> 2026-11-02 15:37:38, Info         DISM  DISM Imaging Provider: PID=1964 TID=1960 No imaging provider supported CreateDismImage for this path - CGenericImagingManager::CreateDismImage
>
> 2026-11-02 15:37:38, Info         DISM  DISM WIM Provider: PID=1964 TID=1960 [X:\Windows\System32\C\] does not exist and is not a WIM mount point. - CWimMountedImageInfo::Initialize
>
> 2026-11-02 15:37:38, Error         DISM  FolderManager: PID=1964 onecore\base\ntsetup\opktools\dism\providers\folderprovider\dll\FolderImage.h:196 - CFolderImage::CreateFolderImage(hr:0x80070032)
>
> 2026-11-02 15:37:38, Info         DISM  DISM FFU Provider: PID=1964 TID=1960 [X:\Windows\System32\C\] is not recognized by the DISM FFU provider. - CFfuImage::Initialize
>
> 2026-11-02 15:37:38, Info         DISM  DISM VHD Provider: PID=1964 TID=1960 [X:\Windows\System32\C\] is not recognized by the DISM VHD provider. - CVhdImage::Initialize
>
> 2026-11-02 15:37:38, Error         DISM  DISM.EXE: Failed to access the image folder or image's windows folder.
>
> 2026-11-02 15:37:38, Info         DISM  DISM.EXE: Image session has been closed. Reboot required=no.
>
> 2026-11-02 15:37:38, Info         DISM  DISM.EXE: 
>
> 2026-11-02 15:37:38, Info         DISM  DISM.EXE: <----- Ending Dism.exe session ----->
>
> 2026-11-02 15:37:38, Info         DISM  DISM.EXE: 
>
> 2026-11-02 15:38:12, Info         DISM  PID=1772 TID=1764 Scratch directory set to 'X:\windows\TEMP\'. - CDISMManager::put_ScratchDir
>
> 2026-11-02 15:38:12, Info         DISM  PID=1772 TID=1764 DismCore.dll version: 10.0.22621.1 - CDISMManager::FinalConstruct
>
> 2026-11-02 15:38:12, Info         DISM  Initialized Panther logging at X:\windows\Logs\DISM\dism.log
>
> 2026-11-02 15:38:12, Info         DISM  PID=1772 TID=1764 Successfully loaded the ImageSession at "X:\Windows\System32\Dism" - CDISMManager::LoadLocalImageSession
>
> 2026-11-02 15:38:12, Info         DISM  Initialized Panther logging at X:\windows\Logs\DISM\dism.log
>
> 2026-11-02 15:38:12, Info         DISM  DISM Provider Store: PID=1772 TID=1764 Found and Initialized the DISM Logger. - CDISMProviderStore::Internal_InitializeLogger
>
> 2026-11-02 15:38:12, Info         DISM  Initialized Panther logging at X:\windows\Logs\DISM\dism.log
>
> 2026-11-02 15:38:12, Info         DISM  DISM Manager: PID=1772 TID=1764 Successfully created the local image session and provider store. - CDISMManager::CreateLocalImageSession
>
> 2026-11-02 15:38:12, Info         DISM  DISM.EXE: 
>
> 2026-11-02 15:38:12, Info         DISM  DISM.EXE: <----- Starting Dism.exe session ----->
>
> 2026-11-02 15:38:12, Info         DISM  DISM.EXE: 
>
> 2026-11-02 15:38:12, Info         DISM  DISM.EXE: Host machine information: OS Version=10.0.22621, Running architecture=amd64, Number of processors=20
>
> 2026-11-02 15:38:12, Info         DISM  DISM.EXE: Dism.exe version: 10.0.22621.1
>
> 2026-11-02 15:38:12, Info         DISM  DISM.EXE: Executing command line: dism /Image:C:\ /Cleanup-Image /RevertPendingActions
>
> 2026-11-02 15:38:12, Info         DISM  DISM FFU Provider: PID=1772 TID=1764 [C:\] is not recognized by the DISM FFU provider. - CFfuImage::Initialize
>
> 2026-11-02 15:38:12, Info         DISM  DISM Imaging Provider: PID=1772 TID=1764 The provider FfuManager does not support CreateDismImage on C:\ - CGenericImagingManager::CreateDismImage
>
> 2026-11-02 15:38:12, Info         DISM  DISM VHD Provider: PID=1772 TID=1764 [C:\] is not recognized by the DISM VHD provider. - CVhdImage::Initialize
>
> 2026-11-02 15:38:12, Info         DISM  DISM Imaging Provider: PID=1772 TID=1764 The provider VHDManager does not support CreateDismImage on C:\ - CGenericImagingManager::CreateDismImage
>
> [1772.1764] [0x80070002] FIOReadFileIntoBuffer:(1456): 系统找不到指定的文件。
>
> [1772.1764] [0xc142011c] UnmarshallImageHandleFromDirectory:(641)
>
> [1772.1764] [0xc142011c] WIMGetMountedImageHandle:(2910)
>
> 2026-11-02 15:38:12, Info         DISM  DISM WIM Provider: PID=1772 TID=1764 [C:\] is not a WIM mount point. - CWimMountedImageInfo::Initialize
>
> 2026-11-02 15:38:12, Info         DISM  DISM Imaging Provider: PID=1772 TID=1764 The provider WimManager does not support CreateDismImage on C:\ - CGenericImagingManager::CreateDismImage
>
> 2026-11-02 15:38:12, Info         DISM  DISM Imaging Provider: PID=1772 TID=1764 No imaging provider supported CreateDismImage for this path - CGenericImagingManager::CreateDismImage
>
> [1772.1764] [0x80070002] FIOReadFileIntoBuffer:(1456): 系统找不到指定的文件。
>
> [1772.1764] [0xc142011c] UnmarshallImageHandleFromDirectory:(641)
>
> [1772.1764] [0xc142011c] WIMGetMountedImageHandle:(2910)
>
> 2026-11-02 15:38:12, Info         DISM  DISM WIM Provider: PID=1772 TID=1764 [C:\] is not a WIM mount point. - CWimMountedImageInfo::Initialize
>
> 2026-11-02 15:38:12, Info         DISM  DISM FFU Provider: PID=1772 TID=1764 [C:\] is not recognized by the DISM FFU provider. - CFfuImage::Initialize
>
> 2026-11-02 15:38:12, Info         DISM  DISM VHD Provider: PID=1772 TID=1764 [C:\] is not recognized by the DISM VHD provider. - CVhdImage::Initialize
>
> 2026-11-02 15:38:12, Info         DISM  DISM Manager: PID=1772 TID=1764 physical location path: C:\ - CDISMManager::CreateImageSession
>
> 2026-11-02 15:38:12, Info         DISM  DISM Manager: PID=1772 TID=1764 Event name for current DISM session is Global\__?_Volume{9508512a-c61f-41bc-bae8-64b14d710d06}__2062103243_65536_58365 - CDISMManager::CheckSessionAndLock
>
> 2026-11-02 15:38:12, Info         DISM  DISM Manager: PID=1772 TID=1764 Create session event 0x258 for current DISM session and event name is Global\__?_Volume{9508512a-c61f-41bc-bae8-64b14d710d06}__2062103243_65536_58365 - CDISMManager::CheckSessionAndLock
>
> 2026-11-02 15:38:12, Info         DISM  DISM Manager: PID=1772 TID=1764 Copying DISM from "C:\Windows\System32\Dism" - CDISMManager::CreateImageSessionFromLocation
>
> 2026-11-02 15:38:12, Info         DISM  DISM Manager: PID=1772 TID=1764 Successfully loaded the ImageSession at "X:\windows\TEMP\D00F2BB2-3241-4675-9DD2-AC5D9C5D7F07" - CDISMManager::LoadRemoteImageSession
>
> 2026-11-02 15:38:12, Info         DISM  DISM Image Session: PID=1224 TID=1388 Instantiating the Provider Store. - CDISMImageSession::get_ProviderStore
>
> 2026-11-02 15:38:12, Info         DISM  DISM OS Provider: PID=1224 TID=1388 Defaulting SystemPath to C:\ - CDISMOSServiceManager::Final_OnConnect
>
> 2026-11-02 15:38:12, Info         DISM  DISM OS Provider: PID=1224 TID=1388 Defaulting Windows folder to C:\Windows - CDISMOSServiceManager::Final_OnConnect
>
> 2026-11-02 15:38:12, Info         DISM  DISM Provider Store: PID=1224 TID=1388 Attempting to initialize the logger from the Image Session. - CDISMProviderStore::Final_OnConnect
>
> 2026-11-02 15:38:12, Info         DISM  Initialized Panther logging at X:\windows\Logs\DISM\dism.log
>
> 2026-11-02 15:38:12, Info         DISM  DISM Provider Store: PID=1224 TID=1388 Found and Initialized the DISM Logger. - CDISMProviderStore::Internal_InitializeLogger
>
> 2026-11-02 15:38:12, Info         DISM  Initialized Panther logging at X:\windows\Logs\DISM\dism.log
>
> 2026-11-02 15:38:12, Info         DISM  Initialized Panther logging at X:\windows\Logs\DISM\dism.log
>
> 2026-11-02 15:38:12, Info         DISM  DISM Manager: PID=1772 TID=1764 Image session successfully loaded from location: X:\windows\TEMP\D00F2BB2-3241-4675-9DD2-AC5D9C5D7F07 - CDISMManager::CreateImageSession
>
> 2026-11-02 15:38:12, Info         DISM  DISM OS Provider: PID=1224 TID=1388 Setting SystemPath to C:\ - CDISMOSServiceManager::SetSystemPath
>
> 2026-11-02 15:38:13, Info         DISM  DISM.EXE: Target image information: OS Version=10.0.22631.5768, Image architecture=amd64
>
> 2026-11-02 15:38:13, Info         DISM  DISM.EXE: Image session version: 10.0.22621.1
>
> 2026-11-02 15:38:13, Info         DISM  DISM Transmog Provider: PID=1224 TID=1388 Current image session is [OFFLINE] - CTransmogManager::GetMode
>
> 2026-11-02 15:38:13, Info         DISM  DISM OS Provider: PID=1224 TID=1388 Determined System directory to be C:\Windows\System32 - CDISMOSServiceManager::get_SystemDirectory
>
> 2026-11-02 15:38:13, Info         DISM  DISM Transmog Provider: PID=1224 TID=1388 Determined WinDir path = [C:\Windows] - CTransmogManager::GetWinDirPath
>
> 2026-11-02 15:38:13, Info         DISM  DISM Transmog Provider: PID=1224 TID=1388 GetProductType: ProductType = [WinNT] - CTransmogManager::GetProductType
>
> 2026-11-02 15:38:13, Info         DISM  DISM Transmog Provider: PID=1224 TID=1388 Product Type: [WinNT] - CTransmogManager::Initialize
>
> 2026-11-02 15:38:13, Info         DISM  DISM Transmog Provider: PID=1224 TID=1388 Product Type ServerNT : [No] - CTransmogManager::Initialize
>
> 2026-11-02 15:38:13, Info         CSI  00000001 Shim considered [l:126]'\??\C:\Windows\Servicing\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\wcp.dll' : got STATUS_OBJECT_PATH_NOT_FOUND
>
> 2026-11-02 15:38:13, Info         CSI  00000002 Shim considered [l:123]'\??\C:\Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\wcp.dll' : got STATUS_SUCCESS
>
> 2026-11-02 15:38:13, Info         DISM  DISM Driver Manager: PID=1224 TID=1388 Further logs for driver related operations can be found in the target operating system at %WINDIR%\inf\setupapi.offline.log - CDriverManager::Initialize
>
> 2026-11-02 15:38:13, Info         DISM  DISM Package Manager: PID=1224 TID=1388 Finished initializing the CbsConUI Handler. - CCbsConUIHandler::Initialize
>
> 2026-11-02 15:38:14, Info         CSI  00000001 Shim considered [l:126]'\??\C:\Windows\Servicing\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\wcp.dll' : got STATUS_OBJECT_PATH_NOT_FOUND
>
> 2026-11-02 15:38:14, Info         CSI  00000002 Shim considered [l:123]'\??\C:\Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\wcp.dll' : got STATUS_SUCCESS
>
> 2026-11-02 15:38:14, Info         CBS  Universal Time is: 2026-11-02 07:38:14.021
>
> 2026-11-02 15:38:14, Info         CBS  Failed to find a matching version for servicing stack: C:\Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\ [HRESULT = 0x80070490 - ERROR_NOT_FOUND]
>
> 2026-11-02 15:38:14, Info         CBS  Failed to find servicing stack directory in online store. [HRESULT = 0x80070490 - ERROR_NOT_FOUND]
>
> 2026-11-02 15:38:14, Info         CBS  Offline servicing, using stack version from: C:\Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\cbscore.dll
>
> 2026-11-02 15:38:14, Info         CBS  Loaded Servicing Stack v10.0.22621.5690 with Core: C:\Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\cbscore.dll
>
> 2026-11-02 15:38:14, Info         CBS  Setting core mode: CbsCoreModeOffline
>
> 2026-11-02 15:38:14, Info         CSI  00000001@2026/11/2:07:38:14.030 WcpInitialize: wcp.dll version 10.0.22621.5690 (WinBuild.160101.0800)
>
> 2026-11-02 15:38:14, Info         CBS  TurboContainer load Successful
>
> 2026-11-02 15:38:14, Info         CBS  Lock: New lock added: CCbsSessionManager, level: 11, total lock:9
>
> 2026-11-02 15:38:14, Info         CBS  Lock: New lock added: CSIInventoryCriticalSection, level: 64, total lock:10
>
> 2026-11-02 15:38:14, Info         DISM  DISM Package Manager: PID=1224 TID=1388 Loaded servicing stack for offline use only. - CDISMPackageManager::CreateCbsSession
>
> 2026-11-02 15:38:14, Info         CBS  Lazy store initialization mode
>
> 2026-11-02 15:38:14, Info         CSI  00000001 Shim considered [l:126]'\??\C:\Windows\Servicing\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\wcp.dll' : got STATUS_OBJECT_PATH_NOT_FOUND
>
> 2026-11-02 15:38:14, Info         CSI  00000002 Shim considered [l:123]'\??\C:\Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\wcp.dll' : got STATUS_SUCCESS
>
> 2026-11-02 15:38:14, Info         DISM  DISM Package Manager: PID=1224 TID=1388 Processing the top level command token(cleanup-image). - CPackageManagerCLIHandler::Private_ValidateCmdLine
>
> 2026-11-02 15:38:14, Warning        DISM  DISM Package Manager: PID=1224 TID=1388 The scratch directory size might be insufficient to perform this operation. This can cause unexpected behavior. Use the /ScratchDir option to point to a folder with sufficient scratch space. The recommended size is at least 1024 MB - CPackageManagerCLIHandler::ExecuteCmdLine
>
> 2026-11-02 15:38:14, Info         DISM  DISM Package Manager: PID=1224 TID=1388 Attempting to route to appropriate command handler. - CPackageManagerCLIHandler::ExecuteCmdLine
>
> 2026-11-02 15:38:14, Info         DISM  DISM Package Manager: PID=1224 TID=1388 Routing the command... - CPackageManagerCLIHandler::ExecuteCmdLine
>
> 2026-11-02 15:38:14, Info         DISM  DISM Package Manager: PID=1224 TID=1388 CBS session options=0x800! - CDISMPackageManager::Internal_Finalize
>
> 2026-11-02 15:38:14, Info         CBS  Lazy store initialization mode, fully initialize.
>
> 2026-11-02 15:38:14, Info         CBS  Offline image is writable
>
> 2026-11-02 15:38:14, Info         CBS  Loading offline registry hive: SOFTWARE, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SOFTWARE' from path '\\?\C:\Windows\System32\config\SOFTWARE'.
>
> 2026-11-02 15:38:14, Info         CBS  Loading offline registry hive: SYSTEM, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SYSTEM' from path '\\?\C:\Windows\System32\config\SYSTEM'.
>
> 2026-11-02 15:38:14, Info         CBS  Loading offline registry hive: SECURITY, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SECURITY' from path '\\?\C:\Windows\System32\config\SECURITY'.
>
> 2026-11-02 15:38:14, Info         CBS  Failed to load offline \\?\C:\Windows\System32\config\SECURITY hive from '\\?\C:\Windows\System32\config\SECURITY' into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SECURITY'. [HRESULT = 0xd000014c - NTSTATUS Error]
>
> 2026-11-02 15:38:14, Info         CBS  Failed to load offline registry: {bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SECURITY [HRESULT = 0xd000014c - NTSTATUS Error]
>
> 2026-11-02 15:38:14, Info         CBS  Failed to load offline SECURITY hive. [HRESULT = 0xd000014c - NTSTATUS Error]
>
> 2026-11-02 15:38:14, Info         CBS  Force unloading offline registry hive: {bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SOFTWARE
>
> 2026-11-02 15:38:14, Info         CBS  Force unloading offline registry hive: {bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SYSTEM
>
> 2026-11-02 15:38:14, Error         CBS  Failed to load offline store from boot directory: '\\?\C:\' and windows directory: '\\?\C:\Windows\' [HRESULT = 0xd000014c - NTSTATUS Error]
>
> 2026-11-02 15:38:14, Error         CBS  Failed to initialize store parameters with boot drive: C:\, windows directory C:\Windows, and external directory: [HRESULT = 0xd000014c - NTSTATUS Error]
>
> 2026-11-02 15:38:14, Error         CBS  Cannot finalize a session that has not been initialized. [HRESULT = 0xd000014c - NTSTATUS Error]
>
> 2026-11-02 15:38:14, Info         CBS  Session: 1224_86156 finalized. Reboot required: no [HRESULT = 0xd000014c - NTSTATUS Error]
>
> 2026-11-02 15:38:14, Error         DISM  DISM Package Manager: PID=1224 TID=1388 Failed finalizing changes. - CDISMPackageManager::Internal_Finalize(hr:0xd000014c)
>
> 2026-11-02 15:38:14, Error         DISM  DISM Package Manager: PID=1224 TID=1388 An error occured clearing the pending actions from the image. - CDISMPackageManager::RevertPendingActions(hr:0xd000014c)
>
> 2026-11-02 15:38:14, Error         DISM  DISM Package Manager: PID=1224 TID=1388 Failed while processing command cleanup-image. - CPackageManagerCLIHandler::ExecuteCmdLine(hr:0xd000014c)
>
> 2026-11-02 15:38:14, Info         DISM  DISM Package Manager: PID=1224 TID=1388 Finalizing CBS core. - CDISMPackageManager::Finalize
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: ExecutionEngineFinalize
>
> 2026-11-02 15:38:14, Info         CBS  Execution Engine Finalize
>
> 2026-11-02 15:38:14, Info         CBS  Execution Engine Finalize
>
> 2026-11-02 15:38:14, Info         CBS  Execution Engine Finalize
>
> 2026-11-02 15:38:14, Info         CBS  Execution Engine Finalize
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: ComponentAnalyzerFinalize
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: PackageTrackerFinalize
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: CoreResourcesUnload
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: SessionManagerFinalize
>
> 2026-11-02 15:38:14, Info         CBS  Lock: Lock removed: CSIInventoryCriticalSection, level: 64, total lock:10
>
> 2026-11-02 15:38:14, Info         CBS  Lock: Lock removed: CCbsSessionManager, level: 11, total lock:9
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: CapabilityManagerFinalize
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: GetPublicObjectMonitor::Audit
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: PublicObjectMonitorFinalize
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: Enter vCoreInitializeLock
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: WcpUnload
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: DrupUnload
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: CfgMgr32Unload
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: DpxUnload
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: SrUnload
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: TurboStackUnload
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: TurboContainerUnload
>
> 2026-11-02 15:38:14, Info         CBS  TurboContainer unload Successful
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: CbsEsdUnload
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: CbsOneSettingsFinalize
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: CbsEventUnregister
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: AppContainerUnload
>
> 2026-11-02 15:38:14, Info         CBS  CbsCoreFinalize: WdsUnload, logging from cbscore will end.
>
> 2026-11-02 15:38:14, Info         DISM  DISM Manager: PID=1772 TID=1764 Closing session event handle 0x258 - CDISMManager::CleanupImageSessionEntry
>
> 2026-11-02 15:38:14, Info         DISM  DISM.EXE: Image session has been closed. Reboot required=no.
>
> 2026-11-02 15:38:14, Info         DISM  DISM.EXE: 
>
> 2026-11-02 15:38:14, Info         DISM  DISM.EXE: <----- Ending Dism.exe session ----->
>
> 2026-11-02 15:38:14, Info         DISM  DISM.EXE: 
>
> 2026-11-02 15:38:51, Info         DISM  PID=1572 TID=1580 Scratch directory set to 'X:\windows\TEMP\'. - CDISMManager::put_ScratchDir
>
> 2026-11-02 15:38:51, Info         DISM  PID=1572 TID=1580 DismCore.dll version: 10.0.22621.1 - CDISMManager::FinalConstruct
>
> 2026-11-02 15:38:51, Info         DISM  Initialized Panther logging at X:\windows\Logs\DISM\dism.log
>
> 2026-11-02 15:38:51, Info         DISM  PID=1572 TID=1580 Successfully loaded the ImageSession at "X:\Windows\System32\Dism" - CDISMManager::LoadLocalImageSession
>
> 2026-11-02 15:38:51, Info         DISM  Initialized Panther logging at X:\windows\Logs\DISM\dism.log
>
> 2026-11-02 15:38:51, Info         DISM  DISM Provider Store: PID=1572 TID=1580 Found and Initialized the DISM Logger. - CDISMProviderStore::Internal_InitializeLogger
>
> 2026-11-02 15:38:51, Info         DISM  Initialized Panther logging at X:\windows\Logs\DISM\dism.log
>
> 2026-11-02 15:38:51, Info         DISM  DISM Manager: PID=1572 TID=1580 Successfully created the local image session and provider store. - CDISMManager::CreateLocalImageSession
>
> 2026-11-02 15:38:51, Info         DISM  DISM.EXE: 
>
> 2026-11-02 15:38:51, Info         DISM  DISM.EXE: <----- Starting Dism.exe session ----->
>
> 2026-11-02 15:38:51, Info         DISM  DISM.EXE: 
>
> 2026-11-02 15:38:51, Info         DISM  DISM.EXE: Host machine information: OS Version=10.0.22621, Running architecture=amd64, Number of processors=20
>
> 2026-11-02 15:38:51, Info         DISM  DISM.EXE: Dism.exe version: 10.0.22621.1
>
> 2026-11-02 15:38:51, Info         DISM  DISM.EXE: Executing command line: dism /Image:C:\ /Get-Packages /Format:Table
>
> 2026-11-02 15:38:51, Info         DISM  DISM FFU Provider: PID=1572 TID=1580 [C:\] is not recognized by the DISM FFU provider. - CFfuImage::Initialize
>
> 2026-11-02 15:38:51, Info         DISM  DISM Imaging Provider: PID=1572 TID=1580 The provider FfuManager does not support CreateDismImage on C:\ - CGenericImagingManager::CreateDismImage
>
> 2026-11-02 15:38:51, Info         DISM  DISM VHD Provider: PID=1572 TID=1580 [C:\] is not recognized by the DISM VHD provider. - CVhdImage::Initialize
>
> 2026-11-02 15:38:51, Info         DISM  DISM Imaging Provider: PID=1572 TID=1580 The provider VHDManager does not support CreateDismImage on C:\ - CGenericImagingManager::CreateDismImage
>
> [1572.1580] [0x80070002] FIOReadFileIntoBuffer:(1456): 系统找不到指定的文件。
>
> [1572.1580] [0xc142011c] UnmarshallImageHandleFromDirectory:(641)
>
> [1572.1580] [0xc142011c] WIMGetMountedImageHandle:(2910)
>
> 2026-11-02 15:38:51, Info         DISM  DISM WIM Provider: PID=1572 TID=1580 [C:\] is not a WIM mount point. - CWimMountedImageInfo::Initialize
>
> 2026-11-02 15:38:51, Info         DISM  DISM Imaging Provider: PID=1572 TID=1580 The provider WimManager does not support CreateDismImage on C:\ - CGenericImagingManager::CreateDismImage
>
> 2026-11-02 15:38:51, Info         DISM  DISM Imaging Provider: PID=1572 TID=1580 No imaging provider supported CreateDismImage for this path - CGenericImagingManager::CreateDismImage
>
> [1572.1580] [0x80070002] FIOReadFileIntoBuffer:(1456): 系统找不到指定的文件。
>
> [1572.1580] [0xc142011c] UnmarshallImageHandleFromDirectory:(641)
>
> [1572.1580] [0xc142011c] WIMGetMountedImageHandle:(2910)
>
> 2026-11-02 15:38:51, Info         DISM  DISM WIM Provider: PID=1572 TID=1580 [C:\] is not a WIM mount point. - CWimMountedImageInfo::Initialize
>
> 2026-11-02 15:38:51, Info         DISM  DISM FFU Provider: PID=1572 TID=1580 [C:\] is not recognized by the DISM FFU provider. - CFfuImage::Initialize
>
> 2026-11-02 15:38:51, Info         DISM  DISM VHD Provider: PID=1572 TID=1580 [C:\] is not recognized by the DISM VHD provider. - CVhdImage::Initialize
>
> 2026-11-02 15:38:51, Info         DISM  DISM Manager: PID=1572 TID=1580 physical location path: C:\ - CDISMManager::CreateImageSession
>
> 2026-11-02 15:38:51, Info         DISM  DISM Manager: PID=1572 TID=1580 Event name for current DISM session is Global\__?_Volume{9508512a-c61f-41bc-bae8-64b14d710d06}__2062103243_65536_58365 - CDISMManager::CheckSessionAndLock
>
> 2026-11-02 15:38:51, Info         DISM  DISM Manager: PID=1572 TID=1580 Create session event 0x250 for current DISM session and event name is Global\__?_Volume{9508512a-c61f-41bc-bae8-64b14d710d06}__2062103243_65536_58365 - CDISMManager::CheckSessionAndLock
>
> 2026-11-02 15:38:51, Info         DISM  DISM Manager: PID=1572 TID=1580 Copying DISM from "C:\Windows\System32\Dism" - CDISMManager::CreateImageSessionFromLocation
>
> 2026-11-02 15:38:51, Info         DISM  DISM Manager: PID=1572 TID=1580 Successfully loaded the ImageSession at "X:\windows\TEMP\1C68D641-0BC3-4A33-9F2C-B08F75B9E8FE" - CDISMManager::LoadRemoteImageSession
>
> 2026-11-02 15:38:51, Info         DISM  DISM Image Session: PID=1944 TID=1084 Instantiating the Provider Store. - CDISMImageSession::get_ProviderStore
>
> 2026-11-02 15:38:51, Info         DISM  DISM OS Provider: PID=1944 TID=1084 Defaulting SystemPath to C:\ - CDISMOSServiceManager::Final_OnConnect
>
> 2026-11-02 15:38:51, Info         DISM  DISM OS Provider: PID=1944 TID=1084 Defaulting Windows folder to C:\Windows - CDISMOSServiceManager::Final_OnConnect
>
> 2026-11-02 15:38:51, Info         DISM  DISM Provider Store: PID=1944 TID=1084 Attempting to initialize the logger from the Image Session. - CDISMProviderStore::Final_OnConnect
>
> 2026-11-02 15:38:51, Info         DISM  Initialized Panther logging at X:\windows\Logs\DISM\dism.log
>
> 2026-11-02 15:38:51, Info         DISM  DISM Provider Store: PID=1944 TID=1084 Found and Initialized the DISM Logger. - CDISMProviderStore::Internal_InitializeLogger
>
> 2026-11-02 15:38:51, Info         DISM  Initialized Panther logging at X:\windows\Logs\DISM\dism.log
>
> 2026-11-02 15:38:51, Info         DISM  Initialized Panther logging at X:\windows\Logs\DISM\dism.log
>
> 2026-11-02 15:38:51, Info         DISM  DISM Manager: PID=1572 TID=1580 Image session successfully loaded from location: X:\windows\TEMP\1C68D641-0BC3-4A33-9F2C-B08F75B9E8FE - CDISMManager::CreateImageSession
>
> 2026-11-02 15:38:51, Info         DISM  DISM OS Provider: PID=1944 TID=1084 Setting SystemPath to C:\ - CDISMOSServiceManager::SetSystemPath
>
> 2026-11-02 15:38:51, Info         DISM  DISM.EXE: Target image information: OS Version=10.0.22631.5768, Image architecture=amd64
>
> 2026-11-02 15:38:51, Info         DISM  DISM.EXE: Image session version: 10.0.22621.1
>
> 2026-11-02 15:38:51, Info         DISM  DISM Transmog Provider: PID=1944 TID=1084 Current image session is [OFFLINE] - CTransmogManager::GetMode
>
> 2026-11-02 15:38:51, Info         DISM  DISM OS Provider: PID=1944 TID=1084 Determined System directory to be C:\Windows\System32 - CDISMOSServiceManager::get_SystemDirectory
>
> 2026-11-02 15:38:51, Info         DISM  DISM Transmog Provider: PID=1944 TID=1084 Determined WinDir path = [C:\Windows] - CTransmogManager::GetWinDirPath
>
> 2026-11-02 15:38:51, Info         DISM  DISM Transmog Provider: PID=1944 TID=1084 GetProductType: ProductType = [WinNT] - CTransmogManager::GetProductType
>
> 2026-11-02 15:38:51, Info         DISM  DISM Transmog Provider: PID=1944 TID=1084 Product Type: [WinNT] - CTransmogManager::Initialize
>
> 2026-11-02 15:38:51, Info         DISM  DISM Transmog Provider: PID=1944 TID=1084 Product Type ServerNT : [No] - CTransmogManager::Initialize
>
> 2026-11-02 15:38:51, Info         CSI  00000001 Shim considered [l:126]'\??\C:\Windows\Servicing\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\wcp.dll' : got STATUS_OBJECT_PATH_NOT_FOUND
>
> 2026-11-02 15:38:51, Info         CSI  00000002 Shim considered [l:123]'\??\C:\Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\wcp.dll' : got STATUS_SUCCESS
>
> 2026-11-02 15:38:52, Info         DISM  DISM Driver Manager: PID=1944 TID=1084 Further logs for driver related operations can be found in the target operating system at %WINDIR%\inf\setupapi.offline.log - CDriverManager::Initialize
>
> 2026-11-02 15:38:52, Info         DISM  DISM Package Manager: PID=1944 TID=1084 Finished initializing the CbsConUI Handler. - CCbsConUIHandler::Initialize
>
> 2026-11-02 15:38:52, Info         CSI  00000001 Shim considered [l:126]'\??\C:\Windows\Servicing\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\wcp.dll' : got STATUS_OBJECT_PATH_NOT_FOUND
>
> 2026-11-02 15:38:52, Info         CSI  00000002 Shim considered [l:123]'\??\C:\Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\wcp.dll' : got STATUS_SUCCESS
>
> 2026-11-02 15:38:52, Info         CBS  Universal Time is: 2026-11-02 07:38:52.426
>
> 2026-11-02 15:38:52, Info         CBS  Failed to find a matching version for servicing stack: C:\Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\ [HRESULT = 0x80070490 - ERROR_NOT_FOUND]
>
> 2026-11-02 15:38:52, Info         CBS  Failed to find servicing stack directory in online store. [HRESULT = 0x80070490 - ERROR_NOT_FOUND]
>
> 2026-11-02 15:38:52, Info         CBS  Offline servicing, using stack version from: C:\Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\cbscore.dll
>
> 2026-11-02 15:38:52, Info         CBS  Loaded Servicing Stack v10.0.22621.5690 with Core: C:\Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\cbscore.dll
>
> 2026-11-02 15:38:52, Info         CBS  Setting core mode: CbsCoreModeOffline
>
> 2026-11-02 15:38:52, Info         CSI  00000001@2026/11/2:07:38:52.426 WcpInitialize: wcp.dll version 10.0.22621.5690 (WinBuild.160101.0800)
>
> 2026-11-02 15:38:52, Info         CBS  TurboContainer load Successful
>
> 2026-11-02 15:38:52, Info         CBS  Lock: New lock added: CCbsSessionManager, level: 11, total lock:9
>
> 2026-11-02 15:38:52, Info         CBS  Lock: New lock added: CSIInventoryCriticalSection, level: 64, total lock:10
>
> 2026-11-02 15:38:52, Info         DISM  DISM Package Manager: PID=1944 TID=1084 Loaded servicing stack for offline use only. - CDISMPackageManager::CreateCbsSession
>
> 2026-11-02 15:38:52, Info         CBS  Lazy store initialization mode
>
> 2026-11-02 15:38:52, Info         CSI  00000001 Shim considered [l:126]'\??\C:\Windows\Servicing\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\wcp.dll' : got STATUS_OBJECT_PATH_NOT_FOUND
>
> 2026-11-02 15:38:52, Info         CSI  00000002 Shim considered [l:123]'\??\C:\Windows\WinSxS\amd64_microsoft-windows-servicingstack_31bf3856ad364e35_10.0.22621.5690_none_e93887f042e96014\wcp.dll' : got STATUS_SUCCESS
>
> 2026-11-02 15:38:52, Info         DISM  DISM Package Manager: PID=1944 TID=1084 Processing the top level command token(get-packages). - CPackageManagerCLIHandler::Private_ValidateCmdLine
>
> 2026-11-02 15:38:52, Warning        DISM  DISM Package Manager: PID=1944 TID=1084 The scratch directory size might be insufficient to perform this operation. This can cause unexpected behavior. Use the /ScratchDir option to point to a folder with sufficient scratch space. The recommended size is at least 1024 MB - CPackageManagerCLIHandler::ExecuteCmdLine
>
> 2026-11-02 15:38:52, Info         DISM  DISM Package Manager: PID=1944 TID=1084 Attempting to route to appropriate command handler. - CPackageManagerCLIHandler::ExecuteCmdLine
>
> 2026-11-02 15:38:52, Info         DISM  DISM Package Manager: PID=1944 TID=1084 Routing the command... - CPackageManagerCLIHandler::ExecuteCmdLine
>
> 2026-11-02 15:38:52, Info         CBS  Lazy store initialization mode, fully initialize.
>
> 2026-11-02 15:38:52, Info         CBS  Offline image is writable
>
> 2026-11-02 15:38:52, Info         CBS  Loading offline registry hive: SOFTWARE, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SOFTWARE' from path '\\?\C:\Windows\System32\config\SOFTWARE'.
>
> 2026-11-02 15:38:52, Info         CBS  Loading offline registry hive: SYSTEM, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SYSTEM' from path '\\?\C:\Windows\System32\config\SYSTEM'.
>
> 2026-11-02 15:38:52, Info         CBS  Loading offline registry hive: SECURITY, into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SECURITY' from path '\\?\C:\Windows\System32\config\SECURITY'.
>
> 2026-11-02 15:38:52, Info         CBS  Failed to load offline \\?\C:\Windows\System32\config\SECURITY hive from '\\?\C:\Windows\System32\config\SECURITY' into registry key '{bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SECURITY'. [HRESULT = 0xd000014c - NTSTATUS Error]
>
> 2026-11-02 15:38:52, Info         CBS  Failed to load offline registry: {bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SECURITY [HRESULT = 0xd000014c - NTSTATUS Error]
>
> 2026-11-02 15:38:52, Info         CBS  Failed to load offline SECURITY hive. [HRESULT = 0xd000014c - NTSTATUS Error]
>
> 2026-11-02 15:38:52, Info         CBS  Force unloading offline registry hive: {bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SOFTWARE
>
> 2026-11-02 15:38:52, Info         CBS  Force unloading offline registry hive: {bf1a281b-ad7b-4476-ac95-f47682990ce7}C:/Windows/System32/config/SYSTEM
>
> 2026-11-02 15:38:52, Error         CBS  Failed to load offline store from boot directory: '\\?\C:\' and windows directory: '\\?\C:\Windows\' [HRESULT = 0xd000014c - NTSTATUS Error]
>
> 2026-11-02 15:38:52, Error         CBS  Failed to initialize store parameters with boot drive: C:\, windows directory C:\Windows, and external directory: [HRESULT = 0xd000014c - NTSTATUS Error]
>
> 2026-11-02 15:38:52, Error         CBS  Cannot enumerate packages in a session that has not been initialized. [HRESULT = 0xd000014c - NTSTATUS Error]
>
> 2026-11-02 15:38:52, Error         DISM  DISM Package Manager: PID=1944 TID=1084 Failed to create the CBS Package enumeration. - CDISMPackageManager::GetPackageCollection(hr:0xd000014c)
>
> 2026-11-02 15:38:52, Error         DISM  DISM Package Manager: PID=1944 TID=1084 Failed to get the package collection. - CPackageManagerCLIHandler::ProcessCmdLine_GetPackages(hr:0xd000014c)
>
> 2026-11-02 15:38:52, Error         DISM  DISM Package Manager: PID=1944 TID=1084 Failed while processing command get-packages. - CPackageManagerCLIHandler::ExecuteCmdLine(hr:0xd000014c)
>
> 2026-11-02 15:38:52, Error         DISM  DISM.EXE: DISM Package Manager processed the command line but failed. HRESULT=D000014C
>
> 2026-11-02 15:38:52, Info         DISM  DISM Package Manager: PID=1944 TID=1084 Finalizing CBS core. - CDISMPackageManager::Finalize
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: ExecutionEngineFinalize
>
> 2026-11-02 15:38:52, Info         CBS  Execution Engine Finalize
>
> 2026-11-02 15:38:52, Info         CBS  Execution Engine Finalize
>
> 2026-11-02 15:38:52, Info         CBS  Execution Engine Finalize
>
> 2026-11-02 15:38:52, Info         CBS  Execution Engine Finalize
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: ComponentAnalyzerFinalize
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: PackageTrackerFinalize
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: CoreResourcesUnload
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: SessionManagerFinalize
>
> 2026-11-02 15:38:52, Info         CBS  Lock: Lock removed: CSIInventoryCriticalSection, level: 64, total lock:10
>
> 2026-11-02 15:38:52, Info         CBS  Lock: Lock removed: CCbsSessionManager, level: 11, total lock:9
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: CapabilityManagerFinalize
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: GetPublicObjectMonitor::Audit
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: PublicObjectMonitorFinalize
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: Enter vCoreInitializeLock
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: WcpUnload
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: DrupUnload
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: CfgMgr32Unload
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: DpxUnload
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: SrUnload
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: TurboStackUnload
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: TurboContainerUnload
>
> 2026-11-02 15:38:52, Info         CBS  TurboContainer unload Successful
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: CbsEsdUnload
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: CbsOneSettingsFinalize
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: CbsEventUnregister
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: AppContainerUnload
>
> 2026-11-02 15:38:52, Info         CBS  CbsCoreFinalize: WdsUnload, logging from cbscore will end.
>
> 2026-11-02 15:38:52, Info         DISM  DISM Manager: PID=1572 TID=1580 Closing session event handle 0x250 - CDISMManager::CleanupImageSessionEntry
>
> 2026-11-02 15:38:52, Info         DISM  DISM.EXE: Image session has been closed. Reboot required=no.
>
> 2026-11-02 15:38:52, Info         DISM  DISM.EXE: 
>
> 2026-11-02 15:38:52, Info         DISM  DISM.EXE: <----- Ending Dism.exe session ----->
>
> 2026-11-02 15:38:52, Info         DISM  DISM.EXE: 
>
> 提到的dism报错如上。此外注意到c盘只有150G，我接手的时候只剩下100M+,清理后剩余9G
>
> 重新研判回答
>
> ![a4f160f0-90cd-4ba3-ba18-7a23d9c04ffb](.\a4f160f0-90cd-4ba3-ba18-7a23d9c04ffb.jpg)

结合最新提供的 `dism.log` 具体行与“**C 盘原本只剩 100M+**”这一关键线索，事故的全貌已经完全锁死，故障点也已精准定位：

### 一、 关键证据与事故根本原因

1. **精确死穴定位：`SECURITY` 注册表损坏**

   在 `dism.log` 中连续两次出现明确拦截：

   > `Loading offline registry hive: SOFTWARE ...` （成功）
   >
   > `Loading offline registry hive: SYSTEM ...` （成功）
   >
   > `Loading offline registry hive: SECURITY ...`
   >
   > `Failed to load offline ...\config\SECURITY ... [HRESULT = 0xd000014c - NTSTATUS Error]`
   >
   > `Failed to load offline SECURITY hive.`

   之前验证 `reg load HKLM\TEMP C:\Windows\System32\config\SYSTEM` 能加载成功，是因为损坏的**根本不是 SYSTEM 文件，而是同目录下的 `SECURITY` 文件**。   

2. **事故发生机理：极度缺盘诱发的“截断坏死”**

   C 盘被塞到只剩 100M+ 时，Windows Update（即日志中提到的 LCU 累积更新补丁）在后台静默解压并尝试写入权限与安全策略。由于**磁盘物理空间完全耗尽**，写操作发生异常崩溃，直接将 `SECURITY` 单元损坏或截断。

3. **连锁反应**：

   - 启动时，内核加载安全子系统失败，触发蓝屏 `BAD_SYSTEM_CONFIG_INFO` 和 `0xc0000001`。   
   - 离线 DISM 修复与自动修复每次跑到底层都要检查 `SECURITY` 配置，一旦加载失败就直接抛出 `0xd000014c` 并强行回滚退出。   

### 二、 针对 `SECURITY` 损坏的终极免重装修复方案

因为 `SYSTEM` 和 `SOFTWARE` 是完好的，只要让系统能够成功读入一个合法的 `SECURITY` 单元，跳过 DISM 和开机阶段的 `0xd000014c` 校验，系统极大概率能起死回生。

#### 步骤 1：释放足够的磁盘空间与指定 ScratchDir

虽然当前清理出了 9G，但在 PE 下执行 DISM 命令时，PE 的 `X:\windows\TEMP` 虚拟内存盘空间严重不足（日志中警告只有几十兆），必须把暂存目录借用给空间充裕的 D 盘：

DOS

```
md D:\DismScratch
```

#### 步骤 2：抢救/重置 `SECURITY` 注册表单元

在 PE 命令提示符中操作：

1. **备份并移出已损坏的 SECURITY 文件**：

   DOS

   ```
   md C:\Windows\System32\config\CorruptBak
   move C:\Windows\System32\config\SECURITY* C:\Windows\System32\config\CorruptBak\
   ```

2. **方案 A（首选）：从 Windows 安装镜像提取干净的空白 SECURITY**

   在你的 PE 里（或者插着 Ventoy/系统安装 U 盘）：

   - 在资源管理器中右键挂载你的 Windows 11 ISO 镜像（假设虚拟光驱盘符为 `G:`）。

   - 打开 `G:\sources\`，找到 `boot.wim` 或 `install.wim`。

   - 使用 **7-Zip**（PE 开始菜单通常自带）直接打开 `G:\sources\boot.wim`，进入 `2\Windows\System32\config\`。

   - 将里面的 `SECURITY` 文件提取并复制到 `C:\Windows\System32\config\` 下。

     *(注：PE 自身的 `X:\Windows\System32\config\SECURITY` 也是现成的未损坏模板，如果找不到镜像，可直接执行：`copy X:\Windows\System32\config\SECURITY C:\Windows\System32\config\SECURITY`)*

#### 步骤 3：清除挂起的更新事务并重置

替换好未损坏的 `SECURITY` 之后，再次调用 DISM（此时带上充足的 D 盘暂存空间）：

DOS

```
dism /Image:C:\ /ScratchDir:D:\DismScratch /Cleanup-Image /RevertPendingActions
```

*此时因为 `SECURITY` 不再报 `0xd000014c`，DISM 能够成功穿透并撤销死锁的 LCU 挂起动作。*

#### 步骤 4：清理可能存在的阻断文件

DOS

```
if exist C:\Windows\WinSxS\pending.xml del /f /q C:\Windows\WinSxS\pending.xml
chkdsk C: /f
```

### 三、 研判总结

- **如果步骤 3 的 `RevertPendingActions` 提示“操作成功完成”**：

  直接拔掉 U 盘重启，电脑会经历一次“正在撤销更改”的更新清理界面，随后将**无损恢复进入桌面**。

- **如果替换后仍报其他核心组件损坏**：

  说明断电截断波及了多个 Hive 节点（如 `SAM`、`COMPONENTS`）。鉴于重要数据已在 PE 下完全解锁并备份，直接使用 **WinNTSetup** 对 C 盘格式化重装，彻底告别此系统盘因爆满造成的暗病，是效率最高的保底手段。

> 替换后依旧报错。你判断一下哪些组件还有可能损坏，给我列出我尝试修复替换一下然后重构dism镜像
>
> ![70c2ebb8-4eaa-44c8-be1b-07c8689cf786](.\70c2ebb8-4eaa-44c8-be1b-07c8689cf786.jpg)![e2220c15-0654-42fd-a3f3-6715244c1329](.\e2220c15-0654-42fd-a3f3-6715244c1329.jpg)![82d1a586-68f4-48d9-8a71-4ed40535f8a3](.\82d1a586-68f4-48d9-8a71-4ed40535f8a3.jpg)

在执行了 `RevertPendingActions` 后终端已显示“操作成功完成”，这说明更新挂起的执行锁已经被清理。但重启后仍然抛出 `0xc0000001`（或 `BAD_SYSTEM_CONFIG_INFO`），证明虽然 DISM 运行时的外层阻断去掉了，但内核引导阶段（ntoskrnl 加载期）必需的关键配置单元仍存在逻辑或键值断裂。   

结合 C 盘被写满到 100MB 截断的背景，以下是当前可能导致蓝屏的核心损坏组件清单与重构步骤：

### 一、 可能损坏的核心组件研判清单

| **损坏组件与路径**                                     | **负责的核心功能**                      | **损坏导致的直接后果**                                       | **修复难度与替换可行性**                                   |
| ------------------------------------------------------ | --------------------------------------- | ------------------------------------------------------------ | ---------------------------------------------------------- |
| **`C:\Windows\System32\config\SAM`**                   | 本地账户与安全上下文                    | 系统引导时 LSASS 安全验证崩溃，直接触发蓝屏                  | **高可行性**：可直接从干净镜像或 PE 提取替换。             |
| **`C:\Windows\System32\config\COMPONENTS`**            | Windows 组件存储映射树（WCP）           | DISM 修复、SFC 离线扫描报错无法执行；更新服务崩溃            | **中等**：可用镜像版重命名替换，但会重置离线包依赖。       |
| **`C:\Windows\System32\config\SYSTEM`** (内部逻辑损坏) | 核心驱动加载列表（Services/ControlSet） | 虽能被 `reg load` 加载头文件，但关键驱动启动项为空或指错路径 | **不可跨机直接替换**（包含特定硬件驱动），需手工修复键值。 |
| **`C:\Windows\System32\drivers\*.sys`** (截断坏文件)   | 基础硬件与内核过滤驱动                  | 系统写满时某些驱动文件被写入为 0 字节，内核加载失败报 `0xc0000001` | 可使用 SFC/DISM 离线还原。                                 |

### 二、 尝试修复/替换组件并重构 DISM

先备份当前的 `config` 文件夹，然后依次执行以下三步：

#### 第一步：备份当前配置目录

在 PE 命令行执行：

DOS

```
xcopy C:\Windows\System32\config C:\Windows\System32\config_Backup\ /E /H /Y
```

#### 第二步：替换 SAM 与 COMPONENTS

将干净的 Windows 11 安装镜像（假设挂载在 `G:`）中的通用单元提取覆盖，以排除安全和组件树损坏：

1. **提取/替换 SAM**（PE 环境下同样可以直接取用）：

   DOS

   ```
   copy /y X:\Windows\System32\config\SAM C:\Windows\System32\config\SAM
   ```

2. **提取/替换 COMPONENTS**：

   从安装镜像 `G:\sources\install.wim`（通过 7-Zip 打开镜像内的 `\Windows\System32\config\COMPONENTS`）提取并复制到：

   `C:\Windows\System32\config\COMPONENTS`

   *(注：镜像内的 COMPONENTS 结构完整无断裂，可使 DISM 组件检查恢复通行)*

#### 第三步：检查并清除 0 字节损坏驱动

磁盘写满时，驱动文件往往会变成 0 KB：

DOS

```
for %F in (C:\Windows\System32\drivers\*.sys) do @if %~zF==0 echo 损坏的驱动: %F
```

*如果有输出 0 字节的驱动文件，记下文件名，直接从 `X:\Windows\System32\drivers\` 或挂载的镜像中拷贝同名文件覆盖。*

#### 第四步：离线镜像验证与健康重构（DISM / RestoreHealth）

现在 `SECURITY`、`SAM`、`COMPONENTS` 都恢复了有效结构，运行以下重构命令（将系统文件源直接指向光驱镜像中的 `install.wim`）：

DOS

```
dism /Image:C:\ /ScratchDir:D:\DismScratch /Cleanup-Image /RestoreHealth /Source:wim:G:\sources\install.wim:1 /LimitAccess
```

*此命令会利用安装镜像中的健康副本，比对并替换 C 盘所有损坏或校验失败的系统二进制文件与驱动。*

执行完毕后紧接着跑一次系统文件完整性修补：

DOS

```
sfc /scannow /offbootdir=C:\ /offwindir=C:\Windows
```

### 三、 最终裁决与止损建议

如果执行 `RestoreHealth` 提示**100% 成功完成**，且 `sfc` 显示**已成功修复保护资源**，重启即可尝试进入系统。

如果运行重构命令仍然提示 `0xd000014c` 或类似注册表不可读错误，这证实 **`SYSTEM` 单元内部的硬件控制树已经丢失**。由于 `SYSTEM` 包含特定硬件（主板芯片组、存储控制器等）独有的注册表项，无法直接从外部镜像替换同名文件（强制替换会导致更严重的蓝屏 `INACCESSIBLE_BOOT_DEVICE`）。此时所有离线修复途径已穷尽，直接使用 PE 里的 **WinNTSetup** 格式化 C 盘安装新系统即可。