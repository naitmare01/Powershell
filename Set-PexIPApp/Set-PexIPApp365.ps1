function Connect-SessionCasServer{
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
        $CasServer
    )#End param

    begin{
        try{
            $sessionOption = New-PSSessionOption -OperationTimeout 40000 -OpenTimeout 40000
            $connectionUri = "http://$CasServer/powershell?serializationLevel=Full;clientApplication=PowerShellISE" 

            $session = New-PSSession -ConnectionURI $connectionUri -ConfigurationName Microsoft.Exchange -SessionOption $sessionOption -Authentication Kerberos -AllowRedirection -ErrorAction Stop

            Import-PSSession $session -DisableNameChecking -ErrorAction Stop | Out-Null

        }#End try
        catch{
            throw "Could not start session to cas-server with name: $CasServer"
        }#End catch

    }#end begin

    process{

    }#End process

    end{
        return $session       
    }#End end
}#End function
function Get-MailboxStatus{
    [cmdletbinding()]
    param(
        [Parameter(mandatory=$true)]
        $Identity,
        [Parameter(mandatory=$true)]
        $OnPremGroup,
        [Parameter(mandatory=$true)]
        $o365Group
    )#End param
    begin{
        $returnArray = [System.Collections.ArrayList]@()
    }#End begin
    process{
        foreach($I in $Identity){
            #On Premise
            try{
                Get-Mailbox -Identity $i -ErrorAction Stop | Out-Null
                $MailBoxStatus = "On-Premise"
                $Group = $OnPremGroup
            }#End try
            catch{
                #Office 365
                try{
                    Get-RemoteMailbox -Identity $i -ErrorAction Stop | Out-Null
                    $MailBoxStatus = "Office 365"
                    $Group = $o365Group
                }#End try
                catch{
                    $MailBoxStatus = $Null
                    $Group = $Null
                }#End catch
            }#End catch
            $customObject = New-Object System.Object
            $customObject | Add-Member -Type NoteProperty -Name Identity -Value $I
            $customObject | Add-Member -Type NoteProperty -Name MailBoxStatus -Value $MailBoxStatus
            $customObject | Add-Member -Type NoteProperty -Name ADGroup -Value $Group
            $returnArray.Add($customObject) | Out-Null
        }#End foreach
    }#End process
    end{
        return $returnArray
    }#End end
}#End function

#1 Connect to Exchange
$Connection = Connect-SessionCasServer -CasServer "EXCHANGESERVER"

#2 Test if user is on-prem or 365 and add to group
Get-MailboxStatus -Identity "userwithfqdn" -OnPremGroup "GROUP" -o365Group "GROUP"

#3 Remove session to Exchange
Remove-PSSession $Connection
