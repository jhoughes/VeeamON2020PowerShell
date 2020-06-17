#Setup
$amazon_account = Add-VBRAmazonAccount -AccessKey 'YTEXSZHP7PIUHGZFTZ' -SecretKey '4V+OERIp2IrX3+1G8erLeQ3x6Q5gUTfve4SD&y43' -Description 'veeamrestore - Amazon credentials'
$amazon_connection = Connect-VBRAmazonS3Service -Account $amazon_account -RegionType Global -ServiceType CapacityTier
$amazon_region = Get-VBRAmazonS3Region -Connection $amazon_connection -RegionId 'us-east-1'
$s3_bucket = Get-VBRAmazonS3Bucket -Connection $amazon_connection -Region $amazon_region -Name 'fsgveeamrestoretest'
$s3_folder = New-VBRAmazonS3Folder -Connection $amazon_connection -Bucket $s3_bucket -Name 'veeams3folder'
$capacity_tier = Add-VBRAmazonS3Repository -Name "AmazonS3Repository" -Connection $amazon_connection -AmazonS3Folder $s3_folder  -EnableIAStorageClass -EnableSizeLimit -SizeLimit 1024

$sobr = Get-VBRBackupRepository -ScaleOut
Set-VBRScaleOutBackupRepository -Repository $sobr -ObjectStorageRepository $capacity_tier -EnableCapacityTier

#Restore
$restorepoint = Get-VBRBackup -Name 'DomainControllers' | Get-VBRRestorePoint -Name 'coredc01' | Sort-Object -“Property CreationTime -Descending | Select-Object -First 1
$amazon_account = Get-VBRAmazonAccount -AccessKey 'YTEXSZHP7PIUHGZFTZ'
$ec2_region = Get-VBRAmazonEC2Region -Account $amazon_account -RegionType Global -Name 'us-east-1'
$ec2_instance = Get-VBRAmazonEC2InstanceType -Region $ec2_region -Name 't2.medium'

[System.Collections.ArrayList]$disk_configs = @()
for ($i = 0; $i -le (($restorepoint.AuxData.Disks.FlatFileName.Count)-1); $i++) {
  $singledeskconfig = New-VBRAmazonEC2DiskConfiguration -DiskName $($restorepoint.AuxData.Disks.FlatFileName[$i]) -Include -DiskType GeneralPurposeSSD
  $null = $disk_configs.Add($singledeskconfig)
}

$ec2_vpc = Get-VBRAmazonEC2VPC -Region $ec2_region -AWSObjectID 'vpc-043b2c7456d832b95'
$ec2_sec_group = Get-VBRAmazonEC2SecurityGroup -VPC $ec2_vpc -Name 'veeamrestoresecurity'
$ec2_subnet = Get-VBRAmazonEC2Subnet -VPC $ec2_vpc -AvailabilityZone 'us-east-1d'
$proxy_appliance = New-VBRAmazonEC2ProxyAppliance -InstanceType $ec2_instance -Subnet $ec2_subnet -SecurityGroup $ec2_sec_group -RedirectorPort '443'

Start-VBRVMRestoreToAmazon -RestorePoint $restorepoint -Region $ec2_region -LicenseType 'BYOL' `
-InstanceType $ec2_instance -VMName 'vmrestore2EC2' -DiskConfiguration $disk_configs -VPC $ec2_vpc `
-SecurityGroup $ec2_sec_group -Subnet $ec2_subnet -ProxyAppliance $proxy_appliance -Reason "PowerShell Restore to EC2"
