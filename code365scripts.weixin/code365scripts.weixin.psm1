<#
.SYNOPSIS
    备份微信公众号文章
.DESCRIPTION
    备份微信公众号文章，保存在本地一个目录中，用JSON格式保存，每个文件保存20篇文章
.EXAMPLE
    PS C:\> Save-WeixinNews -AppId xxxxxxxxx -AppSecret xxxxxxxx -Folder d:\temp\news
    请自行准备AppId和AppSecret，并且注意，要把本机的IP地址添加到白名单中，请参考 https://mp.weixin.qq.com/cgi-bin/announce?action=getannouncement&key=1495617578&version=1&lang=zh_CN&platform=2&token=908727256
.LINK
    https://github.com/code365opensource/code365scripts/tree/master/code365scripts.weixin
#>
function Save-WeixinNews {
    [CmdletBinding(DefaultParameterSetName = "Normal")]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "Normal")]
        [Parameter(Mandatory = $true, ParameterSetName = "Profile")]
        [string]$Folder,


        [Parameter(Mandatory = $true, ParameterSetName = "Normal")]
        [string]$AppId,

        [Parameter(Mandatory = $true, ParameterSetName = "Normal")]
        [string]$AppSecret

        # [Parameter(Mandatory = $true, ParameterSetName = "Profile")]
        # [switch]$UseLocalProfile
    )


    if (!(Test-Path -Path $Folder)) {
        Write-Host "该目录不存在，请检查后重试"
        return
    }

    $tokenUrl = "https://api.weixin.qq.com/cgi-bin/token?grant_type=client_credential&appid=$AppId&secret=$AppSecret"

    $response = Invoke-RestMethod -Method POST -Uri $tokenUrl

    if ($null -ne $response."errcode") {
        Write-Host "当前遇到如下错误，请解决后再次执行代码"
        Write-Host $response
        return
    }

    $token = $response.access_token


    $allmaterialsUrl = "https://api.weixin.qq.com/cgi-bin/material/get_materialcount?access_token=$($token)"

    $response = Invoke-RestMethod -Uri $allmaterialsUrl

    $newsCount = $response.news_count
    $pages = [Math]::Ceiling($newsCount / 20)
    $pageIndex = 1


    $getmateriallistUrl = "https://api.weixin.qq.com/cgi-bin/material/batchget_material?access_token=$($token)"

    do {
        Write-Progress -Activity "保存文章列表" -Status "第 $pageIndex 页" -PercentComplete ($pageIndex / $pages * 100)
        
        $data = @{
            type   = 'news'
            offset = ($pageIndex - 1) * 20
            count  = 20
        } | ConvertTo-Json

        $file = Join-Path $Folder "weixin_news_backup_$pageIndex.json"
        Invoke-RestMethod -Method Post -Uri $getmateriallistUrl -Body $data -OutFile $file
        $PageIndex = $PageIndex + 1
    } until ($pageIndex -gt $pages)


}

# 通过 ParemeterSet 可以实现类似于方法重载的效果