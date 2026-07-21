# Prompt the user for elevated privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Please run this script as an administrator." -ForegroundColor Red
    exit
}

# Path to the text file containing computer names
$computersFile = "C:\GitHub\Hosts\ZG-D11.txt"

# Folders to be deleted from each computer
$foldersToDelete = @("D:\ASBP_ISPIT_1")

# Read computer names from the file
$computers = Get-Content -Path $computersFile

foreach ($computer in $computers) {
    Write-Host "Connecting to $computer..." -ForegroundColor Yellow

    try {
        # Attempt a remote connection to the computer
        $session = New-PSSession -ComputerName $computer -ErrorAction Stop

        # Delete the folders on the remote computer
        foreach ($folderToDelete in $foldersToDelete) {
            Invoke-Command -Session $session -ScriptBlock {
                param($folderToDelete)
                if (Test-Path $folderToDelete -PathType Container) {
                    Remove-Item $folderToDelete -Recurse -Force
                    Write-Host "Folder deleted: $folderToDelete" -ForegroundColor Green
                } else {
                    Write-Host "Folder not found: $folderToDelete" -ForegroundColor Yellow
                }
            } -ArgumentList $folderToDelete
        }

        # Close the remote session
        Remove-PSSession $session
    }
    catch {
        Write-Host "Failed to connect to ${computer}: $_.Exception.Message" -ForegroundColor Red
    }
}
