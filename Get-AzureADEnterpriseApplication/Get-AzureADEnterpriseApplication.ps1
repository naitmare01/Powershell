function Get-AzureADEnterpriseApplication{
    [CmdletBinding()]
    param(
      [array]$BlacklistDomains
    )#End param

    begin{
      foreach($BL in $BlacklistDomains){
        Write-Verbose "$BL is a blacklisted domain"
      }#End foreach
      $returnArray = [System.Collections.ArrayList]@()
      $AllApplications = Get-AzureADServicePrincipal
    }#End begin

    process{
      foreach($Application in $AllApplications){
        $displayname = $Application.DisplayName
        Write-Verbose "Inventoring $displayname"
        $AssignmentDomains = [System.Collections.ArrayList]@()
        $SignInDomains = [System.Collections.ArrayList]@()
        $ContainsBlacklistedDomainInAssignment = $False
        $ContainsBlacklistedDomainInSignIn = $False
        $appid = $Application.AppId

        if($Application.AppRoleAssignmentRequired){
          $AllAssignments = Get-AzureADServiceAppRoleAssignment -ObjectId $Application.ObjectID
  
          foreach($assignment in $AllAssignments){
            $UserInformation = Get-AzureAdUser -ObjectID $assignment.PrincipalId
            $UserDomain = ($UserInformation.userprincipalname -split '@')[1]
            if($UserDomain -notin $AssignmentDomains){
              $AssignmentDomains.add($UserDomain) | Out-Null
            }#End if
          }#End foreach
          foreach($BL in $BlacklistDomains){
            if($BL -in $AssignmentDomains){
              $ContainsBlacklistedDomainInAssignment = $true
            }#End if
          }#End foreach
          $AssignmentDomains = $AssignmentDomains -join ', '
        }#End if
        else{
          $AssignmentDomains = $null
        }#End else
        $7days = (Get-Date).AddDays(-7)
        $7days = Get-Date $7days -Format yyyy-MM-dd
        $AllSignIns = Get-AzureADAuditSignInLogs -Filter "appId eq '$appid' and createdDateTime gt $7days"
        if($AllSignIns){
          foreach($signin in $AllSignIns){
            $UserDomain = ($signin.userprincipalname -split '@')[1]
            if($UserDomain -notin $SignInDomains){
              $SignInDomains.add($UserDomain) | Out-Null
            }#End if
          }#End foreach
          foreach($BL in $BlacklistDomains){
            if($BL -in $SignInDomains){
              $ContainsBlacklistedDomainInSignIn = $true
            }#End if
          }#End foreach
          $SignInDomains = $SignInDomains -join ', '
        }#End if
        else{
          $SignInDomains = $null
        }#End else

        $customObject = New-Object System.Object
        $customObject | Add-Member -Type NoteProperty -Name DisplayName -Value $displayname
        $customObject | Add-Member -Type NoteProperty -Name AppDisplayName -Value $Application.AppDisplayName
        $customObject | Add-Member -Type NoteProperty -Name AppRoleAssignmentRequired -Value $Application.AppRoleAssignmentRequired
        $customObject | Add-Member -Type NoteProperty -Name ObjectId -Value $Application.ObjectId
        $customObject | Add-Member -Type NoteProperty -Name AppId -Value $appid
        $customObject | Add-Member -Type NoteProperty -Name AssignmentDomains -Value $AssignmentDomains
        $customObject | Add-Member -Type NoteProperty -Name ContainsBlacklistedDomainInAssignment -Value $ContainsBlacklistedDomainInAssignment
        $customObject | Add-Member -Type NoteProperty -Name SignInDomains -Value $SignInDomains
        $customObject | Add-Member -Type NoteProperty -Name ContainsBlacklistedDomainInSignIn -Value $ContainsBlacklistedDomainInSignIn
        $returnArray.add($customObject) | Out-Null
      }#End foreach
    }#End process

    end{
      return $returnArray
    }#End end
}#End function

#This function assumes that we are connected to AzureAD

