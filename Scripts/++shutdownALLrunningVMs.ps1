# Specify the path to the text file containing hostnames
$hostnamesFile = "E:\Sime\skripte\Hosts\ZG-D8.txt"

# Read hostnames from the text file
$hostnames = Get-Content -Path $hostnamesFile

# Loop through each hostname
foreach ($hostname in $hostnames) {
    Write-Host "Shutting down VMs on $hostname"
    
    # Connect to the Hyper-V host
    $connection = Connect-VIServer -Server $hostname
    
    if ($connection) {
        try {
            # Get running VMs on the host
            $runningVMs = Get-VM | Where-Object { $_.State -eq "Running" }
            
            if ($runningVMs) {
                foreach ($vm in $runningVMs) {
                    # Shut down each running VM
                    Write-Host "Shutting down VM $($vm.Name)"
                    Stop-VM -VM $vm -Force -Confirm:$false
                }
            } else {
                Write-Host "No running VMs found on $hostname"
            }
        } finally {
            # Disconnect from the Hyper-V host
            Disconnect-VIServer -Server $connection -Force
        }
    } else {
        Write-Host "Failed to connect to $hostname"
    }
}
