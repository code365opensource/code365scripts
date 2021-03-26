## 微信模块

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/code365scripts.weixin?label=code365scripts.weixin)](https://www.powershellgallery.com/packages/code365scripts.weixin) [![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/code365scripts.weixin)](https://www.powershellgallery.com/packages/code365scripts.weixin)


### 如何安装

打开 PowerShell 窗口，运行 `Install-Module code365scripts.weixin`, 如果此前安装过，请运行 `Update-Module code365scripts.weixin`

### 功能介绍

1. 备份微信公众号文章

   备份微信公众号文章，保存在本地一个目录中，用JSON格式保存，每个文件保存20篇文章。请自行准备AppId和AppSecret，并且注意，要把本机的IP地址添加到白名单中，请参考 https://mp.weixin.qq.com/cgi-bin/announce?action=getannouncement&key=1495617578&version=1&lang=zh_CN&platform=2&token=908727256

   `Save-WeixinNews -AppId xxxxxxxxx -AppSecret xxxxxxxx -Folder xxxxxx`
