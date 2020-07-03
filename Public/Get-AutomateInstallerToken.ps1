function Get-AutomateInstallerToken{
    <#
    .SYNOPSIS
        Gets an Automate Installer Token
    .DESCRIPTION
        The token lasts for 24 hours
    .NOTES
        Version:        1.0
        Author:         Gavin Stone
        Creation Date:  2020-07-03
        Purpose/Change: Initial script development
    .EXAMPLE
        Get-AutomateInstallerToken
    #>
        param (
        )
    
        $FinalResult = Get-AutomateAPIGeneric -GenerateInstallerToken -Endpoint "RemoteAgent/Installers"
    
        return $FinalResult
    }