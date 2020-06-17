#Requires -Version 4
#Requires -RunAsAdministrator

function Compare-VeeamJobConfiguration {
    <#
    .Synopsis
        Simple Veeam report to compare job configurations
    .Notes
        Version: 0.2
        Author: Joe Houghes
        Modified Date: 5-24-2020
    .EXAMPLE
    Get-VeeamJobConfiguration -VBRServer ausveeambr -OutVariable JobConfig; Compare-VeeamJobConfiguration -ReferenceJobName 'AUSVCENTER-NoTag' -VBRJobConfig $JobConfig
    #>


    [CmdletBinding()]
    Param
    (
        [Parameter( Mandatory = $true)]
        [string]
        $ReferenceJobName,

        [Parameter( Mandatory = $true, ValueFromPipeline)]
        [PSTypeName('Veeam.JobQuickConfig')]
        $VBRJobConfig
    )

    begin {

        Write-Output ''
        if (!($PSBoundParameters.ReferenceJobName -in $VBRJobConfig.Name)) {
            throw "Failed to find backup job with name: $ReferenceJobName"
        }

    }

    process {

        $ReferenceObject = $VBRJobConfig | Where-Object { $PSItem.Name -eq $PSBoundParameters.ReferenceJobName }
        $DiffObject = $VBRJobConfig | Where-Object { $PSItem.Name -ne $PSBoundParameters.ReferenceJobName }

        $Properties = $ReferenceObject.PSObject.Properties.Name | Where-Object { $PSItem -ne 'Name' }

        [System.Collections.ArrayList]$CompareJobOutput = @()

        foreach ($RefJob in $ReferenceObject) {

            $RefJobDetails = [PSCustomObject] @{ }
            $RefJobDetails = $RefJobDetails | Select-Object Name

            $RefJobDetails.Name = $RefJob.Name

            foreach ($EachProperty in $Properties) {
                $Value = 'REFJOB'

                $PropName = $($EachProperty + "Match")
                $RefJobDetails = $RefJobDetails | Select-Object *, $PropName
                $RefJobDetails.$PropName = $Value
            } #end foreach property

            $null = $CompareJobOutput.Add($RefJobDetails)
            Remove-Variable RefJobDetails

        }# end foreach refjob


        foreach ($DiffJob in $DiffObject) {

            $CompareJobDetails = [PSCustomObject] @{ }
            $CompareJobDetails = $CompareJobDetails | Select-Object Name

            $CompareJobDetails.Name = $DiffJob.Name

            foreach ($EachProperty in $Properties) {
                $Value = [bool]($($DiffJob.$EachProperty) -eq $($ReferenceObject.$EachProperty))

                $PropName = $($EachProperty + "Match")
                $CompareJobDetails = $CompareJobDetails | Select-Object *, $PropName
                $CompareJobDetails.$PropName = $Value
            } #end foreach property

            $null = $CompareJobOutput.Add($CompareJobDetails)
            Remove-Variable CompareJobDetails

        }# end foreach diffjob

    }


    end {

        Write-Output $CompareJobOutput

    }

}
