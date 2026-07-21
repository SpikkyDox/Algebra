# ============================
# Script: Cleanup-DDrive.ps1
# Deletes everything on D:\ except:
#   1. D:\Classroom_SHARE (folder)
#   2. D:\Instalacija mrežih drivera (folder)
#   3. D:\NetworkingCoursesW11.vhdx (file)
#   4. D:\Logo.jpeg (file)
#   5. D:\hp-cmsl-1.8.2.exe (file)
# Runs on all PCs listed in ClassroomPCs.txt
# ============================

# Path to the text file with list of PCs (one hostname or IP per line)
$PCList = "C:\GitHub\Hosts\ZG-D3.txt"

# Drive and exclusions
$Drive          = "D:\"
$ExcludeFolder1 = "Classroom_SHARE"
$ExcludeFolder2 = "Instalacija mrežih drivera"
$ExcludeFile1   = "NetworkingCoursesW11.vhdx"
$ExcludeFile2   = "Logo.jpeg"
$ExcludeFile3   = "hp-cmsl-1.8.2.exe"

# Read list of PCs
$Computers = Get-Content $PCList

foreach ($PC in $Computers) {
    Write-Host "Processing $PC ..." -ForegroundColor Cyan
    
    try {
        Invoke-Command -ComputerName $PC -ScriptBlock {
            param($Drive, $ExcludeFolder1, $ExcludeFolder2, $ExcludeFile1, $ExcludeFile2, $ExcludeFile3)

            # Get all items in D:\ except the excluded folders and files
            $Items = Get-ChildItem -Path $Drive -Force | Where-Object {
                $_.Name -ne $ExcludeFolder1 -and
                $_.Name -ne $ExcludeFolder2 -and
                $_.Name -ne $ExcludeFile1   -and
                $_.Name -ne $ExcludeFile2   -and
                $_.Name -ne $ExcludeFile3
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
            Write-Output "[$env:COMPUTERNAME] Cleanup complete. Exclusions preserved on $Drive"

        } -ArgumentList $Drive, $ExcludeFolder1, $ExcludeFolder2, $ExcludeFile1, $ExcludeFile2, $ExcludeFile3 -ErrorAction Stop
    }
    catch {
        Write-Warning "Could not connect to $PC : $_"
    }
}
