---
title: 间接获取b站账户注册时间，精确到秒
author: Nworm
date: 2020-02-13 13:40:00
update: 2020-07-16 12:40:00
---

于2020 7 16 更新

破站现在默认隐藏收藏，只有公开了收藏的账户能用这方法，就看看自己的注册时间吧，23333
当然，如果你知道它默认文件夹id那就没问题了

```
`GET` https://api.bilibili.com/x/v3/fav/folder/created/list-all?up_mid={你的uid}&jsonp=jsonp
```
<!--more-->
### 返回实例  
```json
{
  "code": 0,
  "message": "0",
  "ttl": 1,
  "data": {
    "count": 1,
    "list": [
      {
        "id": 419483821,	// 文件夹id
        "fid": 4194838,   
        "mid": 415983021,
        "attr": 0,
        "title": "默认收藏夹",
        "fav_state": 0,
        "media_count": 4
      }
    ]
  }
}
```

```
`GET` https://api.bilibili.com/x/v3/fav/resource/list?media_id={文件夹id}&pn=1&ps=20
```

### 返回实例  
```json
{
  "code": 0,
  "message": "0",
  "ttl": 1,
  "data": {
    "info": {
      "id": 84931926,
      "fid": 849319,
      "mid": 27710126,
      "attr": 0,
      "title": "默认收藏夹",
      "cover": "http://i1.hdslb.com/bfs/archive/cd7bae2fb36220f4d6fcf0337b06726fbfe86275.jpg",
      "upper": {
        "mid": 27710126,
        "name": "诋生稳危",
        "face": "http://i2.hdslb.com/bfs/face/8040fb11ac4c0ba86907d2d675a64c63695b46c3.jpg"
      },
      "cover_type": 2,
      "cnt_info": {
        "collect": 0,
        "play": 0,
        "thumb_up": 0,
        "share": 0
      },
      "type": 11,
      "intro": "",
      "ctime": 1460275583,   //文件夹创建时间的时间戳
      "mtime": 1557534324,
      "state": 0,
      "fav_state": 0,
      "like_state": 0,
      "media_count": 163
    },
  "medias": [...]
}
```

默认收藏夹是在账户注册时自动生成的，所以默认收藏夹创建时间即为账户注册时间  

### 注意事项  
 1. 对在2015-08-07 04:34:56前注册的用户无效 

