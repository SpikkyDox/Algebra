# Paths & settings
$computersListPath = "C:\GitHub\Hosts\ZG-C2-.txt"  # List of target PCs
$unityHubInstaller = "D:\UnityHubSetup.exe"
$unityEditorInstaller = "D:\UnitySetup64-2022.3.62f2.exe"
$logPath = "C:\temp\unity_install_log.txt"

function Write-LocalLog {
    param ([string]$msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logLine = "$timestamp - $msg"
    Add-Content -Path $logPath -Value $logLine
    Write-Output $logLine
}

# Prompt for credentials to connect to remote PCs (admin rights required)
$credential = Get-Credential -Message "Enter credentials to connect to target PCs"

# Read list of target computers
$computers = Get-Content -Path $computersListPath

foreach ($computer in $computers) {
    Write-LocalLog "Starting Unity install on: $computer"
    try {
        $result = Invoke-Command -ComputerName $computer -Credential $credential -ScriptBlock {
            param($UnityHubPath, $UnityEditorPath)
            $logs = @()
            function Log {
                param($message)
                $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                $line = "$ts - $message"
                $logs += $line
                Write-Output $line
            }
            
            # Install Unity Hub silently
            try {
                if (Test-Path $UnityHubPath) {
                    Log "Installing Unity Hub from $UnityHubPath..."
                    $procHub = Start-Process -FilePath $UnityHubPath -ArgumentList "/S" -Wait -PassThru
                    if ($procHub.ExitCode -eq 0) {
                        Log "Unity Hub installed successfully."
                    } else {
                        Log "Unity Hub installer failed with exit code $($procHub.ExitCode)."
                    }
                } else {
                    Log "Unity Hub installer not found at $UnityHubPath."
                }
            } catch {
                Log "Error installing Unity Hub: $_"
            }

            # Install Unity Editor silently
            try {
                if (Test-Path $UnityEditorPath) {
                    Log "Installing Unity Editor 2022.3.62f1 from $UnityEditorPath..."
                    $procEditor = Start-Process -FilePath $UnityEditorPath -ArgumentList "/S" -Wait -PassThru
                    if ($procEditor.ExitCode -eq 0) {
                        Log "Unity Editor installed successfully."
                    } else {
                        Log "Unity Editor installer failed with exit code $($procEditor.ExitCode)."
                    }
                } else {
                    Log "Unity Editor installer not found at $UnityEditorPath."
                }
            } catch {
                Log "Error installing Unity Editor: $_"
            }

            return $logs
        } -ArgumentList $unityHubInstaller, $unityEditorInstaller -ErrorAction Stop

        foreach ($line in $result) {
            Write-LocalLog "$computer - $line"
        }
        Write-LocalLog "Unity install completed on $computer."

    } catch {
        Write-LocalLog "Error on ${computer}: $_"
    }
}

