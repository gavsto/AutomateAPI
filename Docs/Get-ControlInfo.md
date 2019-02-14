---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Get-ControlInfo

## SYNOPSIS
Retrieve data from Automate API Control Extension

## SYNTAX

```
Get-ControlInfo [-ComputerID] <Int16[]> [<CommonParameters>]
```

## DESCRIPTION
Connects to the Automate API Control Extension and returns an object with Control Session data

## EXAMPLES

### EXAMPLE 1
```
Get-ControlInfo -ComputerId 123
```

## PARAMETERS

### -ComputerID
The Automate ComputerID to retrieve information on

```yaml
Type: Int16[]
Parameter Sets: (All)
Aliases: Id

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Custom object with the ComputerID and Control SessionID. Additional properties from the return data will be included.
## NOTES
Version:        1.0
Author:         Gavin Stone
Creation Date:  2019-01-20
Purpose/Change: Initial script development

Update Date:    2019-02-12
Author:         Darren White
Purpose/Change: Modified returned object data

## RELATED LINKS
