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
    .PARAMETER Quiet
    Will not output any standard logging messages
    .OUTPUTS
    Two script variables with server and credentials. Returns True or False
    .NOTES
    Version:        1.0
    Author:         Gavin Stone
    Creation Date:  20/01/2019
    Purpose/Change: Initial script development

    Version: 1.1
    Author: Gavin Stone
    Creation Date: 22/06/2019
    Purpose/Change: The previous function was far too complex. No-one could debug it and a lot of it was unnecessary. I have greatly simplified it.

    .EXAMPLE
    All values will be prompted for one by one:
    Connect-ControlAPI
    All values needed to Automatically create appropriate output
    Connect-ControlAPI -Server "https://control.rancorthebeast.com:8040" -Credentials $CredentialsToPass
    #>
    param (
        [Parameter(ParameterSetName = 'credential', Mandatory = $false)]
        [System.Management.Automation.PSCredential]$Credential,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [String]$Server = $Script:ControlServer,

        [Parameter()]
        [Switch]$Quiet,

        [Parameter()]
        [Switch]$SkipCheck
    )
    
    Begin {
        # If Quiet has been set, then do not prompt out for the URL
        If (!$Quiet) {
            While (!($Server -match '.+')) {
                $Server = Read-Host -Prompt "Please enter your Control Server address, the full URL. IE https://control.rancorthebeast.com:8040" 
            }
        }
        $Server = $Server -replace '/$', ''
    }
    
    Process {
        # This indicates an error state because the server is not in a valid format. Triggering will immediately throw an error
        If (!($Server -match 'https?://[a-z0-9][a-z0-9\.\-]*(:[1-9][0-9]*)?$')) { throw "Control Server address is in invalid format."; return }

        # If we have not been given credentials, lets ask for them
        If (!$Credential) {
            $Username = Read-Host -Prompt "Please enter your Control Username"
            $Password = Read-Host -Prompt "Please enter your Control Password" -AsSecureString
            $Credential = New-Object System.Management.Automation.PSCredential ($Username, $Password)
        }

        # Skip check is used in the parallel jobs so that when Connect-ControlAPI is called in a parallel job it doesn't test the credential each time
        if (!$SkipCheck) {
            # Now we will test the credentials
            # Build up the REST request that we will use to test with
            $ControlAPITestURI = ($Server + '/Services/PageService.ashx/GetHostSessionInfo')
            $RESTRequest = @{
                'URI'         = $ControlAPITestURI
                'Method'      = 'GET'
                'ContentType' = 'application/json'
                'Credential'  = $Credential
            }
            Write-Debug "Submitting Request to $($RESTRequest.URI)"

            # Invoke the REST Request
            Try {
                $ControlAPITokenResult = Invoke-RestMethod @RESTRequest
            }
            Catch {
                # The authentication has failed, so remove the credentials from the script scope and throw an error
                Remove-Variable ControlAPICredentials -Scope Script -ErrorAction 0
                Throw "Unable to connect to Control. Server Address or Control Credentials are wrong. This module does not support 2FA for Control Users"
            }
            Write-Debug "Request Results: $($ControlAPITokenResult|ConvertTo-Json -Depth 5 -Compress)"
        
            # Set the auth result to the product version
            $AuthorizationResult = $ControlAPITokenResult.ProductVersion 
        }
    }

    End {
        # If there was no authorization result then throw an error
        If ([string]::IsNullOrEmpty($AuthorizationResult) -and (!$SkipCheck)) {
            Remove-Variable ControlAPICredentials -Scope Script -ErrorAction 0
            Throw "Unable to get Access Token. Either the credentials provided are incorrect or you did not pass a valid two factor token" 
            If ($Quiet) {
                Return $False
            }
            Else {
                Return
            }
        }
        Else {
            # Set the credentials at the script level
            $Script:ControlAPICredentials = $Credential
            $Script:ControlServer = $Server
            If (!$Quiet) {
                Write-Host -BackgroundColor Green -ForegroundColor Black "Successfully tested and connected to the Control API. Server version is $($AuthorizationResult)"
            }
            Else {
                Return $True
            }
        }
    }
}
