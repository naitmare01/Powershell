<#
.Author
  David Berndtsson, Data Ductus
  2016-08-19

.Synopsis
  Detta script är tänkt att köras automatiskt på ett regelbundet intervall. 
  Meningen med detta script är att underhålla AD-grupper som är knutna till localadmin på respektive server.

.DESCRIPTION
  Alla servrar i domänen knet.ad.svenskyrkan.se ska ha varsin domän-säkerhetsgrupp som är knuten till servern. 
  Denna grupp ska tillsammans med standardgrupperna(ex. Domain Admins) vara local Admin på servern. 

  Bakgrunden till detta är för att underlätta administrationen av behörigheteshanteringen.
   
.EXAMPLE
   Example of how to use this cmdlet

   Kommer senare.

.INPUTS
   N/A

.OUTPUTS
   Alla servrar kommer ha sin enga specifika grupp som är localadmin. 
   Om grupperna inte finns kommer grupperna att skapas. 
   Om gruppen finns men inte servern kommer gruppen att tas bort. 

.NOTES
   General notes

   #Requires -version 4(or higher)

   Att göra:


#>

#Statiska variablar
$searchbase = "INPUT LOCATION IN DN FORMAT"
$computers = Get-ADComputer -Filter {OperatingSystem -Like '*Server*'} -searchbase $searchbase
$location = "INPUT LOCATION IN DN FORMAT"

$date = Get-Date -format "dd-MMM-yyyy"
$now = Get-Date -format "dd-MMM-yyyy HH:mm"
$logpath = "C:\Scripts\ServerLocalAdmins\Logs\$date"+"Logfile.txt"



function saveLog($textToSave)
{
    $now = Get-Date -format "dd-MMM-yyyy HH:mm"
    $textToSave = "`n" + $textToSave + " - $now"

    $textToSave | Out-File $logpath -Encoding utf8 -Append
}


#Denna funktion finns endast för att skapa grupper om en server finns men inte en grupp.
#Denna funktion callas i funktionen "checkForGroups" om nödvändigt. 
function createGroupIfMissing($name2)
{
    $serverName = $name2.Substring(24)
    $description = "Members in this group will be granted the local admin priviliges on server $serverName"
    New-AdGroup -Path $location -Name $name2 -SamAccountName $name2 -GroupScope DomainLocal -GroupCategory Security -DisplayName $name2 -Description $description
}


#Nedanstående funktion kollar om det finns grupper kopplade till respektive servrar eller inte. 
#Denna funktion kan man sätta som en scheduled task 1gång/vecka eller liknande. 
function checkForGroups
{

    foreach($a in $computers)
        {
            $namn = $a.Name
            $name = "G.Sec.General.LocalAdmin$namn"
            $checkGroup = Get-ADGroup -Filter {(name -eq $name)} -searchbase $location
            $NyVar = $checkGroup.samaccountname

        #Ser till att rätt grupper finns. 
        if($checkGroup -eq $null)
            {
                $log = "Group $name doesn't Exist"
                savelog($log)
                #OM gruppen inte finns så skapas en grupp med hjälp av funktionen nedan.
                createGroupIfMissing($name)
                $log = "Group $name created"
                savelog($log)
            }
        else
            {
                $log = "Group $name already exist"
                savelog($log)
                #Om gruppen redan finns behövs inget göras och loppen kan gå vidare.
            }

        }
        #Pausar scriptet i 1200s(20minuter) för att replikering ska hinnas göras innan den försöker lägga till grupperna på respektive server. 
        start-sleep -s 1200
        Foreach($a in $computers){

            Localadmin "$namn" "$NyVar" "$Name"

        }
}

#Denna funktion kollar om det finns grupper men inte en server. 
#Om så är fallet så ska gruppen bort.
function deleteGroupIfMissingServer
{
    $orphanedGroup = Get-ADGroup -Filter {(name -like 'G.Sec.General.LocalAdmin*')} -searchbase $location

        foreach($b in $orphanedGroup)
            {
                #Här ändrar man siffran 23 till antal tecken som namnstandarden är på gruppnamnen.
                #Variabeln "Substring" är endast sista delen i gruppnamnet och MÅSTE vara samma som dator-namnet på serven.
                $subString = $b.Name.Substring(25)

                try
                { 
                $missingserver = Get-ADComputer -identity $substring 
                }

                catch
                {
                $b = $b.name
                $log = "Server $substring doesnt exist, but the group $b exist. Saving to log. "
                savelog($log)
                }

                finally
                {
                }
    

            }
}


#Denna funktion lägga till gruppen $DomainGroup på server $Computer som local admin. 
#Den kommer endast att lägga till gruppen som local admin om den inte redan är det. 
function Localadmin($Computer, $DomainGroup, $FullGroupName)
{
    try{
    $group = [ADSI]("WinNT://"+$Computer+"/Administrators,Group")
    $group.psbase.invoke("members") | foreach {

            $username = $_.gettype().invokemember("Name", "GetProperty", $null, $_, $null)
        }

        if ($username -eq $FullGroupName) 
        {
            $log = "$Fullgroupname is already admin on server $computer"
            savelog($log)
        }
        else
        {
            $log =  "$Fullgroupname is NOT admin on server $computer"
            savelog($log)
            $group.add("WinNT://$env:USERDOMAIN/$DomainGroup,Group")
            $log = "Group $FullGroupName has been added as localadmin on server $Computer"
            savelog($log)
        }
    }
    catch{
    $log = "Can't connect with WinRM to server $computer."
    saveLog($log)
    }
}



checkForGroups

$theEnd = "The script finnished.`n---------------------------------"
saveLog($theEnd)
