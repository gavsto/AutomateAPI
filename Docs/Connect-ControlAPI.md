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

### credential (Default)
```
Connect-ControlAPI [-Credential <PSCredential>] [-Server <String>] [-SkipCheck] [-Quiet] [<CommonParameters>]
```

### apikey
```
Connect-ControlAPI [-Server <String>] [-APIKey <Object>] [-SkipCheck] [-Quiet] [<CommonParameters>]
```

### verify
```
Connect-ControlAPI [-Verify] [-Quiet] [<CommonParameters>]
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
Connect-ControlAPI -Server "https://control.rancorthebeast.com:8040" -Credential $CredentialsToPass

## PARAMETERS

### -Credential
Takes a standard powershell credential object, this can be built with $CredentialsToPass = Get-Credential, then pass $CredentialsToPass

```yaml
Type: PSCredential
Parameter Sets: credential
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Server
The address to your Control Server.
Example 'https://control.rancorthebeast.com:8040'

```yaml
Type: String
Parameter Sets: credential, apikey
Aliases:

Required: False
Position: Named
Default value: $Script:ControlServer
Accept pipeline input: False
Accept wildcard characters: False
```

### -APIKey
Automate APIKey for Control Extension

```yaml
Type: Object
Parameter Sets: apikey
Aliases:

Required: False
Position: Named
Default value: ([SecureString]$Script:ControlAPIKey)
Accept pipeline input: False
Accept wildcard characters: False
```

### -Verify
Attempt to verify Cached API key or Credentials.
Invalid results will be removed.

```yaml
Type: SwitchParameter
Parameter Sets: verify
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipCheck
Used to set Server URL and Credentials without testing.

```yaml
Type: SwitchParameter
Parameter Sets: credential, apikey
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Quiet
Will not output any standard logging messages.
Function will returns True or False.

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

## OUTPUTS

### Sets script variables with Server URL and Credentials or ApiKey.
## NOTES
Version:        1.0
Author:         Gavin Stone
Creation Date:  2019-01-20
Purpose/Change: Initial script development

Version:        1.1
Author:         Gavin Stone
Creation Date:  2019-06-22
Purpose/Change: The previous function was far too complex.
No-one could debug it and a lot of it was unnecessary.
I have greatly simplified it.

Version:        1.2
Author:         Darren White
Creation Date:  2019-06-24
Purpose/Change: Added support for APIKey authentication.
The new function was not complex enough.

Version:        1.2.1
Author:         Darren White
Creation Date:  2020-12-01
Purpose/Change: Added origin to standard header

Version:        1.2.2
Author:         Darren White
Creation Date:  2021-01-12
Purpose/Change: Support custom Server URI path
                Reference: https://docs.connectwise.com/ConnectWise_Control_Documentation/On-premises/Get_started_with_ConnectWise_Control_On-Premise/Change_ports_for_an_on-premises_installation

## RELATED LINKS
