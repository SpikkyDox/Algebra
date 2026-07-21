$computerListFile = "C:\Sime\Hosts\ZG-C1.txt"
$computers = Get-Content -Path $computerListFile

function Check-Windows11 {
    param(
        [string]$computerName
    )

    $os = Get-WmiObject -Class Win32_OperatingSystem -ComputerName $computerName
    
    $isWindows11 = $os.Name -match "Windows 11"
    
    return $isWindows11
}

foreach ($computer in $computers) {
    $isWin11Installed = Check-Windows11 -computerName $computer
    if ($isWin11Installed) {
        Write-Host ($computer + ": Windows 11 is installed.")
    } else {
        Write-Host ($computer + ": Windows 11 is not installed.")
    }
}
