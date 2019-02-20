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
        [System.Management.Automation.PSCredential]$Credentials,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Parameter(ParameterSetName = 'refresh', Mandatory = $False)]
        [Parameter(ParameterSetName = 'apikey', Mandatory = $False)]
        [String]$Server = $Script:ControlServer,

        [Parameter(ParameterSetName = 'apikey', Mandatory = $False)]
        $APIKey = ($Script:ControlAPIKey),

#        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
#        [String]$TwoFactorToken,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Switch]$Force,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Switch]$SkipCheck,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Parameter(ParameterSetName = 'refresh', Mandatory = $False)]
        [Parameter(ParameterSetName = 'apikey', Mandatory = $False)]
        [Switch]$Quiet

    )
    
    Begin {
#        $TwoFactorToken=''
#        if ($TwoFactorToken -match '.+') {$Force=$True}
        $TwoFactorNeeded=$False

        If (!$Quiet) {
            While (!($Server -match '.+')) {
                $Server = Read-Host -Prompt "Please enter your Control Server address, the full URL. IE https://control.rancorthebeast.com:8040" 
            }
        }
        $Server = $Server -replace '/$',''
    }
    
    Process {
        If (!($Server -match 'https?://[a-z0-9][a-z0-9\.\-]*(:[1-9][0-9]*)?$')) {throw "Control Server address is in invalid format."; return}
        If ($SkipCheck -and $PSCmdlet.ParameterSetName -eq 'credential' -and !($Null -eq $Credentials)) {
            Write-Debug "Skipping validation. Setting Server=$($Server) and Credentials=$($Credentials.Username)"
            $Script:ControlAPICredentials = $Credentials
            $Script:ControlServer = $Server
            Return
        } ElseIf ($PSCmdlet.ParameterSetName -eq 'apikey' -and $Null -ne $APIKey) {
            If ($APIKey -notmatch '[a-f0-9]{100,}') {
                [SecureString]$APIKey = ConvertTo-SecureString $APIKey -AsPlainText -Force 
            }
            If (!$SkipCheck) {
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
                    $Script:ControlAPIKey = $Null
                    $APIKey=$Null
                    Throw "Attempt to authenticate the Control API Key has failed with error $_.Exception.Message"
                    Return
                }
            }
            Return
        } Else {
            If (!$testCredentials -and !$Force) {
                If (!$Credentials) {
                    $testCredentials = $Script:ControlAPICredentials
                } Else {
                    $testCredentials = $Credentials
                }
            }
            Do {
                $ControlAPITestURI = ($Server + '/Services/PageService.ashx/GetHostSessionInfo')
                If (!$Quiet) {
                    If (!$Credentials) {
                        If (!$testCredentials -or $Force) {
                            Write-Debug "No Credentials were provided and no existing Token was found, or -Force was specified"
                            $testCredentials = $Null
                            $Username = Read-Host -Prompt "Please enter your Control Username"
                            $Password = Read-Host -Prompt "Please enter your Control Password" -AsSecureString
                            $Credentials = New-Object System.Management.Automation.PSCredential ($Username, $Password)
                        } Else {
                            $Force = $True
                        }
                    }
                    If ($TwoFactorNeeded -eq $True -and $TwoFactorToken -match '') {
                        Write-Debug "2FA detected as required. (Someday)"
                        $TwoFactorToken = Read-Host -Prompt "Please enter your 2FA Token"
                    }
                }

                If (!$testCredentials) {$testCredentials=$Credentials}
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
                    $Script:ControlAPICredentials = $Null
                    If ($Credentials) {
                        Throw "Unable to connect to Control. Server Address or Control Credentials are wrong. This module does not support 2FA for Control Users"
                        Return
                    }
                }
                Write-Debug "Request Results: $($ControlAPITokenResult|ConvertTo-Json -Depth 5 -Compress)"
                $AuthorizationResult=$ControlAPITokenResult.ProductVersion
                $TwoFactorNeeded=$ControlAPITokenResult.IsTwoFactorRequired
            } Until ($Quiet -or ![string]::IsNullOrEmpty($AuthorizationResult) -or 
                    ($TwoFactorNeeded -ne $True -and $Credentials) -or 
                    ($TwoFactorNeeded -eq $True -and $TwoFactorToken -ne '')
                )
        }
    }

    End {
        If ($SkipCheck) {
            If ($Quiet) {Return $True} 
            Else {
                Write-Host -BackgroundColor Green -ForegroundColor Black "Skipping validation. Setting Server=$($Server) and Credentials=$($Credentials.Username)"
            }
            Return
        }
        If (($PSCmdlet.ParameterSetName -eq 'apikey' -and !$APIKey)) {
            $Script:ControlAPIKey = $Null
            Throw "Unable to validate the APIKey provided." 
            If ($Quiet) {
                Return $False
            } Else {
                Return
            }
        } ElseIf ($PSCmdlet.ParameterSetName -ne 'apikey' -and [string]::IsNullOrEmpty($AuthorizationResult)) {
            $Script:ControlAPICredentials = $Null
            Throw "Unable to get Access Token. Either the credentials your entered are incorrect or you did not pass a valid two factor token" 
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
