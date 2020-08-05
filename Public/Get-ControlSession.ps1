function Get-ControlSession {
<#
.Synopsis
   Gets bulk session info from Control using the Automate Control Reporting Extension
.DESCRIPTION
   Gets bulk session info from Control using the Automate Control Reporting Extension
.PARAMETER SessionID
    The Session(s) you want information on. If not provided, all sessions will be returned.
.PARAMETER IncludeProperty
    Specify additional Fields to be returned from the Session report endpoint as properties.
.NOTES
    Version:        1.6.0
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

    Update Date:    2020-07-04
    Author:         Darren White
    Purpose/Change: LastConnected type will be DateTime. An output will be returned for all inputs as individual objects.

    Update Date:    2020-07-20
    Author:         Darren White
    Purpose/Change: Include valid sessions even if there are no connection events in history.

    Update Date:    2020-07-28
    Author:         Darren White
    Purpose/Change: Added IncludeEnded, IncludeCustomProperties, IncludeProperty parameters to optionally return additional information

.EXAMPLE
   Get-ControlSession -SessionID 00000000-0000-0000-0000-000000000000

   Return an object with the SessionID,OnlineStatusControl,LastConnected properties
.EXAMPLE
    $SessionList=Get-ControlSession -IncludeProperty 'CreatedTime','GuestMachineSerialNumber','GuestHardwareNetworkAddress','Name' -IncludeCustomProperties
    $ExtraSessions=$SessionList | Group-Object -Property CustomProperty1,Name,GuestMachineSerialNumber,GuestHardwareNetworkAddress | Foreach-Object {$_.Group|Sort-Object CreatedTime -Desc | Select-Object -skip 1}
    $ExtraSessions | Invoke-ControlCommand -CommandID 21

    Will return session information to find duplicate sessions (same CustomProperty1,Name,GuestMachineSerialNumber,GuestHardwareNetworkAddress), and end all but the most recently created.
.EXAMPLE
   Get-ControlSession -SessionID 00000000-0000-0000-0000-000000000000 -IncludeScreenShot | Foreach-Object {If ($_.GuestScreenshotContent) {Set-Content -Path "sc-$($_.SessionID).jpg" -value ([Convert]::FromBase64String($_.GuestScreenshotContent)) -Encoding Byte}}

   Will retrieve and save the session screenshot
.INPUTS
   None
.OUTPUTS
   Custom object of session details
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$False,ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [guid[]]$SessionID,

        # Fields available for the Session report can be gathered from "${Script:ControlServer}/Report.json" - May add additional supported fields
        [ValidateSet(
        'Code','ConnectionCount','CreatedTime',
        'CustomProperty1','CustomProperty2','CustomProperty3','CustomProperty4','CustomProperty5','CustomProperty6','CustomProperty7','CustomProperty8',
        'EventCount','GuestAttributes','GuestDurationSeconds','GuestHardwareNetworkAddress',
        'GuestInfoUpdateTime','GuestLastActivityTime','GuestLastBootTime','GuestLoggedOnUserDomain','GuestLoggedOnUserName',
        'GuestMachineDescription','GuestMachineDomain','GuestMachineManufacturerName','GuestMachineModel','GuestMachineName','GuestMachineProductNumber','GuestMachineSerialNumber',
        'GuestOperatingSystemLanguage','GuestOperatingSystemManufacturerName','GuestOperatingSystemName','GuestOperatingSystemVersion',
        'GuestPrivateNetworkAddress','GuestProcessorArchitecture','GuestProcessorName','GuestProcessorVirtualCount',
        #'GuestScreenshotContent','GuestScreenshotContentHash','GuestScreenshotContentType' not included in field list - Can include with the -IncludeScreenShot switch
        'GuestSystemMemoryAvailableMegabytes','GuestSystemMemoryTotalMegabytes','GuestTimeZoneName','GuestTimeZoneOffsetHours','GuestWakeToken',
        'Host','HostDurationSeconds','IsEnded','IsPublic','LegacyEncryptionKey','Name','SessionType','UnknownDurationSeconds',
        '*')]
        [string[]]$IncludeProperty,
    
        [Parameter()]
        #Returns CustomProperty1 through CustomProperty8 on the output object
        [switch]$IncludeCustomProperties,

        [Parameter()]
        #Returns GuestScreenshotContent,GuestScreenshotContentHash,GuestScreenshotContentType on the output object
        [switch]$IncludeScreenShot,

        [Parameter()]
        #Include results for sessions that existed but have been ended.
        [switch]$IncludeEnded
    )

    Begin {
        $MaxRecords=10000
        $InputSessionIDCollection=@()
        $SCConnected = @{};
        $SessionLookup = @{};
        If ($IncludeProperty -contains '*') {
            $IncludeProperty+=((Get-Variable IncludeProperty).Attributes | Where-Object { $_ -is [System.Management.Automation.ValidateSetAttribute] }).ValidValues
        }
        [string[]]$IncludeProperty=$IncludeProperty | Where-Object {$_ -and $_ -ne '*'} #Redefine $IncludeProperty to allow additional values
        [string[]]$SessionFields=@('SessionID','SessionType','CreatedTime','GuestLastActivityTime','IsEnded')
        If ($IncludeEnded) {
            $IncludeProperty+='IsEnded'
        }
        If ($IncludeCustomProperties) {
            $IncludeProperty+=@('CustomProperty1','CustomProperty2','CustomProperty3','CustomProperty4','CustomProperty5','CustomProperty6','CustomProperty7','CustomProperty8')
        }
        If ($IncludeScreenShot) {
            $IncludeProperty+=@('GuestScreenshotContent','GuestScreenshotContentHash','GuestScreenshotContentType')
        }
        If ($IncludeProperty) {
            $IncludeProperty=$IncludeProperty | Select-Object -Unique
            [string[]]$SessionFields=$( $SessionFields.GetEnumerator(); $IncludeProperty.GetEnumerator() ) | Select-Object -Unique
        }
    }
    
    Process {
        # Gather Sessions from the pipeline for Bulk Processing.
        If ($SessionID) {
            Foreach ($Session IN $SessionID) {
                $InputSessionIDCollection+=$Session.ToString()
            }
        }
    }
    
    End {
        Function New-ReturnObject {
            param([object]$InputObject, [object]$ExtraObject, [string[]]$Property)
            If (!$Property) {$Property=$ExtraObject.psobject.Properties.Name}
            Foreach ($PropertyName IN $Property) {
                $InputObject | Add-Member -NotePropertyName $PropertyName -NotePropertyValue $ExtraObject.$PropertyName -Force
            }
            $InputObject
        }

        # Ensure the session list does not contain duplicate values.
        $SessionIDCollection = @($InputSessionIDCollection | Select-Object -Unique)
        #Split the list into groups of no more than 100 items
        $SplitGUIDsArray = Split-Every -list $SessionIDCollection -count 100
        If (!$SplitGUIDsArray) {Write-Debug "Resetting to include all Sessions"; $SplitGUIDsArray=@('')}
        ForEach ($GUIDs in $SplitGUIDsArray) {
            $GuidCondition=$(ForEach ($GUID in $GUIDs) {If ($GUID) {"sessionid='$GUID'"}}) -join ' OR '
            If ($GuidCondition) {$GuidCondition="($GuidCondition) AND"}
            $GuidCondition=@($GuidCondition,"DisconnectedTime IS NULL") -join ' '
            $Body=ConvertTo-Json @("SessionConnection",@("SessionID"),@("Count"),$GuidCondition.Trim(), "", $MaxRecords) -Compress

            $RESTRequest = @{
                'URI' = "ReportService.ashx/GenerateReportForAutomate"
                'Body' = $Body
            }
            $AllData = Invoke-ControlAPIMaster -Arguments $RESTRequest
            If ($AllData.Count -ge $MaxRecords) {Write-Verbose "Records returned ($($AllData.Count)) equal maximum requested. Data may be incomplete!"}

            $AllData | Where-Object {$_} | ForEach-Object {
                # Build $SCConnected hashtable with information from report request in $AllData - First pass - Only online sessions
                $SCConnected.Add($_.SessionID,$True)
            }

            $GuidCondition=$(ForEach ($GUID in $GUIDs) {If ($GUID -and ($IncludeProperty -or !($SCConnected.ContainsKey($GUID)))) {"sessionid='$GUID'"}}) -join ' OR '
            If (('' -eq $GUIDs) -or $GuidCondition) { #Pull information on sessions that are not connected
                $Body=ConvertTo-Json @("Session","",$SessionFields,"$GuidCondition", "", $MaxRecords) -Compress

                $RESTRequest = @{
                    'URI' = "ReportService.ashx/GenerateReportForAutomate"
                    'Body' = $Body
                }
                $AllData = Invoke-ControlAPIMaster -Arguments $RESTRequest
                If ($AllData.Count -ge $MaxRecords) {Write-Verbose "Records returned ($($AllData.Count)) equal maximum requested. Data may be incomplete!"}

                $AllData | Where-Object {$_.SessionID} | ForEach-Object {
                    If (!$_.IsEnded -or $_.IsEnded -eq $IncludeEnded) {
                        If ($SessionLookup.ContainsKey($_.SessionID)) {
                            $SessionLookup.$($_.SessionID)=$_
                        } Else {
                            $SessionLookup.Add($_.SessionID,$_)
                        }
                    }
                    If ($_.GuestLastActivityTime -and !($_.IsEnded) -and !($SCConnected.ContainsKey($_.SessionID))) {
                        $SCConnected.Add($_.SessionID,$_.GuestLastActivityTime)
                    } ElseIf ($_.IsEnded -and $SCConnected.ContainsKey($_.SessionID)) {
                        $SCConnected.Remove(($_.SessionID))
                    }
                }
            }

            $GuidCondition=$(ForEach ($GUID in $GUIDs) {If ($GUID -and $SCConnected.ContainsKey($GUID) -and $SCConnected[$GUID] -ne $True) {"sessionid='$GUID'"}}) -join ' OR '
            If ($GuidCondition) {$GuidCondition="($GuidCondition) AND"}
            If (('' -eq $GUIDs) -or $GuidCondition) { #Pull information on valid sessions that are not connected
                $Body=ConvertTo-Json @("SessionConnection",@("SessionID"),@("LastDisconnectedTime"),"$GuidCondition ProcessType='Guest'", "", $MaxRecords) -Compress

                $RESTRequest = @{
                    'URI' = "ReportService.ashx/GenerateReportForAutomate"
                    'Body' = $Body
                }
                $AllData = Invoke-ControlAPIMaster -Arguments $RESTRequest
                If ($AllData.Count -ge $MaxRecords) {Write-Verbose "Records returned ($($AllData.Count)) equal maximum requested. Data may be incomplete!"}

                $AllData | Where-Object {$_} | ForEach-Object {
                    If ($_.LastDisconnectedTime -and $SCConnected.ContainsKey($_.SessionID) -and $SCConnected[$_.SessionID] -ne $True) {
                        $SCConnected[$_.SessionID]=$_.LastDisconnectedTime
                    }
                }
            }
        }

        # If no sessions were requested, just send returned sessions.
        If (!($InputSessionIDCollection)) {$InputSessionIDCollection = $SCConnected.Keys}

        #Build final output objects with session information gathered into $SCConnected hashtable
        $Now = Get-Date 
        Foreach ($sessid IN $InputSessionIDCollection) {
            $sessid=$sessid.ToString()
            $SessionResult = [pscustomobject]@{
                SessionID = $sessid
                OnlineStatusControl = $False
                LastConnected = $Null
                }
            If ($SCConnected[$sessid] -eq $True) {
                $SessionResult.OnlineStatusControl = $True
                $SessionResult.LastConnected = $Now
            } ElseIf ($Null -ne $SCConnected[$sessid]) {
                $SessionResult.LastConnected = Get-Date($SCConnected[$sessid])
            }
            If ($IncludeProperty) {
                    $SessionResult=New-ReturnObject -InputObject $SessionResult -ExtraObject $SessionLookup[$sessid] -Property $IncludeProperty
            }
            $SessionResult
        }
    }
}

Set-Alias -Name Get-ControlSessions -Value Get-ControlSession
