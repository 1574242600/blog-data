---
title: '准备迁移到 Astro (完成)'
author: Nworm
slug: qianmyi-2023
date: 2023-11-19 22:00:00
update: 2024-02-12 00:00:00
tags: 
    - 记录
---

又重写了一遍博客主题，写着写着发现了 Astro，觉得应该比 Gatsby 更好用。  
于是，决定把这个半成品主题迁移到 Astro。

-----
摸了几个月鱼，终于迁移到至少能用的程度了，不知道又会冒出来多少 bug。  
体验下来，对这个项目而言 Astro 确实比 Gatsby 好用，其它的项目没经验不敢断言。  
<!--more-->

在获取数据方面，Astro 在 `.astro` 文件里非常直观方便

```astro
---
//这段代码会在服务端执行
const text1 = await fetch('https://api.xxx.xxx')
const text2 = await readFile('1.txt')
//...
---
<div>{text}</div>
<div>{text2}</div>
<!-- ... --->
```
而在 Gatsby, 要么你使用插件，将数据带到 `GraphQL` 数据层，使用时编写语句查询，要么在 `gatsby-node.js` 里创建页面使用 `context` 
参数。  

对 md 文件的处理， Astro 比 Gatsby 方便得多。Astro 原生使用 `remark`, Gatsby 通过插件 `gatsby-transformer-remark`,
这没有什么问题，问题是 Gatsby 不能直接使用 `remark` 的插件，你需要包装成插件 `gatsby-transformer-remark` 的插件
`gatsby-remark-*`。
另外 Astro 将 md 转换为 `HTML` 后还会经过 `rehype`，支持直接使用 `rehype` 的插件，Gatsby 也有相关插件，
但已经很久都没有更新。  ~(你可以再为 Gatsby 造一个轮子，实现这些功能)~  

...todo 

----
更新日志
- React 组件重写至 solid 或 astro
- 现在使用 Turbo 实现单页
- 优化移动端侧边栏滑动
- 新增 tag 页面
- 更换 官方 Disqus 到 DisqusJS
- 修复了一些 bug

todo
- 使用 php 实现 [Moments](https://github.com/Drizzle365/Moments) 部分功能 (主要是 2 欧元买了一年的虚拟主机，好像没地方用)
    - api，在友人界面实现友人动态
    - 聚合rss
