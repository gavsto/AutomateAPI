function Connect-AutomateAPI {
    <#
      .SYNOPSIS
        Connect to the Automate API.
      .DESCRIPTION
        Connects to the Automate API and returns a bearer token which when passed with each requests grants up to an hours worth of access.
      .PARAMETER Server
        The address to your Automate Server. Example 'rancor.hostedrmm.com' - Do not use or prefix https://
      .PARAMETER AutomateCredentials
        Takes a standard powershell credential object, this can be built with $CredentialsToPass = Get-Credential, then pass $CredentialsToPass
      .PARAMETER TwoFactorToken
        Takes a string that represents the 2FA number
      .PARAMETER Quiet
        Will not output any standard logging messages
      .OUTPUTS
        Three strings into global variables, $CWAUri containing the server address, $CWACredentials containing the bearer token and $CWACredentialsExpirationDate containing the date the credentials expire
      .NOTES
        Version:        1.0
        Author:         Gavin Stone
        Creation Date:  20/01/2019
        Purpose/Change: Initial script development
      .EXAMPLE
        Connect-AutomateAPI -Server "rancor.hostedrmm.com" -AutomateCredentials $CredentialObject -TwoFactorToken "999999"
    #>
    [CmdletBinding()]
    param (
        [Parameter(mandatory = $false)]
        [System.Management.Automation.PSCredential]$AutomateCredentials,

        [Parameter(mandatory = $false)]
        [string]$Server,

        [Parameter(mandatory = $false)]
        [string]$TwoFactorToken,

        [Parameter(mandatory = $false)]
        [switch]$Quiet
    )
    
    begin {
        # Check for locally stored credentials
        [string]$CredentialDirectory = "$($env:USERPROFILE)\AutomateAPI\"
        $LocalCredentialsExist = Test-Path "$($CredentialDirectory)Automate - Credentials.txt"
        $TwoFactorNeeded=$False

        While (!($Server -match '.+')) {
            If ($Global:CWAUri -match 'https://.+') {
                $Server = $Global:CWAUri
            } Else {
                $Server = Read-Host -Prompt "Please enter your Automate Server address, without the HTTPS, IE: rancor.hostedrmm.com" 
            }
        }
        $Server = $Server -replace '^https?://','' -replace '/.*',''
    }
    
    Process {
        'I am here'
        Do {
            $AutomateAPIURI = "https://$Server/cwa/api/v1/apitoken"
            If (!$AutomateCredentials -and !($Global:CWACredentials.Authorization)) {
                $Username = Read-Host -Prompt "Please enter your Automate Username"
                $Password = Read-Host -Prompt "Please enter your Automate Password" -AsSecureString
                $AutomateCredentials = New-Object System.Management.Automation.PSCredential ($Username, $Password)
            }
'stinking 2fa'
            If ($TwoFactorNeeded -eq $True) {
                $TwoFactorToken = Read-Host -Prompt "Please enter your 2FA Token"
            }

            If ($AutomateCredentials) {
                #Build the headers for the Authentication
                $PostHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
                $PostHeaders.Add("username", $AutomateCredentials.UserName)
                $PostHeaders.Add("password", $AutomateCredentials.GetNetworkCredential().Password)
                If ($TwoFactorToken -or -not([string]::IsNullOrEmpty($TwoFactorToken))) {
                    #Remove any spaces that were added
                    $TwoFactorToken = $TwoFactorToken -replace '\s', ''
                    $PostHeaders.Add("TwoFactorPasscode", $TwoFactorToken)
                }
            } Else {
                $AutomateAPIURI = $AutomateAPIURI + '/refresh'
                $PostHeaders = $Global:CWACredentials.Authorization -replace 'Bearer ',''
            }
'postit'
            #Convert the body to JSON for Posting
            $PostBody = $PostHeaders | ConvertTo-Json
            #Clear Credential Variables
            Clear-Variable -Name CWACredentials, CWACredentialsExpirationDate -Scope Global -EA 0
            #Invoke the REST Method
            Write-Debug "Submitting Request to $AutomateAPIURI with body: `n$PostBody"
            Try {
                $AutomateAPITokenResult = Invoke-RestMethod -Method post -Uri $AutomateAPIURI -Body $PostBody -ContentType "application/json" -ErrorAction Stop
#Dont forget to remove the next line
$Global:APITokenResultTest=$AutomateAPITokenResult
            }
            Catch {
                If ($AutomateCredentials) {
                    Write-Error "Attempt to authenticated to the Automate API has failed with error $_.Exception.Message"
                }
            }
            If (@($True,$False) -contains ($AutomateAPITokenResult.IsTwoFactorRequired)) {
                $TwoFactorNeeded=$AutomateAPITokenResult.IsTwoFactorRequired
            }
        } Until (
                ![string]::IsNullOrEmpty($AutomateAPITokenResult.accesstoken) -or 
                ($TwoFactorNeeded -eq $False -and $AutomateCredentials) -or 
                ($TwoFactorNeeded -eq $True -and $TwoFactorToken -ne '')
            )
        if ([string]::IsNullOrEmpty($AutomateAPITokenResult.accesstoken)) {
            throw "Unable to get Access Token. Either the credentials your entered are incorrect or you did not pass a valid two factor token"
        }

        Write-Verbose "Token retrieved, $AutomateAPITokenResult.accesstoken, expiration is $AutomateAPITokenResult.ExpirationDate"

        #Build the returned token
        $AutomateToken = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $AutomateToken.Add("Authorization", "Bearer $($AutomateAPITokenResult.accesstoken)")
        Write-Debug "Setting Credentials to $($AutomateToken.Authorization)"
        #Create Global Variables for this session in order to use the token
        $Global:CWAUri = ($server + "/cwa/api")
        $Global:CWACredentials = $AutomateToken
        $Global:CWACredentialsExpirationDate = $AutomateAPITokenResult.ExpirationDate

        if (!$Quiet) {
            Write-Host  -BackgroundColor Green -ForegroundColor Black "Automate Token Retrieved Successfully. Token will expire at $($AutomateAPITokenResult | Select -expandproperty ExpirationDate)"
        }

    }
    
    End {
    }
}