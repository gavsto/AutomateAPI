#using Pester to run tests
Import-Module "$PSScriptRoot\\AutomateAPI.psm1" -Force

Describe AutomateAPI {
    It "Connects to the Automate API" {
        $result = Connect-AutomateAPI
        $result | Should -be $null
    }
    It "Automate API returns a list of computers" {
        (Get-AutomateComputer -AllComputers).Count | Should -BeGreaterThan 0
    }
}