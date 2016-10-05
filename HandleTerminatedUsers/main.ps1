$getuser = Get-aduser -filter * -SearchBase "OU=Slutat,OU=User,DC=david,DC=local" -Properties *
$getDate = (Get-Date).AddDays(-30)

#Utility
function deleteHomeFolder($folderToRemove){

        New-Item -Path "C:\temp\Test\" -ItemType Directory
        robocopy.exe "C:\Temp\Test" "$folderToRemove" /MIR
        Remove-Item -Path "C:\Temp\Test" -Force -Recurse
        Remove-Item -Path $folderToRemove -Force -Recurse
    
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
        $homefolder2 = $homeFolder+"_Quit"
        
         
            if($getDate -gt $userWhenChange){
            #>30days

            Remove-ADUser -Identity $samaccountName -Confirm:$false
            #LOGGA
            deleteHomeFolder($homefolder2)
            #LOGGA

            }
            else{
            #<30days
            disableUser($samaccountName)
            #LOGGA
            renameFolder $homeFolder $samAccountname"_Quit"
            #LOGGA
            }    
    }
}
