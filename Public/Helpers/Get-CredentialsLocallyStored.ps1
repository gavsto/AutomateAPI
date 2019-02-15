function Get-CredentialsLocallyStored {
    [CmdletBinding()]
    param (
        [Parameter(ParameterSetName = 'Automate')]
        [switch]$Automate,

        [Parameter(ParameterSetName = 'Control')]
        [switch]$Control,

        [Parameter(ParameterSetName = 'Custom')]
        [string]$CredentialPath,

        [Parameter(ParameterSetName = 'Automate')]
        [Parameter(ParameterSetName = 'Control')]    
        [string]$CredentialDirectory = "$($env:USERPROFILE)\AutomateAPI\"

    )

    if ($Automate) {
        if (-not (Test-Path "$($CredentialDirectory)Automate - Credentials.txt")) {    throw [System.IO.FileNotFoundException] "Automate Credentials not found at $($CredentialDirectory)Automate - Credentials.txt"}
        $LocalAutomateCredentials = Get-Content "$($CredentialDirectory)Automate - Credentials.txt"
        $LocalAutomateUsername = $LocalAutomateCredentials[0]
        $LocalAutomatePassword = $LocalAutomateCredentials[1] | ConvertTo-SecureString
        $LocalAutomateServer = $LocalAutomateCredentials[2]
        $LocalAutomateCredentialsObject = New-Object System.Management.Automation.PSCredential -ArgumentList $LocalAutomateUsername, $LocalAutomatePassword
        try {
            Connect-AutomateAPI -AutomateCredentials $LocalAutomateCredentialsObject -Server $LocalAutomateServer
        }
        catch {
            Write-Error $_
        }
    }

    if ($Control) {
        if (-not (Test-Path "$($CredentialDirectory)Control - Credentials.txt")) {    throw [System.IO.FileNotFoundException] "Control Credentials not found at $($CredentialDirectory)Control - Credentials.txt"}
        $LocalControlCredentials = Get-Content "$($CredentialDirectory)Control - Credentials.txt"
        $LocalControlUsername = $LocalControlCredentials[0]
        $LocalControlPassword = $LocalControlCredentials[1] | ConvertTo-SecureString
        $LocalControlServer = $LocalControlCredentials[2]
        $LocalControlCredentialsObject = New-Object System.Management.Automation.PSCredential -ArgumentList $LocalControlUsername, $LocalControlPassword
        try {
            Connect-ControlAPI -ControlCredentials $LocalControlCredentialsObject -Server $LocalControlServer -ErrorAction Stop
        }
        catch {
            Write-Error "Unable to store or retrieve Control credentials with error $_.Exception.Message"
        }
    }

    if ($Custom) {
        if (-not (Test-Path "$($CredentialPath)")) {    throw [System.IO.FileNotFoundException] "Credentials not found at $($CredentialPath)"}
        $CustomCredentials = Get-Content $CredentialPath
        $CustomUsername = $CustomCredentials[0]
        $CustomPassword = $CustomCredentials[1] | ConvertTo-SecureString
        $CustomCredentialObject = New-Object System.Management.Automation.PSCredential -ArgumentList $CustomUsername, $CustomPassword
        return $CustomCredentialObject
    }

}