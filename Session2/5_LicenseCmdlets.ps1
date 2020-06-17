Get-Command -Noun *License* -Module VeeamPSSnapIn

$VBRLicense = Get-VBRInstalledLicense
$VBRLicense

Enable-VBRLicenseAutoUpdate

$LicenseSummary = Get-VBRInstanceLicenseSummary -License $VBRLicense
$LicenseSummary

$LicenseSummary.Object

$LicenseSummary.Workload

Get-VBRLicensedInstanceWorkload -License $VBRLicense

Get-VBRCapacityLicenseSummary -License $VBRLicense
