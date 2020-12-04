#using Pester to run tests
Import-Module "$PSScriptRoot\\AutomateAPI.psm1" -Force

Describe AutomateAPI {
    It "Connects to the Automate API" {
        $result = Connect-AutomateAPI -Debug
        $result | Should -be $null
    }
    # It "Connects to the Control API" {
    #     $result = Connect-ControlAPI -Debug
    #     $result | Should -be $null
    # }
    It "Automate API returns a list of computers" {
        (Get-AutomateComputer).Count | Should -BeGreaterThan 0
    }
    # It "Control API returns a list of sessions" {
    #     (Get-ControlSessions).Count | Should -BeGreaterThan 0
    # }
}