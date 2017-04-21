function Get-DiskInfo{
param(
$Disk
)
    $OutPutObject = New-Object System.Object
    $UsedSpace_GB = ([Math]::Round($disk.Capacity /1GB,2)) - ([Math]::Round($disk.FreeSpace /1GB,2))
    $OutPutObject | Add-Member -Type NoteProperty -Name "ServerName" -Value $disk.PSComputerName
    $OutPutObject | Add-Member -Type NoteProperty -Name "UsedSpace_GB" -Value $UsedSpace_GB
    $OutPutObject | Add-Member -Type NoteProperty -Name "Name" -Value $disk.Name
    $OutPutObject | Add-Member -Type NoteProperty -Name "Label" -Value $disk.Label
    return $OutPutObject
}

$Computers = "knetdeploy201", "knetworker201"

foreach($computer in $computers){
    $DiskInfo = Get-WmiObject Win32_Volume -Filter "DriveType='3'" -ComputerName $computer

        foreach($disk in $DiskInfo){
    
            Get-DiskInfo -Disk $disk

        }
}
