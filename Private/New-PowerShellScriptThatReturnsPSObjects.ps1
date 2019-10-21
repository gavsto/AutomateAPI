Function New-PowerShellScriptThatReturnsSerializedPSObjects
{
    param(    
    $ArgumentList
    )
    $EncodedScript = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Command))
        
    $CompressionBlock = {
        Function Compress {
            param($bytearray)
            [System.IO.MemoryStream] $output = New-Object System.IO.MemoryStream
            $gzipStream = New-Object System.IO.Compression.GzipStream $output, ([IO.Compression.CompressionMode]::Compress)
            $gzipStream.Write( $byteArray, 0, $byteArray.Length )
            $gzipStream.Close()
            $output.Close()
            $tmp = $output.ToArray()
            [System.Convert]::ToBase64String($tmp)
        }
    }
    if ($ArgumentList) {
        $XMLArgs = [xml]([System.Management.Automation.PSSerializer]::Serialize($ArgumentList))
        $XMLArgs.PreserveWhitespace = $false                
        $EncodedArguments = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($Xmlargs.OuterXml))
        $FormattedCommand += @"
`$ArgumentList = [System.Management.Automation.PSSerializer]::DeserializeAsList([System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String("$EncodedArguments")))
"@
            }
        
            $FormattedCommand += $CompressionBlock.ToString().Replace("`t", "") + "`r`n"        
            $FormattedCommand += @"            
`$ScriptBlock = [ScriptBlock]::Create([System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String("$EncodedScript")))
"@
            $FormattedCommand += @'
try
{
    $PSInstance = [System.Management.Automation.PowerShell]::Create()
    $OutputCollector = New-Object 'System.Management.Automation.PSDataCollection[psobject]'
    $PSOutputArray = new-object psobject -property @{"OutputObjects"=@();"ConsoleString"="";AllObjects=@()}  
    $NewDataHandler = {
        try {
            $data = $sender.ReadAll() | ?{ $null -ne $_ }
            $event.MessageData.AllObjects += $data
            $event.MessageData.OutputObjects += $data | ?{ $_.GetType().Name -notin @("InformationRecord","ErrorRecord","VerboseRecord","DebugRecord","WarningRecord")}            
            $event.MessageData.ConsoleString += $data | Out-String
        }
        catch{
            $_
        }
    }
    
    $null = $PSInstance.AddScript($ScriptBlock)
    Register-ObjectEvent -InputObject $OutputCollector -EventName DataAdded -MessageData $PSOutputArray -Action $NewDataHandler | Out-Null
    Register-ObjectEvent -InputObject $PSInstance.Streams.Error -EventName DataAdded -MessageData $PSOutputArray -Action $NewDataHandler | Out-Null
    Register-ObjectEvent -InputObject $PSInstance.Streams.Information -EventName DataAdded -MessageData $PSOutputArray -Action $NewDataHandler | Out-Null
    Register-ObjectEvent -InputObject $PSInstance.Streams.Debug -EventName DataAdded -MessageData $PSOutputArray -Action $NewDataHandler | Out-Null
    Register-ObjectEvent -InputObject $PSInstance.Streams.Warning -EventName DataAdded -MessageData $PSOutputArray -Action $NewDataHandler | Out-Null
    Register-ObjectEvent -InputObject $PSInstance.Streams.Verbose -EventName DataAdded -MessageData $PSOutputArray -Action $NewDataHandler | Out-Null
    $InputCollector = New-Object 'System.Management.Automation.PSDataCollection[psobject]'
    foreach($Argument in $ArgumentList)
    {
        $InputCollector.Add($Argument)
    }
    $Output = $PSInstance.BeginInvoke($InputCollector, $OutputCollector)
    while($PSInstance.InvocationStateInfo.State -ne "Completed")
    {
        sleep -s 1
    }    
}
catch
{
    $PSOutputArray += $_
}
finally
{
    $PSInstance.EndInvoke($Output);    
    Get-EventSubscriber | Unregister-Event
    $PSInstance.Dispose()
}
# $Output
[xml]$SerializedOutput = [System.Management.Automation.PSSerializer]::Serialize($PSOutputArray)
$SerializedOutput.PreserveWhiteSpace = $false
$UncompressedBinary = [System.Text.Encoding]::ASCII.GetBytes($SerializedOutput.OuterXml)
$CompressedOutput = Compress $UncompressedBinary
$CompressedOutput
'@
}

Function Decompress-SerializedPSObjects
{
    params($Input)
    $ByteArray = [System.Convert]::FromBase64String($Input)
    $InputStream = New-Object System.IO.MemoryStream( , $ByteArray )
    $OutputStream = New-Object System.IO.MemoryStream
    $GzipStream = New-Object System.IO.Compression.GzipStream $InputStream, ([IO.Compression.CompressionMode]::Decompress)
    $GzipStream.CopyTo( $OutputStream )
    $GzipStream.Close()
    $InputStream.Close()
    $DecompressedOutput = [System.Management.Automation.PSSerializer]::Deserialize([System.Text.Encoding]::ASCII.GetString($OutputStream.ToArray()));
    $OutputStream.Close()
    $DecompressedOutput
}