# 导入本地化数据
Import-LocalizedData -FileName "resources.psd1" -BindingVariable "resources"

# 用当前日期生成的日志文件
$script:folder = "$env:APPDATA\code365scripts.openai"
if (!(Test-Path $script:folder)) {
    New-Item -ItemType Directory -Path $script:folder
}
$script:logfile = "$script:folder\OpenAI_{0}.log" -f (Get-Date -Format "yyyyMMdd")
# $updateflag = "$script:folder\updateflag.txt"

# 检查版本是否需要更新
$env:code365scripts_openai_needUpdate = $false
Start-Job -ScriptBlock {
    $version = (Find-Module code365scripts.openai).Version
    $current = (Get-Module code365scripts.openai -ListAvailable | Sort-Object -Property Version -Descending | Select-Object -First 1).Version
    $env:code365scripts_openai_needUpdate = ($version -ne $current)

    # Add-Content $using:updateflag -Value $env:code365scripts_openai_needUpdate
    # Add-Content $using:updateflag -Value $version
    # Add-Content $using:updateflag -Value $version
}


# 用于记录日志
function Write-Log([array]$message) {
    $message = "{0}`t{1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), ($message -join "`t")
    Add-Content $script:logfile -Value $message
}

function Test-Update() {
    if ($env:code365scripts_openai_needUpdate -eq $true) {
        $confirm = Read-Host $resources.update_prompt
        if ($confirm -eq "y") {
            if ($PSVersionTable['PSVersion'].Major -eq 5) {
                Update-Module code365scripts.openai -Force
                $env:code365scripts_openai_needUpdate = $false
            }
            else {
                Update-Module code365scripts.openai -Scope CurrentUser -Force
                $env:code365scripts_openai_needUpdate = $false
            }

            # Write-Host $resources.update_success
            Import-Module code365scripts.openai
            break
        }
    }
}


function New-OpenAICompletion {
    <#
    .EXTERNALHELP code365scripts.openai-help.xml
    .SYNOPSIS
        调用OpenAI 的Completion 接口并返回结果
    .DESCRIPTION
        同时支持OpenAI原生服务，和Azure OpenAI 服务
    .PARAMETER prompt
        你的提示文本
    .PARAMETER api_key
        OpenAI服务的密钥
    .PARAMETER engine
        模型名称
    .PARAMETER endpoint
        服务端点
    .PARAMETER max_tokens
        最大token的长度，不同的模型支持不同的长度，请参考官方文档，默认值是 1024
    .PARAMETER temperature
        该参数指定了模型的创造性指数，越接近1 的话，则表示可以返回更大创造性的结果。越接近0的话，则表示越返回稳定的结果。
    .PARAMETER n
        返回的结果个数，默认为1
    .PARAMETER azure
        是否使用Azure OpenAI服务
    .EXAMPLE
        New-OpenAICompletion -prompt "What's the capital of China"
        使用OpenAI原生服务查询中国的首都信息
    .EXAMPLE
        New-OpenAICompletion "What's the capital of China"
        使用OpenAI原生服务查询中国的首都信息(直接输入内容)
    .EXAMPLE
        "What's the capital of China" | New-OpenAICompletion
        使用OpenAI原生服务查询中国的首都信息，通过管道传递参数
    .EXAMPLE
        noc "What's the capital of China"
        使用OpenAI原生服务查询中国的首都信息(使用缩写)
    .EXAMPLE
        New-OpenAICompletion -prompt "What's the capital of China" -api_key "sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" -engine "text-davinci-003" -endpoint "https://api.openai.com/v1/completions"
        使用OpenAI原生服务查询中国的首都信息，通过参数指定api_key, engine, endpoint
    .EXAMPLE
        New-OpenAICompletion -prompt "What's the capital of China" -azure
        使用Azure OpenAI服务查询中国的首都信息
    .EXAMPLE
        New-OpenAICompletion -prompt "What's the capital of China" -azure -api_key "xxxxxxxxxxxxxxx" -engine "chenxizhang" -endpoint "https://chenxizhang.openai.azure.com/"
        使用Azure OpenAI服务查询中国的首都信息，通过参数指定api_key, engine, endpoint
    .EXAMPLE
        "What's the capital of China","韭菜炒蛋怎么做" | noc -azure
        使用Azure OpenAI服务查询中国的首都信息,以及如何做菜，通过管道传递参数
    .EXAMPLE
        Get-Children *.txt | Get-Content | noc -azure
        根据当前目录中的所有txt文件，使用Azure OpenAI服务查询对应的回复
    .LINK
        https://github.com/code365opensource/code365scripts/tree/master/code365scripts.openai
    #>

    [CmdletBinding()]
    [Alias("noc")]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)][string]$prompt,
        [Parameter()][string]$api_key,
        [Parameter()][string]$engine,
        [Parameter()][string]$endpoint,
        [Parameter()][int]$max_tokens = 1024,
        [Parameter()][double]$temperature = 1,
        [Parameter()][int]$n = 1,
        [Parameter()][switch]$azure
    )

    BEGIN {

        Test-Update # 检查更新

        if ($azure) {
            $api_key = if ($api_key) { $api_key } else { if ($env:OPENAI_API_KEY_Azure) { $env:OPENAI_API_KEY_Azure } else { $env:OPENAI_API_KEY } }
            $engine = if ($engine) { $engine } else { $env:OPENAI_ENGINE_Azure }
            $endpoint = "{0}openai/deployments/{1}/completions?api-version=2022-12-01" -f $(if ($endpoint) { $endpoint }else { $env:OPENAI_ENDPOINT_Azure }), $engine
        }
        else {
            $api_key = if ($api_key) { $api_key } else { $env:OPENAI_API_KEY }
            $engine = if ($engine) { $engine } else { if ($env:OPENAI_ENGINE) { $env:OPENAI_ENGINE }else { "text-davinci-003" } }
            $endpoint = if ($endpoint) { $endpoint } else { if ($env:OPENAI_ENDPOINT) { $env:OPENAI_ENDPOINT }else { "https://api.openai.com/v1/completions" } }
        }


        $hasError = $false

        if (!$api_key) {
            Write-Host $resources.error_missing_api_key -ForegroundColor Red
            $hasError = $true
        }

        if (!$engine) {
            Write-Host $resources.error_missing_engine -ForegroundColor Red
            $hasError = $true
        }

        if (!$endpoint) {
            Write-Host $resources.error_missing_endpoint -ForegroundColor Red
            $hasError = $true
        }

        if ($hasError) {
            break
        }
    }

    PROCESS {
    
        $params = @{
            Uri         = $endpoint
            Method      = "POST"
            Body        = @{
                model       = "$engine"
                prompt      = "$prompt"
                max_tokens  = $max_tokens
                temperature = $temperature
                n           = $n
            } | ConvertTo-Json
            Headers     = if ($azure) { @{"api-key" = "$api_key" } } else { @{"Authorization" = "Bearer $api_key" } }
            ContentType = "application/json;charset=utf-8"
        }
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $response = Invoke-RestMethod @params
        $stopwatch.Stop()
        $total_tokens = $response.usage.total_tokens
        $prompt_tokens = $response.usage.prompt_tokens
        $completion_tokens = $response.usage.completion_tokens

        if ($PSVersionTable['PSVersion'].Major -eq 5) {
            $dstEncoding = [System.Text.Encoding]::GetEncoding('iso-8859-1')
            $srcEncoding = [System.Text.Encoding]::UTF8

            $response.choices | ForEach-Object {
                $_.text = $srcEncoding.GetString([System.Text.Encoding]::Convert($srcEncoding, $dstEncoding, $srcEncoding.GetBytes($_.text)))
            }
        }
        

        Write-Log -message $stopwatch.ElapsedMilliseconds, $total_tokens, $prompt_tokens, $completion_tokens
        Write-Output $response

    }

}

function New-OpenAIConversation {
    <#
    .EXTERNALHELP code365scripts.openai-help.xml
    .SYNOPSIS
        使用OpenAI服务进行对话
    .DESCRIPTION
        使用OpenAI服务进行对话, 支持单行文本，多行文本，以及从文件中读取文本
    .EXAMPLE
        New-OpenAIConversation
        使用OpenAI服务进行对话，全部使用默认参数
    .EXAMPLE
        New-OpenAIConversation -azure
        使用Azure OpenAI服务进行对话, 全部使用默认参数
    .EXAMPLE
        gpt
        使用OpenAI服务进行对话，全部使用默认参数
    .EXAMPLE
        gpt -azure
        使用Azure OpenAI服务进行对话, 全部使用默认参数
    .EXAMPLE
        gpt -api_key $api_key -engine $engine
        使用OpenAI服务进行对话，使用指定的参数
    .EXAMPLE
        gpt -api_key $api_key -engine $engine -endpoint $endpoint -azure
        使用Azure OpenAI服务进行对话，使用指定的参数
    .EXAMPLE
        gpt -api_key $api_key -engine $engine -endpoint $endpoint -azure -max_tokens 1024 -temperature 1 -n 1
        使用Azure OpenAI服务进行对话，使用指定的参数
    .PARAMETER api_key
        OpenAI服务的API Key, 如果没有设置环境变量 OPENAI_API_KEY 或 OPENAI_API_KEY_AZURE，则必须使用该参数
    .PARAMETER engine
        OpenAI服务的引擎, 如果没有设置环境变量 OPENAI_ENGINE 或 OPENAI_ENGINE_AZURE，则必须使用该参数
    .PARAMETER endpoint
        OpenAI服务的Endpoint, 如果没有设置环境变量 OPENAI_ENDPOINT 或 OPENAI_ENDPOINT_AZURE，则必须使用该参数
    .PARAMETER max_tokens
        生成的文本最大长度, 默认为1024
    .PARAMETER temperature
        生成的文本的创造性指数, 默认为1
    .PARAMETER azure
        是否使用Azure OpenAI服务
    .Link
        https://github.com/code365opensource/code365scripts/tree/master/code365scripts.openai
    #>


    [CmdletBinding()]
    [Alias("oai")][Alias("gpt")]
    param(
        [Parameter()][string]$api_key,
        [Parameter()][string]$engine,
        [Parameter()][string]$endpoint,
        [Parameter()][int]$max_tokens = 1024,
        [Parameter()][double]$temperature = 1,
        [Parameter()][switch]$azure
    )

    BEGIN {

        Test-Update # 检查更新

        if ($azure) {
            $api_key = if ($api_key) { $api_key } else { if ($env:OPENAI_API_KEY_Azure) { $env:OPENAI_API_KEY_Azure } else { $env:OPENAI_API_KEY } }
            $engine = if ($engine) { $engine } else { $env:OPENAI_ENGINE_Azure }
            $endpoint = "{0}openai/deployments/{1}/completions?api-version=2022-12-01" -f $(if ($endpoint) { $endpoint }else { $env:OPENAI_ENDPOINT_Azure }), $engine
        }
        else {
            $api_key = if ($api_key) { $api_key } else { $env:OPENAI_API_KEY }
            $engine = if ($engine) { $engine } else { if ($env:OPENAI_ENGINE) { $env:OPENAI_ENGINE }else { "text-davinci-003" } }
            $endpoint = if ($endpoint) { $endpoint } else { if ($env:OPENAI_ENDPOINT) { $env:OPENAI_ENDPOINT }else { "https://api.openai.com/v1/completions" } }
        }


        $hasError = $false

        if (!$api_key) {
            Write-Host $resources.error_missing_api_key -ForegroundColor Red
            $hasError = $true
        }

        if (!$engine) {
            Write-Host $resources.error_missing_engine -ForegroundColor Red
            $hasError = $true
        }

        if (!$endpoint) {
            Write-Host $resources.error_missing_endpoint -ForegroundColor Red
            $hasError = $true
        }

        if ($hasError) {
            break
        }
    }


    PROCESS {
        
        $index = 1; # 用来保存问答的序号

        $welcome = "`n{0}`n{1}" -f ($resources.welcome -f $(if ($azure) { " $($resources.azure_version) " } else { "" }), $engine), $resources.shortcuts
        
        Write-Host $welcome -ForegroundColor Yellow

        while ($true) {
            $current = $index++
            $prompt = Read-Host -Prompt "`n[$current] $($resources.prompt)"
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

            if ($prompt -eq "q") {
                break
            }

            if ($prompt -eq "m") {
                # 这是用户想要输入多行文本
                $prompt = Read-MultiLineInputBoxDialog -Message $resources.multi_line_prompt -WindowTitle $resources.multi_line_prompt -DefaultText ""
                if ($null -eq $prompt) {
                    Write-Host $resources.cancel_button_message
                    continue
                }
                else {
                    Write-Host "$($resources.multi_line_message)`n$prompt"
                }
            }

            if ($prompt -eq "f") {
                # 这是用户想要从文件输入
                $file = Read-OpenFileDialog -WindowTitle $resources.file_prompt

                if (!($file)) {
                    Write-Host $resources.cancel_button_message
                    continue
                }
                else {
                    $prompt = Get-Content $file -Encoding utf8
                    Write-Host "$($resources.multi_line_message)`n$prompt"
                }
            }

            $params = @{
                Uri         = $endpoint
                Method      = "POST"
                Body        = @{model = "$engine"; prompt = "$prompt"; max_tokens = $max_tokens; temperature = $temperature } | ConvertTo-Json
                Headers     = if ($azure) { @{"api-key" = "$api_key" } } else { @{"Authorization" = "Bearer $api_key" } }
                ContentType = "application/json;charset=utf-8"
            }

            $response = Invoke-RestMethod @params
            $stopwatch.Stop()
            $result = $response.choices[0].text
            $total_tokens = $response.usage.total_tokens
            $prompt_tokens = $response.usage.prompt_tokens
            $completion_tokens = $response.usage.completion_tokens


            if ($PSVersionTable['PSVersion'].Major -eq 5) {
                $dstEncoding = [System.Text.Encoding]::GetEncoding('iso-8859-1')
                $srcEncoding = [System.Text.Encoding]::UTF8
                $result = $srcEncoding.GetString([System.Text.Encoding]::Convert($srcEncoding, $dstEncoding, $srcEncoding.GetBytes($result)))
            }
        

            Write-Host -ForegroundColor Red ("`n[$current] $($resources.response)" -f $total_tokens, $prompt_tokens, $completion_tokens )
            Write-Host $result -ForegroundColor Green

            Write-Log -message $stopwatch.ElapsedMilliseconds, $total_tokens, $prompt_tokens, $completion_tokens
        }

    }
}

