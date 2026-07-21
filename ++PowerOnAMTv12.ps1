Add-Type -AssemblyName System.Windows.Forms

# Prompt user to select a host file
$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$OpenFileDialog.InitialDirectory = "C:\Bruno\EnablerByBruno\Resources\Hosts"  # Change as needed
$OpenFileDialog.Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*"
$OpenFileDialog.Title = "Select a Host File"

if ($OpenFileDialog.ShowDialog() -eq "OK") {
    $HostFilePath = $OpenFileDialog.FileName
    $Hosts = Get-Content $HostFilePath

    # Prompt for AMT credentials
    $AMTCred = Get-Credential -Message "Enter AMT credentials"

    $Operation = "PowerOn"

    switch ($Operation) {
        PowerOn {
            foreach ($PC in $Hosts) {
                Write-Host "Powering on $PC..."
                try {
                    Invoke-AMTPowerManagement -ComputerName $PC -Credential $AMTCred -Operation PowerOn
                    Write-Host "$PC powered on successfully." -ForegroundColor Green
                } catch {
                    Write-Host "Failed to power on ${PC}: $_" -ForegroundColor Red
                }
            }
        }
    }
} else {
    Write-Host "Operation cancelled by user."
}
