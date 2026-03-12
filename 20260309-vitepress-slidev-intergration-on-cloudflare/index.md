# Cloudflare Pages 部署 VitePress + Slidev：单 Pages 方案

`VitePress` 和 `Slidev` 这对组合，用来做课程站、文档站或者社团知识库，体验其实很好。`VitePress` 负责目录、导航和正文，`Slidev` 负责演示文稿，两边各做各的，本地开发时再嵌到一起，基本就能把“文档 + 课件”这一类站点搭起来。

问题往往不是出在本地，而是出在部署。

我这边的项目在开发阶段是同时起多个服务的：`vitepress dev docs` 跑在 `5173`，几套 Slidev 分别跑在 `3030` 到 `3034`。这种方式非常适合改内容，因为你保存一份文档或者一套课件，浏览器立刻就能看到效果。可一旦准备把整站扔到 Cloudflare Pages，上面这套思路就不能直接照搬了。原因很简单，Cloudflare Pages 是静态托管，不是给你长期托管多个开发进程的地方。本地那些端口，在部署后根本不存在。

这篇文章想讲清楚的就是这一点：`VitePress + Slidev` 在本地可以是多服务协作，在 Cloudflare 上则更适合收敛成一个静态产物。围绕这个目标，理论上有不止一种办法，但就我这个项目的约束来说，最后最稳妥的选择是 `单 Pages，合并产物`。

## 先说结论

本地开发时，项目会并行启动一套 VitePress 开发服务和多套 Slidev 开发服务，端口大致长这样：

```text
http://localhost:3030
http://localhost:3031
http://localhost:3032
...
```

这样做的好处是明显的：每套课件都可以单独热更新，`VitePress` 也有自己的热更新，不需要频繁 build，开发反馈很快。

但到了 Cloudflare Pages，情况就完全不同了。Pages 只认“构建命令 + 输出目录”，不会替你常驻运行五个 Slidev dev server，再额外运行一个 VitePress dev server。也就是说，线上如果还依赖 `localhost:303x` 这类地址，文档页能打开，课件区照样会白屏。

真正应该切换的不是某个命令，而是部署模型：开发阶段追求的是并行编辑，生产阶段追求的是确定的、可复现的、一次构建就能交付的静态结果。

## 三种方案

把这个问题摊开看，常见方案大致有三类。

第一类是拆开部署。VitePress 放一个 Pages 项目，每套 Slidev 再拆成单独的 Pages，或者挂在不同子域名下，然后文档页再去链接或者嵌入这些课件。这种做法理论上最“解耦”，每一套内容都能单独发布，但它带来的维护成本也最高。你会很快遇到几个现实问题：站点数量增加、部署配置重复、跨域和缓存排查变复杂、文档和课件版本不容易同步。对于大型团队也许可接受，但对一个以内容组织为主的站点来说，投入和收益并不匹配。

第二类是引入 Worker，在边缘层做路由分发和路径改写。这个方案可以把分散的静态资源拼接成一个统一入口，灵活度确实高，也能做一些更细的控制。但问题同样明显：系统复杂度会立刻上一个台阶。原本一个纯静态站点的问题，会被改造成“静态资源 + 边缘路由”的平台问题。除非你本来就需要 Worker 参与权限、鉴权或者动态拼接，否则这种方案很容易变成过度设计。

第三类就是我最终采用的方案：只保留一个 Cloudflare Pages 项目，在构建阶段先分别产出 VitePress 和所有 Slidev 的静态文件，再把它们合并到同一个目录，比如 `.cloudflare-dist`，最终只把这个目录交给 Pages 发布。对这类“文档站 + 若干课件”的项目来说，这种方式最接近 Cloudflare Pages 的运行方式，也最容易长期维护。

## 为什么选单 Pages

我这里的项目并不是一个纯文档站，而是一个带课件库的知识站。仓库里既有 `docs/`，也有 `slides/`。`docs/` 是 VitePress 的文档源，`slides/` 是真正的 Slidev 源文件。为了方便说明，后文统一用一套名为 `intro` 的示例课件来表示这类独立 deck。

