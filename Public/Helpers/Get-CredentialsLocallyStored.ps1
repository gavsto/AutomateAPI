function Get-CredentialsLocallyStored {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'Automate')]
        [switch]$Automate,

        [Parameter(ParameterSetName = 'Control')]
        [switch]$Control,

        [Parameter(ParameterSetName = 'Custom',Mandatory=$True)]
        [string]$CredentialPath,

        [Parameter(ParameterSetName = 'Automate')]
        [Parameter(ParameterSetName = 'Control')]    
        [string]$CredentialDirectory = "$($env:USERPROFILE)\AutomateAPI\"

    )

    if ($Automate) {
        if (-not (Test-Path "$($CredentialDirectory)Automate - Credentials.txt")) {    throw [System.IO.FileNotFoundException] "Automate Credentials not found at $($CredentialDirectory)Automate - Credentials.txt"}
        $StoreVariables = @(
            @{'Name' = 'CWAServer'; 'Scope' = 'Script'},
            @{'Name' = 'CWACredentials'; 'Scope' = 'Script'},
            @{'Name' = 'CWATokenKey'; 'Scope' = 'Script'},
            @{'Name' = 'CWAToken'; 'Scope' = 'Script'},
            @{'Name' = 'CWATokenExpirationDate'; 'Scope' = 'Script'}
        )
        $StoreBlock = Get-Content "$($CredentialDirectory)Automate - Credentials.txt" | ConvertFrom-Json
        Foreach ($SaveVar in $StoreVariables) {
            If (!($StoreBlock.$($SaveVar.Name))) {Continue}
            If ($SaveVar.Name -match 'Credential') {
                $Null = Set-Variable @SaveVar -Value $(New-Object System.Management.Automation.PSCredential -ArgumentList $($StoreBlock.$($SaveVar.Name).Username), $($StoreBlock.$($SaveVar.Name).Password|ConvertTo-SecureString))
            } ElseIf ($SaveVar.Name -match 'Key') {
                $Null = Set-Variable @SaveVar -Value $($StoreBlock.$($SaveVar.Name)|ConvertTo-SecureString)
            } Else {
                $Null = Set-Variable @SaveVar -Value $($StoreBlock.$($SaveVar.Name))
            }
        }

#        $LocalAutomateUsername = $LocalAutomateCredentials[0]
#        $LocalAutomatePassword = $LocalAutomateCredentials[1] | ConvertTo-SecureString
#        $LocalAutomateServer = $LocalAutomateCredentials[2]
#        $LocalAutomateCredentialsObject = New-Object System.Management.Automation.PSCredential -ArgumentList $LocalAutomateUsername, $LocalAutomatePassword
#        try {
#            Connect-AutomateAPI -AutomateCredentials $LocalAutomateCredentialsObject -Server $LocalAutomateServer
#        }
#        catch {
#            Write-Error $_
#        }
    }

    if ($Control) {
        if (-not (Test-Path "$($CredentialDirectory)Control - Credentials.txt")) {    throw [System.IO.FileNotFoundException] "Control Credentials not found at $($CredentialDirectory)Control - Credentials.txt"}
        $StoreVariables = @(
            @{'Name' = 'ControlAPICredentials'; 'Scope' = 'Script'},
            @{'Name' = 'ControlServer'; 'Scope' = 'Script'},
            @{'Name' = 'ControlAPIKey'; 'Scope' = 'Script'}
        )

        $StoreBlock = Get-Content "$($CredentialDirectory)Control - Credentials.txt" | ConvertFrom-Json
        Foreach ($SaveVar in $StoreVariables) {
            If (!($StoreBlock.$($SaveVar.Name))) {Continue}
            If ($SaveVar.Name -match 'Credential') {
                $Null = Set-Variable @SaveVar -Value $(New-Object System.Management.Automation.PSCredential -ArgumentList $($StoreBlock.$($SaveVar.Name).Username), $($StoreBlock.$($SaveVar.Name).Password|ConvertTo-SecureString))
            } ElseIf ($SaveVar.Name -match 'Key') {
                $Null = Set-Variable @SaveVar -Value $($StoreBlock.$($SaveVar.Name)|ConvertTo-SecureString)
            } Else {
                $Null = Set-Variable @SaveVar -Value $($StoreBlock.$($SaveVar.Name))
            }
        }

#        $LocalControlUsername = $LocalControlCredentials[0]
#        $LocalControlPassword = $LocalControlCredentials[1] | ConvertTo-SecureString
#        $LocalControlServer = $LocalControlCredentials[2]
#        $LocalControlCredentialsObject = New-Object System.Management.Automation.PSCredential -ArgumentList $LocalControlUsername, $LocalControlPassword
#        try {
#            Connect-ControlAPI -ControlCredentials $LocalControlCredentialsObject -Server $LocalControlServer -ErrorAction Stop
#        }
#        catch {
#            Write-Error "Unable to store or retrieve Control credentials with error $_.Exception.Message"
#        }
    }

    if ($Custom) {
        if (-not (Test-Path "$($CredentialPath)")) {    throw [System.IO.FileNotFoundException] "Credentials not found at $($CredentialPath)"}
        $StoreBlock = Get-Content $CredentialPath | ConvertFrom-Json
        If (!($StoreBlock.CustomCredentials)) {Continue}
        
#        $CustomCredentials = Get-Content $CredentialPath
#        $CustomUsername = $CustomCredentials[0]
#        $CustomPassword = $CustomCredentials[1] | ConvertTo-SecureString
        $CustomCredentialObject = New-Object System.Management.Automation.PSCredential -ArgumentList $($StoreBlock.CustomCredentials.Username), $($StoreBlock.CustomCredentials.Password|ConvertTo-SecureString)
        return $CustomCredentialObject
    }

}