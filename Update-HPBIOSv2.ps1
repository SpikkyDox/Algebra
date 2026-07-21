Import-Module HP.ClientManagement -ErrorAction Stop
Import-Module HP.Private -ErrorAction Stop

if (-not (Get-HPBIOSUpdates -Check)) {
    Write-Output "BIOS update needed. Flashing..."
    Get-HPBIOSUpdates -Flash -Password "Pa55w.rd" -Bitlocker Suspend -Yes
} else {
    Write-Output "No BIOS update required."
}
