# Path to the Notepad file with list of computer names
$computerList = Get-Content "C:\GitHub\Hosts\ZG-D10.txt"

foreach ($computer in $computerList) {
    Write-Host "`nChecking $computer..." -ForegroundColor Cyan

    try {
        $version = Invoke-Command -ComputerName $computer -ScriptBlock {
            $output = python --version 2>&1
            return $output
        }

        if ($version) {
            Write-Host "${computer}: $version" -ForegroundColor Green
        } else {
            Write-Host "${computer}: Python not found or not in PATH" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "${computer}: Error - $_" -ForegroundColor Red
    }
}
