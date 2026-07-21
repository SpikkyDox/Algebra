# Script: Set-CurrentOS-Default.ps1
# Run as Administrator on the management PC

$HostFile = "C:\GitHub\Hosts\ZG-A6.txt"
$Hosts = Get-Content $HostFile | Where-Object { $_ -match "^\S+" }   # take all non-empty lines

foreach ($Computer in $Hosts) {
    Write-Host "Processing $Computer ..." -ForegroundColor Cyan
    try {
        Invoke-Command -ComputerName $Computer -ScriptBlock {
            Write-Host "[$env:COMPUTERNAME] Setting default boot to current OS ({current}) ..." -ForegroundColor Cyan
            # Call bcdedit safely with explicit arguments so {current} is passed verbatim to the remote bcdedit
            Start-Process -FilePath "bcdedit.exe" -ArgumentList "" -NoNewWindow -Wait -ErrorAction Stop
            Write-Host "[$env:COMPUTERNAME] Default set to current OS." -ForegroundColor Green
        } -ErrorAction Stop
    }
    catch {
        Write-Host "Failed to process $Computer : $_" -ForegroundColor Red
    }
}
