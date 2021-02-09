function Test-ACLComplianceGeneralGroups{
    <#
    .DESCRIPTION
        Takes an ACL-object from a folder and performs multiple checks if the ACL are correct. 
    .PARAMETER ACLObject
        ACL-object from Get-Acl.
    #>
    [cmdletbinding()]
    param(
        [Parameter(mandatory=$true)] 
        [object]$ACLObject
    )#End param
    begin{
        $returnArray = [System.Collections.ArrayList]@()
    }#End begin
    process{
        $GeneralGroups =  $ACLObject.Access.IdentityReference | Where-Object{$_ -like "KNET\*"} 
        $NumberOfGeneralGroups = $GeneralGroups | Measure-Object
        $Path = $ACLObject.Path -replace 'Microsoft.PowerShell.Core[\\]FileSystem::'
        $Compliance = $true
        $WrongKnetGroups = $null
        $VerboseMessage = ""

        if($NumberOfGeneralGroups.Count -eq 3){
            $CorrectNumber = $true
        }#End if
        elseif($NumberOfGeneralGroups.Count -gt 3){
            $CorrectNumber = $false
            $Compliance = $false
            $VerboseMessage = $VerboseMessage + "Mer än 3st knet-grupper på aclerna. Ta bort felaktiga; "
            $WrongKnetGroups =  $ACLObject.Access.IdentityReference | Where-Object{$_ -like "KNET\*"} |  Where-Object{$_ -notlike "KNET\G.Acl.General.FileSysPermModify" -and $_ -notlike "KNET\G.Acl.General.FileSysPermFullCtrl" -and $_ -notlike "KNET\System.Kontosats"} 
        }#End elseif
        else{
            $CorrectNumber = $false
            $Compliance = $false
            $VerboseMessage = $VerboseMessage + "Mindre än 3st knet-grupper på aclerna. Lägg till de som saknas; "
        }#End else

        if($GeneralGroups -contains "KNET\G.Acl.General.FileSysPermModify"){
            $FileSysPermModify = $true
            $ModifyRights = $ACLObject.Access | Where-Object{$_.IdentityReference -like "KNET\G.Acl.General.FileSysPermModify"}
            $ModifyRights = $ModifyRights.FileSystemRights
            if($ModifyRights -like "Modify, Synchronize"){
                $ModifyRightsCorrect = $true
            }#End if
            else{
                $ModifyRightsCorrect = $false
                $Compliance = $false
                $VerboseMessage = $VerboseMessage + "KNET\G.Acl.General.FileSysPermModify har fel typ av behörighet på aclerna.; "
            }#End else
        }#End if
        else{
            $FileSysPermModify = $false
            $Compliance = $false
            $VerboseMessage = $VerboseMessage + "KNET\G.Acl.General.FileSysPermModify saknas på aclerna.; "
        }#End if

        if($GeneralGroups -contains "KNET\G.Acl.General.FileSysPermFullCtrl"){
            $FileSysPermFullCtrl = $true
            $FullRights = $ACLObject.Access | Where-Object{$_.IdentityReference -like "KNET\G.Acl.General.FileSysPermFullCtrl"}
            $FullRights = $FullRights.FileSystemRights
            if($FullRights -like "FullControl"){
                $FullRightsCorrect = $true
            }#End if
            else{
                $FullRightsCorrect = $false
                $Compliance = $false
                $VerboseMessage = $VerboseMessage + "KNET\G.Acl.General.FileSysPermFullCtrl har fel typ av behörighet på aclerna.; "
            }#End else
        }#End if
        else{
            $FileSysPermFullCtrl = $false
            $Compliance = $false
            $VerboseMessage = $VerboseMessage + "KNET\G.Acl.General.FileSysPermFullCtrl saknas på aclerna.; "
        }#End if

        if($GeneralGroups -contains "KNET\System.Kontosats"){
            $Kontosats = $true
            $KontosatsRights = $ACLObject.Access | Where-Object{$_.IdentityReference -like "KNET\System.Kontosats"}
            $KontosatsRights = $KontosatsRights.FileSystemRights
            if($KontosatsRights -like "FullControl"){
                $KontosatsRightsCorrect = $true
            }#End if
            else{
                $KontosatsRightsCorrect = $false
                $Compliance = $false
                $VerboseMessage = $VerboseMessage + "KNET\System.Kontosats har fel typ av behörighet på aclerna.; "
            }#End else
        }#End if
        else{
            $Kontosats = $false
            $Compliance = $false
            $VerboseMessage = $VerboseMessage + "KNET\System.Kontosats saknas på aclerna.; "
        }#End if
        
        $customObject = New-Object System.Object
        $customObject | Add-Member -Type NoteProperty -Name Path -Value $Path
        $customObject | Add-Member -Type NoteProperty -Name Compliance -Value $Compliance
        $customObject | Add-Member -Type NoteProperty -Name CorrectGroupNumber -Value $CorrectNumber
        $customObject | Add-Member -Type NoteProperty -Name GroupFileSysPermModifyExist -Value $FileSysPermModify
        $customObject | Add-Member -Type NoteProperty -Name GroupFileSysPermModifyACL -Value $ModifyRights
        $customObject | Add-Member -Type NoteProperty -Name GroupFileSysPermModifyACLCorrect -Value $ModifyRightsCorrect
        $customObject | Add-Member -Type NoteProperty -Name GroupFileSysPermFullExist -Value $FileSysPermFullCtrl
        $customObject | Add-Member -Type NoteProperty -Name GroupFileSysPermFullACL -Value $FullRights
        $customObject | Add-Member -Type NoteProperty -Name GroupFileSysPermFullACLCorrect -Value $FullRightsCorrect
        $customObject | Add-Member -Type NoteProperty -Name GroupKontosatsExist -Value $Kontosats
        $customObject | Add-Member -Type NoteProperty -Name GroupKontosatsACL -Value $KontosatsRights
        $customObject | Add-Member -Type NoteProperty -Name GroupKontosatsACLCorrect -Value $KontosatsRightsCorrect
        $customObject | Add-Member -Type NoteProperty -Name WrongKnetGroups -Value $WrongKnetGroups
        $customObject | Add-Member -Type NoteProperty -Name VerboseMessage -Value $VerboseMessage
        $returnArray.Add($customObject) | Out-Null
    }#End process
    end{
        return $returnArray
    }#End
}#End function

