function New-OpenAIConversation {
    [CmdletBinding()]
    [Alias("oai")]
    param(
        [Parameter()][string]$api_key = $env:OPENAI_API_KEY,
        [Parameter()][string]$engine = "text-davinci-003",
        [Parameter()][int]$max_tokens = 1024
    )

    Write-Host "欢迎来到OpenAI的世界，请输入你的提示，按 q 退出."

    while ($true) {
        $prompt = Read-Host -Prompt "`n提示"

        if ($prompt -eq "q") {
            break
        }

        $params = @{
            Uri         = "https://api.openai.com/v1/completions"
            Method      = "POST"
            Body        = @{model = "$engine"; prompt = "$prompt"; max_tokens = $max_tokens } | ConvertTo-Json
            Headers     = @{"Authorization" = "Bearer $api_key" }
            ContentType = "application/json;charset=utf-8"
        }
        
        $response = (Invoke-WebRequest @params).Content | ConvertFrom-Json

        Write-Host $response.choices[0].text -ForegroundColor Green

    }
}