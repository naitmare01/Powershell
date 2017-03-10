<#
.Synopsis
   David Berndtsson 2017-02-13, Data Ductus, Uppsala.
   Function för att lägga till dchp-scope och lägga till subnetet i S&S.
.DESCRIPTION
   Detta script hanterar även felskrivningar i inmatningen. Tex: "-Subnet 192.168.10.10" kommer att konverteras till "-Subnet 192.168.10.0"
.EXAMPLE
   -Input: New-DHCPScope -Name "Enhet X" -Subnet 192.168.10.0 -DHCPServer Localhost
   -OutPut: Kommer att lägga till "Enhet X" som ett scope med ip 192.168.10.0 på dhcp-servern localhost. Samt lägga till nätet i S&S
.EXAMPLE
   $array = Import-csv "C:\ListOfSubnet.csv"
   $array | Foreach-object{New-DHCPScope -Name $_.Name -Subnet $_.Subnet}
#>
function New-DHCPScope{
    param(
    #Namnet på enheten som ska läggas till.
    [parameter(mandatory=$true)]
    [string]$Name,
    #IP-adressen på subnetet.
    [parameter(mandatory=$true)]
    [string]$Subnet,
    #Masken, kan ändras. 
    [string]$SubnetMask = "255.255.255.0",
    #DHCP-Servern. Kan ändras.
    [string]$DHCPServer = "IP Address of server",
    #Y/N om subnetet ska läggas till i S&S. Kan ändras.
    [string]$NewSiteSubnet = "Y"
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
                Add-DhcpServerv4Scope -ComputerName $DHCPServer -Name $Name -StartRange $startrange -EndRange $endrange -SubnetMask $SubnetMask -PassThru | Set-DhcpServerv4OptionValue -OptionId 3 -Value $gateway -ComputerName $DHCPServer
                Set-DhcpServerv4Scope -ScopeId $Subnet -LeaseDuration(New-TimeSpan -Hours 8)
                Write-Host "Scopet för enheten $name skapat!" -ForegroundColor black -BackgroundColor Yellow

                if($NewSiteSubnet -ne "Y"){
                    Write-Warning "Scriptet avslutas. Scope skapad men inget subnet upplagd i S&S skapat."
                    return
                }
                else{
                    Get-AdSiteSubnet
                }
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

function Get-AdSiteSubnet{
    param(
    )

        #Check if AD module is loaded
    If(Get-Module -ListAvailable -Name activedirectory){
        #Module is loaded
    }
    else{
        Import-Module activedirectory
    }

    #Globals
    $AllCurrentSites = Get-ADReplicationSite -Filter *
    $AllCurrentSitesName = $AllCurrentSites.Name
    Write-Host "Listar alla tillgängliga siter i S&S"
        for ($i = 0; $i -lt $AllCurrentSites.Count; $i++){ 
            $number = $i+1
            $sitenameChoice = $AllCurrentSites.name[$i]
            $siteNameChoice = "$sitenameChoice[$number]"
            Write-Host $siteNameChoice
        }

        [int]$ValAvSite = Read-Host -Prompt "Vilket site vill du skapa subnetet i?"

        $siffra = $AllCurrentSites.name[$ValAvSite-1]

            if($ValAvSite -in 1..$AllCurrentSites.count){
                    New-ADReplicationSubnet -Name "$Subnet/24" -Site $siffra -Description $name
                    Write-Host "Enheten $name med subnet $Subnet/24 tillagt i siten $siffra!" -ForegroundColor black -BackgroundColor Yellow
                    return
            }
            else{
            Write-Warning "Du angav inte en giltig siffra. Välj en siffra som finns på listan."
            Get-AdSiteSubnet

            }
            
}
