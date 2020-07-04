function Connect-ControlSession {
    <#
    .SYNOPSIS
        Will open a ConnectWise Control Remote Support session against a given machine.
    .DESCRIPTION
        Will open a ConnectWise Control Remote Support session against a given machine.

    .PARAMETER ComputerName
        The Automate computer name to connect to
    .PARAMETER ComputerID
        The Automate ComputerID to connect to
    .PARAMETER ID
        Taken from the Pipeline, IE Get-AutomateComputer -ComputerID 5 | Connect-ControlSession
    .PARAMETER ComputerObjects
        Used for Pipeline input from Get-AutomateComputer
    .OUTPUTS
        None (opens a Connect Control Remote Support session URL, via a URL to the default browser)
    .NOTES
        Version:        1.0
        Author:         Jason Rush
        Creation Date:  2019-10-15
        Purpose/Change: Initial script development

    .EXAMPLE
        Connect-ControlSession -ComputerName TestComputer
    .EXAMPLE
        Connect-ControlSession -ComputerId 123
    .EXAMPLE
        Get-AutomateComputer -ComputerID 5 | Connect-ControlSession
    #>
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    param
    (
        [Parameter(ParameterSetName = 'Name', Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName=$False)]
        [string[]]$ComputerName,

        [Parameter(ParameterSetName = 'ID', Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName=$False)]
        [int32[]]$ComputerID,

        [Parameter(ParameterSetName = 'pipeline', ValueFromPipelineByPropertyName=$true, Mandatory = $True)]
        [int32[]]$ID,

        [Parameter(ParameterSetName = 'pipeline', ValueFromPipeline = $true, Mandatory = $True)]
        $ComputerObjects
        
    )

    Process {
        #If not pipeline mode, build ComputerObjects
        If ( ($PSCmdlet.ParameterSetName -eq 'ID') -or ($PSCmdlet.ParameterSetName -eq 'Name') ) {
            $ComputerObjects = @()
        }

        If ($PSCmdlet.ParameterSetName -eq 'ID') {
            ForEach ($ComputerIDSingle in $ComputerID) {
                $ComputerObjects += (Get-AutomateComputer -ComputerID $ComputerIDSingle)
            }
        }

        If ($PSCmdlet.ParameterSetName -eq 'Name') {
            ForEach ($ComputerNameSingle in $ComputerName) {
                $ComputerObjects += (Get-AutomateComputer -ComputerName $ComputerNameSingle)
            }
        }

        ForEach ($Computer in $ComputerObjects) {
            try {
                $(Get-AutomateControlInfo $Computer.ID).LaunchSession()
            }
            catch {}
        } #End ForEach
    } #End Process

} #End Connect-ControlSession