function Get-CWAIKToken {
    param (
        [Parameter(Position=0)]
        $APIKey = ([SecureString]$Script:ControlAPIKey)
    )

    If (!$APIKey) {
        Throw "The API Key is not defined and must be provided"
        Continue
    } ElseIf ($APIKey.GetType() -match 'SecureString') {
        $APIKey = $([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($APIKey)))
    }
        
    # If you bothered to actually inspect this module thoroughly, come PM @Gavsto in Slack and win a free Gavsto Karma Point ;)

    $TimeStepSeconds = 600
    $origin = New-Object -Type DateTime -ArgumentList 1970, 1, 1, 0, 0, 0, 0
    $epochsteps = [long]$((New-TimeSpan -Start $origin -End $(get-date).ToUniversalTime()).TotalSeconds/$TimeStepSeconds)
    $barray=[System.BitConverter]::GetBytes($epochsteps); [array]::Reverse($barray)
    $hmacsha = [System.Security.Cryptography.HMACSHA256]::new([Convert]::FromBase64String($APIKey))
    If ($hmacsha) {
        $Local:CWAIKToken = [Convert]::ToBase64String($hmacsha.ComputeHash($barray))
    }
    If ($Local:CWAIKToken) {
        Write-Debug "Generated CWAIKToken ""$($Local:CWAIKToken)"""
    } Else {
        Write-Debug "Error. CWAIKToken was not generated using APIKey $APIKey."
    }
    Return $Local:CWAIKToken
}