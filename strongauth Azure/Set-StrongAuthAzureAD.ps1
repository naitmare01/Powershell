Connect-azuread
Connect-MsolService

$userupn = "User@dtenant"
$mobilenumber = "+46 7XXXXXXX"

Get-AzureADUser -ObjectId $userupn  | fl * 
Get-MSolUser -UserPrincipalName $userupn  | Select-Object -ExpandProperty StrongAuthenticationRequirements

Set-AzureADUser -ObjectId $userupn -Mobile $mobilenumber

$st = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
$st.RelyingParty = "*"
$st.State = "Enabled"
$sta = @($st)
Set-MsolUser -UserPrincipalName $userupn -StrongAuthenticationRequirements $sta
$sm = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationMethod
$sm.IsDefault = $true
$sm.MethodType = "OneWaySMS"
Set-MsolUser -UserPrincipalName $userupn -StrongAuthenticationMethods @($sm) 
