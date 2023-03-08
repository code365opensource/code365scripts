#
# Module manifest for module 'code365scripts.teams'
#
# Generated by: arechen
#
# Generated on: 3/17/2021
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule           = '.\code365scripts.openai.psm1'

    # Version number of this module.
    ModuleVersion        = '1.0.4.8'

    # Supported PSEditions
    CompatiblePSEditions = @("Desktop")

    # ID used to uniquely identify this module
    GUID                 = '4948e170-d2aa-4f97-9cb2-fd0f0843e473'

    # Author of this module
    Author               = 'chenxizhang'

    # Company or vendor of this module
    CompanyName          = 'Code365'

    # Copyright statement for this module
    Copyright            = '(c) code365.xyz. All rights reserved.'

    # Description of the functionality provided by this module
    Description          = 'The non-official OpenAI PowerShell module. This module is used to interact with OpenAI API.`n1.0.4.8 Added error handling.'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion    = '5.1'

    # Name of the PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # ClrVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules      = @(@{ ModuleName = 'MicrosoftTeams'; ModuleVersion = '2.0.0' }, @{ModuleName = 'AzureAD'; ModuleVersion = '2.0.2.130' })

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess  = @("installdependency.ps1")

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport    = @("New-OpenAIConversation", "Get-OpenAILogs", "New-OpenAICompletion", "New-ChatGPTConversation")

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport      = @("New-OpenAIConversation", "Get-OpenAILogs", "New-OpenAICompletion", "New-ChatGPTConversation")

    # Variables to export from this module
    VariablesToExport    = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport      = @("oai", "gpt", "noc", "chatgpt", "chat")

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            Tags       = @("code365", "community", "china", "chenxizhang", "openai")

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/code365opensource/code365scripts'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/code365opensource/code365scripts/tree/master/code365scripts.openai'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            # ReleaseNotes = ''

            # Prerelease string of this module
            # Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false

            # External dependent modules of this module
            # ExternalModuleDependencies = @("MicrosoftTeams")

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    HelpInfoURI          = 'https://github.com/code365opensource/code365scripts/tree/master/code365scripts.openai'

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    # DefaultCommandPrefix = ''

}

