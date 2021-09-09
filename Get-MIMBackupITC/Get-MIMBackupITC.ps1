
$attributes = "c",
"co",
"carLicense",
"company",
"displayName",
"countryCode",
"department",
"mailNickname",
"mail",
"description",
"mobile",
"postalAddress",
"postalCode",
"sn",
"streetAddress",
"telephoneNumber",
"physicalDeliveryOfficeName",
"extensionAttribute15"

$users = Get-ADuser -Filter{samaccountname -like "atea.david" -or samaccountname -like "76annols"} -properties c,co,carLicense,company,displayName,countryCode,department,mailNickname,mail,description,mobile,postalAddress,postalCode,sn,streetAddress,telephoneNumber,physicalDeliveryOfficeName,extensionAttribute15
#$users = Get-ADuser -Filter{samaccountname -like "atea.david" -or samaccountname -like "76annols"} -properties c,co,carLicense,company,displayName,countryCode,department,mail,description,mobile,postalAddress,postalCode,sn,streetAddress,telephoneNumber,physicalDeliveryOfficeName

$returnArray = [System.Collections.ArrayList]@()

foreach($u in $users){
    $CustomObject = New-Object System.Object

    foreach($attr in $attributes){
        if($attr -notin $u.PSObject.Properties.Name){
            $CustomObject | Add-Member -Type NoteProperty -Name $attr -Value $null
        }#End if
    }#End foreach

    foreach($property in $u.PSObject.Properties){
        if($property.IsSettable){
            if($property.name -like 'carLicense'){
                $value = [string]$property.Value
            }#End if
            else{
                $value = $property.value
            }#End else
            $CustomObject | Add-Member -Type NoteProperty -Name $property.name -Value $value
        }#End if
    }#End foreach
    $returnArray.add($CustomObject) | Out-Null
}#End foreach


$returnArray | Export-Csv C:\Users\david\Desktop\orginal.csv -Encoding UTF8


####
# Import and reset part below

$ImportedUsers = Import-Csv C:\Users\david\Desktop\orginal.csv -Encoding UTF8

