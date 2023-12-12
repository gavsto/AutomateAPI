---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Get-AutomateComputerServices

## SYNOPSIS
Get Computer's Services information out of the Automate API

## SYNTAX

## DESCRIPTION
Connects to the Automate API and returns all services for specified computer object.

## EXAMPLES

### EXAMPLE 1
```
Get-AutomateComputerServices -ComputerID 1
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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Computer Services Objects
## NOTES
Version:        1.0
Author:         Marcus Tedde
Creation Date:  2023-12-12
Purpose/Change: Initial script development 

## RELATED LINKS
