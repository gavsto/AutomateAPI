function Connect-AutomateAPI {
<#
.SYNOPSIS
Connect to the Automate API.
.DESCRIPTION
Connects to the Automate API and returns a bearer token which when passed with each requests grants up to an hours worth of access.
.PARAMETER Server
The address to your Automate Server. Example 'rancor.hostedrmm.com'
.PARAMETER Credentials
Takes a standard powershell credential object, this can be built with $CredentialsToPass = Get-Credential, then pass $CredentialsToPass
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
Version:        1.1
Author:         Gavin Stone
Creation Date:  2019-01-20
Purpose/Change: Initial script development

Update Date:    2019-02-12
Author:         Darren White
Purpose/Change: Credential and 2FA prompting is only if needed. Supports Token Refresh.

.EXAMPLE
Connect-AutomateAPI -Server "rancor.hostedrmm.com" -Credentials $CredentialObject -TwoFactorToken "999999"

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
        # Check for locally stored credentials
#        [string]$CredentialDirectory = "$($env:USERPROFILE)\AutomateAPI\"
#        $LocalCredentialsExist = Test-Path "$($CredentialDirectory)Automate - Credentials.txt"
        If ($TwoFactorToken -match '.+') {$Force=$True}
        $TwoFactorNeeded=$False

        If (!$Quiet) {
            While (!($Server -match '.+')) {
                $Server = Read-Host -Prompt "Please enter your Automate Server address, IE: rancor.hostedrmm.com" 
            }
        }
        $Server = $Server -replace '^https?://','' -replace '/.*',''
        $AuthorizationToken = $AuthorizationToken -replace 'Bearer ',''
    } #End Begin
    
    Process {
        If (!($Server -match '^[a-z0-9][a-z0-9\.\-]*$')) {Throw "Server address is missing or in invalid format."; Return}
        If ($SkipCheck) {
            $Script:CWAServer = ("https://" + $Server)
            If ($Credential) {
                Write-Debug "Setting Credentials to $($Credential.UserName)"
                $Script:CWAToken = $AutomateToken
            }
            If ($AuthorizationToken) {
                #Build the token
                $AutomateToken = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
                $Null = $AutomateToken.Add("Authorization", "Bearer $AuthorizationToken")
                Write-Debug "Setting Authorization Token to $($AutomateToken.Authorization)"
                $Script:CWAToken = $AutomateToken
            }
            Return
        }
        If (!$AuthorizationToken -and $PSCmdlet.ParameterSetName -eq 'verify') {
            Throw "Attempt to verify token failed. No token was provided or was cached."
            Return
        }
        Do {
            $AutomateAPIURI = ('https://' + $Server + '/cwa/api/v1')
            $testCredentials=$Credential
            If (!$Quiet) {
                If (!$Credential -and ($Force -or !$AuthorizationToken)) {
                    If (!$Force -and $Script:CWACredentials) {
                        $testCredentials = $Script:CWACredentials
                    } Else {
                        $Username = Read-Host -Prompt "Please enter your Automate Username"
                        $Password = Read-Host -Prompt "Please enter your Automate Password" -AsSecureString
                        $Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)
                        $testCredentials=$Credential
                    }
                }
                If ($TwoFactorNeeded -eq $True -and $TwoFactorToken -match '') {
                    $TwoFactorToken = Read-Host -Prompt "Please enter your 2FA Token"
                }
            }

            If ($testCredentials) {
                #Build the headers for the Authentication
                $PostBody = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
                $PostBody.Add("username", $testCredentials.UserName)
                $PostBody.Add("password", $testCredentials.GetNetworkCredential().Password)
                If (!([string]::IsNullOrEmpty($TwoFactorToken))) {
                    #Remove any spaces that were added
                    $TwoFactorToken = $TwoFactorToken -replace '\s', ''
                    $PostBody.Add("TwoFactorPasscode", $TwoFactorToken)
                }
                $RESTRequest = @{
                    'URI' = ($AutomateAPIURI + '/apitoken')
                    'Method' = 'POST'
                    'ContentType' = 'application/json'
                    'Body' = $($PostBody | ConvertTo-Json -Compress)
                }
            } ElseIf ($PSCmdlet.ParameterSetName -eq 'refresh') {
                $PostBody = $AuthorizationToken -replace 'Bearer ',''
                $RESTRequest = @{
                    'URI' = ($AutomateAPIURI + '/apitoken/refresh')
                    'Method' = 'POST'
                    'ContentType' = 'application/json'
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

            #Invoke the REST Method
            Write-Debug "Submitting Request to $($RESTRequest.URI)`nHeaders:`n$($RESTRequest.Headers|ConvertTo-JSON -Depth 5)`nBody:`n$($RESTRequest.Body|ConvertTo-JSON -Depth 5)"
            Try {
                $AutomateAPITokenResult = Invoke-RestMethod @RESTRequest
            }
            Catch {
                Remove-Variable CWAToken,CWATokenKey -Scope Script -ErrorAction 0
                If ($testCredentials) {
                    Remove-Variable CWACredentials -Scope Script -ErrorAction 0
                }
                If ($Credential) {
                    Throw "Attempt to authenticate to the Automate API has failed with error $_.Exception.Message"
                    Return
                }
            }
            
            $AuthorizationToken=$AutomateAPITokenResult.Accesstoken
            If ($PSCmdlet.ParameterSetName -eq 'verify' -and !$AuthorizationToken -and $AutomateAPITokenResult) {
                $AuthorizationToken = $Script:CWAToken.Authorization -replace 'Bearer ',''
            }
            $TwoFactorNeeded=$AutomateAPITokenResult.IsTwoFactorRequired
        } Until ($Quiet -or ![string]::IsNullOrEmpty($AuthorizationToken) -or 
                ($TwoFactorNeeded -ne $True -and $Credential) -or 
                ($TwoFactorNeeded -eq $True -and $TwoFactorToken -ne '')
            )
    } #End Process

    End {
        If ($SkipCheck) {
            If ($Quiet) {
                Return $False
            } Else {
                Return
            }
        } ElseIf ([string]::IsNullOrEmpty($AuthorizationToken)) {
            Remove-Variable CWAToken -Scope Script -ErrorAction 0
            Throw "Unable to get Access Token. Either the credentials you entered are incorrect or you did not pass a valid two factor token" 
            If ($Quiet) {
                Return $False
            } Else {
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
            If ($Credential) {
                $Script:CWACredentials = $Credential
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