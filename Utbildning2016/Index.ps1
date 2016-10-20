#best practice på att läsa/skapa,ändra/ta bort registernycklar.
#best practice på att skapa/ändra/kopiera/ta bort filer.
#best practice på att skapa/ta bort kataloger.
#best practice på att läs/skapa/ändra xml-filer.
#best practice på att läs/skapa/ändra ini-filer.
#Loggning
#Loopar

#Miljövariablar
#get-Help -name Cmdlet


###Registret

    ##LÄSA
    ##https://technet.microsoft.com/en-us/library/ee176852.aspx?f=255&MSPPError=-2147217396

#Ta fram all under HKLM\Software. Lägg till -Recurse om du vill kolla alla kataloger nedåt.
$all = Get-ChildItem "HKLM:\Software"
#Dotnotification. Använd inte | select om ni ska ha något i produktion då ni sätter krokben för er själv.
$all.Name

#Notera skillnaden mellan Get-ChildItem och Get-Item.
$cirrato = Get-Item "HKLM:\SOFTWARE\Cirrato"
#Pipea vidare till Get-ItemProperty
$property = $cirrato | Get-ItemProperty
$property.installdir

#Nedan rad returnerar all värden som finns för att avinstallera. Tex: 
$uninstall = Get-ChildItem "hklm:\software\microsoft\windows\currentversion\uninstall" | ForEach-Object {Get-ItemProperty $_.pspath} | Where-Object{$_.Displayname -like "Visual Studio*"}
$uninstall.UninstallString

    ##END Läsa

    ##Skapa
    <#The following example creates a new registry key named hsg in the HKCU:\Software location. Because the command includes the full path, it does not need to 
    execute from the HKCU drive. Because the command uses the Force switched parameter, the command overwrites the HKCU:\Software\HSG registry key if it already exists.
    https://blogs.technet.microsoft.com/heyscriptingguy/2012/05/09/use-powershell-to-easily-create-new-registry-keys/#>

$createKey = New-Item -Path HKCU:\Software -Name hsg #–Force
$createKey = New-Item -Path HKCU:\Software -Name hsg –Force 

#Uppdaterar värdet för default key.
$setDeafultKey = Set-Item -Path HKCU:\Software\hsg -Value “TESTING”
$Check = Get-Item HKCU:\SOFTWARE\hsg | Get-ItemProperty
$Check.'(default)'

#OneLiner
New-Item -Path HKCU:\Software\hsg1 -Value “TESTING" -Force | Get-ItemProperty | select '(default)'

#Lägga till properties i en existerande key. Går även att Pipea när man gör en New-Item enligt ovan.
New-ItemProperty -Path HKCU:\Software\hsg1 -Name "Foo" -PropertyType "String" -Value 'The answer is 42'

#https://blogs.technet.microsoft.com/heyscriptingguy/2012/05/12/weekend-scripter-use-powershell-to-easily-modify-registry-property-values/
#Uppdatera befintliga properties.

Set-ItemProperty -Path HKCU:\Software\hsg1 -Name Foo -Value "The answer is not 42"

#Om man vill kolla om en nyckel eller värde finns så kan man använda sig av Test-Path. Returnerar en boolean. 
Test-Path HKCU:\Software\hsg1 #True
Test-Path HKCU:\Software\hsg1\RandomKey #False

function testAndSetReg{
    if((Get-ItemProperty HKCU:\Software\hsg1 -Name bogus -ErrorAction SilentlyContinue).bogus){
    ‘Propertyalready exists’
    }
    else{ 
    Set-ItemProperty -Path HKCU:\Software\hsg1 -Name bogus -Value ’initial value’
    }


}

    ##End Skapa
    <#Uppgift:
    1. Skapa en GPO under HKCU\Software med valfritt namn
    2. Lägg till properties med namnet "Test", typen ska vara "String" och "Value" ska vara "123"
    3. Läs in nyckeln i konsolen och kontrollera att allt är ser rätt ut. 
    4. Uppdatera propertien från punkt 2 med calfritt värde. 
    5. Läs in nyckeln igen. 
    6. Ta bort nyckeln.  
    
    #>


