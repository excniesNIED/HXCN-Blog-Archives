Linux 是开源操作系统内核，广泛用于服务器和开发环境。Ubuntu 是一个基于 Linux 的开源操作系统，以用户友好和稳定性著称。Ubuntu 以高安全性著称，漏洞少，权限管理严格。相较于 Windows 系统它的稳定性和性能优异，适合各种硬件。

对于开发者而言，Ubuntu 预装了众多开发工具，如 GCC 编译器和 Python 解释器，方便快速上手。POSIX 兼容环境的重要性再怎么强调都不为过。当您在 Windows 上为 CRLF 换行符导致的构建错误抓狂时，Git 在 Ubuntu 中会自然地保持 LF 格式的纯粹性；当您需要编译 Rust crate 时，不必在 MSVC 和 MinGW 之间做两难选择。

本文将简单直白介绍如何从零开始在同一台电脑上安装 Ubuntu 24.04 LTS 和 Windows 11，你可以在需要进行专业开发或运维工作时，轻松切换到 Ubuntu，享受其带来的高效与自由；而在日常学习生活和娱乐休闲时，依然可以无缝使用熟悉的 Windows 环境。

## 安装前的准备工作

本人采用默认搭载的 Windows 11 的华硕天选 4 笔记本（市售主流笔记本）。如果你的笔记本电脑购买时间在 5 年以内，可以直接参考本教程。如果你的电脑较为老旧或者是信创等特殊机器，可以参考下面教程，根据实际情况对部分步骤进行调整。

https://hs.cnies.org/archives/dual-boot-ubuntu-2204-and-windows-11

### 1. 关闭设备加密

按 Win + s ，在 Windows 搜索栏输入“设备加密设置”。

