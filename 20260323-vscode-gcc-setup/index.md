---
2026年最新Windows11下VSCode配置GCC开发C语言环境保姆级教程
---

网上关于 VS Code 配 C 语言环境的教程很多，但不少写法要么太旧，还停留在手动装 MinGW；要么太省事，直接让你装一堆插件，最后能跑是能跑，出了问题也不知道该改哪里。

我这次是按自己平时会长期用的方式重新配了一遍：`MSYS2 + GCC/GDB + VS Code 官方 C/C++ 扩展`。这套配置是按 **C 程序** 直接可用来写的：当前文件可以直接编译，按 `F5` 能进调试，项目目录里只留一个 `.vscode` 文件夹，迁移起来也方便。

如果你后面要拿它写 C++，思路也差不多，但 `tasks.json` 里的 `gcc.exe` 需要换成 `g++.exe`，编译参数也得按 C++ 习惯再调一下。本文先把 C 语言这条线讲清楚。

## 第一步：安装 MSYS2，并准备好 GCC / GDB

我这里没有用一些年代比较久的 MinGW 打包器，而是直接用 `MSYS2`。原因很简单：包管理方便，更新也干净，后面装 `gcc`、`gdb`、`make` 这类工具都省心。

访问 [MSYS2 官网](https://www.msys2.org)，点击[ msys2-x86_64-20260322.exe](https://github.com/msys2/msys2-installer/releases/download/2026-03-22/msys2-x86_64-20260322.exe) 下载最新版。如果国内网络下载速度较慢，可以使用访问 [清华大学开源镜像站](https://mirrors.tuna.tsinghua.edu.cn/msys2/distrib/)，点击 [/msys2/distrib/msys2-x86_64-latest.exe](https://mirrors.tuna.tsinghua.edu.cn/msys2/distrib/msys2-x86_64-latest.exe)。

![image-20260323172303087](https://gastigado.cnies.org/d/halo20260323_vscode_gcc_setup/image-20260323172303087.webp)

![image-20260323172323991](https://gastigado.cnies.org/d/halo20260323_vscode_gcc_setup/image-20260323172323991.webp)

安装过程按默认流程走，一直点下一步就行，路径建议自己一开始就定好。本文后面的配置文件，默认都是按 `C:\msys64` 来写的。

![image-20260323172649868](https://gastigado.cnies.org/d/halo20260323_vscode_gcc_setup/image-20260323172649868.webp)

装完以后，在开始 -> 全部 -> MSYS2 打开 **MSYS2 MinGW x64** 终端。

![image-20260323172824354](https://gastigado.cnies.org/d/halo20260323_vscode_gcc_setup/image-20260323172824354.webp)

先更新系统，再装编译链：

```bash
pacman -Syu
```

如果更新后提示关闭窗口重开，就照做。重新打开后继续执行：

```bash
pacman -S --needed mingw-w64-x86_64-gcc mingw-w64-x86_64-gdb make
```

![SnowShot_2026-03-23_15-43-57](https://gastigado.cnies.org/d/halo20260323_vscode_gcc_setup/SnowShot_2026-03-23_15-43-57.webp)

安装完成后，先确认一下工具确实在：

```bash
gcc --version
gdb --version
```

如果有输出，证明安装成功。

![SnowShot_2026-03-23_15-45-20](https://gastigado.cnies.org/d/halo20260323_vscode_gcc_setup/SnowShot_2026-03-23_15-45-20.webp)

## 第二步：配置环境变量

按 <kbd>Win</kbd>+<kbd>s</kbd>，搜索**环境变量**，点击**编辑系统环境变量**，在弹窗的窗口，点击右下角的**环境变量**按钮：

![image-20260323173724108](https://gastigado.cnies.org/d/halo20260323_vscode_gcc_setup/image-20260323173724108.webp)

在用户变量下，点击 Path -> 编辑，在弹出的窗口点击 新建，输入下面路径（如果修改了安装位置，将`C:\msys64`改为实际安装路径即可），然后点击确定。

```cmd
C:\msys64\mingw64\bin
```

![image-20260323174055750](https://gastigado.cnies.org/d/halo20260323_vscode_gcc_setup/image-20260323174055750.webp)

右键开始，点击**终端**，在终端中输入下面命令，输出 GCC 版本号，证明环境变量配置成功：

```cmd
gcc --version
```

![image-20260323174258669](https://gastigado.cnies.org/d/halo20260323_vscode_gcc_setup/image-20260323174258669.webp)

如果这一步报错，则需要在**系统变量**中完成上方**用户变量同样的环境变量配置**：

![SnowShot_2026-03-23_15-53-20](https://gastigado.cnies.org/d/halo20260323_vscode_gcc_setup/SnowShot_2026-03-23_15-53-20.webp)

## 第三步：安装 VS Code

点击访问 VS Code 官网，点击 **Download for Windows** 下载安装包：

![SnowShot_2026-03-23_15-57-10](https://gastigado.cnies.org/d/halo20260323_vscode_gcc_setup/SnowShot_2026-03-23_15-57-10.webp)

打开安装包，按默认流程走，一直点下一步就行：

![image-20260323175144575](https://gastigado.cnies.org/d/halo20260323_vscode_gcc_setup/image-20260323175144575.webp)

打开 VS Code，发现页面为英文。点击左侧栏的**扩展按钮**，搜索 **Chinese**，点击第一个安装简体中文插件。安装完成后，右下角提示 **Change Language and Restart**，点击按钮重启 VS Code 即可：

![SnowShot_2026-03-23_16-03-08](https://gastigado.cnies.org/d/halo20260323_vscode_gcc_setup/SnowShot_2026-03-23_16-03-08.webp)

## 第四步：安装扩展

这里我用的是 **Microsoft 官方的 C/C++ 扩展**。如果你用的是 VSCodium，思路也完全一样。

在扩展搜索 **C++**，安装 **C/C++ DevTools** 和 **C/C++ Extension Pack** 两个扩展：

![SnowShot_2026-03-23_16-04-26](https://gastigado.cnies.org/d/halo20260323_vscode_gcc_setup/SnowShot_2026-03-23_16-04-26.webp)

装完以后，代码高亮、错误提示、断点调试这些基础能力才会正常工作。

## 第五步：修改配置

随便建一个项目目录，比如：

```text
D:\Code\hello-c
```

然后打开这个项目：

![image-20260323190550888](https://gastigado.cnies.org/d/halo20260323_vscode_gcc_setup/image-20260323190550888.webp)

然后在项目里新建 `.vscode` 目录，把下面 4 个文件放进去，每个文件的具体内容在下面：

![image-20260323191024425](https://gastigado.cnies.org/d/halo20260323_vscode_gcc_setup/image-20260323191024425.webp)

```text
.vscode/
├── c_cpp_properties.json
├── launch.json
├── settings.json
└── tasks.json
```

我自己这套配置里，真正关键的是前三样思路：

- `tasks.json` 负责“怎么编译、怎么运行”
- `launch.json` 负责“按 F5 时怎么调试”
- `c_cpp_properties.json` 负责“编辑器该用哪个编译器做智能提示”
- `settings.json` 主要是补一些 C++ 头文件关联，属于锦上添花，不是必须

### 1. `tasks.json`

这个文件决定 VS Code 编译当前文件时到底执行什么命令。

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "C: gcc 生成活动文件",
            "type": "shell",
            "command": "C:/msys64/mingw64/bin/gcc.exe",
            "args": [
                "-fdiagnostics-color=always",
                "-g",
                "${file}",
                "-o",
                "${fileDirname}\\${fileBasenameNoExtension}.exe",
                "-O2",
                "-Wall"
            ],
            "options": {
                "cwd": "${fileDirname}",
                "shell": {
                    "executable": "C:\\Windows\\System32\\cmd.exe",
                    "args": ["/d", "/c"]
                }
            },
            "problemMatcher": ["$gcc"],
            "group": {
                "kind": "build",
                "isDefault": true
            }
        },
        {
            "label": "C: 运行 exe",
            "type": "shell",
            "command": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "options": {
                "cwd": "${fileDirname}",
                "shell": {
                    "executable": "C:\\Windows\\System32\\cmd.exe",
                    "args": ["/d", "/c"]
                }
            }
        },
        {
            "label": "C: 编译并运行",
            "dependsOrder": "sequence",
            "dependsOn": [
                "C: gcc 生成活动文件",
                "C: 运行 exe"
            ]
        }
    ]
}
```

这份配置有几个点值得注意：

- `command` 直接指定了 `gcc.exe` 的绝对路径，所以不吃系统环境变量。
- 如果你用的是别的路径，比如 `D:\msys64`，那就把 `command` 改掉。
- 如果编译 C++ 项目，需要把 `gcc.exe` 改为 `g++.exe`。
- `-g` 是给 `gdb` 调试准备的，不要删
- `-O2 -Wall` 属于比较常见的日常编译参数
- 输出文件就是“当前源文件同目录下、同名的 `exe`”

### 2. `launch.json`

这个文件是给 `F5` 调试用的：

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "运行当前 C 程序",
            "type": "cppdbg",
            "request": "launch",
            "program": "${fileDirname}\\${fileBasenameNoExtension}.exe",
            "args": [],
            "stopAtEntry": false,
            "cwd": "${fileDirname}",
            "environment": [],
            "externalConsole": true,
            "MIMode": "gdb",
            "miDebuggerPath": "C:/msys64/mingw64/bin/gdb.exe",
            "preLaunchTask": "C: gcc 生成活动文件",
            "setupCommands": [
                {
                    "description": "Enable pretty-printing for gdb",
                    "text": "-enable-pretty-printing",
                    "ignoreFailures": true
                }
            ]
        }
    ]
}
```

它的逻辑也很直白：

- 先执行 `preLaunchTask`，也就是先编译
- 然后调用 `gdb.exe`
- 调试目标是当前文件编译出来的那个 `exe`

所以只要 `tasks.json` 里的编译能过，这里一般就能接上。

### 3. `c_cpp_properties.json`

这个文件主要影响 VS Code 的智能提示、报错标记和头文件解析：

```json
{
    "configurations": [
        {
            "name": "Win32",
            "includePath": [
                "${workspaceFolder}/**"
            ],
            "defines": [
                "_DEBUG",
                "UNICODE",
                "_UNICODE"
            ],
            "compilerPath": "C:/msys64/mingw64/bin/gcc.exe",
            "cStandard": "c23",
            "cppStandard": "c++20",
            "intelliSenseMode": "windows-gcc-x64",
            "compilerArgs": [
                "-O2",
                "-Wall"
            ]
        }
    ],
    "version": 4
}
```

这里最重要的是这两个字段：

- `compilerPath`
- `intelliSenseMode`

前者告诉扩展“我实际用的是哪一个编译器”，后者告诉扩展“按什么模型去理解这个编译器环境”。如果你装的是 MSYS2 的 `mingw64` GCC，那么 `windows-gcc-x64` 这组配置基本就是对的。

我这里把 `cStandard` 设成了 `c23`。如果你的课程、OJ 或项目环境还停留在旧标准，也可以改成 `c17` 或 `c11`。

### 4. `settings.json`

这个文件不是必须，但如果你后面还会写 C++，标准库头文件有时会被识别得更顺一点。

```json
{
    "files.associations": {
        "*.tcc": "cpp",
        "list": "cpp",
        "iostream": "cpp",
        "chrono": "cpp",
        "random": "cpp",
        "limits": "cpp",
        "valarray": "cpp",
        "ostream": "cpp",
        "iomanip": "cpp",
        "atomic": "cpp",
        "compare": "cpp",
        "optional": "cpp",
        "future": "cpp",
        "numeric": "cpp",
        "sstream": "cpp",
        "cmath": "cpp",
        "string": "cpp",
        "string_view": "cpp",
        "array": "cpp",
        "memory": "cpp",
        "istream": "cpp",
        "functional": "cpp",
        "tuple": "cpp",
        "utility": "cpp",
        "variant": "cpp"
    }
}
```

如果你现在只写 C，这个文件甚至可以先不放。它更多是给后面顺手写 C++ 时准备的。

## 第六步：测试验证

在项目里新建一个 `hello.c`：

![image-20260323190807187](https://gastigado.cnies.org/d/halo20260323_vscode_gcc_setup/image-20260323190807187.webp)

```c
#include <stdio.h>

int main(void) {
    printf("Hello, world!\n");
    return 0;
}
```

点击这里直接运行代码：

![image-20260323191716856](https://gastigado.cnies.org/d/halo20260323_vscode_gcc_setup/image-20260323191716856.webp)

你也可以按下面顺序测试：

### 编译

按 `Ctrl + Shift + B`，选择默认构建任务 `C: gcc 生成活动文件`。

如果没报错，当前目录下会生成一个同名 `exe`。

### 编译并运行

按 `Ctrl + Shift + P`，输入 `Tasks: Run Task`，选 `C: 编译并运行`。

这样会先编译，再直接把程序跑起来。

### 调试

按 `F5`，选择 `运行当前 C 程序`。

VS Code 会先调用 `gcc` 编译，再接入 `gdb`。这时候断点、单步执行、变量查看就都能用了。

## 常见问题

### 1. 运行代码，黑色窗口闪了一下

这是因为程序执行完就立刻退出了，窗口也会跟着关闭。想看清输出结果，可以在程序末尾临时加一行 `system("pause");`，让程序停一下再结束。也可以在终端中执行 编译 -> 运行 的命令，这样窗口不会闪退。

```c
#include <stdio.h>
#include <stdlib.h>

int main(void) {
    printf("Hello, world!\n");
    system("pause");
    return 0;
}
```

### 2. 使用 VS Code 底部面板终端

如果不想每次都弹出单独的黑色窗口，可以把 `launch.json` 里的 `"externalConsole": true` 改成 `"externalConsole": false`。这样调试时通常就会走 VS Code 的集成终端，运行和查看输出都会更方便。

![image-20260323191907567](https://gastigado.cnies.org/d/halo20260323_vscode_gcc_setup/image-20260323191907567.webp)

### 3. 开启自动保存

如果经常忘记保存，编译或运行时就可能不是最新代码。可以在 VS Code 里开启自动保存，减少这类低级问题，写代码和调试都会更顺手。

![SnowShot_2026-03-23_17-04-30](https://gastigado.cnies.org/d/halo20260323_vscode_gcc_setup/SnowShot_2026-03-23_17-04-30.webp)

### 4. 我想继续写 C++

可以，最把 `tasks.json` 里的编译器从 `gcc.exe` 改成 `g++.exe`，然后按你的需要补上 C++ 的编译参数。本文这份配置没有直接把 C++ 构建也一起塞进去，主要是为了先把 C 这条路径保持得足够干净。

## 这套配置适合什么人

如果你只是偶尔刷题，装个 Code Runner 也不是不行；但如果你想把 VS Code 当成正经开发环境来用，希望编译、运行、调试这三件事都在一套逻辑里，那这套方式会稳很多。

它的好处不在于“最省步骤”，而在于后面好维护。项目里留着 `.vscode` 四个文件，哪天你换电脑、换目录、换编辑器分支，基本都能很快接回来。

我自己现在更愿意用这种配置，而不是每次遇到问题都去猜某个插件到底帮我偷偷做了什么。
