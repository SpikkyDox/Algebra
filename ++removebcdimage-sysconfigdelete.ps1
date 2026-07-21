# Script: Remove-NetworkingCourses2024.ps1
# Run as Administrator on management PC

$HostFile = "C:\GitHub\Hosts\ZG-D3.txt"
$Hosts = Get-Content $HostFile | Where-Object { $_ -match "^ZG-D3-\d+" }

foreach ($Computer in $Hosts) {
    Write-Host "Processing $Computer ..." -ForegroundColor Cyan

    try {
        Invoke-Command -ComputerName $Computer -ScriptBlock {
            # Enumerate all boot entries
            $bcdOutput = bcdedit /enum all

            # More tolerant regex (matches "NetworkingCourses2024", "Networking Courses 2024", "NetowrkingCourses2024")
            $pattern = "CEH*"

            $entries = @()
            for ($i = 0; $i -lt $bcdOutput.Count; $i++) {
                if ($bcdOutput[$i] -match "identifier\s+(\{.+\})") {
                    $id = $Matches[1]
                }
                if ($bcdOutput[$i] -match "description\s+(.+)") {
                    $desc = $Matches[1]
                    if ($desc -match $pattern) {
                        $entries += $id
                    }
                }
            }

            if ($entries.Count -gt 0) {
                foreach ($id in $entries) {
                    Write-Host "  Deleting entry $id ..." -ForegroundColor Yellow
                    bcdedit /delete $id
                }
            } else {
                Write-Host "  No NetworkingCourses2024 entries found." -ForegroundColor Green
            }
        } -ErrorAction Stop
    }
    catch {
        Write-Host "  Failed to connect to $Computer : $_" -ForegroundColor Red
    }
}
