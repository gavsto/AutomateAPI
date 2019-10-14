function Set-AutomateAPIGeneric {
    <#
      .SYNOPSIS
        Internal function used to make generic API calls
      .DESCRIPTION
        Internal function used to make generic API calls
      .PARAMETER Body
        A hashtable of POST parameters to pass
      .PARAMETER PageSize
        The page size of the results that come back from the API - limit this when needed
      .PARAMETER Page
        Brings back a particular page as defined
      .PARAMETER AllResults
        Will bring back all results for a particular query with no concern for result set size
      .PARAMETER Endpoint
        The individial URI to post to for results, IE computers?
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
        Author:         Jason Rush
        Creation Date:  14/10/2019
        Purpose/Change: Initial function development
      .EXAMPLE
        Set-AutomateAPIGeneric -Page 1 -Endpoint "computers/1234/CommandPrompt?" -Body @{ RunAsAdmin = $true; UsePowerShell = $true; CommandText = "gci"; Directory = "C:\Users\" }
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]
        $Body,

        [Parameter(Mandatory = $false, ParameterSetName = "Page")]
        [ValidateRange(1,1000)]
        [int]
        $PageSize = 1000,

        [Parameter(Mandatory = $true, ParameterSetName = "Page")]
        [ValidateRange(1,65535)]
        [int]
        $Page,

        [Parameter(Mandatory = $false, ParameterSetName = "AllResults")]
        [switch]
        $AllResults,

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
        $url = ($Script:CWAServer + '/cwa/api/v1/' + $EndPoint)

        #Convert the Body parameters to expected format
        $BodyString = ($Body | ConvertTo-Json -Compress)

        #Build the Query Up
        $QueryString = ""

        #Put the page size in
        $QueryString += "&pagesize=$PageSize"

        if ($page) {
            
        }

        #Put the condition in
        if ($Condition) {
            $QueryString += "&condition=$condition"
        }

        #Put the orderby in
        if ($OrderBy) {
            $QueryString += "&orderby=$orderby"
        }

        #Include only these fields
        if ($IncludeFields) {
            $QueryString += "&includefields=$IncludeFields"
        }

        #Exclude only these fields
        if ($ExcludeFields) {
            $QueryString += "&excludefields=$ExcludeFields"
        }

        #Include only these IDs
        if ($IDs) {
            $QueryString += "&ids=$IDs"
        }

        #Expands in the returned object
        if ($Expand) {
          $QueryString += "&expand=$Expand"
        }
        
    }
    
    process {
        if ($AllResults) {
            $ReturnedResults = @()
            [System.Collections.ArrayList]$ReturnedResults
            $i = 0
            DO {
                [int]$i += 1
                $URLNew = "$($url)?page=$($i)&$QueryString"
                try {
                    $return = Invoke-RestMethod -Uri $URLNew -Headers $script:CWAToken -ContentType "application/json" -Body $BodyString
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
            $URLNew = "$($url)?page=$($Page)"
            try {
                $return = Invoke-RestMethod -Method Post -Uri $URLNew -Headers $script:CWAToken -ContentType "application/json" -Body $BodyString
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
