# Specify the path to the exported VM folder
$vmFolderPath = "E:\Python"

# Specify the path to the text file containing hostnames
$hostnamesFile = "E:\Sime\skripte\Hosts\ZG-C10.txt"

# Read hostnames from the text file
$hostnames = Get-Content -Path $hostnamesFile

# Loop through each hostname
foreach ($hostname in $hostnames) {
    Write-Host "Importing VM 'python' to $hostname"
    
    try {
        # Check if the destination folder already exists
        $destinationPath = "\\$hostname\d$\python"
        if (Test-Path $destinationPath) {
            Write-Host "Folder already exists on $hostname. Skipping copy..."
        } else {
            # Copy the exported VM folder to the remote host
            Copy-Item -Path $vmFolderPath -Destination $destinationPath -Recurse -Force
        }
        
        # Import the VM on the remote host
        Import-VM -Path "D:\python\Virtual Machines\C31A2F28-8B97-4F04-988F-34D35697A8C4.vmcx" -Copy -VhdDestinationPath "\\$hostname\c$\ProgramData\Microsoft\Windows\Hyper-V"
        
        Write-Host "VM 'python' imported successfully to $hostname"
    } catch {
        Write-Host "Failed to connect to $($hostname): $($_.Exception.Message)"
    }
}
