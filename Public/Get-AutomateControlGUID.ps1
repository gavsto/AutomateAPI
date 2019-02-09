function Get-AutomateControlGUID {
    param
    (
        [Parameter(Mandatory = $true, Position = 0,ValueFromPipeline = $true, ValueFromPipelineByPropertyName=$true)]
        [Alias('Id')]
        [int16[]]$ComputerID
    )

    
  process {
    foreach ($ComputerIDSingle in $ComputerID) {
        $url = ($Global:CWAUri + "/v1/extensionactions/control/$ComputerIDSingle")

        $OurResult = [pscustomobject]@{
          ComputerId = $ComputerIdSingle
        }

        $Result = Invoke-RestMethod -Uri $url -Headers $global:CWACredentials -ContentType "application/json"
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