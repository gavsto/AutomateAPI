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
        [Parameter(ParameterSetName = 'All')]
        [switch]$Save,

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
        $StoreVariables = @(
            @{'Name' = 'CWAServer'; 'Scope' = 'Script'},
            @{'Name' = 'CWACredentials'; 'Scope' = 'Script'},
            @{'Name' = 'CWATokenKey'; 'Scope' = 'Script'},
            @{'Name' = 'CWATokenInfo'; 'Scope' = 'Script'}
        )
        $StoreBlock = [pscustomobject]@{}
        $CredentialPath = "$($CredentialDirectory)Automate - Credentials.txt"

        If ($Save) {
            Foreach ($SaveVar in $StoreVariables) {
                If (!(Get-Variable @SaveVar -ErrorAction 0)) {Continue}
                If ($SaveVar.Name -match 'Credential') {
                    $Null = $StoreBlock | Add-Member -NotePropertyName $($SaveVar.Name) -NotePropertyValue @{'UserName'=(Get-Variable @SaveVar -ValueOnly).UserName; 'Password'=((Get-Variable @SaveVar -ValueOnly).Password|ConvertFrom-SecureString)}
                } ElseIf ($SaveVar.Name -match 'Key') {
                    $Null = $StoreBlock | Add-Member -NotePropertyName $($SaveVar.Name) -NotePropertyValue (Get-Variable @SaveVar -ValueOnly|ConvertFrom-SecureString)
                } Else {
                    $Null = $StoreBlock | Add-Member -NotePropertyName $($SaveVar.Name) -NotePropertyValue (Get-Variable @SaveVar -ValueOnly)
                }
            }
        } Else {
            $TempAutomateServer = Read-Host -Prompt "Please enter your Automate Server address, without the HTTPS, IE: rancor.hostedrmm.com" 
            $TempAutomateUsername = Read-Host -Prompt "Please enter your Automate Username"
            $TempAutomatePassword = Read-Host -Prompt "Please enter your Automate Password" -AsSecureString
#            $TempAutomatePassword = $TempAutomatePassword | ConvertFrom-SecureString
            $Null = $StoreBlock | Add-Member -NotePropertyName 'CWAServer' -NotePropertyValue $TempAutomateServer
            $Null = $StoreBlock | Add-Member -NotePropertyName 'CWACredentials' -NotePropertyValue @{'UserName'=$TempAutomateUsername; 'Password'=($TempAutomatePassword | ConvertFrom-SecureString)}
        }

        $StoreBlock | ConvertTo-JSON -Depth 10 | Out-File -FilePath $CredentialPath -Force -NoNewline

#        Set-Content "$CredentialPath" $TempAutomateUsername -Force
#        Add-Content "$CredentialPath" $TempAutomatePassword
#        Add-Content "$CredentialPath" $TempAutomateServer
        Write-Output "Automate Credentials Set"
    }

    if ($Control) {
        $StoreVariables = @(
            @{'Name' = 'ControlAPICredentials'; 'Scope' = 'Script'},
            @{'Name' = 'ControlServer'; 'Scope' = 'Script'},
            @{'Name' = 'ControlAPIKey'; 'Scope' = 'Script'}
        )
        $StoreBlock = [pscustomobject]@{}
        $CredentialPath = "$($CredentialDirectory)Control - Credentials.txt"

        If ($Save) {
            Foreach ($SaveVar in $StoreVariables) {
                If (!(Get-Variable @SaveVar -ErrorAction 0)) {Continue}
                If ($SaveVar.Name -match 'Credential') {
                    $Null = $StoreBlock | Add-Member -NotePropertyName $($SaveVar.Name) -NotePropertyValue @{'UserName'=(Get-Variable @SaveVar -ValueOnly).UserName; 'Password'=((Get-Variable @SaveVar -ValueOnly).Password|ConvertFrom-SecureString)}
                } ElseIf ($SaveVar.Name -match 'Key') {
                    $Null = $StoreBlock | Add-Member -NotePropertyName $($SaveVar.Name) -NotePropertyValue (Get-Variable @SaveVar -ValueOnly|ConvertFrom-SecureString)
                } Else {
                    $Null = $StoreBlock | Add-Member -NotePropertyName $($SaveVar.Name) -NotePropertyValue (Get-Variable @SaveVar -ValueOnly)
                }
            }
        } Else {
            $TempControlServer = Read-Host -Prompt "Please enter your Control Server address, the full URL. IE https://control.rancorthebeast.com:8040" 
            $TempControlUsername = Read-Host -Prompt "Please enter your Control Username"
            $TempControlPassword = Read-Host -Prompt "Please enter your Control Password" -AsSecureString
#            $TempControlPassword = $TempControlPassword | ConvertFrom-SecureString
            $Null = $StoreBlock | Add-Member -NotePropertyName 'ControlServer' -NotePropertyValue $TempControlServer
            $Null = $StoreBlock | Add-Member -NotePropertyName 'ControlAPICredentials' -NotePropertyValue @{'UserName'=$TempControlUsername; 'Password'=($TempControlPassword | ConvertFrom-SecureString)}
        }
        
        $StoreBlock | ConvertTo-JSON -Depth 10 | Out-File -FilePath $CredentialPath -Force -NoNewline
#        Set-Content "$CredentialPath" $TempControlUsername -Force
#        Add-Content "$CredentialPath" $TempControlPassword 
#        Add-Content "$CredentialPath" $TempControlServer 
        Write-Output "Control Credentials Set"
    }

    if ($Custom) {
        $StoreBlock = [pscustomobject]@{}
        $CredentialPath = "$($CredentialDirectory)\$($CredentialDisplayName).txt"
        $CustomCredentials = Get-Credential -Message "Please enter the Custom Username and Password to store"
#        $CustomUsername = $CustomCredentials.UserName
#        $CustomPasswordSecureString = $CustomCredentials.Password
#        $CustomPassword = $CustomPasswordSecureString | ConvertFrom-SecureString
        $Null = $StoreBlock | Add-Member -NotePropertyName 'CustomCredentials' -NotePropertyValue @{'UserName'=$CustomCredentials.Password; 'Password'=($CustomCredentials.Password | ConvertFrom-SecureString)}

        $StoreBlock | ConvertTo-JSON -Depth 10 | Out-File -FilePath $CredentialPath -Force -NoNewline
 #       Set-Content "$CredentialPath" $CustomUsername -Force
 #       Add-Content "$CredentialPath" $CustomPassword
        Write-Output "Custom Credentials Set"
    }

}