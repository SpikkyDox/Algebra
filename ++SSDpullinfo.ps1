# Define the path to the input and output files
$inputFile = "C:\Sime\Hosts\partial.txt"
$outputFile = "C:\Sime\SSD-D7-v5.txt"

# Clear the output file if it exists
if (Test-Path $outputFile) {
    Remove-Item $outputFile
}

# Read the list of PCs
$pcList = Get-Content $inputFile

foreach ($pc in $pcList) {
    # Write the PC name to the output file
    Add-Content -Path $outputFile -Value "PC: $pc"

    # Get the SSD information
    $ssdInfo = Get-WmiObject -ComputerName $pc -Query "SELECT Model, SerialNumber, Manufacturer FROM Win32_DiskDrive"

    if ($ssdInfo) {
        foreach ($ssd in $ssdInfo) {
            # Write the SSD information to the output file
            Add-Content -Path $outputFile -Value "Model: $($ssd.Model)"
            Add-Content -Path $outputFile -Value "Serial Number: $($ssd.SerialNumber)"
            #Add-Content -Path $outputFile -Value "Manufacturer: $($ssd.Manufacturer)"
            Add-Content -Path $outputFile -Value ""
        }
    } else {
        Add-Content -Path $outputFile -Value "No SSD information found."
    }

    # Add a separator line between hosts
    Add-Content -Path $outputFile -Value "----------------------------------------"
    Add-Content -Path $outputFile -Value ""
}

Write-Output "SSD information has been collected and saved to $outputFile"
