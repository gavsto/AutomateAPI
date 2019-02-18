function Compare-AutomateControlStatusv2 {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $ComputerObject,
        
        [Parameter()]
        [switch]$AllResults
    )
    
    begin {
        $ComputerArray = @()
        $ObjectRebuild = @()
        $ReturnedObject = @()
    }
    
    process {
        if ($ComputerObject) {
            $ObjectRebuild += $ComputerObject 
        }

    }
    
    end {
        # The primary concern now is to get out the ComputerIDs of the machines of the objects
        # We want to support all ComputerIDs being called if no computer object is passed in
        Write-Host -BackgroundColor Blue -ForegroundColor White "Checking to see if the recommended Internal Monitor is present"
        $AutoControlSessions=@{};
        $InternalMonitorMethod = $false
        $Null=Get-AutomateAPIGeneric -Endpoint "InternalMonitorResults" -allresults -condition "(Name like '%GetControlSessionIDs%')" | foreach-object {$AutoControlSessions.Add($_.computerid,$_.IdentityField)};

        # Check to see if the Internal Monitor method has results
        if ($AutoControlSessions.Count -gt 0){$InternalMonitorMethod = $true} Else {Write-Host -ForegroundColor Black -BackgroundColor Yellow "Internal monitor not found. This cmdlet is significantly faster with it. See https://www.github.com/gavsto/automateapi"}

        # Check to see if any Computers were specified in the incoming object
        if(!$ObjectRebuild.Count -gt 0){$FullLookupMethod = $true}

        if ($FullLookupMethod) {
            $ObjectRebuild = Get-AutomateComputer -AllComputers | Select Id, ComputerName, @{Name = 'ClientName'; Expression = {$_.Client.Name}}, OperatingSystemName, Status 
        }

        foreach ($computer in $ObjectRebuild) {
            If(!$InternalMonitorMethod)
            {
                $AutomateControlGUID = Get-AutomateControlInfo -ComputerID $($computer | Select-Object -ExpandProperty id) | Select-Object -ExpandProperty SessionID
            }
            else {
                $AutomateControlGUID = $AutoControlSessions[[int]$Computer.ID]
            }

            $FinalComputerObject = ""
            $FinalComputerObject = [pscustomobject] @{
                ComputerID = $Computer.ID
                ComputerName = $Computer.ComputerName
                ClientName = $Computer.Client.Name
                OperatingSystemName = $Computer.OperatingSystemName
                OnlineStatusAutomate = $Computer.Status
                OnlineStatusControl = ''
                SessionID = $AutomateControlGUID
            }

            $ComputerArray += $FinalComputerObject
        }

        #GUIDs to get Control information for
        $GUIDsToLookupInControl = $ComputerArray | Select-Object -ExpandProperty SessionID

        #Control Sessions
        $ControlSessions = Get-ControlSessionsv2 -SessionGUIDs $GUIDsToLookupInControl

        foreach ($final in $ComputerArray) {

            $ResultControlSessionStatus = $ControlSessions | Where-Object {$_.SessionID -eq $Final.SessionID} | Select -first 1 | Select -ExpandProperty Connected
            
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
        
        if ($AllResults) {
            $ReturnedObject
        }
        else
        {
            $ReturnedObject | Where-Object{($_.OnlineStatusControl -eq $true) -and ($_.OnlineStatusAutomate -eq 'Offline') }
        }
        

    }
}