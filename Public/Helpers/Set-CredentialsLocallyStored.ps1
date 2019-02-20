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
        If (!$Save) {
            Connect-AutomateAPI -Server '' -Force
        }

        $StoreVariables = @(
            @{'Name' = 'CWAServer'; 'Scope' = 'Script'},
            @{'Name' = 'CWACredentials'; 'Scope' = 'Script'},
            @{'Name' = 'CWATokenKey'; 'Scope' = 'Script'},
            @{'Name' = 'CWATokenInfo'; 'Scope' = 'Script'}
        )

        $StoreBlock = [pscustomobject]@{}
        $CredentialPath = "$($CredentialDirectory)\Automate - Credentials.txt"

        Foreach ($SaveVar in $StoreVariables) {
            If (!(Get-Variable @SaveVar -ErrorAction 0)) {Continue}
            If ($SaveVar.Name -match 'Credential') {
                Try {
                    Write-Debug "Trying to save $($SaveVar.Name)"
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

        $StoreBlock | ConvertTo-JSON -Depth 10 | Out-File -FilePath $CredentialPath -Force -NoNewline
        Write-Output "Automate Credentials Set"
    }

    If ($Control) {
        If (!$Save) {
            Connect-ControlAPI -Server '' -Force
        }

        $StoreVariables = @(
            @{'Name' = 'ControlAPICredentials'; 'Scope' = 'Script'},
            @{'Name' = 'ControlServer'; 'Scope' = 'Script'},
            @{'Name' = 'ControlAPIKey'; 'Scope' = 'Script'}
        )

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

        $StoreBlock | ConvertTo-JSON -Depth 10 | Out-File -FilePath $CredentialPath -Force -NoNewline
        Write-Output "Control Credentials Set"
    }

    If ($Custom) {
        $StoreBlock = [pscustomobject]@{}
        $CredentialPath = "$($CredentialDirectory)\$($CredentialDisplayName).txt"
        $CustomCredentials = Get-Credential -Message "Please enter the Custom Username and Password to store"
        $Null = $StoreBlock | Add-Member -NotePropertyName 'CustomCredentials' -NotePropertyValue @{'UserName'=$CustomCredentials.UserName; 'Password'=($CustomCredentials.Password | ConvertFrom-SecureString)}

        $StoreBlock | ConvertTo-JSON -Depth 10 | Out-File -FilePath $CredentialPath -Force -NoNewline
        Write-Output "Custom Credentials Set for $($CredentialDisplayName)"
    }

}