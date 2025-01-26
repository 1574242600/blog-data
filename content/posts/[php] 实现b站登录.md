---
title: '[php] 实现b站登录'
author: Nworm
slug: php-shixianbzhan
date: 2019-12-25 20:00:00
tags: 
    - php
---

> [https://blog.kaaass.net/archives/947](https://blog.kaaass.net/archives/947)
---------------------------
在网上无聊瞎逛时，找到了这位大佬的文章
里面给出了ak，sk ，万分感激 


<!--more-->
```
Device: android
Description: 普通版
AppKey: 1d8b6e7d45233436
SecretKey: 560c52ccd288fed045859ed18bffd973

Device: android_i
Description: 国际版
AppKey: bb3101000e232e27
SecretKey: 36efcfed79309338ced0380abd824ac1

Device: android_b
Description: 概念版
AppKey: 07da50c9a0bf829f
SecretKey: 25bdede4e1581c836cab73a48790ca6e

Device: android_tv
Description: 电视版
AppKey: 4409e2ce8ffd12b8
SecretKey: 59b43e04ad6965f34319062b478f83dd

Device: biliLink
Description: 直播
AppKey: 37207f2beaebf8d7
SecretKey: e988e794d4d4b6dd43bc0e89d6e90c43
```
（之前因为没ak，sk放弃了）
那该死的小破站，居然还没有公开OAuth2 （[https://passport.bilibili.com/register/third.html][2]）
那就只好用安卓客户端的api来玩了


![1](https://i.loli.net/2019/12/25/9IkbpyWfH3ZaxQh.png)
![2](https://i.loli.net/2019/12/25/WIRCULzbswK2rZv.png)

分别请求了
https://passport.bilibili.com/api/oauth2/getKey 用于获取加密明文密码用的hash，公钥
https://passport.bilibili.com/api/v2/oauth2/login 用于简单的获取用户的登录凭据（access_key、Cookie）
下面看请求参数
![3](https://i.loli.net/2019/12/25/sInQoOAdxNuVt6W.png)

| 参数名   | 说明 |
| ------ | ------ |
|  appkey  | key   |
|  build   | 不知道 |
| mobi_app | 不知道 |
| platform | 不知道 |
| ts       | 时间戳 |
| sign     | 签名   |

除了sign，没什么好讲的，第二个请求就多了两个参数 username ，password（重要）

### 返回示例
https://passport.bilibili.com/api/oauth2/getKey
```json
{"ts":1577273591,   // 当前UNIX时间戳
 "code":0,          //状态码
 "data":{
 "hash":"56e15708534f5973", //哈希
 "key":"-----BEGIN PUBLIC KEY-----
 \nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDjb4V7EidX/ym28t2ybo0U6t0n\n6p4ej8VjqKHg100va6jkNbNTrLQqMCQCAYtXM
 XXp2Fwkk6WR+12N9zknLjf+C9sx\n/+l48mjUU8RqahiFD1XT/u2e0m2EN029OhCgkHx3Fc/KlFSIbak93EH/XlYis0w+\nXl69GV6klz
 gxW6d2xQIDAQAB\n-----END PUBLIC KEY-----\n"   //公钥
}}
```

https://passport.bilibili.com/api/v2/oauth2/login
```json
{
	"ts": 1577278563, // 当前UNIX时间戳
	"code": 0,  // 状态码
	"data": {
		"status": 0,
		"token_info": {
			"mid": 1, // 该用户的mid
			"access_token": "1234567890abcde1234567890abc", // 该用户的access_key
			"refresh_token": "1234567890abcde1234567890abc", // 该用户的refresh_token
			"expires_in": 2592000             // 过期时间戳
		},
		"cookie_info": {     // 该用户Cookie凭据
			"cookies": [.....], 
			"domains": [.....]
		},
		"sso": [.....]
	}
}

```

### 签名(sign)生成方式：

> 把接口所需所有参数拼接，如utk=xx&time=xx，按参数名称排序，最后再拼接上密钥App-Secret，做md5加密 (callback不需要参与sign校检)           ------[https://github.com/fython/BilibiliAPIDocs][3]

PHP 版本:
```php
/**
 * @param $params array 参数列表
 * @param $key 加密密钥
 * @return array sign:加密校验串,params:参数拼接串
 */
 function get_sign($params, $key) {
  $_data = array();
  ksort($params);
  reset($params);
  foreach ($params as $k => $v) {
  // rawurlencode 返回的转义数字必须为大写( 如%2F )
  $_data[] = $k . '=' . rawurlencode($v);
  }
  $_sign = implode('&', $_data);
  return array(
    'sign' => strtolower(md5($_sign . $key)),
    'params' => $_sign,
  );
 }
 define("APP_SECRET","abcdef123456");
 get_sign(array("type"=>"json"),APP_SECRET);
```
js版本:
```js
<script type="text/javascript" src="http://static.hdslb.com/js/md5.js">/script>
 function get_sign(params, key)
 {
 	var s_keys = [];
 	for (var i in params)
 	{
 		s_keys.push(i);
 	}
 	s_keys.sort();
 	var data = "";
 	for (var i = 0; i < s_keys.length; i++)
 	{
 		// encodeURIComponent 返回的转义数字必须为大写( 如 %2F )
 		data+=(data ? "&" : "")+s_keys[i]+"="+encodeURIComponent(params[s_keys[i]]);
 	}
 	return {
 		"sign":hex_md5(data+key),
 		"params":data
 	};
 }
```

### password 生成方式
在明文密码前拼接从https://passport.bilibili.com/api/oauth2/getKey得来的hash，用得来的公钥做rsa加密再base64  

```php
/**
 * @param $key 加密公钥
 * @param $hash string 哈希
 * @param $pwd string 明文密码
 * @return string base64后的加密密码
 */

function get_rsa_pwd($key,$hash,$pwd) {
        $pu_key = openssl_pkey_get_public($key);
        if ($loginkey) {
            openssl_public_encrypt($hash . $pwd ,$rsa_pwd,$pu_key);
            return base64_encode($rsa_pwd);
        } else {
            return false ;
        }
    }
```

这些都知道了，你还写不出来登录？？

### demo 
```
https://nworm.cf/my/bili/login.php?user=a&pwd=b
参数都懂吧
我不会记录账号密码，也没有必要
不相信我的，请使用小号
```


### 源码

[https://github.com/1574242600/bili-login][4]
我没写判断

### 关于验证码的问题

关于验证码的问题
https://passport.bilibili.com/captcha
在请求b站登录api（或demo，不过demo的sid的值请自行解析，我懒）时，它会返回一个cookies， 名称为sid
带着sid请求上面的链接，得到验证码图片，和名为JSESSIONID的session
最后带着上面的cookies ，再加个请求参数captcha，值就是验证码
就行了

### 坑
```php
curl_setopt($lo, CURLOPT_POSTFIELDS,$data);
```
```php
curl_setopt($lo, CURLOPT_POSTFIELDS,http_build_query($data));
```
区别：[https://www.cnblogs.com/52php/p/5677689.html][5]
(会导致b站认为你的请求非法)
这玩意害我蒙了半天
以后我绝对加http_build_query()


  [1]: https://blog.kaaass.net/archives/947
  [2]: https://passport.bilibili.com/register/third.html
  [3]: https://github.com/fython/BilibiliAPIDocs
  [4]: https://github.com/1574242600/bili-login
  [5]: https://www.cnblogs.com/52php/p/5677689.html
