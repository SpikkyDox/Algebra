# Define the user to add to the Hyper-V Administrators group
$user = "grafika10@ucione.local"

# Define the group name
$group = "Hyper-V Administrators"

# Read computer names from the text file
$computers = Get-Content -Path "C:\GitHub\Hosts\RI-02.txt"

foreach ($computer in $computers) {
    Write-Host "Processing $computer"

    # Use Invoke-Command to run the command on remote computers
    Invoke-Command -ComputerName $computer -ScriptBlock {
        # Use net localgroup command to add the user to the group
        net localgroup "$using:group" "$using:user" /add
    }

    Write-Host "User $user added to $group group on $computer"
}
