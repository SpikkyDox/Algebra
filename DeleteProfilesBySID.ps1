# Read the list of hosts from the text file
$hostnameList = Get-Content -Path "E:\Sime\Hosts\ZG-C2.txt"

# Array of SIDs to delete
$sidsToDelete = @(
    "S-1-5-21-2239633697-3297838308-1060792335-8615",
    "S-1-5-21-2239633697-3297838308-1060792335-13820",
    "SID_TO_DELETE_3"
    # Add more SIDs to delete as needed
)

# Loop through each host in the list
foreach ($hostname in $hostnameList) {
    Write-Host "Deleting profiles on $hostname"

    # Establish a remote session to the host
    $session = New-PSSession -ComputerName $hostname

    # Copy the script block to the remote host and execute it
    Invoke-Command -Session $session -ScriptBlock {
        param($sidsToDelete)

        foreach ($sidToDelete in $sidsToDelete) {
            # Get list of user profiles from the registry based on the provided SIDs
            $profileList = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | Where-Object { $_.PSChildName -eq $sidToDelete }

            # Delete user profile based on SID
            foreach ($profile in $profileList) {
                $profilePath = $profile.GetValue("ProfileImagePath")

                if (Test-Path $profilePath) {
                    # Backup the profile before deletion (optional)
                    $backupPath = "C:\Backup\$sidToDelete"
                    if (!(Test-Path $backupPath)) {
                        New-Item -Path $backupPath -ItemType Directory
                    }
                    robocopy $profilePath $backupPath /MIR /SEC /R:1 /W:1

                    # Delete the profile
                    Remove-Item -Path $profilePath -Recurse -Force
                    Write-Host "Profile with SID $sidToDelete deleted on $env:COMPUTERNAME"
                } else {
                    Write-Host "Profile path not found for SID: $sidToDelete"
                }
            }
        }
    } -ArgumentList $sidsToDelete

    # Close the remote session
    Remove-PSSession $session
}
