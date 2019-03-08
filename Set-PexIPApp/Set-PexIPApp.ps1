function Set-PexIPApp{
    <#
    .SYNOPSIS
        A brief description of the function or script.

    .DESCRIPTION
        A longer description.

    .PARAMETER CasServer
        Name of the CAS-server in the exchangeorganization in the format of FQDN. E.g. server.domain.local.
    
    .PARAMETER UserFilter
        Unique identifier of the AD-group that stores the users to be added to the application.
        E.g. "G.Sec.General.GroupName"

    .PARAMETER AppId
        The Application ID of the app obtained from Get-App.

    #>
    [cmdletbinding()]
    param(
        [Parameter(mandatory=$true)] 
        $CasServer,
        [Parameter(mandatory=$true)]
        $UserFilter,
        [Parameter(mandatory=$true)]
        $AppId
    )#End param

    begin{
        try{
            $sessionOption = New-PSSessionOption -OperationTimeout 40000 -OpenTimeout 40000
            $connectionUri = “http://$CasServer/powershell?serializationLevel=Full;clientApplication=PowerShellISE”

            $session = New-PSSession -ConnectionURI $connectionUri -ConfigurationName Microsoft.Exchange -SessionOption $sessionOption -Authentication Kerberos -AllowRedirection -ErrorAction Stop

            Import-PSSession $session -DisableNameChecking -ErrorAction Stop | Out-Null

        }#End try
        catch{
            throw "Could not start session to cas-server with name: $CasServer"
        }#End catch

        $returnArray = [System.Collections.ArrayList]@()
    }#end begin

    process{
        $memberList = [System.Collections.ArrayList]@()
        foreach($U in $UserFilter){
            try{
                $GroupMembers = Get-AdGroupmember $u -ErrorAction stop
            }#End try
            catch{
                Write-Warning "Can't get info from the group $u"
                continue
            }#End catch

            foreach($G in $GroupMembers){
                $customObject = New-Object System.Object
                $customObject | Add-Member -Type NoteProperty -Name member -Value $g.distinguishedName
                $memberList.Add($customObject) | Out-Null
            }#End foreach

        }#End foreach

        $UniqueNewMemberList = $memberList | Sort-Object member -Unique

        try{
            Set-App -OrganizationApp -Identity $AppId -UserList $UniqueNewMemberList.member -DefaultStateForUser Enabled -ErrorAction Stop
        }#End try
        catch{
            Write-Warning "Could not add user to the application."
        }#End catch
        
        try{
            $OrgApp = Get-App -OrganizationApp -Identity $AppId -ErrorAction Stop

            foreach($m in $UniqueNewMemberList){
                $customObject = New-Object System.Object
                $customObject | Add-Member -Type NoteProperty -Name Application -Value $OrgApp.DisplayName
                $customObject | Add-Member -Type NoteProperty -Name Member -Value $m.member
                $customObject | Add-Member -Type NoteProperty -Name TimeAdded -Value (Get-Date)
                $returnArray.Add($customObject) | Out-Null
            }#End foreach
            
        }#End Try
        catch{
            Write-Warning "Could not get info about the appliction."
        }#End Catch

    }#End process

    end{
        Remove-PSSession $session
        return $returnArray
    }#End end
}#End function