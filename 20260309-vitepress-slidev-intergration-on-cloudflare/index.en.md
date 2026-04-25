---
title: Deploying VitePress + Slidev on Cloudflare Pages
pubDatetime: 2026-03-09T00:00:00.000+08:00
slug: vitepress-slidev-intergration-on-cloudflare-en
tags:
  - Cloudflare Pages
  - VitePress
  - Slidev
  - Static Deployment
  - Vite
category: 
  - 配置环境的日常
  - 踩坑日志
description: VitePress and Slidev deployment guide for Cloudflare Pages, explaining how to move from local multi-service development to one merged static output, configure build scripts, Slidev base/out paths, route layout, SPA fallbacks, an embed component, and production optimizations. Suitable for docs and course sites.
---

`VitePress` and `Slidev` make a very nice pair for documentation sites, course websites, and knowledge bases. `VitePress` handles navigation, structure, and prose. `Slidev` handles the presentation layer. Put them together, and you get a site that can serve both as a reading space and a slide library.

The tricky part is not local development. The tricky part is deployment.

In my setup, local development runs several services at once: `vitepress dev docs` on `5173`, and multiple Slidev decks on ports like `3030` to `3034`. That works well because it optimizes for editing speed. You save a doc or a slide deck, refresh, and keep moving.

Once you want to deploy the whole thing to Cloudflare Pages, though, that model stops being useful. Cloudflare Pages is static hosting. It is not a place where your local development servers keep running somewhere in the background. Those local ports are part of the development workflow, not part of the deployed system.

That is the core point of this article: `VitePress + Slidev` can absolutely work as a multi-service setup during development, but on Cloudflare Pages it is better to converge everything into one static output. There are several ways to do that in theory. For this kind of project, the one that made the most sense was a `single Pages project with merged build output`.

## The short version

During local development, it is completely normal to run one VitePress dev server and several Slidev dev servers side by side. The ports typically look something like this:

```text
http://localhost:3030
http://localhost:3031
http://localhost:3032
...
```

That is convenient because each deck can hot-reload independently, and the docs site can do the same. No full build required, no extra ceremony.

Cloudflare Pages is a different environment. It only cares about two things: a build command and an output directory. It does not keep five Slidev dev servers alive for you, plus a VitePress dev server for good measure. If your deployed pages still depend on `localhost:303x`, the docs page may render, but the slide area will be dead.

So the real shift is not from one command to another. It is a shift in deployment model. Development optimizes for iteration speed. Production optimizes for determinism: one build, one output, one thing to deploy.

## Three options

For a project like this, the common deployment choices are roughly these three.

The first option is to split everything apart. One Pages project for VitePress, then separate Pages projects for each Slidev deck, perhaps under different subdomains. In theory this is the most decoupled model. In practice, it also creates the most operational overhead. You end up with more sites, more repeated configuration, more routing and caching issues, and a higher chance that docs and slides drift out of sync. That may be acceptable for a large team. For a content-heavy site run as one product, it is usually not worth it.

The second option is to introduce a Worker and let the edge layer rewrite or dispatch routes for you. This buys flexibility, but it also raises the system complexity immediately. A straightforward static site problem becomes a static-site-plus-edge-routing problem. Unless you already need Workers for auth, access control, or some form of dynamic composition, this tends to be overengineering.

The third option is the one I ended up using: keep a single Cloudflare Pages project, build VitePress and all Slidev decks as static assets, merge them into one directory such as `.cloudflare-dist`, and publish only that directory. For a docs site with a collection of decks, this matches how Cloudflare Pages actually works and stays much easier to maintain over time.

## Why I picked a single Pages project

This is not a plain documentation site. It is a documentation site with a slide library attached to it. The repository contains both `docs/` and `slides/`. `docs/` is the VitePress source tree, and `slides/` contains the actual Slidev source files. To keep the explanation concrete, I will use one sample deck named `intro` in the examples below.

That kind of project has a few important characteristics.

First, the docs and the decks are part of one user experience. Visitors are not thinking in terms of separate applications. They are browsing one site where some pages are articles and some pages embed slides. Splitting them into different deployments makes the infrastructure look cleaner while making the user experience feel more fragmented.

Second, the content is almost entirely static. There is no strong runtime need for server-side rendering, and no real reason to push route composition into Workers. If the runtime can stay simple, it is usually better to move the work into the build phase instead.

Third, the main goal here is not independent scaling per deck. The goal is a stable site, predictable paths, and a release process that stays simple. A single Pages project with merged output does exactly that: one build command, one output directory, one deploy target, one rollback story.

There is also a more practical benefit: embedded paths become clean and uniform. Every docs page can point to `/decks/<name>/` and stop caring about which subdomain, service, or port a specific deck belongs to. The environment-specific complexity stays in the build scripts instead of leaking into every content page.

## How it works

The deployment model is simple: keep development parallel, and make production converge.

During development, `package.json` can keep a parallel setup. A minimal example looks like this:

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

Those scripts are about editing speed, so there is no need to force them into a production shape.

What matters for Cloudflare Pages is the production build layer:

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

Only two things happen here. First, build `VitePress` into `.cloudflare-dist`. Second, build each Slidev deck into `.cloudflare-dist/decks/<name>/`. Whether your real project has two decks or twenty does not change the pattern.

Once that finishes, Cloudflare Pages only needs:

