function Connect-ControlAPI {
    <#
    .SYNOPSIS
    Adds credentials required to connect to the Control API
    .DESCRIPTION
    Creates a Control hashtable in memory containing the server and username/password so that it can be used in other functions that connect to ConnectWise Control. Unfortunately the Control API does not support 2FA.
    .PARAMETER Server
    The address to your Control Server. Example 'https://control.rancorthebeast.com:8040'
    .PARAMETER Credentials
    Takes a standard powershell credential object, this can be built with $CredentialsToPass = Get-Credential, then pass $CredentialsToPass
    .PARAMETER APIKey
    Automate APIKey for Control Extension
    .PARAMETER Verify
    Attempt to verify Cached API key or Credentials. Invalid results will be removed.
    .PARAMETER Quiet
    Will not output any standard logging messages
    .OUTPUTS
    Two script variables with server and credentials. Returns True or False
    .NOTES
    Version:        1.0
    Author:         Gavin Stone
    Creation Date:  20/01/2019
    Purpose/Change: Initial script development
    .EXAMPLE
    All values will be prompted for one by one:
    Connect-ControlAPI
    All values needed to Automatically create appropriate output
    Connect-ControlAPI -Server "https://control.rancorthebeast.com:8040" -Credentials $CredentialsToPass
    #>
    [CmdletBinding(DefaultParameterSetName = 'refresh')]
    param (
        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Parameter(ParameterSetName = 'verify', Mandatory = $False)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Parameter(ParameterSetName = 'refresh', Mandatory = $False)]
        [Parameter(ParameterSetName = 'apikey', Mandatory = $False)]
        [Parameter(ParameterSetName = 'verify', Mandatory = $False)]
        [String]$Server = $Script:ControlServer,

        [Parameter(ParameterSetName = 'apikey', Mandatory = $False)]
        $APIKey = ([SecureString]$Script:ControlAPIKey),

#        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
#        [String]$TwoFactorToken,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Switch]$Force,

        [Parameter(ParameterSetName = 'verify', Mandatory = $False)]
        [Switch]$Verify,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Parameter(ParameterSetName = 'apikey', Mandatory = $False)]
        [Switch]$SkipCheck,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Parameter(ParameterSetName = 'refresh', Mandatory = $False)]
        [Parameter(ParameterSetName = 'apikey', Mandatory = $False)]
        [Parameter(ParameterSetName = 'verify', Mandatory = $False)]
        [Switch]$Quiet

    )
    
    Begin {
#        $TwoFactorToken=''
#        if ($TwoFactorToken -match '.+') {$Force=$True}
        $TwoFactorNeeded=$False

        If (!$Quiet -and !$Verify) {
            While (!($Server -match '.+')) {
                $Server = Read-Host -Prompt "Please enter your Control Server address, the full URL. IE https://control.rancorthebeast.com:8040" 
            }
        }
        $Server = $Server -replace '/$',''
    }
    
    Process {
        If (!($Server -match 'https?://[a-z0-9][a-z0-9\.\-]*(:[1-9][0-9]*)?$')) {throw "Control Server address is in invalid format."; return}
        If ($SkipCheck) {
            Return
        }
        If (($PSCmdlet.ParameterSetName -eq 'apikey' -or $PSCmdlet.ParameterSetName -eq 'verify') -and $Null -ne $APIKey) {
            If ($APIKey.GetType() -notmatch 'SecureString') {
                [SecureString]$APIKey = ConvertTo-SecureString $APIKey -AsPlainText -Force 
            }
            # Retrieve Control Instance ID to verify APIKey
            $RESTRequest = @{
                'Method' = 'GET'
                'URI' = "$($Server)/App_Extensions/fc234f0e-2e8e-4a1f-b977-ba41b14031f7/Service.ashx/GetServerVersion"
                'Headers' = @{'CWAIKToken' = (Get-CWAIKToken -APIKey $APIKey)}
            }
            Write-Debug "Submitting Request to $($RESTRequest.URI)"
            Try {
                $AuthorizationResult = Invoke-RestMethod @RESTRequest
            } Catch {
                Write-Debug "Result: $($AuthorizationResult | Select-Object -Property * | ConvertTo-Json -Depth 10 -Compress)"
                Remove-Variable ControlAPIKey -Scope Script -ErrorAction 0
                $APIKey=$Null
                Throw "Attempt to authenticate the Control API Key has failed with error $_.Exception.Message"
                If ($Quiet) {
                    Return $False
                } Else {
                    Return
                }
            }
            Return
        } Else {
            If (!$testCredentials -and !$Force) {
                If (!$Credential) {
                    $testCredentials = $Script:ControlAPICredentials
                } Else {
                    $testCredentials = $Credential
                }
            }
            Do {
                $ControlAPITestURI = ($Server + '/Services/PageService.ashx/GetHostSessionInfo')
                If (!$Quiet) {
                    If (!$Credential -and !$Verify) {
                        If (!$testCredentials -or $Force) {
                            Write-Debug "No Credentials were provided and no existing Token was found, or -Force was specified"
                            $testCredentials = $Null
                            $Username = Read-Host -Prompt "Please enter your Control Username"
                            $Password = Read-Host -Prompt "Please enter your Control Password" -AsSecureString
                            $Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)
                        } Else {
                            $Force = $True
                        }
                    }
                    If ($TwoFactorNeeded -eq $True -and $TwoFactorToken -match '') {
                        Write-Debug "2FA detected as required. (Someday)"
                        $TwoFactorToken = Read-Host -Prompt "Please enter your 2FA Token"
                    }
                }

                If (!$testCredentials) {$testCredentials=$Credential}
                #Invoke the REST Method
                $RESTRequest = @{
                    'URI' = $ControlAPITestURI
                    'Method' = 'GET'
                    'ContentType' = 'application/json'
                    'Credential' = $testCredentials
                }
                Write-Debug "Submitting Request to $($RESTRequest.URI)"
                Try {
                    $ControlAPITokenResult = Invoke-RestMethod @RESTRequest
                }
                Catch {
                    Remove-Variable ControlAPICredentials -Scope Script -ErrorAction 0
                    If ($Credential) {
                        Throw "Unable to connect to Control. Server Address or Control Credentials are wrong. This module does not support 2FA for Control Users"
                        If ($Quiet) {
                            Return $False
                        } Else {
                            Return
                        }
                    }
                }
                Write-Debug "Request Results: $($ControlAPITokenResult|ConvertTo-Json -Depth 5 -Compress)"
                $AuthorizationResult=$ControlAPITokenResult.ProductVersion
                $TwoFactorNeeded=$ControlAPITokenResult.IsTwoFactorRequired
            } Until ($Quiet -or $Verify -or ![string]::IsNullOrEmpty($AuthorizationResult) -or 
                    ($TwoFactorNeeded -ne $True -and $Credential) -or 
                    ($TwoFactorNeeded -eq $True -and $TwoFactorToken -ne '')
                )
        }
    }

    End {
        If ($SkipCheck) {
            If ($PSCmdlet.ParameterSetName -eq 'apikey' -and !($Null -eq $APIKey)) {
                If ($APIKey.GetType() -notmatch 'SecureString') {
                    [SecureString]$APIKey = ConvertTo-SecureString $APIKey -AsPlainText -Force 
                }
                Write-Debug "Skipping validation. Setting Server=$($Server) and APIKey."
                $Script:ControlServer = $Server
                $Script:ControlAPIKey = $APIKey
                If ($Quiet) {
                    Return $True
                } Else {
                    Write-Host -BackgroundColor Green -ForegroundColor Black "Successfully stored the Server and APIKey values."
                    Return
                }
            } ElseIf ($PSCmdlet.ParameterSetName -eq 'credential' -and !($Null -eq $Credential)) {
                Write-Debug "Skipping validation. Setting Server=$($Server) and Credential=$($Credential.Username)"
                $Script:ControlServer = $Server
                $Script:ControlAPICredentials = $Credential
                If ($Quiet) {
                    Return $True
                } Else {
                    Write-Host -BackgroundColor Green -ForegroundColor Black "Successfully stored the Server and Credential values."
                    Return
                }
            }
            Throw "SkipCheck failed because the Server, APIKey, or Credentials were not provided."
            If ($Quiet) {
                Return $False
            } Else {
                Return
            }
        } ElseIf (($PSCmdlet.ParameterSetName -eq 'apikey' -and !$APIKey)) {
            Remove-Variable ControlAPIKey -Scope Script -ErrorAction 0
            Throw "Unable to validate the APIKey provided." 
            If ($Quiet) {
                Return $False
            } Else {
                Return
            }
        } ElseIf ($PSCmdlet.ParameterSetName -ne 'apikey' -and [string]::IsNullOrEmpty($AuthorizationResult)) {
            Remove-Variable ControlAPICredentials -Scope Script -ErrorAction 0
            Throw "Unable to get Access Token. Either the credentials provided are incorrect or you did not pass a valid two factor token" 
            If ($Quiet) {
                Return $False
            } Else {
                Return
            }
        } Else {
            If ($PSCmdlet.ParameterSetName -eq 'apikey') {
                $Script:ControlAPIKey = $APIKey
            } Else {
                $Script:ControlAPICredentials = $testCredentials
            }
            $Script:ControlServer = $Server
            If (!$Quiet) {
                Write-Host -BackgroundColor Green -ForegroundColor Black "Successfully tested and connected to the Control API. Server version is $($AuthorizationResult)"
            } Else {
                Return $True
            }
        }
    }
}
