---
【MkDocs踩坑】MathJax渲染\boldsymbol问题的排查与解决
---

## 问题的初现

在本人使用 MkDocs 搭建技术文档网站时，遇到了一个关于 LaTeX 公式渲染的棘手问题。具体来说，`\boldsymbol` 命令无法被正确渲染为粗斜体向量。页面在开发服务器（`mkdocs serve`）下首次加载时一切正常，公式显示完美。但只要我对 Markdown 文件进行任何修改并保存，触发实时重载后，原先正确的公式就会“损坏”。

损坏后的公式会将 `\boldsymbol` 文本直接显示出来，并通常被主题的 CSS 样式标记为红色，以提示这是一个未识别的命令。

这是当时出现问题的 LaTeX 代码块：
```latex
$$
\boldsymbol{c} =
  \begin{bmatrix}
    c_1\\
    c_2\\
    c_3
  \end{bmatrix} = X^{-1} \boldsymbol{u}_0
$$
```

当时，页面上渲染出的错误效果大致如下。

![在此处插入截图：\boldsymbol命令渲染失败，显示红色文本](https://gastigado.cnies.org/d/halo20250709_mkdocs_mathjax_rendering_issue/1_1752071975499_35.png "错误渲染效果")

## 尝试一：规避Markdown解析冲突

我的第一反应是 Markdown 解析器可能在处理反斜杠 `\` 时出现了问题。在 Markdown 语法中，单个反斜杠通常被视为转义字符。因此，传递给浏览器端 MathJax 的 `\boldsymbol` 命令可能已经残缺不全。

一个常见的解决思路是使用双反斜杠 `\\` 来转义，即写成 `\\boldsymbol`。然而，这个尝试并未奏效，反而让 `\boldsymbol` 被直接当作纯文本输出了。这让我意识到，问题比单纯的字符转义要复杂。

随后，我将注意力转向了 MkDocs 的扩展配置。我的 `mkdocs.yml` 文件中同时启用了 `pymdownx.superfences`（用于代码块美化）和 `pymdownx.arithmatex`（用于数学公式支持）。这两个扩展存在功能上的重叠，很可能 `superfences` 抢先捕获了 `$$...$$` 公式块，并将其错误地识别为一个未知语言的代码块，从而阻止了 `arithmatex` 的后续处理。

为了解决这个冲突，我调整了 `mkdocs.yml`，为 `pymdownx.arithmatex` 显式启用了美元符号块语法，期望它能获得更高的处理优先级。

```yaml
# mkdocs.yml
markdown_extensions:
  # ... 其他扩展 ...
  - pymdownx.arithmatex:
      generic: true
      block_syntax: 'dollar'
```

经过这个调整，并配合清理缓存后重启服务，页面上的公式块确实开始被 MathJax 稳定地识别和渲染了。这是一个巨大的突破，虽然 `\boldsymbol` 的问题依然存在，但至少证明了后端的解析流程已经通畅。

## 动态加载与脚本执行

我的推论是，问题的根源在于脚本的执行时机。当浏览器第一次加载页面时，会完整地执行所有 JavaScript，包括 MathJax 的初始化脚本。MathJax 会扫描整个文档对象模型（DOM），找到 `$$...$$` 这样的数学公式标记，然后将它们转换成格式优美的矢量图形或 HTML。这个过程是完整且正确的。

然而，当我修改文件后，`mkdocs serve` 为了提升效率，并不会让浏览器刷新整个页面。它只会将新生成的主体内容部分的 HTML 通过 WebSocket 推送给浏览器，然后由页面上的脚本将旧的内容区域替换掉。新推送过来的 HTML 里包含了未经渲染的原始 LaTeX 代码。对于页面上已经运行过的 MathJax 来说，它并不知道 DOM 中出现了新的、需要它处理的内容。因此，这些新内容就被遗漏了，导致渲染失败。

这个现象非常明确地指向了 MkDocs 的实时重载（Live Reload）机制与 MathJax 的 JavaScript 渲染流程之间存在冲突。

## 尝试二：强制 MathJax 重新渲染

要解决这个问题，思路很直接：必须在每次 MkDocs 动态更新内容后，主动通知 MathJax 再次执行其渲染任务。

我了解到 `mkdocs-material` 主题提供了一个名为 `document$.subscribe` 的事件订阅接口。这个接口专门用于处理此类动态内容更新的场景。于是，我创建了一个自定义的 JavaScript 文件，意图在每次内容更新后调用 MathJax 的渲染函数。

同时，我也意识到 `\boldsymbol` 命令并非 LaTeX 的核心命令，它属于 AMS (American Mathematical Society) 宏包的一部分。因此，必须在 MathJax 的配置中明确启用这个宏包。

是，我创建了一个 `docs/javascripts/mathjax.js` 配置文件，旨在 MathJax 主库加载前注入我的自定义配置。
```javascript
window.MathJax = {
  tex: {
    // 关键：添加 ams 宏包以支持 \boldsymbol
    packages: {'[+]': ['ams']}
  },
  options: {
    processHtmlClass: "arithmatex"
  }
};

document$.subscribe(() => {
  MathJax.typesetPromise();
});
```

同时，在 `mkdocs.yml` 中注册了这个脚本和 MathJax 库本身。

```yaml
extra_javascript:
  - javascripts/mathjax.js
  - https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js
```
我还清理了 `mkdocs.yml` 中 `pymdownx.arithmatex` 扩展的配置，确保它只使用 `generic: true` 模式，避免不必要的配置冲突。

## 问题范围的缩小

执行上述修改后，情况有了一些变化。`$$...$$` 公式块本身能够被正确渲染了，这说明 `document$.subscribe` 的机制确实生效了。但 `\boldsymbol` 依然是那个顽固的红色文本。

为了进一步确认问题，我做了一个对比测试。我将公式中的 `\boldsymbol` 替换为 `\mathbf`。`\mathbf` 是一个基础的粗体命令，不需要任何额外宏包。

测试结果是 `\mathbf` 可以完美渲染！

这个结果非常有价值。它把一个看似复杂的渲染问题，精确地缩小到了一个点上：**`ams` 宏包没有被成功加载**。我的配置文件 `mathjax.js` 虽然写了加载 `ams` 的指令，但 MathJax 引擎在初始化时出于某种原因忽略了它。

## 脚本加载的“竞速问题”

在浏览器开发者工具的控制台中，我尝试执行 `MathJax.tex.packages.keys()` 来检查已加载的包，结果却收到了一个 `undefined` 的错误。这个看似糟糕的结果，反倒成了破案的关键线索。它表明，在我的脚本执行时，全局的 `window.MathJax` 对象已经被 MathJax 引擎自身初始化后的内部API所替换。我的配置注入发生在 MathJax 初始化之后，自然也就无效了。

问题的根源在于脚本加载和执行的时序竞争（Race Condition），尤其是在 Material 主题这种包含复杂动态加载机制的环境中，依赖 `extra_javascript` 的顺序并不能百分之百保证配置在引擎初始化前就绪。

虽然我把自定义脚本放在了 MathJax 库之前，但这并不能 100% 保证在所有网络环境下都能避免这种竞速。要彻底解决这个问题，必须找到一种方法，能确保我的配置在 MathJax 库的脚本被请求之前，就已经作为页面的一部分牢固地存在。

## 尝试三：利用主题覆盖机制

`mkdocs-material` 主题提供了一个非常优雅且强大的功能：主题覆盖（Theme Overriding）。它允许我们用自定义的模板文件替换或扩展主题的默认模板。这正是我需要的。

我决定不再使用外部的 `mathjax.js` 文件，而是采用了 Material 主题官方推荐的、最为稳健的“主题覆盖”（Theme Override）方法：直接将 MathJax 的配置通过模板注入到每一个 HTML 页面的 `<head>` 或 `<body>` 中。这样，当浏览器解析 HTML 时，`window.MathJax` 这个全局配置对象会最先被创建。随后浏览器再去请求 MathJax 的主库文件时，它必然能读取到这个早已存在的配置。

具体的实施过程如下。

首先，在项目根目录创建 `overrides` 文件夹，并在其中新建一个 `main.html` 文件。

`overrides/partials/main.html` 的内容非常简洁，它继承了主题的 `base.html` 模板，并在 `scripts` 代码块中注入了我们的 MathJax 配置：

```html
{% extends "base.html" %}

{% block scripts %}
  {{ super() }}
  <script>
    window.MathJax = {
      tex: {
        packages: {'[+]': ['ams']}
      }
    };
  </script>
{% endblock %}
```
`{{ super() }}` 这行代码至关重要，它保证了主题原有的所有脚本依然会被加载。我们的配置脚本则紧随其后。

接着，修改 `mkdocs.yml` 文件，启用 `custom_dir` 并清理掉旧的 `extra_javascript` 配置。

```yaml
theme:
  name: material
  custom_dir: overrides
  # ... 其他主题配置

extra_javascript:
  # 不再需要我们自己的 mathjax.js 文件了
  - https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js
```

在重启服务并强制清空浏览器缓存后，问题终于得到了圆满解决。

![在此处插入截图：\boldsymbol命令被正确渲染为粗斜体](https://gastigado.cnies.org/d/halo20250709_mkdocs_mathjax_rendering_issue/2_1752071974972_56.png "正确渲染效果")

现在，无论页面是首次加载还是经过无数次实时重载，`\boldsymbol` 命令都能被稳定、正确地渲染出来。这次排查经历虽然曲折，但它让我对 Web 前端的脚本加载机制以及 MkDocs 主题的定制化有了更深刻的理解。在现代Web开发工作流中，问题的解决往往需要贯穿后端配置、前端脚本、资源加载时序等多个层面进行综合考量。通过这次实践，我不仅解决了眼前的技术难题，也掌握了在 MkDocs 生态中进行深度定制的可靠方法。