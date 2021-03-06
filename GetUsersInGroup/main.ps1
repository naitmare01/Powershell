function Get-UsersInGroup {
    [cmdletbinding()]
    param (
        [parameter(Mandatory=$true)]
        [string]$Object,

        [parameter(Mandatory=$true)]
        [string]$userName,
        
        [parameter(Mandatory=$false)]
        [int]$Level = 0
    )
    
    $indent = "-" * $Level
    $object = (Get-ADGroup "$object").DistinguishedName
   
    $newArray.Add($object)
    $arrayCheck = $newArray | group
    $arrayCheckSelect = $arrayCheck | ?{$_.Group -like "*$object*"}
    
    if($arrayCheckSelect.count -gt 3){
        Write-Warning "$object has caused an infinite loop, script will exit."
        break
    }
    
    $x = Get-ADObject -Identity $Object -Properties SamAccountName
 
    if ($x.ObjectClass -eq "group") {
        Write-Output "$indent# $($x.SamAccountName)"
 
        $y = Get-ADGroup -Identity $Object -Properties Members
 
        $y.Members | %{
            $o = Get-ADObject -Identity $_ -Properties SamAccountName
 
            if ($o.ObjectClass -eq "user" -and $o.Samaccountname -like $username){
                #Write-Output "$indent-> $($o.SamAccountName)"
                Write-host "$indent-> $($o.SamAccountName)" -ForegroundColor black -BackgroundColor Yellow
            } elseif ($o.ObjectClass -eq "group") {
                Get-UsersInGroup -userName $username -Object $o.DistinguishedName -Level ($Level + 1) 
            }
        }
    } 
    else {
        Write-Warning "$($Object) is not a group, it is a $($x.ObjectClass)"
    }
}
$newArray = New-Object System.Collections.Generic.List[System.Object]
