function Get-CredentialsLocallyStored {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'Automate')]
        [switch]$Automate,

        [Parameter(ParameterSetName = 'Control')]
        [switch]$Control,

        [Parameter(ParameterSetName="All")]
        [switch]$All,

        [Parameter(ParameterSetName = 'Custom',Mandatory=$True)]
        [string]$CredentialPath,

        [Parameter(ParameterSetName = 'Automate')]
        [Parameter(ParameterSetName = 'Control')]    
        [string]$CredentialDirectory = "$($env:USERPROFILE)\AutomateAPI\"

    )

    If ($All) {
        $Automate = $True
        $Control = $True
    }

    If ($Automate) {
        $CredentialPath = "$($CredentialDirectory)\Automate - Credentials.txt"
        If (-not (Test-Path $CredentialPath -EA 0)) {
            Throw [System.IO.FileNotFoundException] "Automate Credentials not found at $($CredentialPath)"
        }
        $StoreVariables = @(
            @{'Name' = 'CWAServer'; 'Scope' = 'Script'},
            @{'Name' = 'CWACredentials'; 'Scope' = 'Script'},
            @{'Name' = 'CWATokenKey'; 'Scope' = 'Script'},
            @{'Name' = 'CWATokenInfo'; 'Scope' = 'Script'}
        )
        $StoreBlock = Get-Content $CredentialPath | ConvertFrom-Json
        Foreach ($SaveVar in $StoreVariables) {
            If (!($StoreBlock.$($SaveVar.Name))) {Continue}
            If ($SaveVar.Name -match 'Credential') {
                Try {
                    $Null = Set-Variable @SaveVar -Value $(New-Object System.Management.Automation.PSCredential -ArgumentList $($StoreBlock.$($SaveVar.Name).Username), $(ConvertTo-SecureString $($StoreBlock.$($SaveVar.Name).Password)))
                } Catch {
                    Write-Warning "Failed to restore $($SaveVar.Name). The stored password is invalid."
                }
            } ElseIf ($SaveVar.Name -match 'Key') {
                Try {
                    $Null = Set-Variable @SaveVar -Value $(ConvertTo-SecureString $($StoreBlock.$($SaveVar.Name)))
                } Catch {
                    Write-Warning "Failed to restore $($SaveVar.Name). The stored secure value is invalid."
                }
            } Else {
                $Null = Set-Variable @SaveVar -Value $($StoreBlock.$($SaveVar.Name))
            }
        }
        If ($Script:CWATokenKey -and $Script:CWATokenKey.GetType() -match 'SecureString') {
            $AuthorizationToken = $([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($Script:CWATokenKey)))
            $AutomateToken = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $AutomateToken.Add("Authorization", "Bearer $AuthorizationToken")
            $Script:CWAToken = $AutomateToken
        }
        If (!(Connect-AutomateAPI -Verify -Quiet -ErrorAction 0)) {
            Write-Warning "Automate Credentials failed to successfully validate. Call Connect-AutomateAPI to establish a valid session."
        }
    }

    If ($Control) {
        $CredentialPath = "$($CredentialDirectory)\Control - Credentials.txt"
        If (-not (Test-Path $CredentialPath -EA 0)) {
            Throw [System.IO.FileNotFoundException] "Control Credentials not found at $($CredentialPath)"
        }
        $StoreVariables = @(
            @{'Name' = 'ControlAPICredentials'; 'Scope' = 'Script'},
            @{'Name' = 'ControlServer'; 'Scope' = 'Script'},
            @{'Name' = 'ControlAPIKey'; 'Scope' = 'Script'}
        )

        $StoreBlock = Get-Content $CredentialPath | ConvertFrom-Json
        Foreach ($SaveVar in $StoreVariables) {
            If (!($StoreBlock.$($SaveVar.Name))) {Continue}
            If ($SaveVar.Name -match 'Credential') {
                Try {
                    $Null = Set-Variable @SaveVar -Value $(New-Object System.Management.Automation.PSCredential -ArgumentList $($StoreBlock.$($SaveVar.Name).Username), $(ConvertTo-SecureString $($StoreBlock.$($SaveVar.Name).Password)))
                } Catch {
                    Write-Warning "Failed to restore $($SaveVar.Name). The stored password is invalid."
                }
            } ElseIf ($SaveVar.Name -match 'Key') {
                Try {
                    $Null = Set-Variable @SaveVar -Value $(ConvertTo-SecureString $($StoreBlock.$($SaveVar.Name)))
                } Catch {
                    Write-Warning "Failed to restore $($SaveVar.Name). The stored secure value is invalid."
                }
            } Else {
                $Null = Set-Variable @SaveVar -Value $($StoreBlock.$($SaveVar.Name))
            }
        }
        If (!(Connect-ControlAPI -Verify -Quiet -ErrorAction 0)) {
            Write-Warning "Control Credentials failed to successfully validate. Call Connect-ControlAPI to establish a valid session."
        }
    }

    If ($Custom) {
        If (-not (Test-Path "$($CredentialPath)")) {
            Throw [System.IO.FileNotFoundException] "Credentials not found at $($CredentialPath)"
        }
        $StoreBlock = Get-Content $CredentialPath | ConvertFrom-Json

        Try {
            $CustomCredentialObject = New-Object System.Management.Automation.PSCredential -ArgumentList $($StoreBlock.CustomCredentials.Username), $(ConvertTo-SecureString $($StoreBlock.CustomCredentials.Password))
        } Catch {
            Write-Warning "Failed to restore CustomCredential from $($CredentialPath). The stored password is invalid."
        }
        Return $CustomCredentialObject
    }

}