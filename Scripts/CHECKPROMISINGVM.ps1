# Import the Hyper-V module
Import-Module Hyper-V

# Set the path to the file containing the list of hosts
$hostsFile = "E:\Sime\skripte\Hosts\ZG-D5.txt"

# Set the name of the virtual switch
$switchName = Get-VMSwitch -SwitchType Default -ComputerName $hostName | Select-Object -ExpandProperty Name

# Set the path to the log file
$logpath = "$env:userprofile\desktop"
$logname = "ShutdownVMLog.txt"
$logfile = Join-Path -Path $logpath -ChildPath $logname
if (-not (Test-Path $logfile)) {
    New-Item -ItemType File -Path $logfile -Force
}

# Read the list of hosts from the file
$hosts = Get-Content $hostsFile

# Loop through each host
foreach ($klijent in $hosts) {
    Write-Host "Processing host $klijent..."

    # Prompt the user to enter the name of the VM to check
    $vmName = "Win 10 - MongoDB"

    # Get the VM with the specified name
    $vm = Get-VM -ComputerName $klijent -Name $vmName

    # Check if the VM was found
    if ($vm -eq $null) {
        Write-Host "Could not find VM with name $vmName on $klijent"
        Add-Content $logFile -Value "Could not find VM with name $vmName on $klijent"
        continue
    }

    # Start the VM
    Write-Host "Starting VM $vmName on $klijent..."
    Add-Content $logFile -Value "Starting VM $vmName on $klijent..."
    Start-VM -VM $vm

    # Wait for the VM to start up
    Write-Host "Waiting for VM $vmName on $klijent to start up..."
    Add-Content $logFile -Value "Waiting for VM $vmName on $klijent to start up..."
    do {
        Start-Sleep -Seconds 30
    } until ((Get-VM -ComputerName $klijent -Name $vmName).State -eq "Running")

    # Check if the VM is connected to the specified virtual switch and has internet
    $vmNetworkAdapter = Get-VMNetworkAdapter -VM $vm
    $switch = Get-VMSwitch -Name $switchName

    if ($vmNetworkAdapter.SwitchName -eq 'Default Switch') {
        Write-Host "VM $vmName on $klijent is connected to the Default Switch"
        Add-Content $logFile -Value "VM $vmName on $klijent is connected to the Default Switch"
    } 
    else {
        Write-Host "VM $vmName on $klijent is not connected to the Default Switch"
        Add-Content $logFile -Value "VM $vmName on $klijent is not connected to the Default Switch"
        Stop-VM -VM $vm -Force
    continue
}

    if ($vmNetworkAdapter.SwitchName -ne $switchName) {
        Write-Host "VM $vmName on $klijent is not connected to the $switchName switch"
        Add-Content $logFile -Value "VM $vmName on $klijent is not connected to the $switchName switch"
        Stop-VM -VM $vm -Force
    continue
}

    if (!(Test-Connection $vmNetworkAdapter.IPAddresses[0])) {
        Write-Host "VM $vmName on $klijent does not have internet access"
        Add-Content $logFile -Value "VM $vmName on $klijent does not have internet access"
        Stop-VM -VM $vm -Force
    continue
}

    # Shut down the VM
    Write-Host "Shutting down VM $vmName on $klijent..."
    Add-Content $logFile -Value "Shutting down VM $vmName on $klijent..."
    Stop-VM -VM $vm -Force

    # Wait for the VM to shut down
    Write-Host "Waiting for VM $vmName on $klijent to shut down..."
    do {
        Start-Sleep -Seconds 60
    } until ((Get-VM -ComputerName $klijent -Name $vmName).State -eq "Off")

    Create a snapshot of the VM
    Write-Host "Creating snapshot for VM $vmName on $klijent..."
    $snapshotDescription = "All is gucci"
    New-VMSnapshot -Name $snapshotDescription -VM $vm -Description $snapshotDescription

    Write to log file
    Add-Content $logFile "$(Get-Date) - Snapshot created for VM $vmName on $klijent"
    
    Clean up the checkpoint files
    Write-Host "Cleaning up checkpoint files for VM $vmName on $klijent..."
    Get-VMSnapshot -VM $vm | Where-Object {$_.Name -ne "Current"} | Remove-VMSnapshot -Confirm:$false

    Write to log file
    Add-Content $logFile "$(Get-Date) - Checkpoint files cleaned up for VM $vmName on $klijent"

    Stop the VM and wait for it to stop
    Stop-VM -VM $vm -Force

    Write to log file
    Add-Content $logFile "$(Get-Date) - VM $vmName on $klijent has been stopped"

    Wait for the VM to stop
    Write-Host "Waiting for VM $vmName on $klijent to stop..."
    do {
    Start-Sleep -Seconds 5
    } until ((Get-VM -ComputerName $klijent -Name $vmName).State -eq "Off")

    Write to log file
    Add-Content $logFile "$(Get-Date) - VM $vmName on $klijent is stopped"

}

Write to log file
Add-Content $logFile "$(Get-Date) - Script finished"

Write-Host "Script finished"
   
