# Read hostnames from file
$hostnames = Get-Content "C:\GitHub\Hosts\ZG-A6.txt"

# Prompt for credentials
$cred = Get-Credential

foreach ($hostname in $hostnames) {
    try {
        # Create new PSSession with remote computer
        $session = New-PSSession -ComputerName $hostname -Credential $cred -ErrorAction Stop
        
        # Uninstall existing Veyon (if installed)
        Invoke-Command -Session $session -ScriptBlock {
            # Check if Veyon is installed
            if (Test-Path "C:\Program Files\Veyon\Veyon.exe") {
                # Uninstall Veyon
                Start-Process -FilePath "C:\Program Files\Veyon\uninstall.exe" -ArgumentList "/S" -Wait
            }
        } -ErrorAction Stop
        
        # Install new version of Veyon
        Invoke-Command -Session $session -ScriptBlock {
            # Run the installation command
            Start-Process -FilePath "C:\veyon-4.7.5.0-win64-setup.exe" -ArgumentList "/S" -Wait
           
            # After installation completes, interact with UAC prompt (if needed)
            # Note: Automating UAC interaction may not work reliably due to security restrictions
            
        } -ErrorAction Stop
        
        Write-Host "Installation completed on $hostname"
    } catch {
        Write-Host "Failed to install on" -ComputerName $hostname -Credential $cred
    } finally {
        # Remove PSSession
        if ($session) {
            Remove-PSSession $session
        }
    }
}
