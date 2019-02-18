function FunctionName {
    param (
        $Token
    )

    $a={
        $TSS=600;$b=[System.BitConverter]::GetBytes([long]$((New-TimeSpan -Start $(Get-Date -Date "01/01/1970") -End $(Get-Date).ToUniversalTime()).TotalSeconds/$TSS));[array]::Reverse($b);$h=[System.Security.Cryptography.HMACSHA256]::new([Convert]::FromBase64String($_));[Convert]::ToBase64String($h.ComputeHash($b))
    }
    $CWAIKToken = $Token | &$a

    Return $CWAIKToken
    
}