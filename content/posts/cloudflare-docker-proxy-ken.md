---
title: Cloudflare-docker-proxy 无法匿名拉取官方镜像
author: Nworm
date: 2024-06-13T00:00:00
update: 2024-06-14T00:00:00
tags:
  - Docker
  - Worker
  - Cloudflare
---
最近，由于某些 \[数据删除\] 的原因，Docker 官方的 registry 被 GFW 封锁，导致在默认配置国内无法拉取镜像。而且国内各大镜像站也相继下线。于是打算自建镜像，然后找到了 **[cloudflare-docker-proxy][cloudflare-docker-proxy]**，然后踩坑。

~这里提供关于无法匿名拉取官方镜像的解决方法。~

作者已经在 [PR #20][PR #20] 解决了该问题
<!--more-->
-----
### 解决方法 1
使用 `registry-mirrors`

编辑 docker 的 `daemon.json`
```json
{
  "registry-mirrors": ["https://docker.your.domin"]
}
```

然后重启 docker 后台服务，直接拉取即可
```
docker pull hello-world
```
### 解决方法 2
加上 `library/`

要匿名拉取官方镜像，需要加上 `library/`
```bash
docker pull docker.your.domin/library/hello-world
```

[原因][my-comment]
### BTW
作者在 [PR #14][PR #14]  支持了登入 registry。


[cloudflare-docker-proxy]: https://github.com/ciiiii/cloudflare-docker-proxy
[PR #14]: https://github.com/ciiiii/cloudflare-docker-proxy/pull/14
[my-comment]: https://github.com/ciiiii/cloudflare-docker-proxy/issues/11#issuecomment-2162736963
[PR #20]: https://github.com/ciiiii/cloudflare-docker-proxy/pull/20