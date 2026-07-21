# Define paths
$pcs = Get-Content "C:\GitHub\Hosts\ZG-C3.txt"
$psexec = "C:\Tools\PsExec.exe"
$cmslExe = "hp-cmsl-1.8.2.exe"
$logoFile = "Logo.jpeg"
$cmslLocal = "C:\GitHub\Resources\$cmslExe"
$logoLocal = "C:\Bruno\HPCmsl\Resources\$logoFile"

# Pre-checks
if (-not (Test-Path $psexec)) {
    Write-Error "❌ PsExec.exe not found at $psexec"
    exit 1
}
if (-not (Test-Path $cmslLocal)) {
    Write-Error "❌ CMSL installer not found at $cmslLocal"
    exit 1
}
if (-not (Test-Path $logoLocal)) {
    Write-Error "❌ Logo file not found at $logoLocal"
    exit 1
}

foreach ($pc in $pcs) {
    Write-Host "`n▶️ Processing $pc..." -ForegroundColor Cyan

    try {
        # Copy files to remote machine
        Copy-Item $cmslLocal "\\$pc\D$\" -Force -ErrorAction Stop
        Copy-Item $logoLocal "\\$pc\D$\" -Force -ErrorAction Stop
        Write-Host "📁 Files copied to \\$pc\D$\" -ForegroundColor Gray

        # Define command list
        $commands = @(
    @{ desc = "Installing CMSL"; cmd = @("D:\$cmslExe", "/VERYSILENT", "/NORESTART") },
    @{ desc = "Setting ExecutionPolicy"; cmd = @("powershell.exe", "-Command", "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force") },
    @{ desc = "Applying boot logo"; cmd = @("powershell.exe", "-Command", "Set-HPFirmwareBootLogo -File 'D:\$logoFile' -Password 'Pa55w.rd'") }
)

        foreach ($c in $commands) {
    $result = & $psexec -accepteula -nobanner -s \\$pc @($c.cmd) 2>&1

    if ($LASTEXITCODE -eq 0) {
        Write-Host "✔️ $($c.desc) succeeded on $pc" -ForegroundColor Green
    } else {
        Write-Warning "❌ $($c.desc) failed on $pc (ExitCode: $LASTEXITCODE)"
        Write-Host $result
    }
}
    }
    catch {
        Write-Warning "❌ General error processing ${pc}: $_"
    }
}