function Get-OpenAILogs([switch]$all) {
    # .EXTERNALHELP code365scripts.openai-help.xml

    Test-Update # 检查更新
    
    if ($all) {
        Get-ChildItem -Path $script:folder | Get-Content | ConvertFrom-Csv -Delimiter "`t" -Header Time, Duration, TotalTokens, PromptTokens, CompletionTokens | Format-Table
    }
    else {
        Get-Content $script:logfile | ConvertFrom-Csv -Delimiter "`t" -Header Time, Duration, TotalTokens, PromptTokens, CompletionTokens | Format-Table
    }
}

function Read-OpenFileDialog([string]$WindowTitle, [string]$InitialDirectory, [string]$Filter = "All files (*.*)|*.*", [switch]$AllowMultiSelect) {
    Add-Type -AssemblyName System.Windows.Forms
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.Title = $WindowTitle
    if (![string]::IsNullOrWhiteSpace($InitialDirectory)) { $openFileDialog.InitialDirectory = $InitialDirectory }
    $openFileDialog.Filter = $Filter
    if ($AllowMultiSelect) { $openFileDialog.MultiSelect = $true }
    $openFileDialog.ShowHelp = $true    # Without this line the ShowDialog() function may hang depending on system configuration and running from console vs. ISE.
    $openFileDialog.ShowDialog() > $null
    if ($AllowMultiSelect) { return $openFileDialog.Filenames } else { return $openFileDialog.Filename }
}

