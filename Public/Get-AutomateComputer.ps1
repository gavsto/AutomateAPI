function Get-AutomateComputer {
    param (
        [Parameter(Mandatory = $false, Position = 0, ParameterSetName = "IndividualPC")]
        [int32[]]$ComputerID,

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
        [switch]$DDay,

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
