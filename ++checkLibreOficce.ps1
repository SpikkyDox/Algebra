# Script: Check-LibreOffice.ps1
# Run as Administrator on management PC

$HostFile = "C:\GitHub\Hosts\ZG-C5.txt"
$Hosts = Get-Content $HostFile | Where-Object { $_ -match "^\S+" }   # take all non-empty lines

foreach ($Computer in $Hosts) {
    Write-Host "==== Checking $Computer ====" -ForegroundColor Cyan
    try {
        Invoke-Command -ComputerName $Computer -ScriptBlock {
            $result = [PSCustomObject]@{
                Computer   = $env:COMPUTERNAME
                Installed  = $false
                Executable = $false
                ExecPath   = $null
            }

            # Common LibreOffice install locations
            $paths = @(
                "C:\Program Files\LibreOffice\program\soffice.exe",
                "C:\Program Files (x86)\LibreOffice\program\soffice.exe"
            )

            foreach ($p in $paths) {
                if (Test-Path $p) {
                    $result.Installed  = $true
                    $result.Executable = $true
                    $result.ExecPath   = $p
                    break
                }
            }

            if (-not $result.Installed) {
                # Double-check registry uninstall keys
                $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
                $regPathWow = "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
                $keys = Get-ChildItem $regPath, $regPathWow -ErrorAction SilentlyContinue
                foreach ($k in $keys) {
                    $dispName = (Get-ItemProperty $k.PSPath -ErrorAction SilentlyContinue).DisplayName
                    if ($dispName -like "LibreOffice*") {
                        $result.Installed = $true
                        break
                    }
                }
            }

            return $result
        } -ErrorAction Stop | Format-Table -AutoSize
    }
    catch {
        Write-Host "Failed to connect to $Computer : $_" -ForegroundColor Red
    }
}
