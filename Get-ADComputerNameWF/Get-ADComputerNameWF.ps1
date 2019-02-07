<#
    .SYNOPSIS
        Detta script är en Windows Forms applikation som hanterar datornamnsbyte och flyttar datorn korrekt i ADet. 
    .DESCRIPTION
        Scriptet är framtaget för att vi ska kunna deploya nya datorer med hjälp utav SCCM. 
        Alla datorer kommer att hamna i ett och samma OU. Teknikern loggar sedan in på datorn med sitt tilldelade 
        ad-konto och kör scriptet. Scriptet genererar ett datorkonto och byter namn samt flyttar dator-objektet till 
        den valda enheten i Adet. 

        Scriptet har även en integration mot BAS för att få fram lösenordet till det lokala administratörskontot för enheten. 
        Att byta det lokala administratörslösenordet sker dock manuellt. 
        Integrationen sker genom att en Internet Explrorer öppnas och information om hur man tar fram administratörslösenordet visas. 
    .NOTES
        Senast uppdaterad: 
			David Berndtsson, 2019-02-07, Data Ductus Uppsala
#>
Function Get-IsLaptop{
    Param(
    [string]$computer = $env:COMPUTERNAME
    )#End param

    begin{
        $isLaptop = $false
        $returnArray = [System.Collections.ArrayList]@()
    }#End begin

    process{
        foreach($c in $computer){
            if(Get-WmiObject -Class win32_systemenclosure -ComputerName $c | Where-Object { $_.chassistypes -eq 9 -or $_.chassistypes -eq 10 -or $_.chassistypes -eq 14}){
                $isLaptop = $true
            }#End if

            if(Get-WmiObject -Class win32_battery -ComputerName $c){
                $isLaptop = $true
            }#End if

            $customObject = New-Object System.Object
            $customObject | Add-Member -Type NoteProperty -Name Computer -Value $c
            $customObject | Add-Member -Type NoteProperty -Name Laptop -Value $isLaptop
            $returnArray.Add($customObject) | Out-Null
        }#End foreach
    }#end process
    end{
        return $customObject
    }#End end
}#end function Get-Laptop
function Get-FreeComputerName{
    [CmdletBinding()]
    param(
    #Searchbase to list OUs. 
    [parameter(ValueFromPipeline=$True)]
    [string]$Searchbase = "OU=Computers,OU=ASP,DC=knet,DC=ad,DC=svenskakyrkan,DC=se",
    [parameter(Mandatory=$True)]
    [string]$Stift,
    [parameter(Mandatory=$True)]
    [string]$Enhet,
    [parameter(Mandatory=$True)]
    [ValidateSet('LAP','WSN')]
    [string]$ComputerType
    )#End param

    begin{
        $returnArray = [System.Collections.ArrayList]@()

        if (-not (Get-Module -Name "ActiveDirectory")) {
            Throw "Module ActiveDirectory is not loaded"
        }
        

        if($ComputerType -like "LAP"){
            $ComputerTypeOU = "Mobile"   
        }
        else{
            $ComputerTypeOU = "Stationary"
        }

        $Computers = Get-ADComputer -Filter * -SearchBase "OU=$ComputerTypeOU,OU=$Enhet,OU=$Stift,$Searchbase"
        $StiftDescription = Get-ADOrganizationalUnit -Filter * -SearchBase "OU=$Stift,$Searchbase" -SearchScope Base -Properties description
        $EnhetDescription = Get-ADOrganizationalUnit -Filter * -SearchBase "OU=$Enhet,OU=$Stift,$Searchbase" -SearchScope Base -Properties description
    }#End begin

    process{
        if($null -eq $Computers){
            $AvalibleNumber = "001"
            $compName = $StiftDescription.description + "-$ComputerType-" + $EnhetDescription.description + "-" + $AvalibleNumber
            $customObjectFirstFree = New-Object System.Object
            $customObjectFirstFree | Add-Member -Type NoteProperty -Name FirstFree -Value $AvalibleNumber
            $customObjectFirstFree | Add-Member -Type NoteProperty -Name StiftDescription -Value $StiftDescription.description
            $customObjectFirstFree | Add-Member -Type NoteProperty -Name EnhetDescription -Value $EnhetDescription.description
            $customObjectFirstFree | Add-Member -Type NoteProperty -Name FreeComputerName -Value $compName
            $customObjectFirstFree | Add-Member -Type NoteProperty -Name SearchBase -Value "OU=$ComputerTypeOU,OU=$Enhet,OU=$Stift,$Searchbase"
        }#End if
        else{
            foreach($c in $Computers){
    
                try{
                    [int]$number = $c.Name.Split('-')[3]
                    $customObject = New-Object System.Object
                    $customObject | Add-Member -Type NoteProperty -Name TakenNumber -Value $number
                    $returnArray.Add($customObject) | Out-Null
                }#End try
                catch{
                    #
                }#End catch
            
            }#End foreach

                $range = 1..999
                
                foreach($n in (Compare-Object $range $returnArray.TakenNumber | Where-Object{$_.SideIndicator -like "<="}).inputobject){
                    $intLength = $n.ToString().Length

                    if($intLength -eq 1){
                        $AvalibleNumber = "00$n"
                    }#End if
                    elseif($intLength -eq 2){
                        $AvalibleNumber = "0$n"
                    }#End elseif
                    else{
                        $AvalibleNumber = $n
                    }#End else

                    $compName = $StiftDescription.description + "-$ComputerType-" + $EnhetDescription.description + "-" + $AvalibleNumber

                    try{
                        Get-ADComputer $compName -ErrorAction Stop | Out-Null
                        Write-Verbose "$compName existerar på en annan enhet. Försöker nästa nummer"
                    }#End try
                    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
                        Write-Verbose "$compName är ledigt."
                        break
                    }#End catch
                    catch{
                        Write-Verbose $error[0].exception.GetType().fullname
                    }#End catch

                }#End foreach

                $customObjectFirstFree = New-Object System.Object
                $customObjectFirstFree | Add-Member -Type NoteProperty -Name FirstFree -Value $AvalibleNumber
                $customObjectFirstFree | Add-Member -Type NoteProperty -Name StiftDescription -Value $StiftDescription.description
                $customObjectFirstFree | Add-Member -Type NoteProperty -Name EnhetDescription -Value $EnhetDescription.description
                $customObjectFirstFree | Add-Member -Type NoteProperty -Name FreeComputerName -Value $compName
                $customObjectFirstFree | Add-Member -Type NoteProperty -Name SearchBase -Value "OU=$ComputerTypeOU,OU=$Enhet,OU=$Stift,$Searchbase"

        }#End else
    }#End process

    end{
        return $customObjectFirstFree
    }#End end 
}#End function
function Get-EnhetList{
    [CmdletBinding()]
    param (
    #Searchbase to list OUs. 
    [parameter(ValueFromPipeline=$True)]
    [string]$Searchbase = "OU=Computers,OU=ASP,DC=knet,DC=ad,DC=svenskakyrkan,DC=se",
    [parameter(Mandatory=$True)]
    [string]$Stift
    )#End param
    
    begin{
        $returnArray = [System.Collections.ArrayList]@()

        if (-not (Get-Module -Name "ActiveDirectory")) {
            Throw "Module ActiveDirectory is not loaded"
        }
        Write-Verbose "OU=$Stift,$Searchbase"
        $EnhetList = Get-ADOrganizationalUnit -Filter * -SearchBase "OU=$Stift,$Searchbase" -SearchScope OneLevel -Properties description

    }#End Begin
    
    process{
        $i = 1
        foreach($Enhet in $EnhetList){
            $customObject = New-Object System.Object
            $customObject | Add-Member -Type NoteProperty -Name Stift -Value $Stift
            $customObject | Add-Member -Type NoteProperty -Name Enhet -Value $Enhet.Name
            $customObject | Add-Member -Type NoteProperty -Name Description -Value $Enhet.description
            $customObject | Add-Member -Type NoteProperty -Name Nummer -Value $i
            $returnArray.Add($customObject) | Out-Null
            $i = $i + 1
        }#End foreach
    }#End process
    
    end{
        return $returnArray
    }#End end
}#End function
function Get-StiftList{
    [CmdletBinding()]
    param (
    #Searchbase to list OUs. 
    [parameter(ValueFromPipeline=$True)]
    [string]$Searchbase = "OU=Computers,OU=ASP,DC=knet,DC=ad,DC=svenskakyrkan,DC=se"
    )#End param
    
    begin{
        $returnArray = [System.Collections.ArrayList]@()

        if (-not (Get-Module -Name "ActiveDirectory")) {
            Throw "Module ActiveDirectory is not loaded"
        }
        
        $StiftList = Get-ADOrganizationalUnit -Filter * -SearchBase $Searchbase -SearchScope OneLevel -Properties description

    }#End Begin
    
    process{
        $i = 1
        foreach($Stift in $Stiftlist){
            $customObject = New-Object System.Object
            $customObject | Add-Member -Type NoteProperty -Name Stift -Value $Stift.Name
            $customObject | Add-Member -Type NoteProperty -Name Enhet -Value ""
            $customObject | Add-Member -Type NoteProperty -Name Description -Value $Stift.description
            $customObject | Add-Member -Type NoteProperty -Name Nummer -Value $i
            $returnArray.Add($customObject) | Out-Null
            $i = $i + 1
        }#End foreach
    }#End process
    
    end{
        return $returnArray
    }#End end
}#End function
Function New-WindowsFormsLabel{
    [CmdletBinding()]
    param(
        #Text on the label
        [string]$Text,
        #Location (X,Y) on the label
        $Location,
        [boolean]$AutoSize = $true,
        $Size
    )#End param

    begin{

    }#End begin

    process{
        $Label = New-Object System.Windows.Forms.Label
        $Label.Text = $Text
        $Label.AutoSize = $AutoSize
        $Label.Location = New-Object System.Drawing.Size($Location)
        #if($Width){
        #    $Label.Width = $Width
        #}#End if
        if($Size){
            $Label.Size = New-Object System.Drawing.Size($Size)
        }#End if
    }#End process

    end{
        $Label
    }#end end
}#end function
Function New-WindowsFormsGroupBox{
    [CmdletBinding()]
    param(
        #Text on the label
        [string]$Text,
        #Location (X,Y) on the groupbox
        $Location,
        #Size (X,Y) on the groupbox
        $Size
    )#End param

    begin{

    }#End begin

    process{
        $groupBoxInfo = New-Object System.Windows.Forms.GroupBox #create the group box
        $groupBoxInfo.Location = New-Object System.Drawing.Size($Location) #location of the group box (px) in relation to the primary window's edges (length, height)
        $groupBoxInfo.size = New-Object System.Drawing.Size($Size) #the size in px of the group box (length, height)
        $groupBoxInfo.text = $Text #labeling the box
    }#End process

    end{
        $groupBoxInfo
    }#end end
}#end function
Function New-WindowsFormsRadioButton{
    [CmdletBinding()]
    param(
        #Text on the label
        [string]$Text,
        #Location (X,Y) on the groupbox
        $Location,
        #Size (X,Y) on the groupbox
        $Size,
        $Checked
    )#End param

    begin{

    }#End begin

    process{
        $RadioButton = New-Object System.Windows.Forms.RadioButton #create the radio button
        $RadioButton.Location = new-object System.Drawing.Point($Location) #location of the radio button(px) in relation to the group box's edges (length, height)
        $RadioButton.size = New-Object System.Drawing.Size($Size) #the size in px of the radio button (length, height)
        $RadioButton.Checked = $Checked
        $RadioButton.AutoCheck = $false #Read-only
        $RadioButton.Text = $Text #labeling the radio button
    }#End process

    end{
        $RadioButton
    }#end end
}#end function
Function New-WindowsFormsComboBox{
    [CmdletBinding()]
    param(
        #Text on the label
        [string]$Text,
        #Location (X,Y) on the groupbox
        $Location,
        #Size (X,Y) on the groupbox
        $Size
    )#End param

    begin{

    }#End begin

    process{
        $ComboBox = New-Object System.Windows.Forms.ComboBox #create the group box
        $ComboBox.Location = New-Object System.Drawing.Size($Location) #location of the group box (px) in relation to the primary window's edges (length, height)
        $ComboBox.size = New-Object System.Drawing.Size($Size) #the size in px of the group box (length, height)
        $ComboBox.text = $Text #labeling the box
    }#End process

    end{
        $ComboBox
    }#end end
}#end function
Function New-WindowsFormsTextBox{
    [CmdletBinding()]
    param(
        #Location (X,Y)
        $Location,
        #Size (X,Y)
        $Size,
        #Autosize, True/false
        [boolean]$AutoSize,
        #Read only, True/false
        [boolean]$ReadOnly,
        #Multiline, True/false
        [boolean]$Multiline
    )#End param

    begin{

    }#End begin

    process{
        $TextBox = New-Object System.Windows.Forms.TextBox
        $TextBox.AutoSize = $AutoSize
        $TextBox.ReadOnly = $ReadOnly
        $TextBox.Multiline = $Multiline
        $TextBox.Size = New-Object System.Drawing.Size($Size)
        $TextBox.Location = New-Object System.Drawing.Size($Location) 
    }#End process

    end{
        $Textbox
    }#end end
}#end function
Function New-WindowsFormsButton{
    [CmdletBinding()]
    param(
        #Text
        [string]$Text,
        #Location (X,Y)
        $Location,
        #Size (X,Y)
        $Size
    )#End param

    begin{

    }#End begin

    process{
        $Button = New-Object System.Windows.Forms.Button 
        $Button.Location = New-Object System.Drawing.Size($Location) 
        $Button.Size = New-Object System.Drawing.Size($Size) 
        $Button.Text = $Text 
    }#End process

    end{
        $Button
    }#end end
}#end function
Function New-WindowsForms{
    [CmdletBinding()]
    param(
        #Text
        [string]$Text,
        #Location (X,Y)
        $Size
    )#End param

    begin{

    }#End begin

    process{
        $Form = New-Object System.Windows.Forms.Form 
        $Form.Size = New-Object System.Drawing.Size($Size) 
        $Form.StartPosition = "CenterScreen" 
        $Form.FormBorderStyle = 'Fixed3D' 
        $Form.Text = $Text
        $Font = New-Object System.Drawing.Font("Arial",10,[System.Drawing.FontStyle]::Bold) 
        $form.Font = $Font 
    }#End process

    end{
        $Form
    }#end end
}#end function
Function New-WindowsFormsProgressBar{
    [CmdletBinding()]
    param(
        #Text
        [string]$Text,
        #Location (X,Y)
        $Location,
        #Size (X,Y)
        $Size
    )#End param

    begin{

    }#End begin

    process{
        $ProgressBar = New-Object System.Windows.Forms.ProgressBar
        $ProgressBar.Location = New-Object System.Drawing.Point($Location) #location of the group box (px) in relation to the primary window's edges (length, height)
        $ProgressBar.Size = New-Object System.Drawing.Size($Size) #the size in px of the group box (length, height)
        $Progressbar.Value = 0
        $ProgressBar.Name = $Text
        $ProgressBar.Style = "Continuous"
    }#End process

    end{
        $ProgressBar
    }#end end
}#end function
Function New-WindowsFormsMenuStrip{
    [CmdletBinding()]
    param(
    )#End param

    begin{

    }#End begin

    process{
        $MenuStrip = New-Object System.Windows.Forms.MenuStrip
    }#End process

    end{
        $MenuStrip
    }#end end
}#End function
Function New-WindowsFormsToolStripMenuItem{
    [CmdletBinding()]
    param(
        $Text
    )#End param

    begin{

    }#End begin

    process{
        $ToolStripMenuItem = New-Object System.Windows.Forms.ToolStripMenuItem
        $ToolStripMenuItem.Text = $Text
    }#End process

    end{
        $ToolStripMenuItem
    }#end end
}#End function

