---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Get-ControlSession

## SYNOPSIS
Gets bulk session info from Control using the Automate Control Reporting Extension

## SYNTAX

```
Get-ControlSession [[-SessionID] <Guid[]>] [[-SessionType] <String[]>] [[-IncludeProperty] <String[]>]
 [-IncludeCustomProperties] [-IncludeScreenShot] [-IncludeEnded] [<CommonParameters>]
```

## DESCRIPTION
Gets bulk session info from Control using the Automate Control Reporting Extension

## EXAMPLES

### EXAMPLE 1
```
Get-ControlSession -SessionID 00000000-0000-0000-0000-000000000000
```

Return an object with the SessionID,OnlineStatusControl,LastConnected properties

### EXAMPLE 2
```
$SessionList=Get-ControlSession -IncludeProperty 'CreatedTime','GuestMachineSerialNumber','GuestHardwareNetworkAddress','Name' -IncludeCustomProperties
```

$ExtraSessions=$SessionList | Group-Object -Property CustomProperty1,Name,GuestMachineSerialNumber,GuestHardwareNetworkAddress | Foreach-Object {$_.Group|Sort-Object CreatedTime -Desc | Select-Object -skip 1}
$ExtraSessions | Invoke-ControlCommand -CommandID 21

Will return session information to find duplicate sessions (same CustomProperty1,Name,GuestMachineSerialNumber,GuestHardwareNetworkAddress), and end all but the most recently created.

### EXAMPLE 3
```
Get-ControlSession -SessionID 00000000-0000-0000-0000-000000000000 -IncludeScreenShot | Foreach-Object {If ($_.GuestScreenshotContent) {Set-Content -Path "sc-$($_.SessionID).jpg" -value ([Convert]::FromBase64String($_.GuestScreenshotContent)) -Encoding Byte}}
```

Will retrieve and save the session screenshot

## PARAMETERS

### -SessionID
The Session(s) you want information on.
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

### -SessionType
{{ Fill SessionType Description }}

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: Access
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeProperty
Specify additional Fields to be returned from the Session report endpoint as properties.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeCustomProperties
Returns CustomProperty1 through CustomProperty8 on the output object

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

### -IncludeScreenShot
Returns GuestScreenshotContent,GuestScreenshotContentHash,GuestScreenshotContentType on the output object

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

### -IncludeEnded
Include results for sessions that existed but have been ended.

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

### None
## OUTPUTS

### Custom object of session details
## NOTES
Version:        1.6.1
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

Update Date:    2020-07-04
Author:         Darren White
Purpose/Change: LastConnected type will be DateTime.
An output will be returned for all inputs as individual objects.

Update Date:    2020-07-20
Author:         Darren White
Purpose/Change: Include valid sessions even if there are no connection events in history.

Update Date:    2020-07-28
Author:         Darren White
Purpose/Change: Added IncludeEnded, IncludeCustomProperties, IncludeProperty parameters to optionally return additional information

## RELATED LINKS
