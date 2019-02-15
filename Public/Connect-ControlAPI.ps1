function Connect-ControlAPI {
    <#
    .SYNOPSIS
    Adds credentials required to connect to the Control API
    .DESCRIPTION
    Creates a Control hashtable in memory containing the server and username/password so that it can be used in other functions that connect to ConnectWise Control. Unfortunately the Control API does not support 2FA.
    .PARAMETER Server
    The address to your Control Server. Example 'https://control.rancorthebeast.com:8040'
    .PARAMETER ControlCredentials
    Takes a standard powershell credential object, this can be built with $CredentialsToPass = Get-Credential, then pass $CredentialsToPass
    .PARAMETER Quiet
    Will not output any standard logging messages
    .PARAMETER TestCredentials
    Performs a test to the API
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
    Connect-ControlAPI -Server "https://control.rancorthebeast.com:8040" -ControlCredentials $CredentialsToPass
    #>
    [CmdletBinding(DefaultParameterSetName = 'refresh')]
    param (
        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [System.Management.Automation.PSCredential]$ControlCredentials,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Parameter(ParameterSetName = 'refresh', Mandatory = $False)]
        [String]$Server = $Script:ControlServer,

#        [Parameter(ParameterSetName = 'refresh', Mandatory = $False)]
#        [String]$AuthorizationToken = ($Script:ControlAPICredentials),

#        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
#        [String]$TwoFactorToken,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Switch]$Force,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Switch]$SkipTest,

        [Parameter(ParameterSetName = 'credential', Mandatory = $False)]
        [Parameter(ParameterSetName = 'refresh', Mandatory = $False)]
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
        If (!$AuthorizationToken) {$AuthorizationToken = $Script:ControlAPICredentials}
        If (!$SkipTest) {
            Do {
                $ControlAPITestURI = ($Server + '/Services/PageService.ashx/GetHostSessionInfo')
                If (!$Quiet) {
                    If (!$ControlCredentials -and ($Force -or !$AuthorizationToken)) {
                        $AuthorizationToken = $Null
                        $Username = Read-Host -Prompt "Please enter your Control Username"
                        $Password = Read-Host -Prompt "Please enter your Control Password" -AsSecureString
                        $ControlCredentials = New-Object System.Management.Automation.PSCredential ($Username, $Password)
                    }
                    If ($TwoFactorNeeded -eq $True -and $TwoFactorToken -match '') {
                        $TwoFactorToken = Read-Host -Prompt "Please enter your 2FA Token"
                    }
                }

                #Invoke the REST Method
                Write-Debug "Submitting Request to $ControlAPITestURI"
                If (!$AuthorizationToken) {$AuthorizationToken=$ControlCredentials}
                Try {
                    $ControlAPITokenResult = Invoke-RestMethod -Uri $ControlAPITestURI -Method Get -Credential $AuthorizationToken
                }
                Catch {
                    $Script:ControlAPICredentials = $Null
                    If ($ControlCredentials) {
                        Throw "Unable to connect to Control. Server or Control Credentials are wrong. This module does not support 2FA for Control Users"
                        Return
                    }
                }
                $AuthorizationResult=$ControlAPITokenResult.Version
                $TwoFactorNeeded=$ControlAPITokenResult.IsTwoFactorRequired
            } Until ($Quiet -or ![string]::IsNullOrEmpty($AuthorizationResult) -or 
                    ($TwoFactorNeeded -ne $True -and $ControlCredentials) -or 
                    ($TwoFactorNeeded -eq $True -and $TwoFactorToken -ne '')
                )
        }
    }
    
    End {
        If ([string]::IsNullOrEmpty($AuthorizationToken)) {
            Throw "Unable to get Access Token. Either the credentials your entered are incorrect or you did not pass a valid two factor token" 
            If ($Quiet) {
                Return $False
            }
        } Else {
            $Script:ControlAPICredentials = $AuthorizationToken
            $Script:ControlServer = $Server
            If (!$Quiet) {
                Write-Host -BackgroundColor Green -ForegroundColor Black "Successfully tested and connected to the Control API. Server version is $($ControlAPITokenResult.ProductVersion)"
            } Else {
                Return $True
            }
        }
    }
}