# Get the ID and security principal of the current user account
$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
$myWindowsPrincipal = new-object System.Security.Principal.WindowsPrincipal($myWindowsID)

# Get the security principal for the Administrator role
$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator

# Check to see if we are currently running "as Administrator"
if ($myWindowsPrincipal.IsInRole($adminRole)){
   # We are running "as Administrator"
   clear-host
}
else{
   # We are not running "as Administrator" - so relaunch as administrator

   # Create a new process object that starts PowerShell
    $newProcess = new-object System.Diagnostics.ProcessStartInfo "PowerShell";

   # Specify the current script path and name as a parameter
    $newProcess.Arguments = $myInvocation.MyCommand.Definition;

   # Indicate that the process should be elevated
    $newProcess.Verb = "runas";

    #Run the process in Maximized window.
    $newProcess.WindowStyle = "Maximized"

   # Start the new process
   [System.Diagnostics.Process]::Start($newProcess);

   # Exit from the current, unelevated, process
   exit

}



#This script relies on the module activedirectory to run. See custom module Install-ActiveDirectory
Import-Module activedirectory
[System.Reflection.Assembly]::LoadWithPartialName("System.Drawing") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
[System.Windows.Forms.Application]::EnableVisualStyles() | Out-Null
Add-Type -AssemblyName PresentationFramework

