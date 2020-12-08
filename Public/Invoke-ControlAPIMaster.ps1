function Invoke-ControlAPIMaster {
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
        Version:        1.0
        Author:         Darren White
        Creation Date:  2020-08-01
        Purpose/Change: Initial script development

        Version:        1.1.0
        Author:         Darren White
        Creation Date:  2020-12-01
        Purpose/Change: Include values in $Script:CWCHeaders variable in request

    .EXAMPLE
        $APIRequest = @{
            'URI' = "/App_Extensions/fc234f0e-2e8e-4a1f-b977-ba41b14031f7/ReportService.ashx/GenerateReportForAutomate"
            'Body' = ConvertTo-Json @("Session","",@('SessionID','SessionType','Name','CreatedTime'),"NOT IsEnded", "", 10000)
        }
        $AllSessions = Invoke-ControlAPIMaster -Arguments $APIRequest
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
        If(!$Script:CWCIsConnected) {
            $ErrorMessage = @()
            $ErrorMessage += "Not connected to a Control server."
            $ErrorMessage +=  $_.ScriptStackTrace
            $ErrorMessage += ''
            $ErrorMessage += "----> Run 'Connect-ControlAPI' to initialize the connection before issuing other ControlAPI commands."
            Write-Error ($ErrorMessage | Out-String)
            Return
        }

        # Add default set of arguments
        $Arguments.Item('UseBasicParsing')=$Null
        If (!$Arguments.Headers) {$Arguments.Headers=@{}}
        Foreach($Key in $script:CWCHeaders.Keys){
            If($Arguments.Headers.Keys -notcontains $Key){
                $Arguments.Headers += @{$Key = $script:CWCHeaders.$Key}
            }
        }
        If ($Script:ControlAPIKey) {
            $Arguments.Headers.Item('CWAIKToken') = (Get-CWAIKToken)
        }
        Else {
            $Arguments.Item('Credential')=$Script:ControlAPICredentials
        }

        # Check URI format
        if($Arguments.URI -notlike '*`?*' -and $Arguments.URI -like '*`&*') {
            $Arguments.URI = $Arguments.URI -replace '(.*?)&(.*)', '$1?$2'
        }        
        if($Arguments.URI -notmatch '^(https?://|/)') {
            $Arguments.URI = ('/App_Extensions/fc234f0e-2e8e-4a1f-b977-ba41b14031f7/' + $Arguments.URI)
        }
        if($Arguments.URI -notmatch '^https?://') {
            $Arguments.URI = ($Script:ControlServer + $Arguments.URI)
        }

        If(!$Arguments.ContainsKey('Method')) {
            $Arguments.Add('Method','POST')
        }
        If(!$Arguments.ContainsKey('ContentType')) {
            $Arguments.Add('ContentType','application/json; charset=utf-8')
        }

        # Issue request
        Write-Debug "Calling Control Server Extension with the following arguments:`n$(($Arguments|Out-String -Stream) -join "`n")"
        Try {
            $ProgressPreference = 'SilentlyContinue'
            $Result = Invoke-WebRequest @Arguments
        } 
        Catch {
            # Start error message
            $ErrorMessage = @()
            If($_.Exception.Response){
                # Read exception response
                $ErrorStream = $_.Exception.Response.GetResponseStream()
                $Reader = New-Object System.IO.StreamReader($ErrorStream)
                $global:ErrBody = $Reader.ReadToEnd() | ConvertFrom-Json

                If($errBody.code){
                    $ErrorMessage += "An exception has been thrown."
                    $ErrorMessage +=  $_.ScriptStackTrace
                    $ErrorMessage += ''    
                    $ErrorMessage += "--> $($ErrBody.code)"
                    If($errBody.code -eq 'Unauthorized'){
                        $ErrorMessage += "-----> $($ErrBody.message)"
                        $ErrorMessage += "-----> Use 'Connect-ControlAPI' to set new authentication."
                    } Else {
                        $ErrorMessage += "-----> $($ErrBody.message)"
                        $ErrorMessage += "-----> ^ Error has not been documented please report. ^"
                    }
                }
            }

            If ($_.ErrorDetails) {
                $ErrorMessage += "An error has been thrown."
                $ErrorMessage +=  $_.ScriptStackTrace
                $ErrorMessage += ''
                $global:errDetails = $_.ErrorDetails | ConvertFrom-Json
                $ErrorMessage += "--> $($errDetails.code)"
                $ErrorMessage += "--> $($errDetails.message)"
                If($errDetails.errors.message){
                    $ErrorMessage += "-----> $($errDetails.errors.message)"
                }
            }
            If (!$ErrorMessage) {$ErrorMessage+='An unknown error was returned'; $ErrorMessage+=$Result|Out-String -Stream}
            Write-Error ($ErrorMessage | Out-String)
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
            $Script:CWCIsConnected=$False
            Write-Error "Max retries hit. Status: $($Result.StatusCode) $($Result.StatusDescription)"
            Return
        }
    }

    End {
        If ($Result) {
            Try {
                Get-Variable -Name CWCServerTime -Scope 1 -ErrorAction Stop
                Set-Variable -Name CWCServerTime -Scope 1 -Value (Get-Date $($Result.Headers.Date))
            } Catch {}
            $SCData = $(If ($Result.Content) {$Result.Content | ConvertFrom-Json})
            If ($SCData -and $SCData.FieldNames -and $SCData.Items -and $SCData.Items.Count -gt 0) {
                $FNames = $SCData.FieldNames
                $SCData.Items | ForEach-Object {
                    $x = $_
                    $SCEventRecord = @{}
                    For ($i = 0; $i -lt $FNames.Length; $i++) {
                        $Null = $SCEventRecord.Add($FNames[$i],$x[$i])
                    }
                    [pscustomobject]$SCEventRecord
                }
            }
        }
        Return
    }
}
