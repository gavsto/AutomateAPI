function Invoke-ControlCommand2 {
    <#
    .SYNOPSIS
        Will issue a command against a given machine and return the results.
    .DESCRIPTION
        Will issue a command against a given machine and return the results.
    .PARAMETER GUID
        The GUID identifier for the machine you wish to connect to.
        You can retrieve session info with the 'Get-CWCSessions' commandlet
    .PARAMETER Command
        The command you wish to issue to the machine.
    .PARAMETER TimeOut
        The amount of time in milliseconds that a command can execute. The default is 10000 milliseconds.
    .PARAMETER PowerShell
        Issues the command in a powershell session.
    .PARAMETER Group
        Name of session group to use.
    .OUTPUTS
        The output of the Command provided.
    .NOTES
        Version:        1.0
        Author:         Chris Taylor
        Modified By:    Gavin Stone 
        Creation Date:  1/20/2016
        Purpose/Change: Initial script development
    .EXAMPLE
        Invoke-ControlCommand -GUID $GUID -Command 'hostname'
            Will return the hostname of the machine.
    .EXAMPLE
        Invoke-ControlCommand -GUID $GUID -User $User -Password $Password -TimeOut 120000 -Command 'iwr -UseBasicParsing "https://bit.ly/ltposh" | iex; Restart-LTService' -PowerShell
            Will restart the Automate agent on the target machine.
    #>
    [CmdletBinding()]
    param (
        [string]$Server = $Script:ControlServer,
        [System.Management.Automation.PSCredential]$Credentials = $Script:ControlAPICredentials,
        [Parameter(Mandatory=$True)]
        [guid]$GUID,
        [string]$Command,
        [int]$TimeOut = 10000,
        [switch]$PowerShell,
        [int]$MaxLength = 5000
    )

    $Server = $Server -replace '/$',''
    If (!($Server -match 'https?://[a-z0-9][a-z0-9\.\-]*(:[1-9][0-9]*)?$')) {throw "Control Server address is in invalid format."; return}
    $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0

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
    $Body = ConvertTo-Json @("",@($GUID),$SessionEventType,$FormattedCommand) -Compress
    Write-Verbose $Body

    $RESTRequest = @{
        'URI' = "$Server/App_Extensions/fc234f0e-2e8e-4a1f-b977-ba41b14031f7//ReplicaService.ashx/PageAddEventToSessions"
        'Method' = 'POST'
        'ContentType' = 'application/json'
        'Body' = $Body
    }
    If ($Script:ControlAPIKey) {
        $RESTRequest.Add('Headers',@{'CWAIKToken' = (Get-CWAIKToken)})
    } Else {
        $RESTRequest.Add('Credential',${Script:ControlAPICredentials})
    }
    
    # Issue command
    try {
        $null = Invoke-RestMethod @RESTRequest
    }
    catch {
        Write-Error "$(($_.ErrorDetails | ConvertFrom-Json).message)"
        return
    }

    #Get the timestamp for the Queued command.
    $Body=ConvertTo-Json @("SessionEvent",@("SessionID"),@("LastTime"),"sessionid='$GUID' AND EventType='QueuedCommand'","",10) -Compress
    $RESTRequest = @{
        'URI' = "$Server/App_Extensions/fc234f0e-2e8e-4a1f-b977-ba41b14031f7/ReportService.ashx/GenerateReportForAutomate"
        'Method' = 'POST'
        'ContentType' = 'application/json'
        'Body' = $Body
    }
    If ($Script:ControlAPIKey) {
        $RESTRequest.Add('Headers',@{'CWAIKToken' = (Get-CWAIKToken)})
    } Else {
        $RESTRequest.Add('Credential',${Script:ControlAPICredentials})
    }

    # Get Session
    Write-Verbose $Body
    try {
        $SessionDetails = Invoke-RestMethod @RESTRequest

        $FNames=$SessionDetails.FieldNames
        $SCRecords=($SessionDetails.Items | ForEach-Object {
            $x=$_
            $SCEventRecord = [pscustomobject]@{}
            for($i=0; $i -lt $FNames.Length; $i++){
                $Null = $SCEventRecord | Add-Member -NotePropertyName $FNames[$i] -NotePropertyValue $x[$i]
            }
            $SCEventRecord
        })
        $EventDate=(Get-Date ($SCRecords | Select-Object -Expand LastTime) -UFormat "%Y-%m-%d %T")
    }
    catch {
        Write-Error $($_.Exception.Message)
        return
    }

    # Look for results of command
    $Body=ConvertTo-Json @("SessionConnectionEvent",@(),@("SessionID","Time","Data"),"SessionID='$GUID' AND EventType='RanCommand' AND Time>='$EventDate'","",100) -Compress
    $RESTRequest = @{
        'URI' = "$Server/App_Extensions/fc234f0e-2e8e-4a1f-b977-ba41b14031f7/ReportService.ashx/GenerateReportForAutomate"
        'Method' = 'POST'
        'ContentType' = 'application/json'
        'Body' = $Body
    }

    If ($Script:ControlAPIKey) {
        $RESTRequest.Add('Headers',@{'CWAIKToken' = (Get-CWAIKToken)})
    } Else {
        $RESTRequest.Add('Credential',${Script:ControlAPICredentials})
    }

    $Looking = $True
    $TimeOutDateTime = (Get-Date).AddMilliseconds($TimeOut)
    while ($Looking) {
        Start-Sleep -Seconds 1
        try {
            $SessionEvents = Invoke-RestMethod @RESTRequest
        }
        catch {
            Write-Error $($_.Exception.Message)
            return
        }

        $FNames=$SessionEvents.FieldNames
        $Events = ($SessionEvents.Items | ForEach-Object {$x=$_; $SCEventRecord = [pscustomobject]@{}; for($i=0; $i -lt $FNames.Length; $i++){$Null = $SCEventRecord | Add-Member -NotePropertyName $FNames[$i] -NotePropertyValue $x[$i]}; $SCEventRecord})
        foreach ($Event in $Events) {
            if ($Event.Time -ge $EventDate) {
                $Looking = $False
                $Output = $Event.Data -split '[\r\n]' | Where-Object {$_}
                if(!$PowerShell){
                    $Output = $Output | Select-Object -skip 1
                }
                return $Output 
            }
        }

        if ($Looking -and $(Get-Date) -gt $TimeOutDateTime.AddSeconds(1)) {
            $Looking = $False
            $Output = "Command timed out when sent to Agent"
        }
    }
}