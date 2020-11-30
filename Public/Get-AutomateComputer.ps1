function Get-AutomateComputer {
<#
.SYNOPSIS
    Get Computer information out of the Automate API
.DESCRIPTION
    Connects to the Automate API and returns one or more full computer objects. With no parameters, all computers will be returned.
.PARAMETER ComputerID
    Can take either single ComputerID integer, IE 1, or an array of ComputerID integers, IE 1,5,9. Limits results to include only specified IDs.
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
.PARAMETER ComputerName
    Computer name to search for, uses wildcards so full computer name is not needed
.PARAMETER OpenPort
    Searches through all computers and finds where a UDP or TCP port is open. Can either take a single number, ie -OpenPort "443"
.PARAMETER OperatingSystem
    Operating system name to search for, uses wildcards so full OS Name not needed. IE: -OperatingSystem "Windows 7"
.PARAMETER DomainName
    Domain name to search for, uses wildcards so full OS Name not needed. IE: -DomainName ".local"
.PARAMETER NotSeenInDays
    Returns all computers that have not been seen in an amount of days. IE: -NotSeenInDays 30
.PARAMETER Comment
    Returns all computers that have a comment set with the computer in Automate. Wildcard search.
.PARAMETER LastWindowsUpdateInDays
    Returns computers where the LastWindowUpdate in days is over a certain amount. This is not based on patch manager information but information in Windows
.PARAMETER AntiVirusDefinitionInDays
    Returns computers where the Antivirus definitions are older than x days
.PARAMETER LocalIPAddress
    Returns computers with a specific local IP address
.PARAMETER GatewayIPAddress
    Returns the external IP of the Computer
.PARAMETER MacAddress
    Returns computers with an mac address as a wildcard search
.PARAMETER LoggedInUser
    Returns computers with a certain logged in user, using wildcard search, IE: -LoggedInUser "Gavin" will find all computers where a Gavin is logged in.
.PARAMETER Master
    Returns computers that are Automate masters
.PARAMETER NetworkProbe
    Returns computers that are Automate network probes
.PARAMETER InMaintenanceMode
    Returns computers that are in maintenance mode
.PARAMETER IsVirtualMachine
    Returns computers that are virtual machines
.PARAMETER DDay
    Returns agents that are affected by the Automate Binary issue hitting on 9th March 2019
.PARAMETER Online
    Returns agents that are online or offline, IE -Online $true or alternatively -Online $false
.PARAMETER UserIdleLongerThanMinutes
    Takes an integer in minutes and brings back all users who have been idle on their machines longer than that. IE -UserIdleLongerThanMinutes 60
.PARAMETER UptimeLongerThanMinutes
    Takes an integer in minutes and brings back all computers that have an uptime longer than x minutes. IE -UptimeLongerThanMinutes 60
.PARAMETER AssetTag
    Return computers with a certain asset tag - a wildcard search
.PARAMETER Server
    Return computers that are servers, boolean value can be used as -Server $true or -Server $false
.PARAMETER Workstation
    Return computers that are workstations, boolean value can be used as -Workstation $true or -Workstation $false 
.PARAMETER AntivirusScanner
    Return computers that have a certain antivirus. Wildcard search.
.PARAMETER RebootNeeded
    Return computers that need a reboot. Bool. -RebootNeeded $true or -RebootNeeded $false
.PARAMETER VirtualHost
    Return computers that are virtual hosts. Bool. -VirtualHost $true or -VirtualHost $false  
.PARAMETER SerialNumber
    Return computers that have a serial number specified. Wildcard Search
.PARAMETER BiosManufacturer
    Return computers with a specific Bios Manufacturer. Wildcard search.
.PARAMETER BiosVersion
    Return computers with a specific BIOS Version. This is a string search and a wildcard.
.PARAMETER LocalUserAccounts
    Return computers where certain local user accounts are present
.PARAMETER RemoteAgentVersionMin
    Return computers where the RemoteAgentVersion >= the specified value.
.PARAMETER RemoteAgentVersionMax
    Return computers where the RemoteAgentVersion <= the specified value.
.OUTPUTS
    Computer Objects
.NOTES
    Version:        1.0
    Author:         Gavin Stone
    Creation Date:  2019-01-20
    Purpose/Change: Initial script development

    Update Date:    2020-07-03
    Author:         Darren White
    Purpose/Change: Updates to support custom conditions plus parameter conditions, ID will be returned in ComputerIO property

.EXAMPLE
    Get-AutomateComputer
.EXAMPLE
    Get-AutomateComputer -OperatingSystem "Windows 7"
.EXAMPLE
    Get-AutomateComputer -ClientName "Rancor"
.EXAMPLE
    Get-AutomateComputer -Condition "(Type != 'Workstation')"
#>
    [CmdletBinding(DefaultParameterSetName = 'IncludeFields')]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [Alias('ID')]
        [int32[]]$ComputerID,

        [Alias("Client")]
        [string]$ClientName,

        [int]$ClientId,
        [int]$LocationId,

        [Alias("Location")]
        [string]$LocationName,

        [Alias("Computer","Name","Netbios")]
        [string]$ComputerName,

        [Alias("Port")]
        [string]$OpenPort,

        [Alias("OS","OSName")]
        [string]$OperatingSystem,

        [Alias("Domain")]
        [string]$DomainName,

        [Alias("OfflineSince","OfflineInDays")]
        [int]$NotSeenInDays,

        [string]$Comment,

        [Alias("WindowsUpdateInDays")]
        [int]$LastWindowsUpdateInDays,

        [Alias("AVDefinitionInDays")]
        [string]$AntiVirusDefinitionInDays,

        [Alias("IPAddress","IP")]
        [string]$LocalIPAddress,

        [Alias("ExternalIPAddress","ExternalIP","IPAddressExternal","IPExternal")]
        [string]$GatewayIPAddress,

        [Alias("Mac")]
        [string]$MacAddress,

        [Alias("User","Username")]
        [string]$LoggedInUser,

        [Alias("IsMaster")]
        [bool]$Master,

        [Alias("IsNetworkProbe")]
        [bool]$NetworkProbe,

        [Alias("InMaintenanceMode")]
        [bool]$MaintenanceMode,

        [Alias("IsVirtualMachine")]
        [bool]$VirtualMachine,

#        [switch]$DDay,

        [bool]$Online,

        [Alias("Idle")]
        [int]$UserIdleLongerThanMinutes,

        [Alias("Uptime")]
        [int]$UptimeLongerThanMinutes,

        [string]$AssetTag,
        [bool]$Server,
        [bool]$Workstation,

        [Alias("AV","VirusScanner","Antivirus")]
        [string]$AntivirusScanner,

        [Alias("PendingReboot","RebootRequired")]
        [bool]$RebootNeeded,

        [Alias("IsVirtualHost")]
        [bool]$VirtualHost,

        [string]$SerialNumber,
        [string]$BiosManufacturer,
        [string]$BiosVersion,
        [string]$LocalUserAccounts,
        $RemoteAgentVersionMin,
        $RemoteAgentVersionMax,

        [string]$Condition,
        [Parameter(Mandatory = $false, ParameterSetName = 'IncludeFields')]
        [string]$IncludeFields,
        [Parameter(Mandatory = $false, ParameterSetName = 'ExcludeFields')]
        [string]$ExcludeFields,
        $ResultSetSize,
#        $ResultSetSize = 100,  #Thinking about supporting this to put a default cap back in place.
        [string]$OrderBy

    )

    $RequestParameters = @{
        'AllResults'=$True
        'Endpoint'="computers"
    }

    $ArrayOfConditions = @()

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

    if ($OpenPort) {
        $ArrayOfConditions += "((OpenPortsTCP contains $OpenPort) or (OpenPortsUDP contains $OpenPort))"
    }

    if ($Dday) {
        $ArrayOfConditions += "((RemoteAgentVersion < '190.58') and (RemoteAgentVersion > '120.451'))"
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
        $ArrayOfConditions += "(MacAddress like '%$MacAddress%')"
    }

    if ($LoggedInUser) {
        $ArrayOfConditions += "(LoggedInUsers.LoggedInUserName like '%$LoggedInUser%')"
    }

    if ($PSBoundParameters.ContainsKey('Master')) {
        $ArrayOfConditions += "(IsMaster = $Master)"
    }

    if ($PSBoundParameters.ContainsKey('NetworkProbe')) {
        $ArrayOfConditions += "(IsNetworkProbe = $NetworkProbe)"
    }

    if ($PSBoundParameters.ContainsKey('MaintenanceMode')) {
        $ArrayOfConditions += "(IsMaintenanceModeEnabled = $MaintenanceMode)"
    }

    if ($PSBoundParameters.ContainsKey('Virtualmachine')) {
        $ArrayOfConditions += "(IsVirtualMachine = $Virtualmachine)"
    }

    if (($PSBoundParameters.ContainsKey('Online')) -and ($Online)) {
        $ArrayOfConditions += "(Status = 'Online')"
    }

    if (($PSBoundParameters.ContainsKey('Online')) -and (!$Online)) {
        $ArrayOfConditions += "(Status = 'Offline')"
    }

    if ($UserIdleLongerThanMinutes) {
#        $Seconds = $UserIdleLongerThanMinutes * 60
        $ArrayOfConditions += "((Status = 'Online') and (UserIdleTime >= $UserIdleLongerThanMinutes))"
    }

    if ($UptimeLongerThanMinutes) {
#        $Seconds = $UptimeLongerThanMinutes * 60
        $ArrayOfConditions += "((Status = 'Online') and (SystemUptime >= $UptimeLongerThanMinutes))"
    }

    if ($AssetTag) {
        $ArrayOfConditions += "(AssetTag like '%$AssetTag%')"
    }

    If ($PSBoundParameters.ContainsKey('Server')) {
        If ($Server -eq $False) {
            $ArrayOfConditions += "(Type != 'Server')"
        } Else {
            $ArrayOfConditions += "(Type = 'Server')"
        }
    }

    If ($PSBoundParameters.ContainsKey('Workstation')) {
        If ($Workstation -eq $False) {
            $ArrayOfConditions += "(Type != 'Workstation')"
        } Else {
            $ArrayOfConditions += "(Type = 'Workstation')"
        }
    }

    if ($AntivirusScanner) {
        $ArrayOfConditions += "(VirusScanner.Name like '%$AntivirusScanner%')"
    }

    if ($PSBoundParameters.ContainsKey('RebootNeeded')) {
        $ArrayOfConditions += "(IsRebootNeeded = $RebootNeeded)"
    }

    if ($PSBoundParameters.ContainsKey('VirtualHost')) {
        $ArrayOfConditions += "(IsVirtualHost = $VirtualHost)"
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

    if ($RemoteAgentVersionMin) {
        $ArrayOfConditions += "(RemoteAgentVersion >= '$RemoteAgentVersionMin')"
    }

    if ($RemoteAgentVersionMax) {
        $ArrayOfConditions += "(RemoteAgentVersion <= '$RemoteAgentVersionMax')"
    }

    If ($ArrayOfConditions) {
        $FinalCondition = Get-ConditionsStacked -ArrayOfConditions $ArrayOfConditions
        If ($Condition) {
            $Condition="($Condition) and ($FinalCondition)"
        } Else {
            $Condition=$FinalCondition
        }
    }

    If ($Condition) {
        $RequestParameters.Add('condition',$Condition)
    }

    If ($ComputerID) {
        $RequestParameters.Add('ids',$(($ComputerID) -join ","))
    }

    If ($IncludeFields) {
        $RequestParameters.Add('IncludeFields',$IncludeFields)
    } ElseIf ($ExcludeFields) {
        $RequestParameters.Add('ExcludeFields',$ExcludeFields)
    }

    If ($OrderBy) {
        $RequestParameters.Add('OrderBy',$OrderBy)
    }

    Get-AutomateAPIGeneric @RequestParameters | Select-Object -ExcludeProperty ID -Property @{n='ComputerID';e={$_.ID}},*

#    $FinalResult = Get-AutomateAPIGeneric -AllResults -Endpoint "computers" -Condition $FinalCondition -IncludeFields $IncludeFields -ExcludeFields $ExcludeFields -OrderBy $OrderBy
#    return $FinalResult
}