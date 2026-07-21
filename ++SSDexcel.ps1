# Import the required module for Excel export (ensure ImportExcel module is installed)
Import-Module ImportExcel

# Define the path to the input and output files
$inputFile = "C:\Sime\Hosts\ZG-C3.txt"
$outputFile = "C:\Sime\SSD-c3-v9.5.txt"
$excelFile = "C:\Sime\SSD_sn-C3.xlsx"

# Clear the output file if it exists
if (Test-Path $outputFile) {
    Remove-Item $outputFile
}

# Function to format the size (not needed for Excel but keeping it for reference)
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

# Array to hold data for exporting to Excel
$dataToExport = @()

# Read the list of PCs
$pcList = Get-Content $inputFile

foreach ($pc in $pcList) {
    # Get the PC serial number
    $session = New-PSSession -ComputerName $pc
    $serialNumber = Invoke-Command -Session $session -ScriptBlock {
        (Get-CimInstance -ClassName Win32_BIOS).SerialNumber
    }

    # Get the PhysicalDisk information including FriendlyName and AdapterSerialNumber
    $diskInfo = Invoke-Command -Session $session -ScriptBlock {
        Get-PhysicalDisk | Select-Object FriendlyName, AdapterSerialNumber
    }
    Remove-PSSession -Session $session

    if ($diskInfo) {
        foreach ($disk in $diskInfo) {
            # Clean the Adapter Serial Number by removing trailing parts like "_0000", "_2017"
            $cleanAdapterSerialNumber = $disk.AdapterSerialNumber -replace '_.*$', ''

            # Add the PC name, serial number, model name (formerly Friendly Name), and cleaned serial number (formerly Adapter Serial Number) to the data array
            $dataToExport += [pscustomobject]@{
                "PC Name" = $pc
                "PC Serial Number" = $serialNumber
                "Model Name" = $disk.FriendlyName  # Formerly Friendly Name
                "Serial Number" = $cleanAdapterSerialNumber  # Formerly Adapter Serial Number
            }
        }
    } else {
        # If no disk info is found, still log the PC and serial number, but mark disk info as not available
        $dataToExport += [pscustomobject]@{
            "PC Name" = $pc
            "PC Serial Number" = $serialNumber
            "Model Name" = "No disk found"
            "Serial Number" = "N/A"
        }
    }
}

# Export the collected data to an Excel file
$dataToExport | Export-Excel -Path $excelFile -AutoSize -Title "PC and Disk Info"

Write-Output "Data has been successfully exported to $excelFile"
