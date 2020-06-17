#Connect to Veeam
Add-PSSnapin -Name VeeamPSSnapIn
Connect-VBRServer -Server ausveeambr

#Variables
$CloneRepositoryName = 'NTFS-Bulk'
$CloneRepository = Get-VBRBackupRepository -Name $CloneRepositoryName

#Get & show source job
$SourceJob = Get-VBRJob -Name 'zPowerShellDemoJob'
$SourceJob.Info.CommonInfo
$SourceJob.FindTargetRepository().Name

#Show jobs, clone job, show new job
Get-VBRJob -WarningAction SilentlyContinue | Select-Object Name, Description
$CloneJob = Copy-VBRJob -Job $SourceJob -Name 'zPowerShellDemo2' -Description 'Job cloned by PowerShell' -Repository $CloneRepository
Get-VBRJob -WarningAction SilentlyContinue | Select-Object Name, Description

#Get cloned job details
$CloneJob.Info.CommonInfo
$CloneJob.FindTargetRepository().Name
$CloneJob.Options.NotificationOptions.EmailNotificationAdditionalAddresses
$CloneJob.Options.BackupStorageOptions.RetainCycles

#Get source job and show details
$Source2Job = Get-VBRJob -Name 'SQLLogTest'
$Source2Job.Options.NotificationOptions.EmailNotificationAdditionalAddresses
$Source2Job.Options.BackupStorageOptions.RetainCycles

#Get course job options, set to clone job, show new job options
$Source2Options = $Source2Job | Get-VBRJobOptions

Set-VBRJobOptions -Job $CloneJob -Options $Source2Options

$CloneJobUpdate = Get-VBRJob -Name 'zPowerShellDemo2'
$CloneJobUpdate.Options.NotificationOptions.EmailNotificationAdditionalAddresses
$CloneJobUpdate.Options.BackupStorageOptions.RetainCycles
