# Update-HPBIOS.ps1
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force

Import-Module HP.ClientManagement -ErrorAction Stop
Import-Module HP.Private -ErrorAction Stop

$mod = Get-Module HP.Private
if ($null -eq $mod) {
    Write-Output "HP.Private module NOT loaded!"
    exit 1
}
Write-Output "HP.Private module loaded."

if (-not (Get-HPBIOSUpdates -Check)) {
    Write-Output "BIOS update needed. Flashing now..."
    Get-HPBIOSUpdates -Flash -Password "Pa55w.rd" -Bitlocker Suspend -Yes
    Write-Output "BIOS update completed."
} else {
    Write-Output "No BIOS update required."
}
