# Define the directory containing all the notepad files
$directory = "C:\ZagrebHosts"

# Define the output file
$outputFile = "C:\WIN11-17.4.2024.txt"

# Array to store computers with Windows 11 installed
$windows11Computers = @()

# Get all notepad files in the directory
$notepadFiles = Get-ChildItem -Path $directory -Filter "*.txt"

# Define the function to check Windows 11 installation
function Check-Windows11 {
    param(
        [string]$computerName
    )

    $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computerName
    
    $isWindows11 = $os.Name -match "Windows 11"
    
    return $isWindows11
}

# Loop through each notepad file
foreach ($file in $notepadFiles) {
    $computers = Get-Content -Path $file.FullName
    
    # Check each computer in the current notepad file
    foreach ($computer in $computers) {
        $isWin11Installed = Check-Windows11 -computerName $computer
        if ($isWin11Installed) {
            $windows11Computers += $computer
        }
    }
}

# Save the list of computers with Windows 11 installed to a notepad file
$windows11Computers | Out-File -FilePath $outputFile

Write-Host "List of computers with Windows 11 installed saved to: $outputFile"
