function Connect-AutomateAPI {
    <#
      .SYNOPSIS
        Connect to the Automate API.
      .DESCRIPTION
        Connects to the Automate API and returns a bearer token which when passed with each requests grants up to an hours worth of access.
      .PARAMETER Server
        The address to your Automate Server. Example 'rancor.hostedrmm.com' - Do not use or prefix https://
      .PARAMETER AutomateCredentials
        Takes a standard powershell credential object, this can be built with $CredentialsToPass = Get-Credential, then pass $CredentialsToPass
      .PARAMETER TwoFactorToken
        Takes a string that represents the 2FA number
      .PARAMETER Quiet
        Will not output any standard logging messages
      .OUTPUTS
        Three strings into global variables, $CWAUri containing the server address, $CWACredentials containing the bearer token and $CWACredentialsExpirationDate containing the date the credentials expire
      .NOTES
        Version:        1.0
        Author:         Gavin Stone
        Creation Date:  20/01/2019
        Purpose/Change: Initial script development
      .EXAMPLE
        Connect-AutomateAPI -Server "rancor.hostedrmm.com" -AutomateCredentials $CredentialObject -TwoFactorToken "999999"
    #>
    [CmdletBinding()]
    param (
        [Parameter(mandatory = $false)]
        [System.Management.Automation.PSCredential]$AutomateCredentials,

        [Parameter(mandatory = $false)]
        [string]$Server,

        [Parameter(mandatory = $false)]
        [string]$TwoFactorToken,

        [Parameter(mandatory = $false)]
        [switch]$Quiet
    )
    
    begin {
        if (!$Server) {
            $Server = Read-Host -Prompt "Please enter your Automate Server address, without the HTTPS, IE: rancor.hostedrmm.com" 
        }
        if (!$AutomateCredentials) {
            $Username = Read-Host -Prompt "Please enter your Automate Username"
            $Password = Read-Host -Prompt "Please enter your Automate Password" -AsSecureString
            $AutomateCredentials = New-Object System.Management.Automation.PSCredential ($Username, $Password)
            $TwoFactorToken = Read-Host -Prompt "Please enter your 2FA Token, enter nothing if this account does not have 2FA enabled"
        }
    }
    
    process {
        #Build the headers for the Authentication
        $PostHeaders = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $PostHeaders.Add("username", $AutomateCredentials.UserName)
        $PostHeaders.Add("password", $AutomateCredentials.GetNetworkCredential().Password)
        if ($TwoFactorToken -or -not([string]::IsNullOrEmpty($TwoFactorToken))) {
            #Remove any spaces that were added
            $TwoFactorToken = $TwoFactorToken -replace '\s', ''
            $PostHeaders.Add("TwoFactorPasscode", $TwoFactorToken)
        }

        #Build the URI for Authentication
        $AutomateAPIURI = "https://$Server/cwa/api/v1/apitoken"

        #Convert the body to JSON for Posting
        $PostBody = $PostHeaders | ConvertTo-Json

        #Invoke the REST Method
        try {
            $AutomateAPITokenResult = Invoke-RestMethod -Method post -Uri $AutomateAPIURI -Body $PostBody -ContentType "application/json" -ErrorAction Stop
        }
        catch {
            Write-Error "Attempt to authenticated to the Automate API has failed with error $_.Exception.Message"
        }

        #Build the returned token
        $AutomateToken = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
        $AutomateToken.Add("Authorization", "Bearer $($AutomateAPITokenResult.accesstoken)")

        if ([string]::IsNullOrEmpty($AutomateAPITokenResult.accesstoken)) {
            Write-Error "Unable to get Access Token. Either the credentials your entered are incorrect or you did not pass a valid two factor token"
        }

        Write-Verbose "Token retrieved, $AutomateAPITokenResult.accesstoken, expiration is $AutomateAPITokenResult.ExpirationDate"

        #Create Global Variables for this session in order to use the token
        $Global:CWAUri = ($server + "/cwa/api")
        $Global:CWACredentials = $AutomateToken
        $Global:CWACredentialsExpirationDate = $AutomateAPITokenResult.ExpirationDate

        if (!$Quiet) {
            Write-Host  -BackgroundColor Green -ForegroundColor Black "Token retrieved successfully"
        }

    }
    
    end {
    }
}

