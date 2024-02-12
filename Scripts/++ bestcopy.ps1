
# Set the source and destination paths and the path to the file containing the list of destination hostnames or IP addresses
$vhdxSourcePath = "E:\Sime"
$vhdxDestFolder = "D$\"
$destHostsFile = "E:\Sime\skripte\Hosts\ZG-D1.txt"

# Read the list of destination hosts from the file
$destHosts = Get-Content $destHostsFile

# Loop through the list of destination hosts and copy the VHDX file to each one
foreach ($destHost in $destHosts) {
    # Construct the UNC path to the destination folder
    $destPath = "\\$destHost\$vhdxDestFolder"

    # Use the Copy-Item cmdlet to copy the VHDX file to the destination path
    Copy-Item -Path $vhdxSourcePath -Destination $destPath -Recurse

    # Output a message indicating the status of the copy operation
    Write-Host "VHDX file copied to $destHost"
}
