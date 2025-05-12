---
迁移 Visual Studio Code 设置和扩展到 VSCodium
---

Visual Studio Code（以下简称 VS Code）无疑是当下最常用的代码编辑器。尽管微软的 VS Code 源代码采用 MIT 协议开源（意味着核心代码是开放透明的），但用户实际下载使用的「Visual Studio Code」客户端，其最终用户许可协议（EULA）**并非自由开源软件（Non-FLOSS）许可**，且内置了“遥测追踪”功能。微软在协议中直白写道：

> ...可能会收集您及软件使用的相关信息，并发送给微软...您可以选择关闭部分追踪场景，但并非全部... 

微软坚称这些数据仅用于漏洞追踪等“正当用途”，这或许是真的。但现数据一旦离手，谁又能保证它不会被别有用心之人（甚至是规则变更后的官方）用于其他目的？

你当然可以手动关闭VS Code的遥测上报功能，但别忘了：作为商业公司，微软完全有机会在未来版本中悄悄加入其他“隐蔽功能”——这些改动可能藏在冗长的更新日志里，稍不留意就会从你眼前滑过。

[VSCodium](https://vscodium.com/) 是微软 Visual Studio Code 的一个 100% 免费且开源克隆版本。它是由社区驱动、采用自由许可的二进制发行版，不包含微软的遥测/跟踪功能。

## 安装

访问 [https://vscodium.com/#install](https://vscodium.com/#install) 下载对应的二进制文件即可。也可以使用 [不同平台对应的包管理器](https://github.com/VSCodium/vscodium/blob/master/README.md#download-install) 进行安装。

## 迁移扩展

VSCodium（以及从源代码全新克隆构建的 Visual Studio Code 副本）将其扩展文件存储在 `~/.vscode-oss` 中。因此，如果你当前已安装了 Visual Studio Code，扩展将不会自动迁移。你需要在 VSCodium 中从扩展市场重新安装扩展，或者将扩展从 `~/.vscode/extensions` 复制到 `~/.vscode-oss/extensions`。

## 迁移设置和快捷键

Visual Studio Code 将其 keybindings.json 和 settings.json 文件存储于以下位置：

- Windows: `%APPDATA%\Code\User`
- macOS: `$HOME/Library/Application Support/Code/User` 
- Linux: `$HOME/.config/Code/User`

可以将这些文件复制到 VSCodium 的用户设置文件夹中：

- Windows: `%APPDATA%\VSCodium\User`
- macOS: `$HOME/Library/Application Support/VSCodium/User`
- Linux: `$HOME/.config/VSCodium/User`

手动复制设置配置：

- 在 Visual Studio Code 中，前往设置。
- 点击三个点“...”并选择“打开 `settings.json`。
- 将 `settings.json` 的内容复制到 VSCodium 中的相同位置

## 配置扩展源

VSCodium 是一个基于 VSCode 的编辑器，通过安装 VS Code 扩展可以获得额外的功能。但是，由于微软禁止其他产品使用 Microsoft Marketplace（市场），也禁止从市场中重新分发 “.vsix” 文件，因此，在非微软产品中使用 VS Code 扩展需要以不同的方式安装。

默认情况下，`product.json`文件设置为使用 [open-vsx.org](https://open-vsx.org/) 作为扩展程序库，该库具有适配器，可以使用 VS Code 使用的 Marketplace API。由于这是一个相对较新的项目，您可能会错过一些您从 VS Code Marketplace 中了解的扩展程序。您有以下选项来获取这些缺失的扩展：

- 请求扩展程序维护者在[open-vsx.org](https://open-vsx.org/)上发布扩展程序，以补充 VS Code Marketplace。发布过程在[Open VSX Wiki](https://github.com/eclipse/openvsx/wiki/Publishing-Extensions)中得到说明。
- 在[此存储库](https://github.com/open-vsx/publish-extensions)上创建拉取请求，让[@open-vsx](https://github.com/open-vsx)服务帐户为您发布扩展程序。
- 下载并[安装 vsix 文件](https://code.visualstudio.com/docs/editor/extension-gallery#_install-from-a-vsix)，例如从源代码库的发布页面。

在 `安装根目录/resources/app/product.json` 文件中的修改 `extensionsGallery` 键设置 VSCodium 采用微软官方扩展源：

```json
{
  "extensionsGallery": {
    "serviceUrl": "https://marketplace.visualstudio.com/_apis/public/gallery",
    "itemUrl": "https://marketplace.visualstudio.com/items",
    "cacheUrl": "https://vscode.blob.core.windows.net/gallery/index",
    "controlUrl": ""
  }
}
```

也可以使用以下环境变量：

- `VSCODE_GALLERY_SERVICE_URL='https://marketplace.visualstudio.com/_apis/public/gallery'`
- `VSCODE_GALLERY_ITEM_URL='https://marketplace.visualstudio.com/items'`
- `VSCODE_GALLERY_CACHE_URL='https://vscode.blob.core.windows.net/gallery/index'`
- `VSCODE_GALLERY_CONTROL_URL=''`

## 参考资料

[VSCodium - Open Source Binaries of VSCode](https://vscodium.com/)

[GitHub - VSCodium/vscodium: binary releases of VS Code without MS branding/telemetry/licensing](https://github.com/VSCodium/vscodium)

[VSCodium: 100% Open Source Clone of Microsoft VS Code](https://itsfoss.com/vscodium/)

[VS Code vs VS Codium: What's the Difference?](https://itsfoss.com/vs-code-vs-codium/)

[How to Migrate From Visual Studio Code to VS Codium - All Things Worthwhile](https://kb.levine.io/homelab/git/vs-code/how-to-migrate-from-vs-code-to-vs-codium/)

[Why and how you should migrate from Visual Studio Code to VSCodium - DEV Community](https://dev.to/0xdonut/why-and-how-you-should-to-migrate-from-visual-studio-code-to-vscodium-j7d)

[VSCodium 安装配置手册 | DogDayAfternoon](https://easternday.top/Application/VSCodium/)

[设置vscodium采用微软官方扩展源 - 知乎](https://zhuanlan.zhihu.com/p/276000982)