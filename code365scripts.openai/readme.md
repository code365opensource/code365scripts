# OpenAI 模块

[![PowerShell Gallery Version](https://img.shields.io/powershellgallery/v/code365scripts.openai?label=code365scripts.openai)](https://www.powershellgallery.com/packages/code365scripts.openai) [![PowerShell Gallery](https://img.shields.io/powershellgallery/dt/code365scripts.openai)](https://www.powershellgallery.com/packages/code365scripts.openai)

### 如何安装

打开 PowerShell 窗口，运行 `Install-Module code365scripts.openai`，如果此前已经安装过，请运行 `Update-Module code365scripts.openai`

### 功能介绍

这个模块是对OpenAI服务的封装，以便在桌面电脑中，更加方便地调用它们。目前同时支持OpenAI原生服务，以及微软Azure OpenAI 服务。

### 前期准备

为了进行使用，你需要准备好 OpenAI 服务的密钥。OpenAI原生服务的密钥，你可以通过如下页面找到。

![image](https://user-images.githubusercontent.com/1996954/218254458-efc867cc-f34c-4315-9dfb-823e923641ee.png)

如果是用Azure OpenAI，还需要准备好服务端点和你的模型的名称。在下图位置可以找到 Key 和 Endpoint信息。

![image](https://user-images.githubusercontent.com/1996954/218254252-91dc617b-f706-4249-9455-d8e95baa30e0.png)

你的模型，则通过下图可以找到。

![image](https://user-images.githubusercontent.com/1996954/218254283-0e89b3cd-e72c-4e0e-a069-ea63155ab095.png)

接下来，建议你把有关的密钥等信息保存在环境变量中，这样后续使用就很简单，不需要每次都指定。

如果你是用OpenAI原生服务，则只需要提供api_key即可。请继续在PowerShell 命令行中执行下面的代码。

```powershell
SETX OPENAI_API_KEY "你的密钥"
# 下面这个是可选的，如果不设置，则默认使用 text-davinci-003
SETX OPENAI_ENGINE "你的默认模型"
```

如果你是用Azure OpenAI的GPT3服务，则需要提供多几个环境变量。

```powershell
SETX OPENAI_API_KEY_AZURE "你的密钥"
SETX OPENAI_ENGINE_AZURE "你的模型"
SETX OPENAI_ENDPOINT_AZURE "你的服务地址"
```

下图是我机器上面的情况，因为我同时在用OpenAI 原生的服务，和Azure OpenAI 服务，所以变量比较多。

![image](https://user-images.githubusercontent.com/1996954/218254581-ef22020f-7edc-4e73-825b-2a0a5bd8738a.png)

**请注意，关闭一下PowerShell窗口，然后重新打开，以便读取这些环境变量。**

### 功能介绍

1. New-OpenAICompletion  （别名：noc )

    这个函数可以发起一个 Completion 接口的调用并且返回结果。它有8个参数，但只有第一个 prompt 是可选的，而且这个参数可以直接指定，并且还接受直接从前序管道传递。
    
    ![image](https://user-images.githubusercontent.com/1996954/218255326-079d906d-0169-4d1a-a629-a52674194125.png)

    New-OpenAICompletion [-prompt] <string> [-api_key <string>] [-engine <string>] [-endpoint <string>] [-max_tokens
        <int>] [-temperature <double>] [-n <int>] [-azure] [<CommonParameters>]

    用法：
          # 使用prompt 参数输入文字
          New-OpenAICompletion -prompt "What's the capital of China"

          # 直接输入文字
          New-OpenAICompletion "中国的首都是哪个城市" 

          # 使用缩写的快捷用法
          noc "What's the capital of China"

          # 使用缩写，并指定 prompt
          noc -prompt "中国的首都是哪个城市"

          # 一次性查询两个输入
          "中国的首都是哪个城市","What's the capital of China" | noc

          # 使用Azure OpenAI 服务查询
          "中国的首都是哪个城市","What's the capital of China" | noc -azure 

          # 当然你完全可以指定其他的参数，
          noc "帮我写一个100字以内的感谢信" -api_key xxxxxx -engine "text-ada-001" -max_tokens 200 -temperature 0.5 -n 10
     

1. New-OpenAICoversation (别名 gpt 或 oai）
    
    这个函数可以建立一个聊天机器人界面，以便你可以一直输入内容，并且得到答复，而不需要每次都去调用 New-OpenAICompletion 这个方法。请注意，默认是单行输入，但通过输入 m 回车后即可多行输入，而 输入 f 回车后可以选择磁盘上的整个文件作为输入。
          
    ![image](https://user-images.githubusercontent.com/1996954/218255231-eefc5219-e7b6-4683-bb19-f8ec91463913.png)
   
    它有如下的参数，并且所有参数都是可选的。
          
    New-OpenAIConversation [[-api_key] <string>] [[-engine] <string>] [[-endpoint] <string>] [[-max_tokens] <int>]
    [[-temperature] <double>] [-azure] [<CommonParameters>]
          
    用法：
        
          # 使用OpenAI 原生服务启动对话机器人
          gpt
          
          # 使用Azure OpenAI 服务启动对话机器人
          gpt -azure
          
          # 当然其他函数都是可以指定的，而且都是对应了OpenAI 接口定义，其中 max_tokens 的默认值是 1024， temperature 的默认值是 1。

1. New-ChatGPTConversation (别名 chatgpt 或 chat）
    
    这个函数可以建立一个基于ChatGPT的聊天机器人界面，以便你可以一直输入内容，并且得到答复。请注意，默认是单行输入，但通过输入 m 回车后即可多行输入，而 输入 f 回车后可以选择磁盘上的整个文件作为输入。
    
    ![image](https://user-images.githubusercontent.com/1996954/222958989-b5ebfa89-7473-4946-a32c-470b9e2b7926.png)

         
    它有如下的参数，并且所有参数都是可选的。
    New-ChatGPTConversation [[-api_key] <string>] [[-engine] <string>] [-azure]      
    
          
    用法：
        
          # 使用ChatGPT原生服务启动对话机器人
          chatgpt
          
          # 使用Azure ChatGPT 服务启动对话机器人 【目前其实并不支持，但我先设置好了这个参数】
          chatgpt -azure
          
          # 当然其他函数都是可以指定的，而且都是对应了ChatGPT 接口定义。
          
1. Get-OpenAILogs

    这个函数用来显示日志信息。这个模块每天会产生一个日志文件，里面记录了时间，调用时长（毫秒），总的tokens，输入文本占用的tokens，返回值占用的tokens。
          
    ![image](https://user-images.githubusercontent.com/1996954/218255550-8b0e071d-8888-40b2-ab27-b93c6a3734b0.png)

    该函数带有一个可选的参数 （all），如果启用该参数则会返回所有的日志。
          
    Get-OpenAILogs [-all]
    
    用法：
          
          # 显示当天的日志
          Get-OpenAILogs
          
          # 显示所有的日志
          Get-OpenAILogs -all
          
