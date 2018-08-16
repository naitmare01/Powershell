#function to test if samaccountname is free. Return TRUE(no ad-user with that sam) or FALSE(aduser sam is taken).
function Test-Samaccountname{
    [cmdletbinding()]
    param(
    [parameter(Mandatory=$true,ValueFromPipeline=$True)]
    [string]$Samaccountname
    )
        try{
            Get-aduser $samaccountname | Out-Null
            return $false
        }
        catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException]{
            return $true
        }
}

#Function generate random password.
Function Get-RandomGeneratedPassword{
    [CmdletBinding()]
    param(
        #Length of generated password
        [int]$PasswordLength = 12,
        #Number of generated password
        [int]$NumberOfPassword = 1,
        #Get a simple, less secure password
        [switch]$SimplePassword
    )#End param

    begin{
        $returnArray = [System.Collections.ArrayList]@()
        $NumberOfPassword = $NumberOfPassword - 1
        $PasswordLength = $PasswordLength - 1 
    }#End begin

    process{
        if($SimplePassword){
            $PasswordString = ([char[]]([char]48..[char]57) + [char[]]([char]65..[char]90) + [char[]]([char]97..[char]122))
        }#End if
        else{
            $PasswordString = ([char[]]([char]33..[char]95) + [char[]]([char]97..[char]126))
        }#End else

        0..$NumberOfPassword | foreach-object{
            $Password = ($PasswordString + 0..9 | sort {Get-Random})[0..$PasswordLength] -join ''
            $LastNUmber = Get-Random -Minimum 0 -Maximum 9
            $Password = "$Password$LastNUmber"
            
            $customObject = New-Object System.Object
            $customObject | Add-Member -Type NoteProperty -Name Password -Value $Password
            [void]$returnArray.add($customObject)
        }#End foreach-object
    }#End process

    end{
        return $returnArray
    }#End end

}#End function

#Function to clean string from illegal chars
function Get-CleanString{
    [cmdletbinding()]
    param(
    [parameter(Mandatory=$true,ValueFromPipeline=$True)]
    [string]$StringToClean
    )
        
    #convert to lower
    $stringToClean = $stringToClean.ToLower()

    #replace illegal chars.
    $stringToClean = $stringToClean -replace "[åÅäÄâàá]", "a"
    $stringToClean = $stringToClean -replace "[öÖôòóØ]", "o"
    $stringToClean = $stringToClean -replace "[éêëèÉ]", "e"
    $stringToClean = $stringToClean -replace "[üùúÜû]", "u"
    $stringToClean = $stringToClean -replace "[ñÑ]", "n"
    $stringToClean = $stringToClean -replace "[íìï]", "i"
    $stringToClean = $stringToClean -replace "[æÆ]", "ae"
    $stringToClean = $stringToClean -replace "[ß]", "ss"
    $stringToClean = $stringToClean -replace " ", ""
    $stringToClean = $stringToClean -replace "-", ""
    $stringToClean = $stringToClean -replace ":", ""
    $stringToClean = $stringToClean -replace "[.]", ""
    $stringToClean = $stringToClean -replace "^[\d\.]+$", ""

    return $StringToClean
    
}

