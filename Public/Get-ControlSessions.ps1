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
        $Body=ConvertTo-Json @("SessionConnectionEvent",@("SessionID","EventType"),@("LastTime"),"SessionConnectionProcessType=""Guest"" AND (EventType = ""Connected"" OR EventType = ""Disconnected"")", "", 20000) -Compress
        $RESTRequest = @{
            'URI' = "${Script:ControlServer}/App_Extensions/fc234f0e-2e8e-4a1f-b977-ba41b14031f7/ReportService.ashx/GenerateReportForAutomate"
            'Method' = 'POST'
            'ContentType' = 'application/json'
            'Body' = $Body
        }
        If ($Script:ControlAPIKey) {
            $RESTRequest.Add('Headers',@{'CWAIKToken' = (Get-CWAIKToken)})
        } Else {
            $RESTRequest.Add('Credential',${Script:ControlAPICredentials})
        }
        
        $SCConnected = @{};
        Try {
            $SCData = Invoke-RestMethod @RESTRequest
            If ($SCData.FieldNames -contains 'SessionID' -and $SCData.FieldNames -contains 'EventType' -and $SCData.FieldNames -contains 'LastTime') {
                $AllData = $SCData.Items.GetEnumerator() | select-object @{Name='SessionID'; Expression={$_[0]}},@{Name='Event'; Expression={$_[1]}},@{Name='Date'; Expression={$_[2]}} | sort-Object SessionID,Event -Descending;  
                $AllData | ForEach-Object {
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
            } Else {
                Throw "Attempt to authenticate the Control API Key has failed with error $_.Exception.Message"
                Return
            }
        } Catch { }
        return $SCConnected
    }
}

