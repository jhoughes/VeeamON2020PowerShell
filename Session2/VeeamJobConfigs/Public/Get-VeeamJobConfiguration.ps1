#Requires -Version 4
#Requires -RunAsAdministrator
function Get-VeeamJobConfiguration {
    <#
    .Synopsis
        Simple Veeam report to export quick job configurations
    .Notes
        Version: 0.2
        Author: Joe Houghes
        Modified Date: 5-24-2020
    .EXAMPLE
        Get-VeeamJobConfiguration -VBRServer ausveeambr | Export-CSV D:\temp\VeeamJobConfigDetails.csv
    #>

    [OutputType('Veeam.JobQuickConfig')]
    [CmdletBinding()]
    Param
    (
        [Parameter(
            Mandatory = $false,
            Position = 0)]
        [string]
        $VBRServer = 'localhost'

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

        # Get Backup Jobs & Repositories
        $CompareJobs = [Veeam.Backup.Core.CBackupJob]::GetByType('Backup')
        $Repositories = [Veeam.Backup.Core.CBackupRepository]::GetAll()

    }

    process {

        [System.Collections.ArrayList]$JobDetails = @()

        # Loop through each job adding details to array
        foreach ($EachJob in $CompareJobs) {

            $Repository = ($Repositories | Where-Object { $_.HostId -eq $EachJob.TargetHostId -and $_.Path -eq $EachJob.TargetDir }).Name

            $JobProxies = $EachJob.GetSourceViProxies().Name -join ';'

            if ($EachJob.BackupTargetOptions.TransformFullToSyntethic -OR $EachJob.BackupTargetOptions.TransformIncrementsToSyntethic -OR $EachJob.BackupStorageOptions.EnableFullBackup) {
                $FullEnabled = $true
            } else {
                $FullEnabled = $false
            }

            switch ($EachJob.BackupStorageOptions.CompressionLevel) {
                '5' { $Compression = 'Optimal' }
                '4' { $Compression = 'Dedupe-friendly' }
                '0' { $Compression = 'None' }
                '6' { $Compression = 'High' }
                '9' { $Compression = 'Extreme' }
            }

            switch ($EachJob.BackupStorageOptions.StgBlockSize) {
                'KbBlockSize1024' { $Optimization = 'Local Target' }
                'KbBlockSize8192' { $Optimization = 'Local Target(16TB+ Files)' }
                'KbBlockSize512' { $Optimization = 'LAN Target' }
                'KbBlockSize256' { $Optimization = 'WAN Target' }
            }

            switch ($EachJob.VssOptions.GuestFSIndexingType) {
                'EveryFolders' { $IndexGuest = "Enabled" }
                'None' { $IndexGuest = "Disabled" }
            }

            $JobConfig = [PSCustomObject] @{
                PSTypeName          = 'Veeam.JobQuickConfig'
                Name                = $EachJob.Name
                Scheduled           = $EachJob.IsScheduleEnabled
                BackupMode          = $EachJob.BackupTargetOptions.Algorithm
                FullEnabled         = $FullEnabled
                AutoProxy           = $EachJob.SourceProxyAutoDetect
                Proxies             = $JobProxies
                Repository          = $Repository
                RestorePoints       = $EachJob.BackupStorageOptions.RetainCycles
                Deduplication       = $EachJob.BackupStorageOptions.EnableDeduplication
                Compression         = $Compression
                StorageOptimization = $Optimization
                RemoveDeletedVMs    = $EachJob.BackupStorageOptions.EnableDeletedVmDataRetention
                DeletedVMRetention  = $EachJob.BackupStorageOptions.RetainDays
                CBTEnabled          = $EachJob.ViSourceOptions.UseChangeTracking
                QuiesceVMTools      = $EachJob.ViSourceOptions.VMToolsQuiesce
                IntegrityChecks     = $EachJob.BackupStorageOptions.EnableIntegrityChecks
                SetVMNotes          = $EachJob.ViSourceOptions.SetResultsToVmNotes
                VMAttribute         = $EachJob.ViSourceOptions.VmAttributeName
                VSSEnabled          = $EachJob.VssOptions.Enabled
                IndexGuestFS        = $IndexGuest
            } #end pscustom object

            $Null = $JobDetails.Add($JobConfig)

        } #end foreach job

    }


    end {

        Write-Output $JobDetails

    }

}
