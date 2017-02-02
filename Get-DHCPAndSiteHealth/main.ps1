<#
<#
.Synopsis
   List which DNS and Subnet a specific IP is associated with.
.DESCRIPTION
   Long description
.EXAMPLE
   - Get-DHCPAndSiteHealth -DHCPServer FQDN -DHCPScopeID 192.168.0.1
   - Get-DHCPAndSiteHealth -DHCPServer NETBIOS -DHCPScopeID 192.168.0.1
   - Get-DHCPAndSiteHealth -DHCPServer 192.168.0.1 -DHCPScopeID 192.168.0.1
.EXAMPLE
    $array = "192.168.0.1", "192.168.0.2"
    $array | ForEach-Object{Get-DHCPAndSiteHealth -DHCPServer FQDN -DHCPScopeID $_}
#>


function Get-DHCPAndSiteHealth{
    [CmdletBinding()]
    param(
    [parameter(Mandatory=$true)]
    [string]$DHCPServer,

    [parameter(Mandatory=$true)]
    [string]$DHCPScopeID
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
    Write-Host "---Script Starting for scope $DHCPScopeID---" -BackgroundColor Yellow -ForegroundColor Black
    $DNS = Get-DhcpServerv4optionValue -ComputerName $DHCPServer -ScopeId $DHCPScopeID
    $DNSOfScope = $dns | ?{$_.Name -like "DNS Servers"}
    $DNSOfScope = $DNSOfScope.Value

        foreach($DNSValue in $DNSOfScope){
            Write-Host "DNS is set to $DNSValue on the scope $DHCPScopeID"
        }
    $SiteScopeID = $DHCPScopeID+"*"
    $SiteAndServices = (Get-ADReplicationSubnet -Filter{name -like $SiteScopeID}).Site

    Write-Host "Site is set to $SiteAndServices on the scope $DHCPScopeID" 
    Write-Host "---Script finnished for scope $DHCPServer" -BackgroundColor Yellow -ForegroundColor Black
}




