#AgentToVMInstantRecovery
$LaptopRestorePoint = Get-VBRRestorePoint -Name 'JOESURFACELAP3'
$ESXiHost = Get-VBRServer -Name 'esxi1.fsglab.local'
$VMFolder = Find-VBRViFolder -Name "VeeamON" -Server $ESXiHost
$VMResourcePool = Find-VBRViResourcePool -Name "VeeamON" -Server $ESXiHost
$VMDatastore = Find-VBRViDatastore -Name "ESXi_AllFlash" -Server $ESXiHost
$Networks = Get-VBRComputerNetworkInfo -RestorePoint $LaptopRestorePoint
$TargetNetwork = Get-VBRViServerNetworkInfo -Server $ESXiHost | Where-Object NetworkName -eq 'Austin-PROD'

Start-VBRViComputerInstantRecovery -RestorePoint $LaptopRestorePoint -Server $ESXiHost -RestoredVMName 'Surface_Restore'
-VMFolder $VMFolder -ResourcePool $VMResourcePool -CacheDatastore $VMDatastore -PowerOnAfterRestoring -Reason "VeeamON Demo" -RunAsync
