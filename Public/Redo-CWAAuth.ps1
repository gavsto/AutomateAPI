Function Redo-CWAAuth {
<#
This function should no longer be needed.
It could be aliased to Connect-AutomateAPI or removed entirely.
#>
    If ($Global:CWACredentials.Authorization) {
        Connect-AutomateAPI -Quiet
    }
    If (!$Global:CWACredentials.Authorization) {
        throw "Unable to get Access Token. Either the credentials your entered are incorrect or you did not pass a valid two factor token"
    }
}