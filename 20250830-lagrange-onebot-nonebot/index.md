# 基于Lagrange.OneBot协议搭建NoneBot的聊天QQ机器人

Lagrange 是NTQQ协议的一个纯C#实现，NoneBot是跨平台 Python 异步聊天机器人框架。本文将介绍在Debian 12上部署一个基于Lagrange.OneBot的NoneBot聊天QQ机器人。

## 下载运行Lagrange.OneBot

访问 [Lagrange的发行页面](https://github.com/LagrangeDev/Lagrange.Core/releases)，下载符合我们需求的`Lagrange.OneBot_linux-x64_net9.0_SelfContained.tar.gz`。

上传到服务器，使用下面命令解压：

```bash
tar -xvzf ./Lagrange.OneBot_linux-x64_net9.0_SelfContained.tar.gz
```

将可执行文件移动到 Lagrange.OneBot 目录：

```bash
cd Lagrange.OneBot
mv ./bin/Release/net9.0/linux-x64/publish/Lagrange.OneBot ./Lagrange.OneBot
```

为可执行文件赋予执行权限：

```bash
chmod +x ./Lagrange.OneBot
```

赋予权限后运行程序

```bash
./Lagrange.OneBot
```

### 为 Lagrange 配置 systemd 服务

创建服务配置文件：

```bash
vim /lib/systemd/system/lagrange.service
```

写入以下内容（根据实际路径调整，写入前请删除注释）：

```bash
[Unit]
Description=Lagrange.OneBot Service
After=network.target  # 网络启动后再运行

[Service]
Type=simple
User=root  # 运行用户（根据需求修改，如非root需确保权限）
WorkingDirectory=/root/Lagrange.OneBot  # 程序所在目录
ExecStart=/root/Lagrange.OneBot/Lagrange.OneBot  # 程序完整路径
Restart=always  # 程序崩溃时自动重启
RestartSec=5  # 重启间隔（秒）

[Install]
WantedBy=multi-user.target  # 多用户模式下启动
```

## 安装NoneBot手脚架

建议使用虚拟环境执行。确保你已经安装了 Python 3.9 及以上版本，然后在命令行中执行以下命令：

```bash
python -m pip install --user pipx
python -m pipx ensurepath
```

如果在此步骤的输出中出现了“open a new terminal”或者“re-login”字样，那么请关闭当前终端并重新打开一个新的终端。

如果无法使用上述命令，可以执行：

```bash
sudo apt install pipx
pipx ensurepath  # 配置环境变量（可能需要重启终端）
```

用 pipx 安装脚手架

```bash
pipx install nb-cli
```

安装完成后，使用 `nb` 命令来使用脚手架。如果出现无法找到命令的情况（例如出现“Command not found”字样），请参考 [pipx 文档](https://pypa.github.io/pipx/) 检查你的环境变量。

## 创建NoneBot项目

输入以下命令创建NoneBot项目：

```
nb create
```

推荐选择 `simple`：

![image-20250830215110495](https://gastigado.cnies.org/d/halo20250830_lagrange_onebot_nonebot/image_20250830215110495.png?sign=UDdNg7vf5kUQ3ddtLgNIGYICcBi40RsBRcCOsCvQ5i8=:0)

输入一个项目名：

![image-20250830215150320](https://gastigado.cnies.org/d/halo20250830_lagrange_onebot_nonebot/image_20250830215150320.png?sign=AonzoQu93N83sZuDH6l2fPw9V-1VT5CfEifEzgl8uu8=:0)

选择 OneBot V11 适配器，按 <kbd>空格</kbd> 选择，然后按 <kbd>Enter</kbd> 下一步：

![image-20250830215232794](https://gastigado.cnies.org/d/halo20250830_lagrange_onebot_nonebot/image_20250830215232794.png?sign=n1D0zCMMnggWLWzC-uTfdfcdaXR1KjIjHOk-YVue1iM=:0)

同样默认选择 FastAPI 驱动器即可：

![image-20250830215401640](https://gastigado.cnies.org/d/halo20250830_lagrange_onebot_nonebot/image_20250830215401640.png?sign=hYns5jG6ZD4GglRfxDbQENwySBR-CxFhU6cCM9z410s=:0)

推荐选择 `src` 作为插件存储位置：

![image-20250830215525614](https://gastigado.cnies.org/d/halo20250830_lagrange_onebot_nonebot/image_20250830215525614.png?sign=CwR34TOLrfQ0mjTqtLY5x-1CuSJCRH-5WWPexu3mMl8=:0)

是否安装依赖，输入 `y`

![image-20250830215614661](https://gastigado.cnies.org/d/halo20250830_lagrange_onebot_nonebot/image_20250830215614661.png?sign=ViGgVDj2XOd3PcNCAXH4yZoY275O9rx1ixeJ8ojuJgk=:0)

创建虚拟环境，如果在虚拟环境中运行，可以输入 `n`，如果不在虚拟环境中运行，可以输入 `y`：

![image-20250830215642893](https://gastigado.cnies.org/d/halo20250830_lagrange_onebot_nonebot/image_20250830215642893.png?sign=LDkj16YJs_8KWrbpChTsdughPsZORyP0TSOZXpjfIlA=:0)

安装内置插件，推荐全部安装便于测试：

![image-20250830215802429](https://gastigado.cnies.org/d/halo20250830_lagrange_onebot_nonebot/image_20250830215802429.png?sign=fHo3ZRZsZmtYy8LMicCJ0W69L0n3apnbp6VnW5dtvEk=:0)

安装成功会出现下面提示：

![image-20250830215859407](https://gastigado.cnies.org/d/halo20250830_lagrange_onebot_nonebot/image_20250830215859407.png?sign=knoVTfN7CnRS38v1pyRGMFxk1NWUSbMOunL2ES5aO4I=:0)

根据提示运行下面命令：

```bash
cd chatbot
nb run --reload
```

出现类似下面命令且没有报错，证明 NoneBot 已经和 Lagrange 握手链

```bash
08-30 01:57:36 [SUCCESS] nonebot | NoneBot is initializing...
08-30 01:57:36 [INFO] nonebot | Current Env: dev
08-30 01:57:36 [DEBUG] nonebot | Loaded Config: {'driver': '~fastapi', 'host': IPv4Address('127.0.0.1'), 'port': 8080, 'log_level': 'DEBUG', 'api_timeout': 30.0, 'superusers': set(), 'nickname': set(), 'command_start': {'/'}, 'command_sep': {'.'}, 'session_expire_timeout': datetime.timedelta(seconds=120), 'environment': 'dev'}
08-30 01:57:36 [DEBUG] nonebot | Succeeded to load adapter "OneBot V11"
08-30 01:57:36 [SUCCESS] nonebot | Running NoneBot...
08-30 01:57:36 [SUCCESS] nonebot | Loaded adapters: OneBot V11
08-30 01:57:36 [INFO] uvicorn | Started server process [548469]
08-30 01:57:36 [INFO] uvicorn | Waiting for application startup.
08-30 01:57:36 [INFO] uvicorn | Application startup complete.
08-30 01:57:36 [INFO] uvicorn | Uvicorn running on http://127.0.0.1:8080 (Press CTRL+C to quit)
08-30 01:57:40 [INFO] uvicorn | 127.0.0.1:41046 - "WebSocket /onebot/v11/ws" [accepted]
08-30 01:57:40 [INFO] nonebot | OneBot V11 | Bot 2934575117 connected
08-30 01:57:40 [INFO] websockets | connection open
```

## 配置 NoneBot 后台运行

使用 nohup 命令，适合简单后台运行，但无法自动重启：

```bash
nohup nb run > /root/nonebot.log 2>&1 &
```

查看进程：

```bash
ps aux | grep nb                     # 查找进程 PID
tail -f /root/nonebot.log            # 查看实时日志
```

停止进程：

```bash
kill <PID>                           # 替换为实际 PID
```

当然，也可以使用 `screen`/`tmux` 持久化会话或者使用 `systemd` 创建服务，篇幅原因不再赘述。

## 测试

如果想要测试机器人是否启动运行，可以在 `src/plugins` 目录下新建 `test.py` 文件写入以下内容：

```python
from nonebot import on_regex
from nonebot.typing import T_State
from nonebot.adapters.onebot.v11 import GroupMessageEvent, Bot, Message

Test = on_regex(pattern=r'^测试$',priority=1)


@Test.handle()
async def Test_send(bot: Bot, event: GroupMessageEvent, state: T_State):
    msg = "测试成功"
    await Test.finish(message=Message(msg))
```

在群聊发送“测试”，如果看到机器人回复，则机器人正常运行：

![image-20250830221108484](https://gastigado.cnies.org/d/halo20250830_lagrange_onebot_nonebot/image_20250830221108484.png?sign=vhHsZ0gH9C2G-INOmGktyy6FpvAGa4UTjAqs44J6cmQ=:0)

此时恭喜你成功搭建了一个QQ聊天机器人。

## 修改端口

Lagrange 默认端口是 8080，但是这个端口经常被占用。下面将介绍如何将端口修改到 1145 端口。

首先停止 Lagrange 和 NoneBot，查看 8080 端口占用：

```bash
lsof -i:3010
```

杀死占用进程（将 PID 替换为实际进程号）:

```bash
kill -9 <PID>
```

在 Lagrange 目录下，编辑 `appsettings.json`

```bash 
vim ./appsettings.json
```

将端口进行修改

```json
"Implementations": [
    {
        "Type": "ReverseWebSocket",
        "Host": "127.0.0.1",
        "Port": 1145, // 修改为1145
        "Suffix": "/onebot/v11/ws",
        "ReconnectInterval": 5000,
        "HeartBeatInterval": 5000,
        "AccessToken": ""
    }
]
```

然后在 NoneBot 项目文件夹（本例为 `chatbot`）下，修改 `.env` 文件：

```bash
vim .env
```

在 `.env` 文件后添加下面内容指定端口：

```bash
PORT=3010
```

保存并退出，然后重新运行 Lagrange 和 NoneBot 即可。