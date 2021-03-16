function Get-MSTeamsAndMember{
    [CmdletBinding()]
    param(
      [Parameter(Mandatory=$true)]
      [array]$BlacklistDomains
    )#End param

    begin{
      foreach($BL in $BlacklistDomains){
        Write-Verbose "$BL is a blacklisted domain"
      }#End foreach
      $AllTeams = Get-Team -Archived $False -NumberofThreads 20
    }#End begin

    process{
      foreach($Team in $AllTeams){
        $DispName = $Team.DisplayName
        Write-Verbose "Working on $Dispname"
        $PrimarySmtpAddress = Get-Recipient $Team.MailNickName
        $SecondarySmtpAddress = $PrimarySmtpAddress | where-object{$_.emailaddress -clike "smtp:*"}
        $SecondarySmtpAddressExist = $False
        if($SecondarySmtpAddress){
          $SecondarySmtpAddressExist = $true
        }#End if
        $OwnerDomain = [System.Collections.ArrayList]@()
        $MembersDomain = [System.Collections.ArrayList]@()
        $ContainsBlacklistedDomainInOwner = $False
        $ContainsBlacklistedDomainInMember = $False
        $ContainsBlacklistedDomainInPrimarySMTP = $False

        $AllMembersAndOwner = Get-TeamUser -GroupID $Team.GroupId
        if($AllMembersAndOwner){
          $Owners = $AllMembersAndOwner | Where-Object{$_.role -like "owner"}
          foreach($own in $owners){
            $OwnDomain = ($own.user -split '@')[1]
            if($OwnDomain -notin $OwnerDomain){
              $OwnerDomain.Add($OwnDomain) | Out-Null
            }#End if
          }#End foreach

          $Members = $AllMembersAndOwner | Where-Object{$_.role -like "member"}
          foreach($mem in $Members){
            $memdomain = ($mem.user -split '@')[1]
            if($memdomain -notin $MembersDomain){
              $MembersDomain.add($memdomain) | Out-Null
            }#End if
          }#End foreach

          foreach($BL in $BlacklistDomains){
            if($BL -in $OwnerDomain){
              $ContainsBlacklistedDomainInOwner = $true
            }#End if

            if($BL -in $MembersDomain){
              $ContainsBlacklistedDomainInMember = $true
            }#End if
          }#End if

          $MembersDomain = $MembersDomain -join ', '
          $OwnerDomain = $OwnerDomain -join ', '
        }#End if
        else{
          $MembersDomain = $null
          $OwnerDomain = $null
        }#End else

        foreach($BL in $BlacklistDomains){
          if($BL -like ($PrimarySmtpAddress -split '@')[1]){
            $ContainsBlacklistedDomainInPrimarySMTP = $true
          }#End if
        }#End if

        $customObject = New-Object System.Object
        $customObject | Add-Member -Type NoteProperty -Name DisplayName -Value $Team.DisplayName
        $customObject | Add-Member -Type NoteProperty -Name PrimarySmtpAddress -Value $PrimarySmtpAddress.PrimarySmtpAddress
        $customObject | Add-Member -Type NoteProperty -Name ContainsBlacklistedDomainInPrimarySMTP -Value $ContainsBlacklistedDomainInPrimarySMTP
        $customObject | Add-Member -Type NoteProperty -Name GroupId -Value $Team.GroupId
        $customObject | Add-Member -Type NoteProperty -Name OwnerDomain -Value $OwnerDomain
        $customObject | Add-Member -Type NoteProperty -Name MembersDomain -Value $MembersDomain
        $customObject | Add-Member -Type NoteProperty -Name ContainsBlacklistedDomainInOwner -Value $ContainsBlacklistedDomainInOwner
        $customObject | Add-Member -Type NoteProperty -Name ContainsBlacklistedDomainInMember -Value $ContainsBlacklistedDomainInMember
        $customObject | Add-Member -Type NoteProperty -Name SecondarySmtpAddressExist -Value $SecondarySmtpAddressExist
        $customObject
      }#End foreach
    }#End process

    end{
    }#End end
}#End function

#This function assumes that we are connected to Microsoft Teams AND Exchange Online
