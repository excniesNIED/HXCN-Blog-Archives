刚开始我在 Windows 使用 MSYS2 MinGW 编译 Webots，但 Win 下涉及依赖和环境变量太多，难以逐一排查；链接库也出现很多问题。遂放弃 MSYS2 编译，转而使用 WSL 编译，参考 [仓库 Wiki 教程](https://github.com/cyberbotics/webots/wiki/Linux-installation/) 通过 WSL GUI 运行 Webots。

## 仓库克隆和子仓库克隆

默认使用 WSL 原本配置，然后使用下面命令克隆仓库和子仓库到 `~` 下：

```bash
git clone --recurse-submodules -j8 https://github.com/cyberbotics/webots.git
cd webots
```

项目较大，可以自行 fork 删除不需要的分支。可以使用 Gitcode（Gitee 会屏蔽 1G 以上的仓库）导入 GitHub，可以达到接近满速；也可以使用其他 GitHub 镜像站。如果出现子模块不能自动克隆的情况，可以手动将 `src/glm` 和 `src/stb` 手动补全。

## 安装首选软件包

建议将 `scripts/installer` 下的 Linux 相关的依赖脚本全部执行一遍：

```bash
chmod +x scripts/installer/*.sh
./linux_web_viewer_dependencies.sh
./linux_compilation_dependencies.sh
./linux_optional_compilation_dependencies.sh
./linux_runtime_dependencies.sh
sudo apt install xvfb
```

直接运行可能出现下面报错

```bash
error: externally-managed-environment

× This environment is externally managed
╰─> To install Python packages system-wide, try apt install
    python3-xyz, where xyz is the package you are trying to
    install.

    If you wish to install a non-Debian-packaged Python package,
    create a virtual environment using python3 -m venv path/to/venv.
    Then use path/to/venv/bin/python and path/to/venv/bin/pip. Make
    sure you have python3-full installed.

    If you wish to install a non-Debian packaged Python application,
    it may be easiest to use pipx install xyz, which will manage a
    virtual environment for you. Make sure you have pipx installed.

    See /usr/share/doc/python3.12/README.venv for more information.

note: If you believe this is a mistake, please contact your Python installation or OS distribution provider. You can override this, at the risk of breaking your Python installation or OS, by passing --break-system-packages.
hint: See PEP 668 for the detailed specification.
```

想要强制使用 pip 安装软件包，可以使用下面命令允许 pip 覆盖系统包：

```bash
export PIP_BREAK_SYSTEM_PACKAGES=1
```

还可能出现某些软件包的 `PATH` 问题：

```bash
Next steps:
- To conveniently access emsdk tools from the command line,
  consider adding the following directories to your PATH:
    /home/excnies/webots/dependencies/emsdk
    /home/excnies/webots/dependencies/emsdk/node/20.18.0_64bit/bin
    /home/excnies/webots/dependencies/emsdk/upstream/emscripten
- This can be done for the current shell by running:
    source "/home/excnies/webots/dependencies/emsdk/emsdk_env.sh"
- Configure emsdk in your shell startup scripts by running:
    echo 'source "/home/excnies/webots/dependencies/emsdk/emsdk_env.sh"' >> $HOME/.bash_profile
```

使用下面命令修复：

```bash
export PATH="$HOME/.local/bin:$PATH"
echo 'source "/home/excnies/webots/dependencies/emsdk/emsdk_env.sh"' >> ~/.bashrc
```

验证：

```bash
excnies@HXCN-Win:~/webots$ echo $PATH | tr ':' '\n' | grep "emsdk"
/home/excnies/webots/dependencies/emsdk
/home/excnies/webots/dependencies/emsdk/upstream/emscripten
/home/excnies/webots/dependencies/emsdk/node/20.18.0_64bit/bin
excnies@HXCN-Win:~/webots$ emcc --version  # 应输出 Emscripten 版本
node --version  # 应输出 v20.18.0
shared:INFO: (Emscripten: Running sanity checks)
emcc (Emscripten gcc/clang-like replacement + linker emulating GNU ld) 4.0.4 (273f0216fede04f2445367765eaf2aabeeb60d84)
Copyright (C) 2025 the Emscripten authors (see AUTHORS.txt)
This is free and open source software under the MIT license.
There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

v20.18.0
```

为了方便使用，可以将上面两条命令加入到 `scripts/installer/bashrc.linux`。

## 设置 bash 配置文件

````bash
cat scripts/install/bashrc.linux >> ~/.bashrc
source ~/.bashrc
````

## 构建 Webots

从根目录编译Webots：

```bash
make -jX
```

注意：`X` 表示快速多线程编译的线程数。例如，在具有四个核心和超线程的 CPU 上使用 `make -j12`。

`make` 指令自动下载 `dependencies` 文件夹中所需的资源 

编译完成后，输入 `./webots` 启动。

## 运行 Linux GUI 应用

WSL 现在支持在 Windows 上运行 Linux GUI 应用程序（X11 和 Wayland），提供了完全集成的桌面体验。先决条件：

- 需要使用 **Windows 10 版本 19044+** 或 **Windows 11** 才能使用此功能。

- 已安装适用于 vGPU 的驱动程序

  若要运行 Linux GUI 应用，应首先安装下面与你的系统匹配的驱动程序。 这样，就可以使用虚拟 GPU (vGPU)，使你可受益于硬件加速 OpenGL 渲染。

  - [**Intel** GPU 驱动程序](https://www.intel.com/content/www/us/en/download/19344/intel-graphics-windows-dch-drivers.html)
  - [**AMD** GPU 驱动程序](https://www.amd.com/en/support)
  - [**NVIDIA** GPU 驱动程序](https://www.nvidia.com/Download/index.aspx?lang=en-us)

可从 Linux 终端运行以下命令，下载并安装这些常用的 Linux 应用程序。

```bash
sudo apt install x11-apps -y # 安装 X11 应用
sudo apt install gnome-text-editor -y # 安装 Gnome 文本编辑器
```

这会安装很多相关依赖。安装完成后启动 Webo