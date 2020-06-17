#User input for vCenter servername & credentials, along with IP network to match VMs against
$vCenterHost = Read-Host -Prompt "Enter vCenter server name/IP"
$vCenterCreds = Get-Credential -Message "Enter vCenter credentials"
$IPNetwork = Read-Host -Prompt "Enter the network octets to match"

#Filepath for CSV output
$CSVoutputpath = '\\server\share\vmnames.csv'

#Import the PowerCLI module & connect to vCenter
Import-Module VMware.PowerCLI
Connect-VIServer -Server $vCenterHost -Credential $vCenterCreds

#Run Get-View for efficient query of VM objects
$AllVMs = Get-View -ViewType VirtualMachine

#Filter for VMs with non-Windows guest ID
$LinuxVMs = $AllVMs | Where-Object {$_.Guest.GuestId -NotLike "*windows*"}

#Query for VMs which match the IP network pattern and return their hostnames from guest OS
$IPmatchVMs = $LinuxVMs | Where-Object {$_.Guest.Net.IPaddress -match $IPNetwork}
$VMNames = $IPMatchVMs.Guest.Hostname

#Output results to file
$VMNames | Export-CSV -Path $CSVoutputpath -NoTypeInformation