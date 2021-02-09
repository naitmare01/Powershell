workflow Start-ThrottleWorkflow {
    [cmdletbinding()]
    param(
        [int]$ThrottleLimit = 5,
        $Emails
    )#End param

    foreach -parallel -throttlelimit $ThrottleLimit ($n in $Emails){
       "Working on $n"
       Get-Date
    }#End foreach
 }#End workflow

$smtp = Import-Csv C:\Temp\Mailincident\legacymatch.csv -Encoding UTF8

Start-ThrottleWorkflow -ThrottleLimit 2 -Emails $smtp.primarysmtp