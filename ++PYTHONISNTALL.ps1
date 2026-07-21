# 1. SETUP PATHS
$hostFilePath = "C:\GitHub\Hosts\ZG-D5.txt"
$sourcePath   = "\\ZG-AMT-01\temp\python-3.14.3-amd64.exe"

# 2. ASK FOR ADMIN CREDENTIALS ONCE
$cred = Get-Credential -UserName "Administrator" -Message "Enter Admin credentials for all remote PCs"

# 3. LOAD PC LIST
if (-not (Test-Path $hostFilePath)) { 
    Write-Host "[ERROR] Notepad file not found at: $hostFilePath" -ForegroundColor Red; exit 
}
$PCList = Get-Content $hostFilePath

foreach ($PC in $PCList) {
    Write-Host "`n>>>> Checking $PC <<<<" -ForegroundColor Cyan
    
    if (Test-Connection -ComputerName $PC -Count 1 -Quiet) {
        try {
            # REMOTE CHECK: Does ANY python exist?
            $checkResult = Invoke-Command -ComputerName $PC -Credential $cred -ScriptBlock {
                # Check 1: Is it in the PATH?
                $pyPath = Get-Command python.exe -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
                
                # Check 2: Check common 'All User' install folders if not in path
                if (-not $pyPath) {
                    $pyPath = Get-ChildItem "C:\Program Files\Python*" -Filter "python.exe" -Recurse -ErrorAction SilentlyContinue | 
                              Select-Object -First 1 -ExpandProperty FullName
                }

                if ($pyPath) {
                    $version = & $pyPath --version 2>&1
                    return "FOUND: $version at $pyPath"
                }
                return "NOT_FOUND"
            }

            if ($checkResult -ne "NOT_FOUND") {
                Write-Host "Skipping $PC. $checkResult" -ForegroundColor Green
                continue
            }

            # PROCEED TO INSTALL
            Write-Host "No Python found. Deploying installer..." -ForegroundColor Yellow
            Copy-Item -Path $sourcePath -Destination "\\$PC\C$\Windows\Temp\python-installer.exe" -Force

            Invoke-Command -ComputerName $PC -Credential $cred -ScriptBlock {
                Write-Host "Installing Python 3.14 for All Users..."
                
                # /quiet = Silent
                # InstallAllUsers=1 = Program Files (for everyone)
                # PrependPath=1 = Adds to system environment variables
                $process = Start-Process -FilePath "C:\Windows\Temp\python-installer.exe" `
                    -ArgumentList "/quiet InstallAllUsers=1 PrependPath=1 Include_test=0" `
                    -Wait -PassThru

                if ($process.ExitCode -eq 0) {
                    Write-Host "Successfully installed!" -ForegroundColor Green
                } else {
                    Write-Host "Installation failed. Exit Code: $($process.ExitCode)" -ForegroundColor Red
                }
                Remove-Item "C:\Windows\Temp\python-installer.exe" -Force
            }
        } catch {
            Write-Host "Failed to process $PC. Error: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "PC $PC is OFFLINE." -ForegroundColor Red
    }
}