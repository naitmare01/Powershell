$base = "OU=ASP,OU=Kyrkan,DC=david,DC=local"
$oun = Get-ADOrganizationalUnit -filter{Name -Like "*Test*"} -SearchBase $base

Foreach($ou in $oun){
#$testDn = $Ou.DistinguishedName
$testUsers = Get-ADUser -Filter * -SearchBase $testDn
    
    foreach($users in $testUsers){
    disableUser($users)
    }
}

function errorHandling{
    $errormsg = ($error[0].CategoryInfo.Activity)
    $errormsg = $errormsg + " " + $error[0].Exception.Message
    Write-Warning "An error occurred: $errormsg"
}


function disableUser($userToDisable){

    try{
        Disable-ADAccount "samaccountName"
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
