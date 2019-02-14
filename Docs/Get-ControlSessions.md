---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Get-ControlSessions

## SYNOPSIS
Gets bulk session info from Control using the Automate Control Extension

## SYNTAX

```
Get-ControlSessions [[-SessionGroup] <String>] [<CommonParameters>]
```

## DESCRIPTION
Gets all Session GUIDs in Control and then gets each session info out 100 at a time

## EXAMPLES

### EXAMPLE 1
```
Get-ControlSesssions
```

## PARAMETERS

### -SessionGroup
Parameter group - defaults to All Machines

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: All Machines
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### Custom object of session details for all sessions
## NOTES

## RELATED LINKS