###Filer och mappar

    ##Skapa filer
    New-Item -Path 'C:\temp\dummyfolder\file.txt' -ItemType "File"
    $testPath = Test-Path "C:\temp\dummyfolder\file.txt"

        if($testPath -eq $false){
        Write-Warning "Path $testPath doesnt exist!"
        }
        Else{
        Write-Host "Path $testPath exist!"
        }
    ##Skapa mappar
    New-Item -Path 'C:\temp\dummyfolder' -ItemType "Directory"
    $testPath = Test-Path "C:\Temp\Dummyfolder"

    if($testPath -eq $false){
        Write-Warning "Path $testPath doesnt exist!"
        }
        Else{
        Write-Host "Path $testPath exist!"
        }
    
    ##Ändra filer och kataloger
    #https://technet.microsoft.com/en-us/library/hh849763.aspx
    #Ändrar alla filer i katalogen C:\Temp\ som är av typen .Txt till .log
    Get-ChildItem "C:\temp\*.txt" | Rename-Item -NewName {$_.name -Replace '\.txt','.log' }
    Get-ChildItem "C:\temp\*.log"| Rename-Item -NewName {$_.name -Replace '\.log','.txt' }

    #Ändrar namn på en fil. Man kan kolla på Test-Path om man är osäker på om filen finns eller inte. 
    Rename-Item -Path "C:\Temp\Dummyfolder\file.txt" -NewName "newFileName.txt"
    #WhatIf?
    Rename-Item -Path "C:\Temp\Dummyfolder\file.txt" -NewName "newFileName.txt" -WhatIf

    #Flytta och byta namn samtidigt?
    Move-Item -Path "C:\Temp\Dummyfolder\file.txt" -Destination "C:\temp\OldFile.txt"

    #Byta namn på alla kataloger i en mapp.
    Get-ChildItem "C:\temp" | Where-Object{$_.PSIsContainer} | Rename-Item -NewName {$_.name -Replace 'OldName','NewName' }

    ##Ta bort filer och kataloger
    #https://technet.microsoft.com/sv-se/library/ee176938.aspx
    #Syntax
    Remove-Item "c:\scripts\test.txt"

    #Ta bort alla filer i en mapp rekursivt
    Remove-Item "c:\scripts\*"

    #Ta bort att filer utan en viss typ?
    Remove-Item c:\scripts\* -exclude *.ps1

    #Ta bort endast en viss typ av filer?
    Remove-Item c:\scripts\* -include .jpg,.mp3

    #Inkludera och exkludera samtidigt?
    Remove-Item c:\scripts\* -include *.txt -exclude *test*

    #Ta bort alla filer med en viss filändelse?
    Remove-Item C:\scripts\*.ps1 -WhatIf

    <#
    Uppgift: 
    1. Skapa en mapp
    2. Skapa en fil i mappen
    3. Skapa en mapp i mappen
    4. Läs in hela strukturen i konsolen från med start från mappen som skapades i punkt 1. 
    5. Döp om mappen eller filen. 
    6. Läs in hela strukturen i konsolen för att verifiera att det ser rätt ut. 
    7. Ta bort allt du skapat. 
    #>

    ##XML

    #Läsa xml-dokument
    #Deklarera varibeln för Xml-dokumentet så att vi kan komma åt den i ett senare skede. 
    [xml]$XmlDocument = Get-Content -Path C:\temp\Cars.xml
    $XmlDocument
    $XmlDocument.Cars
    $XmlDocument.Cars.Car | Format-Table -AutoSize
    $XmlDocument.Cars.Car | Where-Object{$_.Seats -eq 4}

    #Skapa XML-filer

    function createXML{
        #Skapa en blank XML-fil.
        $xmlWriter = New-Object System.XMl.XmlTextWriter('C:\temp\Cars2.xml',$Null)
        #Sätter formateringen för att filen ska bli lättläst.
        $XmlWriter.Formatting = 'Indented'
        $xmlWriter.Indentation = 1
        $XmlWriter.IndentChar = "`t"

        #Börja skriva
        $xmlWriter.WriteStartDocument()
        #Sätt en comment på Cars-taggen
        $xmlWriter.WriteComment('Car List')

        #Skapa root-elementet samt fyll på med info
        $xmlWriter.WriteStartElement('Cars')
        $XmlWriter.WriteAttributeString('Owner', 'Jay Leno')
        $xmlWriter.WriteAttributeString('VIN', '123567891')
        $xmlWriter.WriteElementString('Make','Ford')
        $xmlWriter.WriteElementString('Model','Taurus')
        $xmlWriter.WriteElementString('Year','2016')
        #När vi är klara med att lägga in informationen så avslutar vi skrivningen till elementet.
        $xmlWriter.WriteEndElement()

        #Avlsuta skrivningen och dumpa filen från det interna minnet. 
        $xmlWriter.WriteEndDocument()
        $xmlWriter.Flush()
        $xmlWriter.Close()
    }

    #Kolla i filen efter att vi skapat den
    [xml]$cars = Get-Content -Path C:\temp\Cars2.xml

    #Ändra i en XML
    #Gå till denna sida och gör alla steg själva: https://blogs.msdn.microsoft.com/sonam_rastogi_blogs/2014/05/14/update-xml-file-using-powershell/


    ###INI

