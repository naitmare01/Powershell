
function errorHandling{
    $errormsg = ($error[0].CategoryInfo.Activity)
    $errormsg = $errormsg + " " + $error[0].Exception.Message
    Write-Warning "An error occurred: $errormsg"
}


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
