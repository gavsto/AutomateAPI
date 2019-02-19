function Repair-AutomateAgent {
<#
.Synopsis
   Takes changed detected in Compare-AutomateControlStatus and performs a specified repair on them
.DESCRIPTION
   Takes changed detected in Compare-AutomateControlStatus and performs a specified repair on them
.PARAMETER Check
   Triggers a different type of check depending on what is passed either Update, Restart, Reinstall or Check
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
   $BatchSize = 5,

   [Parameter(ValueFromPipeline = $true)]
   $AutomateControlStatusObject
   )

   Begin {
      $ResultArray = @()
      $ObjectCapture = @()
      $null = Get-RSJob | Remove-RSJob | Out-Null
      $ControlAPICredentials = $Script:ControlAPICredentials
      $ControlServer = $Script:ControlServer
      If (!($ControlServer -and $ControlAPICredentials)) {
         Throw "Control Server information must be assigned with Connect-ControlAPI function first."
         Continue
      }
   }

   Process {
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
      Write-Host -ForegroundColor Green "Starting fixes"
      if ($ObjectCapture) {

         If ($Action -eq 'Check') {
            $ObjectCapture | Start-RSJob -Throttle $BatchSize -Name {"$($_.ComputerName) - $($_.ComputerID) - Check Service"} -ScriptBlock {
            Import-Module AutomateAPI -Force
            $ServiceRestartAttempt = Invoke-ControlCommand -Server $($using:ControlServer) -Credential $($using:ControlAPICredentials) -GUID $($_.SessionID) -Powershell -Command "(new-object Net.WebClient).DownloadString('http://bit.ly/LTPoSh') | iex; Get-LTServiceInfo" -TimeOut 60000 -MaxLength 10240
            return $ServiceRestartAttempt
            } | out-null
         } ElseIf ($Action -eq 'Update') {
            $ObjectCapture | Start-RSJob -Throttle $BatchSize -Name {"$($_.ComputerName) - $($_.ComputerID) - Update Service"} -ScriptBlock {
            Import-Module AutomateAPI -Force
            $ServiceRestartAttempt = Invoke-ControlCommand -Server $using:ControlServer -Credential $using:ControlAPICredentials -GUID $($_.SessionID) -Powershell -Command "(new-object Net.WebClient).DownloadString('http://bit.ly/LTPoSh') | iex; Update-LTService" -TimeOut 120000 -MaxLength 10240
            return $ServiceRestartAttempt
            } | out-null
         } ElseIf ($Action -eq 'Restart') {
            $ObjectCapture | Start-RSJob -Throttle $BatchSize -Name {"$($_.ComputerName) - $($_.ComputerID) - Restart Service"} -ScriptBlock {
            Import-Module AutomateAPI -Force
            $ServiceRestartAttempt = Invoke-ControlCommand -Server $using:ControlServer -Credential $using:ControlAPICredentials -GUID $($_.SessionID) -Powershell -Command "(new-object Net.WebClient).DownloadString('http://bit.ly/LTPoSh') | iex; Restart-LTService" -TimeOut 120000 -MaxLength 10240
            return $ServiceRestartAttempt
            } | out-null
         } ElseIf ($Action -eq 'Reinstall') {
            $ObjectCapture | Start-RSJob -Throttle $BatchSize -Name {"$($_.ComputerName) - $($_.ComputerID) - ReInstall Service"} -ScriptBlock {
            Import-Module AutomateAPI -Force
            $ServiceRestartAttempt = Invoke-ControlCommand -Server $using:ControlServer -Credential $using:ControlAPICredentials -GUID $($_.SessionID) -Powershell -Command "(new-object Net.WebClient).DownloadString('http://bit.ly/LTPoSh') | iex; ReInstall-LTService" -TimeOut 360000 -MaxLength 10240
            return $ServiceRestartAttempt
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
            $ResultArray += [pscustomobject] @{
            JobName = $Job.Name
            JobType = "$($Action) Automate Services"
            JobState = $Job.State
            JobHasErrors = $Job.HasErrors
            JobResultStream = "$RecJob"
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
