# Define the folder name to check for
$folderName = "DBA"
# Define the path to the text file containing computer names
$computerListFile = "E:\Sime\Hosts\ZG-F1.txt"
# Read computer names from the text file
$computerNames = Get-Content -Path $computerListFile
# Loop through each computer name and check for the folder on the D:\ drive
foreach ($computerName in $computerNames) {
    # Run the Test-Path command remotely and check if the folder exists
    $folderExists = Invoke-Command -ComputerName $computerName -ScriptBlock {
        Test-Path -Path "D:\$using:folderName" -PathType Container
    }

    if ($folderExists) {
        Write-Host "Folder '$folderName' exists on D:\ drive of $computerName."
    } else {
        Write-Host "Folder '$folderName' does not exist on D:\ drive of $computerName."
    }
}
