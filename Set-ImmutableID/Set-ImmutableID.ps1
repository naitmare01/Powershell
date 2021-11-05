function Get-UserInformation{
    [cmdletbinding()]
    param(
        [Parameter(mandatory=$true)] 
        $UserPrincipalNames #UPNs from the new and coming primary domian. E.g. if user is located in edunet and will be switched to domain, the UPN from domain should be provided.
    )#End param

    begin{
        $returnArray = [System.Collections.ArrayList]@()

        #Static Variables to connect to domain and azuread.
        if($null -eq $edunetcredential){
            $edunetcredential = Get-Credential -Message "Plese enter credential for edunet in netbios\samaccountname"
        }#End if
        if($null -eq $domaincredential){
            $domaincredential = Get-Credential -Message "Plese enter credential for domain in netbios\samaccountname"
        }#End if
        $creds = @{"domain.com" = $domaincredential
                   "subdomain.domain.com" = $edunetcredential}
        $OutOfSyncOUs = @{"domain.com" = "CN=Users,DC=domain,DC=se"
                          "edu.domain.com" = "CN=Users,DC=edunet,DC=domain,DC=se"}
        $Domains = @{"domain.com" = "edu.domain.com"
                     "edu.domain.com" = "domain.com"}
        $AzureTenant = "domainmunicipality1.onmicrosoft.com"
        try{
            $AADSession = Get-AzureADCurrentSessionInfo -ErrorAction Stop
            if($AADSession.TenantDomain -notlike $AzureTenant){
                throw "Not connected to the correct Azure Tenant."
            }#End if
        }#End try
        catch{
            try{
                Connect-AzureAD -erroraction stop # Get-AzureADCurrentSessionInfo
            }#End Try
            catch{
                throw "Could not connect to AzureAD."
            }#End catch
        }#End catch
    }#End begin

    process{
        foreach($upn in $UserPrincipalNames){
            $NewPrimaryDomain = $upn.split('@')[-1]
            if($NewPrimaryDomain -like "edu.domain.com"){
                $ServerNewPrimaryDomain = "edunet.domain.com"
            }#End if
            else{
                $ServerNewPrimaryDomain = "domain.com"
            }#End else

            $NewSecondaryDomain = $Domains[$NewPrimaryDomain]
            if($NewSecondaryDomain -like "edu.domain.com"){
                $ServerNewSecondaryDomain = "edunet.domain.com"
            }#End if
            else{
                $ServerNewSecondaryDomain = "domain.com"
            }#End else

            try{
                $NewPrimaryUser = Get-Aduser -filter{UserPrincipalName -like $upn} -Properties employeenumber -server $ServerNewPrimaryDomain -Credential $creds[$NewPrimaryDomain] -erroraction stop
                $NewPrimaryUserParentOU = $NewPrimaryUser.DistinguishedName -replace 'CN=.*?,((CN|OU)=.*$)', '$1'
            }#End try
            catch{
                Throw "Could not access domain and get information."
            }#End Catch

            try{
                $NewSecondaryUser = Get-Aduser -filter{employeenumber -like $NewPrimaryUser.EmployeeNumber} -Properties employeenumber -server $ServerNewSecondaryDomain -Credential $creds[$NewSecondaryDomain] -erroraction stop
                $NewSecondaryUserParentOU = $NewSecondaryUser.DistinguishedName -replace 'CN=.*?,((CN|OU)=.*$)', '$1'
            }#End try
            catch{
                Throw "Could not access domain and get information."
            }#End catch

            $appendnum = "1"
            $UserUPNShort = $upn.split('@')[0]
            while($True){
                $AzureTempUPN = $UserUPNShort + $appendnum + '@' + $AzureTenant
                try{
                    Get-AzureADUser -objectid $AzureTempUPN -erroraction stop | Out-Null
                    $appendnum += "1"
                }#End try
                catch{
                    break
                }#End catch
            }#End While

            $CurrentImmutableID = Get-AzureADUser -objectid $NewPrimaryUser.userprincipalname ## ErrorHandling??

            [guid]$SGSADMSDSConsistencyguid = ($NewPrimaryUser.objectguid).ToString()
            $NewImmutableID = [System.Convert]::ToBase64String($SGSADMSDSConsistencyguid.ToByteArray())

            $UserInformation = New-Object System.Object
            $UserInformation | Add-Member -Type NoteProperty -Name NewPrimaryUPN -Value $NewPrimaryUser.userprincipalname
            $UserInformation | Add-Member -Type NoteProperty -Name NewSecondaryUPN -Value $NewSecondaryUser.userprincipalname
            $UserInformation | Add-Member -Type NoteProperty -Name DistinguishedNameNewPrimary -Value $NewPrimaryUser.distinguishedName
            $UserInformation | Add-Member -Type NoteProperty -Name DistinguishedNameNewSecondary -Value $NewSecondaryUser.distinguishedName
            $UserInformation | Add-Member -Type NoteProperty -Name OutOfSyncDistinguishedNameNewPrimary -Value $OutOfSyncOUs[$NewPrimaryDomain]
            $UserInformation | Add-Member -Type NoteProperty -Name OutOfSyncDistinguishedNameNewSecondary -Value $OutOfSyncOUs[$NewSecondaryDomain]
            $UserInformation | Add-Member -Type NoteProperty -Name NewPrimaryUserParentOU -Value $NewPrimaryUserParentOU
            $UserInformation | Add-Member -Type NoteProperty -Name NewSecondaryUserParentOU -Value $NewSecondaryUserParentOU
            $UserInformation | Add-Member -Type NoteProperty -Name AzureTempUPN -Value $AzureTempUPN
            $UserInformation | Add-Member -Type NoteProperty -Name CurrentImmutableID -Value $CurrentImmutableID.Immutableid
            $UserInformation | Add-Member -Type NoteProperty -Name NewImmutableID -Value $NewImmutableID
            $UserInformation | Add-Member -Type NoteProperty -Name OnPremiseCreds -Value $creds
            $returnArray.Add($UserInformation) | Out-Null

        }#End foreach
    }#End process

    end{
        return $returnArray
    }#End end
}#End function
function Set-TemporaryUPN{
    param (
        [Parameter(mandatory=$true)]
        [Object]$UserInformation # Must be output from Get-UserInformation!
    )#End param
    begin{
        try{
            Connect-MsolService -ErrorAction Stop
        }#End try
        catch{
            throw "Could not connect to msolservice."
        }#End catch
    }#End Begin
    Process{
        foreach($User in $UserInformation){
            try{
                Set-MsolUserPrincipalName -UserPrincipalName $User.NewPrimaryUPN -NewUserPrincipalName $user.AzureTempUPN -ErrorAction Stop
            }#End try
            catch{
                throw "Could not set temporary UPN in AzureAD."
            }#End Catch
        }#End foreach
    }#End process
    end{}#End end
}#End function
function Set-CorrectImmuatbleIDAndUPN{
    param (
        [Parameter(mandatory=$true)]
        [Object]$UserInformation # Must be output from Get-UserInformation!
    )#End param
    begin{
        try{
            Connect-MsolService -ErrorAction Stop
        }#End try
        catch{
            throw "Could not connect to msolservice."
        }#End catch
    }#End Begin
    Process{
        foreach($User in $UserInformation){
            try{
                #Set-MsolUserPrincipalName -UserPrincipalName $user.AzureTempUPN -ImmutableID $User.NewImmutableID
                Set-MsolUser -UserPrincipalName $user.AzureTempUPN -ImmutableId $user.NewImmutableID
            }#End try
            catch{
                throw "Could not set new ImmutableID"
            }#End catch

            try{
                Set-MsolUserPrincipalName -UserPrincipalName $user.AzureTempUPN -NewUserPrincipalName $User.NewPrimaryUPN
            }#End try
            catch{
                throw "Could not set corret UPN."
            }#End catch
        }#End foreach
    }#End process
    end{}#End end
}#End function
<#
1a. Gather all user information
1b. Move User Out Of Sync
2. Change UPN in cloud to temp UPN
3. Set correct UPN in cloud and move back in sync.

