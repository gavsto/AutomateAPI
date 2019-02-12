Function Redo-CWAAuth {
 
    $auth = ($Global:CWACredentials.Values | Out-String) 

    $body = $auth.Replace("Bearer ",'')
    $b = $body | ConvertTo-Json
    $body = $b.Replace("\r\n",'')
    $authticket = Invoke-RestMethod -Method post -Uri ($Global:CWAUri + "/v1/apitoken/refresh") -Body $body -ContentType "application/json"

    #Build the returned token
    $AutomateToken = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $AutomateToken.Add("Authorization", "Bearer $($authticket.accesstoken)")

    if ([string]::IsNullOrEmpty($authticket.accesstoken)) {
        throw "Unable to get Access Token. Either the credentials your entered are incorrect or you did not pass a valid two factor token"
    }

    $Global:CWACredentials = $AutomateToken
    $Global:CWACredentialsExpirationDate = $authticket.ExpirationDate
     
     
}