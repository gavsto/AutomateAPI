---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Invoke-ControlAPIMaster

## SYNOPSIS
Internal function used to make API calls

## SYNTAX

```
Invoke-ControlAPIMaster [-Arguments] <Object> [[-MaxRetry] <Int32>] [<CommonParameters>]
```

## DESCRIPTION
Internal function used to make API calls

## EXAMPLES

### EXAMPLE 1
```
$APIRequest = @{
```

'URI' = "ReportService.ashx/GenerateReportForAutomate"
    'Body' = ConvertTo-Json @("Session","",@('SessionID','SessionType','Name','CreatedTime'),"NOT IsEnded", "", 10000)
}
$AllSessions = Invoke-ControlAPIMaster -Arguments $APIRequest

## PARAMETERS

### -Arguments
Required parameters for the API call
A URI without a leading "/" will default to the Automate Extension path.
A URI without a protocol/server will default to the Control Server established by Connect-ControlAPI

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxRetry
{{ Fill MaxRetry Description }}

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: 5
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### The returned results from the API call
## NOTES
Version:        1.0
Author:         Darren White
Creation Date:  2020-08-01
Purpose/Change: Initial script development

Version:        1.1.0
Author:         Darren White
Creation Date:  2020-12-01
Purpose/Change: Include values in $Script:CWCHeaders variable in request

## RELATED LINKS