这类项目有几个很明显的特征。

第一，文档和课件本来就是一个整体。用户访问的是同一个站点，只不过有的页面是正文，有的页面里嵌了 PPT。如果把它们拆成多个站点，部署上看似清晰，用户体验上反而会出现割裂感。

第二，站点内容几乎全是静态的。没有必须依赖服务端渲染的业务逻辑，也没有需要 Worker 即时拼装的内容。既然运行时没有动态需求，那就应该尽量把复杂度前移到 build 阶段，而不是在生产链路里再加一层路由系统。

第三，这个项目的核心诉求不是“课件单独扩缩容”，而是“整站稳定、路径统一、上线简单”。单 Pages 合并产物刚好满足这三个要求：构建命令只有一个，输出目录只有一个，回滚也只需要回滚一份静态站点。

还有一个很实际的原因是嵌入路径会变得非常干净。文档页只需要统一指向 `/decks/<name>/`，不再关心某套课件到底部署在第几个子站点、哪个域名、哪个端口。开发和生产的差异被约束在构建脚本里，而不是散落在每一篇文档页面里。

## 怎么落地

思路并不复杂，可以概括成一句话：开发时并行运行，部署时统一收口。

本地开发阶段，`package.json` 里保留并行脚本。下面是一个最小化示例，重点不是脚本名本身，而是“文档服务 + 多个 Slidev 服务并行启动”这个模式：

```json
{
  "scripts": {
    "dev": "concurrently \"npm run docs:dev\" \"npm run slides:intro\" \"npm run slides:topic-a\"",
    "docs:dev": "vitepress dev docs",
    "slides:intro": "slidev slides/intro.md --port 3030",
    "slides:topic-a": "slidev slides/topic-a.md --port 3031"
  }
}
```

这部分不用改，因为它解决的是开发效率问题。真正和 Cloudflare 相关的是另一组脚本，也就是生产构建脚本：

```json
{
  "scripts": {
    "cf:build:clean": "rm -rf .cloudflare-dist slides/.cloudflare-dist",
    "cf:build:docs": "npm run docs:build && mkdir -p .cloudflare-dist && cp -a docs/.vitepress/dist/. .cloudflare-dist/",
    "cf:build:slide:intro": "slidev build slides/intro.md --base /decks/intro/ --out ../.cloudflare-dist/decks/intro --download false",
    "cf:build:slide:topic-a": "slidev build slides/topic-a.md --base /decks/topic-a/ --out ../.cloudflare-dist/decks/topic-a --download false",
    "cf:build:slides": "npm run cf:build:slide:intro && npm run cf:build:slide:topic-a",
    "cf:build": "npm run cf:build:clean && npm run cf:build:docs && npm run cf:build:slides"
  }
}
```

这里的核心动作只有两个。先把 `VitePress` build 到 `.cloudflare-dist`，再把每套 `Slidev` 分别 build 到 `.cloudflare-dist/decks/<name>/`。真实项目里你可能有 2 套、5 套甚至更多课件，但模式都是一样的。构建结束后，整个站点就只剩下一个交付目录，Cloudflare Pages 只需要执行：

```text
Build command: npm run cf:build
Build output directory: .cloudflare-dist
```

这就是“单 Pages，合并产物”的本质。

## `base` 和 `out`

真正开始做的时候，最容易踩坑的地方其实不是 Cloudflare，而是 `Slidev` 的构建路径。

先看 `--base`。既然最终每套课件都要挂在 `/decks/<name>/` 下，那 build 时就必须显式告诉 `Slidev`，它的资源路径应该以这个前缀为根。否则等课件被放到子目录里之后，页面里的脚本、样式、资源引用就会全乱掉。

再看 `--out`。如果你的 Slidev 入口文件都放在 `slides/` 目录下面，那么 `slidev build --out` 的相对路径通常也是从 `slides/` 视角解析的。也正因为如此，输出到仓库根目录下的 `.cloudflare-dist` 时，路径往往要写成 `../.cloudflare-dist/...`，而不是看上去更“自然”的 `./.cloudflare-dist/...`。这不是风格问题，是构建结果会不会落到正确目录的问题。

