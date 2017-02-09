function NewDHCPScope{
    param(
    [parameter(mandatory=$true)]
    [string]$Name,
    [parameter(mandatory=$true)]
    [string]$Subnet,
    [string]$SubnetMask = "255.255.255.0",
    [string]$DHCPServer = "IP ADRESS OF DHCP_SERVER"
    )

    #Check if dhcp module is loaded
    If(Get-Module -ListAvailable -Name DHCPServer){
        #Module is loaded
    }
    else{
        Import-Module DHCPServer
    }

    #Check if AD module is loaded
    If(Get-Module -ListAvailable -Name activedirectory){
        #Module is loaded
    }
    else{
        Import-Module activedirectory
    }

    #Logik för att kolla att subnetet är korrekt inmatat.
        #Rätt format
        $CorrectedSubnet = $subnet.Substring(0, $subnet.LastIndexOf("."))
        $CorrectedSubnet = "$CorrectedSubnet.0"
        
        $repairSubnet = $Subnet
        $repairSubnet = $subnet.Split(".")

        $subnet = $CorrectedSubnet
        $splitatSubnet = $subnet.Split(".")
        
        #Laga subneten ifall man inte matar in 4st okteter. 
        if($repairSubnet.Count.Equals(3)){
            [System.Collections.ArrayList]$SubnetArrayList = $repairSubnet
            $SubnetArrayList.add("0")
            $fixedSubentArray = $SubnetArrayList[0] + "." + $SubnetArrayList[1] + "." + $SubnetArrayList[2] + "." + $SubnetArrayList[3]
            $splitatSubnet = $SubnetArrayList.Split(".")
            $Subnet = $fixedSubentArray
        }


        if($splitatSubnet.Count -notlike "4"){
            Throw "Inte 4st okteter i -Subnet. Kontrollera att det är korrekt."
        }
        else{
            #Rätt format, 4st oktokter.
            #Kollar att ingen är längre än 3st tecken. 
            foreach($oktet in $splitatSubnet){
                if($oktet.Length -gt 3){
                    Throw "$oktet är längre än 3 tecken. Kontrollera att det är korrekt."
                }
                elseif($oktet.Length.Equals(0) -eq $true){
                    Throw "Delar av -Subnet har inget värde. Kontrollera att det finns ett värde i varje oktet."
                }
            }
        }

    #Logik för att kolla om subnetet redan finns
    if((Get-DhcpServerv4Scope -ComputerName $DHCPServer -ScopeId $Subnet -ErrorAction SilentlyContinue) -eq $null){
        $substring = $Subnet.Substring(0,$subnet.Length-1)
        $gateway = "$substring"+"1"
        $startrange = "$substring"+"100"
        $endrange = "$substring"+"239"

        $confirmation = Read-host -Prompt "Följande nät kommer att läggas upp i DHCP-servern $DHCPServer stämmer alla uppgifter? [Y/N]`
        `
        Name: $Name `
        Subnet: $subnet `
        Gateway: $gateway `
        Mask: $SubnetMask `
        Answer"

            if($confirmation -eq "y"){
                Add-DhcpServerv4Scope -Name $Name -StartRange $startrange -EndRange $endrange -SubnetMask $SubnetMask -PassThru | Set-DhcpServerv4OptionValue -OptionId 3 -Value $gateway
                Set-DhcpServerv4Scope -ScopeId $Subnet -LeaseDuration(New-TimeSpan -Hours 1)# | Set-DhcpServerv4OptionValue -optionId 51 -Value 8000
                Write-Host "Scopet för enheten $name skapat!" -ForegroundColor black -BackgroundColor Yellow
                return
            }
            else{
                Write-Warning "Scriptet avslutas. Inget scope skapat."
                return
            }
        

    }
    else{
        Write-Warning "Subnetet $subnet finns redan!`nScriptet avslutas. Mata in ett subnet som inte finns upplagt."
        return
    }

}
