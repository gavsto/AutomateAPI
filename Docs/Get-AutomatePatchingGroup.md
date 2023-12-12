---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Get-AutomatePatchingGroup

## SYNOPSIS
Get Group Patching information out of the Automate API

## SYNTAX

### IndividualGroup
```
Get-AutomatePatchingGroup [[-GroupId] <Int32[]>] [<CommonParameters>]
```

### AllResults
```
Get-AutomatePatchingGroup [-AllGroups] [-IncludeFields <String>] [-ExcludeFields <String>] [-OrderBy <String>]
 [<CommonParameters>]
```

### ByCondition
```
Get-AutomatePatchingGroup [-Condition <String>] [-IncludeFields <String>] [-ExcludeFields <String>]
 [-OrderBy <String>] [<CommonParameters>]
```

### CustomBuiltCondition
```
Get-AutomatePatchingGroup [-IncludeFields <String>] [-ExcludeFields <String>] [-OrderBy <String>]
 [-GroupName <String>] [<CommonParameters>]
```

## DESCRIPTION
Connects to the Automate API and returns one or more full Patching Group objects

## EXAMPLES

### EXAMPLE 1
```
Get-AutomatePatchingGroup -AllGroups
```

### EXAMPLE 2
```
Get-AutomatePatchingGroup -GroupId 4
```

### EXAMPLE 3
```
Get-AutomatePatchingGroup -GroupName "PatchingGroup1"
```

### EXAMPLE 4
```
Get-AutomatePatchingGroup -Condition "(MicrosoftUpdatePolicy/Name = 'MSUPDATE')"
```

## PARAMETERS

### -GroupId
GroupId to search for, integer, -GroupId 1

```yaml
Type: Int32[]
Parameter Sets: IndividualGroup
Aliases: ID

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllGroups
Returns all Patching Groups in Automate, regardless of amount

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
{{ Fill IncludeFields Description }}

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
{{ Fill ExcludeFields Description }}

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

### -GroupName
Group name to search for, uses wildcards so full Group name is not needed

```yaml
Type: String
Parameter Sets: CustomBuiltCondition
Aliases: Group

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

### Client objects
## NOTES
Version:        1.0
Author:         Marcus Tedde
Creation Date:  2023-12-11
Purpose/Change: Initial script development

## RELATED LINKS
