function Start-AutofixAgent {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High',
        DefaultParameterSetName = 'restart')]
    param (
 #       [Parameter(Mandatory = $false)]
 #       [bool]$PromptBeforeAction = $true,

        [Parameter(ParameterSetName = 'restart', Mandatory = $True)]
        [bool]$AutofixRestartService = $false,

        [Parameter(ParameterSetName = 'reinstall', Mandatory = $True)]
        [bool]$AutofixReinstallService = $false,

        [Parameter(ParameterSetName = 'restart', Mandatory = $False)]
        [Parameter(ParameterSetName = 'reinstall', Mandatory = $False)]
        [Parameter(ValueFromPipeline = $true)]
        $AutomateControlStatusObject

    )
  
    Begin {
        $ResultArray = @()
        $ObjectCapture = @()
        $null = Get-RSJob | Remove-RSJob | Out-Null       
    }
  
    Process {
        $ObjectCapture += $AutomateControlStatusObject
    }

    End {
        Write-Host -ForegroundColor Green "Starting fixes - you will be prompted if you have turned this on"
        foreach ($igu in $ObjectCapture) {
            if ($AutofixRestartService -and $PSCmdlet.ShouldProcess("Automate Services","Restart")) {
#                if ($PromptBeforeAction) 
#                    Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($igu.ComputerID) - $($igu.ComputerName) - Shall we attempt to restart the Automate services? Press y for Yes or n for No"
#                    $Confirmation = Read-Host "$($igu.ComputerID) - Enter y or n to process a service restart"
#                    if (($Confirmation -eq 'y') -or ($PromptBeforeAction -eq $false)) {
                if ($igu.OperatingSystem -like '*windows*') {
                    Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($igu.ComputerID) - $($igu.ComputerName) -  Attempting to restart Automate Services - job will be queued"
                    $IGU | Start-RSJob -Throttle $BatchSize -Name "$($igu.ComputerName) - $($igu.ComputerID) - RestartService" -ScriptBlock {
                        Import-Module AutomateAPI -Force
                        $Script:ControlCredentials = $using:ControlCredentials
                        $Script:ControlServer = $using:ControlServer
                        $ServiceRestartAttempt = Invoke-ControlCommand -GUID $($_.Guid) -Powershell -Command "(new-object Net.WebClient).DownloadString('http://bit.ly/LTPoSh') | iex; Restart-LTService" -TimeOut 60000
                        return $ServiceRestartAttempt
                    } | out-null
                }
                else {
                    Write-Host -BackgroundColor Yellow -ForegroundColor Red "This is not a windows machine - there is no Mac/Linux support at present in this module"
                }
            } ElseIf ($AutofixReinstallService -and $PSCmdlet.ShouldProcess("Automate Services","Reinstall")) {
#                if ($PromptBeforeAction) {
#                    Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($igu.ComputerID) - $($igu.ComputerName) - Shall we attempt to reinstall the Automate services? Press y for Yes or n for No"
#                    $Confirmation = Read-Host "$($igu.ComputerID) - Enter y or n to process a service reinstall"
#                    if (($Confirmation -eq 'y') -or ($PromptBeforeAction -eq $false)) {
#                    if ($PSCmdlet.ShouldProcess("Automate Services","Reinstall")) {
                if ($igu.OperatingSystem -like '*windows*') {
                    Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($igu.ComputerID) - $($igu.ComputerName) -  Attempting to reinstall Automate Services - job will be queued"
                    $IGU | Start-RSJob -Throttle $BatchSize -Name "$($igu.ComputerName) - $($igu.ComputerID) - ReinstallService" -ScriptBlock {
                        Import-Module AutomateAPI -Force
                        $Script:ControlCredentials = $using:ControlCredentials
                        $Script:ControlServer = $using:ControlServer
                        $ServiceRestartAttempt = Invoke-ControlCommand -GUID $($_.Guid) -Powershell -Command "(new-object Net.WebClient).DownloadString('http://bit.ly/LTPoSh') | iex; Reinstall-LTService" -TimeOut 600000 -MaxLength 10000
                        return $ServiceRestartAttempt
                    } | out-null
                }
                else {
                    Write-Host -BackgroundColor Yellow -ForegroundColor Red "This is not a windows machine - there is no Mac/Linux support at present in this module"
                }
            }
        }

        Write-Host -ForegroundColor Green "All jobs are queued. Waiting for them to complete. Reinstall jobs can take up to 10 minutes"
        while ($(Get-RSJob | ?{$_.State -ne 'Completed'} | Measure-Object | Select-Object -ExpandProperty Count) -gt 0) {
            Start-Sleep -Milliseconds 10000
            Write-Host -ForegroundColor Yellow "$(Get-Date) - There are currently $(Get-RSJob | ?{$_.State -ne 'Completed'} | Measure-Object | Select -ExpandProperty Count) jobs left to complete"
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
                JobResultStream = "$RecJob"
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
                JobResultStream = "$RecJob"
                AutofixSuccess = $AutofixSuccess
            } 
        }
        Write-Host -ForegroundColor Green "All jobs completed"
        return $ResultArray
    }
}
