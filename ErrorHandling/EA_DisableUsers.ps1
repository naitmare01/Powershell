
function Get-ErrorReason{
    [cmdletbinding()]
    param(
    )
    begin{}

    process{
        $errormsg = ($error[0].CategoryInfo.Activity)
        $errormsg = $errormsg + " " + $error[0].Exception.Message
        $errormsg = "An error occurred: $errormsg"
    }

    end{
        return $errormsg
    }
}


try{
    Disable-ADAccount "samaccountName"
}
#Object not found
catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]
{
    Get-ErrorReason
}
#Insufficient rights
catch [Microsoft.ActiveDirectory.Management.ADException]
{
    Get-ErrorReason
}
#Other issue
catch{
    Get-ErrorReason
}
