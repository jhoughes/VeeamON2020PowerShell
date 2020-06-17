$restorepoint = Get-VBRBackup -Name 'AUSVCENTER-NoTag' | Get-VBRRestorePoint -Name 'ausmemberclt01' | Sort-Object $_.CreationTime -Descending | Select-Object -First 1
$account = Get-VBRAzureAccount -Type ResourceManager -Name 'azure@fullstackgeek.net'
$subscription = Get-VBRAzureSubscription -Account $account -name 'Pay-As-You-Go'
$storageaccount = Get-VBRAzureStorageAccount -Subscription $subscription -Name 'veeamon'
$location = Get-VBRAzureLocation -Subscription $subscription -Name 'southcentralus'
$vmsize = Get-VBRAzureVMSize -Subscription $subscription -Location $location -Name 'Standard_A1'
$network = Get-VBRAzureVirtualNetwork -Subscription $subscription -Name 'veeamon'
$subnet = Get-VBRAzureVirtualNetworkSubnet -Network $network -Name 'veeamon'
$resourcegroup = Get-VBRAzureResourceGroup -Subscription $subscription -Name 'veeamon'


Start-VBRVMRestoreToAzure -RestorePoint $restorepoint -Subscription $subscription -StorageAccount $storageaccount `
-VmSize $vmsize -VirtualNetwork $network -VirtualSubnet $subnet -ResourceGroup $resourcegroup `
-VmName vmrestore2Az -Reason 'PowerShell Restore to Veeam'