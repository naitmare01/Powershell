<#function Get-InstalledSoftware2{
param(
[parameter(Mandatory=$true,ValueFromPipeline=$True)]
[string]$Computers
)


$array = @()

foreach($pc in $computers){

    $computername=$pc

    #Define the variable to hold the location of Currently Installed Programs

    $UninstallKey=”SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall” 

    #Create an instance of the Registry Object and open the HKLM base key

    $reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey(‘LocalMachine’,$computername) 

    #Drill down into the Uninstall key using the OpenSubKey Method

    $regkey=$reg.OpenSubKey($UninstallKey) 

    #Retrieve an array of string that contain all the subkey names

    $subkeys=$regkey.GetSubKeyNames() 

    #Open each Subkey and use GetValue Method to return the required values for each

    foreach($key in $subkeys){

        $thisKey=$UninstallKey+”\\”+$key 

        $thisSubKey=$reg.OpenSubKey($thisKey) 

        $obj = New-Object PSObject

        $obj | Add-Member -MemberType NoteProperty -Name “ComputerName” -Value $computername

        $obj | Add-Member -MemberType NoteProperty -Name “DisplayName” -Value $($thisSubKey.GetValue(“DisplayName”))

        $obj | Add-Member -MemberType NoteProperty -Name “DisplayVersion” -Value $($thisSubKey.GetValue(“DisplayVersion”))

        $obj | Add-Member -MemberType NoteProperty -Name “InstallLocation” -Value $($thisSubKey.GetValue(“InstallLocation”))

        $obj | Add-Member -MemberType NoteProperty -Name “Publisher” -Value $($thisSubKey.GetValue(“Publisher”))

        $array += $obj

    } 

}

$array = $array | Where-Object { $_.DisplayName } 
return $array

}#>

Function Get-InstalledSoftware{
<#
.Synopsis
Generates a list of installed programs on a computer

.DESCRIPTION
This function generates a list by querying the registry and returning the installed programs of a local or remote computer.

.NOTES   
Name       : Get-RemoteProgram
Author     : Jaap Brasser
Version    : 1.3
DateCreated: 2013-08-23
DateUpdated: 2016-08-26
Blog       : http://www.jaapbrasser.com

.LINK
http://www.jaapbrasser.com

.PARAMETER ComputerName
The computer to which connectivity will be checked

.PARAMETER Property
Additional values to be loaded from the registry. Can contain a string or an array of string that will be attempted to retrieve from the registry for each program entry

.PARAMETER ExcludeSimilar
This will filter out similar programnames, the default value is to filter on the first 3 words in a program name. If a program only consists of less words it is excluded and it will not be filtered. For example if you Visual Studio 2015 installed it will list all the components individually, using -ExcludeSimilar will only display the first entry.

.PARAMETER SimilarWord
This parameter only works when ExcludeSimilar is specified, it changes the default of first 3 words to any desired value.

.EXAMPLE
Get-RemoteProgram

Description:
Will generate a list of installed programs on local machine

.EXAMPLE
Get-RemoteProgram -ComputerName server01,server02

Description:
Will generate a list of installed programs on server01 and server02

.EXAMPLE
Get-RemoteProgram -ComputerName Server01 -Property DisplayVersion,VersionMajor

Description:
Will gather the list of programs from Server01 and attempts to retrieve the displayversion and versionmajor subkeys from the registry for each installed program

.EXAMPLE
'server01','server02' | Get-RemoteProgram -Property Uninstallstring

Description
Will retrieve the installed programs on server01/02 that are passed on to the function through the pipeline and also retrieves the uninstall string for each program

.EXAMPLE
'server01','server02' | Get-RemoteProgram -Property Uninstallstring -ExcludeSimilar -SimilarWord 4

Description
Will retrieve the installed programs on server01/02 that are passed on to the function through the pipeline and also retrieves the uninstall string for each program. Will only display a single entry of a program of which the first four words are identical.
#>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(ValueFromPipeline              =$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0
        )]
        [string[]]
            $ComputerName = $env:COMPUTERNAME,
        [Parameter(Position=0)]
        [string[]]
            $Property,
        [switch]
            $ExcludeSimilar,
        [int]
            $SimilarWord
    )

    begin {
        $RegistryLocation = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\',
                            'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\'
        $HashProperty = @{}
        $SelectProperty = @('ProgramName','ComputerName')
        if ($Property) {
            $SelectProperty += $Property
        }
    }

    process {
        foreach ($Computer in $ComputerName) {
            $RegBase = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,$Computer)
            $RegistryLocation | ForEach-Object {
                $CurrentReg = $_
                if ($RegBase) {
                    $CurrentRegKey = $RegBase.OpenSubKey($CurrentReg)
                    if ($CurrentRegKey) {
                        $CurrentRegKey.GetSubKeyNames() | ForEach-Object {
                            if ($Property) {
                                foreach ($CurrentProperty in $Property) {
                                    $HashProperty.$CurrentProperty = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue($CurrentProperty)
                                }
                            }
                            $HashProperty.ComputerName = $Computer
                            $HashProperty.ProgramName = ($DisplayName = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue('DisplayName'))
                            if ($DisplayName) {
                                New-Object -TypeName PSCustomObject -Property $HashProperty |
                                Select-Object -Property $SelectProperty
                            } 
                        }
                    }
                }
            } | ForEach-Object -Begin {
                if ($SimilarWord) {
                    $Regex = [regex]"(^(.+?\s){$SimilarWord}).*$|(.*)"
                } else {
                    $Regex = [regex]"(^(.+?\s){3}).*$|(.*)"
                }
                [System.Collections.ArrayList]$Array = @()
            } -Process {
                if ($ExcludeSimilar) {
                    $null = $Array.Add($_)
                } else {
                    $_
                }
            } -End {
                if ($ExcludeSimilar) {
                    $Array | Select-Object -Property *,@{
                        name       = 'GroupedName'
                        expression = {
                            ($_.ProgramName -split $Regex)[1]
                        }
                    } |
                    Group-Object -Property 'GroupedName' | ForEach-Object {
                        $_.Group[0] | Select-Object -Property * -ExcludeProperty GroupedName
                    }
                }
            }
        }
    }
}

