# Define path to the file containing the list of hostnames
$computersFile = "E:\Sime\Hosts\ZG-C2.txt"

# Define output file path
$outputFile = "E:\2023-Q4\Zagreb\ZG-C2\InstalledProgramsInfo.txt"

# Loop through each hostname in the file
Get-Content $computersFile | ForEach-Object {
    $hostname = $_
    Write-Host "Checking installed programs on $hostname..."

    try {
        # Get installed programs on the remote computer
        $programs = Invoke-Command -ComputerName $hostname -ScriptBlock {
            Get-WmiObject -Class Win32_Product | Select-Object -Property Name, Version, Vendor
        }

        # Format and output results to file
        $outputLine = "$hostname`n"
        $programs | ForEach-Object {
            $outputLine += "Name: $($_.Name)`tVersion: $($_.Version)`tVendor: $($_.Vendor)`n"
        }
        $outputLine += "`n"
        Add-Content $outputFile $outputLine
    } catch {
        Write-Host "Failed to access ${hostname}: $($_.Exception.Message)"
    }
}

Write-Host "Results saved to $outputFile"
