$creationPath = "OU="
$group = "GROUPNAME"
$newPrimaryGroupID = "PRIMARYGROUPTOKENID"
$gt = (Get-ADGroup "GROUPNAME" -Properties primaryGroupToken).primaryGroupToken

import-csv -Encoding UTF8 "C:\temp\macusers.csv" | foreach{
$username = $_.username 
$des = $_.description
try{
#1 - New-ADUser -SamAccountName $username -Name $username -DisplayName $username -Description $des -PasswordNeverExpires:$true -CannotChangePassword:$true -Enabled:$false -UserPrincipalName "$username@knet.ad.svenskakyrkan.se" -Path $creationpath -GivenName $des -Confirm:$false
#1 - Set-ADAccountPassword $username -Reset -NewPassword (ConvertTo-SecureString -AsPlainText "$username" -Force) -Confirm:$false
#2 - Set-ADUser $username -Enabled:$true -Confirm:$false
#3 - Add-ADGroupMember -Identity $group $username -Confirm:$false
#3 - Set-ADUser $username -Replace @{primaryGroupID = $gt} -Confirm:$false
#3 - Remove-ADGroupMember -Identity "Domain Users" -Members $username -Confirm:$false
}
catch{
Write-Warning "Error: On $username"
}
}
