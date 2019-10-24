Function Invoke-AutomateAPIRestMethod {
<#
.SYNOPSIS
Invoke the Automate API to make a REST call.
.DESCRIPTION
Invokes the Automate API (including passing the pre-existing authentication token) and returns the result.
.PARAMETER Endpoint
The endpoint path for the API (ex. 'computers/1111/CommandPrompt').
.PARAMETER Method
The REST method to use (ex. 'GET', 'POST', etc). Defaults to 'GET'.
.PARAMETER Body
The HTTP body to pass, typically as a PowerShell array.
.OUTPUTS
Returns the result of the API call.
.NOTES
Version:        1.0
Author:         Jason Rush
Creation Date:  2019-10-24
Purpose/Change: Initial script development
.EXAMPLE
Invoke-AutomateAPIRestMethod -endpoint "DatabaseServerTime"
.EXAMPLE
Invoke-AutomateAPIRestMethod -endpoint "Computers" -Body @{ "Condition" = "(OperatingSystemName like '%Windows 7%')" }
.EXAMPLE
Invoke-AutomateAPIRestMethod -Endpoint "computers/1111/CommandPrompt?pagesize=-1&page=1&condition=null" -Method "POST" -Body @{ RunAsAdmin = $false; UsePowerShell = $true; CommandText = "gci 'C:\Users\'"; Directory = "C:\Users\" }
#>
    param(
        [Parameter(Mandatory = $True)]
        [string] $Endpoint,

        [Parameter(Mandatory = $False)]
        #TODO: Verify if additional HTTP methods are used by the CW Automate APIs.
        [ValidateSet("GET", "POST")]
        [string] $Method = "GET",

        [Parameter(Mandatory = $False)]
        [hashtable] $Body = @{},

        [Parameter(Mandatory = $False)]
        [hashtable] $Headers = @{}
    )

    process {
        # Add internal headers to hashtable to pass to Invoke-RestMethod call.
        #$Headers.add( "Accept", "application/json, text/plain, */*" )
        $Headers.add( "Authorization", $script:CWAToken['Authorization'] )

        # Verify if the current authentication token should still be valid, otherwise reconnect to the server.
        $TokenExpiration = [DateTime]::Parse($script:CWATokenInfo.ExpirationDate)
        if((Get-Date) -gt $TokenExpiration)
        {
            Connect-AutomateAPI
        }

        Invoke-RestMethod -Uri ($Script:CWAServer + '/cwa/api/v1/' + $Endpoint) -Method $Method -Headers $Headers -Body $Body #-ContentType "application/json" 
    }
}
