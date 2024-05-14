function Install-Apps {
    param([string[]]$apps)

    # Log the runtime
    $logFile = Join-Path $env:USERPROFILE "InstallApps.log"
    Add-Content -Path $logFile -Value "$(Get-Date) - Start installing apps"

    # Install winget 
    $progressPreference = 'silentlyContinue'
    Write-Information "Downloading WinGet and its dependencies..."
    Invoke-WebRequest -Uri https://aka.ms/getwinget -OutFile Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
    Invoke-WebRequest -Uri https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx -OutFile Microsoft.VCLibs.x64.14.00.Desktop.appx
    Invoke-WebRequest -Uri https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.x64.appx -OutFile Microsoft.UI.Xaml.2.8.x64.appx
    Add-AppxPackage Microsoft.VCLibs.x64.14.00.Desktop.appx
    Add-AppxPackage Microsoft.UI.Xaml.2.8.x64.appx
    Add-AppxPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle
    Add-Content -Path $logFile -Value "$(Get-Date) - Finish installing winget"

    # Install apps
    foreach ($app in $apps) {
        # Log the app installation
        Add-Content -Path $logFile -Value "$(Get-Date) - Installing $app"
        winget install $app -h --accept-package-agreements --accept-source-agreements
    }

    # Log the runtime
    Add-Content -Path $logFile -Value "$(Get-Date) - Finish installing apps"
}