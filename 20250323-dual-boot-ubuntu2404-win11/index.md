Linux 是开源操作系统内核，广泛用于服务器和开发环境。Ubuntu 是一个基于 Linux 的开源操作系统，以用户友好和稳定性著称。Ubuntu 以高安全性著称，漏洞少，权限管理严格。相较于 Windows 系统它的稳定性和性能优异，适合各种硬件。

对于开发者而言，Ubuntu 预装了众多开发工具，如 GCC 编译器和 Python 解释器，方便快速上手。POSIX 兼容环境的重要性再怎么强调都不为过。当您在 Windows 上为 CRLF 换行符导致的构建错误抓狂时，Git 在 Ubuntu 中会自然地保持 LF 格式的纯粹性；当您需要编译 Rust crate 时，不必在 MSVC 和 MinGW 之间做两难选择。

本文将简单直白介绍如何从零开始在同一台电脑上安装 Ubuntu 24.04 LTS 和 Windows 11，你可以在需要进行专业开发或运维工作时，轻松切换到 Ubuntu，享受其带来的高效与自由；而在日常学习生活和娱乐休闲时，依然可以无缝使用熟悉的 Windows 环境。

## 安装前的准备工作

本人采用默认搭载的 Windows 11 的华硕天选 4 笔记本（市售主流笔记本）。如果你的笔记本电脑购买时间在 5 年以内，可以直接参考本教程。如果你的电脑较为老旧或者是信创等特殊机器，可以参考下面教程，根据实际情况对部分步骤进行调整。

https://hs.cnies.org/archives/dual-boot-ubuntu-2204-and-windows-11

### 1. 关闭设备加密

按 Win + s ，在 Windows 搜索栏输入“设备加密设置”。

![1](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\1.png)

在设备加密栏位，设置为“关闭”。

![2](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\2.png)

系统会提醒您是否需要关闭设备加密，点选“关闭”即可关闭设备加密。

![3](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\3.png)

### 2. 关闭 Bitlocker

打开“控制面板”，选择系统和安全 -> Bitlocker 驱动器加密

![4](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\4.png)

如果所有驱动器处于“Bitlocker 已关闭”状态，可以跳过这个步骤。

如果 Bitlocker 已启用，点击“备份恢复密钥”，保存到 Microsoft 帐户或者保存到文件。如果保存到文件，请尽可能对恢复密钥进行多次备份，避免恢复密钥丢失。

点击“关闭 Bitlocker”，并等待解密完成。

如果无法关闭 Bitlocker，请先关闭“设备加密”。

### 3. 关闭休眠和快速启动

控制面板 -> 系统和安全 -> 电源选项 -> 选择电源按钮功能，点击“更改当前不可用的设置”

![5](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\5.png)

取消选择“启用快速启动”和“休眠”

![5](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\6.png)

### 4. 关闭 Windows 更新

安装 Ubuntu 和 Windows 双系统建议关闭 Windows 更新。Windows 更新往往会带来更多的 Bug，并可能导致 Ubuntu 无法启动。在安装 Ubuntu 后尽可能不使用 Windows 更新。

