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
Invoke-ControlCommand [[-Server] <String>] [[-Credentials] <PSCredential>] [-SessionID] <Guid[]>
 [[-Command] <String>] [[-TimeOut] <Int32>] [-PowerShell] [[-MaxLength] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Will issue a command against a given machine and return the results.

## EXAMPLES

### EXAMPLE 1
```
Get-AutomateComputer -ComputerID 5 | Get-ControlSessions | Invoke-ControlCommand -Powershell -Command "Get-Service"
```

### EXAMPLE 2
```
Invoke-ControlCommand -SessionID $SessionID -Command 'hostname'
```

Will return the hostname of the machine.

### EXAMPLE 3
```
Invoke-ControlCommand -SessionID $SessionID -User $User -Password $Password -TimeOut 120000 -Command 'iwr -UseBasicParsing "https://bit.ly/ltposh" | iex; Restart-LTService' -PowerShell
```

Will restart the Automate agent on the target machine.

## PARAMETERS

### -Server
{{Fill Server Description}}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: $Script:ControlServer
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credentials
{{Fill Credentials Description}}

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: $Script:ControlAPICredentials
Accept pipeline input: False
Accept wildcard characters: False
```

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
Position: 3
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
Position: 4
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
Position: 5
Default value: 10000
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

### -MaxLength
{{Fill MaxLength Description}}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 6
Default value: 5000
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
Version:        2.0
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

## RELATED LINKS