function Connect-ControlAPI {
    <#
    .SYNOPSIS
    Creates a Control Credential in Memory.
    .DESCRIPTION
    Creates a Control hashtable in memory containing the server and username/password so that it can be used in other functions that connect to ConnectWise Control. Unfortunately the Control API does not support 2FA.
    .PARAMETER Server
    The address to your Control Server. Example 'https://control.rancorthebeast.com:8040'
    .PARAMETER ControlCredentials
    Takes a standard powershell credential object, this can be built with $CredentialsToPass = Get-Credential, then pass $CredentialsToPass
    .PARAMETER Quiet
    Will not output any standard logging messages
    .OUTPUTS
    One hashtable called $ControlCredentials
    .NOTES
    Version:        1.0
    Author:         Gavin Stone
    Creation Date:  20/01/2019
    Purpose/Change: Initial script development
    .EXAMPLE
    All values will be prompted for one by one:
    Connect-ControlAPI
    All values needed to Automatically create appropriate output
    Connect-ControlAPI -Server "https://control.rancorthebeast.com:8040" -ControlCredentials $CredentialsToPass
    #>
    [CmdletBinding()]
    param (
        [Parameter(mandatory = $false)]
        [System.Management.Automation.PSCredential]$ControlCredentials,

        [Parameter(mandatory = $false)]
        [string]$Server,

        [Parameter(mandatory = $false)]
        [switch]$Quiet
    )
    
    begin {
        if (!$Server) {
            $Server = Read-Host -Prompt "Please enter your Control Server address, the full URL. IE https://control.rancorthebeast.com:8040" 
        }
        if (!$ControlCredentials) {
            $Username = Read-Host -Prompt "Please enter your Control Username"
            $Password = Read-Host -Prompt "Please enter your Control Password" -AsSecureString
            $ControlCredentials = New-Object System.Management.Automation.PSCredential ($Username, $Password)
        }
    }
    
    process {

        $Global:ControlCredentials = $ControlCredentials
        $Global:ControlServer = $Server

        if (!$Quiet) {
            Write-Host  -BackgroundColor Green -ForegroundColor Black "Credentials stored in memory"
        }

    }
    
    end {
    }
}

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

