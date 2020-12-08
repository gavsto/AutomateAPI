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

### ExecuteCommand (Default)
```
Invoke-ControlCommand -SessionID <Guid[]> [-BatchSize <Int32>] [-PassthroughObjects]
 [-ResultPropertyName <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### ExecuteCommand PassthroughObjects
```
Invoke-ControlCommand -SessionID <Guid[]> -Command <String> [-TimeOut <Int32>] [-MaxLength <Int32>]
 [-PowerShell] [-OfflineAction <Object>] [-BatchSize <Int32>] [-PassthroughObjects]
 [-ResultPropertyName <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### CommandID
```
Invoke-ControlCommand -SessionID <Guid[]> -CommandID <Int32> [-CommandBody <Object>] [-BatchSize <Int32>]
 [-PassthroughObjects] [-ResultPropertyName <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Will issue a command against a given machine and return the results.

## EXAMPLES

### EXAMPLE 1
```
Invoke-ControlCommand -SessionID $SessionID -Command 'hostname'
```

Will return the hostname of the machine.

### EXAMPLE 2
```
Invoke-ControlCommand -SessionID $SessionID -TimeOut 120000 -Command 'iwr -UseBasicParsing "https://bit.ly/ltposh" | iex; Restart-LTService' -PowerShell
```

Will restart the Automate agent on the target machine.

### EXAMPLE 3
```
Invoke-ControlCommand -SessionID $SessionID -CommandID 40
```

Will tell the control service to Reinstall (update)

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
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Command
The command you wish to issue to the machine.

```yaml
Type: String
Parameter Sets: ExecuteCommand PassthroughObjects
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CommandID
The command ID (Control SessionEventType) to issue to the machine.
When using -CommandID the command will be queued but results will not be checked for or returned.
The "Wait" OfflineAction is treated like "Queue". 
For CommandID values see https://docs.connectwise.com/ConnectWise_Control_Documentation/Developers/Session_Manager_API_Reference/Enumerations

```yaml
Type: Int32
Parameter Sets: CommandID
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -CommandBody
The command body.
Used with the -CommandID parameter.

```yaml
Type: Object
Parameter Sets: CommandID
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeOut
The amount of time in milliseconds that a command can execute.
The default is 10000 milliseconds.

```yaml
Type: Int32
Parameter Sets: ExecuteCommand PassthroughObjects
Aliases:

Required: False
Position: Named
Default value: 10000
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxLength
The maximum number of bytes to return from the remote session.
The default is 5000 bytes.

```yaml
Type: Int32
Parameter Sets: ExecuteCommand PassthroughObjects
Aliases:

Required: False
Position: Named
Default value: 5000
Accept pipeline input: False
Accept wildcard characters: False
```

### -PowerShell
Issues the command in a powershell session.

```yaml
Type: SwitchParameter
Parameter Sets: ExecuteCommand PassthroughObjects
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -OfflineAction
Specifies the action to take if the session is offline.
- Wait : Will queue the command and wait up to the timeout specified for a response.
- Queue : Will queue the command but not wait for any response.
- Skip : Will not queue the command to the session.

```yaml
Type: Object
Parameter Sets: ExecuteCommand PassthroughObjects
Aliases:

Required: False
Position: Named
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
Position: Named
Default value: 20
Accept pipeline input: False
Accept wildcard characters: False
```

### -PassthroughObjects
{{ Fill PassthroughObjects Description }}

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

### -ResultPropertyName
String containing the name of the member you would like to add to the input pipeline object that will hold the result of this command

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Output
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
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### The output of the Command provided.
### When -CommandID is used, the output will only indicate if the commandid was queued or not.
## NOTES
Version:        2.3.1
Author:         Chris Taylor
Modified By:    Gavin Stone
Modified By:    Darren White
Creation Date:  2016-01-20
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

Update Date:    2019-08-20
Author:         Darren Kattan
Purpose/Change: Added ability to retain Computer object passed in from pipeline and append result of script to a named member of the computer object

Update Date:    2020-07-04
Author:         Darren White
Purpose/Change: Removed object processing on the remote host.
Added -CommandID support

Update Date:    2020-08-01
Author:         Darren White
Purpose/Change: Use Invoke-ControlAPIMaster

## RELATED LINKS
