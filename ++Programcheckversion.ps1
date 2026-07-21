# Define the path to the text file containing computer names
$computerListPath = "C:\GitHub\Hosts\ZG-C1.txt"

# Define the path to the SafeExamBrowser executable
$executablePath = "C:\Program Files\SafeExamBrowser\Application\SafeExamBrowser.Client.exe"

# Read the list of computer names from the text file
$computerNames = Get-Content -Path $computerListPath

# Loop through each computer name and check the file version of SafeExamBrowser.exe
foreach ($computerName in $computerNames) {
    Write-Host "Checking $executablePath on $computerName"
    try {
        # Use Invoke-Command to remotely execute Get-ItemProperty to retrieve file version
        $fileVersion = Invoke-Command -ComputerName $computerName -ScriptBlock {
            (Get-ItemProperty -Path $using:executablePath).VersionInfo.FileVersion
        }

        Write-Host "File Version on ${computerName}: $fileVersion"
    } catch {
        Write-Host "Error occurred while checking $executablePath on ${computerName}: $_"
    }
}
