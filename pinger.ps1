Param
(
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [System.Uri[]]$addresses
)
while($true) {
    $jobs = @()
    #Make sure we don't hammer faster than once every 3s
    $waitJerb = Start-Job -ScriptBlock { Start-Sleep -Seconds 4 }
    foreach ($addr in $addresses) {
        $jobs += Start-Job -ScriptBlock {
            $result = Test-Connection -TargetName $using:addr -Count 1
            #because Test-Connection returns null when packet is dropped.
            if($null -eq $result) {
                echo "$using:addr : packet dropped"
            } else {
                echo ($result | Format-Table -Property Address,Latency)
            }
        }
    }
    foreach ($job in $jobs) { Receive-Job $job -Wait}
    Receive-Job $waitJerb -Wait
}