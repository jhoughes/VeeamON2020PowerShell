Add-PSSnapin -Name VeeamPSSnapIn
Connect-VBRServer -Server ausveeambr.lab.fullstackgeek.net -User FSGLAB\VeeamPowerShell -Password 'S3cr3tsquirr3!'

Get-VBRJob -WarningAction SilentlyContinue | Select-Object Name, Description

#NewBackupShellJob
$VeeamVBRServerName = 'ausveeambr.lab.fullstackgeek.net'
$VeeamRepositoryName = 'ReFS-PerVM'
$VeeamBackupJobName = 'VMs-Text-File'

$vCenterServerName = 'ausvcenter.fsglab.local'
$VMName = 'veeamv101'

$Repository = Get-VBRBackupRepository -Name $VeeamRepositoryName
$vCenterServer = Get-VBRServer -Name $vCenterServerName
$VMtoAdd = Find-VBRViEntity -Name $VMName -Server $vCenterServer -VM

#Create new shell backup job
$VMText = Add-VBRViBackupJob -Name $VeeamBackupJobName -Description 'VMs via Text File' -BackupRepository $Repository -Entity $VMtoAdd
$VMText | Get-VBRJobObject | Select-Object Name, TypeDisplayName, Type
