---
title: '[php] av号 bv号 互转'
author: Nworm
date: 2020-3-24 8:50:00
tags: 
	- php
---
> 参考(caoxi)自 mcfx的回答  
https://www.zhihu.com/question/381784377/answer/1099438784  

<!--more-->
## 正文
```php
$table = 'fZodR9XQDSUm21yCkr6zBqiveYah8bt4xsWpHnJE7jL5VG3guMTKNPAwcF';
$tr = [];
for ($i = 0; $i !== 58; $i++){
	$tr[$table[$i]] = $i;
}
$s = [11,10,3,8,4,6];
$add = 8728348608;

function dec($x){
   global $tr,$s,$add;
	$r = 0;
	for ($i = 0; $i !== 6; $i++){
		$r += $tr[$x[$s[$i]]]*pow(58,$i);
   }
	return ($r-$add)^177451812;
}

function enc($x){
   global $add,$table,$s;
	$x = ($x^177451812) + $add;
	$r = 'BV1  4 1 7  ';
	for ($i = 0; $i !== 6; $i++){
      $k = floor($x/pow(58,$i)%58);
		 $r[$s[$i]] = $table[$k];
  }
	return $r;
}
                      
print(dec('BV17x411w7KC')."\n");
print(dec('BV1Q541167Qg')."\n");
print(dec('BV1mK4y1C7Bz')."\n");
print(enc(170001)."\n");
print(enc(455017605)."\n");
print(enc(882584971)."\n");
```
### 输出
```
170001
455017605
882584971
BV17x411w7KC
BV1Q541167Qg
BV1mK4y1C7Bz
```

## 题外话
bv号很早就有了  
![](https://i.loli.net/2020/03/24/MwgDIyX4RPsx6ZU.png)  
![](https://i.loli.net/2020/03/24/wgKLPGQxFb8DsYW.png)  
小三转正了,23333333  
