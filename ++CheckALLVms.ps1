# Path to the text file with hostnames (one per line)
$ComputerList = Get-Content "C:\GitHub\Hosts\ZG-D11.txt"

foreach ($Computer in $ComputerList) {
    Write-Host "Checking VMs on $Computer ..." -ForegroundColor Cyan
    try {
        Invoke-Command -ComputerName $Computer -ScriptBlock {
            Get-VM | Select-Object Name, State, CPUUsage, MemoryAssigned
        } -ErrorAction Stop
    }
    catch {
        Write-Host "Failed to query $Computer : $_" -ForegroundColor Red
    }
}
