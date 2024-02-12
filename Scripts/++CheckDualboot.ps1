# Define the description of the entry you want to check for
$targetDescription = "Server2019"
# Define the path to the text file containing computer names
$computerListFile = "E:\Sime\Hosts\ZG-F3.txt"
# Read computer names from the text file
$computerNames = Get-Content -Path $computerListFile
# Loop through each computer name and check for the target description in the BCD
foreach ($computerName in $computerNames) {
    # Run the bcdedit command remotely and capture the output
    $bcdOutput = Invoke-Command -ComputerName $computerName -ScriptBlock {
        bcdedit /enum
    }

    # Check if the target description is present in the output
    if ($bcdOutput -match "description\s+$targetDescription") {
        Write-Host "Dual-boot entry with description '$targetDescription' found on $computerName."
    } else {
        Write-Host "No dual-boot entry with description '$targetDescription' found on $computerName."
    }
}
