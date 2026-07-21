# Path to the notepad file containing computer names (one per line)
$ComputerList = "C:\GitHub\Hosts\ZG-C2.txt"

# Path to the Unity executable to check
$UnityPath = "C:\Program Files\Unity\Hub\Editor\2022.3.62f1\Editor\Unity.exe"

# Output file for results
$OutputFile = "C:\temp\Unity_Check_Results-v2.csv"

# Create results array
$Results = @()

# Loop through each computer
foreach ($Computer in Get-Content $ComputerList) {
    Write-Host "Checking $Computer..." -ForegroundColor Cyan
    $Computer = $Computer.Trim()

    try {
        # Test if the PC is online
        if (Test-Connection -ComputerName $Computer -Count 1 -Quiet) {
            # Check if the Unity path exists remotely
            $exists = Invoke-Command -ComputerName $Computer -ScriptBlock {
                Test-Path "C:\Program Files\Unity 2022.3.62f1\Editor\Unity.exe"
            }

            if ($exists) {
                $Status = "✅ Unity 2022.3.62f1 Installed"
            } else {
                $Status = "❌ Not Installed"
            }
        } else {
            $Status = "⚠️ Offline or Unreachable"
        }
    } catch {
        $Status = "❌ Error: $($_.Exception.Message)"
    }

    # Add result to array
    $Results += [PSCustomObject]@{
        ComputerName = $Computer
        Status       = $Status
    }
}

# Export results
$Results | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8
Write-Host "Check complete. Results saved to $OutputFile" -ForegroundColor Green
