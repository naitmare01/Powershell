Function Get-NetworkConfig
{
[cmdletbinding()]
param (
 [parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
    [string[]]$Name = $env:computername
)            

begin {}
process {
 foreach ($Computer in $Name) {
  if(Test-Connection -ComputerName $Computer -Count 1 -ea 0) {

   $Networks = Get-WmiObject Win32_NetworkAdapterConfiguration -ComputerName $Computer -ErrorAction SilentlyContinue -ErrorVariable Error | ? {$_.IPEnabled}
   if($Error){
   Write-Warning "Error on $computer"
   }

   foreach ($Network in $Networks) {
    $IPAddress  = $Network.IpAddress[0]
    $SubnetMask  = $Network.IPSubnet[0]
    $DefaultGateway = $Network.DefaultIPGateway
    $DNSServers  = $Network.DNSServerSearchOrder
    $IsDHCPEnabled = $false
    If($network.DHCPEnabled) {
     $IsDHCPEnabled = $true
    }
    $MACAddress  = $Network.MACAddress
    <#$OutputObj  = New-Object -Type PSObject
    $OutputObj | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Computer.ToUpper()
    $OutputObj | Add-Member -MemberType NoteProperty -Name IPAddress -Value $IPAddress
    $OutputObj | Add-Member -MemberType NoteProperty -Name SubnetMask -Value $SubnetMask
    $OutputObj | Add-Member -MemberType NoteProperty -Name Gateway -Value $DefaultGateway
    $OutputObj | Add-Member -MemberType NoteProperty -Name IsDHCPEnabled -Value $IsDHCPEnabled
    $OutputObj | Add-Member -MemberType NoteProperty -Name DNSServers -Value $DNSServers
    $OutputObj | Add-Member -MemberType NoteProperty -Name MACAddress -Value $MACAddress
    $OutputObj#>
    $export = "$Computer,$IPAddress,$SubnetMask,$DefaultGateway,$IsDHCPEnabled,$DNSServers,$MACAddress"
    $export | Out-File -Append "C:\temp\DnsQuery.csv"
   }
  }
 }
}            

end {}
}
$comps = Get-ADComputer -Filter *

foreach($item in $comps){

$item | Get-NetworkConfig 

}
