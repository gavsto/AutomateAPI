---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Connect-AutomateAPI

## SYNOPSIS
Connect to the Automate API.

## SYNTAX

### refresh (Default)
```
Connect-AutomateAPI [-ClientID <String>] [-Server <String>] [-AuthorizationToken <String>] [-SkipCheck]
 [-Quiet] [<CommonParameters>]
```

### credential
```
Connect-AutomateAPI [-Credential <PSCredential>] [-ClientID <String>] [-Server <String>] [-SkipCheck]
 [-TwoFactorToken <String>] [-Force] [-Quiet] [<CommonParameters>]
```

### verify
```
Connect-AutomateAPI [-ClientID <String>] [-Server <String>] [-AuthorizationToken <String>] [-Verify] [-Quiet]
 [<CommonParameters>]
```

## DESCRIPTION
Connects to the Automate API and returns a bearer token which when passed with each requests grants up to an hours worth of access.

## EXAMPLES

### EXAMPLE 1
```
Connect-AutomateAPI -Server "rancor.hostedrmm.com" -Credential $CredentialObject -TwoFactorToken "999999" -ClientID '123123123-1234-1234-1234-123123123123'
```

### EXAMPLE 2
```
Connect-AutomateAPI -Quiet
```

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

### -ClientID
Takes the Client ID required by Automate v2020.11 for API access

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $Script:CWAClientID
Accept pipeline input: False
Accept wildcard characters: False
```

### -Server
The address to your Automate Server.
Example 'rancor.hostedrmm.com'

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: $Script:CWAServer
Accept pipeline input: False
Accept wildcard characters: False
```

### -AuthorizationToken
Used internally when quietly refreshing the Token

```yaml
Type: String
Parameter Sets: refresh, verify
Aliases:

Required: False
Position: Named
Default value: ($Script:CWAToken.Authorization -replace 'Bearer ','')
Accept pipeline input: False
Accept wildcard characters: False
```

### -SkipCheck
Used internally when quietly refreshing the Token

```yaml
Type: SwitchParameter
Parameter Sets: refresh, credential
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Verify
Specifies to test the current token, and if it is not valid attempt to obtain a new one using the current credentials.
Does not refresh (re-issue) the current token.

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

### -TwoFactorToken
Takes a string that represents the 2FA number

```yaml
Type: String
Parameter Sets: credential
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Force
Will not attempt to refresh a current session.
Force new connection with new parameters.

```yaml
Type: SwitchParameter
Parameter Sets: credential
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Quiet
Will not output any standard messages.
Returns $True if connection was successful.

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

### Three strings into Script variables, $CWAServer containing the server address, $CWACredentials containing the bearer token and $CWACredentialsExpirationDate containing the date the credentials expire
## NOTES
Version:        1.2.0
Author:         Gavin Stone
Creation Date:  2019-01-20
Purpose/Change: Initial script development

Update Date:    2019-02-12
Author:         Darren White
Purpose/Change: Credential and 2FA prompting is only if needed.
Supports Token Refresh.

Update Date:    2020-08-01
Purpose/Change: Change to use CWAIsConnected script variable to track connection state

Update Date:    2020-11-19
Author:         Brandon Fahnestock
Purpose/Change: ConnectWise Automate v2020.11 requires a registered ClientID for API access.
Added Support for ClientIDs

## RELATED LINKS