function Get-AutomateControlGUID {
    param
    (
        [Parameter(Mandatory = $true, Position = 0,ValueFromPipeline = $true, ValueFromPipelineByPropertyName=$true)]
        [Alias('Id')]
        [int16[]]$ComputerID
    )

    
  process {
    foreach ($ComputerIDSingle in $ComputerID) {
        $url = ($Global:CWAUri + "/v1/extensionactions/control/$ComputerIDSingle")

        $OurResult = [pscustomobject]@{
          ComputerId = $ComputerIdSingle
        }

        $Result = Invoke-RestMethod -Uri $url -Headers $global:CWACredentials -ContentType "application/json"
        if (-not ([string]::IsNullOrEmpty($Result))) {
            $Position = $Result.IndexOf("=");
            $ControlGUID = ($Result.Substring($position + 1)).Substring(0, 36)
            
            $OurResult | Add-Member -NotePropertyName ControlGuid -NotePropertyValue $ControlGuid -PassThru | Write-Output
        }
        else {
            $OurResult | Add-Member -NotePropertyName ControlGuid -NotePropertyValue "No GUID Found" -PassThru | Write-Output
        }
    }
  }

}
function Get-ControlLastContact {
    <#
    .SYNOPSIS
      Returns the date the machine last connected to the control server.
    .DESCRIPTION
      Returns the date the machine last connected to the control server.
    .PARAMETER GUID
      The GUID/SessionID for the machine you wish to connect to.
      You can retrieve session info with the 'Get-CWCSessions' commandlet
      On Windows clients, the launch parameters are located in the registry at:
        HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\ScreenConnect Client (xxxxxxxxxxxxxxxx)\ImagePath
      On Linux and Mac clients, it's found in the ClientLaunchParameters.txt file in the client installation folder:
        /opt/screenconnect-xxxxxxxxxxxxxxxx/ClientLaunchParameters.txt
    .PARAMETER Quiet
      Will output a boolean result, $True for Connected or $False for Offline.
    .PARAMETER Seconds
      Used with the Quiet switch. The number of seconds a machine needs to be offline before returning $False.
  
    .PARAMETER Group
      Name of session group to use.
    .OUTPUTS
        [datetime] -or [boolean]
    .NOTES
        Version:        1.1
        Author:         Chris Taylor
        Modified By:    Gavin Stone
        Creation Date:  1/20/2016
        Purpose/Change: Initial script development
        Update Date:  8/24/2018
        Purpose/Change: Fix Timespan Seconds duration
  #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $True)]
        [guid]$GUID,
        [switch]$Quiet,
        [int]$Seconds,
        [string]$Group = "All Machines"
    )

    # Time conversion
    $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    $epoch = $((New-TimeSpan -Start $(Get-Date -Date "01/01/1970") -End $(Get-Date)).TotalSeconds)

    $Body = ConvertTo-Json @($Group, $GUID)
    Write-Verbose $Body

    $URl = "$($ControlServer)/Services/PageService.ashx/GetSessionDetails"
    try {
        #Get Credentials out of global var
        $SessionDetails = Invoke-RestMethod -Uri $url -Method Post -Credential $ControlCredentials -ContentType "application/json" -Body $Body
    }
    catch {
        Write-Error "$($_.Exception.Message)"
        return
    }

    if ($SessionDetails -eq 'null' -or !$SessionDetails) {
        Write-Output "Machine not found."
        return
    }

    # Filter to only guest session events
    $GuestSessionEvents = ($SessionDetails.Connections | Where-Object {$_.ProcessType -eq 2}).Events

    if ($GuestSessionEvents) {

        # Get connection events
        $LatestEvent = ($GuestSessionEvents | Where-Object {$_.EventType -in (10, 11)} | Sort-Object time)[0]
        if ($LatestEvent.EventType -eq 10) {
            # Currently connected
            if ($Quiet) {
                return $True
            }
            else {
                return Get-Date
            }

        }
        else {
            # Time conversion hell :(
            $TimeDiff = $epoch - ($LatestEvent.Time / 1000)
            $OfflineTime = $origin.AddSeconds($TimeDiff)
            $Difference = New-TimeSpan -Start $OfflineTime -End $(Get-Date)
            if ($Quiet -and $Difference.TotalSeconds -lt $Seconds) {
                return $True
            }
            elseif ($Quiet) {
                return $False
            }
            else {
                return $OfflineTime
            }
        }
    }
    else {
        Write-Output "Unable to determine last contact."
        return
    }
}

function Get-ConditionsStacked {
    param (
        [Parameter()]
        [string[]]$ArrayOfConditions
    )

    $FinalString = ($ArrayOfConditions) -join " And "
    Return $FinalString
  
}

