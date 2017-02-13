
.Synopsis</br>
   David Berndtsson 2017-02-13, Data Ductus, Uppsala.</br>
   Function för att lägga till dchp-scope och lägga till subnetet i S&S.</br>
.DESCRIPTION</br>
   Detta script hanterar även felskrivningar i inmatningen. Tex: "-Subnet 192.168.10.10" kommer att konverteras till "-Subnet</br> 192.168.10.0"
.EXAMPLE</br>
   -Input: New-DHCPScope -Name "Enhet X" -Subnet 192.168.10.0 -DHCPServer Localhost</br>
   -OutPut: Kommer att lägga till "Enhet X" som ett scope med ip 192.168.10.0 på dhcp-servern localhost. Samt lägga till nätet i S&S</br>
.EXAMPLE</br>
   $array = Import-csv "C:\ListOfSubnet.csv"</br>
   $array | Foreach-object{New-DHCPScope -Name $_.Name -Subnet $_.Subnet}</br>

