function Get-ControlLastContact {
    <#
    .SYNOPSIS
      Returns the date the machine last connected to the control server.
    .DESCRIPTION
      Returns the date the machine last connected to the control server.
    .PARAMETER GUID
      The GUID/SessionID for the machine you wish to connect to.
      On Windows clients, the launch parameters are located in the registry at:
        HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\ScreenConnect Client (xxxxxxxxxxxxxxxx)\ImagePath
      On Linux and Mac clients, it's found in the ClientLaunchParameters.txt file in the client installation folder:
        /opt/screenconnect-xxxxxxxxxxxxxxxx/ClientLaunchParameters.txt
    .PARAMETER Quiet
      Will output a boolean result, $True for Connected or $False for Offline.
    .PARAMETER Seconds
      Used with the Quiet switch. The number of seconds a machine needs to be offline before returning $False.
  
    .PARAMETER Group
      Name of session group to use.
    .OUTPUTS
        [datetime] -or [boolean]
    .NOTES
        Version:        1.1
        Author:         Chris Taylor
        Modified By:    Gavin Stone
        Creation Date:  1/20/2016
        Purpose/Change: Initial script development
        Update Date:  8/24/2018
        Purpose/Change: Fix Timespan Seconds duration
  #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [guid]$GUID,
        [switch]$Quiet,
        [int]$Seconds,
        [string]$Group = "All Machines"
    )

    # Time conversion
    $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    $epoch = $((New-TimeSpan -Start $(Get-Date -Date "01/01/1970") -End $(Get-Date)).TotalSeconds)

    $Body = ConvertTo-Json @($Group, $GUID)
    Write-Verbose $Body

    $URl = "$($ControlServer)/Services/PageService.ashx/GetSessionDetails"
    try {
        #Get Credentials out of global var
        $SessionDetails = Invoke-RestMethod -Uri $url -Method Post -Credential $ControlCredentials -ContentType "application/json" -Body $Body
    }
    catch {
        Write-Error "$($_.Exception.Message)"
        return
    }

    if ($SessionDetails -eq 'null' -or !$SessionDetails) {
        Write-Output "Machine not found."
        return
    }

    # Filter to only guest session events
    $GuestSessionEvents = ($SessionDetails.Connections | Where-Object {$_.ProcessType -eq 2}).Events

    if ($GuestSessionEvents) {

        # Get connection events
        $LatestEvent = ($GuestSessionEvents | Where-Object {$_.EventType -in (10, 11)} | Sort-Object time)[0]
        if ($LatestEvent.EventType -eq 10) {
            # Currently connected
            if ($Quiet) {
                return $True
            }
            else {
                return Get-Date
            }

        }
        else {
            # Time conversion hell :(
            $TimeDiff = $epoch - ($LatestEvent.Time / 1000)
            $OfflineTime = $origin.AddSeconds($TimeDiff)
            $Difference = New-TimeSpan -Start $OfflineTime -End $(Get-Date)
            if ($Quiet -and $Difference.TotalSeconds -lt $Seconds) {
                return $True
            }
            elseif ($Quiet) {
                return $False
            }
            else {
                return $OfflineTime
            }
        }
    }
    else {
        Write-Output "Unable to determine last contact."
        return
    }
}