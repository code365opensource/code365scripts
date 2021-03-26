function GenerateThumbnail {
    param (
        [string]$filePath
    )
    $fileName = Split-Path $filePath -Leaf
    $thumbName = "$($fileName.Split('.')[0])_thumb.jpg"
    
    $full = [System.Drawing.Image]::FromFile($filePath);
    $thumb = $full.GetThumbnailImage(280, 158, $null, [System.IntPtr]::Zero);

    $encoder = GetEncoder

    $myEncoder = [Drawing.Imaging.Encoder]::Quality
    $myEncoderParameters = New-Object Drawing.Imaging.EncoderParameters(1)
    $myEncoderParameter = New-Object Drawing.Imaging.EncoderParameter($myEncoder, 24L)
    $myEncoderParameters.Param[0] = $myEncoderParameter

    $thumb.Save($filePath.replace($fileName, $thumbName), $encoder, $myEncoderParameters);
    $full.Dispose();
    $thumb.Dispose();
}

function GetEncoder() {
    $format = [Drawing.Imaging.ImageFormat]::Jpeg

    $codecs = [System.Drawing.Imaging.ImageCodecInfo]::GetImageDecoders()
    foreach ($codec in $codecs) {
        if ($codec.FormatID -eq $format.Guid) {
            return $codec;
        }
    }
    return $null;
}

function EnsureRequiredModules {
    [CmdletBinding()]
    param (
        [string[]]$requiredModules
    )

    $foundModules = Get-Module $requiredModules -ListAvailable
    if ($null -eq $foundModules) {
        $foundModules = @()
    }
    else {
        $foundModules = $foundModules.Name
    }

    if ($foundModules.Count -lt $requiredModules.Count) {

        $needToInstallModules = $requiredModules | Where-Object { $_ -notin $foundModules }

        $p = Read-Host -Prompt "该命令依赖 $([string]::Join(',',$needToInstallModules)) 模块，当前没有检测到，是否要立即安装?【Y/n】"
        if ($p.Length -eq 0 -xor $p.ToLower() -eq "y") {
            Install-Module $needToInstallModules -Scope CurrentUser
        }
        else {
            return
        }
    }
}

<#
.SYNOPSIS
    批量下载Teams视频会议的背景图
.DESCRIPTION
    下载 https://adoption.microsoft.com/microsoft-teams/custom-backgrounds-gallery/ 这里列出的美图，保存到Teams指定的目录，并且进行压缩，生成缩略图。你只需要运行这个脚本，然后再去打开Teams的视频会议，选择背景图时就可以看到这些新的图片。
.EXAMPLE
    PS C:\> Get-TeamsVideoMeetingBackgrounds
    下载所有推荐的美图到Teams指定目录
.EXAMPLE
    PS C:\> gtvb
    下载所有推荐的美图到Teams指定目录
.LINK
    https://github.com/code365opensource/code365scripts/tree/master/code365scripts.teams
#>
function Get-TeamsVideoMeetingBackgrounds {
    [CmdletBinding()]
    [Alias("gtvb")]
    param ()
    
    if ($PSVersionTable.PSVersion.Major -lt 6) {
        # 老版本Powershell需要手工导入这个图像库
        Add-Type -AssemblyName System.Drawing
    }

    $path = "$home\AppData\Roaming\Microsoft\Teams\Backgrounds\uploads"

    if (-not (Test-Path $path)) {
        New-Item $path -ItemType Directory | Out-Null
    }

    # UseBasicparsing 可以提高性能，而且避免弹出一个对话框的问题，因为它不会尝试用IE去解析文档。（使用老版本的PowerShell的话）
    $images = (Invoke-WebRequest -Uri "https://adoption.microsoft.com/microsoft-teams/custom-backgrounds-gallery/" -UseBasicParsing).Links.href | Where-Object { ($_ -like "https://adoption.azureedge.net/wp-content/custom-backgrounds-gallery*.jpg") -and (-not (Test-Path "$path\$(Split-Path $_ -Leaf)")) } | Select-Object -Unique 

    $wc = New-Object System.Net.WebClient
    $index = 1
    $count = $images.Count

    $images | ForEach-Object {
    
        $fileName = Split-Path $_ -Leaf
        $filePath = "$path\$fileName"
        # 使用web client可以明显提高性能
        $wc.DownloadFile($_, $filePath) 
        Write-Progress -Activity "Download Background image" -Status "Save file: $_" -PercentComplete ($index / $count * 100)

        # Invoke-WebRequest -Uri $_ -OutFile $filePath 
        GenerateThumbnail -filePath $filePath

        Write-Progress -Activity "Download Background image" -Status "Generate thumbnail: $fileName" -PercentComplete ($index / $count * 100)

        $index = $index + 1
    }
}


<#
.SYNOPSIS
    删除Teams客户端缓存
