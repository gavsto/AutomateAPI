function Get-AutomateInstallerToken{
    <#
    .SYNOPSIS
        Gets an Automate Installer Token
    .DESCRIPTION
        The token lasts for 24 hours
    .NOTES
        Version:        1.0
        Author:         Gavin Stone
        Creation Date:  2020-07-03
        Purpose/Change: Initial script development
    .EXAMPLE
        Get-AutomateInstallerToken
    #>
        param (
            [int]$LocationID = 1,
            [int]$InstallerType = 1
        )

        $ReturnedResults = @()
        [System.Collections.ArrayList]$ReturnedResults
        $Endpoint="RemoteAgent/Installers"
        $URI = ($Script:CWAServer + '/cwa/api/v1/' + $EndPoint)
        $Body=@{"LocationId"=$LocationID;"InstallerType"=$InstallerType} | ConvertTo-Json -Compress

        $Arguments = @{
            'URI'=$URI
            'ContentType'="application/json"
            'Method'='POST'
            'Body'=$Body
        }
        Try {
            Write-Debug "Calling Invoke-AutomateAPIMaster with Arguments $($Arguments|ConvertTo-JSON -Depth 100 -Compress)"
            $Result = Invoke-AutomateAPIMaster -Arguments $Arguments
            If ($Result.content){
                $Result = $Result.content | ConvertFrom-Json
            }
            $ReturnedResults += ($Result)
        }
        Catch {
            Write-Error "Failed to perform Invoke-AutomateAPIMaster"
            $Result=$Null
        }

    
        return $ReturnedResults
    }