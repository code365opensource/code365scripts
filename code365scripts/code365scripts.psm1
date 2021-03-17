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
