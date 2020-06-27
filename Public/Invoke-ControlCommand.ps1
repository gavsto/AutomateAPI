function Invoke-ControlCommand {
    <#
    .SYNOPSIS
        Will issue a command against a given machine and return the results.
    .DESCRIPTION
        Will issue a command against a given machine and return the results.
    .PARAMETER SessionID
        The GUID identifier for the machine you wish to connect to.
        You can retrieve session info with the 'Get-ControlSessions' commandlet
        SessionIDs can be provided via the pipeline.
        IE - Get-AutomateComputer -ComputerID 5 | Get-ControlSessions | Invoke-ControlCommand -Powershell -Command "Get-Service"
    .PARAMETER Command
        The command you wish to issue to the machine.
    .PARAMETER MaxLength
        The maximum number of bytes to return from the remote session. The default is 5000 bytes.
    .PARAMETER PowerShell
        Issues the command in a powershell session.
    .PARAMETER TimeOut
        The amount of time in milliseconds that a command can execute. The default is 10000 milliseconds.
    .PARAMETER BatchSize
        Number of control sessions to invoke commands in parallel.
    .OUTPUTS
        The output of the Command provided.
    .NOTES
        Version:        2.2
        Author:         Chris Taylor
        Modified By:    Gavin Stone 
        Modified By:    Darren White
        Creation Date:  1/20/2016
        Purpose/Change: Initial script development

        Update Date:    2019-02-19
        Author:         Darren White
        Purpose/Change: Enable Pipeline support. Enable processing using Automate Control Extension. The cached APIKey will be used if present.

        Update Date:    2019-02-23
        Author:         Darren White
        Purpose/Change: Enable command batching against multiple sessions. Added OfflineAction parameter.
        
        Update Date:    2019-06-24
        Author:         Darren White
        Purpose/Change: Updates to process object returned by Get-ControlSessions
        
    .EXAMPLE
        Get-AutomateComputer -ComputerID 5 | Get-AutomateControlInfo | Invoke-ControlCommand -Powershell -Command "Get-Service"
            Will retrieve Computer Information from Automate, Get ControlSession data and merge with the input object, then call Get-Service on the computer.
    .EXAMPLE
        Invoke-ControlCommand -SessionID $SessionID -Command 'hostname'
            Will return the hostname of the machine.
    .EXAMPLE
        Invoke-ControlCommand -SessionID $SessionID -TimeOut 120000 -Command 'iwr -UseBasicParsing "https://bit.ly/ltposh" | iex; Restart-LTService' -PowerShell
            Will restart the Automate agent on the target machine.
    #>
    [CmdletBinding(DefaultParameterSetName = 'ExecuteCommand')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [guid[]]$SessionID,
        [Parameter(ParameterSetName = 'ExecuteCommand', Mandatory = $True)]
        [string]$Command,
        [Parameter(ParameterSetName = 'CommandID', Mandatory = $True)]
        [int]$CommandID,
        [Parameter(ParameterSetName = 'CommandID')]
        $CommandBody='',
        [Parameter(ParameterSetName = 'ExecuteCommand')]
        [int]$TimeOut = 10000,
        [Parameter(ParameterSetName = 'ExecuteCommand')]
        [int]$MaxLength = 5000,
        [Parameter(ParameterSetName = 'ExecuteCommand')]
        [switch]$PowerShell,
        [ValidateSet('Wait', 'Queue', 'Skip')] 
        $OfflineAction = 'Wait',
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20
    )

    Begin {

        $Server = $Script:ControlServer -replace '/$', ''

        If ($PSCmdlet.ParameterSetName -eq 'CommandID') {
            $SessionEventType = $CommandID
        } Else {
            # Format command
            $FormattedCommand = @()
            if ($Powershell) {
                $FormattedCommand += '#!ps'
            }
            $FormattedCommand += "#timeout=$TimeOut"
            $FormattedCommand += "#maxlength=$MaxLength"
            $FormattedCommand += $Command
            $CommandBody = $FormattedCommand | Out-String
            $SessionEventType = 44
        }

        If ($Script:ControlAPIKey) {
            $User = 'AutomateAPI'
        }
        ElseIf ($Script:ControlAPICredentials.UserName) {
            $User = $Script:ControlAPICredentials.UserName
        }
        Else {
            $User = ''
        }

        $SessionIDCollection = @()
        $ResultSet = @()

    }

    Process {
        If (!($Server -match 'https?://[a-z0-9][a-z0-9\.\-]*(:[1-9][0-9]*)?(\/[a-z0-9\.\-\/]*)?$')) {throw "Control Server address ($Server) is in an invalid format. Use Connect-ControlAPI to assign the server URL."; return}
        If ($SessionID) {
            $SessionIDCollection += $SessionID
        }
    }

    End {
        $SplitGUIDsArray = Split-Every -list $SessionIDCollection -count $BatchSize
        ForEach ($GUIDs in $SplitGUIDsArray) {
            If (!$GUIDs) {Continue} #Skip if Null value
            $RemainingGUIDs = {$GUIDs}.Invoke()
            If ($OfflineAction -ne 'Wait') {
                #Check Online Status. Weed out sessions that have never connected or are not valid.
                $ControlSessions=@{};
                Get-ControlSessions -SessionID $RemainingGUIDs | ForEach-Object {$ControlSessions.Add($_.SessionID, $($_|Select-Object -Property OnlineStatusControl,LastConnected))}
                If ($OfflineAction -eq 'Skip') {
                    ForEach ($GUID in $ControlSessions.Keys) {
                        If (!($ControlSessions[$GUID].OnlineStatusControl -eq $True)) {
                            $ResultSet += [pscustomobject]@{
                                'SessionID' = $GUID
                                'Output'    = 'Skipped. Session was not connected.'
                            }
                            $Null = $RemainingGUIDs.Remove($GUID)
                        }
                    }
                }
            }

            If (!$RemainingGUIDs) {
                Continue; #Nothing to process
            }
            $xGUIDS=@(ForEach ($x in $RemainingGUIDs) {$x})
            $Body = ConvertTo-Json @($User, $xGUIDS, $SessionEventType, $CommandBody) -Compress

            $RESTRequest = @{
                'URI'         = "$Server/App_Extensions/fc234f0e-2e8e-4a1f-b977-ba41b14031f7/ReplicaService.ashx/PageAddEventToSessions"
                'Method'      = 'POST'
                'ContentType' = 'application/json'
                'Body'        = $Body
                'UseBasicParsing' = $Null
            }
            If ($Script:ControlAPIKey) {
                $RESTRequest.Add('Headers', @{'CWAIKToken' = (Get-CWAIKToken)})
            } Else {
                $RESTRequest.Add('Credential', $Script:ControlAPICredentials)
            }

            # Issue command
            Try {
                $Results = Invoke-WebRequest @RESTRequest
            } Catch {
                Write-Error "$(($_.ErrorDetails | ConvertFrom-Json).message)"
                return
            }

            If ($PSCmdlet.ParameterSetName -eq 'ExecuteCommand') {
                $Looking = $True

                $RequestTimer = [diagnostics.stopwatch]::StartNew()

                $EventDate = Get-Date $($Results.Headers.Date)
                $EventDateFormatted = (Get-Date $EventDate.ToUniversalTime() -UFormat "%Y-%m-%d %T")

                $TimeOutDateTime = (Get-Date).AddMilliseconds($TimeOut)
            } Else {
                $Looking = $False
                $WaitingForGUIDs = $Null
            }

            while ($Looking -and $(Get-Date) -lt $TimeOutDateTime.AddSeconds(1)) {

                Start-Sleep -Seconds $(Get-SleepDelay -Seconds $([int]($RequestTimer.Elapsed.TotalSeconds)) -TotalSeconds $([int]($TimeOut / 1000)))

                #Build GUID Conditional
                $GuidCondition = $(ForEach ($GUID in $RemainingGUIDs) {"sessionid='$GUID'"}) -join ' OR '
                # Look for results of command
                $Body = ConvertTo-Json @("SessionConnectionEvent", @(), @("SessionID", "Time", "Data"), "($GuidCondition) AND EventType='RanCommand' AND Time>='$EventDateFormatted'", "", 200) -Compress
                $RESTRequest = @{
                    'URI'         = "$Server/App_Extensions/fc234f0e-2e8e-4a1f-b977-ba41b14031f7/ReportService.ashx/GenerateReportForAutomate"
                    'Method'      = 'POST'
                    'ContentType' = 'application/json'
                    'Body'        = $Body
                    'UseBasicParsing' = $Null
                }

                If ($Script:ControlAPIKey) {
                    $RESTRequest.Add('Headers', @{'CWAIKToken' = (Get-CWAIKToken)})
                } Else {
                    $RESTRequest.Add('Credential', $Script:ControlAPICredentials)
                }

                Try {
                    $SessionEvents = Invoke-RestMethod @RESTRequest
                } Catch {
                    Write-Error $($_.Exception.Message)
                }

                $FNames = $SessionEvents.FieldNames
                $Events = ($SessionEvents.Items | ForEach-Object {$x = $_; $SCEventRecord = [pscustomobject]@{}; for ($i = 0; $i -lt $FNames.Length; $i++) {$Null = $SCEventRecord | Add-Member -NotePropertyName $FNames[$i] -NotePropertyValue $x[$i]}; $SCEventRecord} | Sort-Object -Property Time,SessionID -Descending)
                foreach ($Event in $Events) {
                    if ($Event.Time -ge $EventDate.ToUniversalTime() -and $RemainingGUIDs.Contains($Event.SessionID)) {
                        $Output = $Event.Data
                        if (!$PowerShell) {
                            $Output = $Output -replace '^[\r\n]*',''
                        }
                        $ResultSet += [pscustomobject]@{
                            'SessionID' = $Event.SessionID
                            'Output'    = $Output
                        }
                        $Null = $RemainingGUIDs.Remove($Event.SessionID)
                    }
                }

                $WaitingForGUIDs = $RemainingGUIDs
                If ($OfflineAction -eq 'Queue') {
                    $WaitingForGUIDs=$(
                        ForEach ($GUID in $WaitingForGUIDs) {
                            Write-Debug "Checking if GUID $GUID is online: $($ControlSessions[$GUID.ToString()].OnlineStatusControl)"
                            If ($ControlSessions[$GUID.ToString()].OnlineStatusControl -eq $True) {$GUID}
                        }
                    )
                }

                Write-Debug "$($WaitingForGUIDs.Count) sessions remaining after $($RequestTimer.Elapsed.TotalSeconds) seconds."
                If (!($WaitingForGUIDs.Count -gt 0)) {
                    $Looking = $False
                }
            }
 
            If ($RemainingGUIDs) {
                ForEach ($GUID in $RemainingGUIDs) {
                    If ($WaitingForGUIDs -contains $GUID) {
                        $ResultSet += [pscustomobject]@{
                            'SessionID' = $GUID
                            'Output'    = 'Command timed out when sent to Agent'
                        }  
                    } Else {
                        $ResultSet += [pscustomobject]@{
                            'SessionID' = $GUID
                            'Output'    = 'Command was queued for the session.'
                        }
                    }
                }
            }
        }
        If ($ResultSet.Count -eq 1) {
            Return $ResultSet | Select-Object -ExpandProperty Output -ErrorAction 0
        } Else {
            Return $ResultSet
        }
    }
}