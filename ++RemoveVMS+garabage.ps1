# Path to the file containing PC names (one per line)
$PCList = Get-Content "C:\GitHub\Hosts\ZG-D3.txt"

# Loop through each PC
foreach ($PC in $PCList) {
    Write-Host "Cleaning Hyper-V VMs on $PC ..." -ForegroundColor Cyan

    try {
        Invoke-Command -ComputerName $PC -ScriptBlock {
            $VMs = Get-VM
            if (-not $VMs) {
                Write-Host "No VMs found on $env:COMPUTERNAME" -ForegroundColor Yellow
                return
            }

            foreach ($VM in $VMs) {
                Write-Host "Removing VM: $($VM.Name)" -ForegroundColor Green

                # Collect all VHDX/AVHDX paths
                $DiskPaths = @()
                foreach ($HDD in (Get-VMHardDiskDrive -VMName $VM.Name)) {
                    $DiskPaths += $HDD.Path
                }

                # Remove the VM
                Stop-VM -Name $VM.Name -Force -TurnOff -ErrorAction SilentlyContinue
                Remove-VM -Name $VM.Name -Force

                # Remove associated VHD/VHDX/AVHDX files and folders
                foreach ($Disk in $DiskPaths) {
                    if (Test-Path $Disk) {
                        try {
                            $Folder = Split-Path $Disk -Parent
                            Write-Host "Deleting folder: $Folder" -ForegroundColor Magenta
                            Remove-Item $Folder -Recurse -Force
                        }
                        catch {
                            Write-Warning "Failed to delete $Disk on $env:COMPUTERNAME"
                        }
                    }
                }
            }
        }
    }
    catch {
        Write-Host "Failed to connect to $PC. Error: $_" -ForegroundColor Red
    }

    Write-Host "---------------------------------------------"
}
