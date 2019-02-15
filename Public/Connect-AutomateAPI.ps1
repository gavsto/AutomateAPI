function Connect-AutomateAPI {
<#
.SYNOPSIS
Connect to the Automate API.
.DESCRIPTION
Connects to the Automate API and returns a bearer token which when passed with each requests grants up to an hours worth of access.
.PARAMETER Server
The address to your Automate Server. Example 'rancor.hostedrmm.com'
.PARAMETER AutomateCredentials
Takes a standard powershell credential object, this can be built with $CredentialsToPass = Get-Credential, then pass $CredentialsToPass
.PARAMETER TwoFactorToken
Takes a string that represents the 2FA number
.PARAMETER Token
Used internally when quietly refreshing the Token
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
Connect-AutomateAPI -Server "rancor.hostedrmm.com" -AutomateCredentials $CredentialObject -TwoFactorToken "999999"

.EXAMPLE
Connect-AutomateAPI -Quiet
#>
    [CmdletBinding(DefaultParameterSetName = 'refresh')]
    param (
        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [System.Management.Automation.PSCredential]$AutomateCredentials,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Parameter(ParameterSetName = 'refresh', Mandatory = $False)]
        [String]$Server = $Script:CWAServer,

        [Parameter(ParameterSetName = 'refresh', Mandatory = $False)]
        [String]$AuthorizationToken = ($Script:CWACredentials.Authorization -replace 'Bearer ',''),

        [Parameter(ParameterSetName = 'refresh', Mandatory = $False)]
        [Switch]$SkipCheck,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [String]$TwoFactorToken,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Switch]$Force,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Parameter(ParameterSetName = 'refresh', Mandatory = $False)]
        [Switch]$Quiet
    )

    Begin {
        # Check for locally stored credentials
#        [string]$CredentialDirectory = "$($env:USERPROFILE)\AutomateAPI\"
#        $LocalCredentialsExist = Test-Path "$($CredentialDirectory)Automate - Credentials.txt"
        if ($TwoFactorToken -match '.+') {$Force=$True}
        $TwoFactorNeeded=$False

        If (!$Quiet) {
            While (!($Server -match '.+')) {
                $Server = Read-Host -Prompt "Please enter your Automate Server address, without the HTTPS, IE: rancor.hostedrmm.com" 
            }
        }
        $Server = $Server -replace '^https?://','' -replace '/.*',''
        $AuthorizationToken = $AuthorizationToken -replace 'Bearer ',''
    } #End Begin
    
    Process {
        if (!($Server -match '^[a-z0-9][a-z0-9\.\-]*$')) {throw "Server address is missing or in invalid format."; return}
        if ($SkipCheck) {
            #Build the returned token
            $AutomateToken = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $AutomateToken.Add("Authorization", "Bearer $AuthorizationToken")
            Write-Debug "Setting Credentials to $($AutomateToken.Authorization)"
            $Script:CWAServer = ("https://" + $Server)
            $Script:CWACredentials = $AutomateToken
            return
        }
        Do {
            $AutomateAPIURI = ('https://' + $Server + '/cwa/api/v1/apitoken')
            If (!$Quiet) {
                If (!$AutomateCredentials -and ($Force -or !$AuthorizationToken)) {
                    $Username = Read-Host -Prompt "Please enter your Automate Username"
                    $Password = Read-Host -Prompt "Please enter your Automate Password" -AsSecureString
                    $AutomateCredentials = New-Object System.Management.Automation.PSCredential ($Username, $Password)
                }
                If ($TwoFactorNeeded -eq $True -and $TwoFactorToken -match '') {
                    $TwoFactorToken = Read-Host -Prompt "Please enter your 2FA Token"
                }
            }

            If ($AutomateCredentials) {
                #Build the headers for the Authentication
                $PostHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
                $PostHeaders.Add("username", $AutomateCredentials.UserName)
                $PostHeaders.Add("password", $AutomateCredentials.GetNetworkCredential().Password)
                If (!([string]::IsNullOrEmpty($TwoFactorToken))) {
                    #Remove any spaces that were added
                    $TwoFactorToken = $TwoFactorToken -replace '\s', ''
                    $PostHeaders.Add("TwoFactorPasscode", $TwoFactorToken)
                }
            } Else {
                $AutomateAPIURI = $AutomateAPIURI + '/refresh'
                $PostHeaders = $AuthorizationToken -replace 'Bearer ',''
            }
            #Convert the body to JSON for Posting
            $PostBody = $PostHeaders | ConvertTo-Json -Compress

            #Invoke the REST Method
            Write-Debug "Submitting Request to $AutomateAPIURI with body: `n$PostBody"
            Try {
                $AutomateAPITokenResult = Invoke-RestMethod -Method Post -Uri $AutomateAPIURI -Body $PostBody -ContentType "application/json"
            }
            Catch {
                $Script:CWACredentials = $Null
                $Script:CWACredentialsExpirationDate = $Null
                If ($AutomateCredentials) {
                    Throw "Attempt to authenticated to the Automate API has failed with error $_.Exception.Message"
                    Return
                }
            }
            $AuthorizationToken=$AutomateAPITokenResult.Accesstoken
            $TwoFactorNeeded=$AutomateAPITokenResult.IsTwoFactorRequired
        } Until ($Quiet -or ![string]::IsNullOrEmpty($AuthorizationToken) -or 
                ($TwoFactorNeeded -ne $True -and $AutomateCredentials) -or 
                ($TwoFactorNeeded -eq $True -and $TwoFactorToken -ne '')
            )
    } #End Process

    End {
        If ([string]::IsNullOrEmpty($AuthorizationToken)) {
            Throw "Unable to get Access Token. Either the credentials you entered are incorrect or you did not pass a valid two factor token" 
            If ($Quiet) {
                Return $False
            }
        } Else {

            Write-Verbose "Token retrieved: $AuthorizationToken, expiration is $($AutomateAPITokenResult.ExpirationDate)"

            #Build the returned token
            $AutomateToken = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
            $AutomateToken.Add("Authorization", "Bearer $AuthorizationToken")
            Write-Debug "Setting Credentials to $($AutomateToken.Authorization)"
            #Create Script Variables for this session in order to use the token
            $Script:CWAServer = ("https://" + $Server)
            $Script:CWACredentials = $AutomateToken
            $Script:CWACredentialsExpirationDate = $AutomateAPITokenResult.ExpirationDate

            If (!$Quiet) {
                Write-Host -BackgroundColor Green -ForegroundColor Black "Successfully tested and connected to the Automate REST API. Token will expire at $($AutomateAPITokenResult.ExpirationDate)"
            } Else {
                Return $True
            }
        }
    }
}