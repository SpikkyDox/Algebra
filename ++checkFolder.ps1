# Path to the file with computer names
$ComputerList = Get-Content "C:\GitHub\Hosts\ZG-C6.txt"

# The folder you want to check
$FolderPath = "D:\Windows 11"

# Output results
$Results = @()

foreach ($Computer in $ComputerList) {
    Write-Host "Checking $Computer ..." -ForegroundColor Cyan
    try {
        # Test if computer is online first
        if (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
            $exists = Invoke-Command -ComputerName $Computer -ScriptBlock {
                param($Path)
                Test-Path $Path
            } -ArgumentList $FolderPath -ErrorAction Stop

            $Results += [PSCustomObject]@{
                Computer = $Computer
                Folder   = $FolderPath
                Exists   = $exists
            }
        } else {
            $Results += [PSCustomObject]@{
                Computer = $Computer
                Folder   = $FolderPath
                Exists   = "Offline"
            }
        }
    }
    catch {
        $Results += [PSCustomObject]@{
            Computer = $Computer
            Folder   = $FolderPath
            Exists   = "Error: $_"
        }
    }
}

# Show results in console
$Results | Format-Table -AutoSize

# Optionally export to CSV
$Results | Export-Csv "C:\path\to\FolderCheckResults.csv" -NoTypeInformation