###Build basic forms
$Form = New-WindowsForms -Text "Generera datorkonto" -Size (1280,720)
$ProgressBarForm = New-WindowsForms -Text "Renaming and moving computer object.." -Size (400,175)
$Menustrip = New-WindowsFormsMenuStrip
###End Build basic forms

###Determine if computer is laptop or not. 
if((Get-IsLaptop).laptop){
    #Laptop
    $laptopChecked = $true
    $wsnchecked = $false
}
else{
    #Workstation
    $laptopChecked = $false
    $wsnchecked = $true
}
###END Determine if computer is laptop or not. 

###Create objects. 
$TitleLabel = New-WindowsFormsLabel -Text "Generera ett datorkonto och flytta datorn korrekt i ADet" -Location (50,40)
$StiftLabel = New-WindowsFormsLabel -Text "Stift:" -Location (50,105)
$EnhetLabel = New-WindowsFormsLabel -Text "Enhet:" -Location (50,150)
$ProgresLabel = New-WindowsFormsLabel -Text "Renaming computer name and moving the computer to the correct place in AD. Please wait." -Location (15,40) -Size (375,60) -AutoSize $false
$InformationGroupBox = New-WindowsFormsGroupBox -Text "Information:" -Location (620,250) -Size (500,150)
$ComputerTypeGroupbox = New-WindowsFormsGroupBox -Text "Laptop eller Stationär:" -Location (620,100) -Size (500,150)
$Labelhostname = New-WindowsFormsLabel -Text "Hostname: $env:computername" -Location (15,40)
$LabelUSERDNSDOMAIN = New-WindowsFormsLabel -Text "Userdnsdomain: $env:USERDNSDOMAIN" -Location (15,60)
$LabelUSERName  = New-WindowsFormsLabel -Text "Username: $env:userdomain\$env:username" -Location (15,80)
$RadioButtonLaptop = New-WindowsFormsRadioButton -Text "Laptop" -Location (15,40) -Size (100,40) -Checked $laptopChecked
$RadioButtonWSN = New-WindowsFormsRadioButton -Text "Workstation" -Location (15,70) -Size (150,40) -Checked $wsnchecked
$DropDownStift = New-WindowsFormsComboBox -Text "--Välj Stift--" -Location (100,100) -Size (400,400)
$DropDownEnhet = New-WindowsFormsComboBox -Text "--Välj Enhet--" -Location (100,150) -Size (400,400)
$Textbox = New-WindowsFormsTextbox -Location (100,200) -Size (400,200) -AutoSize $false -ReadOnly $True -Multiline $True
$OkbuttonEnhet = New-WindowsFormsButton -Text "OK" -Location (500,150) -Size (100,30)
$OkbuttonStift = New-WindowsFormsButton -Text "OK" -Location (500,100) -Size (100,30)
$ButtonGenerateName = New-WindowsFormsButton -Text "Generera datornamn" -Location (100,410) -Size (200,30)
$ButtonRenameComp = New-WindowsFormsButton -Text "Byt datornamn" -Location (300,410) -Size (200,30)
$ProgresBar = New-WindowsFormsProgressBar -Text "Progress." -Location (15,15) -Size (360,20)
$FileToolstripMenuItem = New-WindowsFormsToolStripMenuItem -Text "File"
$ToolStripSeparator = New-Object -TypeName System.Windows.Forms.ToolStripSeparator
$ExitToolstripMenuItem = New-WindowsFormsToolStripMenuItem -Text "Exit"
$RestartComputerToolstripMenuItem = New-WindowsFormsToolStripMenuItem -Text "Restart Computer"
###End create objects. 