#Skapa en ini fil
Function createIni{
$functionText = @"
[Options]
UpdateKey=04/28/2015 12:50:27 AM
WINDOW_LEFT=258
WINDOW_TOP=149
WINDOW_WIDTH=666
WINDOW_HEIGHT=519
WINDOW_MAX=0
BackupDir=C:\Windows\System32
UpdateCheck=1
Language=1033
(App)Sun Java=False
NewVersion=5.05.5176
SkipUAC=1
FinderInclude1=PATH|C:\|*.*|RECURSE
FinderInclude2=PATH|D:\|*.*|RECURSE
FinderIncludeStates=1|1
I see SkipUAC=1
ShowCleanWarning=False
ShowFirefoxCleanWarning=False
WipeFreeSpaceDrives=C:\
RunICS=0
CookiesToSave=*.piriform.com|google.com
"@

New-Item "C:\Temp\Ccleaner.ini" -type file -force -value $functionText
}

#Läsa en ini-fil
$ini = Get-Content "C:\Temp\Ccleaner.ini"
#Alternativ är att använda sig av Get-IniContent, custom script. https://gallery.technet.microsoft.com/scriptcenter/ea40c1ef-c856-434b-b8fb-ebd7a76e8d91
#Calla på scriptet. 
."C:\Temp\PowershellUtbildning2016\Get-IniContent.ps1"
$ini2 = Get-IniContent -FilePath "C:\temp\Ccleaner.ini"
$ini2.Options.Language
$Ini2.Options.SkipUAC

#Ändra i en ini-fil
$ini -replace "Language=1033","Language=1050" | Set-content "C:\Temp\Ccleaner.ini"
#Verifiera ändringen
$ini2 = Get-IniContent -FilePath "C:\temp\Ccleaner.ini"
$ini2.Options.Language

###Loggning och EA
Get-Content C:\temp\PowershellUtbildning2016\ErrorHandling.ps1


    ###Loopar
    #Do While
    #While
    #For 
    #Foreach-Object
    #Alla ovan finns men den som är mest kraftfull och den som ni förmodligen kommer jobba mest med är Foreach och foreach-object
    #Syntaxen är foreach/(-Object)($item in $array_collection){Command_block}
    
    #Ex. 1
    $array_collection = Get-ChildItem "C:\Temp\PowershellUtbildning2016"
    foreach($item in $array_collection){
        #Gör saker med innehållet.
        Write-Host "Denna fil eller katalog heter: $item"
        Write-Host "Denna fil eller katalog ändrades:" $item.LastWriteTime "`n"
    }
    
    #Ex. 2
    $Path = "C:\temp\PowershellUtbildning2016"
    Get-ChildItem $Path | ForEach-Object{
        #Gör saker med innehållet.
        Write-Host "Denna fil eller katalog heter: $item"
        Write-Host "Denna fil eller katalog ändrades:" $item.LastWriteTime "`n"
    }

    #Ex 3.
    $Path = Get-ChildItem "C:\temp\PowershellUtbildning2016"
    ForEach($item in $Path){

        #Gör saker med innehållet.
        if($item.LastWriteTime -gt (Get-Date).AddDays(-30)){
        Write-Host $item.Name "Är yngre än 30 dagar"
        }
        Else{
        Write-Host $item.Name "Är äldre än 30 dagar"
        }
    }

    #Mer om olika loopar och exempel: http://www.computerperformance.co.uk/powershell/powershell_loops.htm
    #uppgift, skriv en loop som Går igenom siffrorna 1-20, tar alla jämna tal och multiplicerar dom med 2 och skriver ut till konsolen. Så lite kod som möjligt! 
    <#Resultatet ska se ut som nedan:
    4
    8
    12
    16
    20
    24
    28
    32
    36
    40
    #>
    {
    1..20 | % {if($_ % 2 -eq 0 ) {$_*2 } }
    }


    ###Miljövariablar
    #https://technet.microsoft.com/en-us/library/ff730964.aspx
    #Lista alla på datorn
    Get-ChildItem Env:
    #Skapa en variabel
    $env:TestVariable = "This is a test environment variable."
    Get-ChildItem Env:TestVariable

    #Ta bort variabel
    Remove-Item Env:\TestVariable



    ##Frågor?
