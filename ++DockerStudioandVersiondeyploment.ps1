# Paths & settings
$computersListPath = "C:\GitHub\Hosts\partial2.txt"
$dockerInstallerRemotePath = "D:\Docker Desktop Installer.exe"
$userToAdd = "Student"
$logPath = "C:\temp\docker_setup_remote_log-deploymentv1.txt"

function Write-LocalLog {
    param ([string]$msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "$timestamp - $msg"
    Add-Content -Path $logPath -Value $logLine
    Write-Output $logLine
}

# Credentials prompt
$credential = Get-Credential -Message "Enter credentials to connect to target PCs"

# Read list
$computers = Get-Content -Path $computersListPath

foreach ($computer in $computers) {
    Write-Output "Starting setup on: $computer..."
    try {
        $result = Invoke-Command -ComputerName $computer -Credential $credential -ScriptBlock {
            param($UserToAdd, $DockerInstallerPath)

            $logs = @()

            function LogAndOutput {
                param($Message)
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $line = "$timestamp - $Message"
                $logs += $line
                Write-Output $line
            }

            # 1. Ensure 'docker-users' group exists
            try {
                if (-not (Get-LocalGroup -Name "docker-users" -ErrorAction SilentlyContinue)) {
                    New-LocalGroup -Name "docker-users" -ErrorAction Stop
                    LogAndOutput "Created 'docker-users' group."
                } else {
                    LogAndOutput "Group 'docker-users' already exists."
                }
            } catch {
                LogAndOutput "Error checking/creating group: $_"
            }

            # 2. Install MSI for WSL
            try {
                $msiPath = "D:\wsl.2.6.1.0.x64.msi"
                if (Test-Path $msiPath) {
                    LogAndOutput "Found MSI at $msiPath, installing..."
                    $msiArgs = @(
                        "/i"
                        "`"$msiPath`""
                        "/quiet"
                        "/norestart"
                    )
                    $installProc = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru
                    if ($installProc.ExitCode -eq 0) {
                        LogAndOutput "WSL MSI installed successfully."
                    } else {
                        LogAndOutput "WSL MSI install failed with code $($installProc.ExitCode)"
                    }
                } else {
                    LogAndOutput "MSI not found at $msiPath"
                }
            } catch {
                LogAndOutput "Error during MSI install: $_"
            }

            # 3. Set WSL 2 as default
            try {
                wsl --set-default-version 2
                LogAndOutput "Set WSL 2 as default."
            } catch {
                LogAndOutput "Error setting WSL default version: $_"
            }

            # 4. WSL check/update
            try {
                $wslVer = wsl --version 2>&1
                if ($wslVer -match "WSL version") {
                    LogAndOutput "WSL installed: $wslVer"
                } else {
                    LogAndOutput "WSL not properly installed, attempt manual install if MSI didn't do it."
                }
            } catch {
                LogAndOutput "Error retrieving WSL version: $_"
            }

            # 5. Install Docker
            try {
                if (Test-Path $DockerInstallerPath) {
                    LogAndOutput "Found Docker installer at $DockerInstallerPath, installing..."
                    $args = @(
                        "install"
                        "--accept-license"
                        "--backend=wsl-2"
                        "--quiet"
                        "--always-run-service"
                    )
                    $proc = Start-Process -FilePath $DockerInstallerPath -ArgumentList $args -Wait -PassThru
                    if ($proc.ExitCode -eq 0) {
                        LogAndOutput "Docker Desktop installed successfully."
                    } else {
                        LogAndOutput "Docker installer failed with exit code $($proc.ExitCode)"
                    }
                } else {
                    LogAndOutput "Docker installer not found."
                }
            } catch {
                LogAndOutput "Error installing Docker: $_"
            }

            # 6. Add user to group
            try {
                net localgroup docker-users $UserToAdd /add
                if ($LASTEXITCODE -eq 0) {
                    LogAndOutput "User $UserToAdd added to 'docker-users'."
                } else {
                    LogAndOutput "Failed to add user to group, output: $($?)"
                }
            } catch {
                LogAndOutput "Error adding user: $_"
            }

            return $logs
        } -ArgumentList $userToAdd, $dockerInstallerRemotePath -ErrorAction Stop

        # Output logs
        foreach ($line in $result) {
            Write-Output $line
            Write-LocalLog $line
        }
        Write-Output "Finished setup on: $computer."
        Write-LocalLog "Setup complete."
    } catch {
        Write-LocalLog "$computer - Error: $_"
        Write-Output "Error on ${computer}: $_"
    }
}
