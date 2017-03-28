function Get-StiftAndEnhet{
param(
[parameter(Mandatory=$true,ValueFromPipeline=$True)]
[string]$Distinguishedname
)

#construct custom Object
$CustomObject = New-Object System.Object
    $enheten = $distinguishedname.Split(',')[2]
    $enheten =$enheten -replace ("OU=","")

    $stift = $distinguishedname.Split(',')[3]
    $stift = $stift -replace("OU=","")

    $CustomObject | Add-Member -Type NoteProperty -Name "Enhet" -Value $enheten
    $CustomObject | Add-Member -Type NoteProperty -Name "Stift" -Value $stift

    # Return the value
    return $CustomObject
}
