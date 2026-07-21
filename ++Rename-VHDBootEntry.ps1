# Script: Rename-VHDBootEntry.ps1
# Run as Administrator on management PC

$HostFile = "C:\GitHub\Hosts\ZG-A6.txt"
$Hosts = Get-Content $HostFile | Where-Object { $_ -match "^\S+" } 

foreach ($Computer in $Hosts) {
    Write-Host "==== Processing $Computer ====" -ForegroundColor Cyan
    try {
        Invoke-Command -ComputerName $Computer -ScriptBlock {
            # Get all boot entries
            $bcd = bcdedit /enum all

            $targetIds = @()
            for ($i = 0; $i -lt $bcd.Count; $i++) {
                if ($bcd[$i] -match "identifier\s+(\{.+\})") {
                    $id = $Matches[1]
                }
                if ($bcd[$i] -match "device\s+vhd=\[F:\]\\NetworkingCoursesW11.vhdx") {
                    $targetIds += $id
                }
            }

            if ($targetIds.Count -eq 0) {
                Write-Host "[$env:COMPUTERNAME] No VHDX boot entries found." -ForegroundColor Yellow
            } else {
                foreach ($id in $targetIds) {
                    Write-Host "[$env:COMPUTERNAME] Renaming $id to NetworkingCourses25/26 ..." -ForegroundColor Green
                    bcdedit /set $id description "NetworkingCourses25/26"
                }
            }
        } -ErrorAction Stop
    }
    catch {
        Write-Host "Failed to process $Computer : $_" -ForegroundColor Red
    }
}
