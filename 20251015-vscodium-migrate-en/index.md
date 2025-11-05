# Migrating Visual Studio Code Settings and Extensions to VSCodium

Visual Studio Code (hereinafter referred to as VS Code) is undoubtedly one of the most widely used code editors today. Although the source code of Microsoft's VS Code is open-sourced under the MIT License (meaning the core code is transparent), the final user license agreement (EULA) of the "Visual Studio Code" client that users actually download and use is **not a Free and Open Source Software (Non-FLOSS)** license**, and it includes a "telemetry" feature built-in. Microsoft clearly states in the license:

> Visual Studio Code collects telemetry data, which is used to help understand how to improve the product......we also know that not everyone wants to send usage data and you can disable telemetry as described in [disable telemetry reporting](https://code.visualstudio.com/docs/configure/telemetry#_disable-telemetry-reporting). 

Microsoft insists that this data is only used for "legitimate purposes" such as bug tracking, which may be true. However, once the data is out of their hands, who can guarantee that it won't be used for other purposes by people with ulterior motives (or even by the official party after the terms change)?

You can certainly manually disable the telemetry reporting feature in VS Code, but don't forget: as a commercial company, Microsoft has the full authority to quietly add other "hidden features" in future versions—these changes could be hidden in long update logs and easily go unnoticed.

[VSCodium](https://vscodium.com/) is a 100% free and open-source clone of Microsoft's Visual Studio Code. It is a community-driven, freely licensed binary distribution that does not contain Microsoft's telemetry/tracking features.

## Installation

Visit [https://vscodium.com/#install](https://vscodium.com/#install) to download the corresponding binary files. You can also use the [package managers for different platforms](https://github.com/VSCodium/vscodium/blob/master/README.md#download-install) to install it.

## Migrating Extensions

VSCodium (and a newly cloned version of Visual Studio Code from the source code) stores its extension files in `~/.vscode-oss`. Therefore, if you already have Visual Studio Code installed, the extensions will not be migrated automatically. You will need to reinstall the extensions from the extension market in VSCodium or copy the extensions from `~/.vscode/extensions` to `~/.vscode-extensions`.

## Migrating Settings and Shortcuts

Visual Studio Code stores its `keybindings.json` and `settings.json` files in the following locations:

- Windows: `%APPDATA%\Code\User`
- macOS: `$HOME/Library/Application Support/Code/User`
- Linux: `$HOME/.config/Code/User`

You can copy these files to VSCodium's user settings folder:

- Windows: `%APPDATA%\VSCodium/User`
- macOS: `$HOME/Library/Application Support/VSCodium/User`
- Linux: `$HOME/.config/VSCodium/User`

To manually copy the settings:

1. In Visual Studio Code, go to Settings.
2. Click on the three dots "..." and select "Open `settings.json`."
3. Copy the contents of `settings.json` to the corresponding location in VSCodium.

## Configuring the Extension Source

VSCodium is an editor based on VS Code, and you can get additional features by installing VS Code extensions. However, since Microsoft prohibits other products from using the Microsoft Marketplace and also prohibits the redistribution of `.vsix` files from the marketplace, installing VS Code extensions in non-Microsoft products requires a different approach.

By default, the `product.json` file is set to use [open-vsx.org](https://open-vsx.org/) as the extension library, which has adapters that allow use of the Marketplace API used by VS Code. Since this is a relatively new project, you might miss out on some extensions that are available from the VS Code Marketplace. You have the following options to obtain these missing extensions:

- Request the extension maintainers to publish the extensions on [open-vsx.org](https://open-vsx.org/) to complement the VS Code Marketplace. The publishing process is described in the [Open VSX Wiki](https://github.com/eclipse/openvsx/wiki/Publishing-Extensions).
- Create a pull request on [this repository](https://github.com/open-vsx/publish-extensions) to have the [@open-vsx](https://github.com/open-vsx) service account publish the extensions for you.
- Download and [install the vsix files](https://code.visualstudio.com/docs/editor/extension-gallery#_install-from-a-vsix), for example, from the release page of the source code repository.

Modify the `extensionsGallery` key in the `install-root/resources/app/product.json` file to use Microsoft's official extension repository:

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

You can also use the following environment variables:

- `VSCODE_GALLERY_SERVICE_URL='https://marketplace.visualstudio.com/_apis/public/gallerymatchCondition`
- `VSCODE_GALLERY_ITEM_URL='https://marketplace.visualstudio.com/items'
- `VSCODE_GALLERY_CACHE_URL='https://vscode.blob.core.windows.net/gallery/index'
- `VSCODE_GALLERY_CONTROL_URL ''
`

## References

- [VSCodium - Open Source Binaries of VSCode](https://vscodium.com/)
- [GitHub - VSCodium/vscodium: Binary releases of VS Code without MS branding/telemetry/licensing](https://github.com/VSCodium/vscodium)
- [VSCodium: 100% Open Source Clone of Microsoft VS Code](https://itsfoss.com/vscodium/)
- [VS Code vs VS Codium: What's the Difference?](https://itsfoss.com/vs-code-vs-codium/)
- [How to Migrate From Visual Studio Code to VS Codium - All Things Worthwhile](https://kb.levine.io/homelab/git/vs-code/how-to-migrate-from-vs-code-to-vs-codium/)
- [Why and how you should migrate from Visual Studio Code to VSCodium - DEV Community](https://dev.to/0xdonut/why-and-how-you-should-to-migrate-from-visual-studio-code-to-vscodium-j7d)
- [VSCodium Installation and Configuration Guide | DogDayAfternoon](https://easternday.top/Application/VSCodium/)
- [Setting vscodium to Use Microsoft's Official Extension Source - Zhihu](https://zhuanlan.zhihu.com/p/276000982)