###Logic for objects
    #OkButtonEnhet
    $OkbuttonEnhet.Add_Click({
        if($DropDownEnhet.SelectedItem){
            $TextBox.Clear()
            $TextBox.Text = ("Stift är: " + $DropDownStift.SelectedItem)
            $TextBox.AppendText("`n`n")
            $TextBox.AppendText("Enhet är: " + $DropDownEnhet.SelectedItem)
        }
    })
    #End OkButtonEnhet

    #DropDownStift
    $stiftlist = Get-StiftList
    ForEach ($Item in $stiftlist.Stift) {
        $DropDownStift.Items.Add($Item) | Out-Null
    }
    #End DropDownStift

    #OkbuttonStift
    $OkbuttonStift.Add_Click({
        if($DropDownStift.SelectedItem){
            $TextBox.Text = ("Stift är: " + $DropDownStift.SelectedItem)
    
            $DropDownEnhet.Items.Clear()
            $DropDownEnhet.Text = "--Välj Enhet--"
            $EnhetList = Get-EnhetList -Stift $DropDownStift.SelectedItem
            ForEach ($Item in $EnhetList.Enhet) {
                $DropDownEnhet.Items.Add($Item) | Out-Null
            }
        }
    })
    #End OkbuttonStift

    #ButtonGenerateName
    $ButtonGenerateName.Add_Click({
        if($DropDownEnhet.SelectedItem -and $DropDownStift.SelectedItem){
            if($RadioButtonLaptop.Checked -eq $true){
                $CompType = "LAP"
            }
            elseif($RadioButtonWSN.Checked -eq $true){
                $CompType = "WSN"
            }
            else{
                $CompType = "LAP"
            }
            $global:FirstFreeComputernumber = Get-FreeComputerName -Stift $DropDownStift.SelectedItem -Enhet $DropDownEnhet.SelectedItem -ComputerType $CompType
            $global:compName = $FirstFreeComputernumber.FreeComputerName
            
            $TargetPath = $FirstFreeComputernumber.SearchBase
            $TextBox.Clear()
            $TextBox.Text = ("Stift är: " + $DropDownStift.SelectedItem)
            $TextBox.AppendText("`n`n")
            $TextBox.AppendText("Enhet är: " + $DropDownEnhet.SelectedItem)
            $TextBox.AppendText("`n`n")
            $TextBox.AppendText("Ny sökväg för datorn är: " + $TargetPath)
            $TextBox.AppendText("`n`n")
            $TextBox.AppendText("Datornamn är: $compName")
        }
    })
    #End ButtonGenerateName

    #ButtonRenameComp
    $ButtonRenameComp.Add_Click({
        if($TextBox.Text -like "*Datornamn är: *"){
            $Messageboxbody = "Är du säker på att du vill byta datornamn från $env:computername till $global:compName"
            
            $ButtonType = [System.Windows.MessageBoxButton]::YesNoCancel
            $MessageboxTitle = "Byt datornamn"
            $MessageIcon = [System.Windows.MessageBoxImage]::Warning
            $MessageBox = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

            if($MessageBox -like "Yes"){
                #Start try to rename the computer
                try{
                    Rename-Computer -NewName $global:compName -DomainCredential ($Cred = (Get-Credential -Message "Enter your username and password to perform the renaming of this computer. Format must be DOMAIN\USERNAME")) -ErrorAction Stop

                    $ProgressBarForm.Show() | Out-Null
                    $ProgressBarForm.Focus() | Out-Null
                    $TimeRange = 1..15
                    $processed = 0
                    ForEach ($i in $TimeRange) {
                        Start-Sleep -Milliseconds 1000
                        $processed++
                        $percentage = ($processed/($TimeRange.count))*100
                        $ProgresBar.Value = $percentage
                        $ProgressBarForm.Refresh()
                    }
                    $ProgressBarForm.Close()

                    $TargetPath = $global:FirstFreeComputernumber.SearchBase
                    
                    #Start try to move the computer
                    try{
                        Get-ADComputer $global:compName | Move-ADObject -TargetPath $TargetPath -Credential $Cred -ErrorAction Stop
    
                        #Restart Computer popup
                        $Messageboxbody = "Du har nu bytt namn på datorn till $global:compName. Vill du ändra administratörslösenordet på datorn innan du startar om? `n`nInformation om hur du får fram det lokala administratörslösenordet kommer att skrivas ut i applikationen."
                
                        $ButtonType = [System.Windows.MessageBoxButton]::YesNoCancel
                        $MessageboxTitle = "Ändra administratörslösenordet"
                        $MessageIcon = [System.Windows.MessageBoxImage]::Warning
                        $MessageBox = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
    
                        if($Messagebox -like "Yes"){
                            #Restart-Computer
                            $Browser = New-Object -ComObject internetexplorer.application
                            $Browser.navigate2("http://bestallningsportal.system.svenskakyrkan.se/adminpages/adminartikel.aspx")
                            $Browser.visible=$true

                            $TextBox.Clear()
                            $TextBox.Text = "1. Klicka 'Beställning'"
                            $TextBox.AppendText("`n`n")
                            $TextBox.AppendText("2. Välj beställande enhet i listan")
                            $TextBox.AppendText("`n`n")
                            $TextBox.AppendText("3. Klicka på BAS i vänsterspalten")
                            $TextBox.AppendText("`n`n")
                            $TextBox.AppendText("4. Klicka Stiftadmin längst ned.")
                            $TextBox.AppendText("`n`n")
                            $TextBox.AppendText("5. Gå till korrekt enhet och klicka på 'Ändra' för att se vilket adminlösenord som enheten har.")
                            $TextBox.AppendText("`n`n")
                            $TextBox.AppendText("6. Kopiera ut lösenordet och sätt som nytt lösenord för kontot 'Administrator/Administratör' lokalt.")
                            $TextBox.AppendText("`n`n")
                            $TextBox.AppendText("7. Starta om datorn för att slutföra datornamnsbytet.")
                        }#End if
                        else{
                            $TextBox.Clear()
                            $TextBox.Text = "Datorn har bytt namn till $global:compName, en omstart av datorn krävs för att slutföra. Starta om datorn nu."
                            $TextBox.AppendText("`n`n")
                            $TextBox.AppendText("`n`n")
                            $TextBox.AppendText("1. Klicka på 'File'")
                            $TextBox.AppendText("`n`n")
                            $TextBox.AppendText("2. Klicka på 'Restart Computer'")
                            $TextBox.AppendText("`n`n")
                            $TextBox.AppendText("3. Klicka på 'Yes'")
                        }#End else
                    }#End try
                    catch{
                        $Messageboxbody = "Datorn kunde inte flyttas korrekt i ADet. Kontrollera att du har rättigheter på ditt konto du angav för att flytta datorobjekt och pröva igen. Om felet kvarstår kontakta kanslistöd på 018 - 16 97 00"
                
                        $ButtonType = [System.Windows.MessageBoxButton]::Ok
                        $MessageboxTitle = "Fel vid flytt av datorkonto"
                        $MessageIcon = [System.Windows.MessageBoxImage]::Error
                        $MessageBox = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
                    }#End catch
                }#End try
                catch{
                    $Messageboxbody = "Datorn har inte bytt namn. Kontrollera att du rättigheter på ditt konto du angav och pröva igen. Om felet kvarstår kontakta kanslistöd på 018 - 16 97 00"
            
                    $ButtonType = [System.Windows.MessageBoxButton]::Ok
                    $MessageboxTitle = "Fel vid namnbyte av datorn"
                    $MessageIcon = [System.Windows.MessageBoxImage]::Error
                    $MessageBox = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
                }#End catch

            }#End if

        }#End if
    })
    #End ButtonRenameComp

