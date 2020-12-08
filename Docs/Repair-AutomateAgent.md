---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Repair-AutomateAgent

## SYNOPSIS
Takes changed detected in Compare-AutomateControlStatus and performs a specified repair on them

## SYNTAX

```
Repair-AutomateAgent [[-Action] <String>] [[-BatchSize] <Int32>] [[-LTPoShURI] <String>]
 [-AutomateControlStatusObject] <Object> [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Takes changed detected in Compare-AutomateControlStatus and performs a specified repair on them

## EXAMPLES

### EXAMPLE 1
```
Get-AutomateComputer -Online $False | Compare-AutomateControlStatus | Repair-AutomateAgent -Action Check
```

### EXAMPLE 2
```
Get-AutomateComputer -Online $False | Compare-AutomateControlStatus | Repair-AutomateAgent -Action Restart
```

## PARAMETERS

### -Action
Takes either Update, Restart, Reinstall or Check

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: Check
Accept pipeline input: False
Accept wildcard characters: False
```

### -BatchSize
When multiple jobs are run, they run in Parallel.
Batch size determines how many jobs can run at once.
Default is 10

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 10
Accept pipeline input: False
Accept wildcard characters: False
```

### -LTPoShURI
If you do not wish to use the LT Posh module on GitHub you can use your own link to the LTPosh Module with this parameter

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: $Script:LTPoShURI
Accept pipeline input: False
Accept wildcard characters: False
```

### -AutomateControlStatusObject
Object taken from the Pipeline from Compare-AutomateControlStatus

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 4
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Compare-AutomateControlStatus Object
## OUTPUTS

### Object containing result of job(s)
## NOTES

## RELATED LINKS
