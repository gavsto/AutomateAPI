function Set-CredentialsLocallyStored {
    <#
.SYNOPSIS
   Sets credential objects on a server that has never had them before

.DESCRIPTION
   This function takes a Powershell script and sets credentials on the local disk encrypted with the local system

.EXAMPLE
   Set-CredentialsLocallyStored -Automate

.EXAMPLE
   Set-CredentialsLocallyStored -ITGlue

.EXAMPLE
   Set-CredentialsLocallyStored -MySQL

.EXAMPLE
   Set-CredentialsLocallyStored -Office365

.Example
   Set-CredentialsLocallyStored -Custom -CredentialPath "C:\Credentials\Custom Credentials.txt"

#>
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName="Automate")]
        [switch]$Automate,

        [Parameter(ParameterSetName="All")]
        [switch]$All,

        [Parameter(ParameterSetName="Control")]
        [switch]$Control,

        [Parameter(ParameterSetName="Custom",Mandatory=$True)]
        [switch]$Custom,

        [Parameter(ParameterSetName="Custom",Mandatory=$True)]
        [string]$CredentialDisplayName,

        [Parameter(ParameterSetName = 'Automate')]
        [Parameter(ParameterSetName = 'Control')]
        [Parameter(ParameterSetName = "Custom",Mandatory=$True)]      
        [string]$CredentialDirectory = "$($env:USERPROFILE)\AutomateAPI\"
    )

    if ($All) {
        $Automate = $True
        $Control = $True
    }

    if (-not (Test-Path $CredentialDirectory)) {
        New-Item -ItemType Directory -Force -Path $CredentialDirectory | ForEach-Object{$_.Attributes = "hidden"}
    }


    if ($Automate) {
        $CredentialPath = "$($CredentialDirectory)Automate - Credentials.txt"

        $TempAutomateServer = Read-Host -Prompt "Please enter your Automate Server address, without the HTTPS, IE: rancor.hostedrmm.com" 
        $TempAutomateUsername = Read-Host -Prompt "Please enter your Automate Username"
        $TempAutomatePassword = Read-Host -Prompt "Please enter your Automate Password" -AsSecureString
        $TempAutomatePassword = $TempAutomatePassword | ConvertFrom-SecureString
        
        Set-Content "$CredentialPath" $TempAutomateUsername -Force
        Add-Content "$CredentialPath" $TempAutomatePassword
        Add-Content "$CredentialPath" $TempAutomateServer
        Write-Output "Automate Credentials Set"
    }

    if ($Control) {
        $CredentialPath = "$($CredentialDirectory)Control - Credentials.txt"

        $TempControlServer = Read-Host -Prompt "Please enter your Control Server address, the full URL. IE https://control.rancorthebeast.com:8040" 
        $TempControlUsername = Read-Host -Prompt "Please enter your Control Username"
        $TempControlPassword = Read-Host -Prompt "Please enter your Control Password" -AsSecureString
        $TempControlPassword = $TempControlPassword | ConvertFrom-SecureString
        
        Set-Content "$CredentialPath" $TempControlUsername -Force
        Add-Content "$CredentialPath" $TempControlPassword 
        Add-Content "$CredentialPath" $TempControlServer 
        Write-Output "Control Credentials Set"
    }

    if ($Custom) {
        $CredentialPath = "$($CredentialDirectory)\$($CredentialDisplayName).txt"
        $CustomCredentials = Get-Credential -Message "Please enter the Custom Username and Password to store"
        $CustomUsername = $CustomCredentials.UserName
        $CustomPasswordSecureString = $CustomCredentials.Password
        $CustomPassword = $CustomPasswordSecureString | ConvertFrom-SecureString
        
        Set-Content "$CredentialPath" $CustomUsername -Force
        Add-Content "$CredentialPath" $CustomPassword
        Write-Output "Custom Credentials Set"
    }

}