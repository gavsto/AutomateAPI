---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Invoke-AutomateCommand

## SYNOPSIS
Will issue a command against a given machine and return the results.

## SYNTAX

### ExecuteCommand (Default)
```
Invoke-AutomateCommand -ComputerID <Int32[]> -Command <String> [-WorkingDirectory <String>] [-PowerShell]
 [-TimeOut <Int32>] [-OfflineAction <Object>] [-BatchSize <Int32>] [-PassthroughObjects]
 [-ResultPropertyName <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### PassthroughObjects
```
Invoke-AutomateCommand -ComputerID <Int32[]> [-Command <String>] [-WorkingDirectory <String>] [-PowerShell]
 [-TimeOut <Int32>] [-OfflineAction <Object>] [-BatchSize <Int32>] [-PassthroughObjects]
 [-ResultPropertyName <String>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

### CommandID
```
Invoke-AutomateCommand -ComputerID <Int32[]> -CommandID <Int32> [-CommandParameters <Object>]
 [-TimeOut <Int32>] [-BatchSize <Int32>] [-PassthroughObjects] [-ResultPropertyName <String>] [-WhatIf]
 [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Will issue a command against a given machine and return the results.

## EXAMPLES

### EXAMPLE 1
```
Get-AutomateComputer -ComputerID 5 | Invoke-AutomateCommand -Powershell -Command "Get-Service"
```

Will execute PowerShell command "Get-Service" on the computer.

### EXAMPLE 2
```
Invoke-AutomateCommand -ComputerID @(3,4,5,6,7,8) -Command 'hostname' -OfflineAction Skip
```

Will return the hostnames of the online machines.

### EXAMPLE 3
```
$Results = Get-AutomateComputer -ClientName "Contoso" | Invoke-AutomateCommand -ResultPropertyName "OfficePlatform" -PowerShell -Command { Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration" -Name Platform } -PassthroughObjects
```

$Results | select ComputerName, OfficePlatform

### EXAMPLE 4
```
Invoke-AutomateCommand -ComputerID $ComputerID -CommandID 123 -Timeout 600000
```

Tells the remote agent to resend system inventory.

## PARAMETERS

### -ComputerID
The ComputerID for the machine you wish to connect to.
ComputerIDs can be provided via the pipeline.
IE - Get-AutomateComputer -ComputerID 5 | Invoke-AutomateCommand -Powershell -Command "Get-Service"

```yaml
Type: Int32[]
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
Parameter Sets: ExecuteCommand
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: PassthroughObjects
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WorkingDirectory
{{ Fill WorkingDirectory Description }}

```yaml
Type: String
Parameter Sets: ExecuteCommand, PassthroughObjects
Aliases:

Required: False
Position: Named
Default value: %WINDIR%\Temp
Accept pipeline input: False
Accept wildcard characters: False
```

### -PowerShell
{{ Fill PowerShell Description }}

```yaml
Type: SwitchParameter
Parameter Sets: ExecuteCommand, PassthroughObjects
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CommandID
{{ Fill CommandID Description }}

```yaml
Type: Int32
Parameter Sets: CommandID
Aliases:

Required: True
Position: Named
Default value: 2
Accept pipeline input: False
Accept wildcard characters: False
```

### -CommandParameters
{{ Fill CommandParameters Description }}

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
The amount of time in seconds to wait for the command results.
The default is 30 seconds.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 30000
Accept pipeline input: False
Accept wildcard characters: False
```

### -OfflineAction
{{ Fill OfflineAction Description }}

```yaml
Type: Object
Parameter Sets: ExecuteCommand, PassthroughObjects
Aliases:

Required: False
Position: Named
Default value: Wait
Accept pipeline input: False
Accept wildcard characters: False
```

### -BatchSize
Number of computers to invoke commands in parallel at a time.

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
## NOTES
Version:        1.0
Author:         Darren White
Creation Date:  2020-07-09
Purpose/Change: Initial script development

## RELATED LINKS