foreach($item in $ImportedUsers){
    $user = Get-ADuser $item.DistinguishedName -properties c,co,carLicense,company,displayName,countryCode,department,mailNickname,mail,description,mobile,postalAddress,postalCode,sn,streetAddress,telephoneNumber,physicalDeliveryOfficeName,extensionAttribute15
    #$user = Get-ADuser $item.DistinguishedName -properties c,co,carLicense,company,displayName,countryCode,department,mail,description,mobile,postalAddress,postalCode,sn,streetAddress,telephoneNumber,physicalDeliveryOfficeName
    foreach($attr in $attributes){
        if($user.$attr -notlike $item.$attr){
            if($attr -like 'c'){
                Set-ADuser -identity $item.DistinguishedName -Replace @{c=$item.c;co=$item.co;countrycode=$item.countrycode}
            }#End if

            if($attr -like 'co' -or $attr -like 'countrycode'){
                continue
            }#End if

            if($attr -like 'carlicense'){
                if($null -like $item.carlicense){
                    Set-ADuser -identity $item.DistinguishedName -Clear carlicense
                }#End if
                else{
                    Set-ADuser -identity $item.DistinguishedName -Clear carlicense
                    Set-ADuser -identity $item.DistinguishedName -Add @{carlicense=$item.carlicense}
                }#End else
            }#End if

            if($attr -like 'company'){
                if($null -like $item.company){
                    Set-Aduser -identity $item.DistinguishedName -Clear Company
                }#End if
                else{
                    Set-Aduser -identity $item.DistinguishedName -Company $item.Company
                }#End else
            }#End if

            if($attr -like 'department'){
                if($null -like $item.department){
                    Set-Aduser -identity $item.DistinguishedName -Clear department
                }#End if
                else{
                    Set-Aduser -identity $item.DistinguishedName -department $item.department
                }#End else
            }#End if

            if($attr -like 'Description'){
                if($null -like $item.Description){
                    Set-Aduser -identity $item.DistinguishedName -Clear Description
                }#End if
                else{
                    Set-Aduser -identity $item.DistinguishedName -Description $item.Description
                }#End else
            }#End if

            if($attr -like 'DisplayName'){
                if($null -like $item.DisplayName){
                    Set-Aduser -identity $item.DistinguishedName -Clear DisplayName
                }#End if
                else{
                    Set-Aduser -identity $item.DistinguishedName -DisplayName $item.DisplayName
                }#End else
            }#End if

            if($attr -like 'GivenName'){
                if($null -like $item.GivenName){
                    Set-Aduser -identity $item.DistinguishedName -Clear GivenName
                }#End if
                else{
                    Set-Aduser -identity $item.DistinguishedName -GivenName $item.GivenName
                }#End else
            }#End if

            if($attr -like 'mail'){
                if($null -like $item.mail){
                    Set-Aduser -identity $item.DistinguishedName -Clear mail
                }#End if
                else{
                    Set-Aduser -identity $item.DistinguishedName -EmailAddress $item.mail
                }#End else
            }#End if

            if($attr -like 'mobile'){
                if($null -like $item.mobile){
                    Set-Aduser -identity $item.DistinguishedName -Clear mobile
                }#End if
                else{
                    Set-Aduser -identity $item.DistinguishedName -MobilePhone $item.mobile
                }#End else
            }#End if

            if($attr -like 'physicalDeliveryOfficeName'){
                if($null -like $item.physicalDeliveryOfficeName){
                    Set-Aduser -identity $item.DistinguishedName -Clear physicalDeliveryOfficeName
                }#End if
                else{
                    Set-Aduser -identity $item.DistinguishedName -Office $item.physicalDeliveryOfficeName
                }#End else
            }#End if

            if($attr -like 'postalAddress'){
                if($null -like $item.postalAddress){
                    Set-Aduser -identity $item.DistinguishedName -Clear postalAddress
                }#End if
                else{
                    Set-ADuser -identity $item.DistinguishedName -Clear postalAddress
                    Set-ADuser -identity $item.DistinguishedName -Add @{postalAddress=$item.postalAddress}
                }#End else
            }#End if

            if($attr -like 'PostalCode'){
                if($null -like $item.PostalCode){
                    Set-Aduser -identity $item.DistinguishedName -Clear PostalCode
                }#End if
                else{
                    Set-Aduser -identity $item.DistinguishedName -PostalCode $item.PostalCode
                }#End else
            }#End if

            if($attr -like 'SamAccountName'){
                if($null -like $item.SamAccountName){
                    Set-Aduser -identity $item.DistinguishedName -Clear SamAccountName
                }#End if
                else{
                    Set-Aduser -identity $item.DistinguishedName -SamAccountName $item.SamAccountName
                }#End else
            }#End if

            if($attr -like 'sn'){
                if($null -like $item.sn){
                    Set-Aduser -identity $item.DistinguishedName -Clear sn
                }#End if
                else{
                    Set-Aduser -identity $item.DistinguishedName -surname $item.sn
                }#End else
            }#End if

            if($attr -like 'StreetAddress'){
                if($null -like $item.StreetAddress){
                    Set-Aduser -identity $item.DistinguishedName -Clear StreetAddress
                }#End if
                else{
                    Set-Aduser -identity $item.DistinguishedName -StreetAddress $item.StreetAddress
                }#End else
            }#End if

            if($attr -like 'telephoneNumber'){
                if($null -like $item.telephoneNumber){
                    Set-Aduser -identity $item.DistinguishedName -Clear telephoneNumber
                }#End if
                else{
                    Set-Aduser -identity $item.DistinguishedName -OfficePhone $item.telephoneNumber
                }#End else
            }#End if

            if($attr -like 'UserPrincipalName'){
                if($null -like $item.UserPrincipalName){
                    Set-Aduser -identity $item.DistinguishedName -Clear UserPrincipalName
                }#End if
                else{
                    Set-Aduser -identity $item.DistinguishedName -UserPrincipalName $item.UserPrincipalName
                }#End else
            }#End if

            if($attr -like 'mailNickname'){
                if($null -like $item.mailNickname){
                    Set-Aduser -identity $item.DistinguishedName -Clear mailNickname
                }#End if
                else{
                    Set-ADuser -identity $item.DistinguishedName -Clear mailNickname
                    Set-ADuser -identity $item.DistinguishedName -Add @{mailNickname=$item.mailNickname}
                }#End else
            }#End if

            if($attr -like 'extensionAttribute15'){
                if($null -like $item.extensionAttribute15){
                    Set-Aduser -identity $item.DistinguishedName -Clear extensionAttribute15
                }#End if
                else{
                    Set-ADuser -identity $item.DistinguishedName -Clear extensionAttribute15
                    Set-ADuser -identity $item.DistinguishedName -Add @{extensionAttribute15=$item.extensionAttribute15}
                }#End else
            }#End if

        }#End
    }#End foreach
}#End foreach
