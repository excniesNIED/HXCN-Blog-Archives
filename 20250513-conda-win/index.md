---
Windows系统Anaconda/Miniconda的安装、配置、基础使用、清理缓存空间和Pycharm/VSCode配置指南
---

Conda 是一个开源的跨平台**包管理与环境管理工具**，广泛应用于数据科学、机器学习及 Python 开发领域。它不仅能帮助用户快速安装、更新和卸载第三方库，还能创建相互**隔离的虚拟环境，解决不同项目之间的依赖冲突**问题。例如，项目 A 依赖 Python 3.7 和 NumPy 1.0，而项目 B 需要 Python 3.10 和 NumPy 2.0，通过 conda 可分别创建独立环境，避免版本冲突。此外，conda 不仅支持 Python 包，还能管理 R、C/C++ 等非 Python 依赖，极大提升了跨语言开发的便捷性。

## 为什么推荐 conda 而不是 venv/pyenv

推荐 conda 而非venv的原因在于其开箱即用的生态闭环与跨语言依赖的托管能力。Conda 不仅管理 Python 包版本，还控制 Python 解释器本体，用户可以在同一设备上自由切换 Python 3.4 至 3.10 等不同运行时，这种能力在复现早期科研项目时尤为关键。

venv 是如何创建“独立”的 Python 运行环境的呢？原理很简单，就是把系统 Python 链接或复制一份到 venv 的环境，用命令
```bash
source activate
```
进入一个 venv 环境时，venv 会修改相关环境变量，让命令 python 和 pip 均指向当前的 venv 环境。但传统 venv 方案需要重新编译整个 Python 环境，而 Conda 能直接拉取预编译的解释器二进制文件。

Conda 的独特优势体现在非 Python 组件的管理维度。Conda 源中包含了包含了很多非 Python 的包，比如 gcc，nodejs，cuda，都可以用 conda 来安装和管理。因此很多时候你没得选。比如有个工程需要 torch 0.4，而torch 0.4 依赖了 cuda 9.0。而你电脑里只有 cuda 11.0，此时不需要 下载一个cuda 9.0，只需要使用

```bash
conda install cudatoolkit=9.0
```

就解决了cuda 版本问题。

环境复用效率是另一差异化特征。Venv 创建的隔离环境与项目目录深度绑定，迁移或复用需记忆复杂路径，而 conda 维护全局环境列表支持跨工程调用。当多个项目共享部分基础依赖时，可直接使用
```bash
conda activate <环境名>
```
激活既有环境避免重复安装虽然单个 conda 环境可能占用数百 MB 空间，但相较于为每个项目完整复制 PyTorch 等重型库的方案，整体磁盘利用率反而更优。

Conda 生态还缓解了跨平台编译难题。Windows 环境下配置科学计算库历来繁琐，conda 提供的预编译二进制包覆盖三大主流操作系统，确保 TensorFlow 或 NumPy 等含 C 扩展的包能绕过本地编译直接运行。这种特性对硬件资源有限的开发设备极为重要，用户不再需要为配置 MSVC 编译链耗费数小时。

## Anaconda 和 Miniconda

**Anaconda** 是基于 conda 的完整发行版，预装了超过 250 个科学计算和数据分析的常用工具包（如 NumPy、Pandas、Jupyter），适合新手或需要快速搭建开发环境的用户。但 Anaconda 的安装包体积较大（约 3 GB），对存储空间有限的用户可能不够友好。

**Miniconda** 是 conda 的极简版本，仅包含核心的 conda 工具、Python 基础环境和所依赖的包以及少量其他实用包。（安装包约 50 MB）。用户需手动安装所需依赖，适合熟悉 Python 生态或追求轻量化的开发者。例如，若仅需 TensorFlow 和 PyTorch，可通过 Miniconda 按需安装，避免冗余占用。

本文介绍 Windows 系统下的 Anaconda/Miniconda 安装、配置和基本使用。

## 下载