function Get-ODBCConfig {  
param( 
[parameter(Mandatory=$true,ValueFromPipeline=$True)]
[String]$Server
)  
    if(Test-Connection $Server -Count 1 -Quiet){
      
        # cycle through the odbc and odbc32 keys  
        $keys = "SOFTWARE\ODBC\ODBC.INI", "SOFTWARE\Wow6432Node\ODBC\ODBC.INI" 
         
        foreach ($key in $keys){  

            # open remote registry  
            $type = [Microsoft.Win32.RegistryHive]::LocalMachine  
            $srcReg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($type, $Server)  
            $OdbcKey = $srcReg.OpenSubKey($key)

            # read through each key  
            foreach ($oDrvr in $OdbcKey.GetSubKeyNames()){
              
                # form the key path  
                $sKey = $key + "\" + $oDrvr  
                $oDrvrKey = $srcReg.OpenSubKey( $sKey )  
                # cycle through each value, capture the key path, name, value and type  
                foreach ( $oDrvrVal in $oDrvrKey.GetValueNames()){  
                        $regObj = New-Object psobject -Property @{
                        Server = $Server
                        Path = $sKey  
                        Name = $oDrvrVal  
                        Value = $oDrvrKey.GetValue($oDrvrVal)  
                        Type = $oDrvrKey.GetValueKind($oDrvrVal)  
                    }  
                # dump each to the console 
                $regObj   
                }  
            }  
        }  
    }  
    # can't ping  
    else {
        Write-Warning "$Server offline"
    }  
}  

