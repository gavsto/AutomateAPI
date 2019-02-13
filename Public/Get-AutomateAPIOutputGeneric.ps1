function Get-AutomateAPIOutputGeneric {
    <#
      .SYNOPSIS
        Internal function used to make generic API calls
      .DESCRIPTION
        Internal function used to make generic API calls
      .PARAMETER PageSize
        The page size of the results that come back from the API - limit this when needed
      .PARAMETER Page
        Brings back a particular page as defined
      .PARAMETER AllResults
        Will bring back all results for a particular query with no concern for result set size
      .PARAMETER APIURI
        The individial URI to post to for results, IE /v1/computers?
      .PARAMETER OrderBy
        Order by - Used to sort the results by a field. Can be sorted in ascending or descending order.
        Example - fieldname asc
        Example - fieldname desc
      .PARAMETER Condition
        Condition - the searches that can be used to search for specific things. Supported operators are '=', 'eq', '>', '>=', '<', '<=', 'and', 'or', '()', 'like', 'contains', 'in', 'not'.
        The 'not' operator is only used with 'in', 'like', or 'contains'. The '=' and 'eq' operator are the same. String values can be surrounded with either single or double quotes.
        Boolean values are specified as 'true' or 'false'. Parenthesis can be used to control the order of operations and group conditions.
        The 'like' operator translates to the MySQL 'like' operator.
      .PARAMETER IncludeFields
        A comma delimited list of fields, when specified only these fields will be included in the result set
      .PARAMETER ExcludeFields
        A comma delimited list of fields, when specified these fields will be excluded from the final result set
      .PARAMETER IDs
        A comma delimited list of fields, when specified only these IDs will be returned
      .OUTPUTS
        The returned results from the API call
      .NOTES
        Version:        1.0
        Author:         Gavin Stone
        Creation Date:  20/01/2019
        Purpose/Change: Initial script development
      .EXAMPLE
        Get-AutomateAPIOutputGeneric -Page 1 -Condition "RemoteAgentLastContact <= 2019-12-18T00:50:19.575Z" -APIURI "/v1/computers?"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = "Page")]
        [int]
        $PageSize = 1000,

        [Parameter(Mandatory = $true, ParameterSetName = "Page")]
        [int]
        $Page,

        [Parameter(Mandatory = $false, ParameterSetName = "AllResults")]
        [switch]
        $AllResults,

        [Parameter(Mandatory = $true)]
        [string]
        $APIURI,

        [Parameter(Mandatory = $false)]
        [string]
        $OrderBy,

        [Parameter(Mandatory = $false)]
        [string]
        $Condition,

        [Parameter(Mandatory = $false)]
        [string]
        $IncludeFields,

        [Parameter(Mandatory = $false)]
        [string]
        $ExcludeFields,

        [Parameter(Mandatory = $false)]
        [string]
        $IDs
    )
    
    begin {
        #Build the URL to hit
        $url = ($Global:CWAUri + "$APIURI")

        #Build the Body Up
        $Body = @{}

        #Put the page size in
        $Body.Add("pagesize", "$PageSize")

        if ($page) {
            
        }

        #Put the condition in
        if ($Condition) {
            $Body.Add("condition", "$condition")
        }

        #Put the orderby in
        if ($OrderBy) {
            $Body.Add("orderby", "$orderby")
        }

        #Include only these fields
        if ($IncludeFields) {
            $Body.Add("includefields", "$IncludeFields")
        }

        #Exclude only these fields
        if ($ExcludeFields) {
            $Body.Add("excludefields", "$ExcludeFields")
        }

        #Include only these IDs
        if ($IDs) {
            $Body.Add("ids", "$IDs")
        }
    }
    
    process {
      $RancorNull = Connect-AutomateAPI -Quiet
        if ($AllResults) {
            $ReturnedResults = @()
            [System.Collections.ArrayList]$ReturnedResults
            $i = 0
            DO {
                [int]$i += 1
                $URLNew = "$($url)page=$($i)"
                try {
                    $return = Invoke-RestMethod -Uri $URLNew -Headers $global:CWACredentials -ContentType "application/json" -Body $Body
                }
                catch {
                    Write-Error "Failed to perform Invoke-RestMethod to Automate API with error $_.Exception.Message"
                }

                $ReturnedResults += ($return)
            }
            WHILE ($return.count -gt 0)
        }

        if ($Page) {
            $ReturnedResults = @()
            [System.Collections.ArrayList]$ReturnedResults
            $URLNew = "$($url)page=$($Page)"
            try {
                $return = Invoke-RestMethod -Uri $URLNew -Headers $global:CWACredentials -ContentType "application/json" -Body $Body
            }
            catch {
                Write-Error "Failed to perform Invoke-RestMethod to Automate API with error $_.Exception.Message"
            }

            $ReturnedResults += ($return)
        }

    }
    
    end {
        return $ReturnedResults
    }
}
