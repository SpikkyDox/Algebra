# Import the Hyper-V module
# Import-Module Hyper-V

# Get the list of PCs from the text file
$pcList = Get-Content -Path "C:\GitHub\Hosts\ZG-C5.txt"

# Loop through each PC in the list
foreach ($pc in $pcList) {
    # Create a new PSSession to the PC
    $session = New-PSSession -ComputerName $pc

    # Run the command to create a checkpoint for the VM named "Ispit"
    Invoke-Command -Session $session -ScriptBlock {
        Checkpoint-VM -Name "Ispit" -SnapshotName "Starting_image"
    }

    # Close the PSSession
    Remove-PSSession -Session $session
}
