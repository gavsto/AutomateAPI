function Connect-AutomateAPI {
<#
.SYNOPSIS
Connect to the Automate API.
.DESCRIPTION
Connects to the Automate API and returns a bearer token which when passed with each requests grants up to an hours worth of access.
.PARAMETER Server
The address to your Automate Server. Example 'rancor.hostedrmm.com'
.PARAMETER Credential
Takes a standard powershell credential object, this can be built with $CredentialsToPass = Get-Credential, then pass $CredentialsToPass
.PARAMETER ClientID
Takes the Client ID required by Automate v2020.11 for API access
.PARAMETER TwoFactorToken
Takes a string that represents the 2FA number
.PARAMETER AuthorizationToken
Used internally when quietly refreshing the Token
.PARAMETER SkipCheck
Used internally when quietly refreshing the Token
.PARAMETER Verify
Specifies to test the current token, and if it is not valid attempt to obtain a new one using the current credentials. Does not refresh (re-issue) the current token.
.PARAMETER Force
Will not attempt to refresh a current session
.PARAMETER Quiet
Will not output any standard messages. Returns $True if connection was successful.
.OUTPUTS
Three strings into Script variables, $CWAServer containing the server address, $CWACredentials containing the bearer token and $CWACredentialsExpirationDate containing the date the credentials expire
.NOTES
Version:        1.2.0
Author:         Gavin Stone
Creation Date:  2019-01-20
Purpose/Change: Initial script development

Update Date:    2019-02-12
Author:         Darren White
Purpose/Change: Credential and 2FA prompting is only if needed. Supports Token Refresh.

Update Date:    2020-08-01
Purpose/Change: Change to use CWAIsConnected script variable to track connection state

Update Date:    2020-11-19
Author:         Brandon Fahnestock
Purpose/Change: ConnectWise Automate v2020.11 requires a registered ClientID for API access. Added Support for ClientIDs 

.EXAMPLE
Connect-AutomateAPI -Server "rancor.hostedrmm.com" -Credential $CredentialObject -TwoFactorToken "999999" -ClientID '123123123-1234-1234-1234-123123123123'

.EXAMPLE
Connect-AutomateAPI -Quiet
#>
    [CmdletBinding(DefaultParameterSetName = 'refresh')]
    param (
        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Parameter(ParameterSetName = 'refresh', Mandatory = $False)]
        [Parameter(ParameterSetName = 'verify', Mandatory = $False)]
        [String]$ClientID = $Script:CWAClientID,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Parameter(ParameterSetName = 'refresh', Mandatory = $False)]
        [Parameter(ParameterSetName = 'verify', Mandatory = $False)]
        [String]$Server = $Script:CWAServer,

        [Parameter(ParameterSetName = 'refresh', Mandatory = $False)]
        [Parameter(ParameterSetName = 'verify', Mandatory = $False)]
        [String]$AuthorizationToken = ($Script:CWAToken.Authorization -replace 'Bearer ',''),

        [Parameter(ParameterSetName = 'refresh', Mandatory = $False)]
        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Switch]$SkipCheck,

        [Parameter(ParameterSetName = 'verify', Mandatory = $False)]
        [Switch]$Verify,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [String]$TwoFactorToken,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Switch]$Force,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Parameter(ParameterSetName = 'refresh', Mandatory = $False)]
        [Parameter(ParameterSetName = 'verify', Mandatory = $False)]
        [Switch]$Quiet
    )

    Begin {
        If ($TwoFactorToken -match '.+') {$Force=$True}
        $TwoFactorNeeded=$False

        If (!$Quiet) {
            While (!($Server -match '.+')) {
                $Server = Read-Host -Prompt "Please enter your Automate Server address, IE: rancor.hostedrmm.com" 
            }
            If (!($ClientID -match '.+')) {
                $ClientID = Read-Host -Prompt "Please enter API Client ID (Required for 2020.P11 and above)" 
            }
        }
        $Server = $Server -replace '^https?://','' -replace '/[^\/]*$',''
        $AuthorizationToken = $AuthorizationToken -replace 'Bearer ',''
        $Script:CWAIsConnected=$False
        If ($ClientID -notmatch '.+') {
            $ClientID=$Null
            Write-Warning "API ClientID is missing or in invalid format."
        }

    } #End Begin
    
    Process {
        If (!($Server -match '^[a-z0-9][a-z0-9\.\-\/]*$')) {Throw "Server address ($Server) is missing or in invalid format."; Return}
        $AutomateAPIURI = ('https://' + $Server + '/cwa/api/v1')
        If ($SkipCheck) {
            $Script:CWAServer = ("https://" + $Server)
            If ($Credential) {
                Write-Debug "Setting Credentials to $($Credential.UserName)"
                $Script:CWACredentials = $Credential
            }
            If ($AuthorizationToken) {
                #Build the token
                $AutomateToken = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
                $Null = $AutomateToken.Add("Authorization", "Bearer $AuthorizationToken")
                Write-Debug "Setting Authorization Token to $($AutomateToken.Authorization)"
                $Script:CWAToken = $AutomateToken
            }
            If ($ClientID) {
                Write-Debug "Setting ClientID to $ClientID"
                $Script:CWAClientID = $ClientID
            }
            Return
        }
        If (!$AuthorizationToken -and $PSCmdlet.ParameterSetName -eq 'verify') {
            If (!$Quiet) { Throw "Attempt to verify token failed. No token was provided or was cached." }
            Return
        }
        Do {
            $testCredential=$Credential
            If (!$Quiet) {
                If (!$Credential -and ($Force -or !$AuthorizationToken)) {
                    If ($Force -or !$Script:CWACredentials) {
                        $Username = Read-Host -Prompt "Please enter your Automate Username"
                        $Password = Read-Host -Prompt "Please enter your Automate Password" -AsSecureString
                        $Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)
                        $testCredential=$Credential
                    }
                }
                If ($TwoFactorNeeded -eq $True -and $TwoFactorToken -match '') {
                    $TwoFactorToken = Read-Host -Prompt "Please enter your 2FA Token"
                }
            }

            If (!$AuthorizationToken -and !$testCredential -and $Script:CWACredentials -and $Force -ne $True -and $PSCmdlet.ParameterSetName -ne 'verify') {
                $testCredential = $Script:CWACredentials
            }
            If ($testCredential) {
                #Build the headers for the Authentication
                $PostBody = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
                $PostBody.Add("username", $testCredential.UserName)
                $PostBody.Add("password", $testCredential.GetNetworkCredential().Password)
                If (!([string]::IsNullOrEmpty($TwoFactorToken))) {
                    #Remove any spaces that were added
                    $TwoFactorToken = $TwoFactorToken -replace '\s', ''
                    $PostBody.Add("TwoFactorPasscode", $TwoFactorToken)
                }
                $RESTRequest = @{
                    'URI' = ($AutomateAPIURI + '/apitoken')
                    'Method' = 'POST'
                    'ContentType' = 'application/json'
                    'Headers' = @{}
                    'Body' = $($PostBody | ConvertTo-Json -Compress)
                }
            } ElseIf ($PSCmdlet.ParameterSetName -eq 'refresh') {
                $PostBody = $AuthorizationToken -replace 'Bearer ',''
                $RESTRequest = @{
                    'URI' = ($AutomateAPIURI + '/apitoken/refresh')
                    'Method' = 'POST'
                    'ContentType' = 'application/json'
                    'Headers' = @{}
                    'Body' = $PostBody | ConvertTo-Json -Compress
                }
            } ElseIf ($PSCmdlet.ParameterSetName -eq 'verify') {
                $PostBody = $AuthorizationToken -replace 'Bearer ',''
                $RESTRequest = @{
                    'URI' = ($AutomateAPIURI + '/DatabaseServerTime')
                    'Method' = 'GET'
                    'ContentType' = 'application/json'
                    'Headers' = @{'Authorization' = "Bearer $PostBody"}
                }
            }
            If ($ClientID) {
                $RESTRequest.Headers += @{'clientID' = "$ClientID"}
            }

            #Invoke the REST Method
            Write-Debug "Submitting Request to $($RESTRequest.URI)`nHeaders:`n$($RESTRequest.Headers|ConvertTo-JSON -Depth 5)`nBody:`n$($RESTRequest.Body|ConvertTo-JSON -Depth 5)"
            Try {
                $AutomateAPITokenResult = Invoke-RestMethod @RESTRequest
            }
            Catch {
                Remove-Variable CWAToken,CWATokenKey -Scope Script -ErrorAction 0
                If ($testCredential) {
                    Remove-Variable CWACredentials -Scope Script -ErrorAction 0
                }
                If ($Credential) {
                    Throw "Attempt to authenticate to the Automate API has failed with error $_.Exception.Message"
                    Return
                }
            }
            
            $AuthorizationToken=$AutomateAPITokenResult.Accesstoken
            $TwoFactorNeeded=$AutomateAPITokenResult.IsTwoFactorRequired
            If ($PSCmdlet.ParameterSetName -eq 'verify' -and !$AuthorizationToken -and $AutomateAPITokenResult -and $TwoFactorNeeded -ne $True) {
                $AuthorizationToken = $Script:CWAToken.Authorization -replace 'Bearer ',''
                $Script:CWAToken.Authorization=$Null
            }
        } Until ($Quiet -or ![string]::IsNullOrEmpty($AuthorizationToken) -or 
                ($PSCmdlet.ParameterSetName -eq 'verify' -and !$AuthorizationToken) -or
                ($TwoFactorNeeded -ne $True -and $Credential) -or 
                ($TwoFactorNeeded -eq $True -and $TwoFactorToken -ne '')
            )
    } #End Process

    End {
        If ($SkipCheck) {
            $Script:CWAIsConnected=$True
            If ($Quiet) {
                Return $False
            } Else {
                Return
            }
        } ElseIf ([string]::IsNullOrEmpty($AuthorizationToken)) {
            Remove-Variable CWAToken -Scope Script -ErrorAction 0
            If ($Quiet) {
                Return $False
            } Else {
                Throw "Unable to get Access Token. Either the credentials you entered are incorrect or you did not pass a valid two factor token" 
                Return
            }
        } Else {
            #Build the returned token
            $AutomateToken = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $AutomateToken.Add("Authorization", "Bearer $AuthorizationToken")
            #Create Script Variables for this session in order to use the token
            $Script:CWATokenKey = ConvertTo-SecureString $AuthorizationToken -AsPlainText -Force
            $Script:CWAServer = ("https://" + $Server)
            $Script:CWAToken = $AutomateToken
            $Script:CWAIsConnected=$True
            If ($Credential) {
                $Script:CWACredentials = $Credential
            }
            If ($ClientID) {
                $Script:CWAClientID = $ClientID
            }
            If ($PSCmdlet.ParameterSetName -ne 'verify') {
                $AutomateAPITokenResult.PSObject.properties.remove('AccessToken')
                $Script:CWATokenInfo = $AutomateAPITokenResult
            }
            Write-Verbose "Token retrieved: $AuthorizationToken, expiration is $($Script:CWATokenInfo.ExpirationDate)"

            If (!$Quiet) {
                Write-Host -BackgroundColor Green -ForegroundColor Black "Successfully tested and connected to the Automate REST API. Token will expire at $($Script:CWATokenInfo.ExpirationDate)"
            } Else {
                Return $True
            }
        }
    }
}
