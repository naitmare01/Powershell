function New-LocalUser{
<#
Creates a local user named Axians and adds it to the local administrator groups on $Computer.
#>
param(
$Computer
)

    # Create new local Admin user for script purposes
    $Computer = [ADSI]"WinNT://$Computer,Computer"

    $LocalAdmin = $Computer.Create("User", "NAME OF USER")
    $LocalAdmin.SetPassword("SecretPassword")
    $LocalAdmin.SetInfo()
    $LocalAdmin.FullName = "FULL NAME"
    $LocalAdmin.SetInfo()
    $LocalAdmin.UserFlags = 64 + 65536 # ADS_UF_PASSWD_CANT_CHANGE + ADS_UF_DONT_EXPIRE_PASSWD
    $LocalAdmin.SetInfo()
}
