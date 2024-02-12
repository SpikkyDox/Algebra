# Path to the text file containing computer names
$computersFile = "E:\Sime\Hosts\ZG-F2-18.txt"

# File to be deleted from each computer
$fileToDelete = "D:\Python.vhdx"

# Check if the file exists
if (-not (Test-Path $fileToDelete)) {
    Write-Host "File to delete not found: $fileToDelete"
    exit
}

# Read computer names from the file
$computers = Get-Content -Path $computersFile

foreach ($computer in $computers) {
    Write-Host "Connecting to $computer..."

    try {
        # Attempt a remote connection to the computer
        $session = New-PSSession -ComputerName $computer -ErrorAction Stop

        # Delete the file on the remote computer
        Invoke-Command -Session $session -ScriptBlock {
            param($fileToDelete)
            if (Test-Path $fileToDelete) {
                Remove-Item $fileToDelete -Force
                Write-Host "File deleted: $fileToDelete" -ForegroundColor Green
            } else {
                Write-Host "File not found: $fileToDelete" -ForegroundColor Yellow
            }
        } -ArgumentList $fileToDelete

        # Close the remote session
        Remove-PSSession $session
    }
    catch {
        Write-Host "Failed to connect to ${computer}: $_.Exception.Message" -ForegroundColor Red
    }
}