Windows 更新默认最大暂停更新 5 周，你可以在 5 周后继续延期，也可以自行搜索如何通过编辑组策略无限延期。如果你使用的是 Windows 家庭版，可以下载 [延期  1000  周注册表修改文件](https://ed.qcea.top/ChaIndex/Softwares/Windows/System/Setting_Tools/windows-1000weeks-update-blocker.reg) 通过修改注册表延期 1000 周（更为安全），或者下载 [阻止更新相关软件](https://ed.qcea.top/ChaIndex/Softwares/Windows/System/Setting_Tools/Windows%20Update%20Blocker%20v1.6%EF%BC%88%E9%98%BB%E6%AD%A2win10%E8%87%AA%E5%8A%A8%E6%9B%B4%E6%96%B0%EF%BC%89.zip)，通过移除 Windows 更新组件进行延期（可能造成系统组件损坏）。

## 制作启动盘

### 1. 下载 Ubuntu 24.04 镜像

我们需要下载 Ubuntu 22.04 的 LTS 版本，LTS（Long Time Service）代表长期支持，比起最新的 Ubuntu 24.10（2025 年 3 月底）普通版本，它们都将获得 5 年的技术支持和安全更新，更加稳定。

你可以从下面途径下载 Ubuntu 24.04 LTS：

#### Ubuntu 官网

下载地址：https://ubuntu.com/download/desktop

#### 开源镜像站（以清华大学开源软件镜像站为例）

访问 [清华大学开源镜像站](https://mirrors.tuna.tsinghua.edu.cn)，点击右侧“下载链接”下的“获取下载链接”，

![5](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\7.png)

#### 猹盘 Linux 系统镜像

高速下载，无广告

https://ed.qcea.top/ChaIndex/Systems/Linux/Ubuntu

### 2. 制作启动盘

**使用 U 盘制作启动盘会进行格式化操作，清除 U 盘全部数据。在进行该操作之前，务必对 U 盘全部文件进行备份！**

**关闭 360 安全卫士等杀毒软件，以免影响启动盘制作。**

Ventoy 是一个制作可启动 U 盘的开源工具。有了 Ventoy 你就无需反复地格式化 U 盘，你只需要把镜像文件或者可引导文件直接拷贝到 U 盘里面就可以启动了，无需其他操作。你可以一次性复制多个不同类型的镜像文件，也可以在 U 盘正常保存其他文件。

访问 Ventory 下载页面 https://www.ventoy.net/cn/download.html，下载 `ventoy-x.x.xx-windows.zip` 并解压。你也可以在 [猹盘 -> 烧录工具](https://ed.qcea.top/ChaIndex/Softwares/Windows/System/Burning) 中下载 Ventory。

右键 -> 以管理员身份运行 `Ventoy2Disk.exe`，在“配置选项”中选择开启“安全启动支持”和 GPT 分区类型。

![5](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\8.png)

选择想要制作镜像的 U 盘，点击安装。

安装完成后，将 Ubuntu 24.04 镜像复制到 Ventoy 分区，并使用 [HashMyFiles](https://ed.qcea.top/ChaIndex/Softwares/Windows/Hash) 等工具校验。

![5](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\9.png)

## 引导 Ubuntu 安装 U 盘

**下面操作可能导致磁盘文件丢失，操作前请务必备份重要文件！**

**在进行每一步操作前，请再三确认是否正确后再进行操作，以免失误格式化无关文件。**

### 1. 关闭安全引导

使用必应自行搜索如何进入 BIOS，比如“联想小新 Air 14 进 BIOS”

![5](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\10.png)

大部分笔记本电脑为 F2 或 Fn+F2

在 BIOS 中找到并关闭安全启动（Security Boot）。可以自行使用必应搜索（如惠普战 66 关闭安全启动）寻找教程。

如果你的电脑是 8 代以后的 Intel 处理器，请顺带关闭 VMD 控制器。

### 2. 修改引导顺序

可以自行必应搜索各自型号修改引导顺序的方法，使对应引导方式的 U 盘引导在最前面即可。

![12](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\12.jpg) ![11](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\11.png)

### 高级重启

如果你的电脑不方便进入 BIOS，可以在 Windows 下，按住 Shift 键点击重启 -> 使用设备 -> 选择启动盘即可.

![11](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\13.png)

## Ubuntu 安装

进入 Ubuntu 镜像，选择 `Try or Install Ubuntu` 。

![install (0)](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\install (0).png)

进入安装界面，在此可以切换中文：

![install (1)](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\install (1).png)

无障碍设置，可以直接跳过，如果有使用需求可以进行设置：

![install (2)](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\install (2).png)

键盘布局默认选择汉语，可以直接下一步

![install (3)](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\install (3).png)

连接有线或无线网络

![install (4)](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\install (4).png)

如果提示安装程序有可用更新可以跳过

![install (5)](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\install (5).png)

选择“安装 Ubuntu”

![install (6)](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\install (6).png)

选择“交互安装”

![install (7)](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\install (7).png)

选择“默认集合”，如果有需要可以选择“扩展集合”

![install (8)](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\install (8).png)

推荐全部勾选，可以自动安装一些必要软件和驱动

![install (9)](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\install (9).png)

如果只需要简单安装 Windows 和 Ubuntu 双系统，选择“在 Windows Boot Manager 中安装 Ubuntu”

![install (10)](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\install (10).png)

根据需求调整 Ubuntu 分区大小，建议 64G 以上。如果需要在 Ubuntu 完成较为重度的工作，建议留出 128 GB 或者 256 GB 的磁盘空间。

![install (10.5)](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\install (10.5).png)

如果需要手动分区请选择“手动分区”，根据需求进行分区。以下是需要添加的基本分区类型和大小参考：

| 挂载点    | 文件系统                | 大小（推荐）             |
| --------- | ----------------------- | ------------------------ |
| /boot/efi | EFI System Partition    | 1000 M                   |
| /boot     | Reserved BIOS boot area | 1000 M                   |
| /         | ext4                    | 根据实际情况或者喜好确定 |
| /swap     | linuxswap               | 设置为电脑运行内存大小   |

根据需求设置用户名和密码

![install (12)](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\install (12).png)

时区默认使用“中国上海”即可

![install (13)](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\install (13).png)

点击“安装”正式开始安装

![install (14)](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\install (14).png)

等待安装

![install (15)](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\install (15).png)

安装完成后，重启，拔出 U 盘后按下回车键即可

![install (15)](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\install (15.5).png)

## 如何切换 Windows 和 Ubuntu

Ubuntu 安装后的首次重启可以选择启动 Windows 还是 Ubuntu，默认为 Ubuntu。

![01](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\18.png)

如果日常使用 Windows，可以通过设置 BIOS 引导顺序默认启动 Windows。

![02](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\15.jpg)

同理，要使用 Ubuntu 时，将 Ubuntu 切换至第一个即可。

![03](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\16.jpg)

安装完成重启到 Windows，发现时间慢了 12 小时，右键右下角时钟 -> 调整日期和时间 -> 立即同步 即可。

![36.调整时间](D:\elab\HXCN-Halo-Archives\20250323-dual-boot-ubuntu2404-win11\17.png)

## 其他

此时我们终于完成了 Windows 11 和 Ubuntu 24.04 双系统的安装。安装完成后需要进行一些必要的配置、软件安装，请关注后续更新。也可以根据喜好进行美化，请关注后续更新。
