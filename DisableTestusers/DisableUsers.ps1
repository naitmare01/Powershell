<#
2016-10-20
David Berndtsson
Data Ductus
Uppsala

.Synopsis
   Detta script kommer att disabla alla användarkonton som ligger under Test-Oun i ASP-strukteren. 
   Scriptet kommer undanta alla användare som har ett värde(vilket som helst) i extensionAttrbitue6. Detta för att låta
   pågående införande ha sitt test-kontot enablad över natten. 
.DESCRIPTION
   Long description
.EXAMPLE
   Körs förslagsvis på schemalagd basis. 
   Om man vill återanvända detta script kan man ändra dom statiska variablarna till sina egna värden. 
.EXAMPLE
   Another example of how to use this cmdlet
#>

#Static variables.
$base = "OU=Users,DC="
$oun = Get-ADOrganizationalUnit -filter{Name -Like "*Test*"} -SearchBase $base
$logpath = "c:\Scripts\DisableTestUsers\Logs"

#Function to log
function saveLog($textToSave)
{
    $now = Get-Date -format "dd-MMM-yyyy HH:mm"
    $textToSave = "`n" + $textToSave + " - $now"

    $textToSave | Out-File $logpath -Encoding utf8 -Append
}

#Function to get latest errorlog.
function errorHandling{
    $errormsg = ($error[0].CategoryInfo.Activity)
    $errormsg = $errormsg + " " + $error[0].Exception.Message
    $log = "An error occurred: $errormsg"
    savelog($log)
}

#Funciton to disable user
function disableUser($userToDisable){

    try{
        Disable-ADAccount $userToDisable
        $log = "$userToDisable has been disabled."
        savelog($log)
    }
    #Object not found
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
    {
        errorHandling
    }
    #Insufficient rights
    catch [Microsoft.ActiveDirectory.Management.ADException]
    {
        errorHandling
    }
    #Other issue
    catch{
        errorHandling
    }

}

#Get all user to disable
Foreach($ou in $oun){
$testDn = $Ou.DistinguishedName
$testUsers = Get-ADUser -Filter{extensionAttribute6 -notlike "*"} -SearchBase $testDn
    
    foreach($users in $testUsers){
    disableUser($users)
    }
}