访问 Anaconda 官网 [https://www.anaconda.com](https://www.anaconda.com)，选择右上角“Free Download”，点击“Skip registration”，左侧为 Anaconda，右侧为 Miniconda，根据需求下载即可。

![image-20250513111933309](https://gastigado.cnies.org/d/halo20250513/anaconda_website_download.png?sign=_7YU6IIhGD9yTGd8gW0pyXPEAe4sUbcQacE2NpTlvPc=:0)

国内网络环境可能下载速度较慢，可以访问 [清华大学镜像网站下载最新版 Anaconda](https://mirrors.tuna.tsinghua.edu.cn/anaconda/)：

Anaconda 需要找的日期最新的版本进行下载，Miniconda 下载 `Miniconda3-latest` 即可：

![tsinghua](https://gastigado.cnies.org/d/halo20250513/tsinghua.png?sign=EQTOqvu0YNO7522RGXYIT7Nz7qhl4lqJvPWASmmCsrg=:0)

## 安装

**以 Anaconda 为例进行安装，Miniconda 安装过程同理。**

右键安装包，选择“以管理员身份运行”：

![run-as-admin](https://gastigado.cnies.org/d/halo20250513/run_as_admin.png?sign=WFNCeJcFsy7wOC_QiSBfHxPBt24FBQ9ZmUPsw78b8ko=:0)

进入安装界面，点击下一步即可：

![anaconda-setup-1](https://gastigado.cnies.org/d/halo20250513/anaconda_setup_1.png?sign=VH6un1OiBJh5JsmF9m0N99PQuQiH3qIFO058G43clTU=:0)

同意许可证：

![anaconda-setup-2](https://gastigado.cnies.org/d/halo20250513/anaconda_setup_2.png?sign=IMwvxkCGDxGoIsocWc-WjoRTHsRXEhJAxsJVB2vTBZE=:0)

选择为所有用户安装：

![anaconda-setup-3](https://gastigado.cnies.org/d/halo20250513/anaconda_setup_3.png?sign=II1rcIaSDqFyXKVdw61vuntx6GwfsTx2vNISrbqYbVo=:0)

选择一个安装位置。Anaconda 本体、系统级别的 conda 环境（如果以管理员身份安装）都会存储在这个位置，会占用很大空间，请根据自己需求修改位置。

值得注意的是，用户级别的虚拟环境会安装在 C 盘（通常在 `C:\Users\用户名\.conda\envs`），后面有修改虚拟环境位置的教程。

![anaconda-setup-4](https://gastigado.cnies.org/d/halo20250513/anaconda_setup_4.png?sign=qXyN1KbU96NqruVffJNzTfI9FOwhpDE9hhNRdBmr60E=:0)

推荐全部勾选：

![anaconda-setup-5](https://gastigado.cnies.org/d/halo20250513/anaconda_setup_5.png?sign=eC4NnD0Voasx6BfUD1DPVzBx5qTBoPEg6rOXF2eNX9g=:0)

等待全部安装，点击下一步，然后一直下一步即可：

![anaconda-setup-6](https://gastigado.cnies.org/d/halo20250513/anaconda_setup_6.png?sign=OU66ihWJcX1drYqfkY44r-XLW1sxkbe80vBKEUxMuS4=:0)

![anaconda-setup-7](https://gastigado.cnies.org/d/halo20250513/anaconda_setup_7.png?sign=ryFxqNQHQCfYzRe_xx7n4jbB7BJ33ksRuii11OESP0k=:0)

![anaconda-setup-8](https://gastigado.cnies.org/d/halo20250513/anaconda_setup_8.png?sign=PRV0jHFt3l7RLy1whWSixrAVZzXtcERzUa6dR0Y30yA=:0)

按照下面方法找到 Anaconda 的安装路径，备用：

![install-path](https://gastigado.cnies.org/d/halo20250513/install_path.png?sign=LxE9Xtu0MmeHSR7NkT4SSUFQ7DHGUIN5lB3e8NYayCs=:0)

按 <kbd>Win</kbd> + <kbd>s</kbd> 搜索“环境变量”，在弹出窗口点击“环境变量”，选择“系统变量”下的“Path”，然后点击“编辑”：

![env](https://gastigado.cnies.org/d/halo20250513/env.png?sign=UFmqjJVWjCbhqtqLXYSZlZsV00ScdU3yiQJNd00mup8=:0)

将 `<安装目录>`、`<安装目录>/Scripts`、`<安装目录>/Library/bin` 添加到环境变量中，然后一路点击“确定”后生效：

![env-2](https://gastigado.cnies.org/d/halo20250513/env_2.png?sign=U9TlqgzsW0GdLILxYKBhA2eP6C2rTpGXybQplawvFlU=:0)

想要验证环境变量是否配置成功，按 <kbd>Win</kbd> + <kbd>x</kbd>，选择“终端”，输入 `conda --version`，终端输出版本号，证明配置成功：

![ps-var](https://gastigado.cnies.org/d/halo20250513/ps_var.png?sign=Brz74GcMVyD6ajXKni-N-FA0gPcVFhHXHPF7UisFPlI=:0)

## 初始化

在终端输入下面命令，然后重启终端

```bash
conda init
```

### 修复PowerShell执行策略报错

重启终端后，可能出现下面报错：

```bash
. : 无法加载文件 C:\Users\excnies\Documents\WindowsPowerShell\profile.ps1，因为在此系统上禁止运行脚本。有关详细信息，请

参阅 https:/go.microsoft.com/fwlink/?LinkID=135170 中的 about_Execution_Policies。

所在位置 行:1 字符: 3

+ . 'C:\Users\excnies\Documents\WindowsPowerShell\profile.ps1'

+   ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    + CategoryInfo          : SecurityError: (:) []，PSSecurityException

    + FullyQualifiedErrorId : UnauthorizedAccess
```

这个错误信息表明你的 Windows PowerShell 执行策略阻止了 `profile.ps1` 脚本的加载。系统默认禁止运行脚本以防止恶意脚本的执行。Windows PowerShell 有一个执行策略，用于控制哪些 PowerShell 脚本可以在系统上运行。默认情况下，这个策略通常设置为 "Restricted"（受限制的），这意味着不允许运行任何脚本文件，包括你的个人配置文件 `profile.ps1`。

你需要更改 PowerShell 的执行策略才能加载并运行 `profile.ps1` 脚本。

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

或者，如果你想为所有用户更改（需要管理员身份运行终端）：

```powershell
Set-ExecutionPolicy RemoteSigned -Scope LocalMachine
```

如果 RemoteSigned 不起作用，可以尝试 Unrestricted（请谨慎使用）：

```powershell
Set-ExecutionPolicy Unrestricted -Scope CurrentUser
```

或者，如果你想为所有用户更改（需要管理员身份运行终端）：

```powershell
Set-ExecutionPolicy Unrestricted -Scope LocalMachine
```

当系统询问你是否要更改执行策略时，输入 `Y` (是) 并按 Enter。

重启终端，当命令行开头出现 `base`，初始化成功：

![conda-init](https://gastigado.cnies.org/d/halo20250513/conda_init.png?sign=MbXPcQvY2h8KyN1HZfmwgkgubH77BmpW3ZeCQAb-ZLc=:0)

## 修改虚拟环境地址

### 方法一：修改.condarc

Conda 环境默认安装在用户目录 `C:\Users\<用户名>\.conda\envs` 下，如果选择默认路径，那么之后创建虚拟环境，也是安装在用户目录下，会占用 C 盘大量的空间。不想占用 C 盘空间，可以修改虚拟环境路径。

首先查找 `.condarc` 的文件路径：

```bash
conda info

     active environment : base
    active env location : C:\ProgramData\anaconda3
            shell level : 1
       user config file : C:\Users\excnies\.condarc
 populated config files : C:\ProgramData\anaconda3\.condarc
          conda version : 24.9.2
    conda-build version : 24.9.0
                    // ------ 省略 ------
       envs directories : C:\Users\excnies\.conda\envs
                          C:\ProgramData\anaconda3\envs
```

可以看到 `.condarc` 的文件路径 `user config file` 或 `populated config files`，用户和系统虚拟环境的的路径 `envs directories`。

添加或修改 `.condarc` 中的 `env_dirs` 和 `pkgs_dirs` 设置环境路径，按顺序第⼀个路径作为默认存储路径，搜索环境按先后顺序在各目录中查找。直接在 `.condarc` 添加：

```
envs_dirs:
  - <你希望修改的路径，如D盘>\conda\envs
pkgs_dirs:
  - <你希望修改的路径，如D盘>\conda\pkgs
```

重启终端，输入 `conda info`，就可以看到修改默认环境路径成功

![condarc](https://gastigado.cnies.org/d/halo20250513/condarc.png?sign=z3qLsw5a0LTBofkUe2YXxIFKp8IcQ2pGP8hqjhhHqBM=:0)

### 方法二：使用conda config命令

当新创建虚拟环境验证时，使用 `conda env list` 可能会发现它还是默认安装在 C 盘，可以执行下面命令：

```bash
conda config --add envs_dirs <你希望修改的路径，如D盘>\conda\envs # 添加环境路径
conda config --add pkgs_dirs <你希望修改的路径，如D盘>\conda\envs # 添加缓存路径
```

想要删除环境路径，可以使用下面命名：

```bash
conda config --remove envs_dirs <你希望修改的路径，如D盘>\conda\envs # 删除环境路径
conda config --remove pkgs_dirs <你希望修改的路径，如D盘>\conda\envs # 删除缓存路径
```

如果还是没有修改成功，则需要**提升修改后文件夹（`<你希望修改的路径，如D盘>\conda`）的权限**。右键文件夹，然后右击选则属性，找到安全，Users权限全部允许。接下来确定后，时间稍微有点长，等待完成即可。

这时新创建一个虚拟环境验证时，发现在D:\Anaconda3\envs下，修改成功。

## 配置国内软件源

### conda

删除之前的镜像源，换回conda默认源：

```bash
conda config --remove-key channels
```

然后执行

```bash
conda config --add channels defaults
```

#### 添加清华大学开源镜像站镜像源

```bash
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch/
```

#### 添加中国科学技术大学镜像源

```bash
conda config --add channels https://mirrors.ustc.edu.cn/anaconda/pkgs/free/
conda config --add channels https://mirrors.ustc.edu.cn/anaconda/pkgs/main/
```

#### 显示镜像通道（配置结果）

```bash
conda config --show channels
```

#### 删除下载源

使用 `--remove` 命令

```shell
conda config --remove channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
```

#### 通过.condarc修改

**为避免修改错误导致配置问题，建议先备份原 `.condarc`**。

**如果直接复制下面文字，请删除注释，以免遇到奇奇怪怪的报错**：

```yaml
channels:
  - defaults  # 最后添加官方默认源（备用）
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch/  # PyTorch 镜像源
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge/  # conda-forge 镜像源
  - https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/  # Anaconda 自由包镜像源

show_channel_urls: true  # 安装时显示具体使用的通道 URL（可选，但推荐）
```

Conda 会**优先使用列表中靠后的通道**（因为后添加的通道优先级更高）。上述配置中，`pytorch` 镜像源在最前，但实际优先级最低。我们希望优先使用清华镜像源，需将其放在列表**后面**，`defaults` 放在前面（作为备用）。

#### 包下载目录

虚拟环境的路径：`anaconda安装的位置\envs\虚拟环境\Lib\site-packages`
base环境的路径如下：`anaconda安装的位置\Lib\site-packages`

#### 下载报错

```bash
EnvironmentNotWritableError: The current user does not have write permissions to the target environment
NotWritableError: The current user does not have write permissions to a required path.
```

错误原因：后面列的那个文件夹缺写入权限，终端输入 `conda info`后，`base environment : D:\conda (writable)`，此处必须是可写的
解决方法：找到后面列的那个文件夹、右键、属性、安全、编辑、完全控制（或者只把写入勾上也行）

### pip

#### 永久切换

升级 pip 到最新的版本后进行配置：

```bash
python -m pip install --upgrade pip
pip config set global.index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple
```

如果您到 pip 默认源的网络连接较差，临时使用镜像站来升级 pip：

```bash
python -m pip install -i https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple --upgrade pip
```

#### 临时切换

可以直接在 pip 命令中使用 **-i** 参数来指定镜像地址，例如：

```bash
pip3 install numpy -i https://pypi.tuna.tsinghua.edu.cn/simple
```

#### 修改`pip.ini`

在 `C:\user\username\目录下`，创建 `pip` 文件夹，并在该文件夹内创建 `pip.ini` 文件，即在 `C:\user\username\pip\pip.ini` 中，加入以下内容：

```ini
[global]
index-url=https://pypi.tuna.tsinghua.edu.cn/simple
[install]
trusted-host=pypi.tuna.tsinghua.edu.cn
disable-pip-version-check = true
timeout = 6000
```

## 管理虚拟环境

Conda 允许创建独立的虚拟环境，以隔离不同项目的依赖项，避免版本冲突。

### 创建虚拟环境

使用 `conda create` 命令创建隔离环境，支持指定 Python 版本、预安装包及环境名称。基础语法：  

```bash
conda create --name <环境名称> python=<Python版本> [其他包...]
```

**指定 Python 版本创建环境**：
例如，创建一个名为 `myenv` 且使用 Python 3.8 的环境：

```bash
conda create --name myenv python=3.8
```

**创建环境并同时安装指定包**：
例如，创建一个名为 `data_analysis` 的环境，使用 Python 3.9，并安装 `numpy` 和 `pandas`：

```bash
conda create --name data_analysis python=3.9 numpy pandas
```

**创建不含任何包的纯净环境**（后续手动安装所需包）：

```bash
conda create --name minimal_env
```

这种方式创建的环境可能不包含 Python 解释器，激活后需手动安装。

**从环境文件创建环境**：
如果有一个 `environment.yml` 文件（通常通过导出环境获得），可以使用以下命令创建相同的环境：

```bash
conda env create -f environment.yml
```

创建过程中，conda 会尝试在 `.condarc` 文件中 `envs_dirs` 指定的第一个路径下创建环境。如果该路径不可写或不存在，可能会报错或在默认路径下创建。

### 激活和退出虚拟环境

**激活环境**：
激活环境后，终端提示符前会显示当前环境的名称。所有 Python 和包相关的命令都将在该环境中执行。

```bash
conda activate <环境名称>
```

例如，激活之前创建的 `myenv` 环境：

```bash
conda activate myenv
```

左侧括号内 `base` 编程 `myenv`，激活成功：

![conda-activate](https://gastigado.cnies.org/d/halo20250513/conda_activate.png?sign=HGEFCaSn1kG7ebjDwLQn5e-3LvEFYMUhk5BwGtTHCYU=:0)

激活环境会修改系统的 `PATH` 环境变量，将当前激活环境的脚本和可执行文件路径置于优先位置。

**退出环境**：
退出当前激活的环境后，会返回到上一个环境（通常是 `base` 环境，或者如果没有其他环境激活，则返回到系统默认环境）。

```bash
conda deactivate
```

### 查看虚拟环境

可以列出所有已创建的 conda 环境：

```bash
conda env list
```

或者使用：

```bash
conda info --envs
```

命令输出会显示所有环境及其对应的路径。当前激活的环境会以星号 `*` 标记。

```
# conda environments:
#
base                  * C:\ProgramData\anaconda3
myenv                    D:\conda\envs\myenv
data_analysis            D:\conda\envs\data_analysis
```

### 删除虚拟环境

删除不再需要的虚拟环境可以释放磁盘空间。

```bash
conda env remove -n <环境名称>
```

或者使用更彻底的命令，确保删除所有相关文件：

```bash
conda remove -n <环境名称> --all
```

例如，删除名为 `myenv` 的环境：

```bash
conda remove -n myenv --all
```

**注意**：删除操作不可逆，请谨慎操作。

### 导出虚拟环境

为了在其他机器上复现环境或与他人共享环境配置，可以将当前激活的环境导出为一个 YAML 文件（通常命名为 `environment.yml`）。

**导出当前激活环境的精确包列表**：

```bash
conda env export > environment.yml
```

该文件包含了环境中所有包（包括 Python 版本和 conda 安装的包）的精确版本号和来源通道。

若需排除 base 环境的公共包（避免冗余），可添加 `--no-builds` 参数：  

```bash
conda env export --no-builds > environment.yml
```

**导出更通用的环境描述（推荐用于跨平台分享）**：
如果希望生成一个更简洁、更侧重于描述核心依赖而非所有间接依赖的文件，可以使用 `--from-history` 参数。这会记录用户显式安装的包。

```bash
conda env export --from-history > environment.yml
```

使用此文件创建环境时，conda 会尝试解析并安装最新兼容版本的依赖。

之后，其他人或自己在另一台机器上可以使用此文件创建相同的环境：

```bash
conda env create -f environment.yml
```

## 安装软件包

在激活目标虚拟环境后，可以使用 `conda install` 或 `pip install` 来安装软件包。

### conda install

`conda install` 是 conda 生态系统的首选安装方式，它会处理复杂的依赖关系，并能安装预编译的二进制包，避免了本地编译的麻烦，尤其对于科学计算包非常有用。

通过 conda 安装包时，会自动解析依赖并匹配兼容版本，推荐优先使用。基础语法：  

```bash
conda install -n <环境名> <包名>=<版本> [-c <通道>]
```

- `-n <环境名>`：可选参数，指定目标环境（若未激活目标环境）；若已激活环境，可省略。  
- `<包名>=<版本>`：指定包名及版本（如 `numpy=1.21`）；若省略版本，默认安装最新兼容版。  
- `-c <通道>`：可选参数，指定包的来源通道（如 `-c conda-forge` 或国内镜像源）。  

**基本安装**：

```bash
conda install <包名称>
```

例如，安装 `scikit-learn`：

```bash
conda install scikit-learn
```

**安装指定版本的包**：

```bash
conda install <包名称>=<版本号>
```

例如，安装 `numpy` 版本 1.20：

```bash
conda install numpy=1.20
```

也可以指定更灵活的版本范围，如 `numpy>=1.20`, `numpy<1.21`。

**从特定通道安装**：
如果默认通道没有某个包或特定版本，可以指定通道进行安装。

```bash
conda install -c <通道名称> <包名称>
```

例如，从 `conda-forge` 通道安装 `some-package`：

```bash
conda install -c conda-forge some-package
```

通道的优先级在 `.condarc` 文件中配置。

**搜索包**：
查找可用包及其版本：

```bash
conda search <包名称>
```

例如，搜索所有可用的 `tensorflow` 版本：

```bash
conda search tensorflow
```

### pip install

若 conda 源中无目标包（如部分小众 Python 库），可通过 pip 安装（需确保已激活目标环境）。语法：  

```bash
pip install <包名>==<版本> [-i <镜像源>]
```

- `==<版本>`：可选参数，指定包版本（如 `requests==2.25.1`）；若省略，安装最新版。  
- `-i <镜像源>`：可选参数，指定 pip 镜像源加速下载（如 `-i https://pypi.tuna.tsinghua.edu.cn/simple`）。  

**基本安装**：

```bash
pip install <包名称>
```

例如，安装 `requests`：

```bash
pip install requests
```

**安装指定版本的包**：

```bash
pip install <包名称>==<版本号>
```

例如，安装 `django` 版本 3.2：

```bash
pip install django==3.2
```

**注意**：

1.  **优先使用 `conda install`**：尤其对于有复杂二进制依赖的包（如 NumPy, SciPy, PyTorch, TensorFlow）。
2.  **在激活 conda 环境后使用 `pip`**：这样可以确保 `pip` 将包安装到当前 conda 环境的 `site-packages` 目录，而不是系统 Python 或其他环境。
3.  混合使用 `conda` 和 `pip` 通常是安全的，但建议先用 `conda` 安装尽可能多的包，然后再用 `pip` 补充。

### 批量安装软件包

**使用 conda 安装多个包**：
可以直接在 `conda install` 命令后列出所有需要安装的包名：

```bash
conda install <包1> <包2> <包3>
```

**从 `environment.yml` 文件安装 (创建或更新环境)**：
如前所述，`conda env create -f environment.yml` 用于创建新环境。
如果要在现有环境中安装或更新 `environment.yml` 文件中列出的包，可以使用：

```bash
conda env update --name <环境名称> --file environment.yml --prune
```

`--prune` 选项会移除环境中存在但 `environment.yml` 文件中未列出的包。

**从 `requirements.txt` 文件安装 (通常使用 pip)**：
如果有一个 `requirements.txt` 文件（通常用于 `pip`），可以在激活 conda 环境后使用 `pip` 安装：

```bash
pip install -r requirements.txt
```

`requirements.txt` 文件通常只包含包名和版本，格式如下：

```
numpy==1.20.3
pandas>=1.1.0
requests
```

### 删除软件包

**使用 conda 删除**：
从当前激活的环境中删除一个包：

```bash
conda remove <包名称>
```

例如，删除 `scikit-learn`：

```bash
conda remove scikit-learn
```

**清空当前环境的所有包（谨慎使用）:**

```bash
conda remove --all
```

**使用 pip 删除**：
如果包是使用 `pip` 安装的，也应该使用 `pip` 来卸载：

```bash
pip uninstall <包名称>
```

例如，删除 `requests`：

```bash
pip uninstall requests
```

删除时通常会有确认提示。

## 清理缓存

Conda 会缓存下载的包（`pkgs` 目录）、索引文件及临时文件，长期使用可能占用数 GB 空间。定期清理可释放磁盘资源。  

### 缓存类型及路径  

- **包缓存**：已下载但未被环境使用的包，路径为 `pkgs_dirs`（可通过 `conda info` 查看，默认在 `C:\Users\<用户名>\.conda\pkgs`）。  
- **索引缓存**：各通道的元数据索引，用于加速包搜索。  
- **临时文件**：下载过程中生成的临时文件。  

### conda缓存清理 

**清理未使用的包缓存**（保留当前环境正在使用的包）：  

```bash
conda clean -p  # --packages 的缩写
```

**清理索引缓存**（下次使用时会重新下载）：  

```bash
conda clean -i  # --index-cache 的缩写
```

**清理临时文件**（如下载中断的残留文件）：  

```bash
conda clean -t  # --tarballs 的缩写
```

**清理锁文件**：

```bash
conda clean -l # --lock-files 的缩写
```

**清理临时文件夹**：

```bash
conda clean -s  # tempfiles
```

**自动确认**：
在执行清理命令时添加 `-y` 参数可以跳过确认提示：

```bash
conda clean --all -y
```

**清理所有缓存**（谨慎操作，清理后无法恢复）：  

```bash
conda clean -a  # --all 的缩写，等价于 -p -i -t
```

### 注意事项  

- 清理前建议确认不需要这些缓存包（如跨环境复用的包可能被删除）。  
- 若需保留部分缓存，可手动进入 `pkgs` 目录删除冗余文件（需关闭 conda 相关进程）。  
- 清理后，再次安装相同包时会重新下载，可能影响首次安装速度。  
- 为了尽大程度释放空间，可以将不常用的虚拟环境导出为 yml 文件，删除整个环境，需要时再进行导入。

### pip缓存清理  

Pip 会缓存已下载的包（避免重复下载），缓存默认存储在 `C:\Users\<用户名>\AppData\Local\pip\Cache`（Windows），长期使用可能占用较多空间。以下是清理方法：  

**查看缓存信息**（位置、大小）：  

```bash
pip cache info
```

输出示例：  

```
Cache location: C:\Users\excnies\AppData\Local\pip\Cache
Cache size: 234.5 MB
```

**清理所有缓存**（删除所有已下载的包）：  

```bash
pip cache purge
```

执行后提示 `Successfully purged cache` 即清理完成。  

#### 注意事项  

若 `pip cache` 命令不可用（如旧版 pip），需先升级 pip：  

```bash
python -m pip install --upgrade pip
```

**手动清理**（命令失效时）：  
关闭所有终端及 Python 进程后，手动删除缓存目录 `C:\Users\<用户名>\AppData\Local\pip\Cache`（需管理员权限）。  

清理后，再次使用 `pip install` 下载相同包时会重新从源站获取，不影响功能。

## Pycharm使用conda虚拟环境

打开一个项目，点击设置，根据下面步骤添加本地解释器：

![pyc_inpl](https://gastigado.cnies.org/d/halo20250513/pyc_inpl.png?sign=6eN3f0LCR080iCYRw9QE-d4_LB_UfLrqG31KUemPOOc=:0)

如果预先创建好了虚拟环境，点击“选择现有”；如果需要创建新的环境，点击“生成新的”，“类型”选择“conda”，Python 版本根据需求自行填写。如果无法识别 conda 的路径，点击浏览，找到 `<conda的安装目录>/condabin/conda.bat` 即可。

![pyc_inpl-2](https://gastigado.cnies.org/d/halo20250513/pyc_inpl_2.png?sign=19Z0tQx1sG3iU1KY2pIn4NPunfSct7zzXKRkVRTnS44=:0)

添加 Python 解释器后，在设置中选择添加的解释器，或者在右下角修改解释器：

![pyc_inpl-3](https://gastigado.cnies.org/d/halo20250513/pyc_inpl_3.png?sign=KO23J2V9em1XMEyDw2_ngAdXKFAB-EObS04J9H0dLNg=:0)

## VSCode使用conda虚拟环境

![vscode_impl](https://gastigado.cnies.org/d/halo20250513/vscode_impl.png?sign=xU7GNAHg0D6gfoLfr-VNmZW0_iY5mPzowBncuDw55lw=:0)

点击右下角“选择解释器”，然后根据需求创建虚拟环境或者选择解释器。如果没有检测出需要的解释器，选择“输入解释器路径”后输入对应虚拟环境目录下的 `python.exe` 即可。

也可以按 <kbd>Ctrl</kbd> + <kbd>Shift</kbd> + <kbd>p</kbd>，输入 Python，创建环境或者选择解释器。

## 参考资料

[为什么有些人宁愿花费很多时间去自己手工配置Python环境, 也不用Anaconda? - 知乎](https://www.zhihu.com/question/404402864/answer/1692589822)

[venv - Python教程 - 廖雪峰的官方网站](https://liaoxuefeng.com/books/python/built-in-modules/venv/index.html)

[Anaconda下载与安装详解 - 上善若泪 - 博客园](https://www.cnblogs.com/jingzh/p/17397843.html)

[【2025年最新】Anaconda3的安装配置及使用教程(超详细)，从零基础入门到精通，看完这一篇就够了（附安装包）-CSDN博客](https://blog.csdn.net/logic1001/article/details/144931692)

[改变conda虚拟环境的默认路径_修改conda安装虚拟环境路径-CSDN博客](https://blog.csdn.net/qq_36455412/article/details/125347552)

[【Conda】自定义conda环境安装位置，三种解决方法_修改conda环境安装路径-CSDN博客](https://blog.csdn.net/XC___XC/article/details/134013893)

[修改conda虚拟环境路径 - 贝壳里的星海 - 博客园](https://www.cnblogs.com/tian777/p/17481056.html)

[pip 使用国内镜像源 | 菜鸟教程](https://www.runoob.com/w3cnote/pip-cn-mirror.html)

[python - How to free disk space taken up by (ana)conda? - Stack Overflow](https://stackoverflow.com/questions/48706548/how-to-free-disk-space-taken-up-by-anaconda)

[conda clean — conda 25.3.2.dev55 documentation](https://docs.conda.io/projects/conda/en/latest/commands/clean.html)

