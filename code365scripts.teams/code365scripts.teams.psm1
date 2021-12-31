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
            break
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
            break
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
            break
        }

        if ($createTeam) {
            $team = New-Team -DisplayName $teamName
        }
        else {
            $team = Get-Team -DisplayName $teamName
        }

        if ($null -eq $team) {
            Write-Host "无法查找到该团队，请检查名称"
            break
        }

        $teamId = $team.GroupId
        $channel = Get-TeamChannel -GroupId $teamId | Where-Object { $_.DisplayName -in @("General", "常规") } | Select-Object -First 1
        $channelId = $channel.Id
        $inviteUrl = "https://teams.microsoft.com/l/team/$channelId/conversations?groupId=$teamId&tenantId=$tenantId"


        # 处理用户列表，如果有外部用户，则检查AzureAD模块是否安装
        $guests = $users | Where-Object { $_.Contains("@") -band $_.Split('@')[1] -ne $domain } 
        if ($null -ne $guests) {
            EnsureRequiredModules -requiredModules @("AzureAD")
            Connect-AzureAD | Out-Null

            foreach ($item in $guests) {
                New-AzureADMSInvitation -InvitedUserEmailAddress $item -InviteRedirectUrl $inviteUrl -SendInvitationMessage $true | Out-Null
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

Function Get-RecursiveAzureAdGroupMemberUsers {
    [cmdletbinding()]
    param(
        [parameter(Mandatory = $True, ValueFromPipeline = $true)]$AzureGroup
    )
    Begin {
        If (-not(Get-AzureADCurrentSessionInfo)) { Connect-AzureAD }
    }
    Process {
        $Members = Get-AzureADGroupMember -ObjectId $AzureGroup.ObjectId -All $true
            
        $UserMembers = $Members | Where-Object { $_.ObjectType -eq 'User' }
        If ($Members | Where-Object { $_.ObjectType -eq 'Group' }) {
            [array]$UserMembers += $Members | Where-Object { $_.ObjectType -eq 'Group' } | ForEach-Object { Get-RecursiveAzureAdGroupMemberUsers -AzureGroup $_ }
        }
    }
    end {
        Return $UserMembers
    }
}


<#
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
#>
function Import-TeamsUserFromGroup {
    param (
        [Parameter(Mandatory = $true)][string]$TeamName,
        [Parameter(Mandatory = $true)][string]$GroupName,
        [switch]$createTeam
    )

    begin {
        $errorpreference = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
        EnsureRequiredModules -requiredModules @("MicrosoftTeams", "AzureAD")
    }

    process {
        Connect-MicrosoftTeams
        connect-AzureAD

        $group = Get-AzureADGroup -SearchString $GroupName

        if ($null -eq $group) {
            Write-Host "当前无法查找到这个组: $GroupName"
            break
        }

        if ($createTeam) {
            $team = New-Team -DisplayName $TeamName
        }
        else {
            $team = Get-Team -DisplayName $TeamName
        }

        if ($null -eq $team) {
            Write-Host "无法查找到该团队，请检查名称"
            break
        }

        $index = 1 
        $members = Get-RecursiveAzureAdGroupMemberUsers -AzureGroup $group
        $count = $members.Length

        $members | ForEach-Object {
            Add-TeamUser -GroupId $team.GroupId -User $_.UserPrincipalName
            Write-Progress -Activity "添加用户到 $TeamName" -Status $_.UserPrincipalName -PercentComplete ($index++ / $count * 100)
        }
    }

    end {
        $ErrorActionPreference = $errorpreference
    }
}

function checkAdmin() {
    return [bool](([System.Security.Principal.WindowsIdentity]::GetCurrent()).groups -match "S-1-5-32-544")
}

function testpaths($items) {
    foreach ($item in $items) {
        if ($false -eq (Test-Path $item)) {
            return $false
        }
    }
    return $true
}
<#
.SYNOPSIS
    设置Teams及相关前端项目本地开发证书环境
.DESCRIPTION
    支持生成新的证书，也支持重复利用现有证书
.EXAMPLE
    PS C:\> Set-LocalDevCertificate -appFolder xxxx
    生成新的证书，并修改相关的配置文件（.env文件，package.json文件等），这个操作需要管理员身份运行PowerShell。
.EXAMPLE
    PS C:\> Set-LocalDevCertificate
    为当前项目（目录），生成新的证书，并修改相关的配置文件（.env文件，package.json文件等），这个操作需要管理员身份运行PowerShell。
.EXAMPLE
    PS C:\> Set-LocalDevCertificate -appFolder xxxx -save
    生成新的证书，并修改相关的配置文件（.env文件，package.json文件等），这个操作需要管理员身份运行PowerShell。操作完后，把相关证书保存到用户的根目录，一般是 c:\users\xxxxx\.cert 这个目录中，以便下次使用。
.EXAMPLE
    PS C:\> Set-LocalDevCertificate -appFolder xxxx -existing
    复制现有的证书文件，并修改相关的配置文件（.env文件，package.json文件等），这个操作用普通用户身份就可以了。
 #>
function Set-LocalDevCertificate {
    [CmdletBinding(DefaultParameterSetName = "existing")]
    param (
        [parameter(ParameterSetName = "existing")]
        [parameter(ParameterSetName = "new")]
        [string]$appFolder = ".",
        [parameter(ParameterSetName = "existing")]
        [switch]$existing,
        [parameter(ParameterSetName = "new")]
        [switch]$save
    )
    
    begin {

        if ($existing) {
            # 利用现有的证书, 固定放在 $home 目录下面的.cert目录
            $isExisting = testpaths(@((Join-Path $HOME ".cert"), (Join-Path $HOME ".cert/localhost.pfx"), (Join-Path $HOME ".cert/localhost.pem"), (Join-Path $HOME ".cert/localhost-key.pem")))

            if ($false -eq $isExisting) {
                Write-Host "没有检查到目标目录（$home/.cert）中的合法文件，请确认"
                break
            }
        }
        else {
            $isadmin = checkAdmin

            if ($isadmin -eq $false) {
                Write-Host "这个操作涉及到创建证书，需要在管理员模式下运行，请退出"
                break;
            }

            $ChocoInstalled = $false
            if (Get-Command choco.exe -ErrorAction SilentlyContinue) {
                $ChocoInstalled = $true
            }

            if ($ChocoInstalled -eq $false) {
                Write-Host "正在安装choco 这个工具"
                Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
            }

            refreshenv

            $opensslInstalled = $false
            if (Get-Command openssl.exe -ErrorAction SilentlyContinue) {
                $opensslInstalled = $true
            }

            if ($opensslInstalled -eq $false) {
                Write-Host "正在安装openssl这个工具"
                choco install openssl.light -y

                Set-Alias -Name "openssl" -Value "C:\Program Files\OpenSSL\bin\openssl.exe"
            }
        }

    }
    
    process {

        if ($existing) {
            Copy-Item -Path (Join-Path $HOME ".cert") -Destination $appFolder -Recurse -Force
        }
        else {
            $certificate = New-SelfSignedCertificate -certstorelocation cert:\localmachine\my -dnsname localhost -NotAfter 2030-1-1
            $password = "code365xyz"
            $securePassword = ConvertTo-SecureString -String $password -Force -AsPlainText
            $outFolder = Join-Path $appFolder -ChildPath '.cert'
            if ($false -eq (Test-Path $outFolder)) {
                New-Item $outFolder -ItemType Directory | Out-Null
            }
            $pfxPath = Join-Path -Path $outFolder -ChildPath "localhost.pfx"
            Write-Host "生成$pfxPath"
            Export-PfxCertificate -Cert $certificate -FilePath $pfxPath -Password $securePassword | Out-Null
            Import-PfxCertificate -Password $securePassword -FilePath $pfxPath -CertStoreLocation Cert:\LocalMachine\Root | Out-Null

            if (Test-Path $pfxPath) {
                $keyPath = Join-Path $outFolder "localhost-key.pem"
                $certPath = Join-Path $outFolder "localhost.pem"
                Write-Host "生成$keyPath"
                openssl pkcs12 -in $pfxPath -nocerts -out $keyPath -nodes -passin pass:$password
                Write-Host "生成$certPath"
                openssl pkcs12 -in $pfxPath -nokeys -out $certPath -nodes -passin pass:$password
            }

            if ($save) {
                Write-Host "复制到当前用户的根目录 $home/.cert"
                Copy-Item -Path (Join-Path $appFolder ".cert") -Destination $HOME -Recurse -Force
            }

        }

        # 写入.env文件
        $envFile = Join-Path $appFolder ".env"
        if ($false -eq (Test-Path $envFile)) {
            New-Item $envFile | Out-Null
        }
        $dic = @{}
        Get-Content $envFile | ForEach-Object {
            $key, $value = $_.split("=")
            $dic[$key] = $value
        }

        $dic["HTTPS"] = "true"
        $dic["SSL_CRT_FILE"] = ".cert/localhost.pem"
        $dic["SSL_KEY_FILE"] = ".cert/localhost-key.pem"

        $out = @()
        $dic.Keys | ForEach-Object {
            $out += "$_=$($dic[$_])"
        }
        Write-Host "写入环境变量文件"
        $out | Out-File $envFile

        # 写入api目录下面的package.json 文件，如果有func start这个指令的话
        $package = Join-Path $appFolder "api/package.json"
        if (Test-Path $package) {
            $config = Get-Content $package | ConvertFrom-Json
            if ($null -ne $config.scripts.start -and $config.scripts.start.StartsWith("func start")) {
                $config.scripts.start = "func start --useHttps --cert ../.cert/localhost.pfx --password $password"
                Write-Host "写入api项目的package.json文件"
                $config | ConvertTo-Json | Out-File $package
            }


            $package = Join-Path $appFolder "package.json"

            if (Test-Path $package) {
                $config = Get-Content $package | ConvertFrom-Json
                if ($null -eq $config.proxy) {
                    $config | Add-Member -Name proxy -Value "https://localhost:7071" -MemberType NoteProperty
                    Write-Host "写入前端项目的package.json文件"
                    $config | ConvertTo-Json | Out-File $package
                }
            }
        }
    }
    end {
        
    }
}

<#
.SYNOPSIS
    创建单点登录应用
.DESCRIPTION
    创建单点登录应用（AAD 注册）
.EXAMPLE
    PS C:\> New-TeamsSSOAppliction -name "testapp" -url "https://www.testapp.com"
    创建单点登录应用，并自动授权Teams，Outlook，Office客户端可以访问。
 #>

function New-TeamsSSOAppliction {

    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True)][string]
        $name,
        [Parameter(Mandatory = $True)][string]
        $url
    )

    $account = Connect-AzureAD
    $user = Get-AzureADUser -SearchString $account.Account.Id

    $app = New-AzureADApplication -DisplayName $name -Oauth2AllowImplicitFlow $true -ReplyUrls "$url/auth-end"
    Add-AzureADMSApplicationOwner -ObjectId $app.ObjectId -RefObjectId $user.ObjectId
    $url = $url.Replace("https://", "").Replace("http://", "")

    Write-Host "ClientID: $($app.AppId)"
    Write-Host "Single-Sign-On URL: api://$url/$($app.AppId)"

    #expose an API
    Set-AzureADApplication -ObjectId $app.ObjectId -IdentifierUris "api://$url/$($app.AppId)"
    $apiApp = Get-AzureADMSApplication -ObjectId $app.ObjectId
    $permissionId = $apiApp.Api.Oauth2PermissionScopes[0].Id
    $apiApp.Api.PreAuthorizedApplications = New-Object 'System.Collections.Generic.List[Microsoft.Open.MSGraph.Model.PreAuthorizedApplication]'
    #preauthorize application
    $ids = "1fec8e78-bce4-4aaf-ab1b-5451cc387264", "5e3ce6c0-2b1f-4285-8d4b-75ee78787346", "4345a7b9-9a63-4910-a426-35363201d503", "4765445b-32c6-49b0-83e6-1d93765276ca", "0ec893e0-5785-4de6-99da-4ed124e5296c", "d3590ed6-52b3-4102-aeff-aad2292ab01c", "00000002-0000-0ff1-ce00-000000000000", "bc59ab01-8403-45c6-8796-ac3ef710b3e3"

    foreach ($item in $ids) {
        $preAuthorizedApplication1 = New-Object 'Microsoft.Open.MSGraph.Model.PreAuthorizedApplication'
        $preAuthorizedApplication1.AppId = $item
        $preAuthorizedApplication1.DelegatedPermissionIds = @($permissionId)
        $apiApp.Api.PreAuthorizedApplications.Add($preAuthorizedApplication1)
    }

    Set-AzureADMSApplication -ObjectId $app.ObjectId -Api $apiApp.Api
}
