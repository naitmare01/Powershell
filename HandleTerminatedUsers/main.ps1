$getuser = Get-aduser -filter * -SearchBase "OU=Slutat,OU=User,DC=david,DC=local" -Properties *
$getDate = (Get-Date).AddDays(-30)

#Utility
function deleteHomeFolder(){
        New-Item -Path "C:\temp\Test\" -ItemType Directory
        robocopy.exe "C:\Temp\Test" "$movedest" /MIR
        Remove-Item -Path "C:\Temp\Test" -Force -recurse
}

#Utility
function renameFolder($folderToRename,$sam){
    $oldName = Get-Item $folderToRename
    $oldName = $oldName.Name
    Rename-Item $folderToRename -NewName "$sam"
}

#Utility
function disableUser($userToDisable){
Disable-ADAccount -Identity $userToDisable
    if($userToDisable -match "quit"){
        #Do nothing
        }
    else{
        Set-ADUser $userToDisable -SamAccountName "$userToDisable-quit"
        }
}

#Main Function
function handleUsers(){
    foreach($item in $getuser){
        $userWhenChange = $item.modifyTimeStamp
        $samaccountName = $item.SamAccountName
        $homeFolder = $item.HomeDirectory
         
            if($getDate -gt $userWhenChange){
            #>30days

            Remove-ADUser -Identity $samaccountName -Confirm:$false
            #LOGGA
            deleteHomeFolder
            #LOGGA
            }
            else{
            #<30days
            disableUser($samaccountName)
            #LOGGA
            renameFolder $homeFolder "Quit_$samAccountname"
            #LOGGA
            }    
    }
}

