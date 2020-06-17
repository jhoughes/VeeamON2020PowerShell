#Virtual lab automation

[string]$VirtualLabName = 'VeeamON_Demo_Lab'
[string]$VirtualLabDescription = 'Virtual Lab for Demo VMs'
[string]$ResourcePoolName = 'VeeamON_Demo_ResourcePool'
[string]$VMFolderName = 'VeeamON_Demo_Lab'

[string]$SourceHostname = 'esxi1.fsglab.local'
[string]$DestinationHostname = 'esxi2.fsglab.local'

[string]$CacheDatastoreName = 'ESXi_AllFlash'

[string]$ProxyApplianceName = 'VeeamON_Proxy_Appliance'
[string]$ProxyApplianceIP = '192.168.20.200'
[string]$ProxyApplianceNetmask = '255.255.255.0'
[string]$ProxyApplianceGateway = '192.168.20.1'
[string]$ProxyApplianceDNS1 = '192.168.20.5'
[string]$ProxyApplianceDNS2 = '192.168.20.10'
[string]$ProxyApplianceDatastoreName = 'ESXi_Capacity'
[string]$ProxyApplianceNetworkName = 'AUSTIN-Prod'

[string]$VirtualSwitchName = 'PNTLSLAB-VDS'

[string]$ProdNetworkName1 = 'CORE-Prod'
[string]$IsolatedNetworkName1 = 'DR-Network3'
[int]$IsolatedNetworkVLANID1 = '10'

[string]$ProdNetworkName2 = 'AUSTIN-Prod'
[string]$IsolatedNetworkName2 = 'DR-Network4'
[int]$IsolatedNetworkVLANID2 = '20'

[string]$RemapIP1 = '192.168.10.1'
[string]$MasqueradeIP1 = '192.168.110.0'

[string]$RemapIP2 = '192.168.20.1'
[string]$MasqueradeIP2 = '192.168.120.0'

[string]$StaticIP1 = '192.168.10.10'
[string]$AccessIP1 = '192.168.20.231'

[string]$StaticIP2 = '192.168.20.10'
[string]$AccessIP2 = '192.168.20.232'


#Get base objects
$SourceServer = Get-VBRServer -Name $SourceHostname
$DestinationServer = Get-VBRServer -Name $DestinationHostname

$CacheDatastore = Find-VBRViDatastore -Server $DestinationServer -Name $CacheDatastoreName
$ProxyApplianceDatastore = Find-VBRViDatastore -Server $DestinationServer -Name $ProxyApplianceDatastoreName
$DestinationNetworks = Get-VBRViServerNetworkInfo -Server $DestinationServer
$ProxyNetwork = $DestinationNetworks | Where-Object { $_.NetworkName -eq $ProxyApplianceNetworkName }

$SourceNetworks = Get-VBRViServerNetworkInfo -Server $SourceServer
$ProdNetwork1 = $SourceNetworks | Where-Object { ($_.Type -eq 'ViDVS') -AND ($_.NetworkName -eq $ProdNetworkName1) }
$ProdNetwork2 = $SourceNetworks | Where-Object { ($_.Type -eq "ViDVS") -AND ($_.NetworkName -eq $ProdNetworkName2) }

$VirtualSwitch = Get-VBRViVirtualSwitch -Server $DestinationServer | Where-Object { ($_.Type -eq 'DVS') -AND ($_.Name -eq $VirtualSwitchName) }

#Create building blocks
$ProxyAppliance = New-VBRViVirtualLabProxyAppliance -Server $DestinationServer -Name $ProxyApplianceName  -Datastore $ProxyApplianceDatastore -Network $ProxyNetwork `
  -IPAddress $ProxyApplianceIP -SubnetMask $ProxyApplianceNetmask -DefaultGateway $ProxyApplianceGateway -PreferredDNSServer $ProxyApplianceDNS1 -AlternateDNSServer $ProxyApplianceDNS2

$NetworkMapping1 = New-VBRViNetworkMappingRule -Server $DestinationServer -ProductionNetwork $ProdNetwork1 -IsolatedNetworkName $IsolatedNetworkName1 -VLANID $IsolatedNetworkVLANID1
$NetworkMapping2 = New-VBRViNetworkMappingRule -Server $DestinationServer -ProductionNetwork $ProdNetwork2 -IsolatedNetworkName $IsolatedNetworkName2 -VLANID $IsolatedNetworkVLANID2

$VirtualLabNetworkOptions1 = New-VBRViVirtualLabNetworkOptions -NetworkMappingRule $NetworkMapping1 -IPAddress $RemapIP1 -SubnetMask $ProxyApplianceNetmask -MasqueradeIPAddress $MasqueradeIP1 -DNSServer $ProxyApplianceDNS1 -EnableDHCP
$VirtualLabNetworkOptions2 = New-VBRViVirtualLabNetworkOptions -NetworkMappingRule $NetworkMapping2 -IPAddress $RemapIP2 -SubnetMask $ProxyApplianceNetmask -MasqueradeIPAddress $MasqueradeIP2 -DNSServer $ProxyApplianceDNS1 -EnableDHCP

$IPMapping1 = New-VBRViVirtualLabIPMappingRule -ProductionNetwork $ProdNetwork1 -IsolatedIPAddress $StaticIP1 -AccessIPAddress $AccessIP1 -Note "Static IP address map to access $StaticIP1"
$IPMapping2 = New-VBRViVirtualLabIPMappingRule -ProductionNetwork $ProdNetwork2 -IsolatedIPAddress $StaticIP2 -AccessIPAddress $AccessIP2 -Note "Static IP address map to access $StaticIP2"


#Create Virtual Lab
$VirtualLab = Add-VBRViAdvancedVirtualLab -Server $DestinationServer -Name $VirtualLabName -Description $VirtualLabDescription `
  -DesignatedResourcePoolName $ResourcePoolName -DesignatedVMFolderName $VMFolderName -CacheDatastore $CacheDatastore `
  -ProxyAppliance $ProxyAppliance -NetworkMappingRule $NetworkMapping1, $NetworkMapping2 `
  -NetworkOptions $VirtualLabNetworkOptions1, $VirtualLabNetworkOptions2 `
  -EnableRoutingBetweenvNics -DVS $VirtualSwitch -IpMappingRule $IPMapping1, $IPMapping2 -Force

