# Part 0 Level 1

## 通过 NodeInject 和 Yporaject 在 Linux 安装激活 Typora

参考：[白鼠的小站](https://blog.tcea.top/posts/20231001-typora-crack/)

### 配置 Rust 编译环境Linux：

```
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```

### 安装官方版 Typora

```
flatpak install io.typora.Typora
```

###  克隆 Yporaject 项目

```
git clone https://github.com/hazukieq/Yporaject.git --depth=1
```

> 如果在克隆项目时遇到网络问题，可以使用 gitclone.com 提供的镜像加速：
>
> ```
> git clone https://gitclone.com/github.com/hazukieq/Yporaject.git --depth=1
> ```
>
> 也可以使用
>
> ```
> git config --global http.proxy/https.proxy
> ```
>
> 来为 Git 手动设置代理，本文不再赘述。

### 编译 Yporaject 项目

下面的命令适用于 Bash，Windows Powershell 需要略作调整。

```
# 进入 Yporaject 项目
cd Yporaject
# 运行编译命令
cargo build
# 查看二进制是否生成,程序名称为 node_inject
ls target/debug
```

### 复制二进制程序到安装目录下

```
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

### 获取 License Key

```
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

```
Finished dev [unoptimized + debuginfo] target(s) in 0.00s
Running `target/debug/license-gen`
License for you: xxxxxx-xxxxxx-xxxxxx-xxxxxx
```

复制 License for you 后面的那一串序列号备用。

### 激活 Typora

```
#运行 Typora (或直接在桌面上点击程序图标)
typora &
```

依次点击界面上方菜单栏的 `帮助 > 我的许可证...(Help > My license)` 打开激活界面，然后输入激活邮箱（可以任意填写）和上面复制的序列码。

如果遇到网络问题导致的“序列码激活软件失败，连接不上服务器”，可以在 `偏好设置 > 通用` 中勾选 **“使用 Typora 国内服务器”**。如果问题仍然没有解决，可以挂代理后使用国外激活服务器（不勾选 “使用 Typora 国内服务器”）重试。

## Markdown 语法笔记

参考：[Markdown 教程](https://markdown.com.cn/)

### Markdown 基本语法

Markdown是一种轻量级标记语言，排版语法简洁，让人们更多地关注内容本身而非排版。它使用易读易写的纯文本格式编写文档，可与HTML混编，可导出 HTML、PDF 以及本身的 .md 格式的文件。因简洁、高效、易读、易写，Markdown被大量使用，如Github、Wikipedia、简书等。

省略

---

## Markdown 中文排版

参考：[FOSSScope](https://fosscope.com/wiki/fosscope-workflow/markdown-format-guidelines)

## 标题

### 使用 `#` 来表示标题

开源观察所有文章都使用 `#` 来表示标题，而不是 `=` 和 `-`。

正确：

```
# 这是一级标题
## 这是二级标题
### 这是三级标题
#### 这是四级标题
##### 这是五级标题
```

错误：

```
这是一级标题
================
这是二级标题
----------------
```

### 正文从二级标题开始

由于网站使用 Hexo 构建，而 Hexo 默认会将文章标题作为一级标题渲染到页面中，所以文章正文应该从二级标题开始。

## 空格

> 「有研究显示，打字的时候不喜欢在中文和英文之间加空格的人，感情路都走得很辛苦，有七成的比例会在 34 岁的时候跟自己不爱的人结婚，而其余三成的人最后只能把遗产留给自己的猫。毕竟爱情跟书写都需要适时地留白。
>
> 与大家共勉之。」——[vinta/paranoid-auto-spacing](https://github.com/vinta/pangu.js)

### 中英文之间需要增加空格

正确：

> 在 LeanCloud 上，数据存储是围绕 `AVObject` 进行的。

错误：

> 在LeanCloud上，数据存储是围绕`AVObject`进行的。
>
> 在 LeanCloud上，数据存储是围绕`AVObject` 进行的。

完整的正确用法：

> 在 LeanCloud 上，数据存储是围绕 `AVObject` 进行的。每个 `AVObject` 都包含了与 JSON 兼容的 key-value 对应的数据。数据是 schema-free 的，你不需要在每个 `AVObject` 上提前指定存在哪些键，只要直接设定对应的 key-value 即可。

例外：「豆瓣FM」等产品名词，按照官方所定义的格式书写。

### 中文与数字之间需要增加空格

正确：

> 今天出去买菜花了 5000 元。

错误：

> 今天出去买菜花了 5000元。
>
> 今天出去买菜花了5000元。

### 数字与单位之间需要增加空格

正确：

> 我家的光纤入屋宽带有 10 Gbps，SSD 一共有 20 TB

错误：

> 我家的光纤入屋宽带有 10Gbps，SSD 一共有 20TB

例外：度数／百分比与数字之间不需要增加空格：

正确：

> 角度为 90° 的角，就是直角。
>
> 新 MacBook Pro 有 15% 的 CPU 性能提升。

错误：

> 角度为 90 ° 的角，就是直角。
>
> 新 MacBook Pro 有 15 % 的 CPU 性能提升。

### 全角标点与其他字符之间不加空格

正确：

> 刚刚买了一部 iPhone，好开心！

错误：

> 刚刚买了一部 iPhone ，好开心！
>
> 刚刚买了一部 iPhone， 好开心！

## 标点符号

### 不重复使用标点符号

虽然中国大陆的标点符号用法允许重复使用标点符号，但是这么做会破坏句子的美观性。

正确：

> 德国队竟然战胜了巴西队！
>
> 她竟然对你说「喵」？！

错误：

> 德国队竟然战胜了巴西队！！
>
> 德国队竟然战胜了巴西队！！！！！！！！
>
> 她竟然对你说「喵」？？！！
>
> 她竟然对你说「喵」？！？！？？！！

## 全角和半角

不明白什么是全角（全形）与半角（半形）符号？请查看维基百科条目『[全角和半角](https://zh.wikipedia.org/wiki/全形和半形)』。

### 使用全角中文标点

正确：

> 嗨！你知道嘛？今天前台的小妹跟我说「喵」了哎！
>
> 核磁共振成像（NMRI）是什么原理都不知道？JFGI！

错误：

> 嗨! 你知道嘛? 今天前台的小妹跟我说 “喵” 了哎！
>
> 嗨!你知道嘛?今天前台的小妹跟我说”喵”了哎！
>
> 核磁共振成像 (NMRI) 是什么原理都不知道? JFGI!
>
> 核磁共振成像(NMRI)是什么原理都不知道?JFGI!

例外：中文句子内夹有英文书籍名、报刊名时，不应借用中文书名号，应以英文斜体表示。

### 数字使用半角字符

正确：

> 这个蛋糕只卖 1000 元。

错误：

> 这个蛋糕只卖 １０００ 元。

例外：在设计稿、宣传海报中如出现极少量数字的情形时，为方便文字对齐，是可以使用全角数字的。

### 遇到完整的英文整句、特殊名词，其内容使用半角标点

正确：

> 乔布斯那句话是怎么说的？「Stay hungry, stay foolish.」
>
> 推荐你阅读 *Hackers & Painters: Big Ideas from the Computer Age*，非常地有趣。

错误：

> 乔布斯那句话是怎么说的？「Stay hungry，stay foolish。」
>
> 推荐你阅读《Hackers＆Painters：Big Ideas from the Computer Age》，非常的有趣。

## 名词

### 专有名词使用正确的大小写

大小写相关用法原属于英文书写范畴，不属于本 wiki 讨论内容，在这里只对部分易错用法进行简述。

正确：

> 使用 GitHub 登录
>
> 我们的客户有 GitHub、Foursquare、Microsoft Corporation、Google、Facebook, Inc.。

错误：

> 使用 github 登录
>
> 使用 GITHUB 登录
>
> 使用 Github 登录
>
> 使用 gitHub 登录
>
> 使用 gｲんĤЦ8 登录
>
> 我们的客户有 github、foursquare、microsoft corporation、google、facebook, inc.。
>
> 我们的客户有 GITHUB、FOURSQUARE、MICROSOFT CORPORATION、GOOGLE、FACEBOOK, INC.。
>
> 我们的客户有 Github、FourSquare、MicroSoft Corporation、Google、FaceBook, Inc.。
>
> 我们的客户有 gitHub、fourSquare、microSoft Corporation、google、faceBook, Inc.。
>
> 我们的客户有 gｲんĤЦ8、ｷouЯƧquﾑгє、๓เςг๏ร๏Ŧt ς๏гק๏гคtเ๏ภn、900913、ƒ4ᄃëв๏๏к, IПᄃ.。

注意：当网页中需要配合整体视觉风格而出现全部大写／小写的情形，HTML 中请使用标淮的大小写规范进行书写；并通过 `text-transform: uppercase;`／`text-transform: lowercase;` 对表现形式进行定义。

### 不要使用不地道的缩写

正确：

> 我们需要一位熟悉 TypeScript、HTML5，至少理解一种框架（如 React、Next.js）的前端开发者。

错误：

> 我们需要一位熟悉 Ts、h5，至少理解一种框架（如 RJS、nextjs）的 FED。

## 其他

### 链接之间增加空格

用法：

> 请 [提交一个 issue](https://fosscope.com/wiki/fosscope-workflow/markdown-format-guidelines#) 并分配给相关同事。
>
> 访问我们网站的最新动态，请 [点击这里](https://fosscope.com/wiki/fosscope-workflow/markdown-format-guidelines#) 进行订阅！

对比用法：

> 请[提交一个 issue](https://fosscope.com/wiki/fosscope-workflow/markdown-format-guidelines#)并分配给相关同事。
>
> 访问我们网站的最新动态，请[点击这里](https://fosscope.com/wiki/fosscope-workflow/markdown-format-guidelines#)进行订阅！

### 简体中文使用直角引号

用法：

> 「老师，『有条不紊』的『紊』是什么意思？」

对比用法：

> “老师，‘有条不紊’的‘紊’是什么意思？”