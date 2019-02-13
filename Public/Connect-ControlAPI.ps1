function Connect-ControlAPI {
    <#
    .SYNOPSIS
    Creates a Control Credential in Memory.
    .DESCRIPTION
    Creates a Control hashtable in memory containing the server and username/password so that it can be used in other functions that connect to ConnectWise Control. Unfortunately the Control API does not support 2FA.
    .PARAMETER Server
    The address to your Control Server. Example 'https://control.rancorthebeast.com:8040'
    .PARAMETER ControlCredentials
    Takes a standard powershell credential object, this can be built with $CredentialsToPass = Get-Credential, then pass $CredentialsToPass
    .PARAMETER Quiet
    Will not output any standard logging messages
    .OUTPUTS
    One hashtable called $ControlCredentials
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
    [CmdletBinding()]
    param (
        [Parameter(mandatory = $false)]
        [System.Management.Automation.PSCredential]$ControlCredentials,

        [Parameter(mandatory = $false)]
        [string]$Server,

        [Parameter(mandatory = $false)]
        [switch]$Quiet
    )
    
    begin {
        if (!$Server) {
            $Server = Read-Host -Prompt "Please enter your Control Server address, the full URL. IE https://control.rancorthebeast.com:8040" 
        }
        if (!$ControlCredentials) {
            $Username = Read-Host -Prompt "Please enter your Control Username"
            $Password = Read-Host -Prompt "Please enter your Control Password" -AsSecureString
            $ControlCredentials = New-Object System.Management.Automation.PSCredential ($Username, $Password)
        }
    }
    
    process {

        $Script:ControlCredentials = $ControlCredentials
        $Script:ControlServer = $Server

        if (!$Quiet) {
            Write-Host  -BackgroundColor Green -ForegroundColor Black "Control Credentials Stored for use"
        }

    }
    
    end {
    }
}
