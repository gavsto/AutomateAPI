function Compare-AutomateControlStatus {
    <#
    .SYNOPSIS
    Compares Automate Online Status with Control, and outputs all machines online in Control and not in Automate
    .DESCRIPTION
    Compares Automate Online Status with Control, and outputs all machines online in Control and not in Automate
    .PARAMETER ComputerObject
    Can be taken from the pipeline in the form of Get-AutomateComputer -ComputerID 5 | Compare-AutomateControlStatus
    .PARAMETER AllResults
    Instead of outputting a comparison it outputs everything, which include two columns indicating online status
    .PARAMETER Quiet
    Doesn't output any log messages
    .OUTPUTS
    An object containing Online status for Control and Automate
    .NOTES
    Version:        1.4
    Author:         Gavin Stone
    Creation Date:  2019-01-20
    Purpose/Change: Initial script development

    Update Date:    2019-02-23
    Author:         Darren White
    Purpose/Change: Added SessionID parameter to Get-ControlSessions call.

    Update Date:    2019-02-26
    Author:         Darren White
    Purpose/Change: Reuse incoming object to preserve properties passed on the pipeline.

    Update Date:    2019-06-24
    Author:         Darren White
    Purpose/Change: Update to use objects returned by Get-ControlSessions

    .EXAMPLE
    Get-AutomateComputer -ComputerID 5 | Compare-AutomateControlStatus
    .EXAMPLE
    Get-AutomateComputer -Online $False | Compare-AutomateControlStatus
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $ComputerObject,
        
        [Parameter()]
        [switch]$AllResults,

        [Parameter()]
        [switch]$Quiet
    )
    
    Begin {
        $ComputerArray = @()
        $ObjectRebuild = @()
        $ReturnedObject = @()
    }
    
    Process {
        If ($ComputerObject) {
            $ObjectRebuild += $ComputerObject 
        }
    }
    
    End {
        # The primary concern now is to get out the ComputerIDs of the machines of the objects
        # We want to support all ComputerIDs being called if no computer object is passed in
        If (!$Quiet){Write-Host -BackgroundColor Blue -ForegroundColor White "Checking to see if the recommended Internal Monitor is present"}
        $AutoControlSessions=@{};
        $Null=Get-AutomateAPIGeneric -Endpoint "InternalMonitorResults" -allresults -condition "(Name like '%GetControlSessionIDs%')" -EA 0 | Where-Object {($_.computerid -and $_.computerid -gt 0 -and $_.IdentityField -and $_.IdentityField -match '.+')} | ForEach-Object {$AutoControlSessions.Add($_.computerid,$_.IdentityField)};

        # Check to see if any Computers were specified in the incoming object
        If (!($ObjectRebuild.Count -gt 0)) {$FullLookupMethod = $true}

        If ($FullLookupMethod) {
            $ObjectRebuild = Get-AutomateComputer | Select-Object ComputerId, ComputerName, @{Name = 'ClientName'; Expression = {$_.Client.Name}}, OperatingSystemName, Status 
        }

        Foreach ($Computer in $ObjectRebuild) {
            If (!$AutoControlSessions[[int]$Computer.ComputerID])
            {
                $AutoControlSessionID = Get-AutomateControlInfo -ComputerID $($Computer | Select-Object -ExpandProperty Computerid) | Select-Object -ExpandProperty SessionID
            } Else {
                $AutoControlSessionID = $AutoControlSessions[[int]$Computer.ComputerID]
            }

            $FinalComputerObject = $Computer
            $Null = $FinalComputerObject | Add-Member -MemberType NoteProperty -Name OnlineStatusAutomate -Value $Computer.Status -Force -EA 0
            $Null = $FinalComputerObject | Add-Member -MemberType NoteProperty -Name SessionID -Value $AutoControlSessionID -Force -EA 0
            If([string]::IsNullOrEmpty($Computer.ClientName)) {
                $Null = $FinalComputerObject | Add-Member -MemberType NoteProperty -Name ClientName -Value $Computer.Client.Name -Force -EA 0
            }
            $Null = $FinalComputerObject.PSObject.properties.remove('Status')

            $ComputerArray += $FinalComputerObject
        }

        #SessionIDs to check in Control
        $SessionIDsToCheck = $ComputerArray | Where-Object {$_.SessionID -match '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}'} | Select-Object -ExpandProperty SessionID
        If ($SessionIDsToCheck.Count -gt 100) {$SessionIDsToCheck=$Null} #For larger groups, just retrieve all sessions.

        #Control Sessions
        $ControlSessions=@{};
        Get-ControlSessions -SessionID $SessionIDsToCheck | ForEach-Object {$ControlSessions.Add($_.SessionID, $($_|Select-Object -Property OnlineStatusControl,LastConnected))}

        Foreach ($Final in $ComputerArray) {
            $CAReturn = $Final
            If (![string]::IsNullOrEmpty($Final.SessionID)) {
                If ($ControlSessions.Containskey($Final.SessionID)) {
                    $Null = $CAReturn | Add-Member -MemberType NoteProperty -Name OnlineStatusControl -Value $($ControlSessions[$Final.SessionID].OnlineStatusControl) -Force -EA 0
                    $Null = $CAReturn | Add-Member -MemberType NoteProperty -Name LastConnectedControl -Value $($ControlSessions[$Final.SessionID].LastConnected) -Force -EA 0
                } Else {
                    $Null = $CAReturn | Add-Member -MemberType NoteProperty -Name OnlineStatusControl -Value "SessionID not in Control" -Force -EA 0
                } 
            } Else {
                $Null = $CAReturn | Add-Member -MemberType NoteProperty -Name OnlineStatusControl -Value "Control not installed or SessionID not in Automate" -Force -EA 0
            }

            $ReturnedObject += $CAReturn
        }
        
        If ($AllResults) {
            $ReturnedObject
        } Else {
            $ReturnedObject | Where-Object{($_.OnlineStatusControl -eq $true) -and ($_.OnlineStatusAutomate -eq 'Offline') }
        }
    }
}