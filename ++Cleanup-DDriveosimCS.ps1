# Path to the text file with list of PCs (one hostname or IP per line)
$PCList = "C:\GitHub\Hosts\ZG-C3.txt"

# Drive and folder to exclude
$Drive = "D:\"
$ExcludeFolder = "Classroom_SHARE"

# Read list of PCs
$Computers = Get-Content $PCList

foreach ($PC in $Computers) {
    Write-Host "Processing $PC ..." -ForegroundColor Cyan
    
    try {
        Invoke-Command -ComputerName $PC -ScriptBlock {
            param($Drive, $ExcludeFolder)

            # Get all items except the excluded folder
            $Items = Get-ChildItem -Path $Drive -Force | Where-Object {
                $_.Name -ne $ExcludeFolder
            }

            foreach ($Item in $Items) {
                try {
                    if ($Item.PSIsContainer) {
                        Remove-Item -Path $Item.FullName -Recurse -Force -ErrorAction Stop
                        Write-Output "[$env:COMPUTERNAME] Deleted folder: $($Item.FullName)"
                    }
                    else {
                        Remove-Item -Path $Item.FullName -Force -ErrorAction Stop
                        Write-Output "[$env:COMPUTERNAME] Deleted file: $($Item.FullName)"
                    }
                }
                catch {
                    Write-Output "[$env:COMPUTERNAME] Failed to delete $($Item.FullName): $_"
                }
            }
            Write-Output "[$env:COMPUTERNAME] Cleanup complete. Only $ExcludeFolder remains on $Drive"

        } -ArgumentList $Drive, $ExcludeFolder -ErrorAction Stop
    }
    catch {
        Write-Warning "Could not connect to $PC : $_"
    }
}
