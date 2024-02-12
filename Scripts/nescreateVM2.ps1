# Set the source and destination paths and the path to the file containing the list of destination hostnames or IP addresses
$vhdxSourcePath = "D:\VM\SIS.vhdx"
$vhdxDestFolder = "D$\VM\"
$destHostsFile = "E:\Sime\skripte\Hosts\ZG-F3.txt"

# Read the list of destination hosts from the file
$destHosts = Get-Content $destHostsFile

# Loop through the list of destination hosts and copy the VHDX file to each one
foreach ($destHost in $destHosts) {
    # Construct the UNC path to the destination folder
    $destPath = "\\$destHost\$vhdxDestFolder"

    # Check if the destination folder exists and create it if it does not
    if (!(Test-Path $destPath)) {
        try {
            New-Item -ItemType Directory -Path $destPath | Out-Null
        } catch {
            Write-Host "Failed to create destination folder on $destHost"
            Write-Host $_.Exception.Message
            continue
        }
    }

    # Check if the VHDX file already exists in the destination folder
    $destFilePath = Join-Path -Path $destPath -ChildPath "SIS.vhdx"
    if (Test-Path $destFilePath) {
        Write-Host "VHDX file already exists in $destHost"
    } else {
        # Copy the VHDX file to the destination path
        try {
            Copy-Item -Path $vhdxSourcePath -Destination $destPath -Recurse
            Write-Host "VHDX file copied to $destHost"
        } catch {
            Write-Host "Failed to copy VHDX file to $destHost"
            Write-Host $_.Exception.Message
            continue
        }
    }
}
