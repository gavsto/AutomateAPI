function Get-ControlLastContactBulk {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        [Alias('Id')]
        [int[]]$ComputerID,

        [Parameter()]
        [int]$BatchSize = 50
    )
    
    begin {
        $IDs = @()
    }
    
    process {
        $IDs += $ComputerID
    }
    
    end {
        $IDs | Start-RSJob -Throttle $BatchSize -ScriptBlock {
            Import-Module "C:\GitHubProjects\AutomateAPI\AutomateAPI.psm1" -Force
            $Script:CWAUri = $using:CWAuri
            $Script:CWACredentials = $using:CWACredentials
            $Script:ControlCredentials = $using:ControlCredentials
            $Script:ControlServer = $using:ControlServer
            
            $ControlGUID = Get-AutomateControlGUID -ComputerID $($_) | Select-Object -ExpandProperty ControlGUID
            if (-not([string]::IsNullOrEmpty($ControlGuid)) -and ($ControlGuid -ne 'No Guid Found')){
                $LastContact = Get-ControlLastContact -GUID $ControlGUID
                try {
                    $ControlTimeSpan = New-TimeSpan -Start $LastContact -End (Get-Date)
                    $NumberOfMinutesInControl = $ControlTimeSpan | Select-Object -ExpandProperty TotalMinutes
                    $NumberOfDaysInControl = $ControlTimeSpan | Select-Object -ExpandProperty Days
                }
                catch {
                    $NumberOfMinutesInControl = $null
                    $NumberOfDaysInControl = $null
                }
                if (($NumberOfMinutesInControl -gt -5) -and ($NumberOfMinutesInControl -le 5) -and (-not [string]::IsNullOrEmpty($NumberOfMinutesInControl))) {
                    $Online = 1
                }
                else {
                    $Online = 0
                }
                [pscustomobject] @{
                    ComputerID = ($_)
                    LastContact = $LastContact
                    GUID = $ControlGUID
                    Online = $Online                    
                } 
            }
            else {
                [pscustomobject] @{
                    ComputerID = ($_)
                    LastContact = "No GUID Found"
                    GUID = "Unknown"
                    Online = 0
                } 
            }

        } | Wait-RSJob -ShowProgress | Receive-RSJob 
    }
}