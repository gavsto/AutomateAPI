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
   SupportsShouldProcess = $True,
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

   [Parameter(Mandatory = $True, ValueFromPipeline = $True)]
   $AutomateControlStatusObject
   )

   Begin {
      $RepairProperty='RepairResult'
      $ObjectCapture = {}.Invoke()
   }

   Process {
      Foreach ($igu in $AutomateControlStatusObject) {
         If ($igu.ComputerID -and $igu.SessionID -and $igu.SessionID -match '^[a-z0-9]{8}(?:-[a-z0-9]{4}){3}-[a-z0-9]{12}' -and !($Action -eq 'Reinstall' -and !($igu.Location.ID -gt 0))) {
            If ($PSCmdlet.ShouldProcess("Automate Services on $($igu.ComputerID) - $($igu.ComputerName)",$Action)) {
               if ($igu.OperatingSystemName -like '*windows*') {
                  Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($igu.ComputerID) - $($igu.ComputerName) -  Attempting to $Action Automate Services - job will be submitted to online systems"
                  $Null = $ObjectCapture.Add($AutomateControlStatusObject)
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
      if ($ObjectCapture) {
         Write-Host -ForegroundColor Green "Starting fixes"

         If ($Action -eq 'Check') {
            $ServiceResults = $ObjectCapture | Invoke-ControlCommand -Powershell -Command "(new-object Net.WebClient).DownloadString('$($LTPoShURI)') | iex; Get-LTServiceInfo" -TimeOut 60000 -MaxLength 10240 -BatchSize $BatchSize -OfflineAction Skip -ResultPropertyName $RepairProperty
         } ElseIf ($Action -eq 'Update') {
            $ServiceResults = $ObjectCapture | Invoke-ControlCommand -Powershell -Command "(new-object Net.WebClient).DownloadString('$($LTPoShURI)') | iex; Update-LTService" -TimeOut 120000 -MaxLength 10240 -BatchSize $BatchSize -OfflineAction Skip -ResultPropertyName $RepairProperty
         } ElseIf ($Action -eq 'Restart') {
            $ServiceResults = $ObjectCapture | Invoke-ControlCommand -Powershell -Command "(new-object Net.WebClient).DownloadString('$($LTPoShURI)') | iex; Restart-LTService" -TimeOut 120000 -MaxLength 10240 -BatchSize $BatchSize -OfflineAction Skip -ResultPropertyName $RepairProperty
         } ElseIf ($Action -eq 'Reinstall') {
            $InstallerToken = Get-AutomateInstallerToken
            $ServiceResults = $ObjectCapture | Invoke-ControlCommand -Powershell -Command "(new-object Net.WebClient).DownloadString('$($LTPoShURI)') | iex; Install-LTService -Server '$($Script:CWAServer)' -LocationID $($_.Location.Id) -InstallerToken '$($InstallerToken)' -Force -SkipDotNet" -TimeOut 300000 -MaxLength 10240 -BatchSize $BatchSize -OfflineAction Skip -ResultPropertyName $RepairProperty
         } Else {
            Write-Host -BackgroundColor Yellow -ForegroundColor Red "Action $Action is not currently supported."
         }

         #Prepare a lookup for results
         $SResultLookup=@{}
         $ServiceResults | ForEach-Object {If (!($SResultLookup.ContainsKey("$($_.SessionID)"))) {$SResultLookup.Add("$($_.SessionID)",$_)}}
         Foreach ($singleObject in $ObjectCapture) {
            If ($SResultLookup.ContainsKey($singleObject.SessionID)) {
               $singleResult=$SResultLookup["$($singleObject.SessionID)"]
               If ($Action -eq 'Check') {
                  If ($singleResult.$RepairProperty -like '*LastSuccessStatus*') {$AutofixSuccess = $true} else {$AutofixSuccess = $false}
               } ElseIf ($Action -eq 'Update') {
                  If ($singleResult.$RepairProperty -like '*successfully*') {$AutofixSuccess = $true}else{$AutofixSuccess = $false}
               } ElseIf ($Action -eq 'Restart') {
                  If ($singleResult.$RepairProperty -like '*Restarted successfully*') {$AutofixSuccess = $true}else{$AutofixSuccess = $false}
               } ElseIf ($Action -eq 'ReInstall') {
                  If ($singleResult.$RepairProperty -like '*successfully*') {$AutofixSuccess = $true}else{$AutofixSuccess = $false}
               } Else {
                  $AutofixSuccess = $true
               }   
            } Else {
               $singleResult=[pscustomobject]@{
                  $RepairProperty = "No result was returned for sessionID $($singleObject.SessionID)"
                  $AutofixSuccess = $False
               }
            }
            #Output the final object
            $singleObject | Select-Object -ExcludeProperty $RepairProperty -Property *,@{n=$RepairProperty;e={[pscustomobject]@{'AutofixResult'=$singleResult.$RepairProperty; 'AutofixSuccess'=$AutofixSuccess}}}
         }

         Write-Host -ForegroundColor Green "All jobs completed"
      } Else {
         'No Input Objects could be processed'
      }
   }
}
