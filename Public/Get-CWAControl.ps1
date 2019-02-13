function Get-CWAControl {
<#
.SYNOPSIS
Retrieve data from Automate API Control Extension
.DESCRIPTION
Connects to the Automate API Control Extension and returns an object with Control Session data
.PARAMETER ComputerID
The Automate ComputerID to retrieve information on
.OUTPUTS
Custom object with the ComputerID and Control SessionID. Additional properties from the return data will be included.
.NOTES
Version:        1.0
Author:         Gavin Stone
Creation Date:  2019-01-20
Purpose/Change: Initial script development

Update Date:    2019-02-12
Author:         Darren White
Purpose/Change: Modified returned object data

.EXAMPLE
Get-CWAControl -ComputerId 123
#>
    param
    (
        [Parameter(Mandatory = $true, Position = 0,ValueFromPipeline = $true, ValueFromPipelineByPropertyName=$true)]
        [Alias('Id')]
        [int16[]]$ComputerID
    )

  Begin {
    $defaultDisplaySet = 'SessionID'
    #Create the default property display set
    $defaultDisplayPropertySet = New-Object System.Management.Automation.PSPropertySet('DefaultDisplayPropertySet',[string[]]$defaultDisplaySet)
    $PSStandardMembers = [System.Management.Automation.PSMemberInfo[]]@($defaultDisplayPropertySet)
  } #End Begin

  Process {
    ForEach ($ComputerIDSingle in $ComputerID) {
        $OurResult = [pscustomobject]@{
            ComputerID = $ComputerIdSingle
            SessionID = 'Not Found'
        }
        $Null = $OurResult.PSObject.TypeNames.Insert(0,'CWControl.Information')
        $Null = $OurResult | Add-Member MemberSet PSStandardMembers $PSStandardMembers
        $Null = $OurResult | Add-Member -MemberType AliasProperty -Name ControlGUID -Value SessionID

        $url = ($Global:CWAUri + "/v1/extensionactions/control/$ComputerIDSingle")
        Try {
            $Result = Invoke-RestMethod -Uri $url -Headers $global:CWACredentials -ContentType "application/json"

            $ResultMatch=$Result|select-string -Pattern '^(https?://[^?]*)\??(.*)' -AllMatches
            If ($ResultMatch.Matches) {
                $Null = $OurResult | Add-Member -NotePropertyName LaunchURL -NotePropertyValue $($ResultMatch.Matches.Groups[0].Value)
                $Null = $OurResult | Add-Member -MemberType ScriptMethod -Name 'LaunchSession' -Value {Start-Process "$($this.LaunchURL)"}
                ForEach ($NameValue in $($ResultMatch.Matches.Groups[2].Value -split '&')) {
                    $xName = $NameValue -replace '=.*$',''
                    $xValue = $NameValue -replace '^[^=]*=?',''
                    If ($OurResult | Get-Member -Name $xName) {
                        $OurResult.$xName=$xValue
                    } Else {
                        $Null = $OurResult | Add-Member -NotePropertyName $xName -NotePropertyValue $xValue
                    } #End If
                } #End ForEach
            } #End If
        } Catch {}
        $OurResult    
    } #End ForEach
  } #End Process

} #End Get-CWAControl