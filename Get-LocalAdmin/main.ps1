
function Get-LocalAdmin{
<#
.Synopsis
   Check if an AD-group as localadmin on targeted server.
.DESCRIPTION
   Long description
.EXAMPLE
   Get-LocalAdmin -Computer "NAME" -GroupName "GROUP"
.PARAMETER Computer
    Parameter for computer name. Input is Netbios
.PARAMETER GroupName
    Parameter for groupname to add to localadmingroup of computer. Input is name e.g. "Domain Users"
.INPUTS
Get-LocalAdmin -Computer NAME -GroupName "GROUP"
.OUTPUTS
 ComputerName                              Identity                                  LocalGroup                                AdminGroupPresent                       

------------                              --------                                  ----------                                -----------------                       

localhost                                 test                                      {Administrators}                          False               
#>
param(
#Parameter for computer name. Input is Netbios
[parameter(Mandatory=$true,ValueFromPipeline=$True)]
[string]$Computer,
#Parameter for groupname to check if localadmingroup of computer. Input is name e.g. "Domain Users"
#[parameter(Mandatory=$true)]
[string]$GroupName
)

    #Output Object
    $OutPutObject = New-Object System.Object
    $OutPutObject | Add-Member -Type NoteProperty -Name "ComputerName" -Value "$Computer"
    $OutPutObject | Add-Member -Type NoteProperty -Name "Identity" -Value "$GroupName"

    #Array that holds all the members of the localadminGroup
    $newArray = New-Object System.Collections.Generic.List[System.Object]

    try{
        $group = [ADSI]("WinNT://"+$Computer+"/Administrators,Group")
        $OutPutObject | Add-Member -Type NoteProperty -Name "LocalGroup" -Value $group.Name
        $group.psbase.invoke("members")| foreach {

                    $username = $_.gettype().invokemember("Name", "GetProperty", $null, $_, $null)
                    $newArray.Add($username)
                }
                if($GroupName -eq $Null){
                    $OutPutObject | Add-Member -Type NoteProperty -Name "AdminGroupPresent" -Value "$true"
                    Return $OutPutObject
                }
                elseif($newArray -eq "$GroupName") 
                {
                    #"$GroupName is already admin on server $computer"
                    $OutPutObject | Add-Member -Type NoteProperty -Name "AdminGroupPresent" -Value "$true"
                    Return $OutPutObject
                }
                else
                {
                    #$GroupName is NOT admin on server $computer"
                    $OutPutObject | Add-Member -Type NoteProperty -Name "AdminGroupPresent" -Value "$false"
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
