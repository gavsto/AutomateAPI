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
    .PARAMETER AsObjects
        Receive the output from your script as native psobjects    
    .PARAMETER ArgumentList
        Object[] input parameters for your script (if your script has a param block)
    .PARAMETER ResultAsMember
        String containing the name of the member you would like to add to the input pipeline object that will hold the result of this command
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

        Update Date:    2019-08-14
        Author:         Darren Kattan
        Purpose/Change: Added -AsObject and -ArgumentList parameters for object passing

        Update Date:    2019-08-20
        Author:         Darren Kattan
        Purpose/Change: Added ability to retain Computer object passed in from pipeline and append result of script to a named member of the computer object
        
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

    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True, ParameterSetName='SessionID')]
        [guid[]]$SessionID,
        [string]$Command,
        [int]$TimeOut = 10000,
        [int]$MaxLength = 5000,
        [switch]$PowerShell,
        [ValidateSet('Wait', 'Queue', 'Skip')] 
        $OfflineAction = 'Wait',
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20,
        [switch]$AsObjects = $false,
        [Object[]]$ArgumentList,
        [Parameter(ValueFromPipeLine=$true, ParameterSetName='Computer')]
        $Computer,        
        [string]$ResultPropertyName = 'Output',
        [switch]$IncludeComputerName
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
        if($AsObjects)
        {
            $EncodedScript = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Command))
        
            $CompressionBlock = {
                Function Compress
                {
                    param($bytearray)
                    [System.IO.MemoryStream] $output = New-Object System.IO.MemoryStream
                    $gzipStream = New-Object System.IO.Compression.GzipStream $output, ([IO.Compression.CompressionMode]::Compress)
      	            $gzipStream.Write( $byteArray, 0, $byteArray.Length )
                    $gzipStream.Close()
                    $output.Close()
                    $tmp = $output.ToArray()
                    [System.Convert]::ToBase64String($tmp)
                }
            }
            if($ArgumentList){
                $XMLArgs = [xml]([System.Management.Automation.PSSerializer]::Serialize($ArgumentList))
                $XMLArgs.PreserveWhitespace = $false                
                $EncodedArguments = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Xmlargs.OuterXml))
                $FormattedCommand += @"
`$ArgumentList = [System.Management.Automation.PSSerializer]::DeserializeAsList([System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String("$EncodedArguments")))
"@
            }
        
        $FormattedCommand += $CompressionBlock.ToString().Replace("`t","") + "`r`n"        
        $FormattedCommand += @"            
