# Script: Fix-BootEntries.ps1
# Run as Administrator on management PC

$HostFile = "C:\GitHub\Hosts\ZG-A6.txt"
$Hosts = Get-Content $HostFile | Where-Object { $_ -match "^\S+" } 

foreach ($Computer in $Hosts) {
    Write-Host "==== Processing $Computer (Rename + Set Default) ====" -ForegroundColor Cyan
    try {
        Invoke-Command -ComputerName $Computer -ScriptBlock {

            # Get all boot entries
            $bcd = bcdedit /enum all

            # Find entry created from VHDX
            $ids = @()
            for ($i=0; $i -lt $bcd.Count; $i++) {
                if ($bcd[$i] -match "identifier\s+(\{.+\})") { $id = $Matches[1] }
                if ($bcd[$i] -match "device\s+vhd=\[F:\]\\NetworkingCoursesW11.vhdx") { $ids += $id }
            }

            foreach ($id in $ids) {
                Write-Host "[$env:COMPUTERNAME] Renaming $id to NetworkingCourses25/26 ..." -ForegroundColor Yellow
                bcdedit /set $id description "NetworkingCourses25/26"
            }

            # Restore Windows 11 as default
            $win11id = $null
            for ($i=0; $i -lt $bcd.Count; $i++) {
                if ($bcd[$i] -match "identifier\s+(\{.+\})") { $id = $Matches[1] }
                if ($bcd[$i] -match "description\s+Windows 11") { $win11id = $id; break }
            }

            if ($win11id) {
                Write-Host "[$env:COMPUTERNAME] Setting default boot to Windows 11 ($win11id) ..." -ForegroundColor Cyan
                bcdedit /default $win11id
            } else {
                Write-Host "[$env:COMPUTERNAME] WARNING: Windows 11 entry not found!" -ForegroundColor Red
            }

        } -ErrorAction Stop
    }
    catch {
        Write-Host "Failed to process $Computer : $_" -ForegroundColor Red
    }
}
