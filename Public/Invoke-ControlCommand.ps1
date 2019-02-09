function Invoke-ControlCommand {
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
        Invoke-ControlCommand -Server $ControlServer -GUID $GUID -User $User -Password $Password -TimeOut 120000 -Command 'iwr -UseBasicParsing "https://bit.ly/ltposh" | iex; Restart-LTService' -PowerShell
            Will restart the Automate agent on the target machine.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [guid]$GUID,
        [string]$Command,
        [int]$TimeOut = 10000,
        [switch]$PowerShell,
        [string]$Group = "All Machines",
        [int]$MaxLength = 5000
    )

    $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0

    $URI = "$ControlServer/Services/PageService.ashx/AddEventToSessions"

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
    $Body = ConvertTo-Json @($Group,@($GUID),$SessionEventType,$FormattedCommand)
    Write-Verbose $Body
    
    # Issue command
    try {
        $null = Invoke-RestMethod -Uri $URI -Method Post -Credential $ControlCredentials -ContentType "application/json" -Body $Body
    }
    catch {
        Write-Error "$(($_.ErrorDetails | ConvertFrom-Json).message)"
        return
    }

    # Get Session
    $URI = "$ControlServer/Services/PageService.ashx/GetSessionDetails"
    $Body = ConvertTo-Json @($Group,$GUID)
    Write-Verbose $Body
    try {
        $SessionDetails = Invoke-RestMethod -Uri $URI -Method Post -Credential $ControlCredentials -ContentType "application/json" -Body $Body
    }
    catch {
        Write-Error $($_.Exception.Message)
        return
    }

    #Get time command was executed
    $epoch = $((New-TimeSpan -Start $(Get-Date -Date "01/01/1970") -End $(Get-Date)).TotalSeconds)
    $ExecuteTime = $epoch - ((($SessionDetails.events | Where-Object {$_.EventType -eq 44})[-1]).Time /1000)
    $ExecuteDate = $origin.AddSeconds($ExecuteTime)

    # Look for results of command
    $Looking = $True
    $TimeOutDateTime = (Get-Date).AddMilliseconds($TimeOut)
    $Body = ConvertTo-Json @($Group,$GUID)
    while ($Looking) {
        try {
            $SessionDetails = Invoke-RestMethod -Uri $URI -Method Post -Credential $ControlCredentials -ContentType "application/json" -Body $Body
        }
        catch {
            Write-Error $($_.Exception.Message)
            return
        }

        $ConnectionsWithData = @()
        Foreach ($Connection in $SessionDetails.connections) {
            $ConnectionsWithData += $Connection | Where-Object {$_.Events.EventType -eq 70}
        }

        $Events = ($ConnectionsWithData.events | Where-Object {$_.EventType -eq 70 -and $_.Time})
        foreach ($Event in $Events) {
            $epoch = $((New-TimeSpan -Start $(Get-Date -Date "01/01/1970") -End $(Get-Date)).TotalSeconds)
            $CheckTime = $epoch - ($Event.Time /1000)
            $CheckDate = $origin.AddSeconds($CheckTime)
            if ($CheckDate -gt $ExecuteDate) {
                $Looking = $False
                $Output = $Event.Data -split '[\r\n]' | Where-Object {$_}
                if(!$PowerShell){
                    $Output = $Output | Select-Object -skip 1
                }
                return $Output 
            }
        }

        Start-Sleep -Seconds 1
        if ($(Get-Date) -gt $TimeOutDateTime.AddSeconds(1)) {
            $Looking = $False
            Write-Warning "Command timed out."
        }
    }
}