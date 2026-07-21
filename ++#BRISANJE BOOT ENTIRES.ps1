#BRISANJE BOOT ENTIRES 

$HostFile = "C:\GitHub\Hosts\ZG-D7.txt"
$Hosts = Get-Content $HostFile | Where-Object { $_ -match "^\S+" } 

# Skip the first two PCs (ZG-C3-01, ZG-C3-02)
$Hosts = $Hosts | Where-Object { ($_ -replace '\D','') -ge 3 }

foreach ($Computer in $Hosts) {
    Write-Host "Processing $Computer ..." -ForegroundColor Cyan
    
    try {
        # Get all boot entries remotely
        $bcdOutput = Invoke-Command -ComputerName $Computer -ScriptBlock { bcdedit /enum all } -ErrorAction Stop

        # Find all identifiers with description containing "NetworkingCourses2024" variants
        $pattern = "Networking*"  # matches variations like 'Networking Courses 2024'
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
                Write-Host "  Deleting entry $id on $Computer ..." -ForegroundColor Yellow
                Invoke-Command -ComputerName $Computer -ScriptBlock { param($id) bcdedit /delete $id } -ArgumentList $id
            }
        } else {
            Write-Host "  No NetworkingCourses2024 entries found on $Computer" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "  Failed to connect to ${Computer}: $_" -ForegroundColor Red
    }
}
