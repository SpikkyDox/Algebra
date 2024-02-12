# Set the path to the file containing the list of hosts
$hostFile = "E:\Sime\skripte\Hosts\ZG-C2.txt"

# Set the path to the log file and create it if it doesn't exist
$logFile = "E:\Sime\logc2.txt"
if (!(Test-Path $logFile)) {
    New-Item -ItemType File -Path $logFile
}

# Prompt the user for snapshot actions
$snapshotAction = Read-Host "Enter a snapshot action for all VMs (make, delete, or skip)"

# Loop through each host in the list
foreach ($hostName in (Get-Content $hostFile)) {
    # Get the name of the external virtual switch
    $externalSwitchName = Get-VMSwitch -SwitchType External -ComputerName $hostName | Select-Object -ExpandProperty Name

    # Get the name of the default virtual switch
    $defaultSwitchName = Get-VMSwitch -SwitchType Internal -ComputerName $hostName | Select-Object -ExpandProperty Name

    # Check if an external virtual switch was found on the host
    if (!$externalSwitchName) {
        Write-Host "No external virtual switch found on $hostName"
        Add-Content -Path $logFile -Value "$(Get-Date) - No external virtual switch found on $hostName"
        continue
    }

    # Get all running VMs on the host
    $vms = Get-VM -ComputerName $hostName | Where-Object {$_.State -eq "Running"}

    # Loop through each running VM on the host
    foreach ($vm in $vms) {
        # Check if the VM is connected to the virtual switch and has internet access
        $vmNic = Get-VMNetworkAdapter -VM $vm
        if (($vmNic.SwitchName -eq $externalSwitchName) -or ($vmNic.SwitchName -eq $defaultSwitchName)) {
            if (Test-NetConnection -ComputerName $vm.NetworkAdapters.IPAddresses[0] -Port 80) {
                Write-Host "$($vm.Name) is connected to a virtual switch and has internet access on $hostName"
                Add-Content -Path $logFile -Value "$(Get-Date) - $($vm.Name) is connected to a virtual switch and has internet access on $hostName"
            }
            else {
                Write-Host "$($vm.Name) is connected to a virtual switch but does not have internet access on $hostName"
                Add-Content -Path $logFile -Value "$(Get-Date) - $($vm.Name) is connected to a virtual switch but does not have internet access on $hostName"
            }
        }
        else {
            Write-Host "$($vm.Name) is not connected to a virtual switch on $hostName"
            Add-Content -Path $logFile -Value "$(Get-Date) - $($vm.Name) is not connected to a virtual switch on $hostName"
        }

        # Shut down the VM and wait for it to stop
        Stop-VM -VM $vm -Force
        Do {
            Start-Sleep -Seconds 10
        } while ($vm.State -ne "Off")

            # Prompt the user for snapshot actions
    $snapshotAction = Read-Host "Enter a snapshot action for $vmName on $hostName (make, delete, or skip)"

    # Perform snapshot actions based on user input
    switch ($snapshotAction) {
        "make" {
            Checkpoint-VM -VM $vm -SnapshotName "Pre-production snapshot" -Description "Pre-production environment snapshot"
            Write-Host "Snapshot created for $vmName on $hostName"
            Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Snapshot created for $vmName on $hostName"
        }
        "delete" {
            Get-VMSnapshot -VM $vm | Where-Object {$_.Name -ne "Pre-production snapshot"} | Remove-VMSnapshot
            Write-Host "Snapshots deleted for $vmName on $hostName"
            Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Snapshots deleted for $vmName on $hostName"
        }
        "skip" {
            Write-Host "No snapshot action taken for $vmName on $hostName"
            Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - No snapshot action taken for $vmName on $hostName"
        }
        default {
            Write-Host "Invalid input, skipping snapshot action for $vmName on $hostName"
            Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Invalid input, skipping snapshot action for $vmName on $hostName"
        }
    }
}
}

# Display the contents of the log file
Get-Content $logFile
