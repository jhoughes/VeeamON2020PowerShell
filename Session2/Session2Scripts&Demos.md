# Session 2 Scripts & Demos  

## Demo 1  

This script is a simple example of the workflow for getting a restore point of a Veeam Computer backup job (new terminology for Agent job within PowerShell), then leveraging the new "Start-VBRViComputerInstantRecovery" cmdlet to restore this Veeam Agent backup as a vSphere VM.  

## Demo 2  

This is a simple script to show the new NAS cmdlets within Veeam v10, followed by creating a NAS backup job.  

The following required components are created in this walk-through:  

- NAS Proxy (lines 14 & 15)  
- NAS SMB Server (line 17 - uses already existing credentials within Veeam B&R)  
- NAS Backup Job Object (line 19)  
- NAS Backup Job (line 21)  

The script then displays the job object, NAS proxy, and cache repository used.  

## Script 3  

The script shown on screen and referenced in the demo video can be found here:

[BR-DataIntegrationAPI](https://github.com/VeeamHub/powershell/tree/master/BR-DataIntegrationAPI)

The specific script displayed on-screen is "VBR-DataIntegrationAPI-singlevirtualmachine-lastrestorepoint.ps1"

## Script 4  

This script demonstrates the creation of an advanced multi-host Veeam Virtual Lab via PowerShell, leveraging vSphere Distributed Virtual Switches.

In the current format it is written out to make the variable use for names of the objects used fairly easy to follow, along with specifying IPs for remapping/masquerade, and static IP mappings.

It then gathers details of the datastores, source & destination host networks, and the destination distributed virtual switch.

A new proxy appliance, network mapping rules, network options, static IP mapping rules, and finally the Advanced Virtual Lab are all created in lines 61-79 (lines split for easier readability on the screen)

## Demo 5  

This script is a simple demo of the new licensing cmdlets released within Veeam v10, which was a common request from customers for assistance.

## Demo 6  

This script is a basic function which gathers details of Veeam backup jobs for easy comparison of settings & compliance.  

This output will be also used in the script.  

## Demo 7  

This script is a basic function which takes the job configuration details gathered in the last script and will run a comparison of settings, based on a specified "reference job" name.  

The output of this script will give a simple true/false view of whether the configuration of each backup job matches to the same setting of the "reference job".  

## Script 8  

This basic script shows some examples of setting job options (lines 9-18) such as:  

- Number of restore points for retention policy  
- Enabling VM deletion and number of days for maintenance  
- Setting day of week for synthetic full backups  
- SNMP notifications  
- Email notifications & addresses to notify  
- VM attribute to be used for successful backup details  
- Backup from storage snapshots  

The script also covers setting VSS options (lines 21-46) such as:  

- Enabling VSS options  
- Setting application-aware processing to "Require successful processing"  
- Disabling automatic selection of backup proxy, and setting job proxy  
- Setting VSS credentials, and setting the guest interaction proxy  
- Job scheduling of daily run (not a VSS specific setting)  

The last section of this script covers a few specific settings all together (lines 48-76):  

- Number of restore points  
- Scheduled run every 6 hours  
- Setting a backup window to terminate running jobs from 6AM to 5PM (comment-block section, lines 68-76)  

## Demo 9

This basic script shows some examples of cloning a Veeam backup job, then copying job options from a second source job.

## Script 10

These are two scripts written based on a customer request to show how to leverage some basic Veeam PowerShell & PowerCLI to deploy VMs via IP range.  

The "QueryVMs" script will use PowerCLI to query vCenter for VMs where the guest IP address matches a specific network octet string, and export to a CSV file.

The "CreateProtectionGroup" scope creates an Agent Protection group based on the CSV file from the "QueryVMs" script, and a Computer Backup job for this protection group. The parameters used are specific to a Linux computer backup job, rather than a Windows job as in session 1.  

## Script 11

This script is a function which will take input from a Veeam ONE alert (warning or error for a backup job state or agent backup job state).  It will then connect to a Veeam Backup & Replication server over PowerShell Remoting, and query for details of the task session and the failed VM or agent from the last job run.  

This was based on a customer request to send to an internal API for opening tickets for each specific host based on backup alerts, so some specific API usage has been sanitized from the end block.  

## Scripts for Veeam ONE

The scripts mentioned within the demo video for Veeam ONE alarm notifications can be found on VeeamHub:

- [Notifications to Slack](https://github.com/VeeamHub/powershell/tree/master/VONE-Notifications/veeam_one-notification-to-slack)  
- [Notifications to MSTeams](https://github.com/VeeamHub/powershell/tree/master/VONE-Notifications/veeam_one-notification-to-teams)  
- [Creating/resolving tickets in ServiceNow](https://github.com/VeeamHub/powershell/tree/master/VONE-ServiceNow)  

## Demo 12

This is a repeat of a simple script to demonstrate creating a "shell" job within Veeam Backup & Replication.  It was shown in session 1, but is also used to create the demo job used for script 13.

_NOTE:_ You must add a VM to a job at creation, then you can delete the job object afterwards.  For this purpose, I typically target my VCSA (vCenter) VM, as I know that it will exist within the environment to add to the job.  

**__Additional Note:__** This method to create a "shell" job will still not get you around the requirement within the GUI for there to be a VM that exists within a job, similar to creating a job within PowerShell.  You will need to avoid clicking the "Virtual Machines" tab on the job within the GUI, or else you will need to remove the job object again.

## Demo 13

These three simple scripts show how we can use some simple PowerShell code and text files for some basic job object management.  

The first script will add the VMs listed within a text file to a Veeam backup job.  

The second script will set exclusions for the VMs listed within a text file to a Veeam backup job.  

The third script will remove the VMs listed within a text file from a Veeam backup job.  

## Demo 14

The two scripts shown here are essentially the same code as scripts 6 & 7 from earlier in this session.

The minor changes made here to demonstrate some more advanced PowerShell toolmaking concepts are:

- Leveraging a basic PowerShell module for ease of distributing code, which is two separate functions in this demo
- Adding a PowerShell formatting file to specify a default view (defines how to display specific properties of our custom object)

## Demo 15

This script is a basic example of how to leverage PowerShell to set a VM name to initiate a QuickBackup for a VM.

This code which was created by simply walking through the Veeam Enterprise Manager API to get hierarchy object and VM object references, along with the managing Veeam server entity.  These details are then used to run the POST method for a Quick Backup.  

## Script 16

This script is a simple example of the workflow for setting a Scale-Out Backup Repository (SOBR) to enable an S3 repository as the capacity tier, followed by starting a Veeam restore to Amazon EC2.

For enabling the SOBR capacity tier, the following required components are covered in this walk-through:  

- Add Amazon account & create S3 connection (lines 2 & 3)
- Get S3 region & bucket (lines 4 & 5)
- Create S3 folder (line 6)
- Add the S3 object repository (line 7)
- Get the SOBR, add the new S3 repository, and enable capacity tier (lines 9-10)

For the Veeam restore to Amazon EC2, the following required components are covered in this walk-through:  

- Getting a Veeam restore point (line 13)
- Getting an Amazon account, EC2 region and EC2 instance type (lines 14-16)  
- Creating an array of EC2 disk configurations for the source VM disks (lines 18-22)  
- Getting an Amazon EC2 VPC, security group, and subnet (lines 24-26)
- Creating a new EC2 proxy appliance (line 27)
- Performing the Veeam restore to EC2 (lines 29-31; lines split for easier readability on the screen))

## Script 17

This script is a simple example of the workflow for starting a Veeam restore to Azure.

For the Veeam restore to Azure, the following required components are covered in this walk-through:  

- Getting a Veeam restore point (line 1)
- Getting an Azure account, subscription, storage account, location, VM size, virtual network & subnet, and resource group (lines 2-9)  
- Performing the Veeam restore to Azure (lines 12-14; lines split for easier readability on the screen))

## Demo 18

These two scripts contain functions for finding VMs missing from Veeam backups, and automatically adding them to Veeam jobs.  

The "Find-UnprotectedVMs" script contains a function which will query a vCenter server to gather all registered VMs, then return VMs not backed up by a specific Veeam B&R server (this is just a function which contains the relevant code covered in Script #14 from Session 1, and returns a PSCustomObject with details of the missing VMs)

The "Protect-MissingVMs" script contains a function will calculate the required number of Veeam backup jobs with a specified name prefix to backup VMs, until it reaches the specified maximum number of VMs per job.  If additional jobs are required, it create additional jobs cloned from the highest number job matching the specified name prefix, and will set the job options from the same source job.  It will then add VMs to each of the Veeam backup jobs with the specified name prefix, until the defined maximum number of VMs per job is reached.  

## Script 19

These two scripts contain functions which will launch restore sessions and gather details of the restore points, databases, and database files which match the specified parameters.

There are separate scripts containing functions for MS SQL and Oracle, and these have been made available on VeeamHub as [BR-DatabaseReports](https://github.com/VeeamHub/powershell/tree/master/BR-DatabaseReports)
