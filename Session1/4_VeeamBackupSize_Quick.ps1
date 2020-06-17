#Requires -Version 4
#Requires -RunAsAdministrator
<#
.Synopsis
   Simple Veeam report to expand on information from 'Veeam Backup Billing' report in VeeamOne
.Notes
    Version: 0.2
    Author: Joe Houghes
    Modified Date: 5-19-2020
.EXAMPLE
   Get-VeeamBackupSize | Format-Table
.EXAMPLE
   Get-VeeamBackupSize | Export-Csv VeeamBackupSize.csv -NoTypeInformation
#>

function Get-VeeamBackupSize {
  [CmdletBinding()]
  param (
    [string]$VBRServer = 'localhost',
    [double]$PriceGB = 0.15
  )

  begin {

    #Load the Veeam PSSnapin
    if (!(Get-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue)) {
      Add-PSSnapin -Name VeeamPSSnapIn
      Connect-VBRServer -Server $VBRServer
    }

    else {
      Disconnect-VBRServer
      Connect-VBRServer -Server $VBRServer
    }

  } #end begin block

  process {

    $Repositories = Get-VBRBackupRepository
    $SOBRs = Get-VBRBackupRepository -ScaleOut

    [System.Collections.ArrayList]$RepositoryDetails = @()

    foreach ($Repo in $Repositories) {
      $RepoOutput = [PSCustomObject] @{
        'Name'  = $Repo.Name
        'ID'    = $Repo.ID
        'PerVM' = [bool]($Repo.Options.OneBackupFilePerVm)
      }
      $null = $RepositoryDetails.Add($RepoOutput)
      Remove-Variable RepoOutput
    } #end foreach Repositories

    foreach ($Repo in $SOBRs) {
      $RepoOutput = [PSCustomObject] @{
        'Name'  = $Repo.Name
        'ID'    = $Repo.ID
        'PerVM' = [bool]($Repo | Get-VBRRepositoryExtent | Select-Object -ExpandProperty $_.Repository.Options.OneBackupFilePerVm -Unique)
      }
      $null = $RepositoryDetails.Add($RepoOutput)
      Remove-Variable RepoOutput
    } #end foreach SOBRs

    [System.Collections.ArrayList]$ReportJobOutput = @()

    $ReportJobs = Get-VBRJob -WarningAction SilentlyContinue | Where-Object { $PSItem.JobType -eq 'Backup' -OR $PSItem.JobType -eq 'BackupSync' -AND $PSItem.BackupPlatform.Platform -eq 'EVmware' }

    foreach ($ReportJob in $ReportJobs) {

      #Get Backups & VMs in Job
      $CurrentBackup = Get-VBRBackup -Name $ReportJob.Name
      $CurrentJobVMs = $ReportJob.GetViOijs() | Select-Object Name, ObjectId

      #Get all backup files associated with backup job
      $CurrentJobStorage = $CurrentBackup.GetAllStorages() | Select-Object Id, CreationTime, @{n = 'BackupSize'; e = { $PSItem.Stats.BackupSize } }

      #Check if backup is on a per-VM repository, if so calculate files as per VM backup sizes
      if ([bool]($RepositoryDetails | Where-Object -Property Id -eq -Value $CurrentBackup.RepositoryId | Select-Object -ExpandProperty PerVM)) {

        $CurrentRestorePoints = $CurrentBackup | Get-VBRRestorePoint | Select-Object VMName, StorageId

        foreach ($CurrentJobStorageFile in $CurrentJobStorage) {
          $BackupSizeGB = [math]::round(($CurrentJobStorageFile.BackupSize / 1GB), 2)

          $ReportJobOutputObject = [PSCustomObject] @{
            'BackupJob'      = $ReportJob.Name
            'VMName'         = $($CurrentRestorePoints | Where-Object Storageid -EQ $CurrentJobStorageFile.id | Select-Object -ExpandProperty VMName)
            'Timestamp'      = $CurrentJobStorageFile.CreationTime
            'BackupSize(GB)' = $BackupSizeGB
            'BackupCost($)'  = [math]::round(($BackupSizeGB * $PriceGB), 2)
          } #end ReportJobOutputObject

          $null = $ReportJobOutput.Add($ReportJobOutputObject)

        } # end foreach StorageFile

      } #end if

      else {
        foreach ($CurrentJobStorageFile in $CurrentJobStorage) {
          $BackupSizeGB = [math]::round(($CurrentJobStorageFile.BackupSize / 1GB), 2)
          $numVMs = @($CurrentJobVMs).count

          if ($numVMs -eq '1') {
            $VMName = $CurrentJobVMs | Select-Object -ExpandProperty Name
          }

          else { $VMName = "$numVMs VM(s)" }

          $ReportJobOutputObject = [PSCustomObject] @{
            'BackupJob'      = $ReportJob.Name
            'VMName'         = $VMName
            'Timestamp'      = $CurrentJobStorageFile.CreationTime
            'BackupSize(GB)' = $BackupSizeGB
            'BackupCost($)'  = [math]::round(($BackupSizeGB * $PriceGB), 2)
          } #end ReportJobOutputObject

          $null = $ReportJobOutput.Add($ReportJobOutputObject)

        } # end foreach StorageFile

      } #end else

    } #endforeach Job

  } #end process block

  end {

    Write-Output $ReportJobOutput

  } #end end block

} #end function
