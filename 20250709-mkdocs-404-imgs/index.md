---
【MkDocs踩坑】图片路径问题的排查与解决
---

近期，本人在使用 MkDocs 构建项目文档时，遇到了一个颇为棘手的路径问题。我的 Markdown 文件在本地编辑器 Typora 中显示完全正常，所有图片都能正确加载。然而，通过 `mkdocs serve` 启动本地服务后，网站页面上的一部分图片却无法显示。这个现象引发了我的深入排查。

<img src="https://gastigado.cnies.org/d/halo20250709_mkdocs_404_imgs/pic_404_error.png?sign=gHj4BlOvGR-6gsr5C1POlog3hcMJBvFUDSoRK9KtgmQ=:0" style="zoom:50%;" />

#### 问题现象与初步分析

问题的具体表现是，表格中通过 `<img>` 标签引用的图片全部失效，而文档中其他地方使用标准 Markdown 语法 `![...](...)` 引用的图片则显示正常。

```markdown
<!--显示异常的代码片段-->
| 分解                                       |                         图示                         | 说明                                                         |
| :----------------------------------------- | :--------------------------------------------------: | :----------------------------------------------------------- |
| **$\boldsymbol{A=CR}$**                    |   <img src="figs/A_CR.png" alt="A=CR" width="200">   | $C$为$A$的线性无关列<br>$R$为$A$的行阶梯形矩阵<br>可推知 列秩 = 行秩 |
| **$\boldsymbol{A=LU}$**                    |   <img src="figs/A_LU.png" alt="A=LU" width="200">   | $LU$分解通过<br>高斯消去法<br>(下三角)(上三角)               |
| **$\boldsymbol{A=QR}$**                    |   <img src="figs/A_QR.png" alt="A=QR" width="200">   | $QR$分解为<br>格拉姆-施密特正交化中的<br>正交矩阵$Q$和三角矩阵$R$ |
| **$\boldsymbol{S=Q\Lambda Q^\mathrm{T}}$** | <img src="figs/A_QLQT.png" alt="A=QLQT" width="200"> | 对称矩阵$S$可以进行<br>特征值分解<br>特征向量组成$Q$, 特征值组成$\Lambda$ |
| **$\boldsymbol{A=U\Sigma V^\mathrm{T}}$**  | <img src="figs/A_USVT.png" alt="A=USVT" width="200"> | 所有矩阵$A$的<br>奇异值分解 <br>奇异值组成$\Sigma$           |
<!--显示正常的代码片段-->
![Pattern 4 - (P4)](figs/Pattern4.png)
*<p align="center">图 10: Pattern 4 - (P4)</p>*

```

终端的报错信息是关键的线索。它为每一张失效的图片都返回了 404 Not Found 错误。

```
WARNING - "GET /.../The-Art-of-Linear-Algebra-zh-CN/figs/A_CR.png HTTP/1.1" code 404
```

这个 URL 请求路径引起了我的注意。它表明浏览器试图在当前页面的子目录中寻找 `figs` 文件夹。对比这个请求路径和我的 `docs` 目录结构，我意识到问题的根源在于路径解析的差异。我的 `figs` 文件夹与引用它的 Markdown 文件是同级关系，并非子级。

#### URL 生成策略与路径差异

MkDocs 的一个核心特性影响了最终的路径。Material 主题默认启用了 `use_directory_urls: true` 选项。这个设置会为每个页面生成一个独立的目录，以创建更整洁的 URL。

例如，一个名为 `The-Art-of-Linear-Algebra-zh-CN.md` 的文件，会被编译成 `The-Art-of-Linear-Algebra-zh-CN/index.html`。这个行为导致了编译后的 HTML 文件，相比其源 Markdown 文件，在目录结构上深了一层。

当浏览器访问这个页面时，它的当前路径是 `.../The-Art-of-Linear-Algebra-zh-CN/`。此时，一个写为 `src="figs/..."` 的相对路径自然会被解析为 `.../The-Art-of-Linear-Algebra-zh-CN/figs/...`。这与 `figs` 文件夹的实际位置 `.../figs/...` 不符，因此导致 404 错误。

#### 标准 Markdown 与 HTML 标签的解析行为

至此，还有一个疑问没有解开：为何标准 Markdown 语法的图片链接能正常工作？

经过仔细比对，我发现显示正常的图片使用的是标准 Markdown 语法，形如 `![图片描述](figs/CR1.png)`。而表格中失效的图片则嵌入了原始的 HTML `<img>` 标签，以便控制图片宽度。

这揭示了两者在解析机制上的根本不同。

> **标准 Markdown 语法**：MkDocs 的解析器足够智能。它能识别出这是 Markdown 图片链接，并会分析其路径。在编译时，它会根据最终生成的网站目录结构，自动将 `figs/CR1.png` 修正为正确的相对路径，即 `../figs/CR1.png`。这是一个动态的、自动化的修正过程。

> **HTML `<img>` 标签**：当解析器遇到原始的 HTML 代码时，它会假定开发者意图明确。因此，它不会干预 `src` 属性内的路径，而是将其原封不动地输出到最终的 HTML 文件中。浏览器接收到的就是未经修正的 `src="figs/A_CR.png"`，从而导致了错误的请求。

#### 两种解决方案的实践与权衡

明确了问题根源后，我尝试了两种解决方案。

**第一种方案是直接修正路径。** 为了快速验证我的猜想，我手动修改了 `<img>` 标签中的路径，将其从 `src="figs/..."` 改为 `src="../figs/..."`。这个改动是告诉浏览器，需要先向上返回一级目录，再去寻找 `figs` 文件夹。修改后，网站上的图片果然全部恢复了正常显示。这个方案的优点是快速直接，但它的缺点也同样明显：这个路径在 Typora 等本地编辑器中会失效，破坏了本地预览的体验。

**第二种方案是调整项目的文件组织结构。** 一个更彻底且规范的方案，是让源目录结构与最终生成的网站结构保持逻辑上的一致。我创建了一个与 Markdown 文件同名的目录 `The-Art-of-Linear-Algebra-zh-CN/`。然后，将原 Markdown 文件移入该目录并重命名为 `index.md`，同时也将 `figs` 文件夹一并移入。

调整前后的目录结构如下：
```markdown
<!--调整前-->
docs/
└── resource/
    └── theory/
        └── Linear_Algebra/
            ├── The-Art-of-Linear-Algebra-zh-CN.md  <-- 你的 Markdown 文件
            └── figs/                               <-- 图片文件夹（作为同级）
                ├── A_CR.png
                └── ...
<!--调整后-->
docs/
└── resource/
    └── theory/
        └── Linear_Algebra/
            └── The-Art-of-Linear-Algebra-zh-CN/  <-- 这是一个目录
                ├── index.md                      <-- 原来的 Markdown 内容在这里
                └── figs/                         <-- 图片文件夹现在在这里
                    ├── A_CR.png
                    └── ...
```
通过这种方式，源文件和编译后站点的相对目录结构保持了一致。在 `index.md` 中，无论是使用 `<img>` 标签还是标准 Markdown 语法，`figs/...` 都是一个正确的相对路径。这个方案不仅解决了问题，还让项目结构更加模块化和清晰，是本人更为推荐的长期实践。

#### 总结与反思

这次排查过程让我深刻理解了静态网站生成器的工作原理。它并非简单地复制文件，而是包含了一套完整的路径解析与重构逻辑。问题的关键在于，我们必须同时考虑源文件的编写环境和最终部署的浏览环境。掌握不同语法在编译过程中的细微差别，对于避免未来出现类似问题至关重要。