function Get-AutomateComputer {
    param (
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = "IndividualPC")]
        [int16]$ComputerID,

        [Parameter(Mandatory = $false, ParameterSetName = "AllResults")]
        [switch]$AllComputers,
        
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = "ByCondition")]
        [string]$Condition,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$ClientName,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$ComputerName,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$OpenPort,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$OperatingSystem,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$DomainName,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [int]$NotSeenInDays,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$Comment,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [int]$LastWindowsUpdateInDays,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$AntiVirusDefinitionInDays,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$LocalIPAddress,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$GatewayIPAddress,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$MacAddress,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$LoggedInUser,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [bool]$IsMaster,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [bool]$IsNetworkProbe,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [bool]$InMaintenanceMode,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [bool]$IsVirtualMachine,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [switch]$OnlineOnly,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [switch]$OfflineOnly,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [int]$UserIdleLongerThanMinutes,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [int]$UptimeLongerThanMinutes,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$AssetTag,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [switch]$IsServer,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [switch]$IsWorkstation,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$AntivirusScanner,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [bool]$RebootNeeded,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [bool]$IsVirtualHost,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$SerialNumber,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$BiosManufacturer,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$BiosVersion,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$LocalUserAccounts

    )

    $ArrayOfConditions = @()

    if ($ComputerID) {
        Return Get-AutomateAPIOutputGeneric -AllResults -APIURI "/v1/computers/$($ComputerID)?"
    }

    if ($AllComputers) {
        Return Get-AutomateAPIOutputGeneric -AllResults -APIURI "/v1/computers?"
    }

    if ($Condition) {
        Return Get-AutomateAPIOutputGeneric -AllResults -APIURI "/v1/computers?" -Condition $Condition
    }

    if ($ClientName) {
        $ArrayOfConditions += "(Client.Name like '%$ClientName%')"
    }

    if ($ComputerName) {
        $ArrayOfConditions += "(ComputerName like '%$ComputerName%')"
    }

    if ($OpenPort) {
        $ArrayOfConditions += "((OpenPortsTCP contains $OpenPort) or (OpenPortsUDP contains $OpenPort))"
    }

    if ($OperatingSystem) {
        $ArrayOfConditions += "(OperatingSystemName like '%$OperatingSystem%')"
    }

    if ($DomainName) {
        $ArrayOfConditions += "(DomainName like '%$DomainName%')"
    }

    if ($NotSeenInDays) {
        $CurrentDateMinusVar = (Get-Date).AddDays( - $($NotSeenInDays))
        $Final = (Get-Date $CurrentDateMinusVar -Format s)
        $ArrayOfConditions += "(RemoteAgentLastContact <= $Final)"
    }

    if ($Comment) {
        $ArrayOfConditions += "(Comment like '%$Comment%')"
    }

    if ($LastWindowsUpdateInDays) {
        $Final = (Get-Date).AddDays( - $($LastWindowsUpdateInDays)).ToString('s')
        $OnInLast2Days = (Get-Date).AddDays(-2).ToString('s')
        $ArrayOfConditions += "((WindowsUpdateDate <= $Final) and (RemoteAgentLastContact >= $OnInLast2Days) and (OperatingSystemName not like '%Mac%') and (OperatingSystemName not like '%Linux%'))"
    }

    if ($AntiVirusDefinitionInDays) {
        $Final = (Get-Date).AddDays( - $($AntiVirusDefinitionInDays)).ToString('s')
        $OnInLast2Days = (Get-Date).AddDays(-2).ToString('s')
        $ArrayOfConditions += "((AntiVirusDefinitionDate <= $Final) and (RemoteAgentLastContact >= $OnInLast2Days))"
    }

    if ($LocalIPAddress) {
        $ArrayOfConditions += "(LocalIPAddress = '$LocalIPAddress')"
    }

    if ($GatewayIPAddress) {
        $ArrayOfConditions += "(GatewayIPAddress = '$GatewayIPAddress')"
    }

    if ($MacAddress) {
        $ArrayOfConditions += "(MacAddress = '$MacAddress')"
    }

    if ($LoggedInUser) {
        $ArrayOfConditions += "(LoggedInUsers.LoggedInUserName like '%$LoggedInUser%')"
    }

    if ($PSBoundParameters.ContainsKey('IsMaster')) {
        $ArrayOfConditions += "(IsMaster = $IsMaster)"
    }

    if ($PSBoundParameters.ContainsKey('IsNetworkProbe')) {
        $ArrayOfConditions += "(IsNetworkProbe = $IsNetworkProbe)"
    }

    if ($PSBoundParameters.ContainsKey('InMaintenanceMode')) {
        $ArrayOfConditions += "(IsMaintenanceModeEnabled = $InMaintenanceMode)"
    }

    if ($PSBoundParameters.ContainsKey('IsVirtualmachine')) {
        $ArrayOfConditions += "(IsVirtualMachine = $IsVirtualmachine)"
    }

    if ($OnlineOnly) {
        $ArrayOfConditions += "(Status = 'Online')"
    }

    if ($OfflineOnly) {
        $ArrayOfConditions += "(Status = 'Offline')"
    }

    if ($UserIdleLongerThanMinutes) {
        $Seconds = $UserIdleLongerThanMinutes * 60
        $ArrayOfConditions += "((Status = 'Online') and (UserIdleTime >= $UserIdleLongerThanMinutes))"
    }

    if ($UptimeLongerThanMinutes) {
        $Seconds = $UptimeLongerThanMinutes * 60
        $ArrayOfConditions += "((Status = 'Online') and (SystemUptime >= $UptimeLongerThanMinutes))"
    }

    if ($AssetTag) {
        $ArrayOfConditions += "(AssetTag like '%$AssetTag%')"
    }

    if ($IsServer) {
        $ArrayOfConditions += "(Type = 'Server')"
    }

    if ($IsWorkstation) {
        $ArrayOfConditions += "(Type = 'Workstation')"
    }

    if ($AntivirusScanner) {
        $ArrayOfConditions += "(VirusScanner.Name like '%$AntivirusScanner%')"
    }

    if ($PSBoundParameters.ContainsKey('RebootNeeded')) {
        $ArrayOfConditions += "(IsRebootNeeded = $RebootNeeded)"
    }

    if ($PSBoundParameters.ContainsKey('IsVirtualHost')) {
        $ArrayOfConditions += "(IsVirtualHost = $IsVirtualHost)"
    }

    if ($SerialNumber) {
        $ArrayOfConditions += "(SerialNumber like '%$SerialNumber%')"
    }

    if ($BiosManufacturer) {
        $ArrayOfConditions += "(BIOSManufacturer like '%$BIOSManufacturer%')"
    }

    if ($BiosVersion) {
        $ArrayOfConditions += "(BIOSFlash like '%$BIOSVersion%')"
    }

    if ($LocalUserAccounts) {
        $ArrayOfConditions += "(UserAccounts Contains '$LocalUserAccounts')"
    }

    
    $FinalCondition = Get-ConditionsStacked -ArrayOfConditions $ArrayOfConditions

    $FinalResult = Get-AutomateAPIOutputGeneric -AllResults -APIURI "/v1/computers?" -Condition $FinalCondition

    return $FinalResult
}

