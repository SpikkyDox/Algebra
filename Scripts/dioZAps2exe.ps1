$VMNames = Get-Content E:\Sime\skripte\Hosts\ZG-C5.txt

foreach ($VMName in $VMNames) {
    Add-VMNetworkAdapter -VMName SIS -SwitchName "External network"
    Set-VMProcessor -VMName SIS -Count 3
}