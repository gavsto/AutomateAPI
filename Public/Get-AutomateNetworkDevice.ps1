function Get-AutomateNetworkDevice {
<#
.SYNOPSIS
    Get Network Device Information out of the Automate API
.DESCRIPTION
    Connects to the Automate API and returns one or more full network device objects
.PARAMETER DeviceID
    Can take either single Network Device integer, IE 1, or an array of Network Device integers, IE 1,5,9
.PARAMETER AllNetworkDevices
    Returns all computers in Automate, regardless of amount
.PARAMETER Condition
    A custom condition to build searches that can be used to search for specific things. Supported operators are '=', 'eq', '>', '>=', '<', '<=', 'and', 'or', '()', 'like', 'contains', 'in', 'not'.
    The 'not' operator is only used with 'in', 'like', or 'contains'. The '=' and 'eq' operator are the same. String values can be surrounded with either single or double quotes. IE (RemoteAgentLastContact <= 2019-12-18T00:50:19.575Z)
    Boolean values are specified as 'true' or 'false'. Parenthesis can be used to control the order of operations and group conditions.
.PARAMETER IncludeFields
    A comma separated list of fields that you want including in the returned computer object.
.PARAMETER ExcludeFields
    A comma separated list of fields that you want excluding in the returned computer object.
.PARAMETER OrderBy
    A comma separated list of fields that you want to order by finishing with either an asc or desc.  
.PARAMETER ClientName
    Client name to search for, uses wildcards so full client name is not needed
.PARAMETER LocationName
    Location name to search for, uses wildcards so full location name is not needed
.PARAMETER ClientID
    ClientID to search for, integer, -ClientID 1
.PARAMETER LocationID
    LocationID to search for, integer, -LocationID 2
.PARAMETER NetworkDeviceName
    Computer name to search for, uses wildcards so full computer name is not needed
.OUTPUTS
    Network Device Objects
.NOTES
    Version:        1.0
    Author:         Gavin Stone
    Creation Date:  2020-10-05
    Purpose/Change: Initial script development
.EXAMPLE
    Get-AutomateNetworkDevice -AllNetworkDevices
.EXAMPLE
    Get-AutomateNetworkDevice -ClientName "Rancor"
.EXAMPLE
    Get-AutomateNetworkDevice -Condition "(Type != 'Workstation')"
#>
    param (
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = "IndividualNetworkDevice")]
        [Alias('ID')]
        [int32[]]$NetworkDeviceID,

        [Parameter(Mandatory = $false, ParameterSetName = "AllResults")]
        [switch]$AllNetworkDevices,
        
        [Parameter(Mandatory = $false, ParameterSetName = "ByCondition")]
        [string]$Condition,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [Parameter(Mandatory = $false, ParameterSetName = "AllResults")]
        [Parameter(Mandatory = $false, ParameterSetName = "ByCondition")]
        [string]$IncludeFields,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [Parameter(Mandatory = $false, ParameterSetName = "AllResults")]
        [Parameter(Mandatory = $false, ParameterSetName = "ByCondition")]
        [string]$ExcludeFields,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [Parameter(Mandatory = $false, ParameterSetName = "AllResults")]
        [Parameter(Mandatory = $false, ParameterSetName = "ByCondition")]
        [string]$OrderBy,

        [Alias("Client")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$ClientName,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [int]$ClientId,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [int]$LocationId,

        [Alias("Location")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$LocationName

    )

    $ArrayOfConditions = @()

    if ($ComputerID) {
        Return Get-AutomateAPIGeneric -AllResults -Endpoint "networkdevices" -IDs $(($NetworkDeviceID) -join ",")
    }

    if ($AllComputers) {
        Return Get-AutomateAPIGeneric -AllResults -Endpoint "networkdevices" -IncludeFields $IncludeFields -ExcludeFields $ExcludeFields -OrderBy $OrderBy
    }

    if ($Condition) {
        Return Get-AutomateAPIGeneric -AllResults -Endpoint "networkdevices" -Condition $Condition -IncludeFields $IncludeFields -ExcludeFields $ExcludeFields -OrderBy $OrderBy
    }

    if ($ClientName) {
        $ArrayOfConditions += "(Client.Name like '%$ClientName%')"
    }
    
    if ($LocationName) {
        $ArrayOfConditions += "(Location.Name like '%$LocationName%')"
    }

    if ($ClientID) {
        $ArrayOfConditions += "(Client.Id = $ClientID)"
    }

    if ($LocationID) {
        $ArrayOfConditions += "(Location.Id = $LocationID)"
    }

    if ($ComputerName) {
        $ArrayOfConditions += "(ComputerName like '%$ComputerName%')"
    }

    $FinalCondition = Get-ConditionsStacked -ArrayOfConditions $ArrayOfConditions

    $FinalResult = Get-AutomateAPIGeneric -AllResults -Endpoint "networkdevices" -Condition $FinalCondition -IncludeFields $IncludeFields -ExcludeFields $ExcludeFields -OrderBy $OrderBy

    return $FinalResult
}