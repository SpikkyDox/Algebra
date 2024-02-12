# Read the list of hosts from the text file
$hostnameList = Get-Content -Path "E:\Sime\Hosts\ZG-C2.txt"
$outputFilePath = "E:\2023-Q4\Zagreb\ZG-C2\Installed_VMs_AllHosts.txt"

# Function to get installed virtual machines
function GetInstalledVMs {
    param($computerName)
    
    $vms = Invoke-Command -ComputerName $computerName -ScriptBlock {
        $vms = Get-WmiObject -Namespace "root\virtualization\v2" -Query "SELECT * FROM Msvm_ComputerSystem WHERE Caption='Virtual Machine'"
        $vmNames = $vms | Select-Object -ExpandProperty ElementName
        return $vmNames
    }
    
    return $vms
}

# Loop through each host in the list and retrieve installed virtual machines
foreach ($hostname in $hostnameList) {
    Write-Host "Checking installed VMs on $hostname"

    # Get installed virtual machines for the current host
    $installedVMs = GetInstalledVMs -computerName $hostname

    # Append the list of installed VMs to the output file
    Add-Content -Path $outputFilePath -Value "Installed VMs on ${hostname}:`n$installedVMs`n"
}
