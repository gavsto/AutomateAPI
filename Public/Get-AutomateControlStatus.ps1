function Get-AutomateControlStatus {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName=$true)]
        [Alias('Id')]
        [int[]]$ComputerID

    )
  
    begin {
        $Source = @"
 
using System;
using System.Management.Automation;
namespace FastSearch
{
 
    public static class Search
    {
        public static object Find(PSObject[] collection, string column, string data)
        {
            foreach(PSObject item in collection)
            {
                if (item.Properties[column].Value.ToString() == data) { return item; }
            }
 
            return null;
        }
    }
}
"@
        Add-Type -ReferencedAssemblies $Assem -TypeDefinition $Source -Language CSharp        
        $ArrayTest = @()
    }
  
    process {

        if ($PSBoundParameters.ContainsKey('ComputerID') -and -not([string]::IsNullOrEmpty($ComputerID))) {
            $ComputersToCheck = Get-AutomateComputer -ComputerID $ComputerID
        }
        else {
            
            $ComputersToCheck = Get-AutomateComputer -NotSeenInDays $NotSeenInDays
        }

        #Get all of the Control sessions
        $ControlSessions = Get-ControlSessionBulk

        foreach ($computer in $ComputersToCheck) {
            # See if we can be cheeky without using an API call
            $Count = [FastSearch.Search]::Find($ControlSessions, "Name", $computer.ComputerName) | Measure-Object | Select-Object -ExpandProperty Count
            if ($Count -eq 1) {
                $GUID = [FastSearch.Search]::Find($ControlSessions, "Name", $computer.ComputerName) | Select -First 1 | Select -ExpandProperty SessionID
            }
            else {
                $GUID = Get-AutomateControlGUID -ComputerID $($computer | Select -ExpandProperty id)
            }
        
            $OnlineStatus = [FastSearch.Search]::Find($ControlSessions, "SessionID", $GUID) | Select-Object -ExpandProperty Connected
            $Object = ""
            $Object = [pscustomobject] @{
                ComputerID = $Computer.ID
                ComputerName = $computer.ComputerName
                OnlineStatusControl = $(If($OnlineStatus){"Online"}else{"Offline"})
                OnlineStatusAutomate = $Computer.Status
                GUID = $GUID
            }
            $ArrayTest += $Object
        }
    }

    
  
    end {
        $ArrayTest | ?{($_.OnlineStatusControl -eq 'Online') -and ($_.OnlineStatusAutomate -eq 'Offline') }
    }
}
