---
title: '在 Astro 优化 md 文件里的远程图片'
author: Nworm
date: 2024-03-27 00:00:00
tags: 
    - Astro
---
相比于 Gatsby，Astro 原生支持优化图片，并且提供了 [`Image Service API`][image-service-api] 可以很方便地自定义，
需要优化时在 `.astro` 文件里可以使用内置的 `<Image />` 组件，支持优化本地图片和远程图片。  
但目前对于 `.md` 则只优化本地图片（看[源码][md-source]的意思，似乎以后也不会支持优化远程图片）。

这里提供了两种本质上一样的解决方法。
<!--more-->
-----
是的，只需要将远程图片变为本地图片就行了

## 方法 1
写一个 Remark 插件，在 Astro 构建时将图片下载到本地，然后替换图片链接到本地路径。  
由于没找到能直接用的插件，只能借鉴手搓一个了。  
[源码][remark-plugin] （不建议使用，已放弃维护   

使用方法
```js title="astro.config.mjs"
export default defineConfig({
    markdown: {
        remarkPlugins: [
            [
                copyImageToLocal,
                {
                    domains: ['nworm.icu'],      //要授权的域，只有授权的域下的图片会被下载到本地
                    toPath: './src/posts/image', //存放图片的目录路径，相对于项目根目录
                    mdPath: './image'            //用来替换掉 .md 文件里的图片链接的目录路径，相对于 .md 文件所在的目录
                }
            ]
        ],
    }
})
```
## 方法 2
写一个脚本，在 Astro 构建之前将图片下载到本地并替换掉 `.md` 里的链接  
这里提供一个 bash 的[实现][bash-copyImageToLocal] 
```shell
./copyImageToLocal $MD_filepath
```
该脚本会在 `.md` 文件所在目录下新建 `image/`，所有远程图片都会被下载到该目录，并将图片链接替换成 `./image/{filename}`。  
如果图片下载失败则不会替换。远程图片下载后文件名为 `{MD文件名}.{图片标题}.{图片链接的hash}`，然后会使用 `file` 确定类型并添加后缀名。


[image-service-api]: https://docs.astro.build/en/reference/image-service-reference/
[md-source]: https://github.com/withastro/astro/blob/1cd2a740221ee14267f2889c4eb200bbcecb08aa/packages/markdown/remark/src/remark-collect-images.ts#L28-L31
[remark-plugin]: https://github.com/1574242600/blog-astro/blob/bc66b12caf751ab54b3e4319bc6884713b2d6d15/src/plugin/remark.mjs#L16-L100
[bash-copyImageToLocal]: https://github.com/1574242600/blog-data/blob/main/script/copyImageToLocal.sh