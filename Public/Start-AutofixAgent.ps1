function Start-AutofixAgent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [bool]$PromptBeforeAction = $true,

        [Parameter(Mandatory = $false)]
        [bool]$AutofixRestartService = $false,

        [Parameter(Mandatory = $false)]
        [bool]$AutofixReinstallService = $false,

        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName=$true)]
        $AutomateControlStatusObject

    )
  
    begin {
        $ResultArray = @()
        $RestartServiceRecheckArray  = @()       
    }
  
    process {
        foreach ($igu in $AutomateControlStatusObject) {
            if ($AutofixRestartService) {
                if ($PromptBeforeAction) {
                    Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($igu.ComputerID) - $($igu.ComputerName) - Shall we attempt to restart the Automate services? Press y for Yes or n for No"
                    $Confirmation = Read-Host "$($igu.ComputerID) - Enter y or n to process a service restart"
                    if (($Confirmation -eq 'y') -or ($PromptBeforeAction -eq $false)) {
                        Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($igu.ComputerID) - $($igu.ComputerName) -  Attempting to restart Automate Services - job will be queued"
                        $IGU | Start-RSJob -Throttle $BatchSize -Name -ScriptBlock {
                            Import-Module "C:\GitHubProjects\AutomateAPI\AutomateAPI.psm1" -Force
                            $Global:ControlCredentials = $using:ControlCredentials
                            $Global:ControlServer = $using:ControlServer
                            $ServiceRestartAttempt = Invoke-ControlCommand -GUID $($_.Guid) -Powershell -Command "(new-object Net.WebClient).DownloadString('http://bit.ly/LTPoSh') | iex; Restart-LTService" -TimeOut 60000
                            return $ServiceRestartAttempt
                        } | out-null

                    }
                }
            }
        }




    }

    
  
    end {
        
    }
}