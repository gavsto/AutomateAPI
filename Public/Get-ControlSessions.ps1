function Get-ControlSessions {
<#
.Synopsis
   Gets bulk session info from Control using the Automate Control Reporting Extension
.DESCRIPTION
   Gets bulk session info from Control using the Automate Control Reporting Extension
.PARAMETER SessionID
    The GUID identifier for the machine you want status information on. If none is provided, all sessions will be returned.
.EXAMPLE
   Get-ControlSesssions
.INPUTS
   None
.OUTPUTS
   Custom object of session details for all sessions
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [guid[]]$SessionID
    )
    
    begin {
        $SessionIDCollection=@()
    }
    
    process {
        If ($SessionID) {
            $SessionIDCollection+=$SessionID
        }
    }
    
    end {
        $GuidCondition=$(ForEach ($GUID in $SessionIDCollection) {"sessionid='$GUID'"}) -join ' OR '
        If ($GuidCondition) {$GuidCondition="($GuidCondition) AND"}
        $Body=ConvertTo-Json @("SessionConnectionEvent",@("SessionID","EventType"),@("LastTime"),"$GuidCondition SessionConnectionProcessType='Guest' AND (EventType = 'Connected' OR EventType = 'Disconnected')", "", 20000) -Compress
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
        Write-Debug "Submitting Request to $($RESTRequest.URI)`nHeaders:`n$($RESTRequest.Headers|ConvertTo-JSON -Depth 5 -Compress)`nBody:`n$($RESTRequest.Body|Out-String)"
        Try {
            $SCData = Invoke-RestMethod @RESTRequest
            Write-Debug "Request Result: $($SCData | select-object -property * | convertto-json -Depth 10 -Compress)"
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
        } Catch {
            Write-Debug "FAILED! Request Result: $($SCData | select-object -property * | convertto-json -Depth 10)"
         }
        return $SCConnected
    }
}

