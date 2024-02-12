$computers = Get-ADComputer -Filter *
foreach ($computer in $computers) {
    Write-Host "Updating Group Policy on $($computer.Name) ..."
    Invoke-Command -ComputerName $computer.Name -ScriptBlock {
        gpupdate /force
        # Wait for 5 seconds before checking if a restart is required
        Start-Sleep -Seconds 5 
        $restartRequired = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' -ErrorAction SilentlyContinue).'RebootRequired'
        if ($restartRequired -eq $true) {
            # Automatically confirm the prompt to restart the computer
            Restart-Computer -Force
        }
    }
    Write-Host "Group Policy update completed on $($computer.Name)."
}