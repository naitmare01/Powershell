$Search = [adsisearcher]"(SamAccountName=$env:USERNAME)"
$DN = $Search.FindOne().Properties.distinguishedname

$enheten = $dn.Split(',')[2]
$enheten =$enheten -replace ("OU=","")

$stift = $dn.Split(',')[3]
$stift = $stift -replace("OU=","")

Write-Host "Enheten är $enheten"
Write-Host "Stiftet är $stift"


[Environment]::SetEnvironmentVariable("Enhet","$enheten", "User")
[Environment]::SetEnvironmentVariable("Stift","$stift", "User")
