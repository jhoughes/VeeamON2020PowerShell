#API_Backup_Session_Report
Add-Type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

$server = 'ausveeambem'
$username = 'svc_veeam_api'
$password = 'S3cr3tsquirr3!'
$JobName = 'AUSVCENTER-NoTag'
$report_filepath = 'D:\Demos\Session1\api_backup_session_report_05262020_Name.csv'

#get the api
$r_api = Invoke-WebRequest -Method Get -Uri "https://$($server):9398/api/"
$r_api_xml = [xml]$r_api.Content
$r_api_links = @($r_api_xml.EnterpriseManager.SupportedVersions.SupportedVersion | Where-Object { $_.Name -eq "v1_5" })[0].Links

#login
$securepassword = ConvertTo-SecureString -String $password -AsPlainText -Force
$api_credential = [pscredential]::new($username, $securepassword)
$r_login = Invoke-WebRequest -method Post -Uri $r_api_links.Link.Href -Credential $api_credential

$sessionheadername = "X-RestSvcSessionId"
$sessionid = $r_login.Headers[$sessionheadername]

#content
$r_login_xml = [xml]$r_login.Content
$r_login_links = $r_login_xml.LogonSession.Links.Link
$r_login_links_base = $r_login_links | Where-Object { $_.Type -eq 'EnterpriseManager' }

#get list of all backup jobs
$r_jobs_query = $r_login_links_base.Href + 'query?type=Job&filter=JobType==Backup'

$r_jobs_query_name = $r_login_links_base.Href + 'query?type=Job&filter=JobType==Backup;Name=="' + $JobName + '"'
$r_jobs_name = Invoke-WebRequest -Method Get -Headers @{$sessionheadername = $sessionid } -Uri $r_jobs_query_name
$r_jobs_name_xml = [xml]$r_jobs_name.Content
$r_jobs_name_list = $r_jobs_name_xml.QueryResult.Refs.Ref.Href

#gather backup session entities
$r_backup_session_entity_list = @()
$r_backup_session_link = Invoke-WebRequest -Method Get -Headers @{$sessionheadername = $sessionid } -Uri $(($r_jobs_name_list) + "/backupSessions")
$r_backup_session_link_xml = [xml]$r_backup_session_link.Content
$r_backup_session_entity_list = $r_backup_session_link_xml.EntityReferences.Ref.Links.Link | Where-Object Type -eq 'BackupJobSession' | Select-Object -ExpandProperty Href

#gather task sessions
foreach ($r_backup_session_entity in $r_backup_session_entity_list) {
    $r_backup_session_entity_link = Invoke-WebRequest -Method Get -Headers @{$sessionheadername = $sessionid } -Uri $r_backup_session_entity
    $r_backup_session_entity_link_xml = [xml]$r_backup_session_entity_link
    $r_task_session_ref = $r_backup_session_entity_link_xml.BackupJobSession.Links.Link | Where-Object Type -eq BackupTaskSessionReferenceList | Select-Object -ExpandProperty Href
    $r_task_session_link = Invoke-WebRequest -Method Get -Headers @{$sessionheadername = $sessionid } -Uri $r_task_session_ref
    $r_task_session_link_xml = [xml]$r_task_session_link
    $r_task_session_list = $r_task_session_link_xml.EntityReferences.Ref.Href

    #gather task session details
    foreach ($r_task_session in $r_task_session_list) {
        $r_task_session_entity = $($r_task_session + "?format=Entity")
        $r_task_session_entity_link = Invoke-WebRequest -Method Get -Headers @{$sessionheadername = $sessionid } -Uri $r_task_session_entity
        $r_task_session_entity_link_xml = [xml]$r_task_session_entity_link
        $r_task_session_detail = $r_task_session_entity_link_xml.BackupTaskSession

        #gather VM restore points
        $r_vm_restore_point_link = ($r_task_session_entity_link_xml.BackupTaskSession.Links.Link | Where-Object Type -eq VmRestorePoint)

        #gather VM restore point entities & details
        if ([bool]$r_vm_restore_point_link) {
            $r_vm_restore_point_entity_link = $r_vm_restore_point_link | Select-Object -ExpandProperty Href
            $r_vm_restore_point_entity = Invoke-WebRequest -Method Get -Headers @{$sessionheadername = $sessionid } -Uri $r_vm_restore_point_entity_link
            $r_vm_restore_point_entity_xml = [xml]$r_vm_restore_point_entity
            $r_vm_restore_point_entity_detail = $r_vm_restore_point_entity_xml.VmRestorePoint

            #VM name & task session details
            $backup_session_detail = [PSCustomObject] @{
                'VMName'                  = $r_vm_restore_point_entity_detail.VMName
                'BackupCreationTime(UTC)' = $r_task_session_detail.CreationTimeUTC
                'BackupEndTime(UTC)'      = $r_task_session_detail.EndTimeUTC
                'State'                   = $r_task_session_detail.State
                'Result'                  = $r_task_session_detail.Result
                'Reason'                  = $r_task_session_detail.Reason
            }

            Write-Output $backup_session_detail | Export-Csv -Path $report_filepath -NoTypeInformation -Append

        }

    }

}

#logout
$logofflink = $r_login_xml.LogonSession.Links.Link | Where-Object { $_.type -match "LogonSession" }
Invoke-WebRequest -Method Delete -Headers @{$sessionheadername = $sessionid } -Uri $logofflink.Href
