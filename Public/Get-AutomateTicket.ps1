function Get-AutomateTicket {
<#
.SYNOPSIS
    Get Ticket information out of the Automate API
.DESCRIPTION
    Connects to the Automate API and returns one or more full ticket objects
.PARAMETER AllTickets
    Returns all tickets in Automate, regardless of amount
.PARAMETER Condition
    A custom condition to build searches that can be used to search for specific things. Supported operators are '=', 'eq', '>', '>=', '<', '<=', 'and', 'or', '()', 'like', 'contains', 'in', 'not'.
    The 'not' operator is only used with 'in', 'like', or 'contains'. The '=' and 'eq' operator are the same. String values can be surrounded with either single or double quotes. IE (RemoteAgentLastContact <= 2019-12-18T00:50:19.575Z)
    Boolean values are specified as 'true' or 'false'. Parenthesis can be used to control the order of operations and group conditions.
.PARAMETER IncludeFields
    A comma separated list of fields that you want including in the returned ticket object.
.PARAMETER ExcludeFields
    A comma separated list of fields that you want excluding in the returned ticket object.
.PARAMETER OrderBy
    A comma separated list of fields that you want to order by finishing with either an asc or desc.  
.NOTES
    Version:        1.0
    Author:         Gavin Stone
    Creation Date:  2019-02-25
    Purpose/Change: Initial script development
.EXAMPLE
    Get-AutomateTicket -AllTickets
#>
    param (

        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = "IndividualTicket")]
        [Alias('ID')]
        [int32[]]$TicketID,

        [Parameter(Mandatory = $false, ParameterSetName = "IndividualComputerTicket")]
        [int32[]]$ComputerID,

        [Parameter(Mandatory = $false, ParameterSetName = "AllResults")]
        [switch]$AllTickets,
        
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

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [int]$StatusID,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [Alias('Status')]
        [string]$StatusName,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$Subject,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [int]$PriorityID,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [Alias('Priority')]
        [string]$PriorityName,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$From,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$CC,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [int]$SupportLevel,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [int]$ExternalID,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [Alias('ManageUnsycned')]
        [switch]$UnsyncedTickets


    )

    $ArrayOfConditions = @()

    if ($TicketID) {
        Return Get-AutomateAPIGeneric -AllResults -Endpoint "tickets" -IDs $(($TicketID) -join ",")
    }

    if ($ComputerID) {
        Return $(Get-AutomateAPIGeneric -AllResults -Endpoint "computers" -Expand "tickets" -IDs $(($ComputerID) -join ",") | Select-Object Id, ComputerName, Tickets)
    }

    if ($AllComputers) {
        Return Get-AutomateAPIGeneric -AllResults -Endpoint "tickets" -IncludeFields $IncludeFields -ExcludeFields $ExcludeFields -OrderBy $OrderBy
    }

    if ($Condition) {
        Return Get-AutomateAPIGeneric -AllResults -Endpoint "tickets" -Condition $Condition -IncludeFields $IncludeFields -ExcludeFields $ExcludeFields -OrderBy $OrderBy
    }

    if ($StatusID) {
        $ArrayOfConditions += "(Status.Id = $StatusID)"
    }

    if ($StatusName) {
        $ArrayOfConditions += "(Status.Name like '%$StatusName%')"
    }

    if ($Subject) {
        $ArrayOfConditions += "(Subject like '%$Subject%')"
    }

    if ($PriorityID) {
        $ArrayOfConditions += "(Priority.Id = $PriorityID)"
    }

    if ($PriorityName) {
        $ArrayOfConditions += "(Priority.Name like '%$PriorityName%')"
    }

    if ($From) {
        $ArrayOfConditions += "(From like '%$From%')"
    }

    if ($CC) {
        $ArrayOfConditions += "(CC like '%$CC%')"
    }

    if ($SupportLevel) {
        $ArrayOfConditions += "(SupportLevel = $SupportLevel)"
    }

    if ($ExternalID) {
        $ArrayOfConditions += "(ExternalID = $ExternalID)"
    }

    if ($UnsyncedTickets) {
        $ArrayOfConditions += "(ExternalID = 0)"
    }

    
    $FinalCondition = Get-ConditionsStacked -ArrayOfConditions $ArrayOfConditions

    $FinalResult = Get-AutomateAPIGeneric -AllResults -Endpoint "tickets" -Condition $FinalCondition -IncludeFields $IncludeFields -ExcludeFields $ExcludeFields -OrderBy $OrderBy

    return $FinalResult
}