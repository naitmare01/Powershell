Function Get-WMI {
param(
    [Parameter(Mandatory = $True)]
    [Object]$computer
)
$timeoutSeconds = 1 # set your timeout value here
$j = Start-Job -ScriptBlock {
    # your commands here, e.g.
    Get-WmiObject win32_bios -ComputerName $args[0]
} -ArgumentList $computer
#"job id = " + $j.id # report the job id as a diagnostic only
Wait-Job $j -Timeout $timeoutSeconds | out-null
if ($j.State -eq "Completed")
{
#connection to PC has been verified and WMI commands can go here.
$Answer = "WMI call WAS SUCCESSFULL to $computer"
}
elseif ($j.State -eq "Running")
{
#After the timeout ($timeoutSeconds) has passed and the test is      
#still running, I will assume the computer cannot be connected.
$Answer = "WMI is not running on or could not Connect to $computer"
}
return $Answer
}
