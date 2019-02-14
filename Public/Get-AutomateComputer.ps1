function Get-AutomateComputer {
<#
.SYNOPSIS
    Get Computer information out of the Automate API
.DESCRIPTION
    Connects to the Automate API and returns one or more full computer objects
.PARAMETER ComputerID
    Can take either single ComputerID integer, IE 1, or an array of ComputerID integers, IE 1,5,9
.PARAMETER AllComputers
    Returns all computers in Automate, regardless of amount
.PARAMETER Condition
    A custom condition to build searches that can be used to search for specific things. Supported operators are '=', 'eq', '>', '>=', '<', '<=', 'and', 'or', '()', 'like', 'contains', 'in', 'not'.
    The 'not' operator is only used with 'in', 'like', or 'contains'. The '=' and 'eq' operator are the same. String values can be surrounded with either single or double quotes. IE (RemoteAgentLastContact <= 2019-12-18T00:50:19.575Z)
    Boolean values are specified as 'true' or 'false'. Parenthesis can be used to control the order of operations and group conditions.
.PARAMETER ClientName
    Client name to search for, uses wildcards so full client name is not needed
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
.PARAMETER IsMaster
    Returns computers that are Automate masters
.PARAMETER IsNetworkProbe
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
.OUTPUTS
    Computer Object
.NOTES
    Version:        1.0
    Author:         Gavin Stone
    Creation Date:  2019-01-20
    Purpose/Change: Initial script development

.EXAMPLE
    Get-AutomateComputer -ComputerID 1

.EXAMPLE
    Get-AutomateComputer -ComputerID 1
#>
    param (
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = "IndividualPC")]
        [Alias('ID')]
        [int32[]]$ComputerID,

        [Parameter(Mandatory = $false, ParameterSetName = "AllResults")]
        [switch]$AllComputers,
        
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = "ByCondition")]
        [string]$Condition,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$ClientName,

        [Alias("Computer","Name","Netbios")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$ComputerName,

        [Alias("Port")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$OpenPort,

        [Alias("OS","OSName")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$OperatingSystem,

        [Alias("Domain")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$DomainName,

        [Alias("OfflineSince","OfflineInDays")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [int]$NotSeenInDays,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$Comment,

        [Alias("WindowsUpdateInDays")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [int]$LastWindowsUpdateInDays,

        [Alias("AVDefinitionInDays")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$AntiVirusDefinitionInDays,

        [Alias("IPAddress","IP")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$LocalIPAddress,

        [Alias("ExternalIPAddress","ExternalIP","IPAddressExternal","IPExternal")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$GatewayIPAddress,

        [Alias("Mac")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$MacAddress,

        [Alias("User","Username")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [string]$LoggedInUser,

        [Alias("Master")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [bool]$IsMaster,

        [Alias("NetworkProbe")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [bool]$IsNetworkProbe,

        [Alias("MaintenanceMode")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [bool]$InMaintenanceMode,

        [Alias("VirtualMachine")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [bool]$IsVirtualMachine,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [switch]$DDay,

        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [bool]$Online,

        [Alias("Idle")]
        [Parameter(Mandatory = $false, ParameterSetName = "CustomBuiltCondition")]
        [int]$UserIdleLongerThanMinutes,

        [Alias("Uptime")]
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
        Return Get-AutomateAPIOutputGeneric -AllResults -APIURI "/v1/computers/?" -IDs $(($ComputerID) -join ",")
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

    if (($PSBoundParameters.ContainsKey('Online')) -and ($Online)) {
        $ArrayOfConditions += "(Status = 'Online')"
    }

    if (($PSBoundParameters.ContainsKey('Online')) -and (!$Online)) {
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