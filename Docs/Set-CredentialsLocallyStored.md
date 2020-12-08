---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Set-CredentialsLocallyStored

## SYNOPSIS
Sets credential objects on a server that has never had them before

## SYNTAX

### Automate
```
Set-CredentialsLocallyStored [-Automate] [-SaveCurrent] [-CredentialDirectory <String>] [<CommonParameters>]
```

### All
```
Set-CredentialsLocallyStored [-All] [-SaveCurrent] [<CommonParameters>]
```

### Control
```
Set-CredentialsLocallyStored [-Control] [-SaveCurrent] [-CredentialDirectory <String>] [<CommonParameters>]
```

### Custom
```
Set-CredentialsLocallyStored [-Custom] -CredentialDisplayName <String> -CredentialDirectory <String>
 [<CommonParameters>]
```

## DESCRIPTION
This function takes a Powershell script and sets credentials on the local disk encrypted with the local system

## EXAMPLES

### EXAMPLE 1
```
Set-CredentialsLocallyStored -Automate
```

### EXAMPLE 2
```
Set-CredentialsLocallyStored -Custom -CredentialDisplayName 'Office365' -CredentialDirectory "C:\Credentials"
```

## PARAMETERS

### -Automate
{{ Fill Automate Description }}

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

### -All
Will save both Automate and Control credentials

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

### -Control
{{ Fill Control Description }}

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

### -Custom
{{ Fill Custom Description }}

```yaml
Type: SwitchParameter
Parameter Sets: Custom
Aliases:

Required: True
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CredentialDisplayName
{{ Fill CredentialDisplayName Description }}

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

### -SaveCurrent
{{ Fill SaveCurrent Description }}

```yaml
Type: SwitchParameter
Parameter Sets: Automate, All, Control
Aliases: Save

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -CredentialDirectory
{{ Fill CredentialDirectory Description }}

```yaml
Type: String
Parameter Sets: Automate, Control
Aliases:

Required: False
Position: Named
Default value: "$($env:USERPROFILE)\AutomateAPI\"
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: Custom
Aliases:

Required: True
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

## RELATED LINKS
