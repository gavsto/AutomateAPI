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
        Version:        2.1
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
    .EXAMPLE
        Get-AutomateComputer -ComputerID 5 | Get-ControlSessions | Invoke-ControlCommand -Powershell -Command "Get-Service"
    .EXAMPLE
        Invoke-ControlCommand -SessionID $SessionID -Command 'hostname'
            Will return the hostname of the machine.
    .EXAMPLE
        Invoke-ControlCommand -SessionID $SessionID -User $User -Password $Password -TimeOut 120000 -Command 'iwr -UseBasicParsing "https://bit.ly/ltposh" | iex; Restart-LTService' -PowerShell
            Will restart the Automate agent on the target machine.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [guid[]]$SessionID,
        [string]$Command,
        [int]$TimeOut = 10000,
        [int]$MaxLength = 5000,
        [switch]$PowerShell,
        [ValidateSet('Wait', 'Queue', 'Skip')] 
        $OfflineAction = 'Wait',
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20
    )

    Begin {

        $Server = $Script:ControlServer -replace '/$', ''

        # Format command
        $FormattedCommand = @()
        if ($Powershell) {
            $FormattedCommand += '#!ps'
        }
        $FormattedCommand += "#timeout=$TimeOut"
        $FormattedCommand += "#maxlength=$MaxLength"
        $FormattedCommand += $Command
        $FormattedCommand = $FormattedCommand | Out-String
        $SessionEventType = 44

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
        If (!($Server -match 'https?://[a-z0-9][a-z0-9\.\-]*(:[1-9][0-9]*)?$')) {throw "Control Server address is in invalid format."; return}
        If ($SessionID) {
            $SessionIDCollection += $SessionID
        }
    }

    End {
        $SplitGUIDsArray = Split-Every -list $SessionIDCollection -count $BatchSize
        ForEach ($GUIDs IN $SplitGUIDsArray) {
            $RemainingGUIDs = {$GUIDs}.Invoke()
#            Write-Debug "Starting with $(foreach ($x in $RemainingGUIDs) {$x})"
            If ($OfflineAction -ne 'Wait') {
                #Check Online Status. Weed out sessions that have never connected or are not valid.
                $ControlSessions = Get-ControlSessions -SessionID $RemainingGUIDs | Select-Object -Unique
                If ($OfflineAction -eq 'Skip') {
#                    write-debug "checking for skips"
                    ForEach ($GUID in $ControlSessions.Keys) {
                        If (!($ControlSessions[$GUID] -eq $True)) {
                            $ResultSet += [pscustomobject]@{
                                'SessionID' = $GUID
                                'Output'    = 'Skipped. Session was not connected.'
                            }
#                            Write-Debug "Removing Session $($GUID)"
                            $Null = $RemainingGUIDs.Remove($GUID)
                        }
                    }
                }
            }

            If (!$RemainingGUIDs) {
                Continue; #Nothing to process
            }
            $xGUIDS=@(ForEach ($x in $RemainingGUIDs) {$x})
            $Body = ConvertTo-Json @($User, $xGUIDS, $SessionEventType, $FormattedCommand) -Compress
#            Write-Verbose $Body

            $RESTRequest = @{
                'URI'         = "$Server/App_Extensions/fc234f0e-2e8e-4a1f-b977-ba41b14031f7/ReplicaService.ashx/PageAddEventToSessions"
                'Method'      = 'POST'
                'ContentType' = 'application/json'
                'Body'        = $Body
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
            $RequestTimer = [diagnostics.stopwatch]::StartNew()

            $EventDate = Get-Date $($Results.Headers.Date)
            $EventDateFormatted = (Get-Date $EventDate.ToUniversalTime() -UFormat "%Y-%m-%d %T")

            $Looking = $True
            $TimeOutDateTime = (Get-Date).AddMilliseconds($TimeOut)

            while ($Looking) {
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
                }

                If ($Script:ControlAPIKey) {
                    $RESTRequest.Add('Headers', @{'CWAIKToken' = (Get-CWAIKToken)})
                } Else {
                    $RESTRequest.Add('Credential', $Script:ControlAPICredentials)
                }

#                Write-Verbose "$($Body|Out-String)"
                Try {
                    $SessionEvents = Invoke-RestMethod @RESTRequest
                } Catch {
                    Write-Error $($_.Exception.Message)
                }
#                Write-Verbose ($SessionEvents|Out-String)

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
                            Write-Debug "Checking if GUID $GUID is online: $($ControlSessions[$GUID.ToString()])"
                            If ($ControlSessions[$GUID.ToString()] -eq $True) {$GUID}
                        }
                    )
                }

                Write-Debug "$($WaitingForGUIDs.Count) sessions remaining after $($RequestTimer.Elapsed.TotalSeconds) seconds."
#                Write-Verbose "$($WaitingForGUIDs|Out-String)"
                If (!($WaitingForGUIDs.Count -gt 0)) {
                    $Looking = $False
                    If ($RemainingGUIDs) {
                        ForEach ($GUID in $RemainingGUIDs) {
                            $ResultSet += [pscustomobject]@{
                            'SessionID' = $GUID
                            'Output'    = 'Command was queued for the session.'
                            }
                        }
                        return $Output -Join ""
                    }
                }

                if ($Looking -and $(Get-Date) -gt $TimeOutDateTime.AddSeconds(1)) {
                    $Looking = $False
                    ForEach ($GUID in $RemainingGUIDs) {
                        If ($OfflineAction -ne 'Wait' -and $ControlSessions[$GUID.ToString()] -eq $False) {
                            $ResultSet += [pscustomobject]@{
                                'SessionID' = $GUID
                                'Output'    = 'Command was queued for the session'
                            }
                        } Else {
                            $ResultSet += [pscustomobject]@{
                                'SessionID' = $GUID
                                'Output'    = 'Command timed out when sent to Agent'
                            }
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