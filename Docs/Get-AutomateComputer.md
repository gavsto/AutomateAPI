---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Get-AutomateComputer

## SYNOPSIS
Get Computer information out of the Automate API

## SYNTAX

### IncludeFields (Default)
```
Get-AutomateComputer [[-ComputerID] <Int32[]>] [-ClientName <String>] [-ClientId <Int32>] [-LocationId <Int32>]
 [-LocationName <String>] [-ComputerName <String>] [-OpenPort <String>] [-OperatingSystem <String>]
 [-DomainName <String>] [-NotSeenInDays <Int32>] [-Comment <String>] [-LastWindowsUpdateInDays <Int32>]
 [-AntiVirusDefinitionInDays <String>] [-LocalIPAddress <String>] [-GatewayIPAddress <String>]
 [-MacAddress <String>] [-LoggedInUser <String>] [-Master <Boolean>] [-NetworkProbe <Boolean>]
 [-MaintenanceMode <Boolean>] [-VirtualMachine <Boolean>] [-Online <Boolean>]
 [-UserIdleLongerThanMinutes <Int32>] [-UptimeLongerThanMinutes <Int32>] [-AssetTag <String>]
 [-Server <Boolean>] [-Workstation <Boolean>] [-AntivirusScanner <String>] [-RebootNeeded <Boolean>]
 [-VirtualHost <Boolean>] [-SerialNumber <String>] [-BiosManufacturer <String>] [-BiosVersion <String>]
 [-LocalUserAccounts <String>] [-RemoteAgentVersionMin <Object>] [-RemoteAgentVersionMax <Object>]
 [-Condition <String>] [-IncludeFields <String>] [-ResultSetSize <Object>] [-OrderBy <String>]
 [<CommonParameters>]
```

### ExcludeFields
```
Get-AutomateComputer [[-ComputerID] <Int32[]>] [-ClientName <String>] [-ClientId <Int32>] [-LocationId <Int32>]
 [-LocationName <String>] [-ComputerName <String>] [-OpenPort <String>] [-OperatingSystem <String>]
 [-DomainName <String>] [-NotSeenInDays <Int32>] [-Comment <String>] [-LastWindowsUpdateInDays <Int32>]
 [-AntiVirusDefinitionInDays <String>] [-LocalIPAddress <String>] [-GatewayIPAddress <String>]
 [-MacAddress <String>] [-LoggedInUser <String>] [-Master <Boolean>] [-NetworkProbe <Boolean>]
 [-MaintenanceMode <Boolean>] [-VirtualMachine <Boolean>] [-Online <Boolean>]
 [-UserIdleLongerThanMinutes <Int32>] [-UptimeLongerThanMinutes <Int32>] [-AssetTag <String>]
 [-Server <Boolean>] [-Workstation <Boolean>] [-AntivirusScanner <String>] [-RebootNeeded <Boolean>]
 [-VirtualHost <Boolean>] [-SerialNumber <String>] [-BiosManufacturer <String>] [-BiosVersion <String>]
 [-LocalUserAccounts <String>] [-RemoteAgentVersionMin <Object>] [-RemoteAgentVersionMax <Object>]
 [-Condition <String>] [-ExcludeFields <String>] [-ResultSetSize <Object>] [-OrderBy <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Connects to the Automate API and returns one or more full computer objects.
With no parameters, all computers will be returned.

## EXAMPLES

### EXAMPLE 1
```
Get-AutomateComputer
```

### EXAMPLE 2
```
Get-AutomateComputer -OperatingSystem "Windows 7"
```

### EXAMPLE 3
```
Get-AutomateComputer -ClientName "Rancor"
```

### EXAMPLE 4
```
Get-AutomateComputer -Condition "(Type != 'Workstation')"
```

## PARAMETERS

### -ComputerID
Can take either single ComputerID integer, IE 1, or an array of ComputerID integers, IE 1,5,9.
Limits results to include only specified IDs.

```yaml
Type: Int32[]
Parameter Sets: (All)
Aliases: ID

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientName
Client name to search for, uses wildcards so full client name is not needed

```yaml
Type: String
Parameter Sets: (All)
Aliases: Client

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientId
ClientID to search for, integer, -ClientID 1

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -LocationId
LocationID to search for, integer, -LocationID 2

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -LocationName
Location name to search for, uses wildcards so full location name is not needed

```yaml
Type: String
Parameter Sets: (All)
Aliases: Location

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerName
Computer name to search for, uses wildcards so full computer name is not needed

```yaml
Type: String
Parameter Sets: (All)
Aliases: Computer, Name, Netbios

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OpenPort
Searches through all computers and finds where a UDP or TCP port is open.
Can either take a single number, ie -OpenPort "443"

```yaml
Type: String
Parameter Sets: (All)
Aliases: Port

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OperatingSystem
Operating system name to search for, uses wildcards so full OS Name not needed.
IE: -OperatingSystem "Windows 7"

