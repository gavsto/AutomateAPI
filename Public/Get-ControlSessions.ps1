function Get-ControlSessions {
<#
.Synopsis
   Gets bulk session info from Control using the Automate Control Extension
.DESCRIPTION
   Gets all Session GUIDs in Control and then gets each session info out 100 at a time
.PARAMETER SesssionGroup
   The session group to target, defaults to all machines
.EXAMPLE
   Get-ControlSesssions
.INPUTS
   None
.OUTPUTS
   Custom object of session details for all sessions
#>
    [CmdletBinding()]
    param (
        # Parameter group - defaults to All Machines
        [Parameter(Mandatory = $false)]
        [string]
        $SessionGroup = "All Machines"
    )
    
    begin {
        # Get all the GUIDs out of Control
        $URlGuids = "$($ControlServer)/App_Extensions/fc234f0e-2e8e-4a1f-b977-ba41b14031f7/Service.ashx/GetSessionGuids"
        try {
            $SessionGuids = Invoke-RestMethod -Uri $urlguids -Method Get -Credential $Script:ControlAPICredentials
        }
        catch {
            Write-Error "Unable to get GUIDS out of Control $_.Exception.Message"
        }

        #Split the GUIDs into chunks of 100 so we can bulk submit them
        $SplitGUIDsArray = Split-Every -list $SessionGuids -count 100

        $Query = "" 
        $Version = "5"
        $FinalArray = @()
        $Null = Get-RSJob | Remove-RSJob | out-null
    }
    
    process {
    }
    
    end {
        #Create a result array object
        $ResultArray = @()
        for ($i = 0; $i -lt $SplitGUIDsArray.Count; $i++) {
            $Body = ConvertTo-Json @($SessionGroup,$Query,$SplitGUIDsArray[$i],$Version)
            $ResultArray += [pscustomobject] @{
                Body = $Body
            } 
        }
        
        
        $ResultArray | Start-RSJob -Throttle 20 -Name {"Dunno"} -ScriptBlock {
            Import-Module AutomateAPI -Force
            try{
                $SessionGroupof100 = Invoke-RestMethod -Uri "$($using:ControlServer)/App_Extensions/fc234f0e-2e8e-4a1f-b977-ba41b14031f7/Service.ashx/GetSessionsInfo" -Method POST -Credential $($using:ControlAPICredentials) -ContentType "application/json" -Body $($_.Body)
            }
            Catch
            {
                Write-Output "Error: $_"
            }
            return $SessionGroupof100
        } | out-null

        while ($(Get-RSJob | Where-Object {$_.State -ne 'Completed'} | Measure-Object | Select-Object -ExpandProperty Count) -gt 0) {
            Start-Sleep -Milliseconds 1000
            Write-Host -ForegroundColor Yellow "$(Get-Date) - There are currently $(Get-RSJob | Where-Object{$_.State -ne 'Completed'} | Measure-Object | Select-Object -ExpandProperty Count) jobs left to complete"
         }

        $AllSessionsResult =  Get-RSJob | Receive-RSJob
        $Null = Get-RSJob | Remove-RSJob | out-null

        return $AllSessionsResult.Sessions
    }
}

