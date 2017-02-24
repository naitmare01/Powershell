<#
.Synopsis
   Samling funktioner för att hantera avslut av användarkonton. 
.DESCRIPTION
   Om whenChanged på AD-usern är mindre än 30 dagar 
.EXAMPLE
   handleUsers -searchbase "DistinguishedName" -logFileLocation "C:\Temp\File.txt
   Disablar alla konton under -Searchbase och sparar logg på jobbet i C:\Temp\File.txt
#>

$getDate = (Get-Date).AddDays(-30)
$getDate60 = (Get-Date).AddDays(-60)
$date = Get-Date -format "dd-MMM-yyyy"

#Function to log
function saveLog($textToSave)
{
    $now = Get-Date -format "dd-MMM-yyyy HH:mm"
    $textToSave = "`n" + $textToSave + " - $now"

    $textToSave | Out-File $logpath -Encoding utf8 -Append
}

#Funktion för att byta namn på citrix profildata
function renameProfileData($user){
    $arr = "1001", "2001", "3001"

    foreach($a in $arr){
        $root = Get-childitem \\knet.ad.svenskakyrkan.se\dfs01\profiles$a | ?{$_.PSIsContainer}
        
            foreach($r in $root){

                $fullname = $r.FullName
                    if(Test-path "$fullname\$user"){
                        #"Path Exist $fullname\$user"
                        $userFolder = Get-Item "$fullname\$user"
                        $fullNameOfUserFolder = $userFolder.FullName
                        $newName = $fullNameOfUserFolder+"_Quit"
                        Rename-Item $fullNameOfUserFolder -NewName $newName                        
                        $logg = "Old folder $folderToRename has changed name to $newName"
                        saveLog($logg)
                    }
                    else{
                        #Path not found
                    }

            }
    }
}

#Funktion för att ta bort citrix profildata
function deleteProfileData($user){
    $arr = "1001", "2001", "3001"

    foreach($a in $arr){
        $root = Get-childitem \\knet.ad.svenskakyrkan.se\dfs01\profiles$a | ?{$_.PSIsContainer}
        
            foreach($r in $root){

                $fullname = $r.FullName
                $quitUser = $user+"_Quit"
                    if(Test-path "$fullname\$quitUser"){
                            try{
                                $userFolder = Get-Item "$fullname\$user"
                                $folderToRemove = $userFolder.FullName
                                New-Item -Path "C:\temp\EmptyDummyFolderCtx\" -ItemType Directory
                                robocopy.exe "C:\Temp\EmptyDummyFolderCtx\" "$folderToRemove" /MIR
                                Remove-Item -Path "C:\Temp\EmptyDummyFolderCtx\" -Force -Recurse
                                Remove-Item -Path $folderToRemove -Force -Recurse
                                $logg = "$folderToRemove has been Removed."
                                saveLog($logg)
            
                                }
                                catch{
                                $logg = "ERROR: $user Ctx-folder hasnt been removed or finded!"
                                saveLog($logg)
                                }
                    }
                    else{
                        #Path not found
                    }

            }
    }
}

#Funktion för att delete %homeshare%
function deleteHomeFolder($folderToRemove){
    try{
            New-Item -Path "C:\temp\EmptyDummyFolderCtx\" -ItemType Directory
            robocopy.exe "C:\Temp\EmptyDummyFolderCtx\" "$folderToRemove" /MIR
            Remove-Item -Path "C:\Temp\EmptyDummyFolderCtx\" -Force -Recurse
            Remove-Item -Path $folderToRemove -Force -Recurse
            $logg = "$folderToRemove has been Removed."
            saveLog($logg)
            
        }
    catch{
    $logg = "ERROR: $folderToRemove hasnt been removed!"
    saveLog($logg)
    }
    
}

#Funktion för att byta namn på katalog
function renameFolder($folderToRename,$sam){

        if(Test-Path $folderToRename){
        $oldName = Get-Item $folderToRename
        $oldName = $oldName.Name
        Rename-Item $folderToRename -NewName "$sam"
        $logg = "Old folder $folderToRename has changed name to $sam"
        saveLog($logg)
        }
        
    else{
    $logg = "ERROR: $folderToRename hasnt changed name! Cant find folder."
    saveLog($logg)
    }
}

#Funktion för att disabla usern.
function disableUser($userToDisable){

try{
Disable-ADAccount -Identity $userToDisable
$logg = "ADUSer $userToDisable has been disabled."
saveLog($logg)
    if($userToDisable -match "quit"){
        #Do nothing
        }
    else{
        Set-ADUser $userToDisable -SamAccountName "$userToDisable-quit"
        $logg = "ADUser $userToDisable has changed samaccountname to $userToDisable-quit"
        saveLog($logg)
        }
    }
catch{
$logg = "ERROR: ADUser $userToDisable hasnt been disabled and/or changed samaccoutname."
saveLog($logg)
}
}

