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

        Version:        1.1.0
        Author:         Darren White
        Creation Date:  2020-12-08
        Purpose/Change: Support connection to specified sessionid

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

        [Parameter(ParameterSetName = 'sessionid', Mandatory=$False,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$False)]
        [guid[]]$SessionID,

        [Parameter(ParameterSetName = 'sessionid', Mandatory=$False,ValueFromPipeline=$False,ValueFromPipelineByPropertyName=$False)]
        [string]$ConnectAs = ($Script:ControlAPICredentials.Username),

        [Parameter(ParameterSetName = 'pipeline', ValueFromPipeline = $true, Mandatory = $True)]
        $ComputerObjects
        
    )

    Process {
        #If not pipeline mode, build ComputerObjects
        If ( !($PSCmdlet.ParameterSetName -eq 'pipeline') ) {
            $ComputerObjects = @()
        }

        If ($PSCmdlet.ParameterSetName -eq 'ID') {
            ForEach ($ComputerIDSingle in $ComputerID) {
                $ComputerObjects += (Get-AutomateComputer -ComputerID $ComputerIDSingle)
            }
        } ElseIf ($PSCmdlet.ParameterSetName -eq 'Name') {
            ForEach ($ComputerNameSingle in $ComputerName) {
                $ComputerObjects += (Get-AutomateComputer -ComputerName $ComputerNameSingle)
            }
        }

        If ($PSCmdlet.ParameterSetName -eq 'SessionID') {
            If (!$ConnectAs) {$ConnectAs=$Script:CWACredentials.Username}
            If (!$ConnectAs) {$ConnectAs="AutomateAPI"}
            #Process SessionID
            ForEach ($Session in $SessionID) {
                #Get Access Token. 149249 = Join(1) + RunSharedTool(256) + TransferFiles(512) + HostWithoutConsent(1024) + Print(16384) + ManageCredentials(131072)
                $Body=ConvertTo-Json @("$($Session)", $ConnectAs, 149249) -Compress
                $RESTRequest = @{
                    'URI' = "Service.ashx/GetHostAccessTokenForSessionId"
                    'Body' = $Body
                }
                $AccessToken = Invoke-ControlAPIMaster -Arguments $RESTRequest
                If ($AccessToken) {
                    Write-Debug "Access Token $($AccessToken) retrieved"
                    #Build Launch URL
                    $LaunchURL="$($Script:ControlServer)$($Script:CWCExtensionURI)Launch.aspx?SessionID=$($Session)&HostAccessToken=$($AccessToken)"
                    Write-Debug "Starting $($LaunchURL)"
                    Start-Process "$($LaunchURL)"
                } Else {Write-Error "No Access Token was returned"}
            }
        } Else {
            ForEach ($Computer in $ComputerObjects) {
                try {
                    $(Get-AutomateControlInfo $Computer.ID).LaunchSession()
                }
                catch {}
            } #End ForEach
        }
    } #End Process

} #End Connect-ControlSession