<#
.Synopsis
   Denna funktion körs en gången för att populera upp ett AD med grupper.
   Grupperna kommer att heta $Name.NamnetPåServern.
   Grupperna kommer att skapar i OUet $location.

.DESCRIPTION
   
.EXAMPLE
   Example of how to use this cmdlet

   1. Specificera variablen $searchbase. - Här skriver från vilket OU som man ska leta efter datorobjekt i.
   2. Specificera variablen $location. - Här skriver man vilket OU som grupperna ska skapas i. 
   3. Specificera variablen $description. - Här skriver man ner den text som kommer att synas på gruppens description-fält i ADet.
   4. Specificera variablen $$name. - Här skriver man vilket namnstandard man vill att grupperna ska få. Just nu är det "G.Sec.LocalAdminSever.$Namn"
   5. Spara scriptet och exekvevera det med ett konto som har rättighet att skapa grupper i domänen.

.INPUTS
   N/A

.OUTPUTS
   1 grupp/datorobjekt som har OperatingSystem lika med *Server*.

.NOTES
   General notes

#>



function createGroup
    {
    $searchbase = "IMPUT LOCATION IN DN-format"
    $computers = Get-ADComputer -Filter {OperatingSystem -Like '*Server*'} -searchbase $searchbase
    $location = "IMPUT LOCATION IN DN-format"
    $description = "Members in this group will be granted the local admin priviliges on server $namn"

    foreach($a in $computers)
        {
        $namn = $a.Name
        $name = "G.Sec.General.LocalAdmin$namn"

        New-AdGroup -Path $location -Name $name -SamAccountName $name -GroupScope Global -GroupCategory Security -DisplayName $name -Description $description

        }

    }
