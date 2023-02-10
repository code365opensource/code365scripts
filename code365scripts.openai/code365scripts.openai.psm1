﻿function New-OpenAIConversation {
    [CmdletBinding()]
    [Alias("oai")]
    param(
        [Parameter()][string]$api_key,
        [Parameter()][string]$engine = "text-davinci-003",
        [Parameter()][string]$endpoint = $env:OPENAI_ENDPOINT,
        [Parameter()][int]$max_tokens = 1024,
        [Parameter()][double]$temperature = 1,
        [Parameter()][switch]$azure
    )

    BEGIN {
        if ($azure) {
            $api_key = if ($api_key) { $api_key } else { if ($env:OPENAI_API_KEY_Azure) { $env:OPENAI_API_KEY_Azure } else { $env:OPENAI_API_KEY } }
            $endpoint = "{0}openai/deployments/{1}/completions?api-version=2022-12-01" -f $endpoint, $engine
        }
        else {
            $api_key = if ($api_key) { $api_key } else { $env:OPENAI_API_KEY }
            $endpoint = "https://api.openai.com/v1/completions"
        }

    }


    PROCESS {

        Write-Host ("`n欢迎来到OpenAI{0}的世界，请输入你的提示，按 q 并回车可退出对话, 按 m 并回车可输入多行文本， 按 f 并回车可从文件输入." -f $(if ($azure) { " (Azure版本) " } else { "" }))

        while ($true) {
            $prompt = Read-Host -Prompt "`n提示"

            if ($prompt -eq "q") {
                break
            }

            if ($prompt -eq "m") {
                # 这是用户想要输入多行文本
                $prompt = Read-MultiLineInputBoxDialog -Message "请输入多行文本" -WindowTitle "多行文本" -DefaultText ""
                if ($null -eq $prompt) {
                    Write-Host "你按下了取消按钮"
                    continue
                }
                else {
                    Write-Host "你输入的多行文本是：`n$prompt"
                }
            }

            if ($prompt -eq "f") {
                # 这是用户想要从文件输入
                $file = Read-OpenFileDialog -WindowTitle "请选择文件"
                if ($null -eq $file) {
                    Write-Host "你按下了取消按钮"
                    continue
                }
                else {
                    $prompt = Get-Content $file -Encoding utf8
                    Write-Host "你输入的多行文本是：`n$prompt"
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
            $result = $response.choices[0].text
            $total_tokens = $response.usage.total_tokens
            $prompt_tokens = $response.usage.prompt_tokens
            $completion_tokens = $response.usage.completion_tokens


            if ($PSVersionTable['PSVersion'].Major -eq 5) {
                $dstEncoding = [System.Text.Encoding]::GetEncoding('iso-8859-1')
                $srcEncoding = [System.Text.Encoding]::UTF8
                $result = $srcEncoding.GetString([System.Text.Encoding]::Convert($srcEncoding, $dstEncoding, $srcEncoding.GetBytes($result)))
            }
        

            Write-Host -ForegroundColor Red ("`n回答: - 消耗的token数量: {0} = {1} + {2}" -f $total_tokens, $prompt_tokens, $completion_tokens )
            Write-Host $result -ForegroundColor Green

        }

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
    $okButton.Text = "确定"
    $okButton.Add_Click({ $form.Tag = $textBox.Text; $form.Close() })

    # Create the Cancel button.
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Size(510, 250)
    $cancelButton.Size = New-Object System.Drawing.Size(75, 25)
    $cancelButton.Text = "取消"
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