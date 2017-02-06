Function to log a string and timestamp it. </br>
Supports output of .txt or .csv. </br>
Supports local folders and UNC. </br>

How to use:</br>

1.
$loggToSave = "Example Text"</br>
saveLog -TextToSave $loggToSave -LogFilePath "C:\temp\davidtest.csv"


2.</br>

saveLog -TextToSave "Example text" -LogFilePath "C:\temp\davidtest.csv"

3.</br>

saveLog -TextToSave $loggToSave -LogFilePath "\\UNC\temp\davidtest.txt"
