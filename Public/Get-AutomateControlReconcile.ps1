function Get-AutomateControlReconcile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = "Remediate")]
        [bool]$PromptBeforeAction = $true,

        [Parameter(Mandatory = $false, ParameterSetName = "Remediate")]
        [bool]$AutofixRestartService = $false,

        [Parameter(Mandatory = $false, ParameterSetName = "Remediate")]
        [bool]$AutofixReinstallService = $false,

        [Parameter()]
        [int]$NotSeenInDays = 30,

        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName=$true)]
        [Alias('Id')]
        [int[]]$ComputerID

    )
  
    begin {
        $ResultArray = @()
        $RestartServiceRecheckArray  = @()        
    }
  
    process {

        if ($PSBoundParameters.ContainsKey('ComputerID') -and -not([string]::IsNullOrEmpty($ComputerID))) {
            $ComputersToCheck = Get-AutomateComputer -ComputerID $ComputerID
        }
        else {
            
            $ComputersToCheck = Get-AutomateComputer -NotSeenInDays $NotSeenInDays
        }
   
        foreach ($CompToCheck in $ComputersToCheck) {

            #Calculate how many days until it has been online
            $AutomateDate = [DateTime]$CompToCheck.RemoteAgentLastContact
            $Now = Get-Date
            $NumberOfDays = New-TimeSpan -Start $AutomateDate -End $Now | Select -ExpandProperty Days
  
            #Start building the custom object
            $ResultObject = [PSCustomObject]@{}
            $ResultObject | Add-Member -Type NoteProperty -Name "ComputerID" -Value $CompToCheck.Id
            $ResultObject | Add-Member -Type NoteProperty -Name "ComputerName" -Value $CompToCheck.ComputerName
            $ResultObject | Add-Member -Type NoteProperty -Name "ClientName" -Value $CompToCheck.Client.Name
            $ResultObject | Add-Member -Type NoteProperty -Name "LocationName" -Value $CompToCheck.Location.Name
            $ResultObject | Add-Member -Type NoteProperty -Name "LastContactDateInAutomate" -Value $AutomateDate
            $ResultObject | Add-Member -Type NoteProperty -Name "DaysSinceSeenInAutomate" -Value $NumberOfDays
            $ResultObject | Add-Member -Type NoteProperty -Name "AutofixServiceRestartResult" -Value ""
  
            Write-Host "Checking ID $($CompToCheck.ID) - $($CompToCheck.ComputerName) at $($CompToCheck.Client.Name). Last seen $($AutomateDate) which was $NumberOfDays days ago" -BackgroundColor Yellow -ForegroundColor Black
  
            #Get the Control GUID for this instance
            $ControlGuid = $(Get-AutomateControlGUID -ComputerID $CompToCheck.ID | Select -ExpandProperty ControlGUID)
            if (-not([string]::IsNullOrEmpty($ControlGuid)) -and ($ControlGuid -ne 'No Guid Found')) {
                $ResultObject | Add-Member -Type NoteProperty -Name "ControlGUID" -Value $ControlGUID
  
                #Get Last Contact Date from Control
                $LastContactDateInControl = Get-ControlLastContact -GUID $ControlGuid
                $ResultObject | Add-Member -Type NoteProperty -Name "LastContactDateInControl" -Value $LastContactDateInControl
  
                #Convert to a date, if we can then add to Result Object
                try {
                    $ControlTimeSpan = New-TimeSpan -Start $LastContactDateInControl -End $Now
                    $NumberOfMinutesInControl = $ControlTimeSpan | Select-Object -ExpandProperty TotalMinutes
                    $NumberOfDaysInControl = $ControlTimeSpan | Select-Object -ExpandProperty Days
                }
                catch {
                    $NumberOfMinutesInControl = $null
                    $NumberOfDaysInControl = $null
                }

                #Check if it is actually online now, if so process any fixes
                if (($NumberOfMinutesInControl -gt -5) -and ($NumberOfMinutesInControl -le 5) -and (-not [string]::IsNullOrEmpty($NumberOfMinutesInControl))) {
                    $ResultObject | Add-Member -Type NoteProperty -Name "IsOnline" -Value $True
                    Write-Host "$($CompToCheck.ID) - $($CompToCheck.ComputerName) at $($CompToCheck.Client.Name) is ONLINE in Control. Last seen in Automate $($AutomateDate)" -BackgroundColor Red -ForegroundColor Yellow


                    if ($AutofixRestartService) {
                        if ($PromptBeforeAction) {
                            Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($CompToCheck.ID) - $($CompToCheck.ComputerName) at $($CompToCheck.Client.Name) - Shall we attempt to restart the Automate services? Press y for Yes or n for No"
                            $Confirmation = Read-Host "$($CompToCheck.ID) - $($CompToCheck.ComputerName) - Enter y or n to process a service restart"
                            if ($Confirmation -eq 'y') {
                                #Perform Invoke Action
                                Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($CompToCheck.ID) - $($CompToCheck.ComputerName) - Attempting to restart Automate Services"
                                $ServiceRestartAttempt = Invoke-ControlCommand -GUID $ControlGuid -Powershell -Command "(new-object Net.WebClient).DownloadString('http://bit.ly/LTPoSh') | iex; Restart-LTService"
                                Write-Host -BackgroundColor DarkGray -ForegroundColor Green "$($CompToCheck.ID) - $($CompToCheck.ComputerName) - Result of service restart - $ServiceRestartAttempt"
                                $ResultObject.AutofixServiceRestartResult = $ServiceRestartAttempt
                            }
                        }
                        else {
                            Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($CompToCheck.ID) - $($CompToCheck.ComputerName) - Attempting to restart Automate Services"
                            $ServiceRestartAttempt = Invoke-ControlCommand -GUID $ControlGuid -Powershell -Command "(new-object Net.WebClient).DownloadString('http://bit.ly/LTPoSh') | iex; Restart-LTService" -TimeOut 480000 
                            Write-Host -BackgroundColor DarkGray -ForegroundColor Green "$($CompToCheck.ID) - $($CompToCheck.ComputerName) - Result of service restart - $ServiceRestartAttempt"
                            $ResultObject.AutofixServiceRestartResult = $ServiceRestartAttempt
                        }

                        #Add this computer ID into an Array that gets re-checked at the end of the process
                        if ($Confirmation -eq 'y'){$RestartServiceRecheckArray += $($CompToCheck.ID)}
                    }

                    if ($AutofixReinstallService) {
                        if ($PromptBeforeAction) {
                            Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($CompToCheck.ID) - $($CompToCheck.ComputerName) at $($CompToCheck.Client.Name) - Shall we attempt to reinstall the Automate services? Press y for Yes or n for No"
                            $Confirmation = Read-Host "$($CompToCheck.ID) - $($CompToCheck.ComputerName) - Enter y or n to process a service reinstall"
                            if ($Confirmation -eq 'y') {
                                #Perform Invoke Action
                                Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($CompToCheck.ID) - $($CompToCheck.ComputerName) - Attempting to reinstall Automate Services"
                                $ServiceReinstallAttempt = Invoke-ControlCommand -GUID $ControlGuid -Powershell -Command "(new-object Net.WebClient).DownloadString('http://bit.ly/LTPoSh') | iex; Reinstall-LTService"
                                Write-Host -BackgroundColor DarkGray -ForegroundColor Green "$($CompToCheck.ID) - $($CompToCheck.ComputerName) - Result of service restart - $ServiceReinstallAttempt"
                                $ResultObject.AutofixServiceReinstallResult = $ServiceReinstallAttempt
                            }
                        }
                        else {
                            Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($CompToCheck.ID) - $($CompToCheck.ComputerName) - Attempting to restart Automate Services"
                            $ServiceReinstallAttempt = Invoke-ControlCommand -GUID $ControlGuid -Powershell -Command "(new-object Net.WebClient).DownloadString('http://bit.ly/LTPoSh') | iex; Reinstall-LTService"
                            Write-Host -BackgroundColor DarkGray -ForegroundColor Green "$($CompToCheck.ID) - $($CompToCheck.ComputerName) - Result of service reinstall - $ServiceReinstallAttempt"
                            $ResultObject.AutofixServiceReinstallResult = $ServiceReinstallAttempt
                        }

                        #Add this computer ID into an Array that gets re-checked at the end of the process
                        if ($Confirmation -eq 'y'){$ReinstallServiceRecheckArray += $($CompToCheck.ID)}
                    }

                }
                else {
                    $ResultObject | Add-Member -Type NoteProperty -Name "IsOnline" -Value $False
                }
                $ResultObject | Add-Member -Type NoteProperty -Name "MinutesSinceSeenInControl" -Value $NumberOfMinutesInControl
                $ResultObject | Add-Member -Type NoteProperty -Name "DaysSinceSeenInControl" -Value $NumberOfDaysInControl
            }

            
        }

<#         #Recheck items where services have been restarted
        if ($AutofixRestartService -and ($RestartServiceRecheckArray.Count -gt 0)) {
            Write-Host "Checking the following IDs to ensure service restart worked $RestartServiceRecheckArray"
            foreach ($id in $RestartServiceRecheckArray) {
                $Status = Get-AutomateComputer -ComputerID $id | Select -ExpandProperty Status
                if ($Status -eq 'Online') {Write-Host -BackgroundColor Green -ForegroundColor Black "$ID is back online!"}
            }
        }
        return $ResultObject #>
    }

    
  
    end {
        
    }
}