# File: Deploy-HPBIOS.ps1

$pcList       = Get-Content "C:\GitHub\Hosts\ZG-D12.txt"
$scriptPath   = "C:\GitHub\Scripts\Update-HPBIOS.ps1"
$psexecPath   = "C:\Tools\PsExec.exe"
$logPath      = "C:\GitHub\Logs\BIOSUpdateLog.txt"
$remoteFolder = "C$\Temp"
$remoteScript = "C:\Temp\Update-HPBIOS.ps1"

# Ensure log directory exists
if (-not (Test-Path -Path (Split-Path $logPath))) {
    New-Item -ItemType Directory -Path (Split-Path $logPath) -Force | Out-Null
}

foreach ($pc in $pcList) {
    Write-Host "`nProcessing $pc..." -ForegroundColor Cyan

    if (Test-Connection -ComputerName $pc -Count 1 -Quiet) {
        try {
            # Ensure C:\Temp exists remotely
            New-Item -Path "\\$pc\$remoteFolder" -ItemType Directory -Force | Out-Null

            # Copy BIOS script
            Copy-Item -Path $scriptPath -Destination "\\$pc\$remoteFolder\" -Force

            # Run BIOS update as SYSTEM
            & $psexecPath -accepteula \\$pc -s -h powershell -ExecutionPolicy Bypass -File $remoteScript

            # Delete the script to avoid leaving BIOS password behind
            Remove-Item -Path "\\$pc\$remoteFolder\Update-HPBIOS.ps1" -Force

            # Optional: Reboot PC to finalize BIOS update
            & $psexecPath \\$pc -s -h shutdown -r -t 5

            # Log success
            $logLine = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $pc - BIOS update triggered and rebooted"
            Add-Content -Path $logPath -Value $logLine

            Write-Host "✔ ${pc}: BIOS update triggered and cleaned up." -ForegroundColor Green
        }
        catch {
            $errorLine = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $pc - ERROR: $_"
            Add-Content -Path $logPath -Value $errorLine
            Write-Host "❌ ${pc}: Failed - $_" -ForegroundColor Red
        }
    }
    else {
        $offlineLine = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $pc - UNREACHABLE"
        Add-Content -Path $logPath -Value $offlineLine
        Write-Host "⚠ ${pc}: Not reachable." -ForegroundColor Yellow
    }
}
