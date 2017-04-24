function Get-DiskInfo{
param(
$Name
)
    begin{
        $DiskInfo = Get-WmiObject Win32_Volume -Filter "DriveType='3'" -ComputerName $Name
    }

    process{
    $Target = @()
        foreach($disk in $DiskInfo){
            $OutPutObject = New-Object System.Object
            $UsedSpace_GB = ([Math]::Round($disk.Capacity /1GB,2)) - ([Math]::Round($disk.FreeSpace /1GB,2))
            $OutPutObject | Add-Member -Type NoteProperty -Name "ServerName" -Value $disk.PSComputerName
            $OutPutObject | Add-Member -Type NoteProperty -Name "UsedSpace_GB" -Value $UsedSpace_GB
            $OutPutObject | Add-Member -Type NoteProperty -Name "Name" -Value $disk.Name
            $OutPutObject | Add-Member -Type NoteProperty -Name "Label" -Value $disk.Label
            $Target += $OutPutObject
        }
    }

    end{
        return $Target
    }
}

$Computers = "SERVER1", "SERVER2"
Get-DiskInfo -Name $Computers
