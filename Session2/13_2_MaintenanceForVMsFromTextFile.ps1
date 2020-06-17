#MaintenanceForVMsFromTextFile
$VeeamBackupJobName = 'VMs-Text-File'
$FileToParse = 'D:\Demos\veeamon2020\Session2\VMsFromTextFile\MaintenanceVMs.txt'

#Read in text file
$VMList = Get-Content -Path $FileToParse

#Get Veeam job
$BackupJob = Get-VBRJob -Name $VeeamBackupJobName

#Show Job Objects
$BackupJob | Get-VBRJobObject | Select Name, TypeDisplayName, Type

#Loop through list of VM names and set for maintenance in backup job
foreach ($MaintenanceVM in $VMList){
    $VMforMaintenance = Get-VBRJobObject -Job $BackupJob -Name $MaintenanceVM
    $VMforMaintenance | Remove-VBRJobObject | Out-Null
}

#Show Job Objects
$BackupJob | Get-VBRJobObject | Select Name, TypeDisplayName, Type
