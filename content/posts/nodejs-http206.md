---
title: '[nodejs]koa框架 206 Partial Content'
author: Nworm
date: 2020-04-10 12:40:00
tags: 
    - js
---

c，为什么koa它不直接支持206  

<!--more-->
## 206 Partial Content 是个什么玩意？

> HTTP 206 Partial Content 成功状态响应代码表示请求已成功，并且主体包含所请求的数据区间，该数据区间是在请求的 Range 首部指定的。
> 
> 如果只包含一个数据区间，那么整个响应的 Content-Type 首部的值为所请求的文件的类型，同时包含  Content-Range 首部。
>
> 如果包含多个数据区间，那么整个响应的  Content-Type  首部的值为 multipart/byteranges ，其中一个片段对应一个数据区间，并提供  Content-> Range 和 Content-Type  描述信息。
>  
>  https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Status/206

简单来说，就是获取服务端上，一个文件的部分内容，HTTP断点续传就是依赖的这玩意  
注：本文并未实现  206 Partial Content的全部功能

## 头示例
```
GET /localVideo/?token=14c422b3623a69dbc831c4469794e7a2 HTTP/1.1
Host: 127.0.0.1:3000
User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:75.0) Gecko/20100101 Firefox/75.0
Accept: video/webm,video/ogg,video/*;q=0.9,application/ogg;q=0.7,audio/*;q=0.6,*/*;q=0.5
Range: bytes=0-
Connection: keep-alive

```
### Range: 字节数（bytes）=(开始)-(结束)  

这是浏览器告知服务器所需分部分内容范围的消息头。 注意开始和结束位置是都包括在内的，这个头也只发送一个位置，其含义如下:  
- 如果只发送开始位置，服务器会返回从声明的开始位置到服务器设置的数据区间长度+开始位置的数据  
- 如果只发送结束位置，结束位置参数可以被描述成从最后一个可用的字节算起可以被服务器返回的字节数  

```
HTTP/1.1 206 Partial Content
Content-Type: video/mp4
Content-Range: bytes 0-3145729/24332262
Accept-Ranges: bytes
Content-Length: 3145729
Connection: keep-alive
```
### Content-Range：字节数（bytes）=(开始)-(结束)/(总长度)

服务器返回当前数据区间开始结束位置，文件总长度

### Accept-Ranges: 字节（bytes）

声明数据存储单位 ，然而只能用bytes这一个单位

### Content-Length: 3145729

此次数据长度

## koa 实现部分功能

```js
/**
 * 206 Partial Content
 * @name http206
 * @param ctx  object Koa Context
 * @param path  string 文件路径
 * @return steam
 */
const http206 = async (ctx,path) => {
    let Range = ctx.request.get('Range');
    let file = fs.statSync(path);
    let fileSize = file.size;

    let parts = Range.replace(/bytes=/, "").split("-");
    let start = parts[0] ? Number(parts[0]) : 0;
    //当请求字段Range结束位置为0时，这里长度为3mb,请根据需要调整
    let end = parts[1] ? Number(parts[1]) : start + 1024 * 1024 * 3;  
    end = end > fileSize - 1 ? fileSize - 1 : end;           //当结束位置大于文件长度-1时，结束位置 = 文件长度 - 1
    let chunksize = (end - start) + 1;

    let headers = {
        'Content-Range': `bytes ${start}-${end}/${fileSize}`,
        'Accept-Ranges': 'bytes',
        'Content-Length': chunksize,
        'Content-Type':  mime类型,
    };

    //console.log(headers);
    ctx.response.status = 206;
    ctx.set(headers);
    //请根据需要处理异常
    return fs.createReadStream(path,{start,end})
};
```

![](https://nworm.icu/pan/图片/http206.png)
