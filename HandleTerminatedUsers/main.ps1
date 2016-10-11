$getuser = Get-aduser -filter * -Properties * -SearchBase "OU=,DC=se" -Properties *
$getDate = (Get-Date).AddDays(-30)

$date = Get-Date -format "dd-MMM-yyyy"
$logpath = "C:\Scripts\CleanUpTerminatedUsers\Logs\$date"+"_Logfile.txt"


#Function to log
function saveLog($textToSave)
{
    $now = Get-Date -format "dd-MMM-yyyy HH:mm"
    $textToSave = "`n" + $textToSave + " - $now"

    $textToSave | Out-File $logpath -Encoding utf8 -Append
}

#Utility
function deleteHomeFolder($folderToRemove){
    try{
            New-Item -Path "C:\temp\EmptyDummyFolder\" -ItemType Directory
            robocopy.exe "C:\Temp\EmptyDummyFolder\" "$folderToRemove" /MIR
            Remove-Item -Path "C:\Temp\EmptyDummyFolder\" -Force -Recurse
            Remove-Item -Path $folderToRemove -Force -Recurse
            $logg = "$folderToRemove has been Removed."
            saveLog($logg)
            
        }
    catch{
    $logg = "ERROR: $folderToRemove hasnt been removed!"
    saveLog($logg)
    }
    
}

#Utility
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

#Utility
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

#Main Function
function handleUsers(){
$logg = "Script started----------------"
saveLog($logg)
    foreach($item in $getuser){
        $userWhenChange = $item.modifyTimeStamp
        $samaccountName = $item.SamAccountName
        $homeFolder = $item.HomeDirectory
        $homefolder2 = $homeFolder+"_Quit"
        
         
            if($getDate -gt $userWhenChange){
            #>30days

            Remove-ADUser -Identity $samaccountName -Confirm:$false
            $logg = "ADUser $samaccountname has been removed."
            saveLog($logg)

                if(Test-Path $homefolder2){
                    deleteHomeFolder($homefolder2)
                }
                else{
                    $logg = "Cant find $homefolder2. Will not try to delete this folder."
                    saveLog($logg)
                }

            }
            else{
            #<30days
            disableUser($samaccountName)
            renameFolder $homeFolder $samAccountname"_Quit"
            }    
    }
    $logg = "Script ended.`n------------------"
    saveLog($logg)
}

#handleUsers
