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
    Version:        1.3
    Author:         Gavin Stone
    Creation Date:  20/01/2019
    Purpose/Change: Initial script development

    Update Date:    2019-02-23
    Author:         Darren White
    Purpose/Change: Added SessionID parameter to Get-ControlSessions call.

    Update Date:    2019-02-26
    Author:         Darren White
    Purpose/Change: Reuse incoming object to preserve properties passed on the pipeline.
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
        If (!$ObjectRebuild.Count -gt 0){$FullLookupMethod = $true}

        If ($FullLookupMethod) {
            $ObjectRebuild = Get-AutomateComputer -AllComputers | Select-Object Id, ComputerName, @{Name = 'ClientName'; Expression = {$_.Client.Name}}, OperatingSystemName, Status 
        }

        Foreach ($computer in $ObjectRebuild) {
            If (!$AutoControlSessions[[int]$Computer.ID])
            {
                $AutomateControlGUID = Get-AutomateControlInfo -ComputerID $($computer | Select-Object -ExpandProperty id) | Select-Object -ExpandProperty SessionID
            } Else {
                $AutomateControlGUID = $AutoControlSessions[[int]$Computer.ID]
            }

            $FinalComputerObject = $computer
            $Null = $FinalComputerObject | Add-Member -MemberType NoteProperty -Name ComputerID -Value $Computer.ID -Force -EA 0
            $Null = $FinalComputerObject | Add-Member -MemberType NoteProperty -Name OnlineStatusAutomate -Value $Computer.Status -Force -EA 0
            $Null = $FinalComputerObject | Add-Member -MemberType NoteProperty -Name SessionID -Value $AutomateControlGUID -Force -EA 0
            If([string]::IsNullOrEmpty($Computer.ClientName)) {
                $Null = $FinalComputerObject | Add-Member -MemberType NoteProperty -Name ClientName -Value $Computer.Client.Name -Force -EA 0
            }
            $Null = $FinalComputerObject.PSObject.properties.remove('ID')
            $Null = $FinalComputerObject.PSObject.properties.remove('Status')

            $ComputerArray += $FinalComputerObject
        }

        #GUIDs to get Control information for
        $GUIDsToLookupInControl = $ComputerArray | Where-Object {$_.SessionID -match '[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}'} | Select-Object -ExpandProperty SessionID
        If ($GUIDsToLookupInControl.Count -gt 100) {$GUIDsToLookupInControl=$Null} #For larger groups, just retrieve all sessions.

        #Control Sessions
        $ControlSessions = Get-ControlSessions -SessionID $GUIDsToLookupInControl

        Foreach ($final in $ComputerArray) {
            
            If (![string]::IsNullOrEmpty($Final.SessionID)) {
                If ($ControlSessions.Containskey($Final.SessionID)) {
                    $ResultControlSessionStatus = $ControlSessions[$Final.SessionID]
                } Else {
                    $ResultControlSessionStatus = "GUID Not in Control or No Connection Events"
                } 
            } Else {
                $ResultControlSessionStatus = "Control not installed or GUID not in Automate"
            }

            $CAReturn = $final
            $Null = $CAReturn | Add-Member -MemberType NoteProperty -Name OnlineStatusControl -Value $ResultControlSessionStatus -Force -EA 0

            $ReturnedObject += $CAReturn
        }
        
        If ($AllResults) {
            $ReturnedObject
        } Else {
            $ReturnedObject | Where-Object{($_.OnlineStatusControl -eq $true) -and ($_.OnlineStatusAutomate -eq 'Offline') }
        }
    }
}