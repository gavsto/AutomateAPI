---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Get-AutomateNetworkDevice

## SYNOPSIS
Get Network Device Information out of the Automate API

## SYNTAX

### IndividualNetworkDevice
```
Get-AutomateNetworkDevice [[-NetworkDeviceID] <Int32[]>] [<CommonParameters>]
```

### AllResults
```
Get-AutomateNetworkDevice [-AllNetworkDevices] [-IncludeFields <String>] [-ExcludeFields <String>]
 [-OrderBy <String>] [<CommonParameters>]
```

### ByCondition
```
Get-AutomateNetworkDevice [-Condition <String>] [-IncludeFields <String>] [-ExcludeFields <String>]
 [-OrderBy <String>] [<CommonParameters>]
```

### CustomBuiltCondition
```
Get-AutomateNetworkDevice [-IncludeFields <String>] [-ExcludeFields <String>] [-OrderBy <String>]
 [-ClientName <String>] [-ClientId <Int32>] [-LocationId <Int32>] [-LocationName <String>] [<CommonParameters>]
```

## DESCRIPTION
Connects to the Automate API and returns one or more full network device objects

## EXAMPLES

### EXAMPLE 1
```
Get-AutomateNetworkDevice -AllNetworkDevices
```

### EXAMPLE 2
```
Get-AutomateNetworkDevice -ClientName "Rancor"
```

### EXAMPLE 3
```
Get-AutomateNetworkDevice -Condition "(Type != 'Workstation')"
```

## PARAMETERS

### -NetworkDeviceID
{{ Fill NetworkDeviceID Description }}

```yaml
Type: Int32[]
Parameter Sets: IndividualNetworkDevice
Aliases: ID

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllNetworkDevices
Returns all computers in Automate, regardless of amount

```yaml
Type: SwitchParameter
Parameter Sets: AllResults
Aliases:

Required: False
Position: Named
Default value: False
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
Parameter Sets: ByCondition
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
Parameter Sets: AllResults, ByCondition, CustomBuiltCondition
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
Parameter Sets: AllResults, ByCondition, CustomBuiltCondition
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
Parameter Sets: AllResults, ByCondition, CustomBuiltCondition
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClientName
Client name to search for, uses wildcards so full client name is not needed

```yaml
Type: String
Parameter Sets: CustomBuiltCondition
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
Parameter Sets: CustomBuiltCondition
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
Parameter Sets: CustomBuiltCondition
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
Parameter Sets: CustomBuiltCondition
Aliases: Location

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

### Network Device Objects
## NOTES
Version:        1.0
Author:         Gavin Stone
Creation Date:  2020-10-05
Purpose/Change: Initial script development

## RELATED LINKS
