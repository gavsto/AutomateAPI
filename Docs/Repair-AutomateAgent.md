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

### restart (Default)
```
Repair-AutomateAgent [-AutofixRestartService] [-AutomateControlStatusObject <Object>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

### reinstall
```
Repair-AutomateAgent [-AutofixReinstallService] [-AutomateControlStatusObject <Object>] [-WhatIf] [-Confirm]
 [<CommonParameters>]
```

## DESCRIPTION
Takes changed detected in Compare-AutomateControlStatus and performs a specified repair on them

## EXAMPLES

### EXAMPLE 1
```
Get-AutomateComputer -Online $False | Compare-AutomateControlStatus | Repair-AutomateAgent -AutofixRestartService
```

### EXAMPLE 2
```
Get-AutomateComputer -Online $False | Compare-AutomateControlStatus | Repair-AutomateAgent -AutofixReinstallService
```

## PARAMETERS

### -AutofixRestartService
Restarts Automate Services using the LabTech Powershell Github Module.
Confirmation is on for each by default, to disable add -Confirm:$False to the cmdlet.
Runs (new-object Net.WebClient).DownloadString('http://bit.ly/LTPoSh') | iex; Restart-LTService

```yaml
Type: SwitchParameter
Parameter Sets: restart
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AutofixReinstallService
Reinstalls Automate Services using the LabTech Powershell Github Module.
Confirmation is on for each by default, to disable add -Confirm:$False to the cmdlet.
(new-object Net.WebClient).DownloadString('http://bit.ly/LTPoSh') | iex; Reinstall-LTService

```yaml
Type: SwitchParameter
Parameter Sets: reinstall
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AutomateControlStatusObject
{{Fill AutomateControlStatusObject Description}}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
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
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Compare-AutomateControlStatus Object
## OUTPUTS

### Object containing result of job(s)
## NOTES

## RELATED LINKS
