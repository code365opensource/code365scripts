<#
.SYNOPSIS
    下载保存微信图文消息
.DESCRIPTION
    可以用来存档，保存为JSON格式，或者进行其他的处理
.EXAMPLE
    PS C:\> Get-WeixinNews -appId xxxxx -appSecret xxxxxx
    指定账号信息和密钥
.INPUTS
    
.OUTPUTS
    
.NOTES
    
#>
function Get-WeixinNews {
    [CmdletBinding()]
    param (
        [string]$appId,
        [string]$appSecret
    )
    
    Write-Host $appId, $appSecret
}

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


    Invoke-Expression "& {$(Invoke-Restmethod https://aka.ms/Install-PowerShell.ps1)} -UseMSI"
}
