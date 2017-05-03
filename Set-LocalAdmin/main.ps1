function Set-LocalAdmin{
<#
.Synopsis
   Sets an AD-group as localadmin on targeted server.
.DESCRIPTION
   Long description
.EXAMPLE
   Set-LocalAdmin -Computer knetdeploy201 -GroupName G.Sec.General.LocalAdminknetdeploy201
.PARAMETER Computer
    Parameter for computer name. Input is Netbios
.PARAMETER GroupName
    Parameter for groupname to add to localadmingroup of computer. Input is name e.g. "Domain Users"
.INPUTS
Set-LocalAdmin -Computer knetdeploy201 -GroupName G.Sec.General.LocalAdminknetdeploy201
.OUTPUTS
Name                                                        LocalAdminGroup                                             AdminGroupPresent                                         
----                                                        ---------------                                             -----------------                                         
knetdeploy201                                               G.Sec.General.LocalAdminknetdeploy201                       True      
#>

param(
#Parameter for computer name. Input is Netbios
[parameter(Mandatory=$true,ValueFromPipeline=$True)]
[string]$Computer,
#Parameter for groupname to add to localadmingroup of computer. Input is name e.g. "Domain Users"
[parameter(Mandatory=$true)]
[string]$GroupName
)
    #Output Object
    $OutPutObject = New-Object System.Object
    $OutPutObject | Add-Member -Type NoteProperty -Name "Name" -Value "$Computer"
    $OutPutObject | Add-Member -Type NoteProperty -Name "LocalAdminGroup" -Value "$GroupName"

    try{

    $newArray = New-Object System.Collections.Generic.List[System.Object]

    $group = [ADSI]("WinNT://"+$Computer+"/Administrators,Group")
    $group.psbase.invoke("members")| foreach {

                $username = $_.gettype().invokemember("Name", "GetProperty", $null, $_, $null)
                $newArray.Add($username)
            }
            if($newArray -eq "$GroupName") 
            {
                #"$GroupName is already admin on server $computer"
                $OutPutObject | Add-Member -Type NoteProperty -Name "AdminGroupPresent" -Value "$true"
                Return $OutPutObject
            }
            else
            {
                #$GroupName is NOT admin on server $computer"
                $group.add("WinNT://$env:USERDOMAIN/$GroupName,Group")
                #"Group $GroupName has been added as localadmin on server $Computer"
                $OutPutObject | Add-Member -Type NoteProperty -Name "AdminGroupPresent" -Value "$true"
                Return $OutPutObject
            }
    }
    catch [System.Management.Automation.MethodInvocationException]{
        #"Can't connect remote with [ADSI] on $Computer"
        $OutPutObject | Add-Member -Type NoteProperty -Name "AdminGroupPresent" -Value "$false"
        $OutPutObject | Add-Member -Type NoteProperty -Name "ErrorReason" -Value "ADSI"
        Return $OutPutObject
    }
    catch{
        #"Can't connect with WinRM to server $computer."
        $OutPutObject | Add-Member -Type NoteProperty -Name "AdminGroupPresent" -Value "$false"
        $OutPutObject | Add-Member -Type NoteProperty -Name "ErrorReason" -Value "WinRM"
        Return $OutPutObject
    }
    Return $OutPutObject
}
