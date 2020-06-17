#Options & credentials to be modified per scope/backup job
$FilePath = '\\server\share\vmnames.csv'
$Repository = Get-VBRBackupRepository -Name 'RepositoryName' #-Scaleout  #uncomment this parameter if scale-out repository
$DailyBackup = New-VBRDailyOptions -DayOfWeek Friday -Period 21:00
$BackupSchedule = New-VBRLinuxScheduleOptions -Type Daily -DailyOptions $DailyBackup

#Get existing Master Windows credential
$MasterLinuxCredentialUsername = 'svc_veeam_bk'
$MasterLinuxCredentialDescription = 'Veeam Backup Access to Linux servers'
$VeeamMasterLinuxCredential = Get-VBRCredentials -Name $MasterLinuxCredentialUsername | Where-Object Description -eq $MasterLinuxCredentialDescription

#Get existing credential for fileshare access
$FileshareCredentialUsername = 'FSGLAB\svc_veeam_bkup'
$FileshareCredentialDescription = 'Veeam Backup Access to member servers'
$VeeamFileshareCredential = Get-VBRCredentials -Name $FileshareCredentialUsername | Where-Object Description -eq $FileshareCredentialDescription

#Create schedule for 1-hour discovery cycle
$Periodically = New-VBRPeriodicallyOptions -FullPeriod 1 -PeriodicallyKind Hours
$Schedule = New-VBRProtectionGroupScheduleOptions -PolicyType Periodically -PeriodicallyOptions $Periodically

#Create CSV container when all hosts using master credential
$CSVScope = New-VBRCSVContainer -Path $FilePath -MasterCredentials $VeeamMasterLinuxCredential -NetworkCredentials $VeeamFileshareCredential

#Create protection group from CSV container, set discovery cycle:
$ProtGroup = Add-VBRProtectionGroup -Name 'CSVbyIP' -Container $CSVScope -ScheduleOptions $Schedule

#Create new computer destination options
$Destination = New-VBRComputerDestinationOptions -OSPlatform Linux -BackupRepository $repository

#Create agent backup job for scope targeting CSV file, enable scheduling, 14 restore points, and set target backup repository
#Assuming no options selected for indexing, deleted computer retention, notification, compact of full backup, health check, active/synthetic full, storage (compression & dedupe), custom scripts during job
Add-VBRComputerBackupJob -OSPlatform 'Linux' -Type 'Server' -Mode 'ManagedByAgent' -Name 'LinuxAgentBackup' -Description 'Agent Managed - Prot Group by IP'`
-BackupObject $ProtGroup -BackupType 'EntireComputer' -DestinationOptions $Destination -ScheduleOptions $BackupSchedule -EnableSchedule`
-RetentionPolicy '14' -BackupRepository $Repository

