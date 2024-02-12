# Specify the path to the text file containing hostnames
$hostnamesFile = "E:\Sime\skripte\Hosts\ZG-C10.txt"

# Specify the path for the output file
$outputFile = "C:\path\to\ALL-existing-VMs.txt"

# Read hostnames from the text file
$hostnames = Get-Content -Path $hostnamesFile

# Initialize an empty array to store VM information
$vmInfo = @()

# Loop through each hostname
foreach ($hostname in $hostnames) {
    Write-Host "Checking VMs on $hostname"

    # Get all VMs on the host
    $vms = Get-VM -ComputerName $hostname

    if ($vms) {
        foreach ($vm in $vms) {
            # Get VM information
            $vmData = [PSCustomObject]@{
                Hostname = $hostname
                VMName = $vm.Name
                State = $vm.State
            }

            # Add VM information to the array
            $vmInfo += $vmData
        }
    } else {
        Write-Host "No VMs found on $hostname"
    }
}

# Export the VM information to the output file
$vmInfo | Export-Csv -Path $outputFile -NoTypeInformation

Write-Host "VM information exported to $outputFile"
