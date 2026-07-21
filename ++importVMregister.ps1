# Path to the text file with hostnames (one per line)
$ComputerList = Get-Content "C:\GitHub\Hosts\ZG-D6.txt"

# VM path
$VMPath = "D:\WORDZG-C6\WORDZG-C6\Virtual Machines\00972A52-1CFC-4C98-B2E7-E07546761F21.vmcx"

foreach ($Computer in $ComputerList) {
    Write-Host "Processing $Computer ..." -ForegroundColor Cyan
    try {
        Invoke-Command -ComputerName $Computer -ScriptBlock {
            param($VMPath)
            Import-VM -Path $VMPath -Register
        } -ArgumentList $VMPath -ErrorAction Stop
        Write-Host "VM imported successfully on $Computer" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to import VM on $Computer : $_" -ForegroundColor Red
    }
}
