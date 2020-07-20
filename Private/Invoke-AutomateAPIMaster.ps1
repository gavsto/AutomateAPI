function Invoke-AutomateAPIMaster {
    <#
      .SYNOPSIS
        Internal function used to make API calls
      .DESCRIPTION
        Internal function used to make API calls
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
        Author:         Darren White
        Creation Date:  2020-07-03
        Purpose/Change: Initial script development
      .EXAMPLE
        Get-AutomateAPIGeneric -Page 1 -Condition "RemoteAgentLastContact <= 2019-12-18T00:50:19.575Z" -Endpoint "computers?"
    #>
    [CmdletBinding()]
    param(
        $Arguments,
        [int]$MaxRetry = 5
    )
    
    begin {
    }
    
    process {
        # Check that we have cached connection info
        if(!$script:CWAToken){
            $ErrorMessage = @()
            $ErrorMessage += "Not connected to an Automate server."
            $ErrorMessage +=  $_.ScriptStackTrace
            $ErrorMessage += ''    
            $ErrorMessage += '--> $CWAToken variable not found.'
            $ErrorMessage += "----> Run 'Connect-AutomateAPI' to initialize the connection before issuing other AutomateAPI commandlets."
            Write-Error ($ErrorMessage | Out-String)
            return
        }
        
        # Add default set of arguments
        If (!$Arguments.Headers) {$Arguments.Headers=@{}}
        foreach($Key in $script:CWAToken.Keys){
            if($Arguments.Headers.Keys -notcontains $Key){
                $Arguments.Headers += @{$Key = $script:CWAToken.$Key}
            }
        }
    #    if(!$Arguments.SessionVariable){ $Arguments.WebSession = $global:CWMServerConnection.Session }

        # Check URI format
        if($Arguments.URI -notlike '*`?*' -and $Arguments.URI -like '*`&*') {
            $Arguments.URI = $Arguments.URI -replace '(.*?)&(.*)', '$1?$2'
        }        

        # Issue request
        try {
            Write-Debug "Calling $($Arguments|Out-String)"
            $ProgressPreference = 'SilentlyContinue'
            $Result = Invoke-WebRequest @Arguments -UseBasicParsing
        } 
        catch {
            if($_.Exception.Response){
                # Read exception response
                $ErrorStream = $_.Exception.Response.GetResponseStream()
                $Reader = New-Object System.IO.StreamReader($ErrorStream)
                $global:ErrBody = $Reader.ReadToEnd() | ConvertFrom-Json

                # Start error message
                $ErrorMessage = @()

                if($errBody.code){
                    $ErrorMessage += "An exception has been thrown."
                    $ErrorMessage +=  $_.ScriptStackTrace
                    $ErrorMessage += ''    
                    $ErrorMessage += "--> $($ErrBody.code)"
                    if($errBody.code -eq 'Unauthorized'){
                        $ErrorMessage += "-----> $($ErrBody.message)"
                        $ErrorMessage += "-----> Use 'Connect-AutomateAPI' to set new authentication."
                    } 
                    else {
                        $ErrorMessage += "-----> $($ErrBody.message)"
                        $ErrorMessage += "-----> ^ Error has not been documented please report. ^"
                    }
                }
            }

            if ($_.ErrorDetails) {
                $ErrorMessage += "An error has been thrown."
                $ErrorMessage +=  $_.ScriptStackTrace
                $ErrorMessage += ''
                $global:errDetails = $_.ErrorDetails | ConvertFrom-Json
                $ErrorMessage += "--> $($errDetails.code)"
                $ErrorMessage += "--> $($errDetails.message)"
                if($errDetails.errors.message){
                    $ErrorMessage += "-----> $($errDetails.errors.message)"
                }
            }
            Write-Error ($ErrorMessage | out-string)
            return
        }

        # Not sure this will be hit with current iwr error handling
        # May need to move to catch block need to find test
        # TODO Find test for retry
        # Retry the request
        $Retry = 0
        while ($Retry -lt $MaxRetry -and $Result.StatusCode -eq 500) {
            $Retry++
            $Wait = $([math]::pow( 2, $Retry))
            Write-Warning "Issue with request, status: $($Result.StatusCode) $($Result.StatusDescription)"
            Write-Warning "$($Retry)/$($MaxRetry) retries, waiting $($Wait)ms."
            Start-Sleep -Milliseconds $Wait
            $ProgressPreference = 'SilentlyContinue'
            $Result = Invoke-WebRequest @Arguments -UseBasicParsing
        }
        if ($Retry -ge $MaxRetry) {
            Write-Error "Max retries hit. Status: $($Result.StatusCode) $($Result.StatusDescription)"
            return
        }
    }
    
    end {
        return $Result
    }
}
