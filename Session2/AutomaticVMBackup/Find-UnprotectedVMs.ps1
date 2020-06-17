function Find-UnprotectedVMs {
  <#
  .Synopsis
    This function will check against a vCenter server to gather all registered VMs, the return VMs not backed up by a specific Veeam B&R server
  .DESCRIPTION
    This function will query a vCenter server to gather all registered VMs, then return VMs not backed up by a specific Veeam B&R server
  .EXAMPLE
    Find-UnprotectedVMs -VBRServerName 'ausveeambr' -vCenterName 'ausvcenter'
  .EXAMPLE
    Find-UnprotectedVMs -VBRServerName 'ausveeambr' -vCenterName 'ausvcenter' | Export-Csv 'D:\Temp\UnprotectedVMs.csv' -NoTypeInformation
  .INPUTS
    None. You cannot pipe objects to Find-UnprotectedVMs.
  .OUTPUTS
    PSCustomObject
  #>

  [CmdletBinding()]
  param (

    [string]$VBRServerName,
    [string]$vCenterName

  )

  begin {

    Add-PSSnapin -Name VeeamPSSnapIn
    Connect-VBRServer -Server $VBRServerName

  } #end begin block

  process {

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

    $vCenterServer = Get-VBRServer -Name $vCenterName

    $AllVMs = Find-VBRViEntity -VMsAndTemplates -Server $vCenterServer | Where-Object { $PSItem.Type -eq 'VM' } | Select-Object Name, Reference, Uuid, Path, @{n = 'vCenter'; e = { ($PSItem.Path -split '\\')[0] } }

    $VCTagVMs = Find-VBRViEntity -Tags -Server $vCenterServer | Where-Object { $PSItem.Type -eq 'VM' } | Select-Object Name, Reference, Uuid, Path, @{n = 'vCenter'; e = { ($PSItem.Path -split '\\')[0] } }

    $PathMatchVMs = foreach ($EachVM in $VCTagVMs) {
      foreach ($EachTag in $TagPaths) {
        if ($EachVM.Path -like $EachTag) {
          $EachVM
        }
      }
    }

    [System.Collections.ArrayList]$JobMissingVMs = @()

    foreach ($EachVM in $AllVMs) {

      $CoveredByName = [bool]($EachVM.Uuid -In ($UniqueJobVMs.Uuid))
      $CoveredByTag = [bool]($EachVM.Uuid -In ($PathMatchVMs.Uuid))

      if (-Not $CoveredByName -OR $CoveredByTag) {

        $VMResult = [PSCustomObject] @{
          Name    = $EachVM.Name
          MoRefID = $EachVM.Reference
          Uuid    = $EachVM.Uuid
          Path    = $EachVM.Path
          vCenter = $EachVM.vCenter
        } #end PSCustomObject

        $null = $JobMissingVMs.Add($VMResult)
        Remove-Variable VMResult

      }

    } #end foreach

  } #end process block

  end {

    Write-Output $JobMissingVMs

    Disconnect-VBRServer
    Remove-PSSnapin -Name VeeamPSSnapIn

  } #end end block

}
