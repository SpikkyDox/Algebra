# Specify the path to the notepad file containing the list of computers (each computer on a new line)
$computersFilePath = "C:\GitHub\Hosts\ZG-C3.txt"

# VM name to be deleted
$vmName = "ASBP_VM_1"

# Path to the VHDX file to be deleted
$vhdxFilePath = "D:\ASBP_VM_1\ABP-VM1.vhd"

# Read the list of computers from the file
$computers = Get-Content -Path $computersFilePath

# Loop through each computer
foreach ($computer in $computers) {
    Write-Host "Deleting VM and VHDX file on $computer"

    # Define the command to delete the VM and VHDX file remotely using Invoke-Command
    $deleteCommand = {
        param($vmName, $vhdxFilePath)
        
        # Remove the VM
        Get-VM -Name $vmName | Remove-VM -Force

        # Remove the VHDX file
        if (Test-Path $vhdxFilePath -PathType Leaf) {
            Remove-Item -Path $vhdxFilePath -Force
            Write-Host "VHDX file deleted successfully on $($env:COMPUTERNAME)"
        } else {
            Write-Host "The specified VHDX file does not exist on $($env:COMPUTERNAME)"
        }
    }

    # Execute the command remotely on each computer using Invoke-Command
    Invoke-Command -ComputerName $computer -ScriptBlock $deleteCommand -ArgumentList $vmName, $vhdxFilePath
}
