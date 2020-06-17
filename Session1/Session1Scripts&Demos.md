# Session 1 Scripts & Demos

## Demo 1

This is a simple script to demonstrate creating a "shell" job within Veeam Backup & Replication.  

_NOTE:_ You must add a VM to a job at creation, then you can delete the job object afterwards.  For this purpose, I typically target my VCSA (vCenter) VM, as I know that it will exist within the environment to add to the job.  

**__Additional Note:__** This method to create a "shell" job will still not get you around the requirement within the GUI for there to be a VM that exists within a job, similar to creating a job within PowerShell.  You will need to avoid clicking the "Virtual Machines" tab on the job within the GUI, or else you will need to remove the job object again.

## Demo 2

This is a simple script to gather some commonly requested details for your backups jobs, using both properties and methods of the Veeam jobs.

It also leverages calculated properties to modify the named used to display toe objects' properties.

## Demo 3

There are two nearly matching versions of this script, both with names ending in '_Quick' or '_Slow'.

The slight difference in these scripts is to highlight the usage of these differing techniques within the script:

_Slow_ - Uses a standard array (line 14) to hold our results, uses the "New-Object PSObject" method (line 38) of creating a custom object, and the "+=" logic (line 53) to add members to the array (each of our custom objects)

_Quick_ - Uses a ArrayList (line 14) to hold our results, uses the "PSCustomObject" type accelerator (line 38) for creating a custom object, and the "Add" method of the ArrayList (line 53) to add members to the ArrayList (each of our custom objects)

## Demo 4

There are two nearly matching versions of this script, both with names ending in '_Quick' or '_Slow'.  

The slight difference in these scripts is to highlight the usage of these differing techniques within the script:

_Slow_ - Uses a standard array (lines 18,40) to hold our results, uses the "New-Object PSObject" method (lines 21, 31, 61) of creating a custom object, and the "+=" logic (lines 26, 36, 69, 94) to add members to the array (each of our custom objects)

_Quick_ - Uses a ArrayList (line 43) to hold our results, uses the "PSCustomObject" type accelerator (lines, 46, 56, 86) for creating a custom object, and the "Add" method of the ArrayList (lines 51, 61, 94, 119) to add members to the ArrayList (each of our custom objects).  The Quick script has also been formatted into a function, which can be loaded into memory by dot-sourcing the script or using the 'Import-Module' cmdlet.

## Script 5

This script is a simple example of the workflow for creating a Veeam Computer backup job (new terminology for Agent job within PowerShell), which is built via a protection group managed via CSV file.  

The following required components are created in this walk-through:  

- Schedule options (lines 4 & 5)
- Veeam Credentials (lines 8-10 for use on the hosts; lines 13-15 for the network share of the CSV file)
- Protection Group Discovery Schedule (lines 18-19)
- VBR CSV Container (line 22)
- Protection Group (line 25)
- Computer Backup Job (line 30)

## Script 6

This script is a basic backup/task session report, which was created by simply walking through the Veeam Enterprise Manager API, in a similar method to performing the same process via PowerShell.  

_NOTE:_  This script is not intended to be an efficient method of querying the API, but rather an easy to follow walk-through to help give some correlation to our API for someone that understands the basics of Veeam PowerShell.  

## Demo 7

This is a simple example of showing how to determine the type of an object with PowerShell.  

With that information, we then leveraging the 'ParameterType' parameter of the "Get-Command" cmdlet.  

This will show what additional cmdlets will allow the source object as an input object on the PowerShell pipeline (pipeline binding by value)  

## Demo 8

This basic script shows you how to leverage some PowerShell code to get a CSV file export of both the Veeam objects types and available methods for those object types.

_NOTE:_ You will need to change the file paths on lines 27 & 30 to an appropriate path for your system.

## Script 9

The script shown on screen and references in the demo video can be found here:

[BR-Dump-Object](https://github.com/VeeamHub/powershell/tree/master/BR-Dump-Object)

## Demo 10

This simple script leverages the native "Get-CIMInstance" cmdlet (PowerShell v3+) to gather some of the Veeam general options from WMI on the Veeam Backup & Replication server.

It also leverages the "Show-Object" cmdlet found in the [PowerShellCookbook](https://www.powershellgallery.com/packages/PowerShellCookbook/1.3.6) module on the PowerShell Gallery.

## Demo 11

This script is a simple function which will connect to a Veeam Backup & Replication server and query for details of servers, proxies, repositories, scale-out repositories,  scale-out extents, and jobs (limited details).  

It will then export each of these sets of details as a separate CSV file.  

## Demo 12

There are two versions of this script, both with names ending in '_Quick' or '_Slow'.  However, in this instance, the scripts vary greatly.

The primary difference in these scripts is to highlight the performance cost with using differing techniques within the script:

_Slow_ - Gathers all Veeam backup jobs for VMware, then uses a foreach loop for each job, each backup session, then each task session to gather details about the task session.

_Quick_ - Gathers all Veeam backup jobs for VMware, then gather all backup sessions, filters down to those matching our job IDs, and gather the task sessions for those filtered backup sessions.  We then parse the details for each task session, but do not incur the cost of running queries at each level.

## Demo 13

This script is a basic function to list out the disk filters for all VMware backup & backup copy jobs.  

It is meant to be a simple real-world example of demonstrating how some basic code can make it easier to confirm settings & ensure standardization against your environment, in a method that is quicker and easier than through the GUI.  

## Demo 14

This script came up as an example that was requested to find all VMs registered to a vCenter server which are not included within Veeam backups, with the caveat that both VM & tag objects are used within the Veeam jobs.  

This script leverages the "Get-VBRJobObject" and "Find-VBRViEntity" (along with some additional logic & filtering) to gather details of all VMs/tags within Veeam, then gathers the details of all VMs by name & by tag, to perform a comparison of all VMs & job objects.  

The results parsed by this script which are exported to CSV file include:  

- VMs not included within Veeam jobs
- VMs included within Veeam jobs
- VMs not included within Veeam backups
- VMs included within Veeam backups

These lists of VMs are also parsed to find the following details, exported to text file:  

- VMs duplicated within Veeam jobs
- VMs duplicated within Veeam backups