function Get-AutomateControlReconcile {
    [CmdletBinding()]
    param (
        $ResultArray = @()
    )
  
    begin {
        $ResultArray = @()
        $ComputersToCheck = Get-AutomateComputer -NotSeenInDays 30
    }
  
    process {

        foreach ($CompToCheck in $ComputersToCheck) {

            #Calculate how many days until it has been online
            $AutomateDate = [DateTime]$CompToCheck.RemoteAgentLastContact
            $Now = Get-Date
            $NumberOfDays = New-TimeSpan -Start $AutomateDate -End $Now | Select -ExpandProperty Days
  
            #Start building the custom object
            $ResultObject = [PSCustomObject]@{}
            $ResultObject | Add-Member -Type NoteProperty -Name "ComputerID" -Value $CompToCheck.Id
            $ResultObject | Add-Member -Type NoteProperty -Name "ComputerName" -Value $CompToCheck.ComputerName
            $ResultObject | Add-Member -Type NoteProperty -Name "ClientName" -Value $CompToCheck.Client.Name
            $ResultObject | Add-Member -Type NoteProperty -Name "LocationName" -Value $CompToCheck.Location.Name
            $ResultObject | Add-Member -Type NoteProperty -Name "LastContactDateInAutomate" -Value $AutomateDate
            $ResultObject | Add-Member -Type NoteProperty -Name "DaysSinceSeenInAutomate" -Value $NumberOfDays
  
            Write-Host "Checking ID $($CompToCheck.ID) - $($CompToCheck.ComputerName) at $($CompToCheck.Client.Name). Last seen $($AutomateDate) which was $NumberOfDays days ago" -BackgroundColor Yellow -ForegroundColor Black
  
            #Get the Control GUID for this instance
            $ControlGuid = $(Get-AutomateControlGUID -ComputerID $CompToCheck.ID | Select -ExpandProperty ControlGUID)
            if (-not([string]::IsNullOrEmpty($ControlGuid)) -and ($ControlGuid -ne 'No Control Guid Found')) {
                $ResultObject | Add-Member -Type NoteProperty -Name "ControlGUID" -Value $ControlGUID
  
                #Get Last Contact Date from Control
                $LastContactDateInControl = Get-ControlLastContact -GUID $ControlGuid
                $ResultObject | Add-Member -Type NoteProperty -Name "LastContactDateInControl" -Value $LastContactDateInControl
  
                #Convert to a date, if we can then add to Result Object
                try {
                    $ControlTimeSpan = New-TimeSpan -Start $LastContactDateInControl -End $Now
                    $NumberOfMinutesInControl = $ControlTimeSpan | Select-Object -ExpandProperty TotalMinutes
                    $NumberOfDaysInControl = $ControlTimeSpan | Select-Object -ExpandProperty Days
                }
                catch {
                    $NumberOfMinutesInControl = $null
                    $NumberOfDaysInControl = $null
                }
                if (($NumberOfMinutesInControl -gt -5) -and ($NumberOfMinutesInControl -le 5) -and (-not [string]::IsNullOrEmpty($NumberOfMinutesInControl))) {
                    $ResultObject | Add-Member -Type NoteProperty -Name "IsOnline" -Value $True
                    Write-Host "ONLINE: ID $($CompToCheck.ID) - $($CompToCheck.ComputerName) at $($CompToCheck.Client.Name). Last seen $($AutomateDate) is currently online in Control" -BackgroundColor Red -ForegroundColor Yellow
                }
                else {
                    $ResultObject | Add-Member -Type NoteProperty -Name "IsOnline" -Value $False
                }
                $ResultObject | Add-Member -Type NoteProperty -Name "MinutesSinceSeenInControl" -Value $NumberOfMinutesInControl
                $ResultObject | Add-Member -Type NoteProperty -Name "DaysSinceSeenInControl" -Value $NumberOfDaysInControl
            }
  
            #Add to final Array Object
            $ResultArray += $ResultObject
        }
    }
  
    end {
    }
}

