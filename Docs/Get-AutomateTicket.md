---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Get-AutomateTicket

## SYNOPSIS
Get Ticket information out of the Automate API

## SYNTAX

### IndividualTicket
```
Get-AutomateTicket [[-TicketID] <Int32[]>] [<CommonParameters>]
```

### IndividualComputerTicket
```
Get-AutomateTicket [-ComputerID <Int32[]>] [<CommonParameters>]
```

### AllResults
```
Get-AutomateTicket [-AllTickets] [-IncludeFields <String>] [-ExcludeFields <String>] [-OrderBy <String>]
 [<CommonParameters>]
```

### ByCondition
```
Get-AutomateTicket [-Condition <String>] [-IncludeFields <String>] [-ExcludeFields <String>]
 [-OrderBy <String>] [<CommonParameters>]
```

### CustomBuiltCondition
```
Get-AutomateTicket [-IncludeFields <String>] [-ExcludeFields <String>] [-OrderBy <String>] [-StatusID <Int32>]
 [-StatusName <String>] [-Subject <String>] [-PriorityID <Int32>] [-PriorityName <String>] [-From <String>]
 [-CC <String>] [-SupportLevel <Int32>] [-ExternalID <Int32>] [-UnsyncedTickets] [<CommonParameters>]
```

## DESCRIPTION
Connects to the Automate API and returns one or more full ticket objects

## EXAMPLES

### EXAMPLE 1
```
Get-AutomateTicket -AllTickets
```

## PARAMETERS

### -TicketID
{{ Fill TicketID Description }}

```yaml
Type: Int32[]
Parameter Sets: IndividualTicket
Aliases: ID

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ComputerID
{{ Fill ComputerID Description }}

```yaml
Type: Int32[]
Parameter Sets: IndividualComputerTicket
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllTickets
Returns all tickets in Automate, regardless of amount

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
A comma separated list of fields that you want including in the returned ticket object.

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
A comma separated list of fields that you want excluding in the returned ticket object.

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

### -StatusID
{{ Fill StatusID Description }}

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

### -StatusName
{{ Fill StatusName Description }}

```yaml
Type: String
Parameter Sets: CustomBuiltCondition
Aliases: Status

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Subject
{{ Fill Subject Description }}

```yaml
Type: String
Parameter Sets: CustomBuiltCondition
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PriorityID
{{ Fill PriorityID Description }}

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

### -PriorityName
{{ Fill PriorityName Description }}

```yaml
Type: String
Parameter Sets: CustomBuiltCondition
Aliases: Priority

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -From
{{ Fill From Description }}

```yaml
Type: String
Parameter Sets: CustomBuiltCondition
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CC
{{ Fill CC Description }}

```yaml
Type: String
Parameter Sets: CustomBuiltCondition
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SupportLevel
{{ Fill SupportLevel Description }}

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

### -ExternalID
{{ Fill ExternalID Description }}

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

### -UnsyncedTickets
{{ Fill UnsyncedTickets Description }}

```yaml
Type: SwitchParameter
Parameter Sets: CustomBuiltCondition
Aliases: ManageUnsycned

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Version:        1.0
Author:         Gavin Stone
Creation Date:  2019-02-25
Purpose/Change: Initial script development

## RELATED LINKS
