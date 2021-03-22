## Teams 模块

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/code365scripts.teams?label=code365scripts.teams)](https://www.powershellgallery.com/packages/code365scripts.teams) [![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/code365scripts.teams)](https://www.powershellgallery.com/packages/code365scripts.teams)

### 如何安装

打开 PowerShell 窗口，运行 `Install-Module code365scripts.teams`

### 功能介绍

1. 批量下载 Teams 视频会议的背景图

   下载 https://adoption.microsoft.com/microsoft-teams/custom-backgrounds-gallery/ 这里列出的美图，保存到 Teams 指定的目录，并且进行压缩，生成缩略图。你只需要运行这个脚本，然后再去打开 Teams 的视频会议，选择背景图时就可以看到这些新的图片。

   你可以执行 `Get-TeamsVideoMeetingBackgrounds` 这个命令，或者快捷指令 `gtvb`

2. 清理 Teams 客户端缓存

   有时候你可能希望一键清理Teams客户端的本地缓存，已解决一些奇怪的问题。如果你手工操作，一般是把 `%userprofile%\appdata\Roaming\Microsoft\teams` 的几个子目录 (`blob_storage`, `cache`, `code cache`, `database`, `gpucache`, `indexdb`, `local storage`, `session storage`, `tmp`) 清理一下。

   你可以执行 `Remove-TeamsClientCache` 这个命令快速完成。这个操作并不会丢失任何消息，请放心使用。