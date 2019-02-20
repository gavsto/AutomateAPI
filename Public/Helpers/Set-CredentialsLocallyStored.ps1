function Set-CredentialsLocallyStored {
    <#
.SYNOPSIS
   Sets credential objects on a server that has never had them before

.DESCRIPTION
   This function takes a Powershell script and sets credentials on the local disk encrypted with the local system

.EXAMPLE
   Set-CredentialsLocallyStored -Automate

.Example
   Set-CredentialsLocallyStored -Custom -CredentialDisplayName 'Office365' -CredentialDirectory "C:\Credentials"

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

    If ($All) {
        $Automate = $True
        $Control = $True
    }

    If (-not (Test-Path $CredentialDirectory)) {
        New-Item -ItemType Directory -Force -Path $CredentialDirectory | ForEach-Object{$_.Attributes = "hidden"}
    }


    If ($Automate) {
        $StoreVariables = @(
            @{'Name' = 'CWAServer'; 'Scope' = 'Script'},
            @{'Name' = 'CWACredentials'; 'Scope' = 'Script'},
            @{'Name' = 'CWATokenKey'; 'Scope' = 'Script'},
            @{'Name' = 'CWATokenInfo'; 'Scope' = 'Script'}
        )

        If (!$Save) {
            Connect-AutomateAPI -Server '' -Force
        }

        $StoreBlock = [pscustomobject]@{}
        $CredentialPath = "$($CredentialDirectory)\Automate - Credentials.txt"

        Foreach ($SaveVar in $StoreVariables) {
            If (!(Get-Variable @SaveVar -ErrorAction 0)) {Continue}
            If ($SaveVar.Name -match 'Credential') {
                Try {
                    $x_Credential = @{'UserName'=(Get-Variable @SaveVar -ValueOnly).UserName; 'Password'=((Get-Variable @SaveVar -ValueOnly).Password|ConvertFrom-SecureString)}
                    $Null = $StoreBlock | Add-Member -NotePropertyName $($SaveVar.Name) -NotePropertyValue $x_Credential
                } Catch {
                    Write-Warning "Failed to store $($SaveVar.Name), it is not a valid Credential."
                }
            } ElseIf ($SaveVar.Name -match 'Key') {
                Try {
                    $x_Key = (Get-Variable @SaveVar -ValueOnly|ConvertFrom-SecureString)
                    $Null = $StoreBlock | Add-Member -NotePropertyName $($SaveVar.Name) -NotePropertyValue $x_Key
                } Catch {
                    Write-Warning "Failed to store $($SaveVar.Name), it is not a valid Secure String."
                }
            } Else {
                $Null = $StoreBlock | Add-Member -NotePropertyName $($SaveVar.Name) -NotePropertyValue (Get-Variable @SaveVar -ValueOnly)
            }
        }
<#
        } Else {
            $TempAutomateServer = $Null
            Do {
                $TempAutomateServer = Read-Host -Prompt "Please enter your Automate Server address, IE: rancor.hostedrmm.com"
                $TempAutomateServer = $TempAutomateServer -replace '^https?://','' -replace '/.*','' 
                If (!($TempAutomateServer -match '^[a-z0-9][a-z0-9\.\-]*$')) {Write-Host "Server address is missing or in invalid format."}
            } Until ($TempAutomateServer -match '^[a-z0-9][a-z0-9\.\-]*$')
            $TempAutomateUsername = Read-Host -Prompt "Please enter your Automate Username"
            $TempAutomatePassword = Read-Host -Prompt "Please enter your Automate Password" -AsSecureString
            $Null = $StoreBlock | Add-Member -NotePropertyName 'CWAServer' -NotePropertyValue $TempAutomateServer
            $Null = $StoreBlock | Add-Member -NotePropertyName 'CWACredentials' -NotePropertyValue @{'UserName'=$TempAutomateUsername; 'Password'=($TempAutomatePassword | ConvertFrom-SecureString)}
        }
#>

        $StoreBlock | ConvertTo-JSON -Depth 10 | Out-File -FilePath $CredentialPath -Force -NoNewline
        Write-Output "Automate Credentials Set"
    }

    If ($Control) {
        $StoreVariables = @(
            @{'Name' = 'ControlAPICredentials'; 'Scope' = 'Script'},
            @{'Name' = 'ControlServer'; 'Scope' = 'Script'},
            @{'Name' = 'ControlAPIKey'; 'Scope' = 'Script'}
        )

        If (!$Save) {
            Connect-ControlAPI -Server '' -Force
        }

        $StoreBlock = [pscustomobject]@{}
        $CredentialPath = "$($CredentialDirectory)\Control - Credentials.txt"

        Foreach ($SaveVar in $StoreVariables) {
            If (!(Get-Variable @SaveVar -ErrorAction 0)) {Continue}
            If ($SaveVar.Name -match 'Credential') {
                Try {
                    $x_Credential = @{'UserName'=(Get-Variable @SaveVar -ValueOnly).UserName; 'Password'=((Get-Variable @SaveVar -ValueOnly).Password|ConvertFrom-SecureString)}
                    $Null = $StoreBlock | Add-Member -NotePropertyName $($SaveVar.Name) -NotePropertyValue $x_Credential
                } Catch {
                    Write-Warning "Failed to store $($SaveVar.Name), it is not a valid Credential."
                }
            } ElseIf ($SaveVar.Name -match 'Key') {
                Try {
                    $x_Key = (Get-Variable @SaveVar -ValueOnly|ConvertFrom-SecureString)
                    $Null = $StoreBlock | Add-Member -NotePropertyName $($SaveVar.Name) -NotePropertyValue $x_Key
                } Catch {
                    Write-Warning "Failed to store $($SaveVar.Name), it is not a valid Secure String."
                }
            } Else {
                $Null = $StoreBlock | Add-Member -NotePropertyName $($SaveVar.Name) -NotePropertyValue (Get-Variable @SaveVar -ValueOnly)
            }
        }
<#        } Else {
            $TempControlServer = Read-Host -Prompt "Please enter your Control Server address, the full URL. IE https://control.rancorthebeast.com:8040" 
            $TempControlUsername = Read-Host -Prompt "Please enter your Control Username"
            $TempControlPassword = Read-Host -Prompt "Please enter your Control Password" -AsSecureString
            $Null = $StoreBlock | Add-Member -NotePropertyName 'ControlServer' -NotePropertyValue $TempControlServer
            $Null = $StoreBlock | Add-Member -NotePropertyName 'ControlAPICredentials' -NotePropertyValue @{'UserName'=$TempControlUsername; 'Password'=($TempControlPassword | ConvertFrom-SecureString)}
#        }
#>        

        $StoreBlock | ConvertTo-JSON -Depth 10 | Out-File -FilePath $CredentialPath -Force -NoNewline
        Write-Output "Control Credentials Set"
    }

    If ($Custom) {
        $StoreBlock = [pscustomobject]@{}
        $CredentialPath = "$($CredentialDirectory)\$($CredentialDisplayName).txt"
        $CustomCredentials = Get-Credential -Message "Please enter the Custom Username and Password to store"
        $Null = $StoreBlock | Add-Member -NotePropertyName 'CustomCredentials' -NotePropertyValue @{'UserName'=$CustomCredentials.Password; 'Password'=($CustomCredentials.Password | ConvertFrom-SecureString)}

        $StoreBlock | ConvertTo-JSON -Depth 10 | Out-File -FilePath $CredentialPath -Force -NoNewline
        Write-Output "Custom Credentials Set for $($CredentialDisplayName)"
    }

}