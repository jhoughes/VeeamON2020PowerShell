[string]$VBRServer = 'ausveeambr'

#Load the Veeam PSSnapin
if (!(Get-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue)) {
  Add-PSSnapin -Name VeeamPSSnapIn
  Connect-VBRServer -Server $VBRServer
}

Disconnect-VBRServer
Connect-VBRServer -Server $VBRServer

$Jobs = Get-VBRJob -WarningAction SilentlyContinue | Where-Object { $PSItem.JobType -eq 'Backup' -AND $PSItem.BackupPlatform.Platform -eq 'EVmware' }
$JobObjects = $Jobs | Get-VBRJobObject
$JobVMObjects = $JobObjects | Where-Object { $PSItem.Object.ViType -eq 'VirtualMachine' -AND $PSItem.Object.Platform.Platform -eq 'EVmware' }
$JobTagObjects = $JobObjects | Where-Object { $PSItem.Object.ViType -eq 'Tag' -AND $PSItem.Object.Platform.Platform -eq 'EVmware' }

$JobVMs = $JobVMObjects | Select-Object Name, @{n = 'JobID'; e = { $PSItem.JobId.Guid } }, @{n = 'MoRefID'; e = { $PSItem.Object.ObjectID } }, @{n = 'Uuid'; e = { $PSItem.Object.Uuid } }, @{n = 'vCenter'; e = { $PSItem.Object.Host.Name } }
$UniqueJobVMs = $JobVMs | Select-Object Name, JobID, MoRefID, Uuid, VC -Unique

$JobTags = $JobTagObjects | Select-Object Name, @{n = 'JobID'; e = { $PSItem.JobId.Guid } }, @{n = 'Path'; e = { $PSItem.Location } }, @{n = 'vCenter'; e = { $PSItem.Object.Host.Name } }
$UniqueJobTags = $JobTags | Select-Object Name, JobID, Path, VC -Unique

$TagPaths = foreach ($EachTag in $UniqueJobTags) {
  $EachTag.Path + "\*"
}

$Backups = Get-VBRBackup -Name $Jobs.Name
$BackupObjects = $Backups.GetObjects() | Select-Object Name, @{n = 'MoRefID'; e = { $PSItem.ObjectID } }, @{n = 'Uuid'; e = { $PSItem.Uuid } }, @{n = 'vCenterVC'; e = { $PSItem.Host.Name } }
$UniqueBackupObjects = $BackupObjects | Select-Object Name, MoRefID, Uuid, VC -Unique

$AllVMs = Find-VBRViEntity -VMsAndTemplates | Where-Object { $PSItem.Type -eq 'VM' } | Select-Object Name, Reference, Uuid, Path, @{n = 'vCenter'; e = { ($PSItem.Path -split '\\')[0] } }

$VCTagVMs = Find-VBRViEntity -Tags | Where-Object { $PSItem.Type -eq 'VM' } | Select-Object Name, Reference, Uuid, Path, @{n = 'vCenter'; e = { ($PSItem.Path -split '\\')[0] } }

$PathMatchVMs = foreach ($EachVM in $VCTagVMs) {
  foreach ($EachTag in $TagPaths) {
    if ($EachVM.Path -like $EachTag){
      $EachVM
    }
  }
}

[System.Collections.ArrayList]$JobMissingVMs = @()
[System.Collections.ArrayList]$JobCoveredVMs = @()

[System.Collections.ArrayList]$BackupMissingVMs = @()
[System.Collections.ArrayList]$BackupCoveredVMs = @()

