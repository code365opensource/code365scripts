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
        HelpUri = 'http://www.microsoft.com/',
        ConfirmImpact = 'Medium')]
    [Alias()]
    [OutputType([String])]
    Param ()
    
    begin {
        $res = Read-Host -Prompt "这个命令将退出当前的Teams，并且清理客户端缓存，是否继续【y/N】?"

        if ($res.ToLower() -ne "y") {
            return
        }
    }
    
    process {
        $errorpreference = $ErrorActionPreference
        $ErrorActionPreference = "SilentlyContinue"
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
        $ErrorActionPreference = $errorpreference
    }
    
    end {
    }
}