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
    .PARAMETER ResultPropertyName
        String containing the name of the member you would like to add to the input pipeline object that will hold the result of this command
    .OUTPUTS
        The output of the Command provided.
    .NOTES
        Version:        2.2
        Author:         Chris Taylor
        Modified By:    Gavin Stone 
        Modified By:    Darren White
        Creation Date:  2016-01-20
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

        Update Date:    2019-08-20
        Author:         Darren Kattan
        Purpose/Change: Added ability to retain Computer object passed in from pipeline and append result of script to a named member of the computer object

        Update Date:    2020-07-04
        Author:         Darren White
        Purpose/Change: Removed object processing on the remote host. Added -CommandID support
        
    .EXAMPLE
        Get-AutomateComputer -ComputerID 5 | Get-AutomateControlInfo | Invoke-ControlCommand -Powershell -Command "Get-Service"
            Will retrieve Computer Information from Automate, Get ControlSession data and merge with the input object, then call Get-Service on the computer.
    .EXAMPLE
        Invoke-ControlCommand -SessionID $SessionID -Command 'hostname'
            Will return the hostname of the machine.
    .EXAMPLE
        Invoke-ControlCommand -SessionID $SessionID -TimeOut 120000 -Command 'iwr -UseBasicParsing "https://bit.ly/ltposh" | iex; Restart-LTService' -PowerShell
            Will restart the Automate agent on the target machine.
    .EXAMPLE
        $Results = Get-AutomateComputer -ClientName "Contoso" | Get-AutomateControlInfo | Invoke-ControlCommand -IncludeComputerName -ResultPropertyName "OfficePlatform" -PowerShell -Command { Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -Name Platform }
        $Results | select ComputerName, OfficePlatform
    .EXAMPLE
        $Results = Get-AutomateComputer -ClientName "Contoso" | Get-AutomateControlInfo | Invoke-ControlCommand -AsObjects -IncludeComputerName -ResultPropertyName "OfficeRegInfo" -PowerShell -Command { Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" }
        $Results | ?{$_.OfficeRegInfo.Platform -eq "x86" -and $_.OfficeRegInfo.UpdateEnabled -notlike "true"} | select ComputerName
    .EXAMPLE
        Invoke-ControlCommand -SessionID $SessionID -CommandID 40
            Will tell the control service to Reinstall (update)

    #>
    [CmdletBinding(DefaultParameterSetName = 'ExecuteCommand')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [guid[]]$SessionID,
        [Parameter(ParameterSetName = ('ExecuteCommand','PassthroughObjects'), Mandatory = $True)]
        [string]$Command,
        [Parameter(ParameterSetName = 'CommandID', Mandatory = $True)]
        [int]$CommandID,
        [Parameter(ParameterSetName = 'CommandID')]
        $CommandBody='',
        [Parameter(ParameterSetName = ('ExecuteCommand','PassthroughObjects'))]
        [int]$TimeOut = 10000,
        [Parameter(ParameterSetName = ('ExecuteCommand','PassthroughObjects'))]
        [int]$MaxLength = 5000,
        [Parameter(ParameterSetName = ('ExecuteCommand','PassthroughObjects'))]
        [switch]$PowerShell,
        [Parameter(ParameterSetName = ('ExecuteCommand','PassthroughObjects'))]
        [ValidateSet('Wait', 'Queue', 'Skip')] 
        $OfflineAction = 'Wait',
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20,
        [switch]$PassthroughObjects,
        [string]$ResultPropertyName = 'Output'        
    )

    Begin {
        $ProgressPreference='SilentlyContinue'

        $Server = $Script:ControlServer -replace '/$', ''
        If (('SessionID','IsSuccess') -contains $ResultPropertyName) {throw "ResultPropertyName value $($ResultPropertyName) is reserved."} 

        If ($PSCmdlet.ParameterSetName -eq 'CommandID') {
            $SessionEventType = $CommandID
        } Else {
            $cmdMarker="AUTOMATEAPICOMMAND:"+[GUID]::NewGuid().ToString().ToUpper().Replace('-','')
            # Format command
            $FormattedCommand = @()
            $FormattedCommand += "#timeout=$TimeOut"
            $FormattedCommand += "#maxlength=$MaxLength"
            if ($Powershell) {
                $FormattedCommand = @('#!ps',$($FormattedCommand),"`$ProgressPreference='SilentlyContinue'; ECHO $cmdMarker")
            } Else {
                $FormattedCommand += "@ECHO OFF&ECHO $cmdMarker"
            }
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

        $ResultObjects = @{ }
        $SessionCollection = {}.Invoke()

    }

    Process {
        $ObjectsIn=$_
        If (!($Server -match 'https?://[a-z0-9][a-z0-9\.\-]*(:[1-9][0-9]*)?(\/[a-z0-9\.\-\/]*)?$')) { throw "Control Server address ($Server) is in an invalid format. Use Connect-ControlAPI to assign the server URL."; return }
        If ($PassthroughObjects) {
            Foreach ($xObject in $ObjectsIn) {
                If ($xObject -and $xObject.SessionID) {
                    [string]$Session=$xObject.SessionID
                    If (!($ResultObjects.ContainsKey($Session))) {
                        $ResultObjects.Add($Session, [pscustomobject]@{SessionID = $Session })
                    } Else {Write-Warning "SesssionID $Session has already been added. Skipping"}
                    $Null = $SessionCollection.Add($xObject)
                } Else {Write-Warning "Input Object is missing SesssionID property"}
            }
        } Else {
            Foreach ($Session in $SessionID) {
                If ($Session.SessionID) {$Session=$Session.SessionID}
                [string]$Session="$($Session)"
                [pscustomobject]@{SessionID = $Session} | ForEach-Object {
                    If (!($ResultObjects.ContainsKey($Session))) {
                        $ResultObjects.Add($Session, $_)
                    } Else {Write-Warning "SesssionID $Session has already been added. Skipping"}
                    $Null = $SessionCollection.Add($_)
                }
            }
        }
    }

    End {
        Function New-ReturnObject {
            param([object]$InputObject, [object]$Result, [bool]$IsSuccess, [string]$PropertyName)            
            $InputObject | Add-Member -NotePropertyName $PropertyName -NotePropertyValue $Result -Force
            $InputObject | Add-Member -NotePropertyName 'IsSuccess' -NotePropertyValue $IsSuccess -Force
            $InputObject
        }
        
        $ProcessSessions=@($ResultObjects.Keys)
        $RemainingSessions={}.Invoke()
        $AddSessions={}.Invoke()
        $EventDateFormatted=$Null
        $SessionIndex=0
        Do {

            While (($AddSessions.Count+$RemainingSessions.Count) -lt $BatchSize -and $SessionIndex -lt $ProcessSessions.Count) {
                $AddSessions.Add($ProcessSessions[$SessionIndex])
                $SessionIndex++
            }

            If ($AddSessions.Count -gt 0 -and $OfflineAction -eq 'Skip') {
                $AddingSessions=@($AddSessions.GetEnumerator())
                $ControlSessions = @{ };
                Get-ControlSessions -SessionID $AddingSessions | ForEach-Object { $ControlSessions.Add($_.SessionID, $($_ | Select-Object -Property OnlineStatusControl, LastConnected, CommandSubmitDate)) }
                ForEach ($AddGUID in $AddingSessions) {
                    #Check Online Status. Weed out sessions that have never connected or are not valid.
                    If (!($ControlSessions[$AddGUID].OnlineStatusControl -eq $True)) {
                        $ResultObjects[$AddGUID] = New-ReturnObject -InputObject $ResultObjects[$AddGUID] -Result 'Skipped. Session was not connected.' -PropertyName $ResultPropertyName -IsSuccess $false
                        $Null = $AddSessions.Remove($AddGUID)
                    }
                }
            }

            If ($AddSessions.Count -gt 0) {
                $Body = ConvertTo-Json @($User, $AddSessions, $SessionEventType, $CommandBody) -Compress

                $RESTRequest = @{
                    'URI'         = "$Server/App_Extensions/fc234f0e-2e8e-4a1f-b977-ba41b14031f7/ReplicaService.ashx/PageAddEventToSessions"
                    'Method'      = 'POST'
                    'ContentType' = 'application/json'
                    'Body'        = $Body
                    'UseBasicParsing' = $Null
                }
                If ($Script:ControlAPIKey) {
                    $RESTRequest.Add('Headers', @{'CWAIKToken' = (Get-CWAIKToken) })
                }
                Else {
                    $RESTRequest.Add('Credential', $Script:ControlAPICredentials)
                }

                # Issue command
                Try {
                    $Results = Invoke-WebRequest @RESTRequest -InformationAction 'SilentlyContinue'
                }
                Catch {
                    Write-Error "$(($_.ErrorDetails | ConvertFrom-Json).message)"
                    return
                }

                $RequestTimer = [diagnostics.stopwatch]::StartNew()
                $EventDate = Get-Date $($Results.Headers.Date)
                If (!($EventDateFormatted)) {
                    $EventDateFormatted = (Get-Date $EventDate.ToUniversalTime() -UFormat "%Y-%m-%d %T")
                }
                $TimeOutDateTime = $EventDate.AddMilliseconds($TimeOut+3000)
                Foreach ($SessionsGUID IN $AddSessions) {
                    If ($PSCmdlet.ParameterSetName -ne 'CommandID') {
                        $ResultObjects[$SessionsGUID] = New-ReturnObject -InputObject $ResultObjects[$SessionsGUID] -Result $TimeOutDateTime -PropertyName '__CommandTimeout' -IsSuccess $false
                        $Null = $RemainingSessions.Add($SessionsGUID)
                    } Else {
                        $ResultObjects[$SessionsGUID] = New-ReturnObject -InputObject $ResultObjects[$SessionsGUID] -Result 'Command was queued for the session' -PropertyName $ResultPropertyName -IsSuccess $true
                    }
                }
                $AddSessions.Clear()
            }

            If ($RemainingSessions.Count -gt 0) {

                Start-Sleep -Seconds $(Get-SleepDelay -Seconds $([int]($RequestTimer.Elapsed.TotalSeconds)) -TotalSeconds $([int]($TimeOut / 1000)))
                #Build GUID Conditional
                $GuidCondition = $(ForEach ($SessionsGUID in $RemainingSessions) { "sessionid='$SessionsGUID'" }) -join ' OR '
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
                    $RESTRequest.Add('Headers', @{'CWAIKToken' = (Get-CWAIKToken) })
                }
                Else {
                    $RESTRequest.Add('Credential', $Script:ControlAPICredentials)
                }

                Try {
                    $Results = Invoke-WebRequest @RESTRequest -InformationAction 'SilentlyContinue'
                }
                Catch {
                    Write-Error "$(($_.ErrorDetails | ConvertFrom-Json).message)"
                    return
                }
                $EventDate = Get-Date $($Results.Headers.Date)
                $EventDateFormatted = (Get-Date $EventDate.ToUniversalTime() -UFormat "%Y-%m-%d %T")
                $SessionEvents = $Results.Content | ConvertFrom-JSON
                $FNames = $SessionEvents.FieldNames
                $Events = ($SessionEvents.Items | ForEach-Object { $x = $_; $SCEventRecord = [pscustomobject]@{ }; for ($i = 0; $i -lt $FNames.Length; $i++) { $Null = $SCEventRecord | Add-Member -NotePropertyName $FNames[$i] -NotePropertyValue $x[$i] }; $SCEventRecord } | Sort-Object -Property Time, SessionID -Descending)
                Foreach ($Event in $Events) {
                    [string]$EventGUID = "$($Event.SessionID)"
                    If ($RemainingSessions.Contains($EventGUID)) {
                        $Output = $Event.Data.Trim()
                        If ($Output -match "$cmdMarker") {
                            $Output = $Output -replace "^.*?$cmdMarker\s+(?<=[\n])", ''
                            $ResultObjects[$EventGUID] = New-ReturnObject -InputObject $ResultObjects[$EventGUID] -Result $Output -PropertyName $ResultPropertyName -IsSuccess $true
                            $Null = $RemainingSessions.Remove($EventGUID)
                        }
                    }
                }

                $WaitingSessions=@($RemainingSessions.GetEnumerator())
                Foreach ($WaitingGUID IN $WaitingSessions) {
                    If ($EventDate -gt $ResultObjects[$WaitingGUID].__CommandTimeout) { 
                        Write-Debug "Expiring Session $($WaitingGUID)"
                        If ($OfflineAction -eq 'Queue') {
                            $ResultObjects[$WaitingGUID] = New-ReturnObject -InputObject $ResultObjects[$WaitingGUID] -Result 'Command was queued for the session' -PropertyName $ResultPropertyName -IsSuccess $false
                        } Else {
                            $ResultObjects[$WaitingGUID] = New-ReturnObject -InputObject $ResultObjects[$WaitingGUID] -Result 'Command timed out for the session' -PropertyName $ResultPropertyName -IsSuccess $false
                        }
                        $Null = $RemainingSessions.Remove($WaitingGUID)
                    }
                }
            }
        } Until ($SessionIndex -eq $ProcessSessions.Count -and $RemainingSessions.Count -eq 0)

        If ($SessionCollection.Count -eq 1 -and !($PassthroughObjects)) {
            $ResultObjects.Values | Select-Object -ExpandProperty "$ResultPropertyName" -ErrorAction SilentlyContinue
        } ElseIf (!($PassthroughObjects)) {
            $SessionCollection | Select-Object -Property @{n=$ResultPropertyName;e={If ($_.SessionID) {[string]$SessionID=$_.SessionID} Else {[string]$SessionID=$_}; Write-Debug "Inserting results for sessionID $($SessionID)"; If ($ResultObjects.ContainsKey($SessionID)) {$ResultObjects[$SessionID]|Select-Object -Property * -ExcludeProperty __CommandTimeout} Else {"Results for SessionID $($SessionID) were not found"} }} | Select-Object -ExpandProperty "$ResultPropertyName"
        } Else {
            $SessionCollection | Select-Object -ExcludeProperty $ResultPropertyName -Property *,@{n=$ResultPropertyName;e={If ($_.SessionID) {[string]$SessionID=$_.SessionID} Else {[string]$SessionID=$_}; Write-Debug "Inserting results for sessionID $($SessionID)"; If ($ResultObjects.ContainsKey($SessionID)) {$ResultObjects[$SessionID]|Select-Object -Property * -ExcludeProperty __CommandTimeout} Else {"Results for SessionID $($SessionID) were not found"} }}
        }
    }
}