foreach ($EachVM in $AllVMs) {

  if ($EachVM.Uuid -In ($UniqueBackupObjects.Uuid) ) {

    $VMResult = [PSCustomObject] @{
      Name    = $EachVM.Name
      MoRefID = $EachVM.Reference
      Uuid    = $EachVM.Uuid
      Path    = $EachVM.Path
      vCenter = $EachVM.vCenter
    } #end PSCustomObject

    $null = $BackupCoveredVMs.Add($VMResult)
    Remove-Variable VMResult
  }#end if notin UniqueBackupObjects

  else {
    $VMResult = [PSCustomObject] @{
      Name    = $EachVM.Name
      MoRefID = $EachVM.Reference
      Uuid    = $EachVM.Uuid
      Path    = $EachVM.Path
      vCenter = $EachVM.vCenter
    } #end PSCustomObject

    $null = $BackupMissingVMs.Add($VMResult)
    Remove-Variable VMResult

  }#end else in UniqueBackupObjects

  if ($EachVM.Uuid -In ($UniqueJobVMs.Uuid) ) {

    if ($EachVM.Uuid -In ($PathMatchVMs.Uuid) ) {
      $AddedBy = 'VM;Tag'
    }

    else {
      $AddedBy = 'VM'
    }

    $VMResult = [PSCustomObject] @{
      Name    = $EachVM.Name
      MoRefID = $EachVM.Reference
      Uuid    = $EachVM.Uuid
      Path    = $EachVM.Path
      vCenter = $EachVM.vCenter
      Addedby = $AddedBy
    } #end PSCustomObject

    $null = $JobCoveredVMs.Add($VMResult)
    Remove-Variable VMResult
  }#end if notin UniqueJobVMObjects

  elseif ($EachVM.Uuid -In ($PathMatchVMs.Uuid) ) {

    if ($EachVM.Uuid -In ($UniqueJobVMs.Uuid) ) {
      $AddedBy = 'Tag;VM'
    }

    else {
      $AddedBy = 'Tag'
    }

    $VMResult = [PSCustomObject] @{
      Name    = $EachVM.Name
      MoRefID = $EachVM.Reference
      Uuid    = $EachVM.Uuid
      Path    = $EachVM.Path
      vCenter = $EachVM.vCenter
      Addedby = $AddedBy
    } #end PSCustomObject

    $null = $JobCoveredVMs.Add($VMResult)
    Remove-Variable VMResult
  }#end if notin UniqueJobVMObjects

  else {
    $VMResult = [PSCustomObject] @{
      Name    = $EachVM.Name
      MoRefID = $EachVM.Reference
      Uuid    = $EachVM.Uuid
      Path    = $EachVM.Path
      vCenter = $EachVM.vCenter
    } #end PSCustomObject

    $null = $JobMissingVMs.Add($VMResult)
    Remove-Variable VMResult

  }#end else in UniqueJobVMObjects

} #end foreach

Write-Output 'Script completed, writing output.'
Write-Output $JobMissingVMs | Export-Csv 'JobMissingVMs.csv' -NoTypeInformation
Write-Output $JobCoveredVMs | Export-Csv 'JobCoveredVMs.csv' -NoTypeInformation

Write-Output $BackupMissingVMs | Export-Csv 'BackupMissingVMs.csv' -NoTypeInformation
Write-Output $BackupCoveredVMs | Export-Csv 'BackupCoveredVMs.csv' -NoTypeInformation


$DupeJobVMs = Compare-Object -ReferenceObject $JobVMs -DifferenceObject $UniqueJobVMs -Property Name
if ($DupeJobVMs) {

  Write-Output ''
  Write-Output 'VMs duplicated in Jobs are:'

  foreach ($EachVM in $($DupeJobVMs.Name)) {
    Write-Output "$EachVM"
  }

  Write-Output $($DupeJobVMs.Name) | Out-File 'DupeJobVMs.txt'
}

$DupeJobTagVMs = $JobCoveredVMs | Where-Object { ($PSItem.AddedBy -eq 'Tag;VM') -OR ($PSItem.AddedBy -eq 'VM;Tag') }
if ($DupeJobTagVMs) {

    Write-Output ''
    Write-Output 'VMs duplicated by VM & tag within Jobs are:'

  foreach ($EachVM in $($DupeJobTagVMs.Name)) {
    Write-Output "$EachVM"
  }

  Write-Output $DupeJobTagVMs.Name | Out-File 'DupeJobVMs-VM&Tag.txt'
}

$DupeBackupVMs = Compare-Object -ReferenceObject $BackupObjects -DifferenceObject $UniqueBackupObjects -Property Name

if ($DupeBackupVMs) {

    Write-Output ''
    Write-Output 'VMs duplicated in Backups are:'

  foreach ($EachVM in $($DupeBackupVMs.Name)) {
    Write-Output "$EachVM"
  }

  Write-Output $DupeBackupVMs.Name | Out-File 'DupeBackupVMs.txt'
}