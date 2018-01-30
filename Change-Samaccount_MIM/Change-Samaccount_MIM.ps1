#Funktion för att hantera konton som inte hittas.
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

#Spara filen som csv och importera den. Byt ut sökvägen till där filen ligger.
#Linnea är den som tillhandahåller filen som .xlsx.
$input = import-csv 'C:\temp\Kyrkokansliet_2.csv' -Delimiter ';'



#Loopa igenom och byt, om allt går bra skrivs inget, om något går fel så kommer det att skrivas i shellen. Notera dessa i csven manuellt och skicka till Linnea.
foreach($i in $input){
    try{
        Get-Aduser $i.'Nuvarande användarnamn' | Set-ADUser -SamAccountName $i.'Nytt användarnamn' -ErrorAction Stop
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
        $output = Get-ErrorReason
        Write-Host "$output" "user has the current sam" $i.'Nuvarande användarnamn' "and wants to change to" $i.'Nytt användarnamn'
    }
}