function Invoke-AutomateSendTo {
    <#
    .SYNOPSIS
        Sends entities to a site or group
    .DESCRIPTION
        This uses the Automate API batch command endpoint SendTo
    .NOTES
        Version:        1.0
        Author:         Gavin Stone
        Creation Date:  2020-07-03
        Purpose/Change: Initial script development
    .EXAMPLE
        Invoke-AutomateSendTo
    #>
        param (
            [System.Collections.ArrayList]$EntityIds,
            [int]$EntityType = 1,   # Default to computers type
            [int]$TargetId,
            [int]$TargetType = 7    # Default to group target
        )

        $ReturnedResults = @()
        [System.Collections.ArrayList]$ReturnedResults
        $Endpoint="Batch/Commands/SendTo"
        $URI = ($Script:CWAServer + '/cwa/api/v1/' + $EndPoint + "?pageSize=-1&page=-1&condition=")

        $Body = @{
            EntityIds = $EntityIds
            EntityType = $EntityType              
            TargetId = $TargetId
            TargetType = $TargetType
        } | ConvertTo-Json -Compress

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