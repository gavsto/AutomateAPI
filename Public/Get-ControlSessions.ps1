function Get-ControlSessions {
<#
.Synopsis
   Gets bulk session info from Control using the Automate Control Reporting Extension
.DESCRIPTION
   Gets bulk session info from Control using the Automate Control Reporting Extension
.EXAMPLE
   Get-ControlSesssions
.INPUTS
   None
.OUTPUTS
   Custom object of session details for all sessions
#>
    [CmdletBinding()]
    param (
    )
    
    begin {
    }
    
    process {
    }
    
    end {
        $Body='["SessionConnectionEvent",["SessionID","EventType"],["LastTime"],"SessionConnectionProcessType=\u0027Guest\u0027 AND (EventType = \u0027Connected\u0027 OR EventType = \u0027Disconnected\u0027)",20000]'
        $SCData = Invoke-RestMethod -Uri "$($Script:ControlServer)/App_Extensions/fc234f0e-2e8e-4a1f-b977-ba41b14031f7/ReportService.ashx/GenerateReportForAutomate" -Method POST -Credential $($Script:ControlAPICredentials) -ContentType "application/json" -Body $Body
        $SCConnected = @{};
        $AllData = $SCData.Items.GetEnumerator() | select-object @{Name='SessionID'; Expression={$_[0]}},@{Name='Event'; Expression={$_[1]}},@{Name='Date'; Expression={$_[2]}} | sort-Object SessionID,Event -Descending;  
        $AllData | ForEach-Object {
            if (!($_.SessionID -and $_.Date -and $_.Event)) {'WARNING.. Weird data found.'; $_}
            if ($_.Event -like 'Disconnected') {
                $SCConnected.Add($_.SessionID,$_.Date)
            } else {
                if ($_.Date -ge $SCConnected[$_.SessionID]) {
                    if ($SCConnected.ContainsKey($_.SessionID)) {
                        $SCConnected[$_.SessionID]=$True
                    } else {
                        $SCConnected.Add($_.SessionID,$True)
                    }
                } else {
                    if ($SCConnected.ContainsKey($_.SessionID)) {
                        $SCConnected[$_.SessionID]=$False
                    } else {
                        $SCConnected.Add($_.SessionID,$False)
                    }
                }
            }
        }
        Foreach ($sessid IN $( ($SCConnected.GetEnumerator() | Where-Object {$_.Value -ne $True -and $_.Value -ne $False}).Key)) {$SCConnected[$sessid]=$False}
        return $SCConnected
    }
}