#Function to generate samaccountname and password. The object returned is to be used as master data before creation
function Get-SamaccountName{
    [cmdletbinding()]
    param(
    [parameter(Mandatory=$true,ValueFromPipeline=$True)]
    [object]$User
    )#End param
    
        begin{
            $returnArray = [System.Collections.ArrayList]@()
            $samArray = [System.Collections.ArrayList]@()
        }#End begin

        process{

            foreach($u in $User){

                ###Var declartion
                $firstname = $u.GivenName
                $lastname = $u.SurName
                $telephone = $u.telefonnummer
                $mobile = $u.mobile  #Mobile and extensionattribute15
                $title = $u.title
                $department = $u.department
                $email = $u.email
                $newSam = ""
                $password = ""
                $path = $u.ou
                $company = $u.company
                $personnummer = $u.personnummer
                $oldSam = $u.oldsam

                $customObject = New-Object System.Object
                ###End var Declaration

                #Test is FirstName exist and lastname exist 
                if($firstname -like $null){
                    $firstname = "MISSING_FIRSTNAME"
    
                    ##Build and return customObject
                    $customObject | Add-Member -Type NoteProperty -Name GivenName -Value $firstname
                    $customObject | Add-Member -Type NoteProperty -Name SurName -Value $lastname
                    $customObject | Add-Member -Type NoteProperty -Name telephone -Value $telephone
                    $customObject | Add-Member -Type NoteProperty -Name mobile -Value $mobile
                    $customObject | Add-Member -Type NoteProperty -Name title -Value $title
                    $customObject | Add-Member -Type NoteProperty -Name department -Value $department
                    $customObject | Add-Member -Type NoteProperty -Name email -Value $email
                    $customObject | Add-Member -Type NoteProperty -Name newSam -Value $newSam
                    $customObject | Add-Member -Type NoteProperty -Name password -Value $password
                    $customObject | Add-Member -Type NoteProperty -Name path -Value $path
                    $customObject | Add-Member -Type NoteProperty -Name company -Value $company
                    $customObject | Add-Member -Type NoteProperty -Name personnummer -Value $personnummer
                    $customObject | Add-Member -Type NoteProperty -Name oldSam -Value $oldSam
                    [void]$returnArray.Add($customObject)
                    ##Build and return customObject
                    continue
                }
                elseif($lastname -like $null){
                    $lastname = "MISSING_LASTNAME"
                    
                    ##Build and return customObject
                    $customObject | Add-Member -Type NoteProperty -Name GivenName -Value $firstname
                    $customObject | Add-Member -Type NoteProperty -Name SurName -Value $lastname
                    $customObject | Add-Member -Type NoteProperty -Name telephone -Value $telephone
                    $customObject | Add-Member -Type NoteProperty -Name mobile -Value $mobile
                    $customObject | Add-Member -Type NoteProperty -Name title -Value $title
                    $customObject | Add-Member -Type NoteProperty -Name department -Value $department
                    $customObject | Add-Member -Type NoteProperty -Name email -Value $email
                    $customObject | Add-Member -Type NoteProperty -Name newSam -Value $newSam
                    $customObject | Add-Member -Type NoteProperty -Name password -Value $password
                    $customObject | Add-Member -Type NoteProperty -Name path -Value $path
                    $customObject | Add-Member -Type NoteProperty -Name company -Value $company
                    $customObject | Add-Member -Type NoteProperty -Name personnummer -Value $personnummer
                    $customObject | Add-Member -Type NoteProperty -Name oldSam -Value $oldSam
                    [void]$returnArray.Add($customObject)
                    ##Build and return customObject
                    continue
                }#End if/else first/lastname check

                #clean firstname and lastname from illegal chars.
                $Cleanedfirstname = Get-CleanString -StringToClean $firstname
                $Cleanedlastname = Get-CleanString -StringToClean $lastname

                #Test if firstname is smaller then 3 and lastname is longer then 5. If true add more char to lastname.
                #so we can build samAccountnameString
                if($Cleanedfirstname.length -lt 3 -and $Cleanedlastname.length -gt 5){
                    $CleanedFirtNameNumber = 3 - $Cleanedfirstname.length
                    $Cleanedfirstname = $Cleanedfirstname + $Cleanedlastname.Substring(0,$CleanedFirtNameNumber)
                    $Cleanedlastname = $Cleanedlastname.Substring($CleanedFirtNameNumber,5)
                    Write-Verbose "$Cleanedfirstname $Cleanedlastname"
                }
                elseif($Cleanedfirstname.length -gt 3 -and $Cleanedlastname.length -lt 5){
                    $CleanedLastNameNumber = 5 - $Cleanedlastname.Length
                    $CleanedlastnameNew = $Cleanedfirstname.Substring(3) #+ $Cleanedlastname
    
                        if($CleanedlastnameNew.Length -gt $CleanedLastNameNumber){
                            $Cleanedlastname = $CleanedlastnameNew.Substring(0,$CleanedLastNameNumber) + $Cleanedlastname
                        }
                        else{
                            $Cleanedlastname = $CleanedlastnameNew + $Cleanedlastname
                        }
    
                    $Cleanedfirstname = $Cleanedfirstname.Substring(0,3)
    
                }#End if($Cleanedfirstname.length -lt 3 -and $Cleanedlastname.length -gt 5)

                #Test if firstname is 3 char so we can build samAccountnameString
                if($Cleanedfirstname -eq ""){
                    Write-Verbose "Cleanded first name is null."
                    $firstname = "MISSING_FIRSTNAME"

                    ##Build and return customObject
                    $customObject | Add-Member -Type NoteProperty -Name GivenName -Value $firstname
                    $customObject | Add-Member -Type NoteProperty -Name SurName -Value $lastname
                    $customObject | Add-Member -Type NoteProperty -Name CleanedGivenName -Value $Cleanedfirstname
                    $customObject | Add-Member -Type NoteProperty -Name CleanedSurName -Value $Cleanedlastname
                    $customObject | Add-Member -Type NoteProperty -Name telephone -Value $telephone
                    $customObject | Add-Member -Type NoteProperty -Name mobile -Value $mobile
                    $customObject | Add-Member -Type NoteProperty -Name title -Value $title
                    $customObject | Add-Member -Type NoteProperty -Name department -Value $department
                    $customObject | Add-Member -Type NoteProperty -Name email -Value $email
                    $customObject | Add-Member -Type NoteProperty -Name newSam -Value $newSam
                    $customObject | Add-Member -Type NoteProperty -Name password -Value $password
                    $customObject | Add-Member -Type NoteProperty -Name path -Value $path
                    $customObject | Add-Member -Type NoteProperty -Name company -Value $company
                    $customObject | Add-Member -Type NoteProperty -Name personnummer -Value $personnummer
                    $customObject | Add-Member -Type NoteProperty -Name oldSam -Value $oldSam
                    [void]$returnArray.Add($customObject)
                    ##Build and return customObject
                    continue
                }
                elseif($Cleanedfirstname.length -eq 3){
                    Write-Verbose "$Cleanedfirstname is correct length, do nothing"
                }
                elseif($Cleanedfirstname.length -lt 3){
                    Write-Verbose "$Cleanedfirstname is too short, need to handle it."
                }
                elseif($Cleanedfirstname.length -gt 3){
                    Write-Verbose "$Cleanedfirstname is too long, need to substring it."
    
                    $Cleanedfirstname = $Cleanedfirstname.Substring(0,3)
                }
                #End Test if firstname is 3 char

                #Test if lastname is 5 char so we can build samAccountnameString
                if($Cleanedlastname -eq ""){
                    Write-Verbose "Cleanded last name is null."
                    $lastname = "MISSING_LASTNAME"

                    ##Build and return customObject
                    $customObject | Add-Member -Type NoteProperty -Name GivenName -Value $firstname
                    $customObject | Add-Member -Type NoteProperty -Name SurName -Value $lastname
                    $customObject | Add-Member -Type NoteProperty -Name CleanedGivenName -Value $Cleanedfirstname
                    $customObject | Add-Member -Type NoteProperty -Name CleanedSurName -Value $Cleanedlastname
                    $customObject | Add-Member -Type NoteProperty -Name telephone -Value $telephone
                    $customObject | Add-Member -Type NoteProperty -Name mobile -Value $mobile
                    $customObject | Add-Member -Type NoteProperty -Name title -Value $title
                    $customObject | Add-Member -Type NoteProperty -Name department -Value $department
                    $customObject | Add-Member -Type NoteProperty -Name email -Value $email
                    $customObject | Add-Member -Type NoteProperty -Name newSam -Value $newSam
                    $customObject | Add-Member -Type NoteProperty -Name password -Value $password
                    $customObject | Add-Member -Type NoteProperty -Name path -Value $path
                    $customObject | Add-Member -Type NoteProperty -Name company -Value $company
                    $customObject | Add-Member -Type NoteProperty -Name personnummer -Value $personnummer
                    $customObject | Add-Member -Type NoteProperty -Name oldSam -Value $oldSam
                    [void]$returnArray.Add($customObject)
                    ##Build and return customObject
                    continue
                }
                elseif($Cleanedlastname.length -eq 5){
                    Write-Verbose "$Cleanedlastname is correct length, do nothing"
                }
                elseif($Cleanedlastname.length -lt 5){
                    Write-Verbose "$Cleanedlastname is to short, need to handle it."
                }
                elseif($Cleanedlastname.length -gt 5){
                    Write-Verbose "$Cleanedlastname is to long, need to substring it."
    
                    $Cleanedlastname = $Cleanedlastname.Substring(0,5)
                }
                #End Test if lastname is 5 char

                ##Build new SAMAccountName
                $NewSam = "$Cleanedfirstname$Cleanedlastname"

                #Test if Newsam is already correct or if its taken. 
                if((Test-Samaccountname -Samaccountname $NewSam) -and (($samArray -contains $NewSam) -eq $false)){
                    Write-Verbose "True, samaccount $newsam is free"
                    [void]$samArray.Add($NewSam)
                }
                else{
                    Write-Verbose "False, samaccount is not free"
    
                    $NewSamWithoutLastChar = $NewSam.Substring(0,$NewSam.length-1)
                        
                        #While-loop to generate samaccountname with numbers appended
                        [int]$i = 1
                        $samArrayTest = $samArray -contains "$NewSamWithoutLastChar$i"
                        while((!(Test-Samaccountname -Samaccountname $NewSamWithoutLastChar$i)) -or !($samArrayTest -eq $false)){
                            if(($i -gt 8) -and ($i -lt 98)){
                                $i = $i + 1
                                $NewSamWithoutLastChar = $NewSam.Substring(0,$NewSam.length-2)
                            }
                            elseif($i -ge 99){
                                Write-Verbose "Cant handle over 100."
                                return
                            }
                            else{
                                $i = $i + 1
                            }
    
                            Write-Verbose $i
                            $samArrayTest = $samArray -contains "$NewSamWithoutLastChar$i" 
                            
                        }#End while(!(Test-Samaccountname -Samaccountname $NewSamWithoutLastChar$i))
    
                        [void]$samArray.Add("$NewSamWithoutLastChar$i")
                        $NewSam = "$NewSamWithoutLastChar$i"
                        Write-Verbose $NewSam
    
                }#End if($NewSam -eq $CurrentSam)

                #Generate password
                $Password = (Get-RandomGeneratedPassword -SimplePassword).password

                ##Build and return customObject
                $customObject | Add-Member -Type NoteProperty -Name GivenName -Value $firstname
                $customObject | Add-Member -Type NoteProperty -Name SurName -Value $lastname
                $customObject | Add-Member -Type NoteProperty -Name CleanedGivenName -Value $Cleanedfirstname
                $customObject | Add-Member -Type NoteProperty -Name CleanedSurName -Value $Cleanedlastname
                $customObject | Add-Member -Type NoteProperty -Name telephone -Value $telephone
                $customObject | Add-Member -Type NoteProperty -Name mobile -Value $mobile
                $customObject | Add-Member -Type NoteProperty -Name title -Value $title
                $customObject | Add-Member -Type NoteProperty -Name department -Value $department
                $customObject | Add-Member -Type NoteProperty -Name email -Value $email
                $customObject | Add-Member -Type NoteProperty -Name newSam -Value $newSam
                $customObject | Add-Member -Type NoteProperty -Name password -Value $password
                $customObject | Add-Member -Type NoteProperty -Name path -Value $path
                $customObject | Add-Member -Type NoteProperty -Name company -Value $company
                $customObject | Add-Member -Type NoteProperty -Name personnummer -Value $personnummer
                $customObject | Add-Member -Type NoteProperty -Name oldSam -Value $oldSam
                [void]$returnArray.Add($customObject)
                ##Build and return customObject

            }#End foreach

        }#End process

        end{
            return $returnArray
        }#End end

}#End funtion
#Function to add the users to the PKUE-Groups
function Add-AdUserToPKUEGroup{
    [cmdletbinding()]
    param(
    #Object from the function Get-SamaccountName
    [parameter(Mandatory=$true,ValueFromPipeline=$True)]
    [Object]$GeneratedUsers
    )#End param

    begin{
        $returnArray = [System.Collections.ArrayList]@()
    }#End begin

    process{
        foreach($G in $GeneratedUsers){
            #Var declaration
            $enhet = $g.path.Split(',')[1] -replace "OU="
            $stdAllaGroup =  "G.Std.$enhet.Alla"
            $usrgroup = "G.Usr.$enhet.StdNoMailbox"
            $Sam = $G.Newsam
            #End var declaration
            Write-Verbose $stdAllaGroup
            Write-Verbose $usrgroup
            Write-Verbose $Sam

            try{
                Add-ADGroupMember -Identity $stdAllaGroup -Members $Sam -ErrorAction Stop
                Add-ADGroupMember -Identity $usrgroup -Members $Sam -ErrorAction Stop
            }#end try
            catch{
                Write-Warning "Could nog add $Sam to the PKUE-Groups"
            }#End catch

        }#End foreach
    }#End process

    end{
        return $returnArray
    }#End end
}#End function
#Function to create the PKUE-users
function New-PKUEUser{
    [cmdletbinding()]
    param(
    #Object from the function Get-SamaccountName
    [parameter(Mandatory=$true,ValueFromPipeline=$True)]
    [Object]$GeneratedUsers
    )#End param

    begin{
        $returnArray = [System.Collections.ArrayList]@()
    }#End begin

    process{
        foreach($G in $GeneratedUsers){
            #Var declaration
            $UserDN = "Cn=" + $G.GivenName + " " + $G.SurName + "," + $G.path
            $displayname = $G.GivenName + " " + $G.SurName
            $Initial = $null
            $NewUniqueSam = $G.Newsam
            #End var declaration

            #Hande unique DistinguishedName
            <#
            Try{
                Get-ADUser $UserDN -ErrorAction stop | Out-Null
                Write-Warning "User with DN: $UserDN already exist. Need to add initial to Displayname"
                $Range = 65..90
                foreach($r in $Range){
                    $Initial = [char]$r
                    $UserDN = "Cn=" + $G.GivenName + " " + $Initial + ". " + $G.SurName + "," + $G.path
                    try{
                        Get-AdUser $UserDN -ErrorAction Stop | Out-Null
                    }#End try
                    catch{
                        Write-Verbose "$UserDN is free, note the added initial"
                        $displayname = $G.GivenName + " $Initial. " + $G.SurName
                        break
                    }#End catch
                }#End foreach-object                
            }#End Try
            catch{
                Write-Verbose "$UserDN is free and not changed."
            }#End catch
            #>
            #End hande unique DistinguishedName

            #Mark duplicate UPNs as Not created. 
            try{
                $null = Get-AdUser $UserDN -ErrorAction Stop
                $NewUniqueSam = "NOT CREATED"
            }#End try
            catch{
                try{
                    New-AdUser -AccountPassword (ConvertTo-SecureString $G.password -AsPlainText -Force) `
                    -Company $G.company `
                    -Name $displayname `
                    -DisplayName $displayname `
                    -GivenName $G.GivenName `
                    -SamAccountName $G.newSam `
                    -Surname $G.SurName `
                    -UserPrincipalName ($G.newSam + "@svenskakyrkan.se") `
                    -Path $G.path
    
                }#end try
                catch{
                    Write-Warning "$UserDN could not be created"
                }#End catch
    
                if($G.email){
                    Set-Aduser -Identity $G.NewSam -EmailAddress $G.email
                }#End if
    
                if($Initial){
                    Set-Aduser -Identity $G.NewSam -Initial $Initial
                }#End if
    
                if($G.Mobile){
                    $CleanedMobile = $g.Mobile -replace "-"
                    Set-ADUser -Identity $G.NewSam -MobilePhone $CleanedMobile
                    Set-Aduser -Identity $G.newSam -replace @{Extensionattribute15=$CleanedMobile}
                }#End If
    
                if($G.title){
                    Set-ADUser -Identity $G.NewSam -Title $G.title
                }#End if
    
                if($G.Department){
                    Set-ADUser -Identity $G.NewSam -Department $G.Department
                }#End if
    
                if($G.telephone){
                    Set-Aduser -Identity $G.newSam -replace @{telephoneNumber=$G.telephone}
                }#End if
            }#End Catch
            #End Mark duplicate UPNs as Not created. 
            
            $customObject = New-Object System.Object
            $customObject | Add-Member -Type NoteProperty -Name GivenName -Value $G.GivenName
            $customObject | Add-Member -Type NoteProperty -Name SurName -Value $G.SurName
            $customObject | Add-Member -Type NoteProperty -Name displayname -Value $displayname
            $customObject | Add-Member -Type NoteProperty -Name Initial -Value $Initial
            $customObject | Add-Member -Type NoteProperty -Name CleanedGivenName -Value $G.CleanedGivenName
            $customObject | Add-Member -Type NoteProperty -Name CleanedSurName -Value $G.CleanedSurName
            $customObject | Add-Member -Type NoteProperty -Name telephone -Value $G.telephone
            $customObject | Add-Member -Type NoteProperty -Name mobile -Value $CleanedMobile
            $customObject | Add-Member -Type NoteProperty -Name title -Value $G.title
            $customObject | Add-Member -Type NoteProperty -Name department -Value $G.department
            $customObject | Add-Member -Type NoteProperty -Name email -Value $G.email
            $customObject | Add-Member -Type NoteProperty -Name newSam -Value $NewUniqueSam
            $customObject | Add-Member -Type NoteProperty -Name password -Value $G.password
            $customObject | Add-Member -Type NoteProperty -Name path -Value $G.path
            $customObject | Add-Member -Type NoteProperty -Name company -Value $G.company
            $customObject | Add-Member -Type NoteProperty -Name personnummer -Value $G.personnummer
            $customObject | Add-Member -Type NoteProperty -Name oldSam -Value $G.oldSam
            [void]$returnArray.add($customObject)

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
        #$form.MaximizeBox = $false 
        $Form.StartPosition = "CenterScreen" 
        $Form.FormBorderStyle = 'Sizable' 
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
Function New-WindowsFormsOpenFileDialog{
    [CmdletBinding()]
    param(
        #Text
        [string]$Filter = 'csv (*.csv)|*.csv'
    )#End param

    begin{

    }#End begin

    process{
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        $OpenFileDialog.Multiselect = $false
        $OpenFileDialog.Filter = $Filter
        $OpenFileDialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
    }#End process

    end{
        $OpenFileDialog
    }#end end
}#End function
Function New-WindowsFormsDataGridVIew{
    [CmdletBinding()]
    param(
        #Location
        $Location,
        $Size
    )#End param

    begin{

    }#End begin

    process{
        $DataGridVIew = New-Object System.Windows.Forms.DataGridVIew
        $DataGridVIew.Size = New-Object System.Drawing.Size($Size)
        $DataGridVIew.Location = New-Object System.Drawing.Size($Location)
        $DataGridVIew.AllowUserToAddRows = $False
        $DataGridVIew.RowHeadersVisible = $False
        $DataGridView.Readonly = $True
    }#End process

    end{
        $DataGridVIew
    }#end end
}#End function
function ConvertTo-DataTable{
 <#
 .EXAMPLE
 $DataTable = ConvertTo-DataTable $Source
 .PARAMETER Source
 An array that needs converted to a DataTable object
 #>
[CmdLetBinding(DefaultParameterSetName="None")]
param(
 [Parameter(Position=0,Mandatory=$true)][System.Array]$Source,
 [Parameter(Position=1,ParameterSetName='Like')][String]$Match=".+",
 [Parameter(Position=2,ParameterSetName='NotLike')][String]$NotMatch=".+"
)
    if ($NotMatch -eq ".+"){
        $Columns = $Source[0] | Select-Object * | Get-Member -MemberType NoteProperty | Where-Object {$_.Name -match "($Match)"}
    }#end if
    else{
        $Columns = $Source[0] | Select-Object * | Get-Member -MemberType NoteProperty | Where-Object {$_.Name -notmatch "($NotMatch)"}
    }#end else
    $DataTable = New-Object System.Data.DataTable
    foreach ($Column in $Columns.Name){
        $DataTable.Columns.Add("$($Column)") | Out-Null
    }#End foreach
    #For each row (entry) in source, build row and add to DataTable.
    foreach ($Entry in $Source){
        $Row = $DataTable.NewRow()
        foreach ($Column in $Columns.Name){
            $Row["$($Column)"] = if($Entry.$Column -ne $null){($Entry | Select-Object -ExpandProperty $Column) -join ', '}else{$null}
        }#End foreach
        $DataTable.Rows.Add($Row)
    }#End foreach
        #Validate source column and row count to DataTable
        if ($Columns.Count -ne $DataTable.Columns.Count){
            throw "Conversion failed: Number of columns in source does not match data table number of columns"
        }#end if
    else{ 
        if($Source.Count -ne $DataTable.Rows.Count){
            throw "Conversion failed: Source row count not equal to data table row count"
        }#End if
    #The use of "Return ," ensures the output from function is of the same data type; otherwise it's returned as an array.
        else{
            Return ,$DataTable
        }#End else
    }#End else
}#End function
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
function Export-DGV2CSV ([Windows.Forms.DataGridView] $grid, [String] $File){
  if ($grid.RowCount -eq 0) { return } # nothing to do
  
  $sw  = new-object System.IO.StreamWriter($File)
        
  # write header line
  $sw.WriteLine( ($grid.Columns | foreach-object{ $_.HeaderText } ) -join ',' )

  # dump values
  $grid.Rows | foreach-object {
    $sw.WriteLine(
      ($_.Cells | foreach-object { $_.Value }) -join ','
      )
    }
  $sw.Close()
}#End function
function Export-TemplateCsv{
    [cmdletbinding()]
    param(
        $Path
    )#End param

    begin{}#End begin

    process{
        $customObject = New-Object System.Object
        $customObject | Add-Member -Type NoteProperty -Name GivenName -Value "Förnamn"
        $customObject | Add-Member -Type NoteProperty -Name SurName -Value "Efternamn"
        $customObject | Add-Member -Type NoteProperty -Name telefonnummer -Value "018-123456"
        $customObject | Add-Member -Type NoteProperty -Name mobile -Value "0701231239"
        $customObject | Add-Member -Type NoteProperty -Name title -Value "Titel"
        $customObject | Add-Member -Type NoteProperty -Name department -Value "Avdelning"
        $customObject | Add-Member -Type NoteProperty -Name email -Value "epost@epost.se"
        $customObject | Add-Member -Type NoteProperty -Name ou -Value "OU=Anvandarkonton,OU=Dataductus,OU=STIFT_Leverantor_stift,OU=Users,OU=ASP,DC=knet,DC=ad,DC=svenskakyrkan,DC=se"
        $customObject | Add-Member -Type NoteProperty -Name company -Value "Företag"
        $customObject | Add-Member -Type NoteProperty -Name personnummer -Value "12345678901234"
        $customObject | Add-Member -Type NoteProperty -Name oldSam -Value "tidigare samaccountName"
    }#End process

    end{
        $customObject | Export-Csv $Path -NoTypeInformation -Encoding UTF8
    }#End end
}#End function

#This script relies on the module activedirectory to run.
Import-Module activedirectory
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")  
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") 
[void] [System.Windows.Forms.Application]::EnableVisualStyles() 
Add-Type -AssemblyName PresentationFramework


###Build basic forms
$Form = New-WindowsForms -Text "New PKUE Users" -Size (1280,720)
$Menustrip = New-WindowsFormsMenuStrip
###End Build basic forms

###Create objects. 
$CsvDialog = New-WindowsFormsOpenFileDialog
$OkCsvButton = New-WindowsFormsButton -Text "Import" -Location (570,35) -Size (70,25)
$SelectAllButton = New-WindowsFormsButton -Text "Select All" -Location (30,475) -Size (100,25)
$DeSelectAllButton = New-WindowsFormsButton -Text "Deselect All" -Location (130,475) -Size (100,25)
$GenerateSamButton = New-WindowsFormsButton -Text "Generate data" -Location (30,500) -Size (200,25)
$CreateUsersButton = New-WindowsFormsButton -Text "Create Users" -Location (30,525) -Size (200,25)
$AddAdGroupsButton = New-WindowsFormsButton -Text "Add to AD-Groups" -Location (30,550) -Size (200,25)
$ExportGridButton = New-WindowsFormsButton -Text "Export csv" -Location (30,575) -Size (200,25)
$BrowseCsvLabel = New-WindowsFormsLabel -Text "Browse input csv file" -Location (20,35)
$BrowseCsvTextBox = New-WindowsFormsTextbox -Location (165, 35) -Size (400,25)
$DataGridView = New-WindowsFormsDataGridVIew -Location (30,65) -Size (610,400)
$FileToolstripMenuItem = New-WindowsFormsToolStripMenuItem -Text "File"
$ExportCsvToolstripMenuItem = New-WindowsFormsToolStripMenuItem -Text "Export Template Csv"
$ImportCsvToolstripMenuItem = New-WindowsFormsToolStripMenuItem -Text "Open Csv..."
###End Create objects. 

###Logic for objects
$OkCsvButton.Add_Click({
    if($BrowseCsvTextBox.Text){
        $DataGridView.DataSource = $null

        $data = Import-Csv $BrowseCsvTextBox.Text -Delimiter ";"
        $dt = Convertto-DataTable -Source $data

        $DataGridView.DataSource = $dt
    }
})

$SelectAllButton.Add_Click({
    $Messageboxbody = "Function not yet implemented."
                
    $ButtonType = [System.Windows.MessageBoxButton]::Ok
    $MessageboxTitle = "Warning"
    $MessageIcon = [System.Windows.MessageBoxImage]::Error
    [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
})

$DeSelectAllButton.Add_Click({
    $Messageboxbody = "Function not yet implemented."
                
    $ButtonType = [System.Windows.MessageBoxButton]::Ok
    $MessageboxTitle = "Warning"
    $MessageIcon = [System.Windows.MessageBoxImage]::Error
    [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
})

$GenerateSamButton.Add_Click({
    if($BrowseCsvTextBox.Text){
        $DataGridView.DataSource = $null

        $data = Import-Csv $BrowseCsvTextBox.Text -Delimiter ";"
        $data = $data | Get-SamaccountName
        $dt = Convertto-DataTable -Source $data
        $DataGridView.DataSource = $dt

        $Messageboxbody = "Username and password generated. Proceed to create the accounts in AD"
                
        $ButtonType = [System.Windows.MessageBoxButton]::Ok
        $MessageboxTitle = "Information"
        $MessageIcon = [System.Windows.MessageBoxImage]::Information
        [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
    }#End if
    else{
        $Messageboxbody = "Csv not imported. Import csv and try again."
                
        $ButtonType = [System.Windows.MessageBoxButton]::Ok
        $MessageboxTitle = "Warning"
        $MessageIcon = [System.Windows.MessageBoxImage]::Error
        [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
    }#End else
})

$ImportCsvToolstripMenuItem.Add_Click({
    $CsvDialog.ShowDialog()
    $BrowseCsvTextBox.Text = $CsvDialog.FileNames
})

$ExportCsvToolstripMenuItem.Add_Click({
    $CsvPath = [Environment]::GetFolderPath('Desktop') + "\Export_" + (Get-date -UFormat "%Y%m%d%H%M%S") + ".csv"
    $Messageboxbody = "Do you want to export template csv to $CsvPath"
                
    $ButtonType = [System.Windows.MessageBoxButton]::YesNoCancel
    $MessageboxTitle = "Export template"
    $MessageIcon = [System.Windows.MessageBoxImage]::Warning
    $MessageBox = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

    if($Messagebox -like "Yes"){
        Export-TemplateCsv -Path $CsvPath

        $Messageboxbody = "Template has been exported to $CsvPath."
                
        $ButtonType = [System.Windows.MessageBoxButton]::Ok
        $MessageboxTitle = "Information"
        $MessageIcon = [System.Windows.MessageBoxImage]::Information
        [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
    }#End if
})

$CreateUsersButton.Add_Click({
    if($BrowseCsvTextBox.Text){
        $Messageboxbody = "Are you sure you want to create the users listed in the grid?"
                
        $ButtonType = [System.Windows.MessageBoxButton]::YesNoCancel
        $MessageboxTitle = "Create users"
        $MessageIcon = [System.Windows.MessageBoxImage]::Warning
        $MessageBox = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

        if($Messagebox -like "Yes"){
            $data = Import-Csv $BrowseCsvTextBox.Text -Delimiter ";"
            $Gendata = $data | Get-SamaccountName

            $global:NewUsers = New-PKUEUser -GeneratedUsers $Gendata

            $DataGridView.DataSource = $null
            $dt = Convertto-DataTable -Source $NewUsers
            $DataGridView.DataSource = $dt

            $Numberofusers = ($data | Measure-Object).Count
            $Messageboxbody = "$Numberofusers users has now been created."
                
            $ButtonType = [System.Windows.MessageBoxButton]::Ok
            $MessageboxTitle = "Information"
            $MessageIcon = [System.Windows.MessageBoxImage]::Information
            [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

        }#End if
    }#End if
    else{
        $Messageboxbody = "Csv not imported. Import csv and try again."
                
        $ButtonType = [System.Windows.MessageBoxButton]::Ok
        $MessageboxTitle = "Warning"
        $MessageIcon = [System.Windows.MessageBoxImage]::Error
        [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
    }#End else
})

$ExportGridButton.Add_Click({
    if($BrowseCsvTextBox.Text){
        $CsvPath = [Environment]::GetFolderPath('Desktop') + "\Export_" + (Get-date -UFormat "%Y%m%d%H%M%S") + ".csv"
        $Messageboxbody = "Do you want to export the result to an csv-file to $CsvPath ?"
                
        $ButtonType = [System.Windows.MessageBoxButton]::YesNoCancel
        $MessageboxTitle = "Create users"
        $MessageIcon = [System.Windows.MessageBoxImage]::Warning
        $MessageBox = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

        if($MessageBox -like "Yes"){
            Export-DGV2CSV -grid $DataGridView -File $CsvPath

            $Messageboxbody = "Csv has now been exported to $CsvPath."
                
            $ButtonType = [System.Windows.MessageBoxButton]::Ok
            $MessageboxTitle = "Csv Export"
            $MessageIcon = [System.Windows.MessageBoxImage]::Information
            [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
        }
    }#End if
    else{
        $Messageboxbody = "Csv not imported. Import csv and try again."
                
        $ButtonType = [System.Windows.MessageBoxButton]::Ok
        $MessageboxTitle = "Warning"
        $MessageIcon = [System.Windows.MessageBoxImage]::Error
        [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
    }#End else
})

$AddAdGroupsButton.Add_Click({
    $Messageboxbody = "Are you sure you want to add the users to 'PKUE-AD-Groups'."
                
    $ButtonType = [System.Windows.MessageBoxButton]::YesNoCancel
    $MessageboxTitle = "Information"
    $MessageIcon = [System.Windows.MessageBoxImage]::Information
    $Messagebox = [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)

    if($Messagebox -like "Yes"){
        $data = Import-Csv $BrowseCsvTextBox.Text -Delimiter ";"
        #$Gendata = $data | Get-SamaccountName

        Add-AdUserToPKUEGroup -GeneratedUsers $NewUsers

        $Numberofusers = ($data | Measure-Object).Count
        $Messageboxbody = "$Numberofusers users has now been 'PKUE-AD-Groups'."
            
        $ButtonType = [System.Windows.MessageBoxButton]::Ok
        $MessageboxTitle = "Information"
        $MessageIcon = [System.Windows.MessageBoxImage]::Information
        [System.Windows.MessageBox]::Show($Messageboxbody,$MessageboxTitle,$ButtonType,$messageicon)
    }#End if
})

###End Logic for objects

###Add objects to the form. 
$Form.Controls.Add($OkCsvButton)
$Form.Controls.Add($BrowseCsvLabel)
$Form.Controls.Add($BrowseCsvTextBox)
$Form.Controls.Add($DataGridView)
$Form.Controls.Add($Menustrip)
$Form.Controls.Add($SelectAllButton)
$Form.Controls.Add($DeSelectAllButton)
$Form.Controls.Add($GenerateSamButton)
$Form.Controls.Add($CreateUsersButton)
$Form.Controls.Add($ExportGridButton)
$Form.Controls.Add($AddAdGroupsButton)
[void]$Menustrip.Items.Add($FileToolstripMenuItem)
[void]$FileToolstripMenuItem.DropDownItems.Add($ExportCsvToolstripMenuItem)
[void]$FileToolstripMenuItem.DropDownItems.Add($ImportCsvToolstripMenuItem)
###End Add objects to the form. 

###Initialize the form
$form.Add_Shown({$form.Activate()})
$Form.ShowDialog()
###End ###Initialize the form