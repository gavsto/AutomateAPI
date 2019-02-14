function Get-AutomateControlGUID {
<#
.Synopsis
   Gets the Control GUID for a particular ComputerID from Automate
.DESCRIPTION
   Gets the Control GUID from an Automate extension for a particular ID
.PARAMETER ComputerID
   ComputerIDs to send, will accept integer or array of integers
.EXAMPLE
   Get-AutomateControlGUID -ComputerID 1
.EXAMPLE
   Get-AutomateControlGUID -ComputerID 1,5
.INPUTS
   ComputerID
.OUTPUTS
   ControlGUID Object containing ComputerID and ControlGUID
#>
    param
    (
        [Parameter(Mandatory = $true, Position = 0,ValueFromPipeline = $true, ValueFromPipelineByPropertyName=$true)]
        [Alias('Id')]
        [int16[]]$ComputerID
    )

    
  process {
    foreach ($ComputerIDSingle in $ComputerID) {
        $url = ($Script:CWAUri + "/v1/extensionactions/control/$ComputerIDSingle")

        $OurResult = [pscustomobject]@{
          ComputerId = $ComputerIdSingle
        }

        $Result = Invoke-RestMethod -Uri $url -Headers $script:CWACredentials -ContentType "application/json"
        if (-not ([string]::IsNullOrEmpty($Result))) {
            $Position = $Result.IndexOf("=");
            $ControlGUID = ($Result.Substring($position + 1)).Substring(0, 36)
            
            $OurResult | Add-Member -NotePropertyName ControlGuid -NotePropertyValue $ControlGuid -PassThru | Write-Output
        }
        else {
            $OurResult | Add-Member -NotePropertyName ControlGuid -NotePropertyValue "No GUID Found" -PassThru | Write-Output
        }
    }
  }

}