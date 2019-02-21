---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Compare-AutomateControlStatus

## SYNOPSIS
Compares Automate Online Status with Control, and outputs all machines online in Control and not in Automate

## SYNTAX

```
Compare-AutomateControlStatus [[-ComputerObject] <Object>] [-AllResults] [-Quiet] [<CommonParameters>]
```

## DESCRIPTION
Compares Automate Online Status with Control, and outputs all machines online in Control and not in Automate

## EXAMPLES

### EXAMPLE 1
```
Get-AutomateComputer -ComputerID 5 | Compare-AutomateControlStatus
```

### EXAMPLE 2
```
Get-AutomateComputer -Online $False | Compare-AutomateControlStatus
```

## PARAMETERS

### -ComputerObject
Can be taken from the pipeline in the form of Get-AutomateComputer -ComputerID 5 | Compare-AutomateControlStatus

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -AllResults
Instead of outputting a comparison it outputs everything, which include two columns indicating online status

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Quiet
Doesn't output any log messages

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### An object containing Online status for Control and Automate
## NOTES
Version:        1.1
Author:         Gavin Stone
Creation Date:  20/01/2019
Purpose/Change: Initial script development

## RELATED LINKS
