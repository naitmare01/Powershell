<#
.EXAMPLES
"sas" | Save-Log -LogFilePath "1.csv"
Save-Log "adsasd9090dasda90" -LogFilePath "2.csv"
Save-Log -Text "asdasdasdasdadasd" -LogFilePath "3.csv"
Save-Log -Text "sdjak" -Path "4.csv"
Save-Log -TextToSave "adsad"
#>
function Save-Log{
[CmdletBinding()]
    param(
    [Parameter(Mandatory=$true,ValueFromPipeline=$True)]
    [Alias("Text")]
    [string]$TextToSave,
    [Parameter(Mandatory=$false)]
    [ValidateScript({
        if($_ -like "*.txt" -or $_ -like "*.csv"){
            $True
        }
        else{
            Throw "-LogfilePath must be in format *.txt or *.csv"
        }
    })]
    [Alias("Path")]
    [string]$LogFilePath = (Get-Item -Path ".\" -Verbose).FullName + "Save-Log.csv"
    )
    $now = Get-Date -format "dd-MMM-yyyy HH:mm"
    $textToSave = "`n" + $textToSave + " - $now"

    $textToSave | Out-File $LogFilePath -Encoding utf8 -Append
}



