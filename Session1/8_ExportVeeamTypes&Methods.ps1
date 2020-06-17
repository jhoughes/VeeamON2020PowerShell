[appdomain]::CurrentDomain.GetAssemblies()

Add-PSSnapin -Name VeeamPSSnapIn

[appdomain]::CurrentDomain.GetAssemblies()

$Assemblies = [appdomain]::CurrentDomain.GetAssemblies()

$Assemblies

$Assemblies | Where-Object { $_.Location -Match 'Veeam' }

$VeeamAssemblies = $Assemblies | Where-Object { $_.Location -Match 'Veeam' }

$VeeamAssemblies

$VeeamAssemblies.GetType()

$VeeamTypes = ($VeeamAssemblies).GetTypes()

$VeeamTypes

foreach ($CurrentAssembly in $VeeamAssemblies) {

  try {
    $Types = $CurrentAssembly.GetTypes()
    $Types | Export-Csv 'D:\Demos\Session1\Veeam_v10_Types.csv' -NoTypeInformation -Append

    $Methods = $Types.GetMethods()
    $Methods | Export-Csv 'D:\Demos\Session1\Veeam_v10_TypeMethods.csv' -NoTypeInformation -Append

  }

  catch {
    Write-Output "$($CurrentAssembly.Location) failed"
  }

}

Invoke-Item 'D:\Demos\Session1\Veeam_v10_Types.csv'
Invoke-Item 'D:\Demos\Session1\Veeam_v10_TypeMethods.csv'
