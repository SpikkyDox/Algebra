# Read the list of hosts from the text file
$hostnameList = Get-Content -Path "E:\Sime\Hosts\ZG-C2.txt"
$outputFilePath = "E:\2023-Q4\Zagreb\ZG-C2\UserProfiles_AllHosts.txt"

# Loop through each host in the list
foreach ($hostname in $hostnameList) {
    Write-Host "Executing script on $hostname"

    # Establish a remote session to the host
    $session = New-PSSession -ComputerName $hostname

    # Copy the script block to the remote host and execute it
    Invoke-Command -Session $session -ScriptBlock {
        # Get list of user profiles from the registry
        $profileList = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" | Where-Object { $_.Name -match 'S-1-5-21-\d+-\d+-\d+-\d+$' }

        # Create the output file on the remote host
        if (!(Test-Path "C:\UserProfiles.txt")) {
            New-Item -Path "C:\UserProfiles.txt" -ItemType file
        }

        # Retrieve and calculate user profile information
        foreach ($profile in $profileList) {
            # Retrieve profile SID and path
            $profileSID = $profile.PSChildName
            $profilePath = $profile.GetValue("ProfileImagePath")

            # Calculate profile size
            $profileSize = 0

            # Check if the profile path exists and calculate its size
            if (Test-Path $profilePath) {
                $profileSize = Get-ChildItem -Path $profilePath -Recurse -Force | Measure-Object -Property Length -Sum | Select-Object -ExpandProperty Sum
                $profileSizeInMB = [Math]::Round($profileSize / 1MB, 2)

                # Prepare profile information
                $outputText = "Profile SID: $profileSID"
                $outputText += "`nProfile Path: $profilePath"
                $outputText += "`nProfile Size: $profileSizeInMB MB`n"

                $outputText | Out-File -FilePath "C:\UserProfiles.txt" -Append
            } else {
                Write-Host "Profile path not found for SID: $profileSID"
            }
        }
    }

    # Close the remote session
    Remove-PSSession $session
}

# Collect information from all hosts into a single file
foreach ($hostname in $hostnameList) {
    $outputContent = "User Profiles on Host: $hostname`n`n"
    $outputContent += Get-Content "\\$hostname\C$\UserProfiles.txt" | Out-String
    $outputContent += "------------------------------------------------`n" # Separator line
    $outputContent | Out-File -FilePath $outputFilePath -Append -Encoding UTF8
}

# Remove temporary files on remote hosts
foreach ($hostname in $hostnameList) {
    Remove-Item "\\$hostname\C$\UserProfiles.txt"
}
