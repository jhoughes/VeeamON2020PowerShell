Get-VBRJob -WarningAction SilentlyContinue | Get-Member

(Get-VBRJob -WarningAction SilentlyContinue)[0].GetType()

Get-Command -ParameterType CBackupJob

Get-Command -ParameterType CBackupJob -Verb Add

Get-Command -ParameterType CBackupJob -Verb Set
