#Get Credentials from SPN and connect to EXO
$Credentials = Get-AutomationConnection -Name AzureRunAsConnection
Connect-ExchangeOnline -appid $Credentials.ApplicationID -CertificateThumbprint $Credentials.CertificateThumbprint -Organization domain.onmicrosoft.com

#Distribution group: Filter
$DistributionHashList = @{
    'dl@domain.onmicrosoft.com' = "customattribute3 -like '*dl@domain.onmicrosoft.com*' -or (((customattribute1 -eq 'abc') -or (customattribute1 -eq '123') -or (customattribute1 -eq '456') -or (customattribute1 -eq '234')) -and (title -like '*chef*') -and (recipienttypedetails -eq 'Usermailbox') -and -not(UserAccountControl -eq 'AccountDisabled, NormalAccount'))";
}#End hashtable

#Update each DL from hash-table.
foreach($key in $DistributionHashList.Keys){
    try{
        Get-DistributionGroup $key -ErrorAction Stop | Out-Null
    }#End try
    catch{
        Write-Error "$key doesnt exist."
        continue
    }#End catch

    $currentMembers = Get-DistributionGroupMember $key | Select-Object -ExpandProperty PrimarySmtpAddress
    $allmembersNonBroken = Get-Recipient -filter $DistributionHashList.$key

    if($currentMembers.count -eq 0){
        Write-Output "$key is empty, adding all members from filter."
        foreach($mem in $allmembersNonBroken){
            $smtpoutput = $mem.PrimarySmtpAddress
            Write-Output "Adding $smtpoutput to $key"
        }#End foreach
        try{
            $allmembersNonBroken | Select-Object -ExpandProperty PrimarySmtpAddress | Add-DistributionGroupMember -identity $key -confirm:$false -ErrorAction Stop
        }#End try
        catch{
            Write-Error "Something went wrong when populating $key for the first time"
        }#End catch
    }#End if
    elseif($currentMembers.count -ne 0){
        $compare = Compare-Object -ReferenceObject $currentMembers -DifferenceObject ($allmembersNonBroken | Select-Object -ExpandProperty PrimarySmtpAddress)
        if($compare){
            foreach($update in $compare){
                $usertoupdate = ($allmembersNonBroken | Where-Object{$_.PrimarySmtpAddress -like $update.InputObject} | Select-Object -ExpandProperty PrimarySmtpAddress)
                if($update.SideIndicator -like "=>"){
                    Write-Output "Adding $usertoupdate to $key"
                    try{
                        Add-DistributionGroupMember -Identity $key -Member $usertoupdate -confirm:$false -ErrorAction Stop
                    }#End try
                    catch{
                        Write-Error "Something went wrong when adding $usertoupdate from $key"
                    }#End catch
                }#End if
                else{
                    $usertoremove = (Get-Recipient $update.InputObject | Select-Object -ExpandProperty PrimarySmtpAddress)
                    Write-Output "Removing $usertoremove from $key"
                    try{
                        Remove-DistributionGroupMember -Identity $key -Member $usertoremove -confirm:$false -ErrorAction Stop
                    }#End try
                    catch{
                        Write-Error "Something went wrong when removing $usertoupdate from $key"
                    }#End catch
                }#End else
            }#End foreach
        }#End if
        else{
            Write-OutPut "$key has correct membership. Wont add or remove."
        }#End else
    }#End if
}#End foreach

#Disconnect from EXO
Disconnect-ExchangeOnline -Confirm:$false