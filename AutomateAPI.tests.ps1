#using Pester to run tests
#Remove module from memory
Get-Module AutomateAPI | Remove-Module -Force
Import-Module "$PSScriptRoot\\AutomateAPI.psm1" -Force
#Get credentials $creds is available in every test
#Copy credentials.example.json to a new file credentials.json
$creds = $null
if(Test-Path "$PSScriptRoot\\credentials.json") {
    $creds = Get-Content "$PSScriptRoot\\credentials.json" | Out-String | ConvertFrom-Json
}
Describe AutomateAPI {
    It "AutomateAPI is valid PowerShell code" {
        $psFile = Get-Content -Path "$PSScriptRoot\\AutomateAPI.psm1" -ErrorAction Stop
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
        $errors.Count | Should -Be 0
    }

    It "Connects to the Automate API" {
        if($creds) {
            $password = ConvertTo-SecureString $creds.Automate.password -AsPlainText -Force
            $credentials = New-Object System.Management.Automation.PSCredential($creds.Automate.user, $password)
            $result = Connect-AutomateAPI -Server $creds.Automate.server -Credential $credentials `
                        -ClientID $creds.Automate.clientid
        }
        else {
            $result = Connect-AutomateAPI
        }

        $result | Should -be $null
    }

    It "Automate API returns a list of computers" {
        (Get-AutomateComputer).Count | Should -BeGreaterThan 0
    }
    
    It "Connects to the Control API" {
        if($creds) {
            $password = ConvertTo-SecureString $creds.Control.password -AsPlainText -Force
            $credentials = New-Object System.Management.Automation.PSCredential($creds.Control.user, $password)
            $result = Connect-ControlAPI -Server $creds.Control.server -Credential $credentials
        }
        else {
            $result = Connect-ControlAPI
        }

        $result | Should -be $null
    }
    
    It "Control API returns a list of sessions" {
        (Get-ControlSession).Count | Should -BeGreaterThan 0
    }

    It "Compares Automate Control Status" {
        $result = Get-AutomateComputer -Online $true | Select-Object -First 1 | Compare-AutomateControlStatus -AllResults
        $result | Should -Not -Be $null
    }
}