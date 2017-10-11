<#
.Synopsis
   Scans the AD that the current user is logged on to adter duplicates in UPN(user principalname) or Samaccountname. Other value can be scanned for aswell.
.DESCRIPTION
   Long description
.EXAMPLE
   Find-ADDuplicateAttributes -Attribute $Attribute
   Find-ADDuplicateAttributes -SamAccountName
   Find-ADDuplicateAttributes -UserprincipalName
#>
function Find-ADDuplicateAttributes{
    [CmdletBinding()]
    Param(
        #Attribute to find duplicates of, e.g. samaccount or userprincipalname
        [Parameter(Mandatory=$false)]
        [string]$Attribute,
        #Switch to find duplicates of Samaccountname.
        [switch]$SamAccountName,
        #Switch to find duplicates of UPN.
        [switch]$UserprincipalName
    )#end param

    Begin{
        $returnArray = [System.Collections.ArrayList]@()
        if($SamaccountName -and $UserprincipalName){
            Throw "Only one switch can be used."
        }
        elseif(($Attribute -and $SamaccountName) -or ($Attribute -and $UserprincipalName)){
            Throw "Can't combine Attribute with SamAccountname or UserprincipalName."
        }
        elseif(!($Attribute) -and !($SamaccountName) -and !($UserprincipalName)){
            Throw "Specifiy either Attribute, Userprincipalname or Samaccountname"
        }
    }#end begin

    Process{
        $GetAllUsers = Get-Aduser -Filter *
        
        if($SamAccountName){
            $AttributeValues = "Samaccountname"
        }
        elseif($UserprincipalName){
            $AttributeValues = "UserprincipalName"
        }
        elseif($Attribute){
            $AttributeValues = "$Attribute"
        }

        $DuplicateUsers = $GetAllUsers.$AttributeValues | Group-Object | Where-Object{$_.count -gt 1}
        #$counter = 0
            foreach($dUser in $DuplicateUsers){
                #$Counter ++
                #Write-Progress -Activity "Looking for duplicated value: $AttributeValues" -PercentComplete(($Counter / $DuplicateUsers.Count)*100)
                $customObject = New-Object System.Object
                $customObject | Add-Member -Type NoteProperty -Name Identiy -Value $dUser.Name
                $customObject | Add-Member -Type NoteProperty -Name DuplicateValue -Value $AttributeValues
                $customObject | Add-Member -Type NoteProperty -Name NumberOfDuplicates -Value $dUser.Count

                [void]$returnArray.Add($customObject)

            }#End foreach($dUser in $DuplicateUsers)

    }#end process

    End{
        return $returnArray
    }#End end
}#End function
