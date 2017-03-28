<#
$User must be in an object form and inclube "-Properties memberof"
#>
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

    $CustomObject | Add-Member -Type NoteProperty -Name "GIP-Status" -Value $GIPStatus
    $CustomObject | Add-Member -Type NoteProperty -Name "samaccountName" -Value $user.Samaccountname
    $CustomObject | Add-Member -Type NoteProperty -Name "Enhet" -Value $enheten
    $CustomObject | Add-Member -Type NoteProperty -Name "Stift" -Value $stift

    # Return the value
    return $CustomObject
}
