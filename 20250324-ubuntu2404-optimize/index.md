---
Ubuntu24.04新机配置指南：从常用软件安装到使用技巧全攻略
---

之前本人完成了 [Ubuntu 24.04 与 Windows 11 双系统的安装](https://hs.cnies.org/archives/dual-boot-ubuntu2404-win11)。本指南将手把手教你完成新系统部署后的关键配置，涵盖：系统级优化、Linux 生态必备工具链配置、跨平台生产力工具选型，助你打造媲美 Windows 的高效工作环境。

针对国内网络环境特点，本指南特别设计渐进式配置方案，优先解决网络依赖较低的配置项。本教程同适用 Ubuntu 22.04 使用。

## 补全和快速粘贴

### 补全规则

在 Ubuntu 终端中，**Tab 补全**是一个提高效率的核心功能，其规则和行为主要遵循以下逻辑：

- **单次 Tab 按下**：自动补全当前输入的命令、文件名或路径。若唯一匹配，立即补全；若存在多个候选，补全到最长公共前缀。
- **两次 Tab 按下**：显示所有可能的候选列表（若未输入任何字符，可能列出当前目录所有文件）。

补全优先级逻辑：

- **命令补全优先**：输入命令开头时，优先补全 `PATH` 环境变量中的可执行文件（如 `ls`、`git`）。
- **路径补全次之**：输入路径时（如 `/usr/` 或 `./`），自动补全当前目录下的文件或子目录。
- **变量和波浪号展开：**
  - `~` 自动展开为用户家目录（如 `~/.ssh` → `/home/user/.ssh`）。
  - `$VAR` 补全时会展开环境变量（如 `$HOME` → `/home/user`）。

特殊字符处理：

- **空格和特殊字符**：若文件名包含空格或特殊符号（如 `my file.txt` 或 `file\ name`），补全时会自动添加引号或转义符（`\`）。
- **引号包裹**：输入起始引号（`"` 或 `'`）后按 Tab，会补全文件名并自动闭合引号。

常见限制与问题：

- **权限不足**：若当前用户无权访问某目录或文件，Tab 补全会忽略这些条目。
- **区分大小写**：Linux 文件系统区分大小写，`File.txt` 和 `file.txt` 会被视为不同文件。
- **模糊匹配失败**：若输入的前缀无法匹配任何内容，Tab 补全无响应。
- **通配符辅助**：结合 `*` 或 `?`（如 `ls *.txt`）缩小补全范围。

### 补全示例

在终端善用 <kbd>Tab</kbd> 键可以高效完成命令输入。比如想要使用 Ubuntu 24.04 默认文本编辑器`gnome-text-editor`，可以输入 `gn` 可以补全 `gnome-`，输入 `tex` 可以补全 `text-editor`。

如果想要补全文件，比如安装当前目录下的 `QQ_3.2.16_250307_amd64_01.deb`，输入 `apt ins<Tab>` 可能补全为 `apt install`，输入 `./QQ` 即可补全完整文件名。

输入 `cd /u/l/b` 后按 Tab，可能补全为 `/usr/local/bin`。

### 自定义补全规则

- **bash-completion 扩展**：通过 `bash-completion` 包（默认已安装），支持复杂命令的上下文感知补全（如 `apt`、`git`、`docker`）。

  ```bash
  sudo apt install bash-completion  # 确保已安装
  ```

- **自定义补全脚本**：高级用户可编写补全脚本（位于 `/etc/bash_completion.d/` 或用户目录的 `.bash_completion`）。

### 复制粘贴快捷键

- **Ctrl+Shift+C**：复制选中的文本（通用快捷键）。
- **Ctrl+Insert**：部分终端支持用此键复制。

- **Ctrl+Shift+V**：标准粘贴快捷键（Windows/Linux 系统通用）。
- **Ctrl+Alt+V**：某些终端（如 GNOME Terminal）支持此快捷键粘贴。

- **右键菜单粘贴**：右键点击终端空白处 → 选择 **Paste**。
- **中键粘贴**：直接点击鼠标中键（滚轮）粘贴已复制内容（需提前选中或复制文本）。

### 高级技巧

- **动复制选中文本**：终端默认支持 **选中即复制**（无需 Ctrl+C），之后用中键或快捷键粘贴。

- **使用 `xclip` 或 `xsel` 工具**：安装后可通过命令操作剪贴板：

  ```bash
  sudo apt install xclip xsel  # 安装工具
  echo "hello" | xclip -sel clip  # 复制到系统剪贴板
  xclip -sel clip -o  # 读取剪贴板内容
  ```

- **避免直接粘贴含换行符的命令**：若剪贴板内容含 `\n`，粘贴时可能立即执行命令，建议用 `Ctrl+Shift+V` 或逐行粘贴。

- **敏感信息慎用剪贴板**：避免复制密码、密钥等敏感内容到剪贴板（可通过 `history -c` 清除历史记录）。

- **Tmux**：先按 `Ctrl+B` + `[` 进入复制模式，选中后按 `Enter` 复制，再按 `Ctrl+B` + `]` 粘贴。按 `Ctrl+B` + `]` 粘贴已复制内容。

- SSH 远程连接：确保本地和远程终端的粘贴方式兼容（如使用 `Shift+Insert`）。

## 修改显示设置

在桌面右键点击“显示设置”可以设置屏幕分辨率、刷新率等参数。

如果想要设置 125%、150% 等倍数的缩放，需要先打开“Fractional Scaling”：

![Fractional Scaling](https://gastigado.cnies.org/d/halo20250324ubuntu2404_optimize/config_1_.png?sign=8NJE5MPBEkRq-AJJA7cXo-lDluEzJ2lOCmbwygTd1SY=:0)

## 修改用户的默认目录为英文

Ubuntu系统的个人主目录`~`（即`/home/username`）采用本地语言命名。当系统安装语言设置为中文时，默认生成"桌面"、"文档"、"下载"等中文命名的标准目录。虽然这种本地化命名在图形界面操作中具有直观优势，但在开发场景下可能引发以下技术适配问题：

1. **终端兼容性**：传统命令行工具对 Unicode 字符集支持存在历史遗留限制
2. **脚本可移植性**：跨语言环境脚本易出现路径解析异常
3. **编码一致性**：混合编码环境可能引发文件读写错误
4. **开发工具适配**：部分IDE和编译工具链对非ASCII路径支持不完善
5. **补全困难：**使用终端输入命令时需要进行中英文切换，效率较低。

去年本人使用 Ubuntu 22.04 时的解决方法是使用英文安装系统，然后切换为中文，安装中文相关语言包但保留文件夹命名。但此方法过于繁琐，只需要在终端执行下面命令：

```bash
LANG=en_US xdg-user-dirs-gtk-update
```

注销后重新登陆，勾选“Don't ask me this again”，然后选择“Update Names”即可。

![xdg-user-dirs-gtk-update](https://gastigado.cnies.org/d/halo20250324ubuntu2404_optimize/config_2_.png?sign=3ULsFDEIpDBPDWxb8KiCJWeZNZkHja4wXluRhU9wRBM=:0)


也可以参考下面教程进行修改：

https://blog.csdn.net/w20178556/article/details/131942074

## 软件源与包管理器的使用

### 更新软件源列表

在安装任何软件之前，首先需要更新软件源列表。

```bash
# 步骤1：刷新软件源元数据
sudo apt-get update

# （建议）步骤2：执行全系统升级
sudo apt upgrade -y
```

`apt update` 命令会从 `/etc/apt/sources.list` 配置的镜像源同步软件包索引，建立本地可用软件清单的哈希表（存储在 `/var/lib/apt/lists/`）。建议后续执行 `upgrade` 操作以更新已安装软件至最新版本，确保安全补丁和功能更新生效。

### 软件安装命令

```bash
# 从官方仓库安装（以Vim为例）
sudo apt install vim -y

# 安装本地deb包（需指定相对/绝对路径）
sudo apt install ./QQ_3.2.16_250307_amd64_01.deb
```

安装本地 deb 包时在终端输入 `./` 后按 <kbd>Tab</kbd> 键可触发路径自动补全功能，该符号表示当前工作目录。当处理非仓库软件包时，此操作可避免因路径错误导致的 "Unable to locate package" 报错。

### 解决 AppImage 无法打开

Ubuntu 22.04 及以上系统缺失了 FUSE（用户空间文件系统）库。该 FUSE 库为用户空间程序提供了一个接口，以便向 Linux 内核导出虚拟文件系统。

AppImage的运作机制依托于虚拟文件系统。由于关键库缺失，AppImage未能按预期运行。

如果你正在使用 Ubuntu 24.04 系统，需执行以下命令以安装FUSE库：

```bash
sudo apt install libfuse2t64 
```

若为Ubuntu 22.04系统，则应执行此命令：

```bash
sudo apt install libfuse2 
```

此乃同一软件库，仅在两版本中包名称有所差异。

安装完成后，需要赋予 AppImage 权限，然后即可运行：

```bash
sudo chmod +x <appimage软件包名>.AppImage
./<appimage软件包名>.AppImage
```

## 必备软件

Ubuntu 默认预装 Firefox 浏览器，初期配置我们使用它来下载软件包

### QQ

访问QQ官网（https://im.qq.com）,点击“下载” - “Linux”后，向下滑动出现下载按钮，选择“X86 版下载” - “deb”（根据系统架构进行安装），下载完成后终端切换到 `Downloads` 目录，使用 命令安装即可：

```bash
sudo apt install ./<QQ_3.版本号_amd64_01>.deb
```

Tim 暂时没有 Linux 版原生支持。

### 微信

微信在前一段时间终于推出了 Linux 原生版本。访问微信官网（https://weixin.qq.com），选择“Linux” - “X86” - “deb”，使用命令进行安装：

```bash
sudo apt install ./WeChatLinux_x86_64.deb
```

### Todesk

访问 Todesk 官网（https://www.todesk.com/），选择“下载” - “下载ToDesk个人版”，选择 Linux 版，选择“Debian/Ubuntu/Mint (x64)”，根据提示进行安装即可。

如果想要开机启动，需要在“优化”中设置开机自启动程序。

### 优化

优化（Gnome Tweaks）可以调整外观、字体、键盘鼠标设置、窗口和开机自动启动程序的工具。使用下面命令进行安装：

```bashs
sudo apt install gnome-tweaks
```

外观美化方面将单独写写一篇文章介绍。

### 科学上网
请参考：
[Ubuntu24.04新机配置指南：从常用软件安装到使用技巧全攻略——优化](https://hs.cnies.org/archives/ubuntu2404-optimize#%E4%BC%98%E5%8C%96)
### 输入法

#### Fcitx5

如果在 Ubuntu 24.04 安装时选择中文，系统默认预装了 Fcitx 5 输入法，可以直接使用 <kbd>Ctrl</kbd> + <kbd>Shift</kbd> 进行切换。

你可能发现只能在终端输入中文，大部分应用程序无法切换中文输入法。可以在终端运行下面命令，将 Fcitx 5 添加到系统环境：

```bash
sudo gnome-text-editor /etc/environment
```

`gnome-text-editor`是 Ubuntu 24.04 自带的文本编辑器，在 Ubuntu 22.04 应该更换为 `gedit` 

在最后 `/etc/environment` 末尾添加下面内容

```bash
exec-once = fcitx5 -d --replace
env = XMODIFIERS,@im=fcitx
env = SDL_IM_MODULE,fcitx
env = INPUT_METHOD,fcitx
env = GLFW_IM_MODULE,ibus
```

此时可以在其他窗口切换和使用 Fcitx 5。

在优化中将 Fcitx 5 中设置开机自启动。

打开 Fcitx 5 配置可以进入设置界面。

在“输入法”选项卡可以设置输入法的顺序。

在“全局选项”的“快捷键”可以根据自己的喜好设置快捷键。“共享输入状态”可以调整不同应用之间是否使用相同的输入法。“默认页大小”可以设置候选词数量。

在“附加组件”中，“经典用户界面”可以自定义外观，具体梅花教程将单独写一篇文章介绍。在“云拼音”中可以设置百度等作为输入源。在“拼音”中启动云拼音并设置云拼音候选词的位置、动画等；页可以设置一些常见词的快速输入。

在 GitHub 打开[维基百科中文拼音词库的 Releases 界面](https://github.com/felixonmars/fcitx5-pinyin-zhwiki/releases)，下载最新版的 `.dict` 文件。按照 README 的指导，将其复制到 `~/.local/share/fcitx5/pinyin/dictionaries/` 文件夹下即可。

```bash
# 下载词库文件
wget https://github.com/felixonmars/fcitx5-pinyin-zhwiki/releases/download/0.2.4/zhwiki-20250310.dict
# 创建存储目录
mkdir -p ~/.local/share/fcitx5/pinyin/dictionaries/
# 移动词库文件至该目录
mv zhwiki-20220416.dict ~/.local/share/fcitx5/pinyin/dictionaries/
```

Github 上也有很多优秀的自建词库：

https://github.com/wuhgit/CustomPinyinDictionary

也可以使用搜狗输入法词库，请参考下面教程转换为 Fcitx 词库：

https://www.cnblogs.com/luoshuitianyi/p/11669619.html

想要在 Fcitx 5 中输入特殊符号，可以参考下面教程：

https://www.debuggerx.com/2023/09/20/fcitx5-customizer/

也可以使用 [搜狗输入法](https://shurufa.sogou.com/linux)、[百度输入法](https://srf.baidu.com/site/guanwang_linux/index.html)、[讯飞输入法](https://srf.xunfei.cn/index.html#/)、[华宇拼音输入法](https://pinyin.thunisoft.com/index.html#/sy)等基于 Fcitx 的输入法。这些输入法基于 Fcitx 4，与 Fcitx 5 共存可能存在兼容性问题。

#### iBus

iBus 外观更接近 Ubuntu Gnome 原生外观，并且在本人的 Fcitx 5 无法通过 <kbd>Meta</kbd> + <kbd>Space</kbd> 切换输入法，因此卸载了 Fcitx 5 转而使用 iBus 作为输入法。

```bash
sudo apt remove fcitx5
sudo apt install ibus-pinyin 
```

安装完成后执行“设置” - “键盘” - “输入源” - “添加输入源” - “汉语” - “中文（智能拼音）”即可添加到输入源可以在状态栏切换中文输入法。

切换到中文输入法后，可以点击首选项进入配置界面。在“常规”勾选候选词中的“动态调整候选词序”和“将每个输入记录为新的词汇”，将候选词排列顺序修改为“词频”，可以提高输入效率。

推荐在“拼音模式”中“启用云输入”，云输入源可以设置为百度等。

iBus 同样可以导入词典，Github 上有很多词典，下载 txt 文件后，通过“首选项” - “用户数据” - “用户词典” - “导入”进行词库的安装：

https://github.com/broly8/libpinyin-dict

https://github.com/jayknoxqu/ibus-rime

https://github.com/iDvel/rime-ice

也可以使用搜狗输入法词库，请参考下面教程：

https://blog.csdn.net/qq_42901723/article/details/136046080

也可以使用[中州韵](https://rime.im)、[胖喵拼音输入法](https://www.bilibili.com/read/cv34299567/?opus_fallback=1) 等基于 Rime 二次开发的输入法。

这里推荐开源免费的[输入法词库转换程序”深蓝词库转换“](https://github.com/studyzy/imewlconverter)。

### 开发环境

#### 基础工具

```bash
sudo apt install -y build-essential curl wget git
```

按需安装开发环境：

#### Python

```bash
sudo apt install -y python3 python3-pip python3-venv pipx
```

更换清华大学 Pypi 源：

```bash
python -m pip install --upgrade pip
pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple
```

#### C++

```bash
sudo apt install -y gcc g++ make cmake
```

#### Java

```bash
sudo apt install -y openjdk-18-jdk

echo 'export JAVA_HOME=/usr/lib/jvm/java-18-openjdk-amd64' >> ~/.bashrc
source ~/.bashrc
```

#### Node

https://nodejs.org/en/download

#### Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

国内可以使用

```bash
# 设置 Rustup 镜像， 修改配置 ~/.zshrc or ~/.bashrc
export RUSTUP_DIST_SERVER="https://rsproxy.cn"
export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"

# 安装 Rust
curl --proto '=https' --tlsv1.2 -sSf https://rsproxy.cn/rustup-init.sh | sh

# 设置 crates.io 镜像， 修改配置 ~/.cargo/config，已支持git协议和sparse协议，>=1.68 版本建议使用 sparse-index，速度更快。
[source.crates-io]
replace-with = 'rsproxy-sparse'
[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"
[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"
[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"
[net]
git-fetch-with-cli = true
```

## 软件包管理器和应用商店

### 星火应用商店

星火应用商店是一个为 Debian 系发行版用户提供海量应用的平台，支持极速下载和一键安装。

在 Gitee 打开[星火应用商店 Release 界面](https://gitee.com/spark-store-project/spark-store/releases)，根据系统架构下载最新版 deb 安装包，然后使用命令进行安装，如：

```bash
sudo apt install ./<spark-store_版本号_amd64>.deb
```

***对于 Ubuntu 22.04***，在执行安装后，需要输入下面命令：

```bash
sudo apt install --fix-broken
```

***对于 Ubutnu 20.04、Debian 11***，需要先[下载和安装依赖包](https://gitee.com/spark-store-project/spark-store-dependencies/releases/tag/1.0)。

### Synaptic/Gdebi（新立得软件包管理器）

新立得软件包管理器功能更强大，可以完成一些App Center无法完成的软件管理任务。Synaptic的界面更复杂，不支持更新的App Center功能，如评级和评论，因此不建议Ubuntu新手使用。

使用下面命令可以安装：

```bash
sudo apt install gdebi
```

安装后可以使用 `gdebi` 代替 `apt` 包管理器：

```bash
sudo gdebi <package_name>.deb
```

## 文本办公

### vim

Ubuntu 默认不预装 vim，需要自行安装：

```bash
sudo apt install vim
```

### Gedit/Gnome-text-editor

Gnome 默认文本编辑器，无需安装。在 Ubuntu 22.04 中使用 `gedit` 即可使用，在 Ubuntu 24.04 中包名变更为 ``。

想要使用文本编辑器编辑一个文件，直接使用包名即可调用：

```bash
gnome-text-editor 1.txt
```

如果需要 `sudo` 权限，直接添加 `sudo` 即可：

```bash
sudo gnome-text-editor /etc/environment
```

### Office

#### WPS

访问 WPS Office 官方网站，下载相应软件包安装即可：

https://www.wps.cn

WPS 365 提供了多种 CPU 架构和操作系统的支持：

https://365.wps.cn/

#### Libre Office

LibreOffice是由文档基金会开发的一款完全免费且开源的办公软件解决方案。其诞生旨在取代OpenOffice，并逐渐发展成为一种功能更为强大的替代品。LibreOffice采用简洁明了的设计理念，旨在提升界面的美学吸引力。该用户界面或许并不华丽，但其在符合现代标准方面表现卓越。

默认情况下 Ubuntu 22.04 及更早版本预装了 Libre Office，Ubuntu 24.04 可以根据自己需求安装。

```bash
sudo apt install libreoffice
```

#### Free Office

SoftMaker拥有一款需付费的专有办公软件产品。他们提供的免费版本名为FreeOffice，虽然功能相对有限，但用户无需支付任何费用即可使用。这使得FreeOffice成为那些因某些原因对LibreOffice不甚满意，又希望获得一款更为现代化、类似MS Office且无需支付许可费用的用户的理想选择。

```bash
mkdir -p /etc/apt/keyrings
sudo wget -qO- https://shop.softmaker.com/repo/linux-repo-public.key | gpg --dearmor > /etc/apt/keyrings/softmaker.gpg
sudo echo "deb [signed-by=/etc/apt/keyrings/softmaker.gpg] https://shop.softmaker.com/repo/apt stable non-free" > /etc/apt/sources.list.d/softmaker.list
sudo apt update
sudo apt install softmaker-freeoffice-2024
```

#### Only Office

OnlyOffice作为另一款免费且开源的办公套件，采用OOXML为核心文件格式，确保了与Microsoft Office文件的高度兼容性。

可以前往官方网站下载安装包：

https://www.onlyoffice.com/

### Markdown

#### Typora

下载 Typora 1.8.10：

```bash
wget https://download2.typoraio.cn/linux/typora_1.8.10_amd64.deb
```

配置 Rust 编译环境，上文已经提到，不再赘述。

克隆 Yporaject 项目：

```bash
git clone https://github.com/hazukieq/Yporaject.git --depth=1
```

如果在克隆项目时遇到网络问题，可以使用 gitclone.com 提供的镜像加速：

```bash
git clone https://gitclone.com/github.com/hazukieq/Yporaject.git --depth=1
```

编译 Yporaject 项目：

```bash
# 进入 Yporaject 项目
cd Yporaject
# 运行编译命令
cargo build
# 查看二进制是否生成,程序名称为 node_inject
ls target/debug
```

复制二进制程序到安装目录下:

```bash
# 记录当前目录路径
cur=`pwd`
# 复制二进制程序到相关目录下
sudo cp target/debug/node_inject /usr/share/typora
# 进入相关目录
cd /usr/share/typora
# 给予二进制程序执行权限
sudo chmod +x node_inject
# 运行二进制程序,请注意程序运行输出信息
sudo ./node_inject
```

获取 License Key：

```bash
# 返回项目
cd $cur
# 进入 license-gen 文件夹
cd license-gen
# 编译代码
cargo build
# 运行二进制程序
cargo run
```

你将会得到下面这样的输出：

```bash
Finished dev [unoptimized + debuginfo] target(s) in 0.00s
Running `target/debug/license-gen`
License for you: xxxxxx-xxxxxx-xxxxxx-xxxxxx
```

复制 License for you 后面的那一串序列号备用。

激活 Typora：

```
#运行 Typora (或直接在桌面上点击程序图标)
typora &
```

依次点击界面上方菜单栏的 `帮助 > 我的许可证...(Help > My license)` 打开激活界面，然后输入激活邮箱（可以任意填写）和上面复制的序列码。

如果遇到网络问题导致的“序列码激活软件失败，连接不上服务器”，可以在 `偏好设置 > 通用` 中勾选 **“使用 Typora 国内服务器”**。如果问题仍然没有解决，可以挂代理后使用国外激活服务器（不勾选 “使用 Typora 国内服务器”）重试。

如果想让 Typora 支持导出 Word，请安装 [Pandoc](https://pandoc.org/installing.html)。

#### Marktext

一款简洁优雅的Markdown编辑器：

https://github.com/marktext/marktext/releases

#### Obsidian

Obsidian 是一款个人知识库和笔记应用程序，其运作基础在于用户本地文件夹中的纯文本文件。该应用程序支持Markdown语法，并配备了一个简洁的界面，便于用户高效地进行知识管理与操作。

https://obsidian.md/download

#### Notion

在 Ubuntu 没有较为理想的 Notion 客户端，建议通过浏览器使用 Notion。

## 浏览器/网络/下载工具

### Microsoft Edge

访问 Edge 官方页面（https://www.microsoft.com/en-us/edge）下载 deb 安装包，进行安装：

```bash
sudo apt install microsoft-edge-stable_amd64.deb
```

Edge 可以跨平台同步书签、浏览器扩展、账号密码等，非常适合 Win、Linux 多系统场景使用。

### Vivaldi

如果你不能忍受 Edge 的广告和鸡肋的功能，那么可以试试 Vivaldi，它不仅功能多样，界面和功能高度自定义，支持跨平台同步，还带有拦截广告和跟踪器功能（拦截效果可以达到 AdBlock 的效果）。

访问 Vivaldi 官网（https://vivaldi.com）下载 Linux deb 包，然后使用 `sudo apt install`  进行安装。

### Brave

Brave 浏览器致力于呈现简洁的界面设计但功能，它是完全开源的，可供用户免费使用。Brave浏览器支持IPFS协议，以助用户抵御内容审查。此外，Brave 也赋予用户高度自定义现有界面的权限.

安装命令：

```bash
curl -fsS https://dl.brave.com/install.sh | sh
```

### Chrome/Chromium

#### Chrome

```bash
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmour -o /usr/share/keyrings/chrome.gpg
sudo sh -c 'echo "deb [arch=amd64 signed-by=/usr/share/keyrings/chrome.gpg]  \
http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google.list'
sudo apt update
sudo apt install google-chrome-stable
```

#### Chromium

```bash
sudo apt install chromium
```

### BitComet

前往比特彗星官网下载 AppImage：https://www.bitcomet.com/en/downloads

添加执行权限：

```bash
chmod +x BitComet.AppImage
```

运行：

```bash
./BitComet.AppImage
```

### Motrix

如果均衡考虑用户体验与功能性下载管理器，Motrix 堪称上佳之选。虽然其基于Electron构建，但提供了直观的用户界面，并涵盖用户所需的大多数核心功能。

前往 [Motrix 的 Github Release 页面](https://github.com/agalwood/Motrix/releases)下载 AppImage（注意是否符合系统架构），下载完成后添加执行权限：

```bash
chmod +x Motrix.AppImage
```

运行：

```bash
./Motrix.AppImage
```

### XDM

XDM 是 Xtreme Download Manager 的缩写（不是“下得慢”！）该软件功能全面、运行迅捷且操作简便，在 Windows 上也是一个代替 IDM 的流行选择。但目前开发停滞。

下载 [XDM 最新版](https://github.com/subhra74/xdm/releases/download/7.2.11/xdm-setup-7.2.11.tar.xz) 后解压，进入解压后目录运行 `install.sh`：

```bash
cd xdm-setup-7.2.11
sudo chmod +x ./install.sh
sudo ./install.sh
```

### Wireshark

Wireshark是一款全球广泛应用的免费开源网络协议分析工具。

```bash
sudo add-apt-repository ppa:wireshark-dev/stable
sudo apt update
sudo apt install wireshark
```

在 Ubuntu 22.04 系统中，若通过 apt 命令查询 Wireshark 的可用版本，结果显示为 3.6 版。然而，Wireshark 的 4.0.0 稳定版已于数月前发布。因此建议在安装前添加 Wireshark 软件源。

### 百度网盘

百度网盘有提供Liunx版本：[https://pan.baidu.com/download#linux](https://cloud.tencent.com/developer/tools/blog-entry?target=https%3A%2F%2Fpan.baidu.com%2Fdownload%23linux&objectId=2133939&objectType=1&isNewArticle=undefined)

下载deb格式安装包，安装即可。

## 文件管理

### p7zip

```bash
sudo apt install p7zip-full p7zip-rar
```

安装了 7Zip 后，在 Linux 中，你可以在图形用户界面或者 命令行中提取 7zip 文件。

在图形用户界面，你可以像提取其他压缩文件一样提取 .7z 文件。右击文件来提取它。

在终端中，你可以使用下列命令提取 .7z 归档文件：

```text
7z e file.7z
```

使用 “a” 选项就可以创建一个归档文件，它可以创建 7z、XZ、GZIP、TAR、 ZIP 和 BZIP2 这几种格式的文件。如果指定的归档文件已经存在的话，它会把文件“附加”到存在的归档中，而不是覆盖原有归档文件。

```
7z a <archive-filename> <list-of-files> 
```

### PeaZip

多功能开源文件压缩与加密工具，供图形用户界面(GUI)前端支持。

https://peazip.github.io/peazip-linux-x86.html

依据所使用的桌面环境（或您的个人偏好），点击DEB GTK2链接（推荐用于基于GTK的环境，如GNOME、XFCE、Cinnamon、Unity等）或DEB Qt5链接（推荐用于基于Qt的环境，如KDE、LXQt等），并将所选.deb软件包下载至指定的位置。

### 乱码问题

在Ubuntu下解压zip文件，解压后文件名都是乱码比如╡┌4╒┬╩╡└²-╖╓╬÷╜ß╣√.txt
原因是Windows和Ubuntu下的编码方式不同，导致文件解压出现文件名乱码。
解决方案：
方法一：
安装7zip和convmv：

```bash
sudo apt-get install p7zip-full convmv
```

安装完成之后，使用如下命令进行解压：

```bash
LANG=C 7za x file.zip
convmv -f GBK -t utf8 --notest -r .
```

第一条命令用于解压缩，而LANG=C表示以US-ASCII这样的编码输出文件名，如果没有这个语言设置，它同样会输出乱码，只不过是UTF8格式的乱码(convmv会忽略这样的乱码)。第二条命令是将GBK编码的文件名转化为UTF8编码，-r表示递归访问目录，即对当前目录中所有文件进行转换。
方法二：
使用如下命令：

```bash
unzip -O cp936 file.zip
```

大功告成！

### Nautilus

Nautilus 是 Gnome 预装的文件管理器。在终端使用下面命令可以运行带有 Root 权限的 Nautilus：

```bash
nautilus admin:/
```

## 影音娱乐

### QQ音乐

https://y.qq.com/download/download.html

### YesPlayMusic

高颜值的第三方网易云播放器

https://github.com/qier222/YesPlayMusic

### MusicFree

插件化、定制化、无广告的免费音乐播放器

https://github.com/maotoumao/MusicFree

### GIMP

[GIMP](https://www.gimp.org) 是一个自由开源的图片编辑器，它支持 Linux、Windows 和 macOS。它是 Adobe Photoshop 在 Linux 上最优秀的替代软件。你可以使用它执行任何图片编辑。网上有许多资源帮助你使用 GIMP。

访问https://www.gimp.org/downloads/下载 AppImage。

### vlc

在Ubuntu 24.04系统上安装VLC具有多重实用价值。作为一款多功能开源媒体播放器，VLC赋予用户播放多种音频视频文件格式的能力，这些格式可能无法在其他媒体播放器中原生支持。这种兼容性进一步延伸至多种流媒体协议，使用户得以观看直播流或访问远程文件。

```bash
sudo apt install vlc
```

### Steam

```bash
sudo apt install steam-installer steam-devices
```

对于官方仅支持 Windows 的游戏，可以使用 Proton 运行。要验证某个游戏是否可通过 Proton 运行，可访问 protondb.com。ProtonDB 是一个汇集玩家体验的便捷数据库网站，可以查询特定游戏在 Linux 系统上的性能表现。

如果游戏仅支持 Windows，可通过以下路径启用Steam Play（若尚未激活）：进入Steam -> 设置 -> Steam Play，勾选“为支持的游戏启用Steam Play”及“为所有其他游戏启用Steam Play”选项。

![](https://gastigado.cnies.org/d/halo20250324ubuntu2404_optimize/steam.webp?sign=1zhR5MVsAntCOQ92AvG-AR9vsW-hwLKVMo513krdTys=:0)


此时“适用于Windows”的提示信息应已消失，游戏页面上的“安装”按钮现在应显示为蓝色且可点击状态，就可以畅玩 Windows 游戏啦！

### OBS Studio

OBS Studio 是一款功能强大的开源软件，专用于视频录制与直播推流。

```bash
sudo apt install obs-studio
```

### Calibre

Calibre是一款功能强大且开源的电书管理软件，专为满足电子书读者与作者的多元化需求而设计。

```bash
sudo apt install calibre
```

## 开发工具

### JetBrains

建议前往 JetBrains 官网下载 JetBrains Toolbox，然后通过 JetBrains Toolbox 安装 IDEA、Pycharm、Clion、RustOver 等。

https://www.jetbrains.com/toolbox-app/

### VSCodium

VSCodium 是一款由社区驱动的开源版 VSCode。其核心功能与 VSCode 基本一致，但默认情况下禁用了遥测功能。这一特性使得 VSCodium 成为注重隐私保护、不希望使用数据被发送至微软的用户群体的理想选择。

```bash
wget -qO - https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/raw/master/pub.gpg \
    | gpg --dearmor \
    | sudo dd of=/usr/share/keyrings/vscodium-archive-keyring.gpg
echo 'deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg] https://download.vscodium.com/debs vscodium main' \
    | sudo tee /etc/apt/sources.list.d/vscodium.list
sudo apt update && sudo apt install codium
```

### Zed

[Zed是一个高性能的多人代码编辑器](https://github.com/zed-industries/zed)，由Atom与Tree-sitter的开发者打造。

```bash
curl -f https://zed.dev/install.sh | sh
```

## 虚拟机

### KVM/Qemu

 在开始安装之前，让我们检查一下你的机器是否支持虚拟化：

```bash
LC_ALL=C lscpu | grep Virtualization
```

如果是 AMD 处理器，应该输出：

```bash
Virtualization:                  AMD-V
```

如果是 Intel 处理器，应该输出：

```bash
Virtualization:                  VT-x
```

另外，[确保你的系统有多个处理器核心](https://linuxhandbook.com/check-cpu-info-linux/?ref=itsfoss.com)，这样你可以分配一些给你的虚拟机，并且仍然有足够的处理能力提供给宿主机。

如果你不确定，使用下面的命令，**输出应该大于零**：

```bash
egrep -c '(vmx|svm)' /proc/cpuinfo
```

一旦你都准备好了，你就可以用以下命令在 Ubuntu 上安装 Qemu 和 KVM：

```bash
sudo apt install qemu qemu-kvm virt-manager bridge-utils
```

安装结束后，**重新启动你的系统**。

**将用户添加到适当的组中**

为了使 Qemu 工作，你必须将你的用户加入两个组：`libvirt-kvm` 和 `libvirt`。

要做到这一点，请逐一使用以下命令：

```bash
sudo useradd -g $USER libvirt
sudo useradd -g $USER libvirt-kvm
```

接下来，启用并启动 `libvirt` 服务：

```bash
sudo systemctl enable libvirtd.service && sudo systemctl start libvirtd.service
```

这就行了！Qemu 的安装已经完成。

### Virtual Box

Virtual Box太卡不推荐使用

```bash
sudo apt install virtualbox irtualbox-ext-pack virtualbox-guest-additions-iso
```

## 参考资料

https://www.itangsoft.com/baike/show-14874.html

https://zhuanlan.zhihu.com/p/508797663

https://rsproxy.cn

https://blog.csdn.net/w20178556/article/details/131942074

https://linux.cn/article-4982-1.html

https://itsfoss.com/install-wireshark-ubuntu/

https://itsfoss.com/best-download-managers-linux/

https://blog.tcea.top/posts/typora-crack/

https://itsfoss.com/install-freeoffice-ubuntu/

https://zhuanlan.zhihu.com/p/631195884

https://zhuanlan.zhihu.com/p/65791205

https://linuxstory.org/linux-must-ask-how-to-install-7zip-in-linux/

https://linuxstory.org/3-ways-to-extract-and-copy-files-from-an-iso-image-on-a-linux-system/

https://www.cnblogs.com/real010/p/15460253.html

https://itsfoss.com/cant-run-appimage-ubuntu/

https://ubuntu.com/blog/linux-gaming-with-ubuntu-desktop-steam-and-proton
https://www.howtogeek.com/738967/how-to-use-steams-proton-to-play-windows-games-on-linux/