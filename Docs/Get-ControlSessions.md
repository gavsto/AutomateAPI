---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Get-ControlSessions

## SYNOPSIS
Gets bulk session info from Control using the Automate Control Reporting Extension

## SYNTAX

```
Get-ControlSessions [[-SessionID] <Guid[]>] [<CommonParameters>]
```

## DESCRIPTION
Gets bulk session info from Control using the Automate Control Reporting Extension

## EXAMPLES

### EXAMPLE 1
```
Get-ControlSesssions
```

## PARAMETERS

### -SessionID
The GUID identifier(s) for the machine you want status information on.
If not provided, all sessions will be returned.

```yaml
Type: Guid[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
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
Version:        1.4
Author:         Gavin Stone 
Modified By:    Darren White
Purpose/Change: Initial script development

Update Date:    2019-02-23
Author:         Darren White
Purpose/Change: Added SessionID parameter to return information only for requested sessions.

Update Date:    2019-02-26
Author:         Darren White
Purpose/Change: Include LastConnected value if reported.

Update Date:    2019-06-24
Author:         Darren White
Purpose/Change: Modified output to be collection of objects instead of a hastable.

## RELATED LINKS
