---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Get-AutomateControlInfo

## SYNOPSIS
Retrieve data from Automate API Control Extension

## SYNTAX

### ID (Default)
```
Get-AutomateControlInfo [-ComputerID] <Int32[]> [<CommonParameters>]
```

### pipeline
```
Get-AutomateControlInfo -ComputerObjects <Object> [<CommonParameters>]
```

## DESCRIPTION
Connects to the Automate API Control Extension and returns an object with Control Session data

## EXAMPLES

### EXAMPLE 1
```
Get-AutomateControlInfo -ComputerId 123
```

## PARAMETERS

### -ComputerID
The Automate ComputerID to retrieve information on

```yaml
Type: Int32[]
Parameter Sets: ID
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ComputerObjects
Used for Pipeline input from Get-AutomateComputer

```yaml
Type: Object
Parameter Sets: pipeline
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Custom object with the ComputerID and Control SessionID. Additional properties from the return data will be included.
## NOTES
Version:        1.2.1
Author:         Gavin Stone
Creation Date:  2019-01-20
Purpose/Change: Initial script development

Update Date:    2019-02-12
Author:         Darren White
Purpose/Change: Modified returned object data

Update Date:    2020-07-20
Author:         Darren White
Purpose/Change: Standardized on ComputerID for parameter name

Update Date:    2020-08-04
Author:         Darren White
Purpose/Change: Use Get-AutomateAPIGeneric internally, Error handling

## RELATED LINKS
