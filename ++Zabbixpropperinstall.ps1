# ==========================
# CONFIGURATION
# ==========================
$sourceFiles = @(
    "C:\Sime\Zabbix\zabbix_agent2.msi",
    "C:\Sime\Zabbix\zabbix_agent2.conf"
)

$remoteInstallDir = "C$\Zabbix"
$hostsFile = "C:\GitHub\test3\test.txt"

# REAL Zabbix Server / Proxy
$zabbixServerIP = "10.10.253.210"

$credential = Get-Credential

# ==========================
# READ HOSTS
# ==========================
$computers = Get-Content $hostsFile

foreach ($computer in $computers) {

    Write-Host "==== Processing $computer ====" -ForegroundColor Cyan

    try {
        $remotePath = "\\$computer\$remoteInstallDir"
        
        # Ensure directory exists
        if (!(Test-Path $remotePath)) {
            New-Item -ItemType Directory -Path $remotePath -Force | Out-Null
        }

        # Copy necessary files to remote machine
        foreach ($file in $sourceFiles) {
            Write-Host "Copying $file to $remotePath"
            Copy-Item -Path $file -Destination $remotePath -Force
        }

        Write-Host "Files copied to $computer"

        $session = New-PSSession -ComputerName $computer -Credential $credential

        # Start remote installation process
        Invoke-Command -Session $session -ArgumentList $zabbixServerIP -ScriptBlock {
            param ($serverIP)

            # Update the path to where the MSI file is located on the remote machine
            $msiPath  = "C:\Zabbix\zabbix_agent2.msi"  # Corrected path
            $confPath = "C:\Zabbix\zabbix_agent2.conf" # Corrected path
            $logFile  = "C:\Zabbix\zabbix_agent_install.log" # Log file

            # Check if MSI file exists
            if (!(Test-Path $msiPath)) {
                throw "MSI file not found at $msiPath"
            }

            Write-Host "Installing Zabbix Agent 2 on $env:COMPUTERNAME"

            # Check if Zabbix Agent 2 is already installed
            $existingAgent = Get-Service -Name "Zabbix Agent 2" -ErrorAction SilentlyContinue
            if ($existingAgent) {
                Write-Host "Zabbix Agent 2 is already installed. Restarting the service..." -ForegroundColor Yellow
                Restart-Service "Zabbix Agent 2" -Force
                return
            }

            # Install Zabbix Agent 2 using MSI
            $arguments = @(
                "/i `"$msiPath`"",
                "/qn",
                "/norestart",
                "SERVER=$serverIP",
                "SERVERACTIVE=$serverIP",
                "HOSTNAMEITEM=system.hostname",
                "/l*v $logFile"  # Log installation process
            ) -join " "

            # Run MSI install and wait for completion
            $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -PassThru

            # Check MSI installation exit code
            if ($process.ExitCode -ne 0) {
                throw "MSI install failed with exit code $($process.ExitCode). Check log file at $logFile for details."
            }

            # Copy configuration file if exists
            if (Test-Path $confPath) {
                Write-Host "Copying configuration file..."
                $agentConfTarget = "C:\Program Files\Zabbix Agent 2\zabbix_agent2.conf"
                Copy-Item $confPath $agentConfTarget -Force
            }

            # Restart Zabbix Agent 2 service
            Restart-Service "Zabbix Agent 2" -Force

            # Get service status
            Get-Service "Zabbix Agent 2" | Select-Object Status, Name, DisplayName
        }

        Remove-PSSession $session
        Write-Host "$computer completed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR on ${computer}: $_" -ForegroundColor Red
    }
}