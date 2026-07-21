# ==========================
# Bulk Scheduled Task Deployment
# ==========================

$HostList = "C:\GitHub\Hosts\ZG-C3.txt"
$SourcePath = "C:\Scripts\Task scheduler"
$TargetPath = "C:\Scripts"
$TaskName = "Shutdown-Cleanup"

# Ask for credentials ONCE
$Cred = Get-Credential

# Read hosts
$Computers = Get-Content $HostList

foreach ($Computer in $Computers) {
    Write-Host "---- $Computer ----" -ForegroundColor Cyan

    try {
        # Create remote session
        $Session = New-PSSession -ComputerName $Computer -Credential $Cred -ErrorAction Stop

        # Ensure C:\Scripts exists
        Invoke-Command -Session $Session -ScriptBlock {
            if (-not (Test-Path "C:\Scripts")) {
                New-Item -Path "C:\Scripts" -ItemType Directory | Out-Null
            }
        }

        # Copy PS1
        Copy-Item `
            -Path "$SourcePath\Shutdown-Cleanup.ps1" `
            -Destination "$TargetPath\Shutdown-Cleanup.ps1" `
            -ToSession $Session `
            -Force

        # Copy XML
        Copy-Item `
            -Path "$SourcePath\Shutdown-Cleanup.xml" `
            -Destination "$TargetPath\Shutdown-Cleanup.xml" `
            -ToSession $Session `
            -Force

        # Register scheduled task
        Invoke-Command -Session $Session -ScriptBlock {
    schtasks /Create `
        /TN "Shutdown-Cleanup" `
        /XML "C:\Scripts\Shutdown-Cleanup.xml" `
        /RU "SYSTEM" `
        /F
}

        Write-Host "SUCCESS on $Computer" -ForegroundColor Green
        Remove-PSSession $Session
    }
    catch {
        Write-Host "FAILED on $Computer : $_" -ForegroundColor Red
        if ($Session) {
            Remove-PSSession $Session -ErrorAction SilentlyContinue
        }
    }
}
