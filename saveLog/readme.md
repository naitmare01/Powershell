Function to log a string and timestamp it. </br>
Supports output of .txt or .csv. </br>
Supports local folders and UNC. </br>
Will default to working directory if not path specified. </BR>

How to use:</br>
1.
$loggToSave = "Example Text"</br>
saveLog -TextToSave $loggToSave -LogFilePath "C:\temp\davidtest.csv"


2.</br>

saveLog -TextToSave "Example text" -LogFilePath "C:\temp\davidtest.csv"

3.</br>

saveLog -TextToSave $loggToSave -LogFilePath "\\UNC\temp\davidtest.txt"

</BR>
More Examples: </BR>
"sas" | Save-Log -LogFilePath "1.csv"</BR>
Save-Log "adsasd9090dasda90" -LogFilePath "2.csv"</BR>
Save-Log -Text "asdasdasdasdadasd" -LogFilePath "3.csv"</BR>
Save-Log -Text "sdjak" -Path "4.csv"</BR>
Save-Log -TextToSave "adsad"</BR>
