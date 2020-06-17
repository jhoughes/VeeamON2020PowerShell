#Check configuration of storage latency control
$CIMDetails = Get-CimInstance -ClassName BackupServer -Namespace root/VeeamBS -Computername ausveeambr

$StorageLatencyDetails = [PSCustomObject]@{
    StorageLatencyEnabled = $CIMDetails.LimitParallelTasksByDatastoreLatency;
    StopAssigningTasksLatency = $CIMDetails.MaxDatastoreLatencyMs;
    ThrottleExistingTasksLatency = $CIMDetails.MinDatastoreLatency4ThrottleMs
}

Write-Output $StorageLatencyDetails

$CIMDetails | Show-Object
