function Get-AutomateControlStatus {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true)]
        $ComputerObject

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
        $ObjectRebuild = @()
    }
  
    process {
        $ObjectRebuild += $ComputerObject
    }

    
  
    end {
        #Get all of the Control sessions
        Write-Host -ForegroundColor Green "Getting all control sessions. This may take a few minutes"
        $ControlSessions = Get-ControlSessionBulk

        Write-Host -ForegroundColor Green "Getting all Automate Control GUIDs. This may take a few minutes"
        foreach ($computer in $ObjectRebuild) {
            # See if we can be cheeky without using an API call
            $GUID = Get-AutomateControlGUID -ComputerID $($computer | Select -ExpandProperty id)
        
            $OnlineStatus = [FastSearch.Search]::Find($ControlSessions, "SessionID", $GUID.ControlGuid) | Select-Object -ExpandProperty Connected
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
        $ArrayTest | ?{($_.OnlineStatusControl -eq 'Online') -and ($_.OnlineStatusAutomate -eq 'Offline') }
    }
}
