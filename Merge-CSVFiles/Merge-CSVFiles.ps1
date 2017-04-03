Function Merge-CSVFiles
{
Param(
[string]$XLFileNameOutPut = "Placeholder",
$CSVPath = "C:\Temp\170403\knetagrapp2001p", ## Soruce CSV Folder
$XLOutput ="$CSVPath\$XLFileNameOutPut.xlsx" ## Output file name
)

    $csvFiles = Get-ChildItem ("$CSVPath\*") -Include *.csv
    
    foreach($csvFile in $csvFiles){
        Write-Host $csvFile.Name -ForegroundColor Yellow
    }
    $Choice = Read-Host -Prompt "The above files will be merged to $XLOutput. Is this correct? [Y]/[N]"
    
    if($choice -like "n"){
        Write-Host "User picked no, existing script.." -ForegroundColor Red
        return
    }
    
    $Excel = New-Object -ComObject excel.application 
    $Excel.visible = $false
    $Excel.sheetsInNewWorkbook = $csvFiles.Count
    $workbooks = $excel.Workbooks.Add()
    $CSVSheet = 1

        Foreach ($CSV in $Csvfiles){
            $worksheets = $workbooks.worksheets
            $CSVFullPath = $CSV.FullName
            $SheetName = ($CSV.name -split "\.")[0]
            $worksheet = $worksheets.Item($CSVSheet)
            $worksheet.Name = $SheetName.Split("- ")[-1]
            $TxtConnector = ("TEXT;" + $CSVFullPath)
            $CellRef = $worksheet.Range("A1")
            $Connector = $worksheet.QueryTables.add($TxtConnector,$CellRef)
            $worksheet.QueryTables.item($Connector.name).TextFileCommaDelimiter = $True
            $worksheet.QueryTables.item($Connector.name).TextFileParseType  = 1
            
            #Note: $Dummy is just here to not output to console.
            $dummy = $worksheet.QueryTables.item($Connector.name).Refresh()
            $worksheet.QueryTables.item($Connector.name).delete()

            #Note: $Dummy is just here to not output to console.
            $dummy = $worksheet.UsedRange.EntireColumn.AutoFit()
            $CSVSheet++
        }

$workbooks.SaveAs($XLOutput,51)
$workbooks.Saved = $true
$workbooks.Close()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($workbooks) | Out-Null
$excel.Quit()
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) | Out-Null
[System.GC]::Collect()
[System.GC]::WaitForPendingFinalizers()

Write-Host "All csv files in $CSVPath are now merged to the file: $XLOutput" -ForegroundColor Green

}
