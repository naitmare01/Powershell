Usage

Local Computer

if(Test-RebootRequired)
{
    Restart-Computer -Force
}
Remote Computer

$params = @{
    ComputerName = "172.16.100.64"
    Credential = Get-Credential -UserName "localhost\Administrator" -Message "Enter Password"
    Authentication = "Default"
    ScriptBlock = ${function:Test-RebootRequired}
}

#Check Reboot is required to remote computer
$isRebootRequired = Invoke-Command @params

if($isRebootRequired -eq $true)
{
    #Restart and wait until WinRM available
    Restart-Computer -ComputerName $params.ComputerName -Credential $params.Credential -WsmanAuthentication Default -Force -Wait -For WinRM
}

#Check Reboot is required to remote computer
$isRebootRequired = Invoke-Command @params
if($isRebootRequired -eq $true)
{
    throw "Reboot required once more!"
}
Raw
