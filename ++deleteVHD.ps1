# Specify the path to the notepad file containing the list of computers (each computer on a new line)
$computersFilePath = "C:\Sime\Hosts\ZG-F3.txt"

# Path to the VHDX file to be deleted
$vhdxFilePath = "D:\FigmaSetup.exe"

# Read the list of computers from the file
$computers = Get-Content -Path $computersFilePath

# Loop through each computer and delete the specified VHDX file
foreach ($computer in $computers) {
    Write-Host "Deleting VHDX file on $computer"

    # Define the command to delete the VHDX file remotely using Invoke-Command
    $deleteCommand = {
        param($file)
        if (Test-Path $file -PathType Leaf) {
            Remove-Item -Path $file -Force
            Write-Host "VHDX file deleted successfully on $($env:COMPUTERNAME)"
        } else {
            Write-Host "The specified VHDX file does not exist on $($env:COMPUTERNAME)"
        }
    }

    # Execute the command remotely on each computer using Invoke-Command
    Invoke-Command -ComputerName $computer -ScriptBlock $deleteCommand -ArgumentList $vhdxFilePath
}
