<#
.SYNOPSIS
    安装或更新最新版本的PowerShell
.DESCRIPTION
    安装或更新最新版本的PowerShell
#>
function Update-Powershell {
    [Alias("up")]
    [CmdletBinding()]
    param ()

    process {
        Invoke-Expression "& {$(Invoke-Restmethod https://aka.ms/Install-PowerShell.ps1)}  -Quiet -AddExplorerContextMenu"
    }
}


<#
.SYNOPSIS
    安装新的机器环境，默认情况下安装几个主要的开发工具:"vscode", "anaconda3", "git", "nodejs-lts", "winhotkey", "postman"
 #>
function Install-Machine {
    [Alias("im")]
    param(
        [string[]]$apps,
        [switch]$useDefault
    )

    $confirm = Read-Host -Prompt "这个命令涉及到安装软件，所以你需要在管理员模式下打开Powershell，请问是否继续？【y/N】"

    if ($confirm.ToLower() -ne "y") {
        return
    }


    if ($useDefault) {
        $config = Invoke-Restmethod https://raw.githubusercontent.com/code365opensource/code365scripts/master/code365scripts/config.json
        $apps = $config.defaultapps."$apps"
    }

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