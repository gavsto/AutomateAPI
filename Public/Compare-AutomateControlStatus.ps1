function Compare-AutomateControlStatus {
    <#
    .SYNOPSIS
    Compares Automate Online Status with Control, and outputs all machines online in Control and not in Automate
    .DESCRIPTION
    Compares Automate Online Status with Control, and outputs all machines online in Control and not in Automate
    .PARAMETER ComputerObject
    Can be taken from the pipeline in the form of Get-AutomateComputer -ComputerID 5 | Compare-AutomateControlStatus
    .PARAMETER AllResults
    Instead of outputting only status differences it outputs everything, which include two columns indicating online status
    .PARAMETER Quiet
    Doesn't output any messages
    .OUTPUTS
    An object containing Online status for Control and Automate
    .NOTES
    Version:        1.5.0
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

    Update Date:    2020-08-13
    Author:         Darren White
    Purpose/Change: -Force to include all Control Sessions, even if not found in Automate.

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
        [switch]$Force,

        [Parameter()]
        [switch]$Quiet
    )
    
    Begin {
        $ComputerArray = @()
        $ObjectRebuild = @()
        $ReturnedObject = @()
        $FullLookupMethod = $False
    }
    
    Process {
        If ($ComputerObject) {
            Foreach ($Computer in $ComputerObject) {
                If ($Computer -and $Computer.ComputerID -match '^[1-9]\d*$') {
                    $ObjectRebuild += $Computer
                } Else {
                    Write-Warning "Input Object ComputerID property is missing or invalid. Skipping."
                }
            }
        }
    }
    
    End {
        # Check to see if any Computers were specified in the incoming object
        # We want to support all ComputerIDs being returned if no computer object is passed in
        If (!($ObjectRebuild.Count -gt 0)) {$FullLookupMethod = $true}

        If ($FullLookupMethod) {
            $ObjectRebuild = Get-AutomateComputer | Select-Object ComputerId, ComputerName, Client, Location, OperatingSystemName, RemoteAgentLastContact, Status 
        } ElseIf ($Force) {
            Write-Warning "Input Objects were provided. False positives of Control Sessions not known by Automate may occur for computers not provided."
        }

        # The primary concern now is to get the SessionIDs for the Automate Computers. Skip use of Internal Monitor when a small number of computers are being checked.
        $AutoControlSessions=@{};
        If (!($ObjectRebuild.Count -le 15)) {
            If (!$Quiet){Write-Host -BackgroundColor Blue -ForegroundColor White "Checking to see if the recommended Internal Monitor is present"}
            $Null=Get-AutomateAPIGeneric -Endpoint "InternalMonitorResults" -allresults -condition "(Name like '%GetControlSessionIDs%')" -EA 0 | Where-Object {($_.computerid -and $_.computerid -gt 0 -and $_.IdentityField -and $_.IdentityField -match '.+')} | ForEach-Object {$AutoControlSessions.Add([int]$_.computerid,$_.IdentityField)};
            If ($AutoControlSessions.Count -gt 0 -and !$Quiet) {Write-Host -BackgroundColor Blue -ForegroundColor White "Internal Monitor is present"}
        }

        Foreach ($Computer in $ObjectRebuild) {
            If (!$AutoControlSessions[[int]$Computer.ComputerID]) {
                $AutoControlSessionID = Get-AutomateControlInfo -ComputerID $($Computer | Select-Object -ExpandProperty ComputerId) | Select-Object -ExpandProperty SessionID
                $AutoControlSessions.Add([int]$Computer.ComputerID,$AutoControlSessionID)
            } Else {
                $AutoControlSessionID = $AutoControlSessions[[int]$Computer.ComputerID]
            }

            $FinalComputerObject = $Computer
            If ($Computer|Get-Member -Name Status) {
                $Null = $FinalComputerObject | Add-Member -MemberType NoteProperty -Name OnlineStatusAutomate -Value $Computer.Status -Force -EA 0
            } Else {
                Write-Debug "Refreshing Automate Status for Computer ID $($FinalComputerObject.ComputerID)"
                $Null = $FinalComputerObject | Add-Member -MemberType NoteProperty -Name OnlineStatusAutomate -Value $(Get-AutomateComputer -ComputerID $FinalComputerObject.ComputerID -IncludeFields Status).Status -Force -EA 0
            } 
            $Null = $FinalComputerObject | Add-Member -MemberType NoteProperty -Name SessionID -Value $AutoControlSessionID -Force -EA 0
            If([string]::IsNullOrEmpty($Computer.ClientName) -and $Computer.Client -and $Computer.Client.Name -match '.+') {
                $Null = $FinalComputerObject | Add-Member -MemberType NoteProperty -Name ClientName -Value $Computer.Client.Name -Force -EA 0
            }
            $Null = $FinalComputerObject.PSObject.properties.remove('Status')

            $ComputerArray += $FinalComputerObject
        }

        #SessionIDs to check in Control
        $SessionIDsToCheck = $ComputerArray | Where-Object {$_.SessionID -match '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}'} | Select-Object -ExpandProperty SessionID
        If ($Force -or $SessionIDsToCheck.Count -gt 100) {$SessionIDsToCheck=$Null} #For larger groups, just retrieve all sessions.

        #Control Sessions
        $ControlSessions=@{};
        Get-ControlSessions -SessionID $SessionIDsToCheck -IncludeProperty Name,CreatedTime,GuestOperatingSystemManufacturerName,GuestOperatingSystemName,CustomProperty1,CustomProperty2,SessionType | ForEach-Object {$ControlSessions.Add([string]$_.SessionID, $($_))}

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
        
        If ($Force) {
            ForEach ($ControlSessionID In $AutoControlSessions.Values) {
                $Null = $ControlSessions.Remove($ControlSessionID.ToString())
            }
            # Get list of sessions we learned about from Control, skip any we already knew about.
            $ControlSessions.GetEnumerator() | Foreach-Object {
                $CAReturn=$_.Value | Select-Object -Property @{n='ComputerId';e={0}},@{n='ComputerName';e={[string]$_.Name}},@{n='ClientName';e={$_.CustomProperty1}},@{n='Location';e={$_.CustomProperty2}},@{n='OperatingSystemName';e={(@($_.GuestOperatingSystemManufacturerName,$_.GuestOperatingSystemName).GetEnumerator()|Where-Object {$_}) -join ' '}},@{n='OnlineStatusAutomate';e={'Offline'}},SessionType,SessionID,OnlineStatusControl,CreatedTime,@{n='LastConnectedControl';e={$_.LastConnected}}
                If (!$CAReturn.ComputerName) {$CAReturn.ComputerName=''}
                $ReturnedObject += $CAReturn
            }
        }

        If ($AllResults) {
            $ReturnedObject
        } Else {
            $ReturnedObject | Where-Object{($_.OnlineStatusControl -eq $true) -and ($_.OnlineStatusAutomate -eq 'Offline') }
        }
    }
}