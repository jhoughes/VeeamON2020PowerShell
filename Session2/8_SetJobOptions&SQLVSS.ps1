#NewSQLBackupShellJob
$NewShellJob | Get-VBRJob -Name 'PowerShellOptions'

#Otherwise, create object with default job & VSS options
#$JobOptions = New-VBRJobOptions -ForBackupJob

#Create specific job options object
$JobOptions = Get-VBRJobOptions -Job $NewShellJob
$JobOptions.BackupStorageOptions.RetainCycles = '60'
$JobOptions.BackupStorageOptions.RetainDays = '21'
$JobOptions.BackupStorageOptions.EnableDeletedVmDataRetention = $True
$JobOptions.BackupTargetOptions.TransformToSyntethicDays = 'Friday'
$JobOptions.NotificationOptions.SnmpNotification = $True
$JobOptions.NotificationOptions.SendEmailNotification2AdditionalAddresses = $True
$JobOptions.NotificationOptions.EmailNotificationAdditionalAddresses = 'testemail@testdomain.com'
$JobOptions.ViSourceOptions.VmAttributeName = 'Veeam_Backup_Attribute'
$JobOptions.ViSourceOptions.SetResultsToVmNotes = $True
$JobOptions.SanIntegrationOptions.UseSanSnapshots = $False

#Enable VSS integration and create VSS options object, set guest interaction proxy to new job
$GuestProxy = Get-VBRServer -Name $VeeamProxyName

Enable-VBRJobVSSIntegration -Job $NewShellJob

$JobVSS = $NewShellJob.GetVSSOptions()
$JobVSS.VssSnapshotOptions.Enabled = $True
$JobVSS.VssSnapshotOptions.IgnoreErrors = $False
$JobVSS.GuestProxyAutoDetect = $False
$JobVSS.WinCredsId = $VSSCredential.Id
[Veeam.Backup.Core.CJobProxy]::Create($NewShellJob.Id, $GuestProxy.Id, "EGuest")

#Set job options & VSS options
$NewShellJob.SetVssOptions($JobVSS)
Set-VBRJobVssOptions -Job $NewShellJob -Credentials $SQLCredential
Set-VBRJobOptions -Job $NewShellJob -Options $JobOptions

#Set job proxy for backup, enable & set schedule to new job
$VeeamProxyName = 'ausveeampxy01.lab.fullstackgeek.net'
$SourceProxy = Get-VBRViProxy -Name $VeeamProxyName

$DaysToRun = 'Everyday'
$TimeToRun = '21:00'

Set-VBRJobProxy -Job $NewShellJob -Proxy $SourceProxy
Enable-VBRJobSchedule -Job $NewShellJob
Set-VBRJobSchedule -Job $NewShellJob -Daily -At $TimeToRun -DailyKind $DaysToRun

## Code to modify existing jobs for number of restore points, job run frequency, and backup window

#Set these variables to the required number of restore points, job frequency in hours, and starting & ending hour of the window when backups are not allowed
#NOTE: The NoBackupWindowEnd time will be set to the 59th minute of the hour selected, so subtract 1 hour from the allowed backup start time
#Example: To effectively allow backups from 6PM to 6AM, set the NoBackupWindowStart to 06 (6AM), and NoBackupWindowEnd to 17 (5:59PM)
$RestorePointsToMaintain = '140'
$BackupFrequency = '6'
$NoBackupWindowStart = '17'
$NoBackupWindowEnd = '06'

$JobToModify = Get-VBRJob -Name 'PowerShellOptions'
$JobOptions = Get-VBRJobOptions -Job $JobToModify
$JobOptions.BackupStorageOptions.RetainCycles = $RestorePointsToMaintain
Set-VBRJobOptions -Job $JobToModify -Options $JobOptions

$JobBackupWindow = New-VBRBackupWindowOptions -FromHour $NoBackupWindowEnd -ToHour $NoBackupWindowStart -Enabled:$False
Set-VBRJobSchedule -Job $JobToModify -Periodicaly -FullPeriod $BackupFrequency -PeriodicallyKind Hours -PeriodicallySchedule $JobBackupWindow


#If necessary to terminate running jobs if they exceed the backup window, uncomment the below section
<#
$ScheduleOptions = Get-VBRJobScheduleOptions -Job $JobToModify
$ScheduleOptions.OptionsBackupWindow = $JobBackupWindow
$ScheduleOptions.OptionsBackupWindow.IsEnabled = $true

Set-VBRJobScheduleOptions -Job $JobToModify -Options $ScheduleOptions

Enable-VBRJobSchedule -Job $JobToModify
#>