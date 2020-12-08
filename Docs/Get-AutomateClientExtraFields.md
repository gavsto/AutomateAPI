---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Get-AutomateClientExtraFields

## SYNOPSIS
Get Extra Data Fields (EDFs) for customer.

## SYNTAX

### Title (Default)
```
Get-AutomateClientExtraFields [-ClientId] <Int32> [-Title <String>] [-ValueOnly <Boolean>] [<CommonParameters>]
```

### EdfId
```
Get-AutomateClientExtraFields [-ClientId] <Int32> [-ExtraFieldDefinitionId <Int32>] [-ValueOnly <Boolean>]
 [<CommonParameters>]
```

## DESCRIPTION
Connects to the Automate API and returns EDFs for specified client.

## EXAMPLES

### EXAMPLE 1
```
Get-AutomateClientExtraFields -ClientId 102
```

### EXAMPLE 2
```
Get-AutomateClientExtraFields -ClientId 102 -Title 'PatchingSchedule' -ValueOnly $true
```

## PARAMETERS

### -ClientId
Returns all EDFs for the client.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -Title
Filters the EDFs by specified EDF title.

```yaml
Type: String
Parameter Sets: Title
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExtraFieldDefinitionId
Filters the EDFs by specified EDF ID.

```yaml
Type: Int32
Parameter Sets: EdfId
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ValueOnly
Retrieves only the value of the EDF.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### EDF objects
## NOTES
Version:        1.0
Author:         Kamil Procyszyn
Creation Date:  2020-04-23
Purpose/Change: Initial function development

## RELATED LINKS
