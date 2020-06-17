#AddVMsFromTextFile
$vCenterServerName = 'ausvcenter.fsglab.local'
$VeeamBackupJobName = 'VMs-Text-File'
$FileToParse = 'D:\Demos\veeamon2020\Session2\VMsFromTextFile\AddVMs.txt'

#Read in text file
$VMList = Get-Content -Path $FileToParse

#Get Veeam job
$BackupJob = Get-VBRJob -Name $VeeamBackupJobName

#Show Job Objects
$BackupJob | Get-VBRJobObject | Select-Object Name, TypeDisplayName, Type

#Get vCenter connection object
$vCenterServer = Get-VBRServer -Name $vCenterServerName

#Loop through list of VM names and add each to backup job
foreach ($VMtoAdd in $VMList){
    $VMwareTarget = Find-VBRViEntity -Name $VMtoAdd -VM -Server $vCenterServer
    Add-VBRViJobObject -Job $BackupJob -Entities $VMwareTarget | Out-Null
}

#Show Job Objects
$BackupJob | Get-VBRJobObject | Select-Object Name, TypeDisplayName, Type
