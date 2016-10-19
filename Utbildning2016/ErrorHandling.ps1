function saveLog($textToSave)
{
    $now = Get-Date -format "dd-MMM-yyyy HH:mm"
    $textToSave = "`n" + $textToSave + " - $now"

    $textToSave | Out-File $logpath -Encoding utf8 -Append
}


function errorHandling{
    $errormsg = ($error[0].CategoryInfo.Activity)
    $errormsg = $errormsg + " " + $error[0].Exception.Message
    $errorToLog = "An error occurred: $errormsg"
    saveLog($errorToLog)
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