function Invoke-ControlCommand {
    <#
    .SYNOPSIS
        Will issue a command against a given machine and return the results.
    .DESCRIPTION
        Will issue a command against a given machine and return the results.
    .PARAMETER GUID
        The GUID identifier for the machine you wish to connect to.
        You can retrieve session info with the 'Get-CWCSessions' commandlet
    .PARAMETER Command
        The command you wish to issue to the machine.
    .PARAMETER TimeOut
        The amount of time in milliseconds that a command can execute. The default is 10000 milliseconds.
    .PARAMETER PowerShell
        Issues the command in a powershell session.
    .PARAMETER Group
        Name of session group to use.
    .OUTPUTS
        The output of the Command provided.
    .NOTES
        Version:        1.0
        Author:         Chris Taylor
        Modified By:    Gavin Stone 
        Creation Date:  1/20/2016
        Purpose/Change: Initial script development
    .EXAMPLE
        Invoke-ControlCommand -GUID $GUID -Command 'hostname'
            Will return the hostname of the machine.
    .EXAMPLE
        Invoke-ControlCommand -Server $ControlServer -GUID $GUID -User $User -Password $Password -TimeOut 120000 -Command 'iwr -UseBasicParsing "https://bit.ly/ltposh" | iex; Restart-LTService' -PowerShell
            Will restart the Automate agent on the target machine.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True)]
        [guid]$GUID,
        [string]$Command,
        [int]$TimeOut = 10000,
        [switch]$PowerShell,
        [string]$Group = "All Machines",
        [int]$MaxLength = 5000
    )

    $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0

    $URI = "$ControlServer/Services/PageService.ashx/AddEventToSessions"

    # Format command
    $FormattedCommand = @()
    if ($Powershell) {
        $FormattedCommand += '#!ps'
    }
    $FormattedCommand += "#timeout=$TimeOut"
    $FormattedCommand += "#maxlength=$MaxLength"
    $FormattedCommand += $Command
    $FormattedCommand = $FormattedCommand | Out-String

    $SessionEventType = 44
    $Body = ConvertTo-Json @($Group,@($GUID),$SessionEventType,$FormattedCommand)
    Write-Verbose $Body
    
    # Issue command
    try {
        $null = Invoke-RestMethod -Uri $URI -Method Post -Credential $ControlCredentials -ContentType "application/json" -Body $Body
    }
    catch {
        Write-Error "$(($_.ErrorDetails | ConvertFrom-Json).message)"
        return
    }

    # Get Session
    $URI = "$ControlServer/Services/PageService.ashx/GetSessionDetails"
    $Body = ConvertTo-Json @($Group,$GUID)
    Write-Verbose $Body
    try {
        $SessionDetails = Invoke-RestMethod -Uri $URI -Method Post -Credential $ControlCredentials -ContentType "application/json" -Body $Body
    }
    catch {
        Write-Error $($_.Exception.Message)
        return
    }

    #Get time command was executed
    $epoch = $((New-TimeSpan -Start $(Get-Date -Date "01/01/1970") -End $(Get-Date)).TotalSeconds)
    $ExecuteTime = $epoch - ((($SessionDetails.events | Where-Object {$_.EventType -eq 44})[-1]).Time /1000)
    $ExecuteDate = $origin.AddSeconds($ExecuteTime)

    # Look for results of command
    $Looking = $True
    $TimeOutDateTime = (Get-Date).AddMilliseconds($TimeOut)
    $Body = ConvertTo-Json @($Group,$GUID)
    while ($Looking) {
        try {
            $SessionDetails = Invoke-RestMethod -Uri $URI -Method Post -Credential $ControlCredentials -ContentType "application/json" -Body $Body
        }
        catch {
            Write-Error $($_.Exception.Message)
            return
        }

        $ConnectionsWithData = @()
        Foreach ($Connection in $SessionDetails.connections) {
            $ConnectionsWithData += $Connection | Where-Object {$_.Events.EventType -eq 70}
        }

        $Events = ($ConnectionsWithData.events | Where-Object {$_.EventType -eq 70 -and $_.Time})
        foreach ($Event in $Events) {
            $epoch = $((New-TimeSpan -Start $(Get-Date -Date "01/01/1970") -End $(Get-Date)).TotalSeconds)
            $CheckTime = $epoch - ($Event.Time /1000)
            $CheckDate = $origin.AddSeconds($CheckTime)
            if ($CheckDate -gt $ExecuteDate) {
                $Looking = $False
                $Output = $Event.Data -split '[\r\n]' | Where-Object {$_}
                if(!$PowerShell){
                    $Output = $Output | Select-Object -skip 1
                }
                return $Output 
            }
        }

        Start-Sleep -Seconds 1
        if ($(Get-Date) -gt $TimeOutDateTime.AddSeconds(1)) {
            $Looking = $False
            Write-Warning "Command timed out."
        }
    }
}
