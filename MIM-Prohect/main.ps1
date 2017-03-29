
function Get-StiftAndEnhet{
param(
[parameter(Mandatory=$true,ValueFromPipeline=$True)]
[string]$Distinguishedname
)

#construct custom Object
$CustomObject = New-Object System.Object
    $enheten = $distinguishedname.Split(',')[2]
    $enheten = $enheten -replace ("OU=","")

    $stift = $distinguishedname.Split(',')[3]
    $stift = $stift -replace("OU=","")

    $CustomObject | Add-Member -Type NoteProperty -Name "Enhet" -Value $enheten
    $CustomObject | Add-Member -Type NoteProperty -Name "Stift" -Value $stift

    # Return the value
    return $CustomObject
}

#Denna funktion tar ut GIP-Status + enhet och stift.
function Get-GipStatus{
param(
[parameter(Mandatory=$true,ValueFromPipeline=$True)]
[object]$User
)
    $distinguishedname = $User.DistinguishedName
    #construct custom Object
    $CustomObject = New-Object System.Object
    
    if($User.Memberof -match "G.Usr.*.GIP"){

        $GIPStatus = "GIP"

    }
    else{

        $GIPStatus = "EJ_GIP"

    }

    #Append user enhet and stift to the object
    $enheten = $distinguishedname.Split(',')[2]
    $enheten = $enheten -replace ("OU=","")

    $stift = $distinguishedname.Split(',')[3]
    $stift = $stift -replace("OU=","")

    $CustomObject | Add-Member -Type NoteProperty -Name "GIPStatus" -Value $GIPStatus
    $CustomObject | Add-Member -Type NoteProperty -Name "samaccountName" -Value $user.Samaccountname
    $CustomObject | Add-Member -Type NoteProperty -Name "Enhet" -Value $enheten
    $CustomObject | Add-Member -Type NoteProperty -Name "Stift" -Value $stift

    # Return the value
    return $CustomObject
}

#Function to clean string from illegal chars
function Clean-String{
param(
[parameter(Mandatory=$true,ValueFromPipeline=$True)]
[string]$StringToClean
)
    
    #convert to lower
    $stringToClean = $stringToClean.ToLower()

    #replace illegal chars.
    $stringToClean = $stringToClean -replace "[åÅäÄâàá]", "a"
    $stringToClean = $stringToClean -replace "[öÖôòó]", "o"
    $stringToClean = $stringToClean -replace "[éêëèÉ]", "e"
    $stringToClean = $stringToClean -replace "[üùúÜ]", "u"
    $stringToClean = $stringToClean -replace "[ñÑ]", "n"
    $stringToClean = $stringToClean -replace "[íìï]", "i"
    $stringToClean = $stringToClean -replace "[æÆ]", "ae"
    $stringToClean = $stringToClean -replace " ", ""
    $stringToClean = $stringToClean -replace "-", ""
    $stringToClean = $stringToClean -replace ":", ""

    return $StringToClean

}

#function to test if samaccountname is free. Return TRUE or FALSE.
function Test-Samaccountname{
param(
[parameter(Mandatory=$true,ValueFromPipeline=$True)]
[string]$Samaccountname
)
    try{
        Get-aduser $samaccountname
        return $false
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
        return $true
    }
}

function Get-SamaccountName{
param(
[parameter(Mandatory=$true,ValueFromPipeline=$True)]
[object]$User
)

    #var declartion
    $firstname = $User.GivenName
    $lastname = $User.SurName
    $CurrentSam = $User.SamaccountName
    $OutPutObject = New-Object System.Object

    #Save current sam in the customobject
    $OutPutObject | Add-Member -Type NoteProperty -Name "CurrentSAM" -Value $CurrentSAM

    #test if lastname exist.
    #test if firstname exist.
    if($firstname -eq $null){
        Write-Warning "$CurrentSam is missing firstname"
        $OutPutObject| Add-Member -Type NoteProperty -Name "NewSAM"-Value "MISSING_FIRSTNAME"
        return $OutPutObject
    }
    elseif($lastname -eq $null){
        Write-Warning "$CurrentSam is missing lastname"
        $OutPutObject| Add-Member -Type NoteProperty -Name "NewSAM"-Value "MISSINGLASTNAME"
        return $OutPutObject
    }

    #clean firstname and lastname from illegal chars.
    $firstname = Clean-String -StringToClean $firstname
    $lastname = Clean-String -StringToClean $lastname

    #declare fullname in one string
    [string]$fullName = "$firstname$lastname"
        
        #If lastname is less then 5 char append 0 to the end.
        #elseif fullname is less then 8 char append 0 to the end. 
        if($lastname.Length -lt 5){
            
            #Get number of Zeroes to add to lastname
            $zerosToAdd = 5 - $fullName.Length
            $numArray = 1..$zerosToAdd
            foreach($z in $numArray){
                $lastname += "0"
            }
        }
        elseif($fullName.Length -lt 8){
            
            #Get number of Zeroes to add to lastname
            $zerosToAdd = 8 - $fullName.Length
            $numArray = 1..$zerosToAdd
            foreach($z in $numArray){
                $lastname += "0"
            }
        }

        
    #Get first 3 first char from firstname and 5 first char lastname
    #If firstname is shorter then 3 chars dont substring on firstname, substring lastname based on chars. 
    if($firstname.length -lt 3){
        #Write-Host "$FirstName is shorter then 3 chars. Do Nothing"
        $shortFirstName = $firstname
        $cutLength = 8 - $firstname.Length
        $shortLastName = $lastname.Substring(0,$cutLength)
    }
    else{
        $shortFirstName = $firstname.Substring(0,3)
        $shortLastName = $lastname.Substring(0,5)
    }
    
    #Merge firstname and lastname to one string that is samaccountname
    [string]$stringToClean = "$shortFirstName$shortLastName"

    #Logic to check if samaccountname already is correct
    if($CurrentSam -like $stringToClean){
        #Sam is already correct. Do nothing.
        $OutPutObject| Add-Member -Type NoteProperty -Name "NewSAM"-Value "NO_CHANGE"
        return $OutPutObject
    }

    #Logic to try if sam if taken or not. 
    $Test = $stringToClean | Test-Samaccountname
    
    if($test -eq $true){
        #Write-host "$stringToClean is free" -ForegroundColor Green
        $OutPutObject| Add-Member -Type NoteProperty -Name "NewSAM"-Value $stringToClean
    }
    else{
        #Write-Host "$stringToClean is not free" -ForegroundColor Red
        [int]$i = -1
            #loop to generate sam based on numbers.
            while($Test -like $false){
                if($i -eq 9){
                    Write-Warning "to many numbers $stringToClean"
                    return
                }
                else{
                    $i = $i + 1
                }
                $cutName = $stringToClean.Substring(0,$stringToClean.Length-1)
                $cutName = $cutName + "$i"
                $test = $cutName | Test-Samaccountname
            }
            #Write-Host "$cutName is the new sam" -ForegroundColor Green
            $OutPutObject| Add-Member -Type NoteProperty -Name "NewSAM"-Value $cutName

    }   
    return $OutPutObject
}
