function Send-VeeamError {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$FileToParse,

    [string]$Method = 'POST',

    $ContentType = "application/json",
    $APIKey = "%Insert API key here%",

    $headers = @{
      'content-type' = $ContentType;
      'x-api-key'    = $APIKey
    },

    $CredentialKey = 'PSCredentialKey1',

    [System.Uri]$Uri = "%Insert API URI here%"
  )

  begin {
    $ScriptPath = $PSScriptRoot
    Push-Location -Path $ScriptPath

    Import-Module .\PSJsonCredential\PSJsonCredential.psd1

    $parse = Get-Content $FileToParse

    $VBRServer = $parse[0].Replace('"', '')
    $VBRServer = $VBRServer -replace ' '

    $CredentialFile = Get-ChildItem -Path .\Credentials\ -Filter "*$VBRServer*"
    $Credential = Import-PSCredentialFromJson -Path $CredentialFile.FullName -Key $CredentialKey

    $JobTypeCheck = $parse[3]

    $JobType = switch -Wildcard ($JobTypeCheck) {
      'Fired by event: VeeamBpEpAgent*' { 'Agent' }
      'Fired by event: VeeamBpBackup*' { 'Job' }
    }

    if ($JobType -eq 'Job') {
      $JobNameRegex = [regex]'\bEvent description. Job \b(.+)\b finished with error\. \b'
      $JobNameErrors = $parse[3] -match "$JobNameRegex"
      [string]$Summary = $Matches[0]

      if ($JobNameErrors) {
        [string]$JobName = $Matches[1]
      }

    }

    if ($JobType -eq 'Agent') {
      $JobNameRegex = [regex]'\bEvent description. Job \b(.+)\b finished with error\. \b'
      $JobNameErrors = $parse[3] -match "$JobNameRegex"

      if ($JobNameErrors) {
        [string]$JobName = ($Matches[1].split(' - '))[0]
        $stringreplace = $Matches[1].Replace("$JobName", '')
        [string]$Summary = $Matches[0].Replace($stringreplace, '')

      }

    }

    [string]$AlarmName = $($parse[1].Replace('"', ''))
    $TimeSplit = $parse[2].Split('_')
    $AlarmTime = ($TimeSplit[0].Replace('-', '/')) + ' ' + ($TimeSplit[1].Replace('-', ':'))

    $Session = New-PSSession -ComputerName $VBRServer -Credential $Credential -ConfigurationName microsoft.powershell #-UseSSL #(Uncomment for using SSL)

  }

  process {

    $ScriptBlock = {
      param($JobType, $JobName, $AlarmName, $AlarmTime, $Summary, $VBRServer)
      Add-PSSnapin -Name VeeamPSSnapin

      Connect-VBRServer
      $Job = Get-VBRJob -Name $JobName
      $BackupSession = $Job.FindLastSession()

      if ($JobType -eq 'Job') {
        $TaskSession = Get-VBRTaskSession -Session $BackupSession
        $FailedTasks = $TaskSession | Where-Object { $_.Status -eq 'Failed' }
      }

      if ($JobType -eq 'Agent') {
        $FailedTasks = $BackupSession.Logger.GetLog().UpdatedRecords | Where-Object { $_.Title -like '*Failed*' } | Select-Object Status, Title
      }

      [System.Collections.ArrayList]$AllTasksOutput = @()

      foreach ($Task in $FailedTasks) {

        if ($JobType -eq 'Job') {

          $TaskRegex = [regex]'\bCode: (\d+)'
          $TaskErrors = $Task.Info.Reason -match "$TaskRegex"
          if ($TaskErrors) {
            $ErrorCode = $Matches[1]
          }

          switch ($Task.Info.Status) {
            'Warning' { $Status = 'Warning'; break }
            'Failed' { $Status = 'Critical'; break }
          }

          $NodeName = $Task.Name
        }

        if ($JobType -eq 'Agent') {

          $ErrorCode = 'N/A-Agent'

          $TaskRegex = [regex]'\bProcessing \b(.+)\b Error: \b'
          $TaskErrors = $Task.Title -match "$TaskRegex"
          if ($TaskErrors) {
            $NodeName = $Matches[1]
          }

          switch ($Task.Status) {
            'EWarning' { $Status = 'Warning'; break }
            'EFailed' { $Status = 'Critical'; break }
          }

        }

        $TaskOutputResult = [pscustomobject] @{

          'job_name'           = $Job.Name;
          'backup_server'      = $VBRServer;
          'affected_node_name' = $NodeName;
          'alarm_status'       = $Job.GetLastResult();
          'host_status'        = $Status;
          'error_code'         = $ErrorCode;
          'alarm_name'         = $AlarmName;
          'alarm_time'         = $AlarmTime;
          'alarm_summary'      = $Summary
        }

        $null = $AllTasksOutput.Add($TaskOutputResult)

      }

      Write-Output $AllTasksOutput

    }

    $AllTasksOutput = Invoke-Command -Session $Session -ScriptBlock $ScriptBlock -ArgumentList $JobType, $JobName, $AlarmName, $AlarmTime, $Summary, $VBRServer
    $SelectedOutput = $AllTasksOutput | Select-Object -Property 'affected_node_name', 'alarm_name', 'alarm_summary', 'alarm_status', 'job_name', 'host_status', 'error_code', 'alarm_time', 'backup_server'

    #$SelectedOutput | Export-Csv -Path .\Output.csv -NoTypeInformation

  }

  end {

    Remove-PSSession -Session $Session

    foreach ($TaskOutput in $SelectedOutput) {

      $TaskJson = $TaskOutput | ConvertTo-Json

      $props = @{
        Uri     = $Uri
        Headers = $Headers
        Method  = $Method
        Body    = $TaskJson
      }

      Invoke-RestMethod @props

    }

  }

}
