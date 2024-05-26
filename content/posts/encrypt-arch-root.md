---
title: '使用 dm-crypt 加密 archLinux 根分区'
author: Nworm
date: 2022-12-04 12:50:00
tags: 
    - dm-crypt
    - linux
    - encrypt
    - archlinux
---

**警告：在正式操作之前，请务必备份根分区**  

这篇博文仅介绍了使用 LUKS2 格式加密已有的未加密的根分区和之后的一些调整。如果需要更多信息，请参考 [[ArchWiki] dm-crypt/Device encryption][参考-2]。

<!--more-->
---------------
> ~~某些人：~~  
>  ~~你要加密干嘛，你是不是有见不得人的东西。~~  
>  ~~身正不怕影子斜，干嘛要加密。~~  
>  ~~你在害怕什么，居然需要用加密？~~  
>  ...... 

dm-crypt 是 linux 内核 2.6 及之后版本中的硬盘加密子系统，所以你不用像 veracrypt 那样安装它。但是你需要安装 Cryptsetup ——它的命令行前端。不过，大多数发行版都已内置了它。


## 准备
1. 备份！备份！备份！
2. 进入你之前安装 archLinux 时的预先安装环境
3. 单独分出一个引导分区  
   如果是 uefi 引导，请直接跳过此步骤。 

   如果剩余有足够大（512MB左右）的未分配空间，请使用 `fdisk` 分配一个引导分区。  
   如果没有剩余的未分配空间，你需要调整其它分区大小（建议使用 diskgenius），再使用 `fdisk` 分配一个引导分区。 

   然后，删除原先的 `/boot` 里的文件。  
   最后，将引导分区格式化（只要是内核支持的格式就行）。
4. 缩小文件系统
   
   由于通常情况下文件系统会占用分区的所有可用空间，而 LUCK2 需要一定空间（默认 16MB，`man` 手册推荐 32MB）用作头部，所以我们需要缩小文件系统。（这里的命令仅适用于 ext2、3、4）

   下面这条命令会把文件系统缩小到 resize2fs 认为的最小的大小。
   ```shell
   # e2fsck -f /dev/分区 && resize2fs -p -M /dev/分区
   ```
   
   下面这条命令比上面的那条要快许多。因为它只会把文件系统缩小到指定的大小。 （这里是原大小减32MB）
   ```shell 
   # e2fsck -f /dev/分区 && resize2fs /dev/分区 原4k区块数减9216
   ```

   原4k区块数可以用 `# resize2fs /dev/分区` 查看。  
   
   建议使用第一条命令。

## 加密

### 测试密码性能
   
   ```shell
   # cryptsetup benchmark 
   ```   
   ![benchmark](https://img.nworm.icu/encrypt-arch-root/benchmark.png)

   它会测试各种密码的性能。在结果中会有一些密码的吞吐量特别高，说明它可能是受硬件支持的密码，请根据情况优先选用它们。(但我觉得懂这些的也不会来这里，所以建议使用默认设置)

   在这里，我们选用了 `aes-xts` 和 `sha256` 用来在之后加密根分区，这也是 Cryptsetup 的默认参数。

   查看默认参数  `# cryptsetup --help`


### 加密根分区
   | 参数  | 默认值 | 示例 | 说明 |
   | ---- | ----- | ---- | ---- |
   | -c | aes-xts-plain64 | 默认 | 密码算法。格式为 `密码算法-分组模式-初始向量生成方法` |
   | -s | 256 (如果分组模式是 xts 则为 512) | 默认 | 密钥大小 |
   | -h | sha256 | 默认 | 摘要算法 |
   | --reduce-device-size | 无 | 32MB | 头部大小。这里用了 `man` 推荐的大小 32MB |
   |......

   
   最后一位参数会让它加密完成后自动解密分区于 `/dev/mapper/名称`，就不需要再用 `# cryptsetup open`。

   ```shell
   # cryptsetup reencrypt --encrypt --reduce-device-size 32M /dev/根分区 名称
   ```

## 调整
由于我们刚才可能过度地缩小了文件系统，所以现在我们要扩展文件系统大小

```shell
# resize2fs /dev/mapper/名称
```

进入 chroot 环境  
```shell
# mount /dev/mapper/名称 /mnt
# arch-chroot /mnt
```

### 修改内核钩子
```shell
# vim /etc/mkinitcpio.conf
```

找到 `HOOKS`，它大概长这样：
```
HOOKS="base udev autodetect modconf block filesystems fsck"
```

现在你需要在 `autodetect` 后面加上 `keyboard keymap`，在 `block` 后面加上 `encrypt`。

```
HOOKS="base udev autodetect keyboard keymap modconf block encrypt filesystems fsck"
```

### 修改内核参数
这里只介绍了 grub，如果你使用其他的引导程序请参考 [[ArchWiki] Kernel_parameters][参考-3]  

```shell
# vim /etc/default/grub
```

找到 `GRUB_CMDLINE_LINUX`，在引号里加上

```
cryptdevice=UUID=分区的UUID:名称
```

UUID 可以使用 `# blkid /dev/根分区` 查看。

### 修改 fstab
```shell
# vim /etc/fstab
```

把挂载在根目录上的 `/dev/根分区` 改为 `/dev/mapper/名称`。

### 重新生成 grub 配置文件和 initramfs
```shell
# mount /dev/引导分区 /boot
# mkinitcpio -p linux
# grub-install /dev/引导设备 //如果是 uefi 引导，请跳过这一条命令
# grub-mkconfig -o /boot/grub/grub.cfg
```

然后重启即可。

![end](https://img.nworm.icu/encrypt-arch-root/end.png)

## 参考资料
Thx.
1. [[ArchWiki] dm-crypt/Device encryption][参考-1] / [Archive][参考-1-存档] 
2. [[ArchWiki] dm-crypt/Encrypting an entire system][参考-2] / [Archive][参考-2-存档]
3. [[ArchWiki] Kernel_parameters][参考-3] / [Archive][参考-3-存档]


[参考-1]: https://wiki.archlinux.org/title/Dm-crypt/Device_encryption 
[参考-1-存档]: https://web.archive.org/web/20211125074608/https://wiki.archlinux.org/title/Dm-crypt/Device_encryption

[参考-2]: https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system
[参考-2-存档]: https://web.archive.org/web/20211202010400/https://wiki.archlinux.org/title/Dm-crypt/Encrypting_an_entire_system

[参考-3]: https://wiki.archlinux.org/title/Kernel_parameters
[参考-3-存档]: https://web.archive.org/web/20211217061555/https://wiki.archlinux.org/title/Kernel_parameters