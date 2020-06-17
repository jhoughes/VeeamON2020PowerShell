#Requires -Version 4
#Requires -RunAsAdministrator
<#
.Synopsis
  Simple Veeam report to give details of task sessions for VMware backup jobs
.Notes
  Version: 1.0
  Author: Joe Houghes
  Modified Date: 4-21-20
.EXAMPLE
  Get-VeeamSessionReport | Format-Table
.EXAMPLE
  Get-VeeamSessionReport -VBRServer ausveeambr | Export-Csv D:\Temp\VeeamSessionReport.csv -NoTypeInformation
  .EXAMPLE
  Get-VeeamSessionReport -VBRServer ausveeambr -RemoveDuplicates | Export-Csv D:\Temp\VeeamSessionReport_NoDupes.csv -NoTypeInformation

#>

function Get-VeeamSessionReport {
  [CmdletBinding()]
  param (
    [string]$VBRServer = 'localhost',
    [switch]$RemoveDuplicates
  )
  begin {

    #Load the Veeam PSSnapin
    if (!(Get-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue)) {
      Add-PSSnapin -Name VeeamPSSnapIn
      Connect-VBRServer -Server $VBRServer
    }

    Disconnect-VBRServer
    Connect-VBRServer -Server $VBRServer

    $AllJobs = Get-VBRJob -WarningAction SilentlyContinue | Where-Object { ($_.JobType -eq 'Backup') -AND ($_.BackupPlatform.Platform -eq 'EVmware') }

    [System.Collections.ArrayList]$AllTasksOutput = @()

  }

  process {

    foreach ($EachJob in $AllJobs) {

      $JobSessions = [Veeam.Backup.Core.CBackupSession]::GetByJob($EachJob.Id)

      if ([bool]$JobSessions) {

        foreach ($CurrentSession in $JobSessions) {

          $TaskSessions = Get-VBRTaskSession -Session $CurrentSession

          foreach ($TaskSession in $TaskSessions) {

            $LogMatch = [regex]'\bUsing \b.+\s(\[[^\]]*\])'
            $LogMatches = $TaskSession.Logger.GetLog().UpdatedRecords | Where-Object Title -match $LogMatch

            foreach ($LogMatch in $LogMatches) {
              $TitleMatch = $LogMatch.Title -match $LogMatch
              $ProcessingMode = ($Matches[1] -replace '\[', '') -replace ']', ''

              $TaskOutputResult = [pscustomobject] @{

                'JobName'        = $TaskSession.JobName;
                'VMName'         = $TaskSession.Name;
                'Status'         = $TaskSession.Status;
                'IsRetry'        = $TaskSession.JobSess.IsRetryMode;
                'ProcessingMode' = $ProcessingMode;
                'WorkDuration'   = $TaskSession.WorkDetails.WorkDuration.TotalSeconds;
                'TaskAlgorithm'  = $TaskSession.WorkDetails.TaskAlgorithm;
                'CreationTime'   = $TaskSession.JobSess.CreationTime;
                'BackupSize'     = $TaskSession.JobSess.BackupStats.BackupSize;
                'DataSize'       = $TaskSession.JobSess.BackupStats.DataSize;
                'DedupRatio'     = $TaskSession.JobSess.BackupStats.DedupRatio;
                'CompressRatio'  = $TaskSession.JobSess.BackupStats.CompressRatio;

              } #end TaskOutputResult object

              $null = $AllTasksOutput.Add($TaskOutputResult)

            } #end foreach LogMatch

          } #end foreach TaskSession

        } #end foreach JobSession

      } #end if JobSessions

    } #end foreach Job

  }

  end {

    if ($RemoveDuplicates) {
      $UniqueTaskOutput = $AllTasksOutput | Select-Object JobName, VMName, Status, IsRetry, ProcessingMode, WorkDuration, TaskAlgorithm, CreationTime, BackupSize, DataSize, DedupRatio, CompressRatio -Unique
      Write-Output $UniqueTaskOutput
    }

    else {
      Write-Output $AllTasksOutput
    }

  }

}