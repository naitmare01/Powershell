<#
.Synopsis
   Function to get info about VeeamBilling and save it to a sql database.
   The whole function will log with help of Start-Transict.

   This scipt accepts arrays and csv and other list. 
.DESCRIPTION
   Long description
.EXAMPLE
    This will run the script and save the log but will not print to console. 
   Get-VeeamBillingInfo -SqlInstance "InstanceName" -SqlDb "DatabaseServer" -WorkingPath "PathToFolderToSaveLog"
.EXAMPLE
    This will run the script, save the log and print to console. 
   Get-VeeamBillingInfo -SqlInstance "InstanceName" -SqlDb "DatabaseServer" -WorkingPath "PathToFolderToSaveLog" -PrintToConsole "Y"

    This will run the script and save the log but will not print to console. 
   Get-VeeamBillingInfo -SqlInstance "InstanceName" -SqlDb "DatabaseServer" -WorkingPath "PathToFolderToSaveLog" -PrintToConsole "n"
#>

function Get-VeeamBillingInfo{
    param(
    [parameter(Mandatory=$true)]
    [string]$SqlInstance,
    [parameter(Mandatory=$true)]
    [string]$SqlDb,
    [parameter(Mandatory=$true)]
    [string]$WorkingPath,
    [parameter(Mandatory=$false)]
    [string]$PrintToConsole
    )

    #Check if the correct snapin is loaded
    if ((Get-PSSnapin -Name VeeamPSSnapIn -ErrorAction SilentlyContinue) -eq $null) {
        try{
            Add-PsSnapin -Name VeeamPSSnapIn -ErrorAction Stop
        }
        catch [System.Management.Automation.PSArgumentException]{
            Write-Warning "Snapin not found! Will end script!"
            return
        }
        catch{
            $errormsg = ($error[0].CategoryInfo.Activity)
            $errormsg = $errormsg + " " + $error[0].Exception.Message
            Write-Warning "An error occurred: $errormsg"
            return
        }
    }
    
    #Test if $WorkingPath exist!
    If(!(Test-Path $WorkingPath)){
        Throw "$WorkingPath doesnt exist, make sure u a pointing to a folder or catalog and not a file!"
        return
    }

    #Start logging
    Start-Transcript -Path "$workingPath\$(Get-Date -Format "yyyyMMdd_hhmmss").log" -Append

        foreach($job in $(Get-VBRBackup)){
            #Get size of backup jobs
            $jobBackupSize = $job.GetAllStorages().Stats.BackupSize | % { $sumTotal += $_}
            $jobDataSize = $job.GetAllStorages().Stats.DataSize | % { $sumTotal += $_}
            
            #Get VMs from backups
            $vmList = @(($job.GetObjectOibsAll() | ? { $_.ObjType -eq "VM"}).Name)
            $amoutVMs = ($vmList).Count
            $joinedVMs = $vmList -join "#"

            #SQL Queries
            $sql = "INSERT INTO usage (jobName,backupSize,totalSize,vmList) VALUES ('$($job.Name)','$($jobBackupSize)','$($jobDataSize)','$($joinedVMs)')"
            Invoke-Sqlcmd -Query $sql -ServerInstance $SqlInstance -Database $SqlDb

                if($PrintToConsole -eq "Y"){
                        Write "--------------------------------------------"
                        Write "Job: " $job.Name
                        Write "Total Backup Size: " $jobBackupSize;
                        Write "Total Data Size: " $jobDataSize;
                        Write "List of VMs: " $joinedVMs;
                        Write "Amount VMs: " $amoutVMs;
                        Write "--------------------------------------------"
                }
        }

        #Stop logging
        Stop-Transcript

}
