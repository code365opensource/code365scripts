# 添加中文输入法
$languagelist = Get-WinUserLanguageList
$languagelist.add("zh-CN")
Set-WinUserLanguageList $languagelist -Force

# 设置默认输入法为中文
Set-WinDefaultInputMethodOverride -InputTip "0804:{81D4E9C9-1D3B-41BC-9E6C-4B40BF79E35E}{FA550B04-5AD7-411F-A5AC-CA038EC515D7}"


# 设置输入法默认为英文

Push-Location
Set-Location HKCU:\SOFTWARE\Microsoft\InputMethod\Settings\CHS
Set-ItemProperty . "Default Mode" "1"
Pop-Location

# 输入法字体设置大一些
Push-Location
Set-Location HKCU:\SOFTWARE\Microsoft\InputMethod\CandidateWindow\CHS\1
Set-ItemProperty . FontStyle "32.00pt;Regular;;Microsoft YaHei UI"
Set-ItemProperty . "Default Mode" "1"
Pop-Location