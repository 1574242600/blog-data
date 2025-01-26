---
title: '使用 FreshRSS 实现友人最近文章 API'
author: Nworm
slug: shiyong-freshrss
date: 2024-03-31 00:00:00
tags: 
    - FreshRSS
---
之前，在 LowEndTalk 看到 2 欧一年循环带邮箱的虚拟主机，觉得应该会有用，趁着优惠下单。结果就在上面挂了贴吧云签到就吃灰了。  
因为不甘心让这 2 欧元被浪费，打算用 PHP 实现 [Moments][Moments] 部分功能。

-  聚合RSS
-  API，在友人页面实现友人最近文章

然后遇到了 [FreshRSS][FreshRSS]
<!--more-->
--- 
>FreshRSS 是一个自托管的 RSS 订阅源聚合器。  
>
>它轻量级、易于操作、功能强大且可定制。
>
>这是一个支持匿名阅读模式的多用户应用程序。它支持自定义标签。为客户端提供了 API 接口，以及命令行界面。
>
>得益于 WebSub 标准，FreshRSS 能够从兼容的源，如 Friendica、WordPress、Blogger、Medium 等，接收即时推送通知。
>
>FreshRSS 原生支持基于 XPath 的基础网页抓取，用于那些未提供任何 RSS / Atom 订阅源的网站。也支持 JSON 文档。
>
>FreshRSS 提供了通过 HTML、RSS 和 OPML 重新分享文章选择的功能。
>
>支持不同的登录方法：网页表单（包括匿名选项）、HTTP 认证（兼容代理委派）、OpenID Connect。
>
>最后，FreshRSS 支持扩展，以便进一步调整。  
> by ChatGPT

## 需求一
很明显，FreshRSS 已经满足了需求一
## 需求二
FreshRSS 实现了 `Google Reader API`，可以使用支持该 API 的 RSS 阅读器方便地阅读文章，添加和分类 Feed ...... (此前， 使用 TG 机器人来订阅 RSS  

很可惜的是，在尝试了该 API 实现后发现无法满足需求，原因如下
- 文档较乱，需要参考源码
- 无法在单次请求里获取该需求需要的数据
- 响应内容不适合，对于该需求太臃肿
- 需要身份验证 （可以使用 CF Worker

同时也发现了 FreshRSS 不会处理和存储 RSS 的 `item.description`，也就是没有文章介绍，由于想摸鱼故放弃为其添加存储 `item.description` 的功能，放弃 `文章介绍`。  

FreshRSS 基于 PHP-FPM，API 实现都在 `/p/api` 目录，所以可以很方便地实现自己的 API。

[/p/api/friends.php][friends-api]

### 配置
请确保在 FreshRSS 管理页面启用 API 访问   
`Administration -> Authentication -> Allow API access`  
然后修改 friends.php
```php title='friends.php' showLineNumbers startLineNumber=22
$user = ''; //指定用户
$category = 'Friends'; //指定用户分类
```
跨域
```php title='friends.php' showLineNumbers startLineNumber=7
header("Access-Control-Allow-Origin: *"); // 建议修改为自己的域
```

### 文档
请求路径: `/api/friends.php`  
请求方法: `GET`  
请求参数: searchParams
- items: number 返回条目数
- offset: number 偏移

#### 响应格式
返回 JSON  
状态码: 200  
```ts
interface Res {
   list: {
        url: string       //文章 URL
        date: number      //文章发表时间戳
        title: string     //文章标题
        siteName: string  //RSS 名称
    }[],
    items: number
    offset: number
}
```

状态码: 非 200
```ts
interface ErrorRes {
   msg: string
}
```

#### 示例
`/api/friends.php?items=3&offset=0`
```json
{
  "list": [
    {
      "url": "https://dyedd.cn/1012.html",
      "date": 1711627860,
      "title": "解决：PytorchStreamWriter failed writing file data",
      "siteName": "染念Blog"
    },
    {
      "url": "https://xfox.fun/archives/1839/",
      "date": 1711561320,
      "title": "新装单路X99主机",
      "siteName": "未知狐的小窝"
    },
    {
      "url": "https://xfox.fun/archives/1836/",
      "date": 1711218600,
      "title": "脊柱侧弯",
      "siteName": "未知狐的小窝"
    }
  ],
  "items": 3,
  "offset": 0
}
```

#### 其它
该 API 只读  
如果需要通过 `Google Reader API` 添加 RSS 并移动到指定分组，请参考
FreshRSS 的文档和源码。嫌麻烦也可以直接参考该 [sh 脚本][sh-script]，但不保证这是最好的实现。
## 参考
[FreshRSS][FreshRSS] (文档和源码)  
[Moments][Moments]


[Moments]: https://github.com/Drizzle365/Moments
[FreshRSS]: https://github.com/FreshRSS/FreshRSS/
[friends-api]: https://github.com/1574242600/FreshRSS/blob/edge/p/api/friends.php
[sh-script]: https://github.com/1574242600/blog-data/blob/main/script/toFreshrss.sh
