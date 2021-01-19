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

    Version:        1.2.2
    Author:         Darren White
    Creation Date:  2021-01-12
    Purpose/Change: Support custom Server URI path
                    Reference: https://docs.connectwise.com/ConnectWise_Control_Documentation/On-premises/Get_started_with_ConnectWise_Control_On-Premise/Change_ports_for_an_on-premises_installation

    Version:        1.2.3
    Author:         Darren White
    Creation Date:  2021-01-19
    Purpose/Change: Regex Fix

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
        $AuthorizationResult=$Null
        $Script:CWCIsConnected = $False
        $Server = $Server -replace ':(?<=^https:[^:]+:)443(?!\d)|:(?<=^http:[^:]+:)80(?!\d)|/$', '' #Cleanup URL, remove port specification for standard port values
        $testCWCHeaders = @{'Origin'=$Server -replace '/(?<=://.+).*$',''}
        If ($Script:CWAClientID) {$testCWCHeaders.Add('ClientID',$Script:CWAClientID)}
    }
    
    Process {
        # This indicates an error state because the server is not in a valid format. Triggering will immediately throw an error
        If (!($Server -match 'https?://[a-z0-9][a-z0-9\.\-]*(:[1-9][0-9]*)?(\/[a-z0-9\._\-\/]*)?$')) {$Server=$Null; throw "Control Server address ($Server) is in invalid format."; return}

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
                    $SvrCheck = Invoke-WebRequest $Server -Headers $testCWCHeaders -Method Head -UseBasicParsing
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
                'Method'  = 'GET'
                'Headers' = $testCWCHeaders
                'URI'     = "$($Server)/App_Extensions/${Script:CWCExtensionID}/Service.ashx/GetServerVersion"
            }

            $RESTRequest.Headers.Add('CWAIKToken',(Get-CWAIKToken -APIKey $APIKey))
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

            $testCredential=$Credential
            If (!$Quiet) {
                If (!$testCredential -and !$Script:ControlAPICredentials -and $PSCmdlet.ParameterSetName -ne 'verify') {
                    # If we have not been given credentials, lets ask for them
                    $Username = Read-Host -Prompt "Please enter your Control Username"
                    $Password = Read-Host -Prompt "Please enter your Control Password" -AsSecureString
                    $Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)
                    $testCredential=$Credential
                }
                If ($TwoFactorNeeded -eq $True -and $TwoFactorToken -match '') {
                    #Just putting this framework here. 2FA is not currently supported.
                    $TwoFactorToken = Read-Host -Prompt "Please enter your 2FA Token"
                }
            }

            If (!$testCredential -and $Script:ControlAPICredentials) {
                $testCredential = $Script:ControlAPICredentials
            }

            # Clear the ControlAPICredentials variable
            Remove-Variable ControlAPICredentials -Scope Script -ErrorAction 0

            If ($SkipCheck) {
                # Skip check is used in the parallel jobs so that when Connect-ControlAPI is called in a parallel job it doesn't test the credential each time
                Return # Bypass "Processing", execution resumes in the End {} Block.
            }

            # Now we will test the credentials
            # Build up the REST request that we will use to test with
            $RESTRequest = @{
                'URI'         = "$($Server)/App_Extensions/${Script:CWCExtensionID}/Service.ashx/GetServerVersion"
                'Headers'     = $testCWCHeaders
                'Method'      = 'GET'
                'ContentType' = 'application/json; charset=utf-8'
                'Credential'  = $testCredential
            }

            # Invoke the REST Request
            Write-Debug "Submitting Request to $($RESTRequest.URI)`nHeaders:`n$($RESTRequest.Headers|ConvertTo-JSON -Depth 5)`nBody:`n$($RESTRequest.Body|ConvertTo-JSON -Depth 5)"
            Try {
                $AuthorizationResult = Invoke-RestMethod @RESTRequest
            }
            Catch {
                Write-Debug "Request Results: $($AuthorizationResult|ConvertTo-Json -Depth 5 -Compress -EA 0)"
                If ($Credential) {
                    Remove-Variable ControlAPICredentials -Scope Script -ErrorAction 0
                    Throw "Attempt to authenticate to the Control server has failed with error $($_.Exception.Message|Out-String)"
                    Return
                }
            }
        } 
    }

    End {
        If ($SkipCheck -and (!$Server -or ($PSCmdlet.ParameterSetName -eq 'apikey' -and ($Null -eq $APIKey)) -or ($PSCmdlet.ParameterSetName -eq 'credential' -and ($Null -eq $testCredential)))) {
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
            If ($PSCmdlet.ParameterSetName -eq 'credential' -or $testCredential) {
                # Set the credentials at the script level
                $Script:ControlAPICredentials = $testCredential
            } 
            ElseIf ($PSCmdlet.ParameterSetName -eq 'apikey' -or $APIKey) {
                $Script:ControlAPIKey = $APIKey
            }
            Else {
                Throw "Error - No parameter set was recognized."
            }
            $Script:ControlServer = $Server
            $Script:CWCHeaders = $testCWCHeaders
            $Script:CWCIsConnected = $True

            If (!$Quiet) {
                If (!$SkipCheck) {
                    Try {
                        $CWCExtension = Invoke-ControlAPIMaster -Arguments @{'URI' = "ReplicaService.ashx/ExtensionGetExtensionInfos"} | Where-Object {$_.ExtensionID -eq $Script:CWCExtensionID}
                        Write-Host -BackgroundColor Green -ForegroundColor Black "Control Extension version $($CWCExtension.Version) enabled: $($CWCExtension.IsEnabled)"
                    } Catch {Write-Warning "Failed to obtain extension information."}
                    Write-Host -BackgroundColor Green -ForegroundColor Black "Server version is $($AuthorizationResult)."
                    Write-Host -BackgroundColor Green -ForegroundColor Black "Successfully tested and connected to the Control API."
                } Else {
                    Write-Host -BackgroundColor Green -ForegroundColor Black "Successfully stored Control Server parameters"
                }
            } Else {
                Return $True
            }
        }
    }
}
