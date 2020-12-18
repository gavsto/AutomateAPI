$Public = @( Get-ChildItem -Recurse -Path "$PSScriptRoot\Public\" -File -Filter *.ps1 )
$Private = @( Get-ChildItem -Recurse -Path "$PSScriptRoot\Private\" -File -Filter *.ps1 )

@($Public + $Private) | ForEach-Object {
    Try {
        If ($_.Length -gt 0) {. $_.FullName}
    } Catch {
        Write-Error -Message "Failed to import function $($_.FullName): $_"
    }
}

$Script:LTPoShURI='https://raw.githubusercontent.com/LabtechConsulting/LabTech-Powershell-Module/master/LabTech.psm1'
$Script:CWCExtensionID='fc234f0e-2e8e-4a1f-b977-ba41b14031f7'

#check PS version for this, PS 6 and above use -SkipCertificateCheck for Invoke-RestMethod
if ($PSVersionTable.PSVersion.Major -lt 6)
{
    #Ignore SSL errors
    If ($Null -eq ([System.Management.Automation.PSTypeName]'TrustAllCertsPolicy').Type) {
        Add-Type -Debug:$False @"
            using System.Net;
            using System.Security.Cryptography.X509Certificates;
            public class TrustAllCertsPolicy : ICertificatePolicy {
                public bool CheckValidationResult(
                    ServicePoint srvPoint, X509Certificate certificate,
                    WebRequest request, int certificateProblem) {
                    return true;
                }
            }
"@
    }
    [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
}


#Enable TLS, TLS1.1, TLS1.2 in this session if they are available
IF([Net.SecurityProtocolType]::Tls) {[Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls}
IF([Net.SecurityProtocolType]::Tls11) {[Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls11}
IF([Net.SecurityProtocolType]::Tls12) {[Net.ServicePointManager]::SecurityProtocol=[Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12}

Export-ModuleMember -Function $Public.BaseName -Alias *