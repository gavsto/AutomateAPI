function Invoke-AutomateAPIMaster {
    <#
    .SYNOPSIS
        Internal function used to make API calls
    .DESCRIPTION
        Internal function used to make API calls
    .PARAMETER Arguments
        Required parameters for the API call
    .OUTPUTS
        The returned results from the API call
    .NOTES
        Version:        1.1.0
        Author:         Darren White
        Creation Date:  2020-07-03
        Purpose/Change: Initial script development

        Update Date:    2020-08-01
        Purpose/Change: Change to use CWAIsConnected script variable to track connection state
      
        Update Date:    2020-11-19
        Author:         Brandon Fahnestock
        Purpose/Change: ConnectWise Automate v2020.11 requires a registered ClientID for API access. Added Support for ClientIDs 
    .EXAMPLE
        Invoke-AutomateAPIMaster -Arguments $Arguments
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        $Arguments,
        [int]$MaxRetry = 5
    )
    
    Begin {
    }
    
    Process {
        # Check that we have cached connection info
        If(!$Script:CWAIsConnected){
            $ErrorMessage = @()
            $ErrorMessage += "Not connected to an Automate server."
            $ErrorMessage +=  $_.ScriptStackTrace
            $ErrorMessage += ''
            $ErrorMessage += "----> Run 'Connect-AutomateAPI' to initialize the connection before issuing other AutomateAPI commandlets."
            Write-Error ($ErrorMessage | Out-String)
            Return
        }
        
        # Add default set of arguments
        $Arguments.Item('UseBasicParsing')=$Null
        If (!$Arguments.Headers) {$Arguments.Headers=@{}}
        Foreach($Key in $script:CWAToken.Keys){
            If($Arguments.Headers.Keys -notcontains $Key){
                $Arguments.Headers += @{$Key = $script:CWAToken.$Key}
            }
        }
    #    if(!$Arguments.SessionVariable){ $Arguments.WebSession = $global:CWMServerConnection.Session }

        # Check URI format
        If($Arguments.URI -notlike '*`?*' -and $Arguments.URI -like '*`&*') {
            $Arguments.URI = $Arguments.URI -replace '(.*?)&(.*)', '$1?$2'
        }        

        If($Arguments.URI -notmatch '^https?://') {
          $Arguments.URI = ($Script:CWAServer + $Arguments.URI)
        }
        #Add required CWA ClientID to API request
        If($Arguments.Headers.Keys -notcontains 'clientID' -and $Script:CWAClientID -match '.+') {
            $Arguments.Headers += @{'clientID' = "$Script:CWAClientID"}
        }

        # Issue request
        Try {
            Write-Debug "Calling AutomateAPI with the following arguments:`n$(($Arguments|Out-String -Stream) -join "`n")"
            $ProgressPreference = 'SilentlyContinue'
            $Result = Invoke-WebRequest @Arguments
        } 
        Catch {
            If($_.Exception.Response){
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
            Return
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
            $Result = Invoke-WebRequest @Arguments
        }
        If ($Retry -ge $MaxRetry -and $Result.StatusCode -eq 500) {
            $Script:CWAIsConnected=$False
            Write-Error "Max retries hit. Status: $($Result.StatusCode) $($Result.StatusDescription)"
            Return
        }
    }
    
    End {
        Return $Result
    }
}