function Get-ServerInfo{
param(
[parameter(Mandatory=$true,ValueFromPipeline=$True)]
[string]$Server,
[parameter(Mandatory=$false)]
[string]$Vmware = "knetvc2001",
[string]$LogPath = "C:\temp\"+(Get-Date -Format yyMMdd)+"\$Server",
[string]$ScheduledTaskLogPath = "$server - ScheduledTask_Log.csv",
[string]$ServicesLogPath = "$server - Services_Log.csv",
[string]$IISLogPath = "$server - IIS_Log.csv",
[string]$InstalledSoftwareLogPath = "$server - InstalledSoftware_Log.csv",
[string]$ComputerInfoLogPath = "$server - ComputerInfo_Log.csv",
[string]$ODBCLogPath = "$Server - ODBCInfo_Log.csv"
)

#Felhantering
$vmsnapin = Get-PSSnapin VMware.VimAutomation.Core -ErrorAction SilentlyContinue
    try{
        Import-Module webadministration
        Write-Host "IIS Module was successfully enabled." -ForegroundColor Green
    }
    catch{
        Write-Host "ISS Module not installed on $env:COMPUTERNAME" -ForegroundColor Red
        exit
    }

    if($vmsnapin -eq $null){
	    Add-PSSnapin VMware.VimAutomation.Core
	        if($error.Count -eq 0){
		        write-host "PowerCLI VimAutomation.Core Snap-in was successfully enabled." -ForegroundColor Green
		    }
	        else{
		        write-host "ERROR: Could not enable PowerCLI VimAutomation.Core Snap-in, exiting script" -ForegroundColor Red
	        Exit
		    }
	}
    else{
	    Write-Host "PowerCLI VimAutomation.Core Snap-in is already enabled" -ForegroundColor Green
	}
    
    Write-Host "Testing if logfolder exist.." -ForegroundColor Green
    if(Test-Path $LogPath){
        Write-host "$LogPath exist" -ForegroundColor Green
    }
    else{
        Write-Host "$LogPath doesnt exist. Creating folder." -ForegroundColor Red
        New-Item -Path $LogPath -ItemType Directory
    }

    #Connect to vmware
    Connect-VIServer $Vmware

    #Create custom object
    $OutPutObject = New-Object System.Object
    $OutPutObjectScheduledTask = New-Object System.Object

    #Save current Server in the customobject
    $OutPutObject | Add-Member -Type NoteProperty -Name "ServerName" -Value $server
    $OutPutObjectScheduledTask | Add-Member -Type NoteProperty -Name "ServerName" -Value $server

    #Get server info.
    $VM = Get-VM -Name $Server
    $VMDisk = $vm | Get-View
    $memory = $Vm.MemoryGB
    $numcpu = $Vm.NumCpu
    $Harddrives = $VMDisk.Guest.Disk
    $HdNumber = -1

        foreach($HD in $Harddrives){
            
            $HdNumber = $HdNumber + 1
            $HDName = $Hd.diskpath
            $HDCapacity = $Hd.Capacity | foreach {[math]::Round($_ / 1GB)}
            $HDFree = $Hd.FreeSpace | foreach {[math]::Round($_ / 1GB)}
            $HDPercentFree = $HD | foreach{[math]::Round(((100 * ($_.FreeSpace))/ ($_.Capacity)),0)}
            

            $OutPutObject | Add-Member -Type NoteProperty -Name "HD_$HdNumber" -Value "$HDName"
            $OutPutObject | Add-Member -Type NoteProperty -Name "HD_Capacity_$HdNumber" -Value "$HDCapacity GB"
            $OutPutObject | Add-Member -Type NoteProperty -Name "HD_FreeSpace(GB)_$HdNumber" -Value "$HDFree GB"
            $OutPutObject | Add-Member -Type NoteProperty -Name "HD_FreeSpace(%)_$HdNumber" -Value "$HDPercentFree%"

        }

    $OutPutObject | Add-Member -Type NoteProperty -Name "Memory" -Value "$memory GB"
    $OutPutObject | Add-Member -Type NoteProperty -Name "Number_OF_CPUs" -Value "$numcpu"

    #Get all scheduled task and IIS-Sites and output them in seperate object
    try{
        Enter-PSSession $Server
        $allTask = Get-ScheduledTask

        #Inventera IIS
        $IISSites = Get-Website -name *
        $IISSites | Export-CSv "$LogPath\$IISLogPath"
        Write-Host "All IIS-Sites has been saved to $LogPath\$IISLogPath" -ForegroundColor Green
        $allTask | Export-Csv "$LogPath\$ScheduledTaskLogPath"
        Write-Host "All scheduledtask has been saved to $LogPath\$ScheduledTaskLogPath" -ForegroundColor Green
        Exit-PSSession
    }
    catch{
        Write-Warning "Cant connect with WINRM to $server"
        return
    }

    #Get ODBC connections
    try{
        $ODBC = Get-OdbcConfig -Server $Server
            If($ODBC -ne $null){
                $ODBC | Export-Csv "$LogPath\$ODBCLogPath"
                Write-Host "ODBC info has been saved to $LogPath\$ODBCLogPath" -ForegroundColor Green
            }
            else{
                Write-Host "No ODBC settings on $server" -ForegroundColor Yellow
            }
    }
    catch{
        Write-Host "Could not inventory ODBC on $server" -ForegroundColor Red
    }

    #Get services and export to csv
    $AllServices = Get-Service -ComputerName $Server
    $AllServices | Export-Csv "$LogPath\$ServicesLogPath"
    Write-Host "All Services has been saved to $LogPath\$ServicesLogPath" -ForegroundColor Green

    #Get installed Software
    $InstalledSoftware = Get-InstalledSoftware -ComputerName $Server
    $InstalledSoftware | Export-Csv "$LogPath\$InstalledSoftwareLogPath"   
    Write-Host "All installed Software has been saved to $LogPath\$InstalledSoftwareLogPath" -ForegroundColor Green

    #Output Computerinfo
    $OutPutObject | Export-Csv "$LogPath\$ComputerInfoLogPath"
    Write-Host "All computer info as shown velow has been saved to $LogPath\$ComputerInfoLogPath" -ForegroundColor Green
    return $OutPutObject
}


