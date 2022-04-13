function Invoke-AutomateCommand {
    <#
    .SYNOPSIS
        Will issue a command against a given machine and return the results.
    .DESCRIPTION
        Will issue a command against a given machine and return the results.
    .PARAMETER ComputerID
        The ComputerID for the machine you wish to connect to.
        ComputerIDs can be provided via the pipeline.
        IE - Get-AutomateComputer -ComputerID 5 | Invoke-AutomateCommand -Powershell -Command "Get-Service"
    .PARAMETER Command
        The command you wish to issue to the machine.
    .PARAMETER TimeOut
        The amount of time in seconds to wait for the command results. The default is 30 seconds.
    .PARAMETER BatchSize
        Number of computers to invoke commands in parallel at a time.
    .PARAMETER ResultPropertyName
        String containing the name of the member you would like to add to the input pipeline object that will hold the result of this command
    .OUTPUTS
        The output of the Command provided.
    .NOTES
        Version:        1.0
        Author:         Darren White
        Creation Date:  2020-07-09
        Purpose/Change: Initial script development

    .EXAMPLE
        Get-AutomateComputer -ComputerID 5 | Invoke-AutomateCommand -Powershell -Command "Get-Service"
            Will execute PowerShell command "Get-Service" on the computer.
    .EXAMPLE
        Invoke-AutomateCommand -ComputerID @(3,4,5,6,7,8) -Command 'hostname' -OfflineAction Skip
            Will return the hostnames of the online machines.
    .EXAMPLE
        $Results = Get-AutomateComputer -ClientName "Contoso" | Invoke-AutomateCommand -ResultPropertyName "OfficePlatform" -PowerShell -Command { Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -Name Platform } -PassthroughObjects
        $Results | select ComputerName, OfficePlatform
    .EXAMPLE
        Invoke-AutomateCommand -ComputerID $ComputerID -CommandID 123 -Timeout 600000
            Tells the remote agent to resend system inventory.

    #>
    [CmdletBinding(SupportsShouldProcess=$True,DefaultParameterSetName = 'ExecuteCommand')]
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [int[]]$ComputerID,
        [Parameter(ParameterSetName = 'ExecuteCommand', Mandatory = $True)]
        [Parameter(ParameterSetName = 'PassthroughObjects')]
        [string]$Command,
        [Parameter(ParameterSetName = 'ExecuteCommand')]
        [Parameter(ParameterSetName = 'PassthroughObjects')]
        [string]$WorkingDirectory="%WINDIR%\Temp",
        [Parameter(ParameterSetName = 'ExecuteCommand')]
        [Parameter(ParameterSetName = 'PassthroughObjects')]
        [switch]$PowerShell,
        [Parameter(ParameterSetName = 'CommandID', Mandatory = $True)]
        [int]$CommandID=2,
        [Parameter(ParameterSetName = 'CommandID')]
        $CommandParameters='',
        [int]$TimeOut = 30000,
        [Parameter(ParameterSetName = 'ExecuteCommand')]
        [Parameter(ParameterSetName = 'PassthroughObjects')]
        [ValidateSet('Wait', 'Queue', 'Skip')] 
        $OfflineAction = 'Wait',
        [ValidateRange(1, 100)]
        [int]$BatchSize = 20,
        [switch]$PassthroughObjects,
        [string]$ResultPropertyName = 'Output'        
    )

    Begin {
        $ProgressPreference='SilentlyContinue'

        $URI = "cwa/api/v1/Computers"

        Write-Debug "Selected parameterset $($PSCmdlet.ParameterSetName)"
        If ($PSCmdlet.ParameterSetName -eq 'CommandID') {
            $CommandBody=$CommandParameters
        } Else {
            If ($PowerShell) {
                $Command=$Command -Replace '"','\"'
                $FormattedCommand="powershell.exe!!! -NonInteractive -Command ""`$WorkingDirectory=[System.Environment]::ExpandEnvironmentVariables('$WorkingDirectory'); Set-Location -Path `$WorkingDirectory -ErrorAction Stop; $Command"""
            } Else {
                $FormattedCommand="cmd.exe!!! /c ""CD /D ""$WorkingDirectory"" && $Command"""
            }
            $CommandBody = $FormattedCommand
        }
        $ResultObjects = @{}
        $ComputerCollection = {}.Invoke()
        Write-Debug "CommandID $($CommandID) will be used to submit the following command`n$($CommandBody)"
    }

    Process {
        If ($PassthroughObjects) {
            $ObjectsIn=$_
            Foreach ($xObject in $ObjectsIn) {
                If ($xObject -and $xObject.ComputerID) {
                    [string]$Computer=$xObject.ComputerID
                    If (!($ResultObjects.ContainsKey($Computer))) {
                        $ResultObjects.Add($Computer, [pscustomobject]@{ComputerID = $Computer })
                    } Else {Write-Warning "ComputerID $Computer has already been added. Skipping"}
                    $Null = $ComputerCollection.Add($xObject)
                } Else {Write-Warning "Input Object is missing ComputerID property"}
            }
        } Else {
            Foreach ($Computer in $ComputerId) {
                If ($Computer.ComputerID) {$Computer=$Computer.ComputerID}
                [string]$Computer="$($Computer)"
                [pscustomobject]@{ComputerID = $Computer} | ForEach-Object {
                    If (!($ResultObjects.ContainsKey($Computer))) {
                        $ResultObjects.Add($Computer, $_)
                    } Else {Write-Warning "ComputerID $Computer has already been added. Skipping"}
                    $Null = $ComputerCollection.Add($_)
                }
            }
        }
    }

    End {
        Function New-ReturnObject {
            param([object]$InputObject, [object]$Result, [bool]$IsSuccess, [string]$PropertyName)
            $InputObject | Add-Member -NotePropertyName $PropertyName -NotePropertyValue $Result -Force
            $InputObject | Add-Member -NotePropertyName 'IsSuccess' -NotePropertyValue $IsSuccess -Force
            $InputObject
        }
        
        $ProcessComputers=@($ResultObjects.Keys)
        $RemainingComputers={}.Invoke()
        $AddComputers={}.Invoke()
        $ComputerIndex=0
        Do {

            While (($AddComputers.Count+$RemainingComputers.Count) -lt $BatchSize -and $ComputerIndex -lt $ProcessComputers.Count) {
                $AddComputers.Add($ProcessComputers[$ComputerIndex])
                $ComputerIndex++
            }

            If ($AddComputers.Count -gt 0) {
                If ( $PSCmdlet.ShouldProcess($AddComputers, "Submit Command to Agents") ) {
                    Foreach ($tmpComputerID IN $AddComputers) {
                        # Issue command
                        $ExecuteCommand=@{
                            'ComputerId' = $tmpComputerID
                            'Command'=@{'Id'="$($CommandID)"}
                            'Parameters'=@($CommandBody)
                        }

                        $Arguments = @{
                            'URI'="/${URI}/${tmpComputerID}/CommandExecute"
                            'ContentType'="application/json"
                            'Body'=$ExecuteCommand|ConvertTo-Json -Depth 100 -Compress
                            'Method'='POST'
                        }

                        Write-Debug "Calling Invoke-AutomateAPIMaster with Arguments $(ConvertTo-JSON -InputObject $Arguments -Depth 100 -Compress)"
                        Try {
                            $Result = Invoke-AutomateAPIMaster -Arguments $Arguments
                            If ($Result.content){
                                $Result = $Result.content | ConvertFrom-Json
                            }

                            If ($Result -and $Result.ID) {
                                $ResultObjects[$tmpComputerID] = New-ReturnObject -InputObject $ResultObjects[$tmpComputerID] -Result "$($Result.Id)" -PropertyName 'CmdID' -IsSuccess $false
                                $EventDate = Get-Date
                                $TimeOutDateTime = $EventDate.AddMilliseconds($TimeOut+3000)
                                $ResultObjects[$tmpComputerID] = New-ReturnObject -InputObject $ResultObjects[$tmpComputerID] -Result $TimeOutDateTime -PropertyName '__CommandTimeout' -IsSuccess $false
                                $Null = $RemainingComputers.Add($tmpComputerID)
                            }
                        }
                        Catch {
                            Write-Error "$(($_.ErrorDetails | ConvertFrom-Json).message)"
                            return
                        }
                    }
                }
                $AddComputers.Clear()
            }

            If ($RemainingComputers.Count -gt 0) {

                Start-Sleep -Seconds 5

                $WaitingComputers=@($RemainingComputers.GetEnumerator())
                Foreach ($tmpComputerID IN $WaitingComputers) {
                    If ( $PSCmdlet.ShouldProcess($ResultObjects[$tmpComputerID].CmdID, "Checking Command Result") ) {
                        Try {
                            $RequestParameters = @{
                                'endpoint'="Computers/${tmpComputerID}/CommandExecute"
                                'IDs'=$ResultObjects[$tmpComputerID].CmdID
                            }
                            $CommandExpired=($ResultObjects[$tmpComputerID].__CommandTimeout -le (Get-Date))

                            Write-Debug "Submitting: $(ConvertTo-JSON -InputObject $RequestParameters -Depth 10 -compress)"
                            $cmdResult = Get-AutomateAPIGeneric @RequestParameters
                            Write-Debug "Response: $(ConvertTo-JSON -InputObject $cmdResult -Depth 10 -compress)"

                            If ($cmdResult -and @('Failed','Success') -contains $cmdResult.Status) {
                                $Output = $cmdResult.Output.Trim()
                                $ResultObjects[$tmpComputerID] = New-ReturnObject -InputObject $ResultObjects[$tmpComputerID] -Result $Output -PropertyName $ResultPropertyName -IsSuccess $($cmdResult.Status -eq 'Success')
                                $Null = $RemainingComputers.Remove($tmpComputerID)
                            } ElseIf ($CommandExpired) {
                                $ResultObjects[$tmpComputerID] = New-ReturnObject -InputObject $ResultObjects[$tmpComputerID] -Result "Command timed out" -PropertyName $ResultPropertyName -IsSuccess $False
                                $Null = $RemainingComputers.Remove($tmpComputerID)
                            }
                        }
                        Catch {
                            Write-Error "$(($_.ErrorDetails | ConvertFrom-Json).message)"
                        }
                    }
                }
            }
        } Until ($ComputerIndex -eq $ProcessComputers.Count -and $RemainingComputers.Count -eq 0)

        If ($ComputerCollection.Count -eq 1 -and !($PassthroughObjects)) {
            $ResultObjects.Values | Select-Object -ExpandProperty "$ResultPropertyName" -ErrorAction SilentlyContinue
        } ElseIf (!($PassthroughObjects)) {
            $ComputerCollection | Select-Object -Property @{n=$ResultPropertyName;e={If ($_.ComputerID) {[string]$ComputerID=$_.ComputerID} Else {[string]$ComputerID=$_}; Write-Debug "Inserting results for ComputerID $($ComputerID)"; If ($ResultObjects.ContainsKey($ComputerID)) {$ResultObjects[$ComputerID]|Select-Object -Property * -ExcludeProperty __CommandTimeout} Else {"Results for ComputerID $($ComputerID) were not found"} }} | Select-Object -ExpandProperty "$ResultPropertyName"
        } Else {
            $ComputerCollection | Select-Object -ExcludeProperty $ResultPropertyName -Property *,@{n=$ResultPropertyName;e={If ($_.ComputerID) {[string]$ComputerID=$_.ComputerID} Else {[string]$ComputerID=$_}; Write-Debug "Inserting results for ComputerID $($ComputerID)"; If ($ResultObjects.ContainsKey($ComputerID)) {$ResultObjects[$ComputerID]|Select-Object -Property * -ExcludeProperty ComputerID,__CommandTimeout} Else {"Results for ComputerID $($ComputerID) were not found"} }}
        }

    }
}
