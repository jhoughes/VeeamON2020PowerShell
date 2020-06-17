#RemoveForVMsFromTextFile
$VeeamBackupJobName = 'VMs-Text-File'
$FileToParse = 'D:\Demos\veeamon2020\Session2\VMsFromTextFile\RemoveVMs.txt'

#Read in text file
$VMList = Get-Content -Path $FileToParse

#Get Veeam job & vCenter connection object
$BackupJob = Get-VBRJob -Name $VeeamBackupJobName

#Show Job Objects
$BackupJob | Get-VBRJobObject | Select Name, TypeDisplayName, Type

#Loop through list of VM names and add each to backup job
foreach ($RemoveVM in $VMList){
    $VMtoRemove = Get-VBRJobObject -Job $BackupJob -Name $RemoveVM
    $VMtoRemove | Remove-VBRJobObject -Completely | Out-Null
}

#Show Job Objects
$BackupJob | Get-VBRJobObject | Select Name, TypeDisplayName, Type

