function saveLog{
    param(
    [Parameter(Mandatory=$true)]
    [string]$TextToSave,
    [Parameter(Mandatory=$true)]
    [string]$LogFilePath
    )
    if($LogFilePath -like "*.txt" -or $LogFilePath -like "*.csv"){
        #Correct fileformat  
    }
    else{
        Throw "-LogfilePath must be in format C:\Folder\File.txt or \\UNC\Folder\File.csv"
    }
    $now = Get-Date -format "dd-MMM-yyyy HH:mm"
    $textToSave = "`n" + $textToSave + " - $now"

    $textToSave | Out-File $LogFilePath -Encoding utf8 -Append
}

