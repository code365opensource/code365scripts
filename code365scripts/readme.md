## 核心模块

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/code365scripts?label=code365scripts)](https://www.powershellgallery.com/packages/code365scripts) [![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/code365scripts)](https://www.powershellgallery.com/packages/code365scripts)

### 如何安装

打开 PowerShell 窗口，运行 `Install-Module code365scripts`

### 功能介绍

1. 升级 PowerShell 到最新版本

   目前 Windows 默认安装的 PowerShell 版本是 5.1，这个版本是只能在 Windows 上面运行的。后来，微软开发了一个可以跨平台的 PowerShell 版本，从 6.0 开始编号。这个版本可以在 Windows， Mac， Liunx 等多个平台运行，并且这个版本经常更新，目前的版本号是 7.1.3。

   更新 PowerShell 版本本身并不难，你在打开 PowerShell 窗口时就会有提示，然后通过一个网址，你可以下载，然后安装。

   但是如果你觉得这个过程还是比较繁琐的话，你可以简单地通过 `Update-Powershell` 这个命令来完成，甚至可以用 `up` 这个快捷指令即可。

1. 初始化电脑环境

   这是我最喜欢用的一个脚本，我自己有一个习惯，就是隔一段时间就重装一下系统（例如半年），那么当你拿到一个新的干净的机器，如何快速地把你喜爱的一些程序都安装起来呢？

   我采取的方法是通过 [choco](https://chocolatey.org/) 这个工具来批量安装应用，绝大部分常见的软件在这里都有。关于如何查找这些软件，你可以参考这里 <https://chocolatey.org/packages>

   例如你要安装几个工具，`vscode,7zip,git`等，你可以用核心模块中下面这个命令来实现

   `Install-Machine -apps vscode,7zip,git`

   > 由于安装软件可能涉及到到管理员权限，所以你需要用管理员模式打开 Powershell

   是不是很容易呢？你甚至可以用 `im -apps vscode,7zip,git`这样的快捷方式。

   为了帮助大家更好地重用，这个工具支持加载预定义的一些应用集合，例如我定义了一个给开发人员用的集合，叫 `dev`，这里面包含了我自己常用的一些软件。如果你想直接使用，那么就可以输入 `im -apps dev -useDefault` 即可。

   这些应用集合，是定义在 <https://github.com/code365opensource/code365scripts/blob/master/code365scripts/config.json>  这个文件的，你可以随时参考，如果你想贡献内容，例如你有一个针对特定人群的应用集合，你可以 `Fork` 这个项目，然后修改这个文件，并且给我提交 `Pull request`，我会视情况合并进去。


