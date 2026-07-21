# Script: Add-NetworkingCourses2526.ps1
# Run as Administrator on management PC

$HostFile = "C:\GitHub\Hosts\ZG-D3.txt"
$Hosts = Get-Content $HostFile | Where-Object { $_ -match "^\S+" }   # take all non-empty lines

foreach ($Computer in $Hosts) {
    Write-Host "==== Processing $Computer (Mount + bcdboot) ====" -ForegroundColor Cyan
    try {
        Invoke-Command -ComputerName $Computer -ScriptBlock {
            param($VHDPath)

            Write-Host "[$env:COMPUTERNAME] Mounting VHDX $VHDPath ..." -ForegroundColor Cyan
            Mount-DiskImage -ImagePath $VHDPath -ErrorAction Stop

            # Get disk and partition from mounted VHD
            $disk = Get-DiskImage -ImagePath $VHDPath | Get-Disk
            $part = Get-Partition -DiskNumber $disk.Number | Where-Object { $_.Type -eq 'Basic' -and $_.GptType -ne $null }

            # Assign drive letter F if not already
            if (-not (Get-PSDrive F -ErrorAction SilentlyContinue)) {
                Write-Host "[$env:COMPUTERNAME] Assigning drive letter F ..." -ForegroundColor Yellow
                Set-Partition -DiskNumber $disk.Number -PartitionNumber $part.PartitionNumber -NewDriveLetter "F"
            } else {
                Write-Host "[$env:COMPUTERNAME] Drive F already assigned." -ForegroundColor Green
            }

            # Add boot entry
            Write-Host "[$env:COMPUTERNAME] Running bcdboot F:\Windows ..." -ForegroundColor Cyan
            bcdboot F:\Windows | Out-Null

        } -ArgumentList "D:\NetworkingCoursesW11.vhdx" -ErrorAction Stop
    }
    catch {
        Write-Host "Failed to process $Computer : $_" -ForegroundColor Red
    }
}
