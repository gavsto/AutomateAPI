---
external help file: AutomateAPI-help.xml
Module Name: AutomateAPI
online version:
schema: 2.0.0
---

# Get-AutomateAPIGeneric

## SYNOPSIS
Internal function used to make generic API calls

## SYNTAX

### AllResults (Default)
```
Get-AutomateAPIGeneric [-AllResults] [-ResultSetSize <Object>] -Endpoint <String> [-OrderBy <String>]
 [-Condition <String>] [-IncludeFields <String>] [-ExcludeFields <String>] [-IDs <String>] [-Expand <String>]
 [<CommonParameters>]
```

### Page
```
Get-AutomateAPIGeneric [-PageSize <Int32>] [-Page <Int32>] -Endpoint <String> [-OrderBy <String>]
 [-Condition <String>] [-IncludeFields <String>] [-ExcludeFields <String>] [-IDs <String>] [-Expand <String>]
 [<CommonParameters>]
```

## DESCRIPTION
Internal function used to make generic API calls

## EXAMPLES

### EXAMPLE 1
```
Get-AutomateAPIGeneric -Page 1 -Condition "RemoteAgentLastContact <= 2019-12-18T00:50:19.575Z" -Endpoint "computers"
```

## PARAMETERS

### -PageSize
The page size of the results that come back from the API - limit this when needed

```yaml
Type: Int32
Parameter Sets: Page
Aliases:

Required: False
Position: Named
Default value: 1000
Accept pipeline input: False
Accept wildcard characters: False
```

### -Page
Brings back a particular page as defined

```yaml
Type: Int32
Parameter Sets: Page
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -AllResults
Will bring back all results for a particular query with no concern for result set size

```yaml
Type: SwitchParameter
Parameter Sets: AllResults
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ResultSetSize
{{ Fill ResultSetSize Description }}

```yaml
Type: Object
Parameter Sets: AllResults
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Endpoint
The individial URI to post to for results, IE computers

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OrderBy
Order by - Used to sort the results by a field.
Can be sorted in ascending or descending order.
Example - fieldname asc
Example - fieldname desc

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Condition
Condition - the searches that can be used to search for specific things.
Supported operators are '=', 'eq', '\>', '\>=', '\<', '\<=', 'and', 'or', '()', 'like', 'contains', 'in', 'not'.
The 'not' operator is only used with 'in', 'like', or 'contains'.
The '=' and 'eq' operator are the same.
String values can be surrounded with either single or double quotes.
Boolean values are specified as 'true' or 'false'.
Parenthesis can be used to control the order of operations and group conditions.
The 'like' operator translates to the MySQL 'like' operator.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeFields
A comma delimited list of fields, when specified only these fields will be included in the result set

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExcludeFields
A comma delimited list of fields, when specified these fields will be excluded from the final result set

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IDs
A comma delimited list of IDs, when specified only these IDs will be returned

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Expand
{{ Fill Expand Description }}

```yaml
Type: String
Parameter Sets: (All)
Aliases:

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

### The returned results from the API call
## NOTES
Version:        1.1.0
Author:         Gavin Stone
Creation Date:  2019-01-20
Purpose/Change: Initial script development

Update Date:    2020-07-03
Purpose/Change: Update to use Invoke-AutomateAPIMaster

## RELATED LINKS