![1](https://gastigado.cnies.org/d/halo20250323dual_boot/9.%E8%AE%BE%E5%A4%87%E5%8A%A0%E5%AF%86%E5%85%B3%E9%97%AD1.png?sign=P6X39hy0B1BEwr2dBowIGTMZKTwV4AQTnYIgn_LN3TQ=:0)

在设备加密栏位，设置为“关闭”。

![2](https://gastigado.cnies.org/d/halo20250323dual_boot/10.%E5%85%B3%E9%97%AD%E8%AE%BE%E5%A4%87%E5%8A%A0%E5%AF%862.png?sign=pkhdV3tl6So4Mc_x1BAcJDElXL7LD5HHLxW-hvmLpvg=:0)

系统会提醒您是否需要关闭设备加密，点选“关闭”即可关闭设备加密。

![3](https://gastigado.cnies.org/d/halo20250323dual_boot/11.%E5%85%B3%E9%97%AD%E8%AE%BE%E5%A4%87%E5%8A%A0%E5%AF%863.png?sign=7_6ozhBSQQiQUHprDc4d0cefLO-LgIbiThTlQr7CCk8=:0)

### 2. 关闭 Bitlocker

打开“控制面板”，选择系统和安全 -> Bitlocker 驱动器加密

![4](https://gastigado.cnies.org/d/halo20250323dual_boot/32.Bitlocker.png?sign=Pa-qmWxrS00w_FWYFd1SoT653hpJkw99kGJ2pfKjBAs=:0)

如果所有驱动器处于“Bitlocker 已关闭”状态，可以跳过这个步骤。

如果 Bitlocker 已启用，点击“备份恢复密钥”，保存到 Microsoft 帐户或者保存到文件。如果保存到文件，请尽可能对恢复密钥进行多次备份，避免恢复密钥丢失。

点击“关闭 Bitlocker”，并等待解密完成。

如果无法关闭 Bitlocker，请先关闭“设备加密”。

### 3. 关闭休眠和快速启动

控制面板 -> 系统和安全 -> 电源选项 -> 选择电源按钮功能，点击“更改当前不可用的设置”

![5](https://gastigado.cnies.org/d/halo20250323dual_boot/15.%E7%94%B5%E6%BA%90%E8%AE%A1%E5%88%921.png?sign=svOEwf7X1fOa_-_wHwzFOF6aKzJSjQDUHJEGMU0gYQM=:0)

取消选择“启用快速启动”和“休眠”

![5](https://gastigado.cnies.org/d/halo20250323dual_boot/16.%E7%94%B5%E6%BA%90%E8%AE%A1%E5%88%92%E5%85%B3%E6%9C%BA%E8%AE%BE%E7%BD%AE.png?sign=yf4yWrolvh1P0dzzvW-JMDcclPJ5qTc-hyA5Sxh6M88=:0)

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

![5](https://gastigado.cnies.org/d/halo20250323dual_boot/7_1742795575110_94.png?sign=S7Ll4W9QPgGgmA0sKpmg36a9_l2MsroNBJb6zf0q834=:0)

#### 猹盘 Linux 系统镜像

高速下载，无广告

https://ed.qcea.top/ChaIndex/Systems/Linux/Ubuntu

### 2. 制作启动盘

**使用 U 盘制作启动盘会进行格式化操作，清除 U 盘全部数据。在进行该操作之前，务必对 U 盘全部文件进行备份！**

**关闭 360 安全卫士等杀毒软件，以免影响启动盘制作。**

Ventoy 是一个制作可启动 U 盘的开源工具。有了 Ventoy 你就无需反复地格式化 U 盘，你只需要把镜像文件或者可引导文件直接拷贝到 U 盘里面就可以启动了，无需其他操作。你可以一次性复制多个不同类型的镜像文件，也可以在 U 盘正常保存其他文件。

访问 Ventory 下载页面 https://www.ventoy.net/cn/download.html，下载 `ventoy-x.x.xx-windows.zip` 并解压。你也可以在 [猹盘 -> 烧录工具](https://ed.qcea.top/ChaIndex/Softwares/Windows/System/Burning) 中下载 Ventory。

右键 -> 以管理员身份运行 `Ventoy2Disk.exe`，在“配置选项”中选择开启“安全启动支持”和 GPT 分区类型。

![5](https://gastigado.cnies.org/d/halo20250323dual_boot/7.ventory%E5%BC%95%E5%AF%BC%E5%92%8C%E5%88%86%E5%8C%BA.png?sign=QteTu27S58iQgyXYkXiSOfVYn_laMd3pQWlXHyyeboE=:0)

选择想要制作镜像的 U 盘，点击安装。

安装完成后，将 Ubuntu 24.04 镜像复制到 Ventoy 分区，并使用 [HashMyFiles](https://ed.qcea.top/ChaIndex/Softwares/Windows/Hash) 等工具校验。

![5](https://gastigado.cnies.org/d/halo20250323dual_boot/8.ventory%E9%95%9C%E5%83%8F%E5%A4%8D%E5%88%B6.png?sign=zOpMk3cP_j8jokaVqOO9c6mYE-q6mjqaxL45Npl9LLo=:0)

## 引导 Ubuntu 安装 U 盘

**下面操作可能导致磁盘文件丢失，操作前请务必备份重要文件！**

**在进行每一步操作前，请再三确认是否正确后再进行操作，以免失误格式化无关文件。**

### 1. 关闭安全引导

使用必应自行搜索如何进入 BIOS，比如“联想小新 Air 14 进 BIOS”

![5](https://gastigado.cnies.org/d/halo20250323dual_boot/17.%E8%BF%9Bbios.png?sign=WdHWwowEDjW1p_629wsscN71b5MbwO0-agE2nfdQZ9U=:0)

大部分笔记本电脑为 F2 或 Fn+F2

在 BIOS 中找到并关闭安全启动（Security Boot）。可以自行使用必应搜索（如惠普战 66 关闭安全启动）寻找教程。

如果你的电脑是 8 代以后的 Intel 处理器，请顺带关闭 VMD 控制器。

### 2. 修改引导顺序

可以自行必应搜索各自型号修改引导顺序的方法，使对应引导方式的 U 盘引导在最前面即可。

![12](https://gastigado.cnies.org/d/halo20250323dual_boot/35.upan%E7%AC%AC%E4%B8%80.jpg?sign=YTGHVs3Hs-jto4LAqTAzrSkCJE8qJGZADhXj-FIMvQM=:0) ![11](https://gastigado.cnies.org/d/halo20250323dual_boot/19.%E5%BC%95%E5%AF%BC%E9%A1%BA%E5%BA%8F.png?sign=PTEQF-mK45MWHnnKyHgd2XtRUwTMOVSe6xC_3BmPCBo=:0)

### 高级重启

如果你的电脑不方便进入 BIOS，可以在 Windows 下，按住 Shift 键点击重启 -> 使用设备 -> 选择启动盘即可.

![11](https://gastigado.cnies.org/d/halo20250323dual_boot/18.%E9%AB%98%E7%BA%A7%E5%90%AF%E5%8A%A8.png?sign=btRajezoh7pgKDQuI_5OK3TeIDrcXEyBWfZYd2u8_SY=:0)

## Ubuntu 安装

进入 Ubuntu 镜像，选择 `Try or Install Ubuntu` 。

![install (0)](https://gastigado.cnies.org/d/halo20250323dual_boot/20.png?sign=N36lp2YJ1GjzwWUBT6Qlp7HMfc6K8ClyFqFEJHMvz40=:0)

进入安装界面，在此可以切换中文：

![install (1)](https://gastigado.cnies.org/d/halo20250323dual_boot/install_1_.png?sign=6l-IRGJ5cEIpYhpimS6NOzZ-OtC3agJEuvtTCheXCUo=:0)

无障碍设置，可以直接跳过，如果有使用需求可以进行设置：

![install (2)](https://gastigado.cnies.org/d/halo20250323dual_boot/install_2_.png?sign=zEB1RTaWXMHFm7CHlVFoNsk91EffTJwftxDQCOri6tE=:0)

键盘布局默认选择汉语，可以直接下一步

![install (3)](https://gastigado.cnies.org/d/halo20250323dual_boot/install_3_.png?sign=HPW-zKM68qbAXFenzOU6c3yfQ86SzGgMlBBNXKQVYj4=:0)

连接有线或无线网络

![install (4)](https://gastigado.cnies.org/d/halo20250323dual_boot/install_4_.png?sign=eGK9SY8IB0URjJXmZi9fwnIJMWSqo8-g6OjiTt1qWq4=:0)

如果提示安装程序有可用更新可以跳过

![install (5)](https://gastigado.cnies.org/d/halo20250323dual_boot/install_5_.png?sign=a7pJ8Q-bce8fUWdVprbXCUS6zg2kv45SjcleNZ3vdJ4=:0)

选择“安装 Ubuntu”

![install (6)](https://gastigado.cnies.org/d/halo20250323dual_boot/install_6_.png?sign=y893na0tTAgN7DKlNniRZDLqZXOeNEVEvi4YWTW8-M4=:0)

选择“交互安装”

![install (7)](https://gastigado.cnies.org/d/halo20250323dual_boot/install_7_.png?sign=4sfujfW2BCt3FxSDpKta4SpGebDQq2V9VU0-g3cg8P0=:0)

选择“默认集合”，如果有需要可以选择“扩展集合”

![install (8)](https://gastigado.cnies.org/d/halo20250323dual_boot/install_8_.png?sign=Cdbx2oEpLypAewXc9ScNdOMOdL_En-850HARo4o9cp8=:0)

推荐全部勾选，可以自动安装一些必要软件和驱动

![install (9)](https://gastigado.cnies.org/d/halo20250323dual_boot/install_9_.png?sign=zguko-Kz7JItsbyCaZVZXJ_MB50kMG3p0w2J8-tv6gM=:0)

如果只需要简单安装 Windows 和 Ubuntu 双系统，选择“在 Windows Boot Manager 中安装 Ubuntu”

![install (10)](https://gastigado.cnies.org/d/halo20250323dual_boot/install_10_.png?sign=iWLuIt2_0lsl2Aem1-lUT-Lo8GL_DCNOwmBLAlYaZ7c=:0)

根据需求调整 Ubuntu 分区大小，建议 64G 以上。如果需要在 Ubuntu 完成较为重度的工作，建议留出 128 GB 或者 256 GB 的磁盘空间。

![install (10.5)](https://gastigado.cnies.org/d/halo20250323dual_boot/install_10.5_.png?sign=Xblcokz5xGLAXwLcsbCI3kqtvf2MFpCLs6WIiCpA5Rc=:0)

如果需要手动分区请选择“手动分区”，根据需求进行分区。以下是需要添加的基本分区类型和大小参考：

| 挂载点    | 文件系统                | 大小（推荐）             |
| --------- | ----------------------- | ------------------------ |
| /boot/efi | EFI System Partition    | 1000 M                   |
| /boot     | Reserved BIOS boot area | 1000 M                   |
| /         | ext4                    | 根据实际情况或者喜好确定 |
| /swap     | linuxswap               | 设置为电脑运行内存大小   |

根据需求设置用户名和密码

![install (12)](https://gastigado.cnies.org/d/halo20250323dual_boot/install_12_.png?sign=uRlJg_45e3-MM6a11iOCQBNMRrZcz2FSokJjlHGFyuk=:0)

时区默认使用“中国上海”即可

![install (13)](https://gastigado.cnies.org/d/halo20250323dual_boot/install_13_.png?sign=qK0sZt9Ztwy1r16CS9v79xDsGuIqQ0fiYHQhC_BsKvU=:0)

点击“安装”正式开始安装

![install (14)](https://gastigado.cnies.org/d/halo20250323dual_boot/install_14_.png?sign=pLOrskn9Y4jLja8EP1BYfko2qJ-F9HI9D8sbh7EAicw=:0)

等待安装

![install (15)](https://gastigado.cnies.org/d/halo20250323dual_boot/install_15_.png?sign=njRZO_0rf2RWiCrxAm2EciRZ0g1wgKpeZulX53sTRWg=:0)

安装完成后，选择“立即”，拔出 U 盘后按下回车键即可

![install (15.2)](https://gastigado.cnies.org/d/halo20250323dual_boot/install_15.2_.png?sign=_2-okpT1ZZXKKOT5ZhWKdW2hOMBtQE0l3pkRlUIYOvw=:0)

![install (15)](https://gastigado.cnies.org/d/halo20250323dual_boot/29.png?sign=br2ZKLf_tWbdIZVLZEuIMviWT4nN2nEGlgfeE1Ph7CQ=:0)

## 如何切换 Windows 和 Ubuntu

Ubuntu 安装后的首次重启可以选择启动 Windows 还是 Ubuntu，默认为 Ubuntu。

![01](https://gastigado.cnies.org/d/halo20250323dual_boot/30.png?sign=zOKod5um-CrTYhGeIwiVj3bmj5xkBho3IRN-U2AL-og=:0)

如果日常使用 Windows，可以通过设置 BIOS 引导顺序默认启动 Windows。

![02](https://gastigado.cnies.org/d/halo20250323dual_boot/33.Windows%E7%AC%AC%E4%B8%80.jpg?sign=Hf3U2twA7vxnYJJyDBSFZBN7QR5CMfAzz-RdgMfaYI0=:0)

同理，要使用 Ubuntu 时，将 Ubuntu 切换至第一个即可。

![03](https://gastigado.cnies.org/d/halo20250323dual_boot/34.ubuntu%E7%AC%AC%E4%B8%80.jpg?sign=RnsEpAg8A-w94ja4Rshn11Rmx3JbZcmol3HA1LgfHnw=:0)

安装完成重启到 Windows，发现时间慢了 12 小时，右键右下角时钟 -> 调整日期和时间 -> 立即同步 即可。

![36.调整时间](https://gastigado.cnies.org/d/halo20250323dual_boot/36.%E8%B0%83%E6%95%B4%E6%97%B6%E9%97%B4.png?sign=nQGizPx6QtSS3rQnvUSZIqXtrZ0ntuf54HCEXPtg0w0=:0)

## 其他

此时我们终于完成了 Windows 11 和 Ubuntu 24.04 双系统的安装。安装完成后需要进行一些必要的配置、软件安装，请关注后续更新。也可以根据喜好进行美化，请关注后续更新。
