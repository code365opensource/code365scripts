$found = Get-Module MicrosoftTeams -ListAvailable
if ($null -eq $found) {
    $p = Read-Host -Prompt "code365scripts.teams 这个模块依赖 MicrosoftTeams这个模块，当前没有检测到，是否要立即安装?【Y/n】"
    if ($p.Length -eq 0 -xor $p.ToLower() -eq "y") {
        Install-Module MicrosoftTeams -Scope CurrentUser
        Import-Module MicrosoftTeams
    }
}