function Get-AutomateAPIGeneric {
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
      .PARAMETER Endpoint
        The individial URI to post to for results, IE computers
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
        A comma delimited list of IDs, when specified only these IDs will be returned
      .OUTPUTS
        The returned results from the API call
      .NOTES
        Version:        1.0
        Author:         Gavin Stone
        Creation Date:  2019-01-20
        Purpose/Change: Initial script development

        Update Date:    2020-07-03
        Purpose/Change: Update to use Invoke-AutomateAPIMaster

      .EXAMPLE
        Get-AutomateAPIGeneric -Page 1 -Condition "RemoteAgentLastContact <= 2019-12-18T00:50:19.575Z" -Endpoint "computers"
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, ParameterSetName = "Page")]
        [ValidateRange(1,1000)]
        [int]
        $PageSize = 1000,

        [Parameter(Mandatory = $false, ParameterSetName = "Page")]
        [ValidateRange(1,65535)]
        [int]
        $Page = 1,

        [Parameter(Mandatory = $false, ParameterSetName = "AllResults")]
        [switch]
        $AllResults,
        [Parameter(Mandatory = $false, ParameterSetName = "AllResults")]
        $ResultSetSize,

        [Parameter(Mandatory = $true)]
        [string]
        $Endpoint,

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
        $IDs,

        [Parameter(Mandatory = $false)]
        [string]
        $Expand
    )
    
    begin {
        #Build the URL to hit
        $URI = ($Script:CWAServer + '/cwa/api/v1/' + $EndPoint)

        #Build the Body Up
        $Body = @{}

        #Put the page size in
        $Body.Add("pagesize", $PageSize)
        $Body.Add("page", $Page)

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

        #Expands in the returned object
        if ($Expand) {
          $Body.Add("expand", "$Expand")
        }

        $ReturnedResults = @()
        [System.Collections.ArrayList]$ReturnedResults
    }
    
    process {
        $Arguments = @{
            'URI'=$URI
            'ContentType'="application/json"
            'Body'=$Body
        }
        If ($AllResults) {$Arguments.Body.page=1}
        Do {
            Try {
                Write-Debug "Calling Invoke-AutomateAPIMaster with Arguments ($Arguments|ConvertTo-JSON -Depth 100 -Compress)"
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

            $Arguments.Body.page+=1
        }
        While ($Result.Count -gt 0 -and $AllResults -and !($ResultSetSize -gt 0 -and $ReturnedResults.Count -ge $ResultSetSize))
        If ($ResultSetSize -and $ResultSetSize -gt 0) {
          $ReturnedResults = $ReturnedResults | Select-Object -First $ResultSetSize
        }
    }
    
    End {
        return $ReturnedResults
    }
}
