function New-OpenAIConversation {
    [CmdletBinding()]
    [Alias("oai")]
    param(
        [Parameter()][string]$api_key = $env:OPENAI_API_KEY,
        [Parameter()][string]$engine = "text-davinci-003",
        [Parameter()][string]$max_tokens = 1024
    )

    Write-Host "欢迎来到OpenAI的世界，请输入你的提示，按 q 退出.`n"

    while ($true) {
        $prompt = Read-Host -Prompt "提示"

        if ($prompt -eq "q") {
            break
        }

        $body = @{
            model      = $engine
            prompt     = $prompt
            max_tokens = $max_tokens
        } | ConvertTo-Json
        
        Invoke-WebRequest -Uri "https://api.openai.com/v1/completions" -Headers @{"Content-Type" = "application/json"; "Authorization" = "Bearer $api_key" } -Body $body

    }
}