#Funktion för att sätta description på en användare om den inte har det sedan tidigare.
Function setDescription{
    param(
    [string]$samaccountname)

    $date = Get-Date -format "yyyy-MM-dd"
    $Descrip = "Stängt $date"

    $user = Get-ADUser $samaccountname -Properties description
    $oldDescription = $user.description
    $sam = $user.SamAccountName
    
        if($oldDescription -like "Stängt *"){
            $logg = "Description already on place on user $sam. Do nothing."
            saveLog($logg)
        }
        else{
            Set-ADUser $samaccountname -Description "$descrip"
            $logg = "Description set on user $sam."
            saveLog($logg)
        }
}

#Funktion för att cleara membership för en användare
Function RemoveMemberships{

    param(
    [string]$SAMAccountName)  
 
    $user = Get-ADUser $SAMAccountName -properties memberof
    $userGroups = $user.memberof
    $sam = $user.SamAccountName
    if($userGroups.count -eq 0){
    #Do nothing
    }
    else{
        try{
        $userGroups | %{get-adgroup $_ | Remove-ADGroupMember -confirm:$false -member $SAMAccountName}
            foreach($u in $userGroups){
                $logg = "Removed $u from $sam"
                saveLog($logg)
            }
        }
        catch{
        $logg = "Couldnt clear membership on user. $sam"
        saveLog($logg)
        }
    }
}

#Function to rename aduser.
function setSIDAsName{
    param(
    [string]$samaccountname)

        $user = Get-ADUser $samaccountname -Properties SID
        $SID = $user.sid.Value
        $sam = $user.SamAccountName
        $name = $user.Name
        $newName = "Stängt konto $sid"
        try{
            if($name -like "Stängt konto *"){
            #Do nothing
            }
            else{
            Rename-ADObject -Identity $user -NewName $newName
            $logg = "Changed name on $sam"
            saveLog($logg)
            }
        }
        catch{
            $logg = "Didnt change name on $sam"
            saveLog($logg)
        }

}

#Main Function thats calls other funciton.
function handleUsers(){
param(
[string]$searchbase,
[string]$logFileLocation
)
$logg = "Script started----------------"
$logpath = $logFileLocation
$getuser = Get-aduser -filter * -Properties * -SearchBase $searchbase
saveLog($logg)
    foreach($item in $getuser){
        $userWhenChange = $item.modifyTimeStamp
        $samaccountName = $item.SamAccountName
        $UserDn = $item.DistinguishedName
        $homeFolder = $item.HomeDirectory
        $enabled = $item.Enabled
        $homefolder2 = $homeFolder+"_Quit"
        
         
            if($getDate -ge $userWhenChange -and $getDate60 -lt $userWhenChange){
            #>30days
            #30-59 dagar
            
            <#
            Byt namn till SID
            Ta bort memberOF
            #>

                RemoveMemberships -SAMAccountName $samaccountName
                setSIDAsName -samaccountname $samaccountName


            }
            elseif($getDate60 -ge $userWhenChange){
            #>60days
            #60- dagar
            
            <#
            Radera Kontot
            Radera hemkatalog
            Radera Profilkatalog
            #>

                Get-ADuser $samaccountName | Remove-ADObject -Recursive -Confirm:$false
                $logg = "ADUser $samaccountname has been removed."
                saveLog($logg)
                                if(Test-Path $homefolder2){
                        deleteHomeFolder($homefolder2)
                    }
                    else{
                        $logg = "Cant find $homefolder2. Will not try to delete this folder."
                        saveLog($logg)
                    }
                
                deleteProfileData($samaccountName)
            }
            elseif($getDate -lt $userWhenChange -and $enabled -eq $true){
            #<30days + enabled = true
            #0-29 dagar
            #Disable kontot
            
            disableUser($samaccountName)
            }
            elseif($getDate -lt $userWhenChange -and $enabled -eq $true){
            <#
            30days + enabled = true
            #0-29 dagar
            Bytt namn på hemkatalogen
            Byt namn på profilkatalogen
            Sätt description
            #>
                
                renameFolder $homeFolder $samAccountname"_Quit"
                renameProfileData($samaccountName)
                setDescription -samaccountname $samaccountName
            
            }    
    }
    $logg = "Script ended.`n------------------"
    saveLog($logg)
}

handleUsers -searchbase "OU=Slutat,OU=Users,OU=ASP,DC=knet,DC=ad,DC=svenskakyrkan,DC=se" -logFileLocation "C:\Scripts\CleanUpTerminatedUsers\Logs\$date _Logfile.txt"
handleUsers -searchbase "OU=Trash,OU=ASP,DC=knet,DC=ad,DC=svenskakyrkan,DC=se" -logFileLocation "C:\Scripts\CleanUpTerminatedUsers\Logs\$date _TRASHOULogfile.txt"