function Test-ACLComplianceHomeDirectory{
    <#
    .DESCRIPTION
        Takes an ACL-object from a folder and performs multiple checks if the ACL are correct. 
    .PARAMETER User
        AD-User from Get-ADuser with the property HomeDirectory.
.
    #>
    [cmdletbinding()]
    param(
        [Parameter(mandatory=$true)] 
        [object]$User
    )#End param
    begin{
        $returnArray = [System.Collections.ArrayList]@()
    }#End begin

    process{
        foreach($u in $User){
            $HomeDirectory = $u.HomeDirectory
            $UserSamAccountName = $u.SamAccountName
            $VerboseMessage = ""

            If(Test-Path $HomeDirectory){
                Write-Verbose "Kan komma åt sökvägen. Kör resten av scriptet."
                $PathAvalible = $true
                $Compliance = $true
                $HomeDirAcl = Get-Acl $HomeDirectory
                $NonInherited = $HomeDirAcl.Access | Where-Object{$_.IsInherited -eq $false}
                $NumberOfACLs = $NonInherited | Measure-Object
                $WrongKnetGroups = $null

                if($NumberOfACLs.Count -eq 1){
                    $CorrectNumber = $true
                }#End if
                elseif($NumberOfACLs.Count -gt 1){
                    $CorrectNumber = $false
                    $Compliance = $false
                    $VerboseMessage = $VerboseMessage + "Mer än 1st knet-objekt på aclerna. Ta bort felaktiga; "
                    $WrongKnetGroups =  $NonInherited | Where-Object{$_.IdentityReference -notlike "KNET\$UserSamAccountName"}
                }
                else{
                    $CorrectNumber = $false
                    $Compliance = $false
                    $VerboseMessage = $VerboseMessage +  "Mindre än 3st knet-objekt på aclerna. Lägg till de som saknas; "
                }#End else

                if($HomeDirAcl.Access.IdentityReference -contains "KNET\$UserSamAccountName"){
                    $UserSamAccountNameExist = $true
                    $UserSamAccountNameRights = $HomeDirAcl.Access | Where-Object{$_.IdentityReference -like "KNET\$UserSamAccountName"}
                    $UserSamAccountNameRights = $UserSamAccountNameRights.FileSystemRights
                    if($UserSamAccountNameRights -like "FullControl" -or $UserSamAccountNameRights -like "Modify, Synchronize"){
                        $UserSamAccountNameRightsCorrect = $true
                    }#End if
                    else{
                        $UserSamAccountNameRightsCorrect = $false
                        $Compliance = $false
                        $VerboseMessage = $VerboseMessage + "KNET\$UserSamAccountName har fel typ av behörighet på aclerna.; "
                    }#End else
                }#End if
                else{
                    $Compliance = $false
                    $UserSamAccountNameExist = $false
                    $VerboseMessage = $VerboseMessage + "KNET\$UserSamAccountName saknas på aclerna.; " 
                }#End else
            }#End if
            else{
                Write-Verbose "Kan inte komma åt sökvägen. Avsluta scriptet."
                $PathAvalible = $false
                $Compliance = $false
                $VerboseMessage = $VerboseMessage + "Kan inte nå hemkatalogen.; " 
            }#End else

            $customObject = New-Object System.Object
            $customObject | Add-Member -Type NoteProperty -Name Path -Value $HomeDirectory
            $customObject | Add-Member -Type NoteProperty -Name Compliance -Value $Compliance
            $customObject | Add-Member -Type NoteProperty -Name PathAvalible -Value $PathAvalible
            $customObject | Add-Member -Type NoteProperty -Name CorrectGroupNumber -Value $CorrectNumber
            $customObject | Add-Member -Type NoteProperty -Name UserSamAccountNameExist -Value $UserSamAccountNameExist
            $customObject | Add-Member -Type NoteProperty -Name UserSamAccountNameRights -Value ([string]$UserSamAccountNameRights)
            $customObject | Add-Member -Type NoteProperty -Name UserSamAccountNameRightsCorrect -Value $UserSamAccountNameRightsCorrect
            $customObject | Add-Member -Type NoteProperty -Name WrongKnetGroups -Value  ([string]$WrongKnetGroups.IdentityReference)
            $customObject | Add-Member -Type NoteProperty -Name VerboseMessage -Value $VerboseMessage
            $returnArray.Add($customObject) | Out-Null
        }#End foreach
    }#End process

    end{
        return $returnArray
    }#End end
}#End function

###Test root-folders of DFS-structure

$rootdfs = "\\knet.ad.svenskakyrkan.se\dfs01\HomeFolders"
$stift = Get-ChildItem $rootdfs
$returnArray = [System.Collections.ArrayList]@()

foreach($s in $stift){
    $Acl = Get-Acl $s.FullName
    $result = Test-ACLComplianceGeneralGroups -ACLObject $Acl
    $returnArray.Add($result) | Out-Null
}#End foreach
$stiftsfilename = "StiftRapport_" + (Get-Date -Format yyMdd) + ".csv" 
$returnArray | Export-CSv C:\scripts\Get-AclCompliance\Logs\$stiftsfilename -Encoding UTF8  
###

###Test homedirectory
$Users = Get-Aduser -filter{HomeDirectory -like "*"} -properties HomeDirectory -searchbase "OU=Users,OU=ASP,DC=knet,DC=ad,DC=svenskakyrkan,DC=se"
$Homedirectoryfilename = "HomedirectoryRapport_" + (Get-Date -Format yyMdd) + ".csv" 
Test-ACLComplianceHomeDirectory -User $Users | Export-CSv C:\scripts\Get-AclCompliance\Logs\$Homedirectoryfilename.csv -Encoding UTF8  
###
