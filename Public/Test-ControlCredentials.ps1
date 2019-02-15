function Test-ControlCredentials {
<#
.Synopsis
   Tests Control Credentials as added in Connect-ControlAPI
.DESCRIPTION
   Tests Control Credentials as added in Connect-ControlAPI
.EXAMPLE
   Test-ControlCredentials
.PARAMETER Quiet
   Returns a simple true or false
.INPUTS
   None
.OUTPUTS
   Result of connection test - version
#>
    [CmdletBinding()]
    param (
      [Parameter(ParameterSetName = 'refresh', Mandatory = $False)]
      [Switch]$Quiet        
    )
    
    begin {        
    }
    
    process {
        $TestURL = "$($ControlServer)/Services/PageService.ashx/GetHostSessionInfo"

        try {
            $TestResult = Invoke-RestMethod -Uri $TestURL -Method Get -Credential $ControlCredentials
        }
        catch {
           if (!$Quiet) {
            Write-Error "Unable to connect to Control. Server or Control Credentials are wrong. This module does not support 2FA for Control Users"
            Return $false
           }
           else {
              Return $false
           }
            
        }

        if (!$Quiet) {
         Write-Host -BackgroundColor Green -ForegroundColor Black "Successfully tested and connected to the Control API. Server version is $($TestResult.ProductVersion)"
        }
        else {
           Return $true
        }

    }
    
    end {
    }
}