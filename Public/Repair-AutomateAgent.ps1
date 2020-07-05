function Repair-AutomateAgent {
<#
.Synopsis
   Takes changed detected in Compare-AutomateControlStatus and performs a specified repair on them
.DESCRIPTION
   Takes changed detected in Compare-AutomateControlStatus and performs a specified repair on them
.PARAMETER Action
   Takes either Update, Restart, Reinstall or Check
.PARAMETER BatchSize
   When multiple jobs are run, they run in Parallel. Batch size determines how many jobs can run at once. Default is 10
.PARAMETER LTPoShURI 
   If you do not wish to use the LT Posh module on GitHub you can use your own link to the LTPosh Module with this parameter
.PARAMETER AutomateControlStatusObject
   Object taken from the Pipeline from Compare-AutomateControlStatus
.EXAMPLE
   Get-AutomateComputer -Online $False | Compare-AutomateControlStatus | Repair-AutomateAgent -Action Check
.EXAMPLE
   Get-AutomateComputer -Online $False | Compare-AutomateControlStatus | Repair-AutomateAgent -Action Restart
.INPUTS
   Compare-AutomateControlStatus Object
.OUTPUTS
   Object containing result of job(s)
#>
   [CmdletBinding(
   SupportsShouldProcess = $true,
   ConfirmImpact = 'High')]
   param (
   [ValidateSet('Update','Restart','ReInstall','Check')]
   [String]$Action = 'Check',

   [Parameter(Mandatory = $False)]
   [ValidateRange(1,50)]
   [int]
   $BatchSize = 10,

   [Parameter(Mandatory = $False)]
   [String]$LTPoShURI = $Script:LTPoShURI,

   [Parameter(ValueFromPipeline = $true)]
   $AutomateControlStatusObject
   )

   Begin {
      $ResultArray = @()
      $ObjectCapture = @()
<#
      $null = Get-RSJob | Remove-RSJob | Out-Null
      $ControlServer = $Script:ControlServer
      $ControlAPIKey = $Script:ControlAPIKey
      $ControlAPICredentials = $Script:ControlAPICredentials
      $ConnectOptions=$Null
#>
   }

   Process {
<#
      If ($ControlServer -and $ControlAPIKey) {
         $ConnectOptions = @{
            'Server' = $ControlServer
            'APIKey' = $ControlAPIKey
         }
      } ElseIf ($ControlServer -and $ControlAPICredentials) {
         $ConnectOptions = @{
            'Server' = $ControlServer
            'Credential' = $ControlAPICredentials
         }
      } Else {
         Return
      }
#>
      Foreach ($igu in $AutomateControlStatusObject) {
         If ($igu.ComputerID -and $igu.SessionID) {
            If ($PSCmdlet.ShouldProcess("Automate Services on $($igu.ComputerID) - $($igu.ComputerName)",$Action)) {
               if ($igu.OperatingSystemName -like '*windows*') {
                  Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($igu.ComputerID) - $($igu.ComputerName) -  Attempting to $Action Automate Services - job will be queued"
                  $ObjectCapture += $AutomateControlStatusObject
               } Else {
                  Write-Host -BackgroundColor Yellow -ForegroundColor Red "This is not a windows machine - there is no Mac/Linux support at present in this module"
               }
            }
         } Else {
            Write-Host -BackgroundColor Yellow -ForegroundColor Red "An object was passed that is missing a required property (ComputerID, SessionID)"
         }
      }
   }

   End {
<#
      If (!$ConnectOptions) {
         Throw "Control Server information must be assigned with Connect-ControlAPI function first."
         Return
      }
#>
      if ($ObjectCapture) {
         Write-Host -ForegroundColor Green "Starting fixes"

         If ($Action -eq 'Check') {
            $ServiceResult = $ObjectCapture | Invoke-ControlCommand -Powershell -Command "(new-object Net.WebClient).DownloadString('$($LTPoShURI)') | iex; Get-LTServiceInfo" -TimeOut 60000 -MaxLength 10240 -BatchSize $BatchSize -OfflineAction Skip
         } ElseIf ($Action -eq 'Update') {
            $ServiceResult = $ObjectCapture | Invoke-ControlCommand -Powershell -Command "(new-object Net.WebClient).DownloadString('$($LTPoShURI)') | iex; Update-LTService" -TimeOut 120000 -MaxLength 10240 -BatchSize $BatchSize -OfflineAction Skip
         } ElseIf ($Action -eq 'Restart') {
            $ServiceResult = $ObjectCapture | Invoke-ControlCommand -Powershell -Command "(new-object Net.WebClient).DownloadString('$($LTPoShURI)') | iex; Restart-LTService" -TimeOut 120000 -MaxLength 10240 -BatchSize $BatchSize -OfflineAction Skip
         } ElseIf ($Action -eq 'Reinstall') {
            $InstallerToken = Get-AutomateInstallerToken
            $ServiceResult = $ObjectCapture | Invoke-ControlCommand -Powershell -Command "(new-object Net.WebClient).DownloadString('$($LTPoShURI)') | iex; Install-LTService -Server '$($Script:CWAServer)' -LocationID $($_.Location.Id) -InstallerToken '$($InstallerToken)' -Force -SkipDotNet" -TimeOut 300000 -MaxLength 10240 -BatchSize $BatchSize -OfflineAction Skip
         } Else {
            Write-Host -BackgroundColor Yellow -ForegroundColor Red "Action $Action is not currently supported."
         }
            
            
<#
         If ($Action -eq 'Check') {
            $ObjectCapture | Start-RSJob -Throttle $BatchSize -Name {"$($_.ComputerName) - $($_.ComputerID) - Check Service"} -ScriptBlock {
            Import-Module AutomateAPI -Force
            $ConnectOptions=$Using:ConnectOptions
            If (Connect-ControlAPI @ConnectOptions -SkipCheck -Quiet) {
               $ServiceResult = Invoke-ControlCommand -SessionID $($_.SessionID) -Powershell -Command "(new-object Net.WebClient).DownloadString('$($Using:LTPoShURI)') | iex; Get-LTServiceInfo" -TimeOut 60000 -MaxLength 10240
               return $ServiceResult
            }
            } | out-null
         } ElseIf ($Action -eq 'Update') {
            $ObjectCapture | Start-RSJob -Throttle $BatchSize -Name {"$($_.ComputerName) - $($_.ComputerID) - Update Service"} -ScriptBlock {
            Import-Module AutomateAPI -Force
            $ConnectOptions=$Using:ConnectOptions
            If (Connect-ControlAPI @ConnectOptions -SkipCheck -Quiet) {
               $ServiceResult = Invoke-ControlCommand -SessionID $($_.SessionID) -Powershell -Command "(new-object Net.WebClient).DownloadString('$($Using:LTPoShURI)') | iex; Update-LTService" -TimeOut 300000 -MaxLength 10240
               return $ServiceResult
            }
            } | out-null
         } ElseIf ($Action -eq 'Restart') {
            $ObjectCapture | Start-RSJob -Throttle $BatchSize -Name {"$($_.ComputerName) - $($_.ComputerID) - Restart Service"} -ScriptBlock {
            Import-Module AutomateAPI -Force
            $ConnectOptions=$Using:ConnectOptions
            If (Connect-ControlAPI @ConnectOptions -SkipCheck -Quiet) {
               $ServiceResult = Invoke-ControlCommand -SessionID $($_.SessionID) -Powershell -Command "(new-object Net.WebClient).DownloadString('$($Using:LTPoShURI)') | iex; Restart-LTService" -TimeOut 120000 -MaxLength 10240
               return $ServiceResult
            }
            } | out-null
         } ElseIf ($Action -eq 'Reinstall') {
            $ObjectCapture | Add-Member -NotePropertyName InstallerToken -NotePropertyValue $(Get-AutomateInstallerToken)
            $ObjectCapture | Add-Member -NotePropertyName AutomateServerAddress -NotePropertyValue $Script:CWAServer
            $ObjectCapture | Start-RSJob -Throttle $BatchSize -Name {"$($_.ComputerName) - $($_.ComputerID) - ReInstall Service"} -ScriptBlock {
            Import-Module AutomateAPI -Force
            $ConnectOptions=$Using:ConnectOptions
            If (Connect-ControlAPI @ConnectOptions -SkipCheck -Quiet) {
               $ServiceResult = Invoke-ControlCommand -SessionID $($_.SessionID) -Powershell -Command "(new-object Net.WebClient).DownloadString('$($Using:LTPoShURI)') | iex; Install-LTService -Server '$($_.AutomateServerAddress)' -LocationID $($_.Location.Id) -InstallerToken '$($_.InstallerToken)' -Force -SkipDotNet" -TimeOut 300000 -MaxLength 10240
               return $ServiceResult
            }
            } | out-null
         } Else {
            Write-Host -BackgroundColor Yellow -ForegroundColor Red "Action $Action is not currently supported."
         }

         Write-Host -ForegroundColor Green "All jobs are queued. Waiting for them to complete. Reinstall jobs can take up to 10 minutes"
         while ($(Get-RSJob | Where-Object {$_.State -ne 'Completed'} | Measure-Object | Select-Object -ExpandProperty Count) -gt 0) {
            Start-Sleep -Milliseconds 10000
            Write-Host -ForegroundColor Yellow "$(Get-Date) - There are currently $(Get-RSJob | Where-Object{$_.State -ne 'Completed'} | Measure-Object | Select-Object -ExpandProperty Count) jobs left to complete"
         }

         $AllServiceJobs = Get-RSJob | Where-Object {$_.Name -like "*$($Action) Service*"}

         foreach ($Job in $AllServiceJobs) {
            $RecJob = ""
            $RecJob = Receive-RSJob -Name $Job.Name
            If ($Action -eq 'Check') {
               If ($RecJob -like '*LastSuccessStatus*') {$AutofixSuccess = $true}else{$AutofixSuccess = $false}
            } ElseIf ($Action -eq 'Update') {
               If ($RecJob -like '*successfully*') {$AutofixSuccess = $true}else{$AutofixSuccess = $false}
            } ElseIf ($Action -eq 'Restart') {
               If ($RecJob -like '*Restarted successfully*') {$AutofixSuccess = $true}else{$AutofixSuccess = $false}
            } ElseIf ($Action -eq 'ReInstall') {
               If ($RecJob -like '*successfully*') {$AutofixSuccess = $true}else{$AutofixSuccess = $false}
            } Else {
               $AutofixSuccess = $true
            }
#>
         foreach ($Job in $ServiceResult) {
            If ($Action -eq 'Check') {
               If ($Job.Output -like '*LastSuccessStatus*') {$AutofixSuccess = $true} else {$AutofixSuccess = $false}
            } ElseIf ($Action -eq 'Update') {
               If ($Job.Output -like '*successfully*') {$AutofixSuccess = $true}else{$AutofixSuccess = $false}
            } ElseIf ($Action -eq 'Restart') {
               If ($Job.Output -like '*Restarted successfully*') {$AutofixSuccess = $true}else{$AutofixSuccess = $false}
            } ElseIf ($Action -eq 'ReInstall') {
               If ($Job.Output -like '*successfully*') {$AutofixSuccess = $true}else{$AutofixSuccess = $false}
            } Else {
               $AutofixSuccess = $true
            }
            $ResultArray += [pscustomobject] @{
            JobResultStream = $Job
            AutofixSuccess = $AutofixSuccess
            } 
         }

         Write-Host -ForegroundColor Green "All jobs completed"
         return $ResultArray
      } Else {
         'No Queued Jobs'
      }
   }
}