这一步如果没想清楚，后面就会出现一种很烦人的情况：构建命令没有报错，但产物被扔到了你没注意到的目录里，Cloudflare Pages 发布时当然也找不到那套 deck。

## 路由组织

产物合并之后，路由最好也保持一眼能看懂。

我这里的约定是把两类页面明确分开：

- VitePress 文档页继续走它自己的静态 `.html`
- Slidev 课件统一挂到 `/decks/<name>/`

文档里对应的嵌入页面放在 `docs/slides/*.md`，例如：

```md
<SlideEmbed src="/decks/topic-a/" title="示例课件" :height="600" />
```

这样有两个好处。第一，导航和内容说明仍然交给 VitePress 管；第二，真正播放 PPT 的责任完全留给 Slidev 的静态产物。文档页负责入口，课件页负责展示，职责很清楚。

不过 `Slidev` 的产物本质上还是单页应用，所以部署到静态托管后要考虑刷新子路由的问题。为此，可以在 `docs/public/_redirects` 里给每套 deck 加上 SPA fallback。下面仍然是泛化后的示例：

```text
# Slidev SPA fallback
/decks/intro/* /decks/intro/index.html 200
/decks/topic-a/* /decks/topic-a/index.html 200
/decks/topic-b/* /decks/topic-b/index.html 200
```

这几条规则的作用很直接：用户访问 deck 内部路径时，Cloudflare Pages 仍然回到对应 deck 的 `index.html`。如果不加这层回退，PPT 里一旦用了内部路由或者用户直接刷新，马上就是 404。

这里还有一个很值得强调的点：不要顺手写一个全局 `/* /index.html 200`。VitePress 文档页本来就会生成明确的静态文件，`assets`、`sitemap.xml` 这类资源也需要原样命中。为了给 deck 做 SPA 回退，把整个站点都改成“通配重写”，属于典型的图省事但后患无穷。

## 嵌入组件

参考实现里最有用的一部分，其实不是构建脚本，而是 `SlideEmbed` 这个组件。

如果每一篇 `docs/slides/*.md` 都手写一段原始 `iframe`，短期看很快，长期会非常难维护。你一旦想加加载态、超时提示、重试按钮、统一高度或者新窗口打开，所有页面都要重新改一遍。更糟的是，不同页面里很容易留下不一致的属性，最后控制台一堆警告，你还不一定记得是从哪篇文档里冒出来的。

这个项目最终把嵌入逻辑收到了 `docs/.vitepress/theme/components/SlideEmbed.vue`，核心实现大致如下：

```vue
<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'

const props = withDefaults(
  defineProps<{
    src: string
    title: string
    height?: number | string
    timeoutMs?: number
  }>(),
  {
    height: 600,
    timeoutMs: 12000
  }
)

const isLoading = ref(true)
const isTimedOut = ref(false)
const iframeKey = ref(0)

let timeoutHandle: ReturnType<typeof setTimeout> | null = null

const normalizedHeight = computed(() =>
  typeof props.height === 'number' ? `${props.height}px` : props.height
)

function clearTimer() {
  if (timeoutHandle) {
    clearTimeout(timeoutHandle)
    timeoutHandle = null
  }
}

function startLoadingTimer() {
  clearTimer()
  isLoading.value = true
  isTimedOut.value = false
  timeoutHandle = setTimeout(() => {
    isLoading.value = false
    isTimedOut.value = true
  }, props.timeoutMs)
}

function handleLoaded() {
  clearTimer()
  isLoading.value = false
  isTimedOut.value = false
}

function retryLoad() {
  iframeKey.value += 1
  startLoadingTimer()
}

watch(
  () => props.src,
  () => {
    iframeKey.value += 1
    startLoadingTimer()
  }
)

onMounted(() => {
  startLoadingTimer()
})

onBeforeUnmount(() => {
  clearTimer()
})
</script>

<template>
  <section class="slide-embed" :style="{ '--slide-embed-height': normalizedHeight }">
    <div class="slide-embed__shell">
      <iframe
        :key="iframeKey"
        class="slide-embed__frame"
        :src="src"
        :title="title"
        loading="lazy"
        allow="fullscreen"
        frameborder="0"
        scrolling="no"
        @load="handleLoaded"
      />
    </div>
  </section>
</template>
```

