Param
(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [System.Uri[]]$addresses
)

$pingTimeout = 5

while($true) {
    Get-Date -Format "HH:mm:ss"
    echo ""
    $jobs = @()
    #Make sure we don't hammer faster than once every 3s
    $waitJerb = Start-Job -ScriptBlock { Start-Sleep -Seconds ($using:pingTimeout) }
    foreach ($addr in $addresses) {
        $jobs += Start-Job -ScriptBlock {
            $result = Test-Connection -TargetName $using:addr -Count 1 -TimeoutSeconds $using:pingTimeout
            return [PSCustomObject]@{
                Address = $using:addr
                Latency = if ($result) { $result.Latency } else { "dropped" }
            }
        }
    }
    $results = @()
    foreach ($job in $jobs) {
        $results += Receive-Job $job -Wait
    }
    $results | Select-Object -Property Address,Latency
    echo ""
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()
    Receive-Job $waitJerb -Wait
}