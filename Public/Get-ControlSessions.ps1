function Get-ControlSessions {
<#
.Synopsis
   Gets bulk session info from Control using the Automate Control Reporting Extension
.DESCRIPTION
   Gets bulk session info from Control using the Automate Control Reporting Extension
.PARAMETER SessionID
    The GUID identifier(s) for the machine you want status information on. If not provided, all sessions will be returned.
.NOTES
    Version:        1.4
    Author:         Gavin Stone 
    Modified By:    Darren White
    Purpose/Change: Initial script development

    Update Date:    2019-02-23
    Author:         Darren White
    Purpose/Change: Added SessionID parameter to return information only for requested sessions.

    Update Date:    2019-02-26
    Author:         Darren White
    Purpose/Change: Include LastConnected value if reported.

    Update Date:    2019-06-24
    Author:         Darren White
    Purpose/Change: Modified output to be collection of objects instead of a hastable.

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
        $SCConnected = @{};
    }
    
    process {
        # Gather Sessions from the pipeline for Bulk Processing.
        If ($SessionID) {
            $SessionIDCollection+=$SessionID
        }
    }
    
    end {
        # Ensure the session list does not contain duplicate values.
        $SessionIDCollection = @($SessionIDCollection | Select-Object -Unique)
        #Split the list into groups of no more than 100 items
        $SplitGUIDsArray = Split-Every -list $SessionIDCollection -count 100
        If (!$SplitGUIDsArray) {Write-Debug "Resetting to include all GUIDs"; $SplitGUIDsArray=@('')}
        $Now = Get-Date 
        ForEach ($GUIDs in $SplitGUIDsArray) {
            If ('' -ne $GUIDs) {
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
            $AllData=$Null
            Try {
                $SCData = Invoke-RestMethod @RESTRequest
                Write-Debug "Request Result: $($SCData | select-object -property * | convertto-json -Depth 10 -Compress)"
                If ($SCData.FieldNames -contains 'SessionID' -and $SCData.FieldNames -contains 'EventType' -and $SCData.FieldNames -contains 'LastTime') {
                    $AllData = $($SCData.Items.GetEnumerator() | select-object @{Name='SessionID'; Expression={$_[0]}},@{Name='Event'; Expression={$_[1]}},@{Name='Date'; Expression={$_[2]}} | sort-Object SessionID,Event -Descending)
                } Else {
                    Throw "Session report data was not returned: Error $_.Exception.Message"
                    Return
                }
            } Catch {
                Write-Debug "Request FAILED! Request Result: $($SCData | select-object -property * | convertto-json -Depth 10)"
            }

            $AllData | Where-Object {$_} | ForEach-Object {
                # Build $SCConnected hashtable with information from report request in $AllData
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
        }
        #Build final output objects with session information gathered into $SCConnected hashtable

        # Combine requested sessions with returned sessions
        $SessionIDCollection += $SCConnected.Keys
        #Ensure the session list does not contain duplicate values.
        $SessionIDCollection = @($SessionIDCollection | Select-Object -Unique)

        $SCStatus = $(
            Foreach ($sessid IN $SessionIDCollection) {
                $sessid=$sessid.ToString()
                write-debug "assigning status for $sessid"
                $SessionResult = [pscustomobject]@{
                    SessionID = $sessid
                    OnlineStatusControl = $Null
                    LastConnected = $Null
                    }
                If ($SCConnected[$sessid] -eq $True) {
                    $SessionResult.OnlineStatusControl = $True
                    $SessionResult.LastConnected = $Now.ToUniversalTime()
                } Else {
                    $SessionResult.OnlineStatusControl = $False
                    $SessionResult.LastConnected = $SCConnected[$sessid]
                }
                $SessionResult
            }
        )
        Return $SCStatus
    }
}

