# FULL AUTO SCRIPT - BULLETPROOF FOR 1,0,0 DEVICES
param(
    [string]$MeshDir = "C:\meshcentral2\node_modules\meshcentral",
    [string]$LogDir = "C:\GitHub\Logs",
    [string]$MeshUrl = "wss://zg-amt-01:444",
    [string]$User = "admin",
    [string]$Pass = "D0br1D3ck1!"
)

# Ensure log directory exists
if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# Step 1: Navigate + run meshctrl
Push-Location $MeshDir
Write-Host "🚀 Running meshctrl in $MeshDir..." -ForegroundColor Cyan

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$outputFile = Join-Path $LogDir "meshctrl_output_$timestamp.txt"

$fullOutput = & node meshctrl listdevices --url $MeshUrl --loginuser $User --loginpass $Pass 2>&1
$fullOutput | Out-File $outputFile -Encoding UTF8

Write-Host "✅ Full output saved to $outputFile" -ForegroundColor Green

# Step 2: Parse 1,0,0 devices
$badHosts = @()
$currentGroup = ""

Get-Content $outputFile | ForEach-Object {
    $line = $_.Trim()

    # Detect group headers
    if ($line -match "(?i)Device group[:\s]*['`"]?([^-`']+)['`"]?\s*(id|$)") {
        $currentGroup = $matches[1].Trim()
        return
    }

    # Skip empty lines or table headers
    if ([string]::IsNullOrWhiteSpace($line) -or $line -match "(id|name|icon|conn|pwr|---)") {
        return
    }

    # FLEXIBLE catch-all 1,0,0 devices
    if ($line -match '"([^"]+)"\s*,\s*"([^"]+)"\s*,.*1\s*,\s*0\s*,\s*0\s*$') {
        $id = $matches[1]
        $ip = $matches[2]

        if ($ip -match '\d+\.\d+\.\d+\.\d+') {
            $groupName = if ($currentGroup) { $currentGroup } else { "UNKNOWN" }

            $badHosts += [PSCustomObject]@{
                Group  = $groupName
                ID     = $id
                IP     = $ip
                Status = "1,0,0 (AGENT OK/PWR OFF)"
            }
        }
    }
}


Pop-Location  # back to original dir

# Step 3: Display and save results
Write-Host "`n🔥 === 1,0,0 HOSTS ($($badHosts.Count)) ===" -ForegroundColor Red -BackgroundColor Black

if ($badHosts.Count -gt 0) {
    $badHosts | Sort-Object Group, IP | Format-Table -AutoSize

    $csvName = Join-Path $LogDir "Broken_1-0-0_$timestamp.csv"
    $ipsName = Join-Path $LogDir "1-0-0_IPs_$timestamp.txt"

    $badHosts | Export-Csv $csvName -NoTypeInformation
    $badHosts.IP | Out-File $ipsName

    Write-Host "`n📁 Saved to logs:" -ForegroundColor Yellow
    Write-Host "  CSV: $csvName"
    Write-Host "  IPs: $ipsName (for AMT script)"
    Write-Host "  Full log: $outputFile"

} else {
    Write-Host "✅ No 1,0,0 hosts detected (all powered ON)" -ForegroundColor Green
}

Write-Host "`n🎯 IPs ready in $LogDir for AMT power-on!" -ForegroundColor Magenta
Exit 0