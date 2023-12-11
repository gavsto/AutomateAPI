function Get-AutomateGroup {
    <#
    .SYNOPSIS
        Get Group information out of the Automate API
    .DESCRIPTION
        Connects to the Automate API and returns one or more full Group objects
    .PARAMETER AllGroups
        Returns all Groups in Automate, regardless of amount
    .PARAMETER Condition
        A custom condition to build searches that can be used to search for specific things. Supported operators are '=', 'eq', '>', '>=', '<', '<=', 'and', 'or', '()', 'like', 'contains', 'in', 'not'.
        The 'not' operator is only used with 'in', 'like', or 'contains'. The '=' and 'eq' operator are the same. String values can be surrounded with either single or double quotes. IE (RemoteAgentLastContact <= 2019-12-18T00:50:19.575Z)
        Boolean values are specified as 'true' or 'false'. Parenthesis can be used to control the order of operations and group conditions.
    .PARAMETER OrderBy
        A comma separated list of fields that you want to order by finishing with either an asc or desc.
    .PARAMETER GroupName
        Group name to search for, uses wildcards so full Group name is not needed
    .PARAMETER GroupID
        GroupID to search for, integer, -GroupID 1
    .OUTPUTS
        Client objects
    .NOTES
        Version:        1.0
        Author:         Marcus Tedde
        Creation Date:  2023-12-11
        Purpose/Change: Initial script development
    .EXAMPLE
        Get-AutomateGroup -AllGroups
    .EXAMPLE
        Get-AutomateGroup -GroupId 4
    .EXAMPLE
        Get-AutomateGroup -GroupName "Rancor"
    .EXAMPLE
        Get-AutomateGroup -Condition "(TypeName = 'Patching')"
    #>
        param (
            [Parameter(Mandatory = $false, Position = 0, ParameterSetName = "IndividualGroup")]
            [Alias('ID')]
            [int32[]]$GroupId,

            [Parameter(Mandatory = $false, ParameterSetName = "AllResults")]
            [switch]$AllGroups,

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

            [Alias("Group")]
            [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
            [string]$GroupName
        )

        $ArrayOfConditions = @()

        
        if ($ClientID) {
            Return Get-AutomateAPIGeneric -AllResults -Endpoint "Groups" -IDs $(($GroupID) -join ",")
        }

        if ($AllClients) {
            Return Get-AutomateAPIGeneric -AllResults -Endpoint "Groups" -IncludeFields $IncludeFields -ExcludeFields $ExcludeFields -OrderBy $OrderBy
        }

        if ($Condition) {
            Return Get-AutomateAPIGeneric -AllResults -Endpoint "Groups" -Condition $Condition -IncludeFields $IncludeFields -ExcludeFields $ExcludeFields -OrderBy $OrderBy
        }

        if ($ClientName) {
            $ArrayOfConditions += "(Name like '%$GroupName%')"
        }

        $ClientFinalCondition = Get-ConditionsStacked -ArrayOfConditions $ArrayOfConditions

        $Clients = Get-AutomateAPIGeneric -AllResults -Endpoint "Groups" -Condition $ClientFinalCondition -IncludeFields $IncludeFields -ExcludeFields $ExcludeFields -OrderBy $OrderBy

        $FinalResult = @()
        foreach ($Client in $Clients) {
            $ArrayOfConditions = @()
            $ArrayOfConditions += "(Client.Id = '$($Client.Id)')"
            $LocationFinalCondition = Get-ConditionsStacked -ArrayOfConditions $ArrayOfConditions
            $Locations = Get-AutomateAPIGeneric -AllResults -Endpoint "locations" -Condition $LocationFinalCondition -IncludeFields $IncludeFields -ExcludeFields $ExcludeFields -OrderBy $OrderBy
            $FinalClient = $Client
            Add-Member -inputobject $FinalClient -NotePropertyName 'Locations' -NotePropertyValue $locations
            $FinalResult += $FinalClient
        }

        return $FinalResult
    }
