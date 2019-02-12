function Start-AutofixAgent {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [bool]$PromptBeforeAction = $true,

        [Parameter(Mandatory = $false)]
        [bool]$AutofixRestartService = $false,

        [Parameter(Mandatory = $false)]
        [bool]$AutofixReinstallService = $false,

        [Parameter(ValueFromPipeline = $true)]
        $AutomateControlStatusObject

    )
  
    begin {
        $ResultArray = @()
        $ObjectCapture = @()
        $null = Get-RSJob | Remove-RSJob | Out-Null       
    }
  
    process {
        $ObjectCapture += $AutomateControlStatusObject
    }

    
  
    end {
        Write-Host -ForegroundColor Green "Starting fixes - you will be prompted if you have turned this on"
        foreach ($igu in $ObjectCapture) {
            if ($AutofixRestartService) {
                if ($PromptBeforeAction) {
                    Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($igu.ComputerID) - $($igu.ComputerName) - Shall we attempt to restart the Automate services? Press y for Yes or n for No"
                    $Confirmation = Read-Host "$($igu.ComputerID) - Enter y or n to process a service restart"
                    if (($Confirmation -eq 'y') -or ($PromptBeforeAction -eq $false)) {
                        Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($igu.ComputerID) - $($igu.ComputerName) -  Attempting to restart Automate Services - job will be queued"
                        $IGU | Start-RSJob -Throttle $BatchSize -Name "$($igu.ComputerName) - $($igu.ComputerID) - RestartService" -ScriptBlock {
                            Import-Module "C:\GitHubProjects\AutomateAPI\AutomateAPI.psm1" -Force
                            $Global:ControlCredentials = $using:ControlCredentials
                            $Global:ControlServer = $using:ControlServer
                            $ServiceRestartAttempt = Invoke-ControlCommand -GUID $($_.Guid) -Powershell -Command "(new-object Net.WebClient).DownloadString('http://bit.ly/LTPoSh') | iex; Restart-LTService" -TimeOut 60000
                            return $ServiceRestartAttempt
                        } | out-null
                    }
                }
            }
            if ($AutofixReinstallService) {
                if ($PromptBeforeAction) {
                    Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($igu.ComputerID) - $($igu.ComputerName) - Shall we attempt to reinstall the Automate services? Press y for Yes or n for No"
                    $Confirmation = Read-Host "$($igu.ComputerID) - Enter y or n to process a service reinstall"
                    if (($Confirmation -eq 'y') -or ($PromptBeforeAction -eq $false)) {
                        Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($igu.ComputerID) - $($igu.ComputerName) -  Attempting to reinstall Automate Services - job will be queued"
                        $IGU | Start-RSJob -Throttle $BatchSize -Name "$($igu.ComputerName) - $($igu.ComputerID) - ReinstallService" -ScriptBlock {
                            Import-Module "C:\GitHubProjects\AutomateAPI\AutomateAPI.psm1" -Force
                            $Global:ControlCredentials = $using:ControlCredentials
                            $Global:ControlServer = $using:ControlServer
                            $ServiceRestartAttempt = Invoke-ControlCommand -GUID $($_.Guid) -Powershell -Command "(new-object Net.WebClient).DownloadString('http://bit.ly/LTPoSh') | iex; Reinstall-LTService" -TimeOut 600000 -MaxLength 10000
                            return $ServiceRestartAttempt
                        } | out-null
                    }
                }
            }
        }

        Write-Host -ForegroundColor Green "All jobs are queued. Waiting for them to complete. Reinstall jobs can take up to 10 minutes"
        while ($(Get-RSJob | ?{$_.State -ne 'Completed'} | Measure-Object | Select -ExpandProperty Count) -gt 0) {
            Start-Sleep -Milliseconds 5000
            Write-Host -ForegroundColor Yellow "There are currently $(Get-RSJob | ?{$_.State -ne 'Completed'} | Measure-Object | Select -ExpandProperty Count) jobs left to complete"
        }

        $AllServiceRestartJobs = Get-RSJob | Where-Object {$_.Name -like '*RestartService*'}
        $AllServiceReinstallJobs = Get-RSJob | Where-Object {$_.Name -like '*ReinstallService*'}

        foreach ($Job in $AllServiceRestartJobs) {
            $RecJob = ""
            $RecJob = Receive-RSJob -Name $Job.Name
            if ($RecJob -like '*Restarted successfully*') {$AutofixSuccess = $true}else{$AutofixSuccess = $false}
            $ResultArray += [pscustomobject] @{
                JobName = $Job.Name
                JobType = "Restart Automate Services"
                JobState = $Job.State
                JobHasErrors = $Job.HasErrors
                JobResultStream = $RecJob
                AutofixSuccess = $AutofixSuccess
            } 
        }

        foreach ($Job2 in $AllServiceReinstallJobs) {
            $RecJob = ""
            $RecJob = Receive-RSJob -Name $Job2.Name
            if ($RecJob -like '*successfully*') {$AutofixSuccess = $true}else{$AutofixSuccess = $false}
            $ResultArray += [pscustomobject] @{
                JobName = $Job2.Name
                JobType = "Reinstall Automate Service"
                JobState = $Job2.State
                JobHasErrors = $Job2.HasErrors
                JobResultStream = $RecJob
                AutofixSuccess = $AutofixSuccess
            } 
        }
        return $ResultArray
    }
}