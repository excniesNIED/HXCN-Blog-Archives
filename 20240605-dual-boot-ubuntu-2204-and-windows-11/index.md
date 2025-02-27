## 安装前的准备工作

### 确认 BIOS 模式和磁盘分区表类型

#### Windows 在 UEFI 和 BIOS 上的限制

不同版本的 Windows 对固件启动模式和分区表有不同的需求，根据不同版本大致分为以下情况：

> **注意：** 下列情形是 [Windows安装程序](https://en.wikipedia.org/wiki/Windows_Setup) 的限制。但 Windows 本身仍可能在 Windows安装程序 不支持的情况下正常运行。例如，在绕过相关安装检测后，Windows 11 仍可在 BIOS/MBR 的配置上运行。

- **Windows 8/8.1** 和 **10** 的 **x86 32位**版本只支持从 GPT 磁盘启动 IA32 UEFI模式，或者从 MBR 磁盘启动 BIOS 模式。它们不支持从 GPT/MBR 磁盘启动 x86_64 UEFI，从 MBR 磁盘启动 x86_64 UEFI，或者从 GPT 磁盘启动 BIOS。目前市面上，唯一已知装载 IA32 (U)EFI 的系统是一些较老的 Intel Mac（2010年前的型号？）以及 Intel Atom 系统级芯片（Clover Trail 和 Bay Trail）的 Windows 平板电脑，这些设备只支持在 IA32 UEFI 模式下并且只从 GPT 磁盘启动。
- **Windows 8/8.1** 和 **10** 的 **x86_64**版本只支持从 GPT 磁盘启动 x86_64 UEFI 模式，或者从 MBR 磁盘启动 BIOS 模式。它们不支持IA32 UEFI启动，从 MBR 磁盘启动 x86_64 UEFI，或者从 GPT 磁盘启动 BIOS。
- **Windows 11** 只支持 **x86_64** 并从 GPT 磁盘以 UEFI 模式启动。

#### 对于预装系统的计算机：

- 所有预装 Windows XP、Vista 或 7 32 位的系统，无论服务包级别、位宽度、版本（SKU），或固件中是否支持 UEFI，都默认以 BIOS/MBR 模式启动。
- 大部分预装 Windows 7 x86_64 的系统，无论服务包级别、位宽度还是版本（SKU），默认均以 BIOS/MBR 模式启动。极少数较新的预装 Windows 7 的系统默认以 x86_64 UEFI/GPT 模式启动。
- 所有预装 Windows 8/8.1、10 和 11 的系统都默认以 UEFI/GPT 模式启动。在 Windows 10 之前，固件位宽与 Windows 位宽匹配，即 x86_64 Windows 在 x86_64 UEFI 模式下启动，32位 Windows 在IA32 UEFI模式下启动。

#### 判断 Windows 启动模式的简单方式：

- 按 `Win + R` 打开“运行”，在“运行”对话框中输入 `msinfo32` 并回车

- 系统信息 -> 系统摘要 -> BIOS模式

  - 如果值为  UEFI，Windows 以 UEFI/GPT 模式启动。如果值为  Legacy，Windows 以 BIOS/MBR 模式启动。

  ![判断启动方法](https://gastigado.cnies.org/d/halo202406062045/1.%E5%88%A4%E6%96%AD%E5%90%AF%E5%8A%A8%E6%96%B9%E6%B3%95.png?sign=6x7gwAIoM7eDu4aUnzGeY5_ygPVKnPgKXi0vXrmCgoE=:0)

#### 判断磁盘分区类型的方法

- 按下 `Win + R` 打开“运行”，输入 `diskmgmt.msc` 并回车。

- 在磁盘管理工具中，选择需要查看的磁盘，右键单击并选择“属性”。

- 在磁盘属性对话框中，点击“卷”选项卡，找到“磁盘分区形式”项，即可查看该磁盘的分区表类型。

![判断分区类型](https://gastigado.cnies.org/d/halo202406062045/2.%E5%88%A4%E6%96%AD%E5%88%86%E5%8C%BA%E7%B1%BB%E5%9E%8B.png?sign=5aX889xWYTLcZYHot--cdsTpFGVaf7sBB71OJ_qmdVM=:0)

通常来说，Windows 安装程序基于固件模式强制选择磁盘分区类型：UEFI 启动只能装到 GPT 盘，BIOS 启动只能装到 MBR 盘。这是 Windows 安装程序强加的限制，截至 2014 年 4 月，没有官方（Microsoft）支持的在 UEFI/MBR 或BIOS/GPT配置中安装 Windows 的方法。因此，Windows 只支持 UEFI/GPT 启动或 BIOS/MBR 配置。

**提示：Windows 10的1703版本及以后的版本支持使用 [MBR2GPT.EXE](https://docs.microsoft.com/en-us/windows/deployment/mbr-to-gpt) 从 BIOS/MBR 转换为 UEFI/GPT。**

Linux 内核没有这样的限制，但可能取决于使用的 [引导加载程序](https://wiki.archlinuxcn.org/wiki/引导加载程序) 以及/或者 其配置。如果用户希望从同一磁盘启动 Windows 和 Linux，那么应该考虑 Windows 的这个限制，因为 boot loader 的安装过程取决于固件类型和磁盘[分区](https://wiki.archlinuxcn.org/wiki/分区)配置。建议遵循 Windows 使用的方法，即选择 UEFI/GPT 启动或 BIOS/MBR 启动。请参见https://support.microsoft.com/kb/2581408获取更多信息。

#### 注意

本文采用的搭载 UEFI + GPT 的 Windows 11 的华硕天选 4 笔记本，这也是目前市售主流笔记本的配置。

### 解锁 Bitlocker

#### 检查是否开启 Bitlocker 

- 打开“控制面板”
- 系统和安全 -> Bitlocker 驱动器加密

![32.Bitlocker](https://gastigado.cnies.org/d/halo202406062045/32.Bitlocker.png?sign=7SVQd-85OcrYUg0j8tftOFRj5NuTr89rjdZ7UkcxVu4=:0)

#### 关闭 Bitlocker

如果所有驱动器处于“Bitlocker 已关闭”状态，请前往 [下一步](#关闭快速启动和休眠)

#### 如果 Bitlocker 已启用

- 点击“备份恢复密钥”，保存到 Microsoft 帐户或者保存到文件。如果保存到文件，请尽可能对恢复密钥进行多次备份，避免恢复密钥丢失。

- 点击“关闭 Bitlocker”，并等待解密完成。
- 如果无法关闭 Bitlocker，请先关闭“设备加密”。

#### 关闭设备加密

- 按 Win + s ，在 Windows 搜索栏输入“设备加密设置”。

  ![设备加密关闭1](https://gastigado.cnies.org/d/halo202406062045/9.%E8%AE%BE%E5%A4%87%E5%8A%A0%E5%AF%86%E5%85%B3%E9%97%AD1.png?sign=EP6OUI5H-wQpMQ_Be2cvJOEvs7cB3-eTueDyjeMwWds=:0)

  在设备加密栏位，设置为“关闭”。

  ![关闭设备加密2](https://gastigado.cnies.org/d/halo202406062045/10.%E5%85%B3%E9%97%AD%E8%AE%BE%E5%A4%87%E5%8A%A0%E5%AF%862.png?sign=JEJ7G_73WhyF6wz56XnU99G2uttkUtF7rkhktGWVI9Q=:0)

  系统会提醒您是否需要关闭设备加密，点选“关闭”即可关闭设备加密。

  ![关闭设备加密3](https://gastigado.cnies.org/d/halo202406062045/11.%E5%85%B3%E9%97%AD%E8%AE%BE%E5%A4%87%E5%8A%A0%E5%AF%863.png?sign=WJFRpm_RXPCFBe8gvd2luo7tA89_fa3yQcrlL3mszdw=:0)

### 关闭快速启动和休眠

- 控制面板 -> 系统和安全 -> 电源选项 -> 选择电源按钮功能，点击“更改当前不可用的设置”

![电源计划1](https://gastigado.cnies.org/d/halo202406062045/15.%E7%94%B5%E6%BA%90%E8%AE%A1%E5%88%921.png?sign=prSttBp_FVxN3o4TWKAvqMIrGElHzwDBDOVxyyx5_mA=:0)

- 取消选择“启用快速启动”和“休眠”

![电源计划关机设置](https://gastigado.cnies.org/d/halo202406062045/16.%E7%94%B5%E6%BA%90%E8%AE%A1%E5%88%92%E5%85%B3%E6%9C%BA%E8%AE%BE%E7%BD%AE.png?sign=kenCOTEfDejBHAHAEBs-vquGZf5jGM_gmN1Hg2sqiqM=:0)

### 关闭 Windows 更新

如果要在同一个磁盘安装 Ubuntu 和 Windows，建议关闭 Windows 更新。Windows 更新往往会带来更多的 Bug，并可能导致 Ubuntu 无法启动，因此建议关闭，并在安装 Ubuntu 后尽可能不使用 Windows 更新。

Windows 更新默认最大暂停更新 5 周，你可以在 5 周后继续延期，也可以自行搜索如何通过编辑组策略无限延期。如果你使用的是 Windows 家庭版，可以到猹盘下载 [延期  1000  周注册表修改文件](https://ed.qcea.top/ChaIndex/Softwares/Windows/System/Setting_Tools/windows-1000weeks-update-blocker.reg) 通过修改注册表延期 1000 周（更为安全），或者下载 [阻止更新相关软件](https://ed.qcea.top/ChaIndex/Softwares/Windows/System/Setting_Tools/Windows%20Update%20Blocker%20v1.6%EF%BC%88%E9%98%BB%E6%AD%A2win10%E8%87%AA%E5%8A%A8%E6%9B%B4%E6%96%B0%EF%BC%89.zip)，通过移除 Windows 更新组件进行延期（可能造成系统组件损坏）。

## 制作启动盘

### 下载 Ubuntu 22.04.03 LTS镜像

Ubuntu 22.04 系列的 LTS 支持期如下：

​	Ubuntu 22.04.01 (2022 年 4 月初次发布)

​	Ubuntu 22.04.2 (2022 年 8 月)

​	Ubuntu 22.04.3 (2023 年 1 月)

​	Ubuntu 22.04.4 (2023 年 4 月)

这四个版本都是 Ubuntu 22.04 的 LTS 版本，它们都将获得 5 年的技术支持和安全更新，直到 2027 年 4 月。因此，无论是 Ubuntu 22.04.01、22.04.2、22.04.3 还是 22.04.4，它们都是 Ubuntu 22.04 的 LTS 版本，提供相同的长期支持。本文选择最新的 **Ubuntu 22.04.4 桌面**版本。

考虑到网络的差异，本文推荐三种方法下载系统镜像，选择下载速度相对较快的方式即可。

#### Ubuntu官网下载

下载地址：https://ubuntu.com/download/desktop

#### 开源镜像站（以清华大学开源软件镜像站为例）

##### 通过索引下载
转到 ubuntu-releases/22.04/ 下载

下载地址：https://mirrors.tuna.tsinghua.edu.cn/ubuntu-releases/22.04/ubuntu-22.04.4-desktop-amd64.iso

##### 常用发行版 ISO 和应用软件安装包直接下载

![清华镜像站下载ISO](https://gastigado.cnies.org/d/halo202406062045/3.%E6%B8%85%E5%8D%8E%E9%95%9C%E5%83%8F%E7%AB%99%E4%B8%8B%E8%BD%BDISO.png?sign=daxtJETzO7kx6HIP1m3hudy_1i7DFC_5kbMBJoncsuQ=:0)

下载地址：https://mirrors.tuna.tsinghua.edu.cn/ubuntu-releases/jammy/ubuntu-22.04.4-desktop-amd64.iso

#### 猹盘 Linux 系统镜像

<iframe>https://ed.qcea.top/ChaIndex/Systems/Linux/Ubuntu/ubuntu-22.04.4-desktop-amd64.iso</iframe>

直链：https://ed.qcea.top/d/ChaIndex/Systems/Linux/Ubuntu/ubuntu-22.04.4-desktop-amd64.iso

**注意：使用迅雷等第三方下载工具很有可能无法下载。**

#### 校验

下载完成后，请务必使用 [文件校验工具](https://ed.qcea.top/ChaIndex/Softwares/Windows/Hash) 对镜像进行校验。

### 制作启动盘

#### 操作前注意

**使用 U 盘制作启动盘会进行格式化操作，清除 U 盘全部数据。在进行该操作之前，务必对 U 盘全部文件进行备份！**

**关闭 360 安全卫士等杀毒软件，以免影像启动盘制作。**

下面推荐两种方法制作启动盘。

#### 使用 Rufus 等制作 Ubuntu 启动盘

1. 访问 [Rufus 官网](https://rufus.ie/zh/)，根据系统指令集下载最新版本的 Rufus，比如 64 位的 Windows 11 应下载 `rufus-x.x.exe`。
2. 你也可以在 [猹盘 -> 烧录工具](https://ed.qcea.top/ChaIndex/Softwares/Windows/System/Burning) 中下载 Rufus。
3. 右键 -> 以管理员身份运行。
4. 选择插入的 U 盘，选择下载并校验通过的 ubuntu-22.04.4 镜像。
5. 分区类型根据情况进行选择。
6. 文件系统推荐选择 NTFS。

![rufus配置](https://gastigado.cnies.org/d/halo202406062045/4.rufus%E9%85%8D%E7%BD%AE.png?sign=fD4iZtp7pKtpXzdb5Ts5zy6EA61B9-7Ce8g6WxvVZ_I=:0)

7. 点击开始，选择“以 ISO 镜像 模式写入（推荐）”。

![以ISO模式写入](https://gastigado.cnies.org/d/halo202406062045/5.%E4%BB%A5ISO%E6%A8%A1%E5%BC%8F%E5%86%99%E5%85%A5.png?sign=sRIImsg-4MSmShSOO_M48bmuMgqKjfFehZcc5G0XB90=:0)

8. 等待状态的“准备就绪”为绿色状态，写入完成，关闭 Rufus 即可。

#### 使用 Ventory 制作多镜像启动盘

Ventoy 是一个制作可启动 U 盘的开源工具。有了 Ventoy 你就无需反复地像 Rufus 那样格式化 U 盘，你只需要把镜像文件或者可引导文件直接拷贝到 U 盘里面就可以启动了，无需其他操作。

你可以一次性复制多个不同类型的镜像文件。Ventoy 在启动时会显示一个菜单供您选择，同时它还允许您在 U 盘上存储其他文件，而不会影响其作为启动盘的功能。

![ventory界面](https://gastigado.cnies.org/d/halo202406062045/6.ventory%E7%95%8C%E9%9D%A2.png?sign=JlUBY2xwqWKiER3Nxk-5Q-3KQeTL8eFU6_de7KNxNJo=:0)

1. 访问 Ventory 下载页面 https://www.ventoy.net/cn/download.html
2. 下载 `ventoy-x.x.xx-windows.zip` 并解压
3. 你也可以在 [猹盘 -> 烧录工具](https://ed.qcea.top/ChaIndex/Softwares/Windows/System/Burning) 中下载 Ventory
4. 右键 -> 以管理员身份运行 `Ventoy2Disk.exe`
5. 根据情况，在配置选项中选择是否开启安全启动支持和分区类型

![ventory引导和分区](https://gastigado.cnies.org/d/halo202406062045/7.ventory%E5%BC%95%E5%AF%BC%E5%92%8C%E5%88%86%E5%8C%BA.png?sign=rVHsMyJM9u0mQ8c4pEw5rB1KYkjceshIq43H-4Se4IU=:0)

6. 选择正确的设备，点击安装

7. 安装完成后，将 ubuntu-22.04.4 镜像复制到 Ventoy 分区，并完成校验。

![ventory镜像复制](https://gastigado.cnies.org/d/halo202406062045/8.ventory%E9%95%9C%E5%83%8F%E5%A4%8D%E5%88%B6.png?sign=EhBXNsfV7YDB5hVy4ooRCQCUy69pFwcZ4OlnMFW_Vmo=:0)

## 安装 Ubuntu

### 磁盘分区

#### 分区方案

Ubuntu 官网要求 25 GB 可用硬盘空间。如果计划将 Ubuntu 作为日常使用，或者需要在 Ubuntu 完成较为重度的工作，建议留出 128 GB 或者 256 GB 的磁盘空间。

如果你财力雄厚，建议单独购买一块硬盘安装 Ubuntu，并在安装时拔下安装 Windows 的硬盘（哪怕是打算安装在移动硬盘中）。

如果你的磁盘空间划分给 Ubuntu 后仍有足够的保证正常使用的空间，课选择下面两种方法进行分区划分。

#### 操作前注意

**下面操作可能导致磁盘文件丢失，操作前请务必备份重要文件！**

**在进行每一步操作前，请再三确认是否正确后再进行操作，以免误删文件。**

#### 使用 Windows 磁盘管理从现有盘符划分空间

按下 Win + R 打开“运行”，输入 `diskmgmt.msc` 并回车。

![win磁盘管理](https://gastigado.cnies.org/d/halo202406062045/12.win%E7%A3%81%E7%9B%98%E7%AE%A1%E7%90%86.png?sign=WKtP-43M64GstpQNEA-fMPM8PnXpMX-TbELy-1smaBs=:0)

根据磁盘具体容量和自身需求选择分区。注意不要破坏 OEM 自带的恢复分区等。

如果希望进一步调整分区或需要调整 C 盘分区并且无法操作，[请参考下面的 PE 分区方法](#使用 DiskGenius 在 PE 下进行分区)。

- 右键想要操作的分区 -> 压缩卷 -> 输入压缩空间量 （如 128*1024 =131072）

![压缩卷](https://gastigado.cnies.org/d/halo202406062045/13.%E5%8E%8B%E7%BC%A9%E5%8D%B7.png?sign=p6wrEqZA85goVXFclbKeTObAW1OmfLgvejbu3-mxkZk=:0)

- 点击压缩，出现对应的未分配空间，压缩完成

![压缩完成](https://gastigado.cnies.org/d/halo202406062045/14.%E5%8E%8B%E7%BC%A9%E5%AE%8C%E6%88%90.png?sign=-S24J_KeqYu9hYfEnEMInE_FR925PdqhWtzs7otLeac=:0)

#### 使用 DiskGenius 在 PE 下进行分区

使用此方法进行分区，你首先需要 [使用 Ventory 制作多镜像启动盘](#使用 Ventory 制作多镜像启动盘)。

选择一个 PE 工具，推荐 [微PE工具箱](https://www.wepe.com.cn/)、[FirPE ](https://www.firpe.cn/?sid=U3FOqN)等优秀 PE 工具。在 PE 工具箱生成可启动的 ISO 文件，复制到 U 盘即可。你也可以直接在 [猹盘](https://ed.qcea.top/ChaIndex/Softwares/Windows/System/PE) 下载各种PE 的 ISO 镜像，复制到 U 盘并校验。

### 从 U 盘启动

先插入启动盘，重启进入 BIOS。

#### 进入 BIOS 设置

使用必应自行搜索，比如“联想小新 Air 14 进 BIOS”

![进bios](https://gastigado.cnies.org/d/halo202406062045/17.%E8%BF%9Bbios.png?sign=TpV-KgdCkkm6WfOAQ4mYD4uoRgv4knEy-r0Nw7UZi4o=:0)

目前市售主流笔记本进 BIOS 快捷键为 F2 或 Fn + F2 

#### 关闭安全启动

关闭安全启动（Security Boot），具体操作请自行使用必应搜索（如惠普战 66 关闭安全启动）

#### 从 U 盘引导的若干种方法

##### 高级重启

在 Windows 下，按住 Shift 键点击重启 -> 使用设备 -> 选择启动盘即可.

![高级启动](https://gastigado.cnies.org/d/halo202406062045/18.%E9%AB%98%E7%BA%A7%E5%90%AF%E5%8A%A8.png?sign=zYFUwZRHlrT1HM0jaHhkS-VpaqjBFGPigZxZF3u2K1s=:0)

具体步骤因品牌和系统版本有所不同。

##### 修改引导顺序

可以自行必应搜索各自型号修改引导顺序的方法，使对应引导方式的 U 盘引导在最前面即可。

![引导顺序](https://gastigado.cnies.org/d/halo202406062045/19.%E5%BC%95%E5%AF%BC%E9%A1%BA%E5%BA%8F.png?sign=M-E5GO13cmvvMkmdZuPdiSj23h2V81vTQ_kTObFKs88=:0)

![修改引导2](https://gastigado.cnies.org/d/halo202406062045/35.upan%E7%AC%AC%E4%B8%80.jpg?sign=difYwgac94o0-yHf_6va0UlF2iO_YMUs_y7rR7gnzC0=:0)

### Ubuntu 安装

1. 进入 Ubuntu 镜像，选择 `Try or Install Ubuntu` 。

![Try or Install Ubuntu](https://gastigado.cnies.org/d/halo202406062045/20.png?sign=FRQfTf6Dk2Xa73fryBQisuzP5KgQ0IZ0e1cEI0Aj0HM=:0)

2. 进入安装界面，左侧可以切换中文，但是推荐先使用英文进行安装。然后点击 `Install Ubuntu`。

![Install Ubuntu](https://gastigado.cnies.org/d/halo202406062045/21.png?sign=kvhnHgV35-XJEgCeO3eGEhNrVebJ_5AtBcLyOTO4aEw=:0)

3. 键盘布局，无特殊需求使用默认设置即可。

![键盘布局](https://gastigado.cnies.org/d/halo202406062045/22.png?sign=YMArhwOjgf9b23JejoJP5oLjFUZufMyNiZpwckuubjI=:0)

4. 使用默认设置即可，如有需求可以勾选“为图形或无线硬件，以及其它媒体格式安装第三方软件”（需要联网，并且安装时间较长）

![软件更新](https://gastigado.cnies.org/d/halo202406062045/23.png?sign=z5sq7mIkAg1vG2MwEegPDqkEjjUK-ffGGSDIhnO_Zow=:0)

5. 选择“安装 Ubuntu，与 Windows Boot Manager 共存”即可

![安装类型](https://gastigado.cnies.org/d/halo202406062045/24.png?sign=LQyGZ3kzU758YU-vuXia_tMoASbxVuykdhOkq8E0-wc=:0)

可以无脑确认，也可以通过“其他选项”手动选择划分好的空闲分区。

![安装位置确认](https://gastigado.cnies.org/d/halo202406062045/25.png?sign=dYeEmDkrTQivs_iWJME7MhwJpRR3FoB5l9ygLoBK7xI=:0)

注意，如果希望在不同磁盘安装 Ubuntu，并希望 Windows 和 Ubuntu 的引导独立，请务必在“其他选项”选择 Ubuntu 的安装位置后，在“安装启动引导器的设备”选择对应的引导磁盘。

如果采用双磁盘且为 UEFI + GPT，安装 Ubuntu 的磁盘需要建立这些分区（推荐）

| 挂载点    | 文件系统  | 大小（推荐）           |
| --------- | --------- | ---------------------- |
| /boot/efi | EFI System Partition | 1000 M                 |
| /boot     | Reserved BIOS boot area | 1000 M                 |
| /         | ext4      | 根据实际情况或者喜好确定           |
| /swap     | linuxswap | 设置为电脑运行内存大小 |

6. 选择区域，点击中国版图即可

![区域选择](https://gastigado.cnies.org/d/halo202406062045/26.png?sign=eWo5xrEYG1OWtH94Z1SOrZtLyL_CaSu0UF36F7AIp44=:0)

7. 设置用户名、计算机名称和密码。用户名推荐使用英文 + 数字，计算机名称推荐电脑型号 + 系统版本，密码推荐以字母开头。建议勾选自动登录；使用动态目录可以不勾选。

![用户名](https://gastigado.cnies.org/d/halo202406062045/27.png?sign=su-uZ99gVaeFVyUGHfXrwm2_0BgEkAqK12jH8Hetl4k=:0)

8. 耐心等待安装

![安装完成](https://gastigado.cnies.org/d/halo202406062045/28.png?sign=SfyKEPMpQm7zRO1O-OLoMnGOtlH8rZtf-1YAxoxa_1Q=:0)

9. 安装完成后，重启，拔出 U 盘后按下回车键即可

![移除安装介质](https://gastigado.cnies.org/d/halo202406062045/29.png?sign=7aLpeNdQ8zU5Z2aBOlCnav8MzXQEKQPtMEAggQKu7C8=:0)

## 如何切换 Windows 和 Ubuntu

Ubuntu 安装后的首次重启可以选择启动 Windows 还是 Ubuntu，默认为 Ubuntu。

![grub](https://gastigado.cnies.org/d/halo202406062045/30.png?sign=vPkCTJqRqeNV-SGkY9accDqbztxc9sRNzzi1m8ccSUA=:0)

如果日常使用 Windows，可以通过设置 BIOS 引导顺序默认启动 Windows。

![windows优先](https://gastigado.cnies.org/d/halo202406062045/33.Windows%E7%AC%AC%E4%B8%80.jpg?sign=sj-bHUjOj6VQIbISoxb6JWWYVU7vR_nsdI0o-t9JXVw=:0)

同理，要使用 Ubuntu 时，将 Ubuntu 切换至第一个即可。

![ubuntu优先](https://gastigado.cnies.org/d/halo202406062045/34.ubuntu%E7%AC%AC%E4%B8%80.jpg?sign=Xp7nRiY4EK-Fo8Qf-VspNb3a1JpkD12snrdQDLBe7rs=:0)

## 尾声

此时我们终于完成了 Windrows 11 和 Ubuntu 22.04 双系统的安装。对于如何在配置、美化 Ubuntu 并安装必要的软件，请查看这篇文章 -> [《Ubuntu 安装、配置、美化和日常使用》](https://hs.cnies.org/archives/ubuntu-installation-and-daily-usage-guide)

安装完成重启到 Windows，发现时间慢了 12 小时，右键右下角时钟 -> 调整日期和时间 -> 立即同步 即可。

![自动调整时间](https://gastigado.cnies.org/d/halo202406062045/36.%E8%B0%83%E6%95%B4%E6%97%B6%E9%97%B4.png?sign=LfmjtGSDFag8NN9XH1DWGFJfSQWTq-wODC9np-WPVSw=:0)

----

## 参考和引用

[Arch + Windows 双系统 - Arch Linux 中文维基 (archlinuxcn.org)](https://wiki.archlinuxcn.org/wiki/Arch_%2B_Windows_双系统)

[分区 - Arch Linux 中文维基 (archlinuxcn.org)](https://wiki.archlinuxcn.org/wiki/分区)

[EFI 系统分区 - Arch Linux 中文维基 (archlinuxcn.org)](https://wiki.archlinuxcn.org/wiki/EFI_系统分区)

[UEFI - Arch Linux 中文维基 (archlinuxcn.org)](https://wiki.archlinuxcn.org/wiki/UEFI#在_32_位_UEFI_上启动_64_位内核)

[[Windows 11\] 如何关闭设备加密与标准BitLocker加密 | 官方支持 | ASUS 中国](https://www.asus.com.cn/support/faq/1047461/#A2)

[【装机教程】超详细WIN10系统安装教程，官方ISO直装与PE两种方法教程，UEFI+GUID分区与Legacy+MBR分区-哔哩哔哩-bilibili](https://www.bilibili.com/video/BV1DJ411D79y/)

[猹盘 - 一个芜湖起飞的网盘 (qcea.top)](https://ed.qcea.top/)

[How To Install Ubuntu Along With Windows (itsfoss.com)](https://itsfoss.com/install-ubuntu-dual-boot-mode-windows/)

[Beginners Guide to Install Windows With Ubuntu in Dual Boot (itsfoss.com)](https://itsfoss.com/install-ubuntu-1404-dual-boot-mode-windows-8-81-uefi/)

[Dual Booting Ubuntu and Windows With a SSD and a HDD (itsfoss.com)](https://itsfoss.com/dual-boot-hdd-ssd/)

[How to Install Windows After Ubuntu Linux in Dual Boot (itsfoss.com)](https://itsfoss.com/install-windows-after-ubuntu-dual-boot/)

[[Fixed\] No Grub Screen in Dual Boot， System Boots in Windows (itsfoss.com)](https://itsfoss.com/no-grub-windows-linux/)

[How to Uninstall Ubuntu from Windows Dual Boot Safely (itsfoss.com)](https://itsfoss.com/uninstall-ubuntu-linux-windows-dual-boot/)

[Ventoy](https://www.ventoy.net/cn/)