```yaml
Type: String
Parameter Sets: (All)
Aliases: OS, OSName

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DomainName
Domain name to search for, uses wildcards so full OS Name not needed.
IE: -DomainName ".local"

```yaml
Type: String
Parameter Sets: (All)
Aliases: Domain

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NotSeenInDays
Returns all computers that have not been seen in an amount of days.
IE: -NotSeenInDays 30

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: OfflineSince, OfflineInDays

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Comment
Returns all computers that have a comment set with the computer in Automate.
Wildcard search.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LastWindowsUpdateInDays
Returns computers where the LastWindowUpdate in days is over a certain amount.
This is not based on patch manager information but information in Windows

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: WindowsUpdateInDays

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -AntiVirusDefinitionInDays
Returns computers where the Antivirus definitions are older than x days

```yaml
Type: String
Parameter Sets: (All)
Aliases: AVDefinitionInDays

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LocalIPAddress
Returns computers with a specific local IP address

```yaml
Type: String
Parameter Sets: (All)
Aliases: IPAddress, IP

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -GatewayIPAddress
Returns the external IP of the Computer

```yaml
Type: String
Parameter Sets: (All)
Aliases: ExternalIPAddress, ExternalIP, IPAddressExternal, IPExternal

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MacAddress
Returns computers with an mac address as a wildcard search

```yaml
Type: String
Parameter Sets: (All)
Aliases: Mac

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LoggedInUser
Returns computers with a certain logged in user, using wildcard search, IE: -LoggedInUser "Gavin" will find all computers where a Gavin is logged in.

```yaml
Type: String
Parameter Sets: (All)
Aliases: User, Username

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Master
Returns computers that are Automate masters

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases: IsMaster

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -NetworkProbe
Returns computers that are Automate network probes

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases: IsNetworkProbe

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaintenanceMode
{{ Fill MaintenanceMode Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases: InMaintenanceMode

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -VirtualMachine
{{ Fill VirtualMachine Description }}

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases: IsVirtualMachine

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Online
Returns agents that are online or offline, IE -Online $true or alternatively -Online $false

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -UserIdleLongerThanMinutes
Takes an integer in minutes and brings back all users who have been idle on their machines longer than that.
IE -UserIdleLongerThanMinutes 60

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: Idle

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -UptimeLongerThanMinutes
Takes an integer in minutes and brings back all computers that have an uptime longer than x minutes.
IE -UptimeLongerThanMinutes 60

```yaml
Type: Int32
Parameter Sets: (All)
Aliases: Uptime

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -AssetTag
Return computers with a certain asset tag - a wildcard search

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Server
Return computers that are servers, boolean value can be used as -Server $true or -Server $false

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Workstation
Return computers that are workstations, boolean value can be used as -Workstation $true or -Workstation $false

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AntivirusScanner
Return computers that have a certain antivirus.
Wildcard search.

```yaml
Type: String
Parameter Sets: (All)
Aliases: AV, VirusScanner, Antivirus

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RebootNeeded
Return computers that need a reboot.
Bool.
-RebootNeeded $true or -RebootNeeded $false

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases: PendingReboot, RebootRequired

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -VirtualHost
Return computers that are virtual hosts.
Bool.
-VirtualHost $true or -VirtualHost $false

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases: IsVirtualHost

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SerialNumber
Return computers that have a serial number specified.
Wildcard Search

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BiosManufacturer
Return computers with a specific Bios Manufacturer.
Wildcard search.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BiosVersion
Return computers with a specific BIOS Version.
This is a string search and a wildcard.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LocalUserAccounts
Return computers where certain local user accounts are present

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RemoteAgentVersionMin
Return computers where the RemoteAgentVersion \>= the specified value.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RemoteAgentVersionMax
Return computers where the RemoteAgentVersion \<= the specified value.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Condition
A custom condition to build searches that can be used to search for specific things.
Supported operators are '=', 'eq', '\>', '\>=', '\<', '\<=', 'and', 'or', '()', 'like', 'contains', 'in', 'not'.
The 'not' operator is only used with 'in', 'like', or 'contains'.
The '=' and 'eq' operator are the same.
String values can be surrounded with either single or double quotes.
IE (RemoteAgentLastContact \<= 2019-12-18T00:50:19.575Z)
Boolean values are specified as 'true' or 'false'.
Parenthesis can be used to control the order of operations and group conditions.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeFields
A comma separated list of fields that you want including in the returned computer object.

```yaml
Type: String
Parameter Sets: IncludeFields
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeFields
A comma separated list of fields that you want excluding in the returned computer object.

```yaml
Type: String
Parameter Sets: ExcludeFields
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResultSetSize
{{ Fill ResultSetSize Description }}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OrderBy
A comma separated list of fields that you want to order by finishing with either an asc or desc.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Computer Objects
## NOTES
Version:        1.0
Author:         Gavin Stone
Creation Date:  2019-01-20
Purpose/Change: Initial script development

Update Date:    2020-07-03
Author:         Darren White
Purpose/Change: Updates to support custom conditions plus parameter conditions, ID will be returned in ComputerIO property

## RELATED LINKS