function Read-MultiLineInputBoxDialog([string]$Message, [string]$WindowTitle, [string]$DefaultText) {
    <#
    .SYNOPSIS
    Prompts the user with a multi-line input box and returns the text they enter, or null if they cancelled the prompt.

    .DESCRIPTION
    Prompts the user with a multi-line input box and returns the text they enter, or null if they cancelled the prompt.

    .PARAMETER Message
    The message to display to the user explaining what text we are asking them to enter.

    .PARAMETER WindowTitle
    The text to display on the prompt window's title.

    .PARAMETER DefaultText
    The default text to show in the input box.

    .EXAMPLE
    $userText = Read-MultiLineInputDialog "Input some text please:" "Get User's Input"

    Shows how to create a simple prompt to get mutli-line input from a user.

    .EXAMPLE
    # Setup the default multi-line address to fill the input box with.
    $defaultAddress = @'
    John Doe
    123 St.
    Some Town, SK, Canada
    A1B 2C3
    '@

    $address = Read-MultiLineInputDialog "Please enter your full address, including name, street, city, and postal code:" "Get User's Address" $defaultAddress
    if ($address -eq $null)
    {
        Write-Error "You pressed the Cancel button on the multi-line input box."
    }

    Prompts the user for their address and stores it in a variable, pre-filling the input box with a default multi-line address.
    If the user pressed the Cancel button an error is written to the console.

    .EXAMPLE
    $inputText = Read-MultiLineInputDialog -Message "If you have a really long message you can break it apart`nover two lines with the powershell newline character:" -WindowTitle "Window Title" -DefaultText "Default text for the input box."

    Shows how to break the second parameter (Message) up onto two lines using the powershell newline character (`n).
    If you break the message up into more than two lines the extra lines will be hidden behind or show ontop of the TextBox.

    .NOTES
    Name: Show-MultiLineInputDialog
    Author: Daniel Schroeder (originally based on the code shown at http://technet.microsoft.com/en-us/library/ff730941.aspx)
    Version: 1.0
#>
    Add-Type -AssemblyName System.Drawing
    Add-Type -AssemblyName System.Windows.Forms

    # Create the Label.
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Size(10, 10)
    $label.Size = New-Object System.Drawing.Size(280, 20)
    $label.AutoSize = $true
    $label.Text = $Message

    # Create the TextBox used to capture the user's text.
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Size(10, 40)
    $textBox.Size = New-Object System.Drawing.Size(575, 200)
    $textBox.AcceptsReturn = $true
    $textBox.AcceptsTab = $false
    $textBox.Multiline = $true
    $textBox.ScrollBars = 'Both'
    $textBox.Text = $DefaultText

    # Create the OK button.
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Size(415, 250)
    $okButton.Size = New-Object System.Drawing.Size(75, 25)
    $okButton.Text = $resources.dialog_okbutton_text
    $okButton.Add_Click({ $form.Tag = $textBox.Text; $form.Close() })

    # Create the Cancel button.
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Size(510, 250)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 25)
    $cancelButton.Text = $resources.dialog_cancelbutton_text
    $cancelButton.Add_Click({ $form.Tag = $null; $form.Close() })

    # Create the form.
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $WindowTitle
    $form.Size = New-Object System.Drawing.Size(610, 320)
    $form.FormBorderStyle = 'FixedSingle'
    $form.StartPosition = "CenterScreen"
    $form.AutoSizeMode = 'GrowAndShrink'
    $form.Topmost = $True
    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton
    $form.ShowInTaskbar = $true

    # Add all of the controls to the form.
    $form.Controls.Add($label)
    $form.Controls.Add($textBox)
    $form.Controls.Add($okButton)
    $form.Controls.Add($cancelButton)

    # Initialize and show the form.
    $form.Add_Shown({ $form.Activate() })
    $form.ShowDialog() > $null  # Trash the text of the button that was clicked.

    # Return the text that the user entered.
    return $form.Tag
}