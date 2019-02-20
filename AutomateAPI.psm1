$Public = @( Get-ChildItem -Recurse -Path "$PSScriptRoot\Public\" -filter *.ps1 )
$Private = @( Get-ChildItem -Recurse -Path "$PSScriptRoot\Private\" -filter *.ps1 )

@($Public + $Private) | ForEach-Object {
    Try {
        . $_.FullName
    } Catch {
        Write-Error -Message "Failed to import function $($_.FullName): $_"
    }
}

$Script:LTPoShURI='http://bit.ly/LTPoSh'

Export-ModuleMember -Function $Public.BaseName