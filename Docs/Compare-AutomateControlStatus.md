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
Compare-AutomateControlStatus [[-ComputerObject] <Object>] [-AllResults] [-Force] [-Quiet] [<CommonParameters>]
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
Instead of outputting only status differences it outputs all records

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

### -Force
Instead of retrieving only known Control Sessions, all Control Sessions will be returned.
ComputerID will be 0 for extra sessions

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
Doesn't output any messages

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
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### An object containing properties for Online status in Control and Automate
## NOTES
Version:        1.5.0
Author:         Gavin Stone
Creation Date:  2019-01-20
Purpose/Change: Initial script development

Update Date:    2019-02-23
Author:         Darren White
Purpose/Change: Added SessionID parameter to Get-ControlSessions call.

Update Date:    2019-02-26
Author:         Darren White
Purpose/Change: Reuse incoming object to preserve properties passed on the pipeline.

Update Date:    2019-06-24
Author:         Darren White
Purpose/Change: Update to use objects returned by Get-ControlSessions

Update Date:    2020-08-13
Author:         Darren White
Purpose/Change: -Force to include all Control Sessions, even if not found in Automate.

## RELATED LINKS
