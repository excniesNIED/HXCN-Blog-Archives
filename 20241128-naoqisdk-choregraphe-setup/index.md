---
title: 从零配置 Choregraphe 和 NAOqi SDK
pubDatetime: 2024-11-28T00:00:00.000+08:00
slug: naoqisdk-choregraphe-setup
tags:
  - NAO
  - NAOqi SDK
  - Choregraphe
  - Python 2.7
  - Python
  - Pycharm
category: 技术教程
description: Choregraphe 和 NAOqi SDK 环境配置教程，从零讲解安装 Python 2.7、配置环境变量、下载并设置 NAOqi SDK、在 PyCharm 中添加解释器、运行 ALProxy 测试和安装 Choregraphe 连接 NAO 机器人。适合机器人竞赛和 NAO 开发新手。
---

本教程适用于 **NAO 机器人连接、Choregraphe 安装、NAOqi SDK 配置** 等环境搭建内容，主要面向初学者完成比赛和开发前的基础配置。本文以 Windows 系统为例，Linux 系统配置思路同理。想要安装 Linux 双系统或者虚拟机请阅读下面教程：

[从零开始：2026年Ubuntu 24.04 LTS + Win11双系统安装教程](https://hs.cnies.org/archives/dual-boot-ubuntu2404-win11)

[安装年轻人的第一个 Linux 虚拟机](https://ain.hmgf.hxcn.space/guides/first-vm-2024)

更多竞赛教程和相关信息，欢迎访问 **环梦工坊编程竞赛组知识库**：https://ain.hmgf.hxcn.space/

也欢迎 **山东师范大学** 的师弟师妹加入 **环梦工坊编程竞赛组**（QQ 群：**915668300**），一起交流学习、参与项目和编程竞赛。

### 安装 Python 2.7

访问下面任意网址下载 Python **2.7** 安装包（Windows x86-64 MSI installer）

[https://www.python.org/download/releases/2.7](https://www.python.org/download/releases/2.7)

[https://www.python.org/downloads/release/python-2718/](https://www.python.org/downloads/release/python-2718/)

[https://mirrors.aliyun.com/python-release/](https://mirrors.aliyun.com/python-release/)

选择“为所有用户安装”，然后一路下一步（记住安装位置）

![image.png](https://gastigado.cnies.org/d/halo20241128-naoqisdk-choregraphe-setup/image.png)

为 Python 2.7 添加环境变量。按 Win+s 搜索“高级系统设置”并打开，选择“环境变量”，在“系统变量”下找到“Path”，点击“编辑”，将 `Python 2.7 安装路径` 和 `Python 2.7 安装路径/Scripts` 添加到最后一行（图示安装在`C:\Python27\`下），然后点击确定。

![image.png](https://gastigado.cnies.org/d/halo20241128-naoqisdk-choregraphe-setup/image%201.webp)

![fb630b0ba55167147671e003a6e07d13.png](https://gastigado.cnies.org/d/halo20241128-naoqisdk-choregraphe-setup/fb630b0ba55167147671e003a6e07d13.webp)

如果你的电脑安装了多个版本的 Python，可以为 Python 2.7 设置别名方便区分：

![image.png](https://gastigado.cnies.org/d/halo20241128-naoqisdk-choregraphe-setup/image%202.webp)

Linux 可以根据发行版下载对应的软件包安装，也可以使用二进制安装，并完成环境变量和别名的配置。

### 安装 NAOqi SDK

访问下面链接下载

[https://www.aldebaran.com/en/support/nao-6/downloads-softwares](https://www.aldebaran.com/en/support/nao-6/downloads-softwares)

![image.png](https://gastigado.cnies.org/d/halo20241128-naoqisdk-choregraphe-setup/image%203.webp)

下载完成后，将压缩包解压到一个不易被删除的位置，并记住这个路径（打开这个路径包含以下文件）

![image.png](https://gastigado.cnies.org/d/halo20241128-naoqisdk-choregraphe-setup/image%204.webp)

为 NAOqi SDK 添加环境变量。在“用户变量”中执行“新建”操作，变量名为 `PYTHONPATH` ，变量值设定为 `NAOqi SDK的路径/lib` ，然后确定即可。

![image.png](https://gastigado.cnies.org/d/halo20241128-naoqisdk-choregraphe-setup/image%205.webp)

想要验证 NAOqi SDK 是否被正确配置，按 Win + x 打开终端或者 Powershell，运行 Python 2.7，在 Python 控制台输入 `import naoqi` ，无错误输出证明配置成功。

![image.png](https://gastigado.cnies.org/d/halo20241128-naoqisdk-choregraphe-setup/image%206.webp)

### 为 Pycharm 添加 Python2.7 解释器

访问 [https://ain.hmgf.hxcn.space/resource/lesson0-2025#jetbrains-全家桶](https://ain.hmgf.hxcn.space/resource/lesson0-2025#jetbrains-%E5%85%A8%E5%AE%B6%E6%A1%B6)查看 Pycharm 专业版申请方法

运行 Pycharm，点击文件 - 设置（或者按下 Ctrl + Alt + S），添加本地已有的解释器即可

![image.png](https://gastigado.cnies.org/d/halo20241128-naoqisdk-choregraphe-setup/image%207.webp)

解释器配置成功后，运行下面代码

```python
from naoqi import ALProxy

IP = "127.0.0.1"
Port = 9559
motionProxy = ALProxy("ALMotion", IP, Port)
```

运行后出现类似下面结果，则证明配置成功

```bash
C:\Python27\python.exe D:\LERNAS\BOT211\Daily\20241128\main.py 
[W] 1732796951.982959 29384 qi.path.sdklayout: No Application was created, trying to deduce paths
[I] 1732796951.991978 29384 qimessaging.session: Session listener created on tcp://0.0.0.0:0
[I] 1732796952.216920 29384 qimessaging.transportserver: TransportServer will listen on: tcp://192.168.43.23:1340
[I] 1732796952.216920 29384 qimessaging.transportserver: TransportServer will listen on: tcp://172.26.48.1:1340
[I] 1732796952.216920 29384 qimessaging.transportserver: TransportServer will listen on: tcp://172.20.80.1:1340
[I] 1732796952.216920 29384 qimessaging.transportserver: TransportServer will listen on: tcp://169.254.130.167:1340
[I] 1732796952.216920 29384 qimessaging.transportserver: TransportServer will listen on: tcp://127.0.0.1:1340
[W] 1732796954.253943 6628 qitype.signal: disconnect: No subscription found for SignalLink 18446744073709551615.
```

### 安装 Choregraphe

访问下面链接下载安装包：

[https://corporate-internal-prod.aldebaran.com/en/support/nao-6/downloads-softwares](https://corporate-internal-prod.aldebaran.com/en/support/nao-6/downloads-softwares)

Windows 下载安装版即可，Linux 可以根据需求下载安装脚本或者二进制文件。

以管理员身份运行安装包，一路下一步即可。

安装完成后，运行 Choregraphe 主程序：

![image.png](https://gastigado.cnies.org/d/halo20241128-naoqisdk-choregraphe-setup/image%208.webp)

点击”连接” - “连接至”，输入机器人 IP 地址以连接。

![image.png](https://gastigado.cnies.org/d/halo20241128-naoqisdk-choregraphe-setup/image%209.webp)