`$ScriptBlock = [ScriptBlock]::Create([System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String("$EncodedScript")))
"@
 $FormattedCommand += @'
try
{
    $PSInstance = [System.Management.Automation.PowerShell]::Create()
    $OutputCollector = New-Object 'System.Management.Automation.PSDataCollection[psobject]'
    $PSOutputArray = new-object psobject -property @{"OutputObjects"=@();"ConsoleString"="";AllObjects=@()}  
    $NewDataHandler = {
        try {
            $data = $sender.ReadAll() | ?{ $null -ne $_ }
            $event.MessageData.AllObjects += $data
            $event.MessageData.OutputObjects += $data | ?{ $_.GetType().Name -notin @("InformationRecord","ErrorRecord","VerboseRecord","DebugRecord","WarningRecord")}            
            $event.MessageData.ConsoleString += $data | Out-String
        }
        catch{
            $_
        }
    }
    
    $null = $PSInstance.AddScript($ScriptBlock)
    Register-ObjectEvent -InputObject $OutputCollector -EventName DataAdded -MessageData $PSOutputArray -Action $NewDataHandler | Out-Null
    Register-ObjectEvent -InputObject $PSInstance.Streams.Error -EventName DataAdded -MessageData $PSOutputArray -Action $NewDataHandler | Out-Null
    Register-ObjectEvent -InputObject $PSInstance.Streams.Information -EventName DataAdded -MessageData $PSOutputArray -Action $NewDataHandler | Out-Null
    Register-ObjectEvent -InputObject $PSInstance.Streams.Debug -EventName DataAdded -MessageData $PSOutputArray -Action $NewDataHandler | Out-Null
    Register-ObjectEvent -InputObject $PSInstance.Streams.Warning -EventName DataAdded -MessageData $PSOutputArray -Action $NewDataHandler | Out-Null
    Register-ObjectEvent -InputObject $PSInstance.Streams.Verbose -EventName DataAdded -MessageData $PSOutputArray -Action $NewDataHandler | Out-Null
    $InputCollector = New-Object 'System.Management.Automation.PSDataCollection[psobject]'
    foreach($Argument in $ArgumentList)
    {
        $InputCollector.Add($Argument)
    }
    $Output = $PSInstance.BeginInvoke($InputCollector, $OutputCollector)
    while($PSInstance.InvocationStateInfo.State -ne "Completed")
    {
        sleep -s 1
    }    
}
catch
{
    $PSOutputArray += $_
}
finally
{
    $PSInstance.EndInvoke($Output);    
    Get-EventSubscriber | Unregister-Event
    $PSInstance.Dispose()
}
# $Output
[xml]$SerializedOutput = [System.Management.Automation.PSSerializer]::Serialize($PSOutputArray)
$SerializedOutput.PreserveWhiteSpace = $false
$UncompressedBinary = [System.Text.Encoding]::ASCII.GetBytes($SerializedOutput.OuterXml)
$CompressedOutput = Compress $UncompressedBinary
$CompressedOutput
'@
            
        }
        else
        {
            $FormattedCommand += $Command
        }

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
        $ComputerCollection = @()
        $ResultSet = @()

    }

    Process {
        If (!($Server -match 'https?://[a-z0-9][a-z0-9\.\-]*(:[1-9][0-9]*)?(\/[a-z0-9\.\-\/]*)?$')) {throw "Control Server address ($Server) is in an invalid format. Use Connect-ControlAPI to assign the server URL."; return}
        
        If ($SessionID) {
            $SessionIDCollection += $SessionID
        }
        If($Computer) {
            $ComputerCollection += $Computer
        }

    }

    End {
        if($PSCmdlet.ParameterSetName -eq 'Computer')
        {
            $SessionIDCollection = $ComputerCollection.SessionID
        }
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
                            $FriendlyResult = 'Skipped. Session was not connected.'
                            if($IncludeComputerName)
                            {
                                $Computer = $ComputerCollection | ?{$_.SessionID -eq $GUID} | select -First 1
                                $Computer | Add-Member -NotePropertyName $ResultPropertyName -NotePropertyValue $FriendlyResult
                                $ReturnObject = $Computer
                            }
                            else
                            {
                                $ReturnObject = [pscustomobject]@{
                                    'SessionID' = $GUID                                
                                    "$ResultPropertyName" = $FriendlyResult
                                    'IsSuccess' = $false
                                }
                            }
                            $ResultSet += $ReturnObject
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

                Try {
                    $SessionEvents = Invoke-RestMethod @RESTRequest
                } Catch {
                    Write-Error $($_.Exception.Message)
                }

                $FNames = $SessionEvents.FieldNames
                $Events = ($SessionEvents.Items | ForEach-Object {$x = $_; $SCEventRecord = [pscustomobject]@{}; for ($i = 0; $i -lt $FNames.Length; $i++) {$Null = $SCEventRecord | Add-Member -NotePropertyName $FNames[$i] -NotePropertyValue $x[$i]}; $SCEventRecord} | Sort-Object -Property Time,SessionID -Descending)
                foreach ($Event in $Events) {
                    if ($Event.Time -ge $EventDate.ToUniversalTime() -and $RemainingGUIDs.Contains($Event.SessionID)) {
                        $GUID = $Event.SessionID
                        $Output = $Event.Data.Trim()
                        if (!$PowerShell) {
                            $Output = $Output -replace '^[\r\n]*',''
                        }
                        elseif($AsObjects)
                        {
                            $OutputByteArray = [System.Convert]::FromBase64String($Output)
                            $inputStream = New-Object System.IO.MemoryStream( , $OutputByteArray )
	                        $outputStream = New-Object System.IO.MemoryStream
                            $gzipStream = New-Object System.IO.Compression.GzipStream $inputStream, ([IO.Compression.CompressionMode]::Decompress)
	                        $gzipStream.CopyTo( $outputStream )
                            $gzipStream.Close()
		                    $inputStream.Close()
                            $Output = [System.Management.Automation.PSSerializer]::Deserialize([System.Text.Encoding]::ASCII.GetString($outputStream.ToArray()));
                            $outputStream.Close()
                        }
                        
                        $ReturnObject = [pscustomobject]@{
                            'SessionID' = $GUID
                            "$ResultPropertyName" = $Output
                            'IsSuccess' = $True
                        }
                        if($IncludeComputerName)
                        {
                            $Computer = $ComputerCollection | ?{$_.SessionID -eq $GUID} | select -First 1
                            $ReturnObject | Add-Member -NotePropertyName Computer -NotePropertyValue $Computer.ComputerName                            
                        }
                        

                        $ResultSet += $ReturnObject
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
                    If ($RemainingGUIDs) {
                        ForEach ($GUID in $RemainingGUIDs) {
                            $FriendlyResult = 'Command was queued for the session.'
                            $ReturnObject = [pscustomobject]@{
                            'SessionID' = $GUID
                            "$ResultPropertyName" = $FriendlyResult
                            'IsSuccess' = $false
                            }
                            if($IncludeComputerName)
                            {
                                $Computer = $ComputerCollection | ?{$_.SessionID -eq $GUID} | select -First 1
                                $ReturnObject | Add-Member -NotePropertyName Computer -NotePropertyValue $Computer.ComputerName                            
                            }
                            $ResultSet += $ReturnObject
                        }
                        return $Output -Join ""
                    }
                }

                if ($Looking -and $(Get-Date) -gt $TimeOutDateTime.AddSeconds(1)) {
                    $Looking = $False
                    ForEach ($GUID in $RemainingGUIDs) {
                        If ($OfflineAction -ne 'Wait' -and $ControlSessions[$GUID.ToString()].OnlineStatusControl -eq $False) {
                            $FriendlyResult = 'Command was queued for the session'
                        } 
                        Else {
                            $FriendlyResult = 'Command timed out when sent to Agent'
                        }
                        
                        $ReturnObject = [pscustomobject]@{
                            'SessionID' = $GUID
                            "$ResultPropertyName" = $FriendlyResult
                            'IsSuccess' = $false
                        }
                        if($IncludeComputerName)
                        {
                            $Computer = $ComputerCollection | ?{$_.SessionID -eq $GUID} | select -First 1
                            $ReturnObject | Add-Member -NotePropertyName Computer -NotePropertyValue $Computer.ComputerName                            
                        }
                        $ResultSet += $ReturnObject
                    }
                }
            }
        }
        If ($ResultSet.Count -eq 1) {
            Return $ResultSet | Select-Object -ExpandProperty "$ResultPropertyName" -ErrorAction 0
        } Else {
            Return $ResultSet
        }
    }
}