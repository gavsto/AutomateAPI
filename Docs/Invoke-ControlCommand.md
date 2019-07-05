---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Invoke-ControlCommand

## SYNOPSIS
Will issue a command against a given machine and return the results.

## SYNTAX

```
Invoke-ControlCommand [-SessionID] <Guid[]> [[-Command] <String>] [[-TimeOut] <Int32>] [[-MaxLength] <Int32>]
 [-PowerShell] [[-OfflineAction] <Object>] [[-BatchSize] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Will issue a command against a given machine and return the results.

## EXAMPLES

### EXAMPLE 1
```
Get-AutomateComputer -ComputerID 5 | Get-AutomateControlInfo | Invoke-ControlCommand -Powershell -Command "Get-Service"
```

Will retrieve Computer Information from Automate, Get ControlSession data and merge with the input object, then call Get-Service on the computer.

### EXAMPLE 2
```
Invoke-ControlCommand -SessionID $SessionID -Command 'hostname'
```

Will return the hostname of the machine.

### EXAMPLE 3
```
Invoke-ControlCommand -SessionID $SessionID -TimeOut 120000 -Command 'iwr -UseBasicParsing "https://bit.ly/ltposh" | iex; Restart-LTService' -PowerShell
```

Will restart the Automate agent on the target machine.

## PARAMETERS

### -SessionID
The GUID identifier for the machine you wish to connect to.
You can retrieve session info with the 'Get-ControlSessions' commandlet
SessionIDs can be provided via the pipeline.
IE - Get-AutomateComputer -ComputerID 5 | Get-ControlSessions | Invoke-ControlCommand -Powershell -Command "Get-Service"

```yaml
Type: Guid[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Command
The command you wish to issue to the machine.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeOut
The amount of time in milliseconds that a command can execute.
The default is 10000 milliseconds.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: 10000
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxLength
The maximum number of bytes to return from the remote session.
The default is 5000 bytes.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: 5000
Accept pipeline input: False
Accept wildcard characters: False
```

### -PowerShell
Issues the command in a powershell session.

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

### -OfflineAction
{{Fill OfflineAction Description}}

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: 5
Default value: Wait
Accept pipeline input: False
Accept wildcard characters: False
```

### -BatchSize
Number of control sessions to invoke commands in parallel.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: 20
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### The output of the Command provided.
## NOTES
Version:        2.2
Author:         Chris Taylor
Modified By:    Gavin Stone 
Modified By:    Darren White
Creation Date:  1/20/2016
Purpose/Change: Initial script development

Update Date:    2019-02-19
Author:         Darren White
Purpose/Change: Enable Pipeline support.
Enable processing using Automate Control Extension.
The cached APIKey will be used if present.

Update Date:    2019-02-23
Author:         Darren White
Purpose/Change: Enable command batching against multiple sessions.
Added OfflineAction parameter.

Update Date:    2019-06-24
Author:         Darren White
Purpose/Change: Updates to process object returned by Get-ControlSessions

## RELATED LINKS
