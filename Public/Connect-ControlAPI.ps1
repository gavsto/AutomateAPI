function Connect-ControlAPI {
    <#
    .SYNOPSIS
    Adds credentials required to connect to the Control API
    .DESCRIPTION
    Creates a Control hashtable in memory containing the server and username/password so that it can be used in other functions that connect to ConnectWise Control. Unfortunately the Control API does not support 2FA.
    .PARAMETER Server
    The address to your Control Server. Example 'https://control.rancorthebeast.com:8040'
    .PARAMETER Credential
    Takes a standard powershell credential object, this can be built with $CredentialsToPass = Get-Credential, then pass $CredentialsToPass
    .PARAMETER APIKey
    Automate APIKey for Control Extension
    .PARAMETER Verify
    Attempt to verify Cached API key or Credentials. Invalid results will be removed.
    .PARAMETER Quiet
    Will not output any standard logging messages. Function will returns True or False.
    .PARAMETER SkipCheck
    Used to set Server URL and Credentials without testing.
    .OUTPUTS
    Sets script variables with Server URL and Credentials or ApiKey.
    .NOTES
    Version:        1.0
    Author:         Gavin Stone
    Creation Date:  2019-01-20
    Purpose/Change: Initial script development

    Version:        1.1
    Author:         Gavin Stone
    Creation Date:  2019-06-22
    Purpose/Change: The previous function was far too complex. No-one could debug it and a lot of it was unnecessary. I have greatly simplified it.

    Version:        1.2
    Author:         Darren White
    Creation Date:  2019-06-24
    Purpose/Change: Added support for APIKey authentication. The new function was not complex enough.

    Version:        1.2.1
    Author:         Darren White
    Creation Date:  2020-12-01
    Purpose/Change: Added origin to standard header

    .EXAMPLE
    All values will be prompted for one by one:
    Connect-ControlAPI
    All values needed to Automatically create appropriate output
    Connect-ControlAPI -Server "https://control.rancorthebeast.com:8040" -Credential $CredentialsToPass
    #>
    [CmdletBinding(DefaultParameterSetName = 'credential')]
    param (
        [Parameter(ParameterSetName = 'credential', Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Parameter(ParameterSetName = 'apikey', Mandatory = $False)]
        [String]$Server = $Script:ControlServer,

        [Parameter(ParameterSetName = 'apikey', Mandatory = $False)]
        $APIKey = ([SecureString]$Script:ControlAPIKey),
        
        [Parameter(ParameterSetName = 'verify', Mandatory = $false)]
        [Switch]$Verify, 

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Parameter(ParameterSetName = 'apikey', Mandatory = $False)]
        [Switch]$SkipCheck,

        [Parameter()]
        [Switch]$Quiet
    )
    
    Begin {
        # If Quiet has been set, then do not prompt for the URL
        If (!$Quiet) {
            While (!($Server -match '.+')) {
                $Server = Read-Host -Prompt "Please enter your Control Server address, the full URL. IE https://control.rancorthebeast.com:8040" 
            }
        }
        $Server = $Server -replace '/$', ''
        $AuthorizationResult=$Null
        $Script:CWCIsConnected = $False
        $AntiForgeryToken=$Script:CWCHeaders.'x-anti-forgery-token'
    }
    
    Process {
        # This indicates an error state because the server is not in a valid format. Triggering will immediately throw an error
        If (!($Server -match 'https?://[a-z0-9][a-z0-9\.\-]*(:[1-9][0-9]*)?(\/[a-z0-9\.\-\/]*)?$')) {$Server=$Null; throw "Control Server address ($Server) is in invalid format."; return}

        If (($PSCmdlet.ParameterSetName -eq 'apikey' -or $PSCmdlet.ParameterSetName -eq 'verify') -and $Null -ne $APIKey) {
            # Authenticating with an APIKey
            # Clear the ControlAPICredentials variable
            Remove-Variable ControlAPICredentials -Scope Script -ErrorAction 0
            If ($APIKey.GetType() -notmatch 'SecureString') {
                # If the key was passed as plaintext, convert to Secure String
                [SecureString]$APIKey = ConvertTo-SecureString $APIKey -AsPlainText -Force 
            }

            If ($SkipCheck) {
                # Skip check is used in the parallel jobs so that when Connect-ControlAPI is called in a parallel job it doesn't test the credential each time
                Return # Bypass "Processing", execution resumes in the End {} Block.
            } Else {
                # Watch for time offset problems
                Try {
                    $SvrCheck = Invoke-WebRequest $Server -Method Head -UseBasicParsing
                    $SvrOffset=New-TimeSpan -Start $(Get-Date ($SvrCheck.Headers.Date))
                    Write-Debug "Server Time $($SvrCheck.Headers.Date) is $([Math]::Truncate($SvrOffset.TotalSeconds)) seconds offset from local clock"
                    If ([Math]::ABS($SvrOffset.TotalMinutes) -gt 30) {
                        Write-Warning "Server time offset is greater than 30 minutes. Authentication failures may occur."
                    }
                } Catch {}
            }

            # Clear the ControlAPIKey variable
            Remove-Variable ControlAPIKey -Scope Script -ErrorAction 0
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
                Throw "Attempt to authenticate the Control API Key has failed with error $_.Exception.Message"
            }
        } Else {
            # Authenticating with Credentials.
            # Clear the ControlAPIKey variable
            Remove-Variable ControlAPIKey -Scope Script -ErrorAction 0

            IF ($PSCmdlet.ParameterSetName -eq 'verify' -and $Null -eq $Credential) {
                # The Verify parameter will use the current ControlAPICredentials value.
                $Credential = $Script:ControlAPICredentials
            }
            # Clear the ControlAPICredentials variable
            Remove-Variable ControlAPICredentials -Scope Script -ErrorAction 0

            # If we have not been given credentials, lets ask for them
            If (!$Credential -and !$Quiet) {
                $Username = Read-Host -Prompt "Please enter your Control Username"
                $Password = Read-Host -Prompt "Please enter your Control Password" -AsSecureString
                $Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)
            }

            If ($SkipCheck) {
                # Skip check is used in the parallel jobs so that when Connect-ControlAPI is called in a parallel job it doesn't test the credential each time
                Return # Bypass "Processing", execution resumes in the End {} Block.
            }

            # Retrieve AntiForgeryToken
            Try {
                $SvrCheck = Invoke-WebRequest $Server -Method Get -UseBasicParsing | Select-Object -Expand Content | Select-String -Pattern '"antiForgeryToken":"([^"]*)"' 
                If ($SvrCheck -and $SvrCheck.Matches -and $SvrCheck.Matches.Count -gt 0) {
                    $AntiForgeryToken = $SvrCheck.Matches.Groups[1].Value
                    Write-Debug "AntiForgeryToken $($AntiForgeryToken) retrieved"
                } Else {Write-Verbose "No AntiForgeryToken was found"}
            } Catch {}

            # Now we will test the credentials
            # Build up the REST request that we will use to test with
            $ControlAPITestURI = ($Server + '/Services/PageService.ashx/GetHostSessionInfo')
            $RESTRequest = @{
                'URI'         = $ControlAPITestURI
                'Method'      = 'GET'
                'ContentType' = 'application/json'
                'Credential'  = $Credential
            }
            If ($AntiForgeryToken) {$RESTRequest.Add('Headers',@{'x-anti-forgery-token'=$AntiForgeryToken})}
            Write-Debug "Submitting Request to $($RESTRequest.URI)"

            # Invoke the REST Request
            Try {
                $ControlAPITokenResult = Invoke-RestMethod @RESTRequest
            }
            Catch {
                # The authentication has failed, so remove the credentials from the script scope and throw an error
                Write-Debug $_.Exception.Message
                Throw "Unable to connect to Control. Server Address or Control Credentials are wrong. This module does not support 2FA for Control Users"
            }
            Write-Debug "Request Results: $($ControlAPITokenResult|ConvertTo-Json -Depth 5 -Compress)"
        
            # Set the auth result to the product version
            $AuthorizationResult = $ControlAPITokenResult.ProductVersion
        } 
    }

    End {
        If ($SkipCheck -and (!$Server -or ($PSCmdlet.ParameterSetName -eq 'apikey' -and ($Null -eq $APIKey)) -or ($PSCmdlet.ParameterSetName -eq 'credential' -and ($Null -eq $Credential)))) {
            # If Skipping Checks, validate required information exists and throw error if missing.
            Throw "SkipCheck failed because the Server, APIKey, or Credentials were not provided."
            If ($Quiet) {
                Return $False
            } Else {
                Return
            }
        } ElseIf ([string]::IsNullOrEmpty($AuthorizationResult) -and !$SkipCheck) {
            # If there was no authorization result then throw an error
            Throw "Unable to successfully authenticate. Either the credentials or APIKey provided are incorrect." 
            If ($Quiet) {
                Return $False
            }
            Else {
                Return
            }
        }
        Else {
            If ($PSCmdlet.ParameterSetName -eq 'credential' -or ($PSCmdlet.ParameterSetName -eq 'verify' -and $Credential)) {
                # Set the credentials at the script level
                $Script:ControlAPICredentials = $Credential
            } 
            ElseIf ($PSCmdlet.ParameterSetName -eq 'apikey' -or ($PSCmdlet.ParameterSetName -eq 'verify' -and $APIKey)) {
                $Script:ControlAPIKey = $APIKey
            }
            Else {
                Throw "Error - No parameter set was recognized."
            }
            $Script:ControlServer = $Server
            $Script:CWCIsConnected = $True
            $Script:CWCHeaders = @{'Origin'=$Server -replace ':\d+.*$',''}
            If ($AntiForgeryToken) {$Script:CWCHeaders.Add('x-anti-forgery-token',$AntiForgeryToken)}
            If ($Script:CWAClientID) {$Script:CWCHeaders.Add('ClientID',$Script:CWAClientID)}
            Write-Debug "CWC Header Set: $($Script:CWCHeaders|Out-String)"

            If (!$Quiet) {
                If (!$SkipCheck) {
                    Write-Host -BackgroundColor Green -ForegroundColor Black "Successfully tested and connected to the Control API. Server version is $($AuthorizationResult)"
                } Else {
                    Write-Host -BackgroundColor Green -ForegroundColor Black "Successfully stored Control Server parameters"
                }
            } Else {
                Return $True
            }
        }
    }
}
