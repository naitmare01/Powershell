Function to log a string and timestamp it. 
Supports output of .txt or .csv. 
Supports local folders and UNC. 

How to use:

1.
$loggToSave = "Example Text"
saveLog -TextToSave $loggToSave -LogFilePath "C:\temp\davidtest.csv"


2.

saveLog -TextToSave "Example text" -LogFilePath "C:\temp\davidtest.csv"

3.

saveLog -TextToSave $loggToSave -LogFilePath "\\UNC\temp\davidtest.txt"
