---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Connect-ControlSession

## SYNOPSIS
Will open a ConnectWise Control Remote Support session against a given machine.

## SYNTAX

### Name (Default)
```
Connect-ControlSession [-ComputerName] <String[]> [<CommonParameters>]
```

### ID
```
Connect-ControlSession [-ComputerID] <Int32[]> [<CommonParameters>]
```

### pipeline
```
Connect-ControlSession -ID <Int32[]> -ComputerObjects <Object> [<CommonParameters>]
```

### sessionid
```
Connect-ControlSession [-SessionID <Guid[]>] [-ConnectAs <String>] [<CommonParameters>]
```

## DESCRIPTION
Will open a ConnectWise Control Remote Support session against a given machine.

## EXAMPLES

### EXAMPLE 1
```
Connect-ControlSession -ComputerName TestComputer
```

### EXAMPLE 2
```
Connect-ControlSession -ComputerId 123
```

### EXAMPLE 3
```
Get-AutomateComputer -ComputerID 5 | Connect-ControlSession
```

## PARAMETERS

### -ComputerName
The Automate computer name to connect to

```yaml
Type: String[]
Parameter Sets: Name
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ComputerID
The Automate ComputerID to connect to

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

### -ID
Taken from the Pipeline, IE Get-AutomateComputer -ComputerID 5 | Connect-ControlSession

```yaml
Type: Int32[]
Parameter Sets: pipeline
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -SessionID
{{ Fill SessionID Description }}

```yaml
Type: Guid[]
Parameter Sets: sessionid
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -ConnectAs
{{ Fill ConnectAs Description }}

```yaml
Type: String
Parameter Sets: sessionid
Aliases:

Required: False
Position: Named
Default value: ($Script:ControlAPICredentials.Username)
Accept pipeline input: False
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

### None (opens a Connect Control Remote Support session URL, via a URL to the default browser)
## NOTES
Version:        1.0
Author:         Jason Rush
Creation Date:  2019-10-15
Purpose/Change: Initial script development

Version:        1.1.0
Author:         Darren White
Creation Date:  2020-12-08
Purpose/Change: Support connection to specified sessionid

## RELATED LINKS
