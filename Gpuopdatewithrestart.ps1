$computers = Get-Content "E:\Sime\skripte\Hosts\ZG-C1.txt\ZG-C1-09"
$jobs = Invoke-Command -ComputerName $computers -AsJob -ScriptBlock {
    Write-Host "Updating Group Policy on $($env:COMPUTERNAME) ..."
    try {
        gpupdate /force
        # Wait for 5 seconds before checking if a restart is required
        Start-Sleep -Seconds 300 
        $restartRequired = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired' -ErrorAction SilentlyContinue).'RebootRequired'
        if ($restartRequired -eq $true) {
            # Automatically confirm the prompt to restart the computer
            Restart-Computer -Force
        }
        Write-Host "Group Policy update completed on $($env:COMPUTERNAME)."
    } catch {
        Write-Host "Error updating Group Policy on $($env:COMPUTERNAME): $($_.Exception.Message)"
    }
}
# Wait for all jobs to complete
Wait-Job $jobs
# Display the output of each job
Receive-Job $jobs
