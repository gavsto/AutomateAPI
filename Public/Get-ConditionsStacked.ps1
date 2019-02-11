function Get-ConditionsStacked {
    param (
        [Parameter()]
        [string[]]$ArrayOfConditions
    )

    $FinalString = ($ArrayOfConditions) -join " And "
    Return $FinalString
  
}