The rest of the steps will be done manually.
Be carefull to only run the steps and function one by one. This is not intended to be run all at once.

Modules Required:
ActiveDirectory
AzureAD
MSOnline
#>


<#
1a. Run the following to gather all information and save it. Optional is to save it to an csv.
Output should look like below. This Output show exemple of move from edunet -> domain:

NewPrimaryUPN                          : daniel.a.anderssson@domain.com
NewSecondaryUPN                        : daniel.a.andersson@edunet.domain.com
DistinguishedNameNewPrimary            : CN=User1DN,OU=HomeOU,DC=domain,DC=se
DistinguishedNameNewSecondary          : CN=User1DN,OU=HomeOU,DC,edunet,DC=domain,DC=se
OutOfSyncDistinguishedNameNewPrimary   : CN=Users,DC=domain,DC=se
OutOfSyncDistinguishedNameNewSecondary : CN=Users,DC=edunet,DC=domain,DC=se
NewPrimaryUserParentOU                 : OU=HomeOU,DC=domain,DC=se
NewSecondaryUserParentOU               : OU=HomeOU,DC,edunet,DC=domain,DC=se
AzureTempUPN                           : daniel.a.andersson1@domainmunicipality1.onmicrosoft.com
CurrentImmutableID                     : abcdefghnkGcBm4VC0I/gQ==
NewImmutableID                         : tmnvYUdS9kGcBm4VC0I/gQ==
OnPremiseCreds                         : CredentialsObject
#>

