#API_Start_Backup_Job
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

$server = 'ausveeambem.lab.fullstackgeek.net'
$username = 'svc_veeam_api'
$password = 'S3cr3tsquirr3!'
$vCenter_name = 'ausvcenter.fsglab.local'
$VM_name = 'ausjump01'

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

#get hierarchy root
$r_hier_root_uri = $r_login_links_base.Href + 'hierarchyRoots'
$r_hier_roots = Invoke-WebRequest -Method Get -Headers @{$sessionheadername = $sessionid } -Uri $r_hier_root_uri
$r_hier_roots_xml = [xml]$r_hier_roots.Content
$r_hier_root = $r_hier_roots_xml.EntityReferences.Ref | Where-Object { $_.Name -eq $vCenter_name }
$r_hier_root_ID = $r_hier_root.Href -replace ($($r_hier_root_uri + '/'))

#get vm object reference
$vm_query = $("lookup?host=urn%3aveeam%3aHierarchyRoot%3a$r_hier_root_ID&name=*&type=Vm")
$r_vm_query_uri = $r_login_links_base.Href + $vm_query
$r_vm = Invoke-WebRequest -Method Get -Headers @{$sessionheadername = $sessionid } -Uri $r_vm_query_uri
$r_vm_xml = [xml]$r_vm.Content
$r_vm_obj_ref = $r_vm_xml.HierarchyItems.HierarchyItem | Where-Object { $_.ObjectName -eq $VM_name } | Select-Object -ExpandProperty ObjectRef

#get vbr server entity
$vcenter_query = 'managedServers?format=Entity'
$r_vcenter_query_uri = $r_login_links_base.Href + $vcenter_query
$r_vcenter = Invoke-WebRequest -Method Get -Headers @{$sessionheadername = $sessionid } -Uri $r_vcenter_query_uri
$r_vcenter_xml = [xml]$r_vcenter
$r_backup_server = ($r_vcenter_xml.ManagedServers.ManagedServer | Where-Object { $_.Name -eq $vCenter_name }).Links.Link | Where-Object { $_.Type -eq 'BackupServer' }
$r_backup_server_id = ($r_backup_server.Href -replace $(($r_login_links_base.Href + 'backupServers/'))) -replace ('\?format=Entity')

#initiate quick backup for vm
$r_quick_backup_link = $('backupServers/' + $r_backup_server_id + '?action=quickbackup')
$r_quick_backup_uri = $r_login_links_base.Href + $r_quick_backup_link

$request_body = @"
<?xml version="1.0" encoding="utf-8"?>
<QuickBackupStartupSpec xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://www.veeam.com/ent/v1.0">
  <VmRef>$r_vm_obj_ref</VmRef>
</QuickBackupStartupSpec>
"@

Invoke-WebRequest -Method Post -Headers @{$sessionheadername = $sessionid } -Uri $r_quick_backup_uri -Body $request_body
