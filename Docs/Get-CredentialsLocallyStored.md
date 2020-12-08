---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Get-CredentialsLocallyStored

## SYNOPSIS
Fetches credentials stored by the Set-CredentialsLocallStored function.

## SYNTAX

### Automate
```
Get-CredentialsLocallyStored [-Automate] [-CredentialDirectory <String>] [<CommonParameters>]
```

### Control
```
Get-CredentialsLocallyStored [-Control] [-CredentialDirectory <String>] [<CommonParameters>]
```

### All
```
Get-CredentialsLocallyStored [-All] [-CredentialDirectory <String>] [<CommonParameters>]
```

### Custom
```
Get-CredentialsLocallyStored -CredentialPath <String> [<CommonParameters>]
```

## DESCRIPTION
Defaults to "$($env:USERPROFILE)\AutomateAPI\" to fetch credentials

## EXAMPLES

### EXAMPLE 1
```
Import-Module AutomateAPI
```

if(!$Connected)
{
    try
    {
        Get-CredentialsLocallyStored -All
        $Connected = $true   
    }
    catch
    {
        try
        {
            Set-CredentialsLocallyStored -All
            $Connected = $true
        }
        catch
        {

        }
    }   
}

Get-AutomateComputer -ComputerID 171 | Get-AutomateControlInfo | Invoke-ControlCommand -Command { "Hello World" } -PowerShell

## PARAMETERS

### -Automate
When specified, fetches credentials from disk and loads them into the variables necessary for Automate related cmdlets to function

```yaml
Type: SwitchParameter
Parameter Sets: Automate
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Control
When specified, fetches credentials from disk and loads them into the variables necessary for Control related cmdlets to function

```yaml
Type: SwitchParameter
Parameter Sets: Control
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
When specified, fetches credentials from disk and loads them into the variables necessary for Automate and Control related cmdlets to function

```yaml
Type: SwitchParameter
Parameter Sets: All
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CredentialPath
Overrides default credential file path

```yaml
Type: String
Parameter Sets: Custom
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CredentialDirectory
Overrides default credential folder path

```yaml
Type: String
Parameter Sets: Automate, Control, All
Aliases:

Required: False
Position: Named
Default value: "$($env:USERPROFILE)\AutomateAPI\"
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Does not return a credential object!
You do not need to run Connect-AutomateAPI or Connect-ControlAPI, this method calls those methods to validate the credentials
To prevent reconnection each time, you will want to store the connection state yourself as shown in the above example

## RELATED LINKS
