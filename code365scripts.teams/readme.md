## Teams 模块

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/code365scripts.teams?label=code365scripts.teams)](https://www.powershellgallery.com/packages/code365scripts.teams) [![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/code365scripts.teams)](https://www.powershellgallery.com/packages/code365scripts.teams)

### 如何安装

打开 PowerShell 窗口，运行 `Install-Module code365scripts.teams`，如果此前已经安装过，请运行 `Update-Module code365scripts.teams`

### 功能介绍

1. 批量下载 Teams 视频会议的背景图

   下载 https://adoption.microsoft.com/microsoft-teams/custom-backgrounds-gallery/ 这里列出的美图，保存到 Teams 指定的目录，并且进行压缩，生成缩略图。你只需要运行这个脚本，然后再去打开 Teams 的视频会议，选择背景图时就可以看到这些新的图片。

   你可以执行 `Get-TeamsVideoMeetingBackgrounds` 这个命令，或者快捷指令 `gtvb`

2. 清理 Teams 客户端缓存

   有时候你可能希望一键清理 Teams 客户端的本地缓存，已解决一些奇怪的问题。如果你手工操作，一般是把 `%userprofile%\appdata\Roaming\Microsoft\teams` 的几个子目录 (`blob_storage`, `cache`, `code cache`, `database`, `gpucache`, `indexdb`, `local storage`, `session storage`, `tmp`) 清理一下。

   你可以执行 `Remove-TeamsClientCache` 这个命令快速完成。这个操作并不会丢失任何消息，请放心使用。

3. 批量导入用户到团队

   经常会有这样的需求，用户希望能快速创建团队，并且批量添加用户（不管是内部用户还是外部用户）.这个命令支持为现有团队添加用户，也支持创建团队后添加用户。用户名信息，可以在命令行中直接指定，也可以通过 CSV 文件导入。

   ```powershell
   .DESCRIPTION
      通过指定用户名或者从CSV中批量导入用户到某个团队。同时支持内部用户，和外部用户（作为来宾邀请加入），如果是内部用户的话，支持不带邮箱信息直接添加。
   .EXAMPLE
      PS C:\> Import-TeamUser -teamName "开发测试" -users mike@xyz.com,tom@abc.com
      用逗号分开不同的用户名,这里假定 mike@xyz.com 是内部用户，而 tom@abc.com 是外部用户。
   .EXAMPLE
      PS C:\> Import-TeamUser -teamName "开发测试" -users mike@xyz.com,tom@abc.com -createTeam
      用指定的名称创建团队，然后导入用户。用逗号分开不同的用户名,这里假定 mike@xyz.com 是内部用户，而 tom@abc.com 是外部用户。
   .EXAMPLE
      PS C:\> Import-TeamUser -teamName "开发测试" -users mike,tom
      用逗号分开不同的用户名，如果不带邮箱后缀，则自动以当前用户的邮箱后缀补充
   .EXAMPLE
      PS C:\> Import-TeamUser -teamName "开发测试" -users (Import-Csv data.csv).email
      从CSV中导入用户，以上命令假设用户信息文件名为 data.csv, 并且在 email 这个列中保存了用户的邮箱地址（可以带公司的后缀，也可以不带）

   ```

4. 从多级嵌套用户组中导入用户到团队

   ```powershell
   .SYNOPSIS
    从一个用户组中导入用户到团队
   .DESCRIPTION
      支持多层嵌套用户组，不限层级
   .EXAMPLE
      PS C:\> Import-TeamsUserFromGroup -TeamName AllFTE -GroupName "GCR ALL FTE"
      把GCR ALL FTE这个组的用户，全部导入到 ALLFTE 这个团队中去
   .EXAMPLE
      PS C:\> Import-TeamsUserFromGroup -TeamName AllFTE -GroupName "GCR ALL FTE" -createTeam
      把GCR ALL FTE这个组的用户，全部导入到新创建的 ALLFTE 这个团队中去
   ```
