function Get-UserInformation{
    [cmdletbinding()]
    param(
        [Parameter(mandatory=$true)] 
        $UserPrincipalNames #UPNs from the new and coming primary domian. E.g. if user is located in skolnet and will be switched to uppsala, the UPN from Uppsala should be provided.
    )#End param

    begin{
        $returnArray = [System.Collections.ArrayList]@()

        #Static Variables to connect to domain and azuread.
        if($null -eq $skolnetcredential){
            $skolnetcredential = Get-Credential -Message "Plese enter credential for skolnet in netbios\samaccountname"
        }#End if
        if($null -eq $Uppsalacredential){
            $Uppsalacredential = Get-Credential -Message "Plese enter credential for uppsala in netbios\samaccountname"
        }#End if
        $creds = @{"uppsala.se" = $Uppsalacredential
                   "skolnet.uppsala.se" = $skolnetcredential}
        $OutOfSyncOUs = @{"uppsala.se" = "OU=Users,DC=uppsala,DC=se"
                          "skolnet.uppsala.se" = "OU=Users,DC=skolnet,DC=uppsala,DC=se"}
        $Domains = @{"uppsala.se" = "skolnet.uppsala.se"
                     "skolnet.uppsala.se" = "uppsala.se"}
        $AzureTenant = "uppsalakommun1.onmicrosoft.com"
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
            $NewSecondaryDomain = $Domains[$NewPrimaryDomain]

            try{
                $NewPrimaryUser = Get-Aduser -filter{UserPrincipalName -like $upn} -Properties employeenumber -server $NewPrimaryDomain -Credential $creds[$NewPrimaryDomain] -erroraction stop
                $NewPrimaryUserParentOU = $NewPrimaryUser.DistinguishedName -replace 'CN=.*?,((CN|OU)=.*$)', '$1'
            }#End try
            catch{
                Throw "Could not access domain and get information."
            }#End Catch

            try{
                $NewSecondaryUser = Get-Aduser -filter{employeenumber -like $NewPrimaryUser.EmployeeNumber} -Properties employeenumber -server $NewSecondaryDomain -Credential $creds[$NewSecondaryDomain] -erroraction stop
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
            $UserInformation | Add-Member -Type NoteProperty -Name CurrentImmutableID -Value $AzureTempUPN.ImmutableID
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
        Connect-MsolService
    }#End Begin
    Process{
        foreach($User in $UserInformation){
            Set-MsolUserPrincipalName -UserPrincipalName $User.NewSecondaryUPN -NewUserPrincipalName $user.AzureTempUPN
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
        Connect-MsolService
    }#End Begin
    Process{
        foreach($User in $UserInformation){
            Set-MsolUserPrincipalName -UserPrincipalName $user.AzureTempUPN -ImmutableID $User.NewImmutableID
            Set-MsolUserPrincipalName -UserPrincipalName $user.AzureTempUPN -NewUserPrincipalName $User.NewPrimaryUPN
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
MSOLService

Todo list:
[/] Verify Credentials and server
[] Error handling
[] Check for connection and creds
#>


<#
1a. Run the following to gather all information and save it. Optional is to save it to an csv.
Output should look like below. This Output show exemple of move from skolnet -> Uppsala:

NewPrimaryUPN                          : daniel.a.anderssson@uppsala.se
NewSecondaryUPN                        : daniel.a.andersson@skolnet.uppsala.se
DistinguishedNameNewPrimary            : CN=User1DN,OU=HomeOU,DC=uppsala,DC=se
DistinguishedNameNewSecondary          : CN=User1DN,OU=HomeOU,DC,skolnet,DC=uppsala,DC=se
OutOfSyncDistinguishedNameNewPrimary   : CN=Users,DC=uppsala,DC=se
OutOfSyncDistinguishedNameNewSecondary : CN=Users,DC=skolnet,DC=uppsala,DC=se
NewPrimaryUserParentOU                 : OU=HomeOU,DC=uppsala,DC=se
NewSecondaryUserParentOU               : OU=HomeOU,DC,skolnet,DC=uppsala,DC=se
AzureTempUPN                           : daniel.a.andersson1@uppsalakommun1.onmicrosoft.com
CurrentImmutableID                     : abcdefghnkGcBm4VC0I/gQ==
NewImmutableID                         : tmnvYUdS9kGcBm4VC0I/gQ==
OnPremiseCreds                         : CredentialsObject
#>

$UserInformation = Get-UserInformation -UserPrincipalNames daniel.a.andersson@uppsala.se
$UserInformation | Export-Csv c:\temp\UserInformation.csv -Encoding UTF8

<#
1b. Run the following code to move both users from 'DistinguishedNameNewPrimary' to 'OutOfSyncDistinguishedNameNewPrimary' and the same with NewSecondary.
#>

foreach($user in $UserInformation){
    $UserPrimaryNewDomain = $User.NewPrimaryUPN.split('@')[-1]
    $UserSecondaryNewDomain = $User.SecondaryUPN.split('@')[-1]
    try{
        Move-AdObject -Identity $user.DistinguishedNameNewPrimary -TargetPath $User.OutOfSyncDistinguishedNameNewPrimary -server $UserPrimaryNewDomain -Credentials $user.OnPremiseCreds[$UserPrimaryNewDomain] -ErrorAction stop
    }#End try
    catch{
        Throw "Could now move user out of sync in new primary domain."
    }#End catch

    try{
        Move-AdObject -Identity $user.DistinguishedNameNewSecondary -TargetPath $User.OutOfSyncDistinguishedNameNewSecondary -server $UserSecondaryNewDomain -Credentials $user.OnPremiseCreds[$UserSecondaryNewDomain] -ErrorAction Stop
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
    $UserSecondaryNewDomain = $User.SecondaryUPN.split('@')[-1]

    Set-CorrectImmuatbleIDAndUPN -UserInformation $user

    $UserToMovePrimary = get-aduser -filter{userprincipalname -like $User.NewPrimaryUPN} -server $UserPrimaryNewDomain -Credentials $user.OnPremiseCreds[$UserPrimaryNewDomain]
    $UserToMovePrimary | Move-ADObject -TargetPath $User.NewPrimaryUserParentOU -server $UserPrimaryNewDomain -Credentials $user.OnPremiseCreds[$UserPrimaryNewDomain]

    $UserToMoveSecondary = get-aduser -filter{userprincipalname -like $User.NewSecondaryUPN} -server $UserSecondaryNewDomain -Credentials $user.OnPremiseCreds[$UserSecondaryNewDomain]
    $UserToMoveSecondary | Move-ADObject -TargetPath $User.NewSecondaryUPN -server $UserSecondaryNewDomain -Credentials $user.OnPremiseCreds[$UserSecondaryNewDomain]
}#End foreach
