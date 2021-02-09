function Get-TakenUPN{
    <#
    .Synopsis
        Checks if a users primary smtp-adress is taken by another users UPN. 
        Script to inventory before a change of users UPN to match the smtp.
    .DESCRIPTION
        Takes a users primary smtp-address and checks in every domain in the forest if that string appears on any users UPN.
    .Parameter SMTPAddress
        Users primary SMTP-address stored in porxyaddresses.
    .Parameter GloblaCatalog
        FQDN to GC in root domain. 
    #>
    [CmdletBinding()]
    param(
        [parameter(Mandatory=$True)]
        $SMTPAddress,
        [parameter(Mandatory=$True)]
        $GlobalCatalog
    )#End param

    begin{
        $returnArray = [System.Collections.ArrayList]@()
    }#End begin

    process{
        foreach($smtp in $SMTPAddress){
            $upnfree = Get-aduser -Filter{userprincipalname -like $smtp} -Server ($GlobalCatalog + ":3268")
            
            if($null -eq $upnfree){
                $UpnIsTaken = $false
            }#End if
            else{
                $UpnIsTaken = $true
            }#End else

            $customObject = New-Object System.Object
            $customObject | Add-Member -Type NoteProperty -Name Name -Value $upnfree.Name
            $customObject | Add-Member -Type NoteProperty -Name UserPrincipalName -Value $upnfree.UserPrincipalName
            $customObject | Add-Member -Type NoteProperty -Name SMTP -Value $smtp
            $customObject | Add-Member -Type NoteProperty -Name UpnIsTaken -Value $UpnIsTaken
            $returnArray.Add($customObject) | Out-Null

        }#end foreach
    }#End process

    end{
        return $returnArray
    }#End end
}#End function