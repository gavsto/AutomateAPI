---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Connect-ControlAPI

## SYNOPSIS
Adds credentials required to connect to the Control API

## SYNTAX

```
Connect-ControlAPI [[-ControlCredentials] <PSCredential>] [[-Server] <String>] [-Quiet] [<CommonParameters>]
```

## DESCRIPTION
Creates a Control hashtable in memory containing the server and username/password so that it can be used in other functions that connect to ConnectWise Control.
Unfortunately the Control API does not support 2FA.

## EXAMPLES

### EXAMPLE 1
```
All values will be prompted for one by one:
```

Connect-ControlAPI
All values needed to Automatically create appropriate output
Connect-ControlAPI -Server "https://control.rancorthebeast.com:8040" -ControlCredentials $CredentialsToPass

## PARAMETERS

### -ControlCredentials
Takes a standard powershell credential object, this can be built with $CredentialsToPass = Get-Credential, then pass $CredentialsToPass

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Server
The address to your Control Server.
Example 'https://control.rancorthebeast.com:8040'

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

### -Quiet
Will not output any standard logging messages

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
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### Two script variables with server and credentials
## NOTES
Version:        1.0
Author:         Gavin Stone
Creation Date:  20/01/2019
Purpose/Change: Initial script development

## RELATED LINKS
