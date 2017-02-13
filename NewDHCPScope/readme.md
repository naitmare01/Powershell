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
