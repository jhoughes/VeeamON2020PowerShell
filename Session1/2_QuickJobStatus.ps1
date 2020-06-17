$Jobs = Get-VBRJob -WarningAction SilentlyContinue

#Properties:
$Jobs | Select-Object -Property Name, TypeToString, IsRunning, IsRequireRetry, IsScheduleEnabled, LatestRunLocal | Format-Table -AutoSize

#Properties (Custom Labels):
$Properties = @(
                  @{n='Name';e={$_.Name}},
                  @{n='JobType';e={$_.TypeToString}},
                  @{n='Running';e={$_.IsRunning}},
                  @{n='RequiresRetry';e={$_.IsRequireRetry}},
                  @{n='Scheduled';e={$_.IsScheduleEnabled}},
                  @{n='LatestRunLocal';e={$_.LatestRunLocal}}
)

$Jobs | Select-Object -Property $Properties | Format-Table

$Jobs | Select-Object -Property $Properties | Export-CSV D:\Demos\Session1\JobStatusProperties.csv -NoTypeInformation

Invoke-Item D:\Demos\Session1\JobStatusProperties.csv

#Methods:
$Jobs | Select-Object -Property Name, TypeToString, @{n = 'LastResult'; e = { $_.GetLastResult() } }, @{n = 'LastState'; e = { $_.GetLastState() } }, @{n = 'Objects'; e = { $_.GetObjectsInJob().Count } }, @{n = 'Repo'; e = { $_.GetTargetRepository().Name } }, @{n = 'InWindow'; e = { $_.IsInBackupWindow($(Get-Date)) } }, @{n = 'WANAcc';e = { $_.IsWanAcceleratorEnabled()}} | Format-Table -AutoSize

#Methods (Custom Labels):

$Methods = @(
              @{n='Name';e={$_.Name}},
              @{n='JobType';e={$_.TypeToString}},
              @{n='LastResult';e={$_.GetLastResult()}},
              @{n='LastState';e={$_.GetLastState()}},
              @{n='ObjectsCount';e={$_.GetObjectsInJob().Count}},
              @{n='Repository';e={$_.GetTargetRepository().Name}},
              @{n='InWindow';e={$_.IsInBackupWindow($(Get-Date))}},
              @{n='WANAcc';e={$_.IsWanAcceleratorEnabled()}}
)

$Jobs | Select-Object -Property $Methods | Format-Table

$Jobs | Select-Object -Property $Methods | Export-CSV D:\Demos\Session1\JobStatusMethods.csv -NoTypeInformation

Invoke-Item D:\Demos\Session1\JobStatusMethods.csv