#>
function Remove-TeamsClientCache {
    [CmdletBinding(DefaultParameterSetName = 'default',
        SupportsShouldProcess = $true,
        PositionalBinding = $false,
        HelpUri = 'https://scripts.code365.xyz/code365scripts.teams/',
        ConfirmImpact = 'Medium')]
    [Alias()]
    Param ()
    
    begin {
        $res = Read-Host -Prompt "这个命令将退出当前的Teams，并且清理客户端缓存，是否继续【y/N】?"

        if ($res.ToLower() -ne "y") {
            return
        }

        $errorpreference = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
    }
    
    process {

        Get-Process | Where-Object { $_.ProcessName -eq "Teams" } | Stop-Process
        Remove-Item –path $env:APPDATA"\Microsoft\teams\cache\*" | Out-Null
        Remove-Item –path $env:APPDATA"\Microsoft\teams\blob_storage\*" | Out-Null
        Remove-Item –path $env:APPDATA"\Microsoft\teams\databases\*" | Out-Null
        Remove-Item –path $env:APPDATA"\Microsoft\teams\GPUcache\*" | Out-Null
        Remove-Item –path $env:APPDATA"\Microsoft\teams\IndexedDB\*" -recurse | Out-Null
        Remove-Item –path $env:APPDATA"\Microsoft\teams\Local Storage\*" -recurse | Out-Null
        Remove-Item –path $env:APPDATA"\Microsoft\teams\tmp\*" | Out-Null
        Remove-Item –path $env:APPDATA"\Microsoft\teams\Code Cache\*" -Recurse | Out-Null
        Remove-Item –path $env:APPDATA"\Microsoft\teams\backgrounds\*" -Recurse | Out-Null
        Write-Host "客户端缓存已经清理，请重新启动Teams客户端"
    }
    
    end {
        
        $ErrorActionPreference = $errorpreference
    }
}

<#
.SYNOPSIS
    批量添加用户到某个团队
.DESCRIPTION
    通过指定用户名或者从CSV中批量导入用户到某个团队。同时支持内部用户，和外部用户（作为来宾邀请加入），如果是内部用户的话，支持不带邮箱信息直接添加。
.EXAMPLE
    PS C:\> Import-TeamUser -teamName "开发测试" -users mike@xyz.com,tom@xyz.com
    用逗号分开不同的用户名,这里假定 mike@xyz.com 是内部用户，而 tom@abc.com 是外部用户。
.EXAMPLE
    PS C:\> Import-TeamUser -teamName "开发测试" -users mike@xyz.com,tom@abc.com -createTeam
    用指定的名称创建团队，然后导入用户。用逗号分开不同的用户名,这里假定 mike@xyz.com 是内部用户，而 tom@abc.com 是外部用户。
.EXAMPLE
    PS C:\> Import-TeamUser -teamName "开发测试" -users mike,tom
    用逗号分开不同的用户名，如果不带邮箱后缀，则自动以当前用户的邮箱后缀补充
.EXAMPLE
    PS C:\> Import-TeamUser -teamName "开发测试" -users (Import-Csv data.csv).email
    从CSV中导入用户，以上命令假设用户信息文件名为 data.csv, 并且在email这个列中保存了用户的邮箱地址（可以带公司的后缀，也可以不带）
#>
function Import-TeamUser {
    [CmdletBinding(DefaultParameterSetName = "default")]
    param (
        [Parameter(ParameterSetName = "default", Mandatory = $true)]
        [string]$teamName,
        [Parameter(ParameterSetName = "default", Mandatory = $true)]
        [string[]]$users,
        [Parameter(ParameterSetName = "default")]
        [switch]$createTeam
    )
    
    begin {
        $errorpreference = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
        EnsureRequiredModules -requiredModules @("MicrosoftTeams")
    }
    
    process {
        $connect = Connect-MicrosoftTeams
        if ($null -ne $connect) {
            $domain = $connect.Account.Id.split('@')[1]
            $tenantId = $connect.TenantId
        }
        else {
            Write-Host "无法连接到Teams，操作终止"
            return
        }

        if ($createTeam) {
            $team = New-Team -DisplayName $teamName
        }
        else {
            $team = Get-Team -DisplayName $teamName
        }

        if ($null -eq $team) {
            Write-Host "无法查找到该团队，请检查名称"
            return
        }

        $teamId = $team.GroupId
        $channel = Get-TeamChannel -GroupId $teamId | Where-Object { $_.DisplayName -in @("General", "常规") } | Select-Object -First 1
        $channelId = $channel.Id
        $inviteUrl = "https://teams.microsoft.com/l/team/$channelId/conversations?groupId=$teamId&tenantId=$tenantId"


        # 处理用户列表，如果有外部用户，则检查AzureAD模块是否安装
        $guests = $users | Where-Object { $_.Contains("@") -band $_.Split('@')[1] -ne $domain } 
        if ($null -ne $guests) {
            EnsureRequiredModules -requiredModules @("AzureAD")
            Connect-AzureAD

            foreach ($item in $guests) {
                New-AzureADMSInvitation -InvitedUserEmailAddress $item -InviteRedirectUrl $inviteUrl -SendInvitationMessage $true
                Start-Sleep -Seconds 2
            }
        }

        $index = 1
        $count = $users.Count
        
        foreach ($item in $users) {
            if (!($item.Contains("@"))) {
                $item += "@$domain"
            }


            Add-TeamUser -GroupId $team.GroupId -User $item -ErrorVariable e
            Write-Progress -Activity "批量导入用户" -Status $item -PercentComplete ($index++ / $count * 100)
            if ($null -eq $e.Message) {
                Write-Host "$item 导入成功"
            }
            else {
                Write-Host "$item 导入失败"
                Write-Host "$e.Message"
            }
        }
    }
    
    end {
        $ErrorActionPreference = $errorpreference
    }
}