$ExitToolstripMenuItem.Add_Click({
    $Messageboxbody ="Vill du avsluta scriptet?"
                
    $ButtonType = [System.Windows.MessageBoxButton]::YesNoCancel
    $MessageboxTitle = "Avsluta Scriptet"
    $MessageIcon = [System.Windows.MessageBoxImage]::Warning
    $MessageBox = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

    if($Messagebox -like "Yes"){
        [System.Windows.Forms.Application]::Exit($null)
    }#End if
})

$RestartComputerToolstripMenuItem.Add_Click({
    $Messageboxbody ="Vill du starta om datorn?"
                
    $ButtonType = [System.Windows.MessageBoxButton]::YesNoCancel
    $MessageboxTitle = "Starta om datorn"
    $MessageIcon = [System.Windows.MessageBoxImage]::Warning
    $MessageBox = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

    if($Messagebox -like "Yes"){
        Restart-Computer
    }#End if
})
###End logic for objects 

###Add objects to the form. 
$Form.Controls.Add($TitleLabel)
$Form.Controls.Add($StiftLabel)
$Form.Controls.Add($EnhetLabel)
$Form.Controls.Add($InformationGroupBox)
$InformationGroupBox.Controls.Add($Labelhostname)
$InformationGroupBox.Controls.Add($LabelUSERDNSDOMAIN)
$InformationGroupBox.Controls.Add($LabelUSERName)
$Form.Controls.Add($ComputerTypeGroupbox)
$ComputerTypeGroupbox.Controls.Add($RadioButtonLaptop)
$ComputerTypeGroupbox.Controls.Add($RadioButtonWSN)
$Form.Controls.Add($DropDownStift)
$Form.Controls.Add($DropDownEnhet)
$Form.Controls.Add($TextBox)
$Form.Controls.Add($OkbuttonEnhet)
$Form.Controls.Add($OkbuttonStift)
$Form.Controls.Add($ButtonGenerateName)
$Form.Controls.Add($ButtonRenameComp)
$ProgressBarForm.Controls.Add($ProgresBar)
$ProgressBarForm.Controls.Add($ProgresLabel)
$Form.Controls.Add($Menustrip)
$Menustrip.Items.Add($FileToolstripMenuItem) | Out-Null
$FileToolstripMenuItem.DropDownItems.Add($RestartComputerToolstripMenuItem) | Out-Null
$FileToolstripMenuItem.DropDownItems.Add($ToolStripSeparator) | Out-Null
$FileToolstripMenuItem.DropDownItems.Add($ExitToolstripMenuItem) | Out-Null
###End Add objects to the form. 

$form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
$form.Add_Shown({$form.Activate()})
$Form.ShowDialog()