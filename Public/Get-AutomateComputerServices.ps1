function Get-AutomateComputerServices {
    <#
    .SYNOPSIS
        Get Computer's Services information out of the Automate API
    .DESCRIPTION
        Connects to the Automate API and returns all services for specified computer object.
    .PARAMETER ComputerID
        Can take either single ComputerID integer, IE 1, or an array of ComputerID integers, IE 1,5,9. Limits results to include only specified IDs.
    .OUTPUTS
        Computer Services Objects
    .NOTES
        Version:        1.0
        Author:         Marcus Tedde
        Creation Date:  2023-12-12
        Purpose/Change: Initial script development    
    .EXAMPLE
        Get-AutomateComputerServices -ComputerID 1
    #>
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [Alias('ID')]
        [int32[]]$ComputerID    
    )
    
    $RequestParameters = @{
        'AllResults' = $True
        'Endpoint'   = "computers/$ComputerID/services"
    }
    
    Get-AutomateAPIGeneric @RequestParameters
    
    #    $FinalResult = Get-AutomateAPIGeneric -AllResults -Endpoint "computers" -Condition $FinalCondition -IncludeFields $IncludeFields -ExcludeFields $ExcludeFields -OrderBy $OrderBy
    #    return $FinalResult
}