这段代码干的事情并不复杂，但非常实用。它把“嵌入 Slidev”这件事从一段 HTML，变成了一个有状态的组件：加载时显示骨架屏，超时后给重试入口，`src` 变化时自动刷新 iframe，而且只保留 `allow="fullscreen"`，不再额外写 `allowfullscreen`。后面这一点看起来小，实际上能直接消掉浏览器里那条烦人的 `Allow attribute will take precedence over 'allowfullscreen'` 警告。

## 生产优化

做到“能打开”其实不难，难的是让它在 Cloudflare 上跑得稳定，不出现一堆边缘问题。

这个项目里，比较关键的优化主要有四个。

第一个是去掉对 Google Fonts 的在线依赖。`Slidev` 默认可能会拉远程字体，在本地网络好的时候你不一定感觉得到，到了 Cloudflare 或某些网络环境下，就会频繁看到 `fonts.googleapis.com` 超时。解决办法也很直接：在 deck frontmatter 里把 `fonts.provider` 设为 `none`，改用系统字体栈，把字体依赖从运行时挪掉。

第二个是避免构建阶段走 PDF 下载相关流程。生产构建里我显式写了 `--download false`，目的就是不让 `Slidev` 在 build 时引入额外导出动作。否则一旦某套 deck 开启了下载或导出，你很可能在 CI 或 Cloudflare 环境里碰到 Playwright 浏览器缺失之类的问题，排查成本完全不值。

第三个是给静态资源加明确的缓存策略。项目里在 `docs/public/_headers` 里做了区分：

```text
/assets/*
  Cache-Control: public, max-age=31536000, immutable

/decks/*/assets/*
  Cache-Control: public, max-age=31536000, immutable

/decks/*
  X-Robots-Tag: noindex, nofollow
  Cache-Control: public, max-age=600
```

思路很清楚：真正带 hash 的静态资源长缓存，deck 页面本身保守一点缓存，同时不把课件播放页当成搜索引擎要重点索引的落地页。这样既不浪费缓存，也不会让搜索结果里冒出一堆只适合课堂展示的子页面。

第四个是统一线上路径。文档里所有嵌入都写 `/decks/<name>/`，而不是在不同页面里塞不同域名、不同环境变量或者本地端口。线上路径一旦统一，后续无论是换 CDN、清缓存还是做排障，成本都会低很多。

## 适用边界

如果你的项目和我这个案例差不多，满足下面这些条件，那单 Pages 合并产物基本就是优先选项：一是内容主要是静态文档和静态课件；二是文档与课件本来就属于同一个站点；三是你更在意部署简单、路径统一和回滚容易，而不是把每套课件拆成独立应用运营。

反过来说，如果你的课件量特别大、发布频率差异很大，或者课件本身已经是独立业务，需要单独权限、单独域名、单独统计，那拆分部署或者引入 Worker 也不是不能做。只是那已经不是“如何把 VitePress 和 Slidev 一起部署到 Cloudflare”这个问题了，而是“如何设计一个多应用内容平台”的问题。那时你要权衡的就不只是部署便利性，而是组织边界和运维复杂度。

## 收尾

`VitePress + Slidev` 真正难的地方，不是怎么让它在本地一起跑，而是怎么让它在线上仍然保持简单。

本地开发可以继续保留多服务并行，因为那是为了效率；Cloudflare Pages 上则应该接受它是一个静态托管平台的事实，把所有课件和文档在构建阶段合并成一个产物目录，再通过明确的路由和少量页面组件把它们组织起来。这样做不炫技，也不复杂，但它和平台的运行方式是对齐的。

至少对我这个项目来说，最后证明这是最省心的一条路：一个仓库，一套构建，一个 Pages 项目，文档能看，PPT 能播，出问题时也知道该从哪一层查起。
