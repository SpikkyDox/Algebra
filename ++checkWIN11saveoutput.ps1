$computerListFile = "C:\Sime\Hosts\ZG-F6.txt"
$outputFile = "C:\WIN11.txt"

$computers = Get-Content -Path $computerListFile

function Check-Windows11 {
    param(
        [string]$computerName
    )

    $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computerName
    
    $isWindows11 = $os.Name -match "Windows 11"
    
    return $isWindows11
}

# Array to store computers with Windows 11 installed
$windows11Computers = @()

foreach ($computer in $computers) {
    $isWin11Installed = Check-Windows11 -computerName $computer
    if ($isWin11Installed) {
        $windows11Computers += $computer
    }
}

# Save the list of computers with Windows 11 installed to a notepad file
$windows11Computers | Out-File -FilePath $outputFile

Write-Host "List of computers with Windows 11 installed saved to: $outputFile"
