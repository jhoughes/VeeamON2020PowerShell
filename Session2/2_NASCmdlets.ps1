Get-Command -Module Veeam* -Noun *NAS* | Measure-Object

Get-Command -Module Veeam* -Noun *NAS* -Verb Add

Get-Command -Module Veeam* -Noun *NAS* -Verb Start

Get-Command -Module Veeam* -Noun *NAS* -Verb Restore

#Create NAS Proxy, NAS Server, NAS Object & NAS job
$RepositoryName = 'ReFS-PerVM'
$Repository = Get-VBRBackupRepository -Name $RepositoryName

$ProxyServer = Get-VBRServer -Name 'ausveeampxy02.lab.fullstackgeek.net'
$VBRNASProxyServer = Add-VBRNASProxyServer -Server $ProxyServer -Description 'Demo File Proxy'

$NASCredentials = Get-Credential -Username 'admin' -Message 'NAS Admin Credentials'
$NASServer = Add-VBRNASSMBServer -Path '\\192.168.50.9\LabMedia' -AccessCredentials $NASCredentials -CacheRepository $Repository -ProcessingMode Direct -ProxyMode SelectedProxy -SelectedProxyServer $VBRNASProxyServer -BackupIOControlLevel Medium

$NASObject = New-VBRNASBackupJobObject -Server $NASServer -Path "\\192.168.50.9\LabMedia\Veeam"

$NASBackupJob = Add-VBRNASBackupJob -BackupObject $NASObject -ShortTermBackupRepository $Repository -Name 'Veeam_Lab_Media' -Description 'NAS Backup by PowerShell' -ShortTermRetentionPeriod 3 -ShortTermRetentionType Daily

#Show Job & Object
$NASBackupJob.BackupObject

$NASBackupJob.BackupObject.Server

$NASBackupJob.BackupObject.Server.CacheRepository

$NASBackupJob.BackupObject.Server.CacheRepository.Name
