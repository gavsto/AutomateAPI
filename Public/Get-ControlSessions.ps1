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
            $SessionGuids = Invoke-RestMethod -Uri $urlguids -Method Get -Credential $ControlCredentials
        }
        catch {
            Write-Error "Unable to get GUIDS out of Control $_.Exception.Message"
        }

        #Split the GUIDs into chunks of 100 so we can bulk submit them
        $SplitGUIDsArray = Split-Every -list $SessionGuids -count 100

        $Query = "" 
        $Version = "5"
        $FinalArray = @()
    }
    
    process {
        for ($i = 0; $i -lt $SplitGUIDsArray.Count; $i++) {
            $Body = ConvertTo-Json @($SessionGroup,$Query,$SplitGUIDsArray[$i],$Version)
            $URl = "$($ControlServer)/App_Extensions/fc234f0e-2e8e-4a1f-b977-ba41b14031f7/Service.ashx/GetSessionsInfo"
            $ProgressPreference = 'SilentlyContinue'
            $SessionDetails = ""
            $SessionDetails = Invoke-RestMethod -Uri $url -Method Post -Credential $ControlCredentials -ContentType "application/json" -Body $Body
            $FinalArray += $SessionDetails.Sessions
        }
    }
    
    end {
        return $FinalArray
    }
}

