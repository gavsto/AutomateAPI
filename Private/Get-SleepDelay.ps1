        function Get-SleepDelay {
            param($seconds = 1, $totalseconds)
            if (!$totalseconds) {$totalseconds = $seconds * 2}
            Try {$Delay = [math]::Ceiling([math]::pow(($totalseconds / 2) - [math]::Abs($seconds - ($totalseconds / 2)), 1 / 3))}
            Catch {$Delay = 1}
            Finally {If ([double]::IsNaN($Delay) -or $Delay -lt 1) {$Delay = 1}}
            Write-Debug "Sleep Delay is $Delay"
            return $Delay
        }