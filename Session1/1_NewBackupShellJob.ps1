Add-PSSnapin -Name VeeamPSSnapIn
Connect-VBRServer -Server ausveeambr.lab.fullstackgeek.net

Get-VBRJob -WarningAction SilentlyContinue | Select-Object Name, Description

#NewBackupShellJob
$VeeamRepositoryName = 'ReFS-PerVM'
$VeeamBackupJobName = 'zPowerShellDemoJob'

$vCenterServerName = 'ausvcenter.fsglab.local'
$VMName = 'ausvcenter'

$Repository = Get-VBRBackupRepository -Name $VeeamRepositoryName
$vCenterServer = Get-VBRServer -Name $vCenterServerName
$VMtoAdd = Find-VBRViEntity -Name $VMName -Server $vCenterServer -VM

#Create new shell backup job
$NewShellJob = Add-VBRViBackupJob -Name $VeeamBackupJobName -Description 'Demo backup job for VMware VM created via script' -BackupRepository $Repository -Entity $VMtoAdd

#Show Job Objects
$NewShellJob | Get-VBRJobObject | Select Name, TypeDisplayName, Type

#Remove VM from job objects
$JobObject = $NewShellJob | Get-VBRJobObject
Remove-VBRJobObject -Objects $JobObject -Completely

$NewShellJob.Info.CommonInfo
$NewShellJob.Info.CommonInfo.ModifiedBy
$NewShellJob.Info.ScheduleOptions.LatestRunLocal

Get-VBRJob -WarningAction SilentlyContinue | Select-Object Name, Description
