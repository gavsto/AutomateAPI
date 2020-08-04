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
            $Null = $ObjectCapture.Add($igu)
         } Else {
            Write-Host -BackgroundColor Yellow -ForegroundColor Red "An object was passed that is missing a required property (ComputerID, SessionID)"
         }
      }
   }

   End {
      If ($ObjectCapture) {
         Write-Host -ForegroundColor Green "Starting fixes"
         If ($Action -eq 'Check') {
            $ServiceResults = $(
               $ObjectCapture | Where-Object {$_.OperatingSystemName -like '*windows*'} | ForEach-Object {
                  If ($PSCmdlet.ShouldProcess("Automate Services on $($_.ComputerID) - $($_.ComputerName)",$Action)) {
                     Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($_.ComputerID) - $($_.ComputerName) - Attempting to $Action Automate Services - job will be submitted to online systems"
                     $_
                  }
               } | Invoke-ControlCommand -Powershell -Command "(new-object Net.WebClient).DownloadString('$($LTPoShURI)') | iex; Get-LTServiceInfo" -TimeOut 60000 -MaxLength 10240 -BatchSize $BatchSize -OfflineAction Skip -ResultPropertyName $RepairProperty -PassthroughObjects
               $ObjectCapture | Where-Object {$_.OperatingSystemName -like '*OS X*'}  | ForEach-Object {
                  If ($PSCmdlet.ShouldProcess("Automate Services on $($_.ComputerID) - $($_.ComputerName)",$Action)) {
                     Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($_.ComputerID) - $($_.ComputerName) - Attempting to $Action Automate Services - job will be submitted to online systems"
                     $_
                  }
               } | Invoke-ControlCommand -Command @'
[ -f /usr/local/ltechagent/state ]&&(echo "["
cat /usr/local/ltechagent/state 2>/dev/null
[ -f /usr/local/ltechagent/agent_config ]&&echo ',{'
cat /usr/local/ltechagent/agent_config | awk '{ print "\"" $1 "\": \"" $2 "\","} END { print "\"" $1 "\": \"" $2 "\"\n}]"}')
'@ -TimeOut 60000 -MaxLength 10240 -BatchSize $BatchSize -OfflineAction Skip -ResultPropertyName $RepairProperty -PassthroughObjects
            )
            $ObjectCapture | Where-Object {!($_.OperatingSystemName -like '*windows*' -or $_.OperatingSystemName -like '*OS X*')}  | ForEach-Object {
               Write-Host -BackgroundColor Yellow -ForegroundColor Red "$($_.ComputerID) - $($_.ComputerName) - $Action action for Operating System ($($_.OperatingSystemName)) is not supported at present in this module"
            }
         } ElseIf ($Action -eq 'Update') {
            $ServiceResults = $(
               $ObjectCapture | Where-Object {$_.OperatingSystemName -like '*windows*'} | ForEach-Object {
                  If ($PSCmdlet.ShouldProcess("Automate Services on $($_.ComputerID) - $($_.ComputerName)",$Action)) {
                     Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($_.ComputerID) - $($_.ComputerName) - Attempting to $Action Automate Services - job will be submitted to online systems"
                     $_
                  }
               } | Invoke-ControlCommand -Powershell -Command "(new-object Net.WebClient).DownloadString('$($LTPoShURI)') | iex; Update-LTService" -TimeOut 120000 -MaxLength 10240 -BatchSize $BatchSize -OfflineAction Skip -ResultPropertyName $RepairProperty -PassthroughObjects
               $ObjectCapture | Where-Object {$_.OperatingSystemName -like '*OS X*'}  | ForEach-Object {
                  If ($PSCmdlet.ShouldProcess("Automate Services on $($_.ComputerID) - $($_.ComputerName)",$Action)) {
                     Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($_.ComputerID) - $($_.ComputerName) - Attempting to $Action Automate Services - job will be submitted to online systems"
                     $_
                  }
               } | Invoke-ControlCommand -Command '/usr/local/ltechagent/ltupdate' -TimeOut 60000 -MaxLength 10240 -BatchSize $BatchSize -OfflineAction Skip -ResultPropertyName $RepairProperty -PassthroughObjects
            )
            $ObjectCapture | Where-Object {!($_.OperatingSystemName -like '*windows*' -or $_.OperatingSystemName -like '*OS X*')}  | ForEach-Object {
               Write-Host -BackgroundColor Yellow -ForegroundColor Red "$($_.ComputerID) - $($_.ComputerName) - $Action action for Operating System ($($_.OperatingSystemName)) is not supported at present in this module"
            }
         } ElseIf ($Action -eq 'Restart') {
            $ServiceResults = $(
               $ObjectCapture | Where-Object {$_.OperatingSystemName -like '*windows*'} | ForEach-Object {
                  If ($PSCmdlet.ShouldProcess("Automate Services on $($_.ComputerID) - $($_.ComputerName)",$Action)) {
                     Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($_.ComputerID) - $($_.ComputerName) - Attempting to $Action Automate Services - job will be submitted to online systems"
                     $_
                  }
               } | Invoke-ControlCommand -Powershell -Command "(new-object Net.WebClient).DownloadString('$($LTPoShURI)') | iex; Restart-LTService" -TimeOut 120000 -MaxLength 10240 -BatchSize $BatchSize -OfflineAction Skip -ResultPropertyName $RepairProperty -PassthroughObjects
               $ObjectCapture | Where-Object {$_.OperatingSystemName -like '*OS X*'}  | ForEach-Object {
                  If ($PSCmdlet.ShouldProcess("Automate Services on $($_.ComputerID) - $($_.ComputerName)",$Action)) {
                     Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($_.ComputerID) - $($_.ComputerName) - Attempting to $Action Automate Services - job will be submitted to online systems"
                     $_
                  }
               }| Invoke-ControlCommand -Command @'
LOGGEDUSERS=`who | grep console | awk '{ print $1 }'`
echo "Stopping Services"
(launchctl unload /Library/LaunchDaemons/com.labtechsoftware.LTSvc.plist; launchctl unload /Library/LaunchDaemons/com.labtechsoftware.LTUpdate.plist; for CURRUSER in $LOGGEDUSERS; do su -l $CURRUSER -c 'launchctl unload /Library/LaunchAgents/com.labtechsoftware.LTTray.plist'; done)
echo "Starting Services"
sleep 5; launchctl load /Library/LaunchDaemons/com.labtechsoftware.LTSvc.plist
for CURRUSER in $LOGGEDUSERS; do su -l $CURRUSER -c 'launchctl load /Library/LaunchAgents/com.labtechsoftware.LTTray.plist'; done
echo "Checking Services"
(for CURRUSER in $LOGGEDUSERS; do su -l $CURRUSER -c 'launchctl list'; done) | grep -i "com.labtechsoftware"
launchctl list | grep -i "com.labtechsoftware"&&echo "LTService Restarted successfully"
'@ -TimeOut 60000 -MaxLength 10240 -BatchSize $BatchSize -OfflineAction Skip -ResultPropertyName $RepairProperty -PassthroughObjects
            )
            $ObjectCapture | Where-Object {!($_.OperatingSystemName -like '*windows*' -or $_.OperatingSystemName -like '*OS X*')}  | ForEach-Object {
               Write-Host -BackgroundColor Yellow -ForegroundColor Red "$($_.ComputerID) - $($_.ComputerName) - $Action action for Operating System ($($_.OperatingSystemName)) is not supported at present in this module"
            }
         } ElseIf ($Action -eq 'Reinstall') {
            $ServiceResults = $(
               $InstallerToken = Get-AutomateInstallerToken
               $ObjectCapture | Where-Object {$_.OperatingSystemName -like '*windows*'} | ForEach-Object {
                  If ($PSCmdlet.ShouldProcess("Automate Services on $($_.ComputerID) - $($_.ComputerName)",$Action)) {
                     Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($_.ComputerID) - $($_.ComputerName) - Attempting to $Action Automate Services - job will be submitted to online systems"
                     $_ | Invoke-ControlCommand -Powershell -Command "(new-object Net.WebClient).DownloadString('$($LTPoShURI)') | iex; Install-LTService -Server '$($Script:CWAServer)' -LocationID $($_.Location.Id) -InstallerToken '$($InstallerToken)' -Force -SkipDotNet -WhatIf" -TimeOut 300000 -MaxLength 10240 -BatchSize $BatchSize -OfflineAction Skip -ResultPropertyName $RepairProperty -PassthroughObjects
                  }
               }
               $InstallerToken = Get-AutomateInstallerToken -InstallerType 5
               $ObjectCapture | Where-Object {$_.OperatingSystemName -like '*OS X*'} | ForEach-Object {
                  If ($PSCmdlet.ShouldProcess("Automate Services on $($_.ComputerID) - $($_.ComputerName)",$Action)) {
                     Write-Host -BackgroundColor DarkGray -ForegroundColor Yellow "$($_.ComputerID) - $($_.ComputerName) - Attempting to $Action Automate Services - job will be submitted to online systems"
                     $_ | Invoke-ControlCommand -Command @"
(LOCATIONID=$($_.Location.Id)
cd /tmp&&(
 (rm -f cwaagent.zip; rm -Rf CWAutomate)&>/dev/null
 curl '$($Script:CWAServer)/LabTech/Deployment.aspx?InstallerToken=$($InstallerToken)' -s -o cwaagent.zip
 [[ `$(find cwaagent.zip -type f -size +1500000c 2>/dev/null) ]]&&(
  echo SUCCESS-cwaagent.zip was downloaded
  unzip -n -d CWAutomate cwaagent.zip &>/dev/null
  [ -f CWAutomate/config.sh ]&&(
   [ -f /usr/local/ltechagent/uninstaller.sh ]&&(echo Existing installation found. Removing.; /usr/local/ltechagent/uninstaller.sh)
   cd /tmp/CWAutomate&&(
    mv -f config.sh config.sh.bak 2>/dev/null
    [ -f config.sh.bak ]&&sed "s/LOCATION_ID=[0-9]*/LOCATION_ID=`$LOCATIONID/" config.sh.bak > config.sh&&[ -f config.sh ]&&echo "SUCCESS-Installer Data Updated for location `$LOCATIONID" 
    cat ./config.sh
    . ./config.sh ; installer -pkg ./LTSvc.mpkg -verbose -target /; [ -d /usr/local/ltechagent ]&&echo SUCCESS-Installer completed
    launchctl list | grep -i "com.labtechsoftware"&&echo "LTService Started successfully"
   )  
  )||echo ERROR-Failed to extract
 )||echo ERROR-Failed to download cwaagent.zip
)||echo ERROR-Failed to change path to /tmp
)| sed -e 's/`$/\'`$'\r/g'
"@ -TimeOut 60000 -MaxLength 10240 -BatchSize $BatchSize -OfflineAction Skip -ResultPropertyName $RepairProperty -PassthroughObjects
                  }
               }
            )
            $ObjectCapture | Where-Object {!($_.OperatingSystemName -like '*windows*' -or $_.OperatingSystemName -like '*OS X*')}  | ForEach-Object {
               Write-Host -BackgroundColor Yellow -ForegroundColor Red "$($_.ComputerID) - $($_.ComputerName) - $Action action for Operating System ($($_.OperatingSystemName)) is not supported at present in this module"
            }
         } Else {
            Write-Host -BackgroundColor Yellow -ForegroundColor Red "Action $Action is not currently supported."
         }

         #Prepare a lookup for results
         $SResultLookup=@{}
         $ServiceResults | ForEach-Object {If (!($SResultLookup.ContainsKey("$($_.SessionID)"))) {$SResultLookup.Add("$($_.SessionID)",$_)}}
         Foreach ($singleObject in $ObjectCapture) {
            [string]$SessionID=$singleObject.SessionID
            If ($SResultLookup.ContainsKey($SessionID)) {
               $singleResult=$SResultLookup[$SessionID] | Select-Object -Expand $RepairProperty
               $AutofixSuccess = $false
               If ($Action -eq 'Check') {
                  If ($singleResult.$RepairProperty -like '*LastSuccessStatus*' -or $singleResult.$RepairProperty -like '*is_signed_in*') {$AutofixSuccess = $true}
               } ElseIf ($Action -eq 'Update') {
                  If ($singleResult.$RepairProperty -like '*successfully*') {$AutofixSuccess = $true}
               } ElseIf ($Action -eq 'Restart') {
                  If ($singleResult.$RepairProperty -like '*Restarted successfully*') {$AutofixSuccess = $true}
               } ElseIf ($Action -eq 'ReInstall') {
                  If ($singleResult.$RepairProperty -like '*successfully*') {$AutofixSuccess = $true}
               } Else {
                  $AutofixSuccess = $true
               }
            } Else {
               $singleResult=[pscustomobject]@{
                  $RepairProperty = "No result was returned for sessionID $($SessionID)"
               }
               $AutofixSuccess = $False
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
