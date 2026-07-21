# Define the path to the input and output files
$inputFile = "C:\ZagrebHosts\ZG-D2.txt"
$outputFile = "C:\Sime\SSD-D2-v2.5.txt"


# Clear the output file if it exists
if (Test-Path $outputFile) {
    Remove-Item $outputFile
}

# Function to format the size
function Format-Size {
    param (
        [Parameter(Mandatory=$true)]
        [int64]$Size
    )
    if ($Size -ge 1TB) {
        return [math]::Round($Size / 1TB, 2).ToString() + " TB"
    } elseif ($Size -ge 1GB) {
        return [math]::Round($Size / 1GB, 2).ToString() + " GB"
    } else {
        return $Size.ToString() + " Bytes"
    }
}

# Read the list of PCs
$pcList = Get-Content $inputFile

foreach ($pc in $pcList) {
    # Write the PC name to the output file
    Add-Content -Path $outputFile -Value "PC: $pc"

    # Get the SSD information
    $session = New-PSSession -ComputerName $pc
    $ssdInfo = Invoke-Command -Session $session -ScriptBlock {
        Get-PhysicalDisk | Select-Object DeviceID, MediaType, SerialNumber, Model, Size, BusType
    }
    Remove-PSSession -Session $session

    if ($ssdInfo) {
        foreach ($ssd in $ssdInfo) {
            # Format the serial number
            $formattedSerialNumber = $ssd.SerialNumber -replace '_', '' -replace '\.', ''

            # Format the size
            $formattedSize = Format-Size -Size $ssd.Size

            # Write the SSD information to the output file
            Add-Content -Path $outputFile -Value "Device ID: $($ssd.DeviceID)"
            Add-Content -Path $outputFile -Value "Media Type: $($ssd.MediaType)"
            Add-Content -Path $outputFile -Value "Serial Number: $formattedSerialNumber"
            Add-Content -Path $outputFile -Value "Model: $($ssd.Model)"
            Add-Content -Path $outputFile -Value "Size: $formattedSize"
            Add-Content -Path $outputFile -Value "Bus Type: $($ssd.BusType)"
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
