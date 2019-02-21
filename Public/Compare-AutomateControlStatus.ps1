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
    Version:        1.1
    Author:         Gavin Stone
    Creation Date:  20/01/2019
    Purpose/Change: Initial script development
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

            If([string]::IsNullOrEmpty($Computer.Client.Name))
            {
                $FiClientName = $Computer.ClientName
            }
            else {
                $FiClientName = $Computer.Client.Name
            }

            $FinalComputerObject = ""
            $FinalComputerObject = [pscustomobject] @{
                ComputerID = $Computer.ID
                ComputerName = $Computer.ComputerName
                ClientName = $FiClientName
                OperatingSystemName = $Computer.OperatingSystemName
                OnlineStatusAutomate = $Computer.Status
                OnlineStatusControl = ''
                SessionID = $AutomateControlGUID
            }

            $ComputerArray += $FinalComputerObject
        }

        #GUIDs to get Control information for
        #$GUIDsToLookupInControl = $ComputerArray | Select-Object -ExpandProperty SessionID

        #Control Sessions
        $ControlSessions = Get-ControlSessions

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

            $CAReturn = ""
            $CAReturn = [pscustomobject] @{
                ComputerID = $final.ComputerID
                ComputerName = $final.ComputerName
                ClientName = $final.ClientName
                OperatingSystemName = $final.OperatingSystemName
                OnlineStatusAutomate = $final.OnlineStatusAutomate
                OnlineStatusControl = $ResultControlSessionStatus
                SessionID = $final.SessionID
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