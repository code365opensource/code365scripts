<#
.SYNOPSIS
    升级 PowerShell 到最新版本
.DESCRIPTION
    目前 Windows 默认安装的 PowerShell 版本是 5.1，这个版本是只能在 Windows 上面运行的。后来，微软开发了一个可以跨平台的 PowerShell 版本，从 6.0 开始编号。这个版本可以在 Windows， Mac， Liunx 等多个平台运行，并且这个版本经常更新，目前的版本号是 7.1.3。
    更新 PowerShell 版本本身并不难，你在打开 PowerShell 窗口时就会有提示，然后通过一个网址，你可以下载，然后安装。
    但是如果你觉得这个过程还是比较繁琐的话，你可以简单地通过 `Update-Powershell` 这个命令来完成，甚至可以用 `up` 这个快捷指令即可。
.LINK
    https://github.com/code365opensource/code365scripts/tree/master/code365scripts
#>
function Update-Powershell {
    [Alias("up")]
    [CmdletBinding()]
    param ()

    process {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        Invoke-Expression "& {$(Invoke-Restmethod https://aka.ms/Install-PowerShell.ps1)}  -Quiet -AddExplorerContextMenu"
    }
}

<#
.SYNOPSIS
    安装新的机器环境
.DESCRIPTION
   这是我最喜欢用的一个脚本，我自己有一个习惯，就是隔一段时间就重装一下系统（例如半年），那么当你拿到一个新的干净的机器，如何快速地把你喜爱的一些程序都安装起来呢？
   我采取的方法是通过 [choco](https://chocolatey.org/) 这个工具来批量安装应用，绝大部分常见的软件在这里都有。关于如何查找这些软件，你可以参考这里 <https://chocolatey.org/packages>
   例如你要安装几个工具，`vscode,7zip,git`等，你可以用核心模块中下面这个命令来实现
   `Install-Machine -apps vscode,7zip,git`
   是不是很容易呢？你甚至可以用 `im -apps vscode,7zip,git`这样的快捷方式。
   为了帮助大家更好地重用，这个工具支持加载预定义的一些应用集合，例如我定义了一个给开发人员用的集合，叫 `dev`，这里面包含了我自己常用的一些软件。如果你想直接使用，那么就可以输入 `im -apps dev -useDefault` 即可。未来还可以支持更多的场景，欢迎大家给我提反馈，https://github.com/code365opensource/code365scripts/discussions/1

   如果你安装英文系统，但是要一次性添加中文输入法，并且将其设置为默认输入法（初始输入为英文状态），字体输入提示变大，请使用 -setupChineseInput 这个开关
   如果你要删除掉一些不常用的功能，请使用 -disableOptionalFeatures 这个开关
   如果你要删除掉一些不常用的UWP（Windows Store中的应用），请使用 -removeUWPs这个开关
.EXAMPLE
    PS C:\> Install-Machine -apps vscode,git,7zip
    这是常规用法，安装以上四个应用
.EXAMPLE
    PS C:\> im -apps vscode,git,7zip
    这是简写用法，安装以上四个应用
.EXAMPLE
    PS C:\> im -apps dev -useDefault
    这是安装服务器端定义好的dev这个场景的应用集合。还支持其他更多自定义集合。
.LINK
    https://github.com/code365opensource/code365scripts/tree/master/code365scripts
#>
function Install-Machine {
    [Alias("im")]
    param(
        [string[]]$apps,
        [switch]$useDefault,
        [switch]$setupChineseInput,
        [switch]$disableOptionalFeatures,
        [switch]$removeUWPs
    )

    $confirm = Read-Host -Prompt "Please run powershell in Administrator mode [y/N]"

    if ($confirm.ToLower() -ne "y") {
        return
    }

    Set-ExecutionPolicy Bypass -Scope Process -Force
    
    if ($setupChineseInput) {
    
        # 添加中文输入法
        $languagelist = Get-WinUserLanguageList
        $languagelist.add("zh-CN")
        Set-WinUserLanguageList $languagelist -Force

        # 设置默认输入法为中文
        Set-WinDefaultInputMethodOverride -InputTip "0804:{81D4E9C9-1D3B-41BC-9E6C-4B40BF79E35E}{FA550B04-5AD7-411F-A5AC-CA038EC515D7}"

        # 设置系统默认语言为中文
        Set-winsystemlocale -SystemLocale zh-CN

        # 设置时区为中国
        Set-TimeZone -Name "China Standard Time"

        # 设置资源管理器中，显示文件扩展名
        Push-Location
        Set-Location HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced
        Set-ItemProperty . HideFileExt "0"
        Pop-Location

        # 设置输入法默认为英文

        Push-Location
        Set-Location HKCU:\SOFTWARE\Microsoft\InputMethod\Settings\CHS
        Set-ItemProperty . "Default Mode" "1"
        Pop-Location

        # 输入法字体设置大一些
        # Push-Location
        # Set-Location HKCU:\SOFTWARE\Microsoft\InputMethod\CandidateWindow\CHS\1
        # Set-ItemProperty . FontStyle "32.00pt;Regular;;Microsoft YaHei UI"
        # Set-ItemProperty . "Default Mode" "1"
        # Pop-Location

    }

    if ($useDefault) {
        $config = Invoke-Restmethod "https://github.com/code365opensource/code365scripts/raw/master/code365scripts.core/config.json"
        $apps = $config.defaultapps."$apps"
    }

    if ($apps) {
        if (!(Test-Path "$env:programdata\chocoportable\bin\choco.exe")) {
            Invoke-Expression "& {$(Invoke-Restmethod https://chocolatey.org/install.ps1)}"
        }

        $list = Invoke-Expression "choco list --localonly"

        foreach ($item in $apps) {
            $found = $list -like "$item*"
            if ($null -ne $found) {
                Invoke-Expression "choco upgrade $item -y"
            }
            else {
                Invoke-Expression "choco install $item -y"
            }
        }
    }



    # 禁用所有的可选功能
    if ($disableOptionalFeatures) {
        Get-WindowsOptionalFeature -Online | Where-Object { $_.State -eq "Enabled" } | Disable-WindowsOptionalFeature -Online -NoRestart
        $removeCapabilities = 
        "App.StepsRecorder",
        "App.Support.QuickAssist",
        "Browser.InternetExplorer",
        "DirectX.Configuration.Database",
        "Hello.Face",
        "Language.Handwriting",
        "Language.OCR",
        "Language.Speech",
        "Language.TextToSpeech",
        "MathRecognizer",
        "Media.WindowsMediaPlayer",
        "Microsoft.Windows.MSPaint",
        "Microsoft.Windows.PowerShell.ISE",
        "Microsoft.Windows.WordPad",
        "OpenSSH.Client",
        "Print.Management.Console",
        "Windows.Client.ShellComponents",
        "Language.Fonts.Hans",
        "Print.Fax.Scan";

        $removeCapabilities | ForEach-Object {
            Get-WindowsCapability -Name "$($_)*" -Online `
            | Where-Object { $_.State -eq "Installed" } `
            | ForEach-Object {
                Remove-WindowsCapability -Name $_ -Online
            }
        }
    }


    # 删除不用的UWP
    if ($removeUWPs) {
        $apps = "Microsoft.People,Microsoft.Office.OneNote,Microsoft.YourPhone,Microsoft.PowerAutomateDesktop,Microsoft.Todos,Microsoft.BingNews,MicrosoftTeams,Microsoft.BingWeather,Microsoft.Getstarted,Microsoft.MicrosoftOfficeHub,Microsoft.WindowsCamera,Microsoft.WindowsCalculator,Microsoft.Xbox.TCUI,Microsoft.XboxGamingOverlay,Microsoft.WindowsAlarms,Microsoft.ZuneVideo,Microsoft.XboxSpeechToTextOverlay,Microsoft.SkypeApp,Microsoft.WindowsMaps,Microsoft.WindowsFeedbackHub,Microsoft.XboxApp,Microsoft.MicrosoftStickyNotes,Microsoft.XboxGameOverlay,Microsoft.MicrosoftSolitaireCollection,Microsoft.MSPaint,Microsoft.Microsoft3DViewer,Microsoft.Wallet,Microsoft.ZuneMusic,microsoft.windowscommunicationsapps,Microsoft.MixedReality.Portal,Microsoft.GetHelp,Microsoft.WindowsSoundRecorder,Microsoft.549981C3F5F10"

        $apps.split(",") | ForEach-Object {
            Get-AppxPackage -Name $_ | Remove-AppxPackage
        }
    }
    
    # 重启电脑
    Restart-Computer
}

# 自动更新Powershell模块（默认更新code365scripts这几个模块，可以加入到powershell启动时运行）


<#
.SYNOPSIS
    设置Word，Excel，PowerPoint的默认字体为微软雅黑
#>
function Set-OfficeDefaultFont {
    $confirm = Read-Host -Prompt "Please run powershell in Administrator mode [y/N]"
    if ($confirm.ToLower() -ne "y") {
        return
    }

    $path = "$home\AppData\Roaming\Microsoft\Templates"
    $wc = New-Object System.Net.WebClient
    
    Write-Host "Set Powerpoint template"

    $wc.DownloadFile("https://github.com/code365opensource/code365scripts/blob/master/code365scripts.core/templates/Blank.potx?raw=true", "$path\blank.potx")


    Write-Host "Set Word template"
    $wc.DownloadFile("https://github.com/code365opensource/code365scripts/blob/master/code365scripts.core/templates/Normal.dotm?raw=true", "$path\normal.dotm")

    Write-Host "Set Excel options"

    $location = Get-Location
    Set-Location "HKCU:"
    Set-ItemProperty -Path "HKEY_CURRENT_USER\software\policies\microsoft\office\16.0\excel\options" -Name "font" -Value "Microsoft YaHei UI,11" -Type String
    set-location $location

    
}
