function Get-ControlSessions {
<#
.Synopsis
   Gets bulk session info from Control using the Automate Control Reporting Extension
.DESCRIPTION
   Gets bulk session info from Control using the Automate Control Reporting Extension
.PARAMETER SessionID
    The GUID identifier for the machine you want status information on. If not provided, all sessions will be returned.
.NOTES
    Version:        1.3
    Author:         Gavin Stone 
    Modified By:    Darren White
    Purpose/Change: Initial script development

    Update Date:    2019-02-23
    Author:         Darren White
    Purpose/Change: Added SessionID parameter to return information only for requested sessions.

    Update Date:    2019-02-26
    Author:         Darren White
    Purpose/Change: Include LastConnected value if reported.
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
        $SessionIDCollection = $SessionIDCollection | Select-Object -Unique
        $SplitGUIDsArray = @(Split-Every -list $SessionIDCollection -count 100)
        If (!$SplitGUIDsArray) {$SplitGUIDsArray=@('')}
        $SCStatus=@{}
        $Now = Get-Date
        ForEach ($GUIDs in $SplitGUIDsArray) {
            If ('' -ne $GUIDS) {
                Write-Verbose "Starting on a new array $($GUIDs)"
                $GuidCondition=$(ForEach ($GUID in $GUIDs) {"sessionid='$GUID'"}) -join ' OR '
                If ($GuidCondition) {$GuidCondition="($GuidCondition) AND"}
            }
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
            
            Write-Debug "Submitting Request to $($RESTRequest.URI)`nHeaders:`n$(ConvertTo-JSON $($RESTRequest.Headers) -Depth 5 -Compress)`nBody:`n$($RESTRequest.Body|Out-String)"
            Try {
                $SCData = Invoke-RestMethod @RESTRequest
                Write-Debug "Request Result: $($SCData | select-object -property * | convertto-json -Depth 10 -Compress)"
                If ($SCData.FieldNames -contains 'SessionID' -and $SCData.FieldNames -contains 'EventType' -and $SCData.FieldNames -contains 'LastTime') {
                    $AllData += $($SCData.Items.GetEnumerator() | select-object @{Name='SessionID'; Expression={$_[0]}},@{Name='Event'; Expression={$_[1]}},@{Name='Date'; Expression={$_[2]}} | sort-Object SessionID,Event -Descending)
                } Else {
                    Throw "Attempt to authenticate the Control API Key has failed with error $_.Exception.Message"
                    Return
                }
            } Catch {
                Write-Debug "FAILED! Request Result: $($SCData | select-object -property * | convertto-json -Depth 10)"
            }
            $SCConnected = @{};
            $AllData | ForEach-Object {
                If ($_.Event -like 'Disconnected') {
                    $SCConnected.Add($_.SessionID,$_.Date)
                } Else {
                    If ($_.Date -ge $SCConnected[$_.SessionID]) {
                        If ($SCConnected.ContainsKey($_.SessionID)) {
                            $SCConnected[$_.SessionID]=$True
                        } Else {
                            $SCConnected.Add($_.SessionID,$True)
                        }
                    }
                }
            }
            Foreach ($sessid IN $($SCConnected.Keys)) {
                $SessionResult = [pscustomobject]@{
                    SessionID = $sessid
                    OnlineStatusControl = $Null
                    LastConnected = $Null
                    }
                If ($SCConnected[$sessid] -eq $True) {
                    $SessionResult.OnlineStatusControl = $True
                    $SessionResult.LastConnected = $Now
                } Else {
                    $SessionResult.OnlineStatusControl = $False
                    $SessionResult.LastConnected = $SCConnected[$sessid]
                }
                $SCStatus.Add($sessid,$SessionResult)
            }
        }
        Return $SCStatus
    }
}

