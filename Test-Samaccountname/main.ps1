#function to test if samaccountname is free. Return TRUE or FALSE.
function Test-Samaccountname{
param(
[parameter(Mandatory=$true,ValueFromPipeline=$True)]
[string]$Samaccountname
)
    try{
        Get-aduser $samaccountname
        return $false
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
        return $true
    }
    catch{
    #Other Issue
    Break
    }
}
