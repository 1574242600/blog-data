---
title: 'Nginx webdav 在 Dolphin 上的一些坑'
author: Nworm
date: 2021-5-22 23:50:00
tags: 
    - Webdav
    - Nginx
    - Dolphin
    - 踩坑
---

ps: 要不是webdav可以用cdn，我会用它？

## 环境
### 服务器
- OS: ubuntu 21.04 x64
- Docker: v19.03.13, build cd8016b6bc
  - ugeek/webdav:amd64-alpine (ed65583ea58e)
    - nginx: v1.19.7

### 客户端
- OS: Archlinux
- Dolphin: v21.04.0
<!--more-->
## 坑
### 无法上传大文件(状态码: 413)
webdav 镜像本身没有这个问题，client_max_body_size 在主机配置文件中值为0。 

我在另一台服务器使用 nginx 反代 webdav，但反代配置文件的 client_max_body_size 为 10M 导致无法上传大文件

#### 原因
client_max_body_size 值过小
> Syntax: 	client_max_body_size size;  
> Default: 	client_max_body_size 1m;  
> Context: 	http, server, location  
>
> 设置客户端请求正文的最大允许大小。如果请求中的大小超过配置值，则向客户端返回413(请求实体过大)错误。请注意浏览器无法正确显示此错误。将配置值设置为0将禁用对客户端请求正文大小的检查。

#### 解决方法
请检查 webdav 主机配置文件的 client_max_body_size，并设置适当的值

### 无法创建文件夹(状态码: 409)
#### 原因
创建文件夹时，Dolphin 发送的 MKCOL 请求，路径未以 "/" 结尾。nginx 对于这种行为直接返回 ”409 Conflict“

[ngx_http_dav_module.c (504-508)][dav_module-L504]
 ```c
 if (r->uri.data[r->uri.len - 1] != '/') {
    ngx_log_error(NGX_LOG_ERR, r->connection->log, 0,
                "MKCOL can create a collection only");
    return NGX_HTTP_CONFLICT;
 }
``` 

至于请求路径是否该以 "/" 结尾，[rfc2518][rfc2518] 中好像没有规定，不过在[示例][rfc-MKCOL示例]里路径以 "/" 结尾。  

#### 解决方法
方法1: 配置文件  
使用 rewrite 重写路径  

```nginx
if ($request_method = MKCOL) { 
    rewrite ^(.*[^/])$ $1/ break; 
}
```
方法2: 删除相关代码，重新编译  
删除 ngx_http_dav_module.c 中相关的代码，重新编译。

### 无法删除文件夹(状态码: 409)
#### 原因
删除文件夹时，Dolphin 发送的 DELETE 请求，目录的路径未以 "/" 结尾。  
nginx 会先判断是否为文件夹，如果是，就再判断路径是否以 "/" 结尾。不以"/"结尾返回 ”409 Conflict“

[ngx_http_dav_module.c (357-364)][dav_module-L357]
```c
if (ngx_is_dir(&fi)) {

    if (r->uri.data[r->uri.len - 1] != '/') {
        ngx_log_error(NGX_LOG_ERR,r->connection->log, NGX_EISDIR,
                        "DELETE \"%s\" failed", path.data);
        return NGX_HTTP_CONFLICT;
    }

......
```

#### 解决方法
方法1: 配置文件  
使用 rewrite 重写路径  
```nginx
if (-d $request_filename) { 
    rewrite ^(.*[^/])$ $1/ break; 
}
```
方法2: 删除相关代码，重新编译  
删除 ngx_http_dav_module.c 中相关的代码，重新编译。

### 无法复制/移动文件夹(状态码: 409)
#### 原因
没错，还tm是"/"的问题。。。  

复制/移动文件夹时发送的 COPY/MOVE 请求，目录的路径和 Destination 头未以"/"结尾。Nginx 返回 409  
 
ps: 复制文件夹的话 Dolphin 问题不大，因为它不会直接发送复制文件夹的请求。它会先创建文件夹，再复制文件。

[ngx_http_dav_module.c (637-646)][dav_module-L637]
```c
if ((r->uri.data[r->uri.len - 1] == '/' && *(last - 1) != '/')
    || (r->uri.data[r->uri.len - 1] != '/' && *(last - 1) == '/'))
{
    ngx_log_error(NGX_LOG_ERR, r->connection->log, 0,
                    "both URI \"%V\" and \"Destination\" URI \"%V\" "
                    "should be either collections or non-collections",
                    &r->uri, &dest->value);
    return NGX_HTTP_CONFLICT;
}

......
```
#### 解决方法
适用于 Dolphin 或类似机制的客户端无法复制文件夹的解决方法同 [无法创建文件夹](#)

通用:  
方法1: 配置文件  
使用 rewrite 和 more_set_input_headers(需要 headers-more-nginx-module) 重写路径和 Destination 头

```nginx
set $is_copy_or_move 0;
set $is_dir 0;

if (-d $request_filename) { 
    set $is_dir 1; 
}

if ($request_method = COPY) {
    set $is_copy_or_move 1;
}

if ($request_method = MOVE) {
    set $is_copy_or_move 1;
}

set $is_rewrite "${is_dir}${is_copy_or_move}";

if ($is_rewrite = 11) { 
    more_set_input_headers 'Destination: $http_destination/';
    rewrite ^(.*[^/])$ $1/ break;
}
```
方法2: 删除相关代码，重新编译  
删除 ngx_http_dav_module.c 中相关的代码，重新编译。

<!-- todo
## 不显示含非英文字符文件及文件夹
这个我不确定，不过大概率是编码的问题。
-->

## 成果
这是修复以上问题的 docker 镜像
[https://hub.docker.com/r/1574242600/webdav](https://hub.docker.com/r/1574242600/webdav)

## 参考
1. [Nginx and Microsoft Windows WebClient (WebDav)](http://netlab.dhis.org/wiki/ru:software:nginx:webdav)  / [Archived](https://web.archive.org/web/20201026211658/http://netlab.dhis.org/wiki/ru:software:nginx:webdav)
2. [Can’t create or delete directories on an NGINX WebDAV server? Here’s how to fix that!](https://cetteup.com/36/cant-create-or-delete-directories-on-an-nginx-webdav-server-here-is-how-to-fix-that/) / [Archived](https://web.archive.org/web/20210521142218/https://cetteup.com/36/cant-create-or-delete-directories-on-an-nginx-webdav-server-here-is-how-to-fix-that/)
3. [rfc2518][rfc2518]



[dav_module-L504]: https://github.com/nginx/nginx/blob/5e5fa2e9e57b713e445b1737005ff6a202bda8ad/src/http/modules/ngx_http_dav_module.c#L504-L508
[dav_module-L357]: https://github.com/nginx/nginx/blob/5e5fa2e9e57b713e445b1737005ff6a202bda8ad/src/http/modules/ngx_http_dav_module.c#L357-L364
[dav_module-L637]: https://github.com/nginx/nginx/blob/5e5fa2e9e57b713e445b1737005ff6a202bda8ad/src/http/modules/ngx_http_dav_module.c#L637-L646
[rfc-MKCOL示例]: https://datatracker.ietf.org/doc/html/rfc2518#section-8.3.3
[rfc2518]: https://datatracker.ietf.org/doc/html/rfc2518