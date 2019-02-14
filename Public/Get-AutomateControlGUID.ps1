function Get-AutomateControlGUID {
  <#
  This function should not be needed.
  Get-CWAControl replaces it.
  #>
  param
  (
      [Parameter(Mandatory = $true, Position = 0,ValueFromPipeline = $true, ValueFromPipelineByPropertyName=$true)]
      [Alias('Id')]
      [int16[]]$ComputerID
  )

  process {
    foreach ($ComputerIDSingle in $ComputerID) {
      Get-CWAControl -ComputerID $ComputerIDSingle
    }
  }
}