$UserInformation = Get-UserInformation -UserPrincipalNames anders.daun@edu.domain.com
$UserInformation | Export-Csv c:\temp\UserInformation.csv -Encoding UTF8

<#
1b. Run the following code to move both users from 'DistinguishedNameNewPrimary' to 'OutOfSyncDistinguishedNameNewPrimary' and the same with NewSecondary.
#>

foreach($user in $UserInformation){
    $UserPrimaryNewDomain = $User.NewPrimaryUPN.split('@')[-1]
    if($UserPrimaryNewDomain -like "edu.domain.com"){
        $ServerUserPrimaryNewDomain = "edunet.domain.com"
    }#End if
    else{
        $ServerUserPrimaryNewDomain = "domain.com"
    }#End else

    $UserSecondaryNewDomain = $User.NewSecondaryUPN.split('@')[-1]
    if($UserSecondaryNewDomain -like "edu.domain.com"){
        $ServerUserSecondaryNewDomain = "edunet.domain.com"
    }#End if
    else{
        $ServerUserSecondaryNewDomain = "domain.com"
    }#End else

    try{
        Move-AdObject -Identity $user.DistinguishedNameNewPrimary -TargetPath $User.OutOfSyncDistinguishedNameNewPrimary -server $ServerUserPrimaryNewDomain -Credential $user.OnPremiseCreds[$UserPrimaryNewDomain] -ErrorAction stop
    }#End try
    catch{
        Throw "Could now move user out of sync in new primary domain."
    }#End catch

    try{
        Move-AdObject -Identity $user.DistinguishedNameNewSecondary -TargetPath $User.OutOfSyncDistinguishedNameNewSecondary -server $ServerUserSecondaryNewDomain -Credential $user.OnPremiseCreds[$UserSecondaryNewDomain] -ErrorAction Stop
    }#End try
    catch{
        Throw "Could now move user out of sync in new secondary domain."
    }#End catch
}#End foreach

<#
2. This code will change UPN from the current to a temporary in the cloud to be able to set immutableid later.
#>

foreach($user in $UserInformation){
    Set-TemporaryUPN -UserInformation $user 
}#End foreach

<#
3. This code will change UPN from the temporary to the correct in the cloud to be able to set immutableid later. This piece will also move the user back to his/her OU.
#>

foreach($user in $UserInformation){
    $UserPrimaryNewDomain = $User.NewPrimaryUPN.split('@')[-1]
    if($UserPrimaryNewDomain -like "edu.domain.com"){
        $ServerUserPrimaryNewDomain = "edunet.domain.com"
    }#End if
    else{
        $ServerUserPrimaryNewDomain = "domain.com"
    }#End else

    $UserSecondaryNewDomain = $User.NewSecondaryUPN.split('@')[-1]
    if($UserSecondaryNewDomain -like "edu.domain.com"){
        $ServerUserSecondaryNewDomain = "edunet.domain.com"
    }#End if
    else{
        $ServerUserSecondaryNewDomain = "domain.com"
    }#End else

    Set-CorrectImmuatbleIDAndUPN -UserInformation $user

    try{
        $upnfilter = $User.NewPrimaryUPN
        $UserToMovePrimary = get-aduser -filter{userprincipalname -like $upnfilter} -server $ServerUserPrimaryNewDomain -Credential $user.OnPremiseCreds[$UserPrimaryNewDomain] -ErrorAction Stop
        try{
            $UserToMovePrimary | Move-ADObject -TargetPath $User.NewPrimaryUserParentOU -server $ServerUserPrimaryNewDomain -Credential $user.OnPremiseCreds[$UserPrimaryNewDomain] -ErrorAction Stop
        }#End try
        catch{
            throw "Could not move user in primary domain."
        }#End catch
    }#End try
    catch{
        throw "Could not get user to move from primary domain."
    }#End catch

    try{
        $upnfilterSecondary = $User.NewSecondaryUPN
        $UserToMoveSecondary = get-aduser -filter{userprincipalname -like $upnfilterSecondary} -server $ServerUserSecondaryNewDomain -Credential $user.OnPremiseCreds[$UserSecondaryNewDomain] -ErrorAction Stop
        try{
            $UserToMoveSecondary | Move-ADObject -TargetPath $User.NewSecondaryUserParentOU -server $ServerUserSecondaryNewDomain -Credential $user.OnPremiseCreds[$UserSecondaryNewDomain] -ErrorAction Stop
        }#End try
        catch{
            throw "Could not move user in secondary domain."
        }#End catch
    }#End try
    catch{
        throw "Could not get user to move from secondary domain."
    }#End catch
}#End foreach