```text
Build command: npm run cf:build
Build output directory: .cloudflare-dist
```

That is the whole single-Pages idea in one sentence.

## `base` and `out`

The easiest place to trip is not Cloudflare itself. It is the Slidev build paths.

Start with `--base`. If a deck is going to live under `/decks/<name>/`, then Slidev needs to know that during the build. Otherwise its asset references will be generated as if the deck lived somewhere else, and things break as soon as you serve the result from a subdirectory.

Then there is `--out`. If your Slidev entry files live under `slides/`, the output path is often resolved relative to that directory. In that case, writing into a root-level folder like `.cloudflare-dist` usually means using `../.cloudflare-dist/...` rather than the more tempting `./.cloudflare-dist/...`. This is not a stylistic preference. It determines whether the built files end up where you think they do.

If that detail is wrong, the build may still succeed, which makes the mistake annoying. You only notice it later when Cloudflare Pages cannot find the deck where you thought it would be.

## Route layout

Once the build outputs are merged, the route layout should stay boring and obvious.

The basic convention is:

- VitePress documentation pages keep their own static `.html` outputs
- Slidev decks live under `/decks/<name>/`

The embedding pages can live under `docs/slides/*.md`, for example:

```md
<SlideEmbed src="/decks/topic-a/" title="Sample deck" :height="600" />
```

That split keeps responsibilities clear. VitePress owns navigation and surrounding context. Slidev owns the actual presentation experience.

Since Slidev output is still a single-page application, you also need to think about refresh behavior for nested deck routes. A simple `_redirects` file works well for that:

```text
# Slidev SPA fallback
/decks/intro/* /decks/intro/index.html 200
/decks/topic-a/* /decks/topic-a/index.html 200
/decks/topic-b/* /decks/topic-b/index.html 200
```

These rules make sure requests to internal deck routes still fall back to the correct `index.html`. Without them, refresh one of those routes and you get a 404.

One important warning here: do not casually add a global rule like `/* /index.html 200`. VitePress already generates explicit static files, and assets such as `assets/` or `sitemap.xml` should still be served directly. A blanket SPA fallback solves one problem by creating several others.

## Why I used an embed component

One of the most useful pieces in this setup is not the build script. It is the `SlideEmbed` component.

If every `docs/slides/*.md` page contains a handwritten `iframe`, it feels quick at first and becomes annoying later. The moment you want a loading state, a timeout state, a retry button, a consistent height, or a clean “open in new tab” path, you have to touch every page. It also becomes very easy to leave slightly different attributes all over the site and forget where a given browser warning is coming from.

Wrapping that behavior in `docs/.vitepress/theme/components/SlideEmbed.vue` solves the problem once:

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

The implementation is not fancy, but it is practical. It turns “embed a Slidev deck” from a raw `iframe` into a small stateful component with a loading state, a timeout path, a retry mechanism, and consistent fullscreen behavior. Just as importantly, it keeps only `allow="fullscreen"` and drops `allowfullscreen`, which removes that familiar browser warning about the `allow` attribute taking precedence.

## Production-side optimizations

Getting the site to load is one thing. Getting it to behave cleanly on Cloudflare is another.

The first useful optimization is removing runtime dependency on Google Fonts. Slidev may try to fetch remote fonts by default. On a good network you may barely notice. On a bad one, or in some regions, you suddenly start seeing `fonts.googleapis.com` timeouts everywhere. Setting `fonts.provider: none` and using local or system fonts fixes that at the root.

The second optimization is avoiding unnecessary export behavior during production builds. In the scripts above, `--download false` is there on purpose. If deck export or download features stay enabled, CI or Cloudflare builds can end up pulling in extra Playwright requirements for no real benefit.

The third optimization is cache control. Static assets should be cached aggressively, while deck pages themselves can use a shorter cache window. A setup like this is enough:

```text
/assets/*
  Cache-Control: public, max-age=31536000, immutable

/decks/*/assets/*
  Cache-Control: public, max-age=31536000, immutable

/decks/*
  X-Robots-Tag: noindex, nofollow
  Cache-Control: public, max-age=600
```

The idea is straightforward: hashed assets get long caching, while deck pages stay more conservative. The `X-Robots-Tag` also keeps presentation pages from being treated as primary landing pages by search engines.

The fourth optimization is path consistency. If every embedded deck uses `/decks/<name>/`, you stop leaking local ports, temporary hosts, or environment-specific URLs into your content. That makes future debugging much less annoying.

## When this approach fits

This approach is a good default when your site is mostly static, when docs and slides belong to the same product, and when you care more about a clean deployment pipeline than about operating each deck as a separate application.

It is not automatically the right answer for every setup. If decks are effectively independent products, need separate access control, have very different release cadences, or already live under separate domains, splitting them out may make sense. At that point, however, you are no longer solving a simple “deploy VitePress + Slidev to Cloudflare Pages” problem. You are designing a multi-application platform.

## Closing thought

The hardest part of `VitePress + Slidev` is not making them run together locally. That part is easy enough. The harder part is keeping the deployed version simple.

For Cloudflare Pages, the cleanest answer is usually to accept the platform for what it is: a static hosting target. Build the docs, build the decks, merge the outputs, define the routes clearly, and keep the runtime boring. It is not flashy, but it is reliable, and in this case reliability is exactly what you want.
