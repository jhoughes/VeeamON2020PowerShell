function Protect-MissingVMs {
  <#
  .Synopsis
    This function will take a list of VMs, add them to Veeam backup jobs matching a specific name prefix, until a job VM limit is reached
  .DESCRIPTION
    This function will calculate the required number of Veeam backup jobs with a specified name prefix to backup VMs, until it reaches the specified maximum number of VMs per job.
    If additional jobs are required, it create additional jobs cloned from the highest number job matching the specified name prefix, and will set the job options from the same source job.
    It will then add VMs to each of the Veeam backup jobs with the specified name prefix, until the defined maximum number of VMs per job is reached.
  .EXAMPLE
    Protect-MissingVMs -VBRServerName 'ausveeambr' -vCenterName 'ausvcenter' -VMstoProtect vm1,vm2, vm3 -JobNamePrefix 'zPowerShellDemoJob-' -MaxJobVMs '8'
  .INPUTS
    None. You cannot pipe objects to Protect-MissingVMs.
  .OUTPUTS
    PSCustomObject
  #>

  [CmdletBinding()]
  param (

    [string]$VBRServerName,
    [string]$vCenterName,
    [string[]]$VMName,
    [string]$JobNamePrefix,
    [int]$MaxJobVMs

  )

  begin {

    Add-PSSnapin -Name VeeamPSSnapIn
    Connect-VBRServer -Server $VBRServerName

  } #end begin block

  process {

    [System.Collections.ArrayList]$ExistingJobs = @()
    $ExistingJobs = Get-VBRJob -WarningAction SilentlyContinue -Name "$JobNamePrefix*" | Where-Object { $PSItem.JobType -eq 'Backup' -AND $PSItem.BackupPlatform.Platform -eq 'EVmware' } | Select-Object Name, @{n = 'VMCount'; e = { $_.GetViOijs().Count } }

    [int]$TotalVMsExistingJobs = $($ExistingJobs.VMCount) | Measure-Object -Sum | Select-Object -ExpandProperty Sum
    [int]$TotalCapacityExistingJobs = ($ExistingJobs.Count * $MaxJobVMs) - $TotalVMsExistingJobs
    [int]$UnprotectedVMsBeyondCapacity = $VMName.Count - $TotalCapacityExistingJobs
    [int]$AdditionalJobsRequired = [math]::Round(($UnprotectedVMsBeyondCapacity / $MaxJobVMs), 0)

    #Create Arraylist & get VIEntities
    [System.Collections.ArrayList]$VMsToProtect = @()

    $vCenterServer = Get-VBRServer -Name $PSBoundParameters.vCenterName
    $VMsToProtect = Find-VBRViEntity -Name $VMName -VMsAndTemplates -Server $vCenterServer | Where-Object { $PSItem.Type -eq 'VM' }

    Write-Output '------------------------------------------'
    Write-Output "Total VMs to add: '$($VMsToProtect.Count)'"

    #Clone additional jobs if required
    if ($AdditionalJobsRequired) {

      $JobToClone = $ExistingJobs | Sort-Object Name | Select-Object -Last 1 -ExpandProperty Name
      $BaseJob = Get-VBRJob -Name $JobToClone
      $BaseJobOptions = $BaseJob.GetOptions()
      $BaseJobID = [int](($BaseJob.Name -split '(\d+)$')[1])
      $CloneRepository = $BaseJob.FindTargetRepository()

      For ($i = 1; $i -le $AdditionalJobsRequired; $i++) {

        $JobName = $($JobNamePrefix + $($BaseJobID + $i))
        #Write-Output "Job name: '$JobName'"
        #Copy-VBRJob -Job $BaseJob -Name $JobName -Description 'Job cloned by PowerShell' -Repository $CloneRepository | Out-Null

        $NewJob = Add-VBRViBackupJob -Name $JobName -Description 'Job cloned by PowerShell' -BackupRepository $CloneRepository -Entity $VMsToProtect[0]
        $NewJob = Get-VBRJob -Name $JobName

        #$CloneJob = Get-VBRJob -Name $JobName
        #$CloneJob | Get-VBRJobObject | Remove-VBRJobObject -Completely
        $VMsToProtect.RemoveAt(0)
        Set-VBRJobOptions -Job $NewJob -Options $BaseJobOptions | Out-Null
        Write-Output "Created new job: '$JobName'"
        Remove-Variable JobName, NewJob -ErrorAction SilentlyContinue

      } #end for loop add jobs

      Remove-Variable ExistingJobs

      [System.Collections.ArrayList]$ExistingJobs = @()
      $ExistingJobs = Get-VBRJob -WarningAction SilentlyContinue -Name "$JobNamePrefix*" | Where-Object { $PSItem.JobType -eq 'Backup' -AND $PSItem.BackupPlatform.Platform -eq 'EVmware' } | Select-Object Name, @{n = 'VMCount'; e = { $_.GetViOijs().Count } }

    } #end if AdditionalJobsRequired

    Write-Output '------------------------------------------'
    Write-Output "VMs to add after job creation: '$($VMsToProtect.Count)'"

    #Adding VMs to jobs
    for ($v = $VMsToProtect.Count; $v -gt 0; $v--) {

      if ($ExistingJobs.Count -gt 0) {

        $EachJob = $ExistingJobs[0]
        $VBRJob = Get-VBRJob -Name $($EachJob.Name)

        for ($j = $EachJob.VMCount; $j -lt $MaxJobVMs; $j++) {

          if ($VMsToProtect.Count -gt 1) {
            Add-VBRViJobObject -Job $VBRJob -Entities $VMsToProtect[0] | Out-Null
            $VMsToProtect.RemoveAt(0)
            Write-Output "Added VM: '$($VMsToProtect[0].Name)' to Job: '$($VBRJob.Name)'"
          }

        }

        $ExistingJobs.RemoveAt(0)

      }

    }

  } #end process block

  end {

    Write-Output '------------------------------------------'
    Write-Output "$($VMName.Count) new VMs added to jobs"
    Write-Output "$AdditionalJobsRequired new jobs cloned"

    Disconnect-VBRServer
    Remove-PSSnapin -Name VeeamPSSnapIn

  } #end end block

}