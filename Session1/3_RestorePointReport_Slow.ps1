[string]$VBRServer = 'ausveeambr'

#Load the Veeam PSSnapin
if (!(Get-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue)) {
  Add-PSSnapin -Name VeeamPSSnapIn
  Connect-VBRServer -Server $VBRServer
} else {
  Disconnect-VBRServer
  Connect-VBRServer -Server $VBRServer
}

$VMBackups = Get-VBRBackup | Where-Object { $_.TypeToString -eq 'VMware Backup' }

$AllRestorePointsObject = @()

foreach ($CurrentBackup in $VMBackups) {

  $RestorePoints = $CurrentBackup | Get-VBRRestorePoint

  $Storages = $CurrentBackup.GetAllStorages()

  foreach ($CurrentRestorePoint in $RestorePoints) {

    if ($CurrentRestorePoint.Info.IsConsistent) {
      $Status = 'Successful'
    }
    if ($CurrentRestorePoint.Info.IsCorrupted) {
      $Status = 'Corrupted'
    }
    if ($CurrentRestorePoint.Info.IsRecheckCorrupted) {
      $Status = 'FailedHealthCheck'
    }


    $StorageFile = $Storages | Where-Object { $_.Id -eq $CurrentRestorePoint.StorageId }
    $FileName = ($StorageFile.PartialPath.Internal.Elements[0])

    $CurrentBackupOutputObject = New-Object PSObject -Property @{

      'Hostname'       = $CurrentRestorePoint.Name
      'CreationTime'   = $CurrentRestorePoint.CreationTime
      'Job Name'       = $CurrentBackup.JobName
      'BackupSize(GB)' = [math]::Round(($StorageFile.Stats.BackupSize / 1GB), 4)
      'DataSize(GB)'   = [math]::Round(($StorageFile.Stats.DataSize / 1GB), 4)
      'Full/Inc'       = $CurrentRestorePoint.Algorithm
      'Status'         = $Status
      'Job Type'       = $CurrentBackup.TypeToString
      'FileName'       = $FileName
      'IsAvailable'    = $StorageFile.IsAvailable
      'FilePath'       = $StorageFile.FilePath
    }

    $AllRestorePointsObject += $CurrentBackupOutputObject

    Remove-Variable -Name CurrentBackupOutputObject -ErrorAction SilentlyContinue

  } #end foreach CurrentRestorePoint

} #end foreach CurrentBackup

Disconnect-VBRServer
Remove-PSSnapin -Name VeeamPSSnapIn

Write-Output $AllRestorePointsObject

