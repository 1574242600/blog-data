---
title: 'onevps 日本线路貌似炸了'
author: Nworm
slug: onevpsboom
date: 2020-08-17 21:40:00
tags: 
    - vps
---

## 起因
用vps下载一些不可描述的种子，速度向往常一样1MB/s-20MB/波动。  
唯一不同的是ssh比平常卡一些(当时是晚上，我就没有在意)。  

但从vps上下载文件，异常出现了，最高只有1MB/s (我？？？,vps安装了锐速)，32线程都救不了
<!--more-->
## 经过
遇到这种鬼事情，那肯定先ping, traceroute  

### ping and traceroute:  

因为ssh卡得登不上去,所以没测回程

![](https://nworm.icu/pan/%E5%9B%BE%E7%89%87/ping194.156.230.211.png)

嗯,延迟平均250，丢包62%，没毛病。。。。。  
没你个大头鬼啊，这是日本vps,ijj线路啊,延迟也太高了吧。  
丢包62%？？？？  

![我什么场面没见过？，这场面我真没见过.jpg]\()

![](https://nworm.icu/pan/%E5%9B%BE%E7%89%87/route194.156.230.211.png)
相较于以前多了bit-isle这一个路由,然后延迟和丢包就。。。。boom  

重启服务器,依然一样,然后在网上也没看到什么消息  
起先以为只有我这样, 直到找了个在线ping  

![](https://nworm.icu/pan/%E5%9B%BE%E7%89%87/ping194.156.230.211-2.png)

很明显,线路炸了

### 提交工单
把ping和traceroute提交给了技术支持

![](https://nworm.icu/pan/图片/onevps-support-1.png)

照做, 结果和上面基本差不多,都是高延迟高丢包  
你也可以试一试  

![](https://nworm.icu/pan/%E5%9B%BE%E7%89%87/onevps-support-2.png)

额,看来他们也无法解决。。。  
换了ip也一样

## 结果
备份服务器,退款

md, 他家是原生ip, 我在$5元时买的,不用额外付日本机房的钱  

~~现在还有没有$5的原生日本ip, G口的vps,  qwq~~
