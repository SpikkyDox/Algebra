# Define variables
$hostsFile = "E:\Sime\Hosts\ZG-C10.txt"  # Replace with your actual path
$imagePath = "D:\NetworkingCourses22H2\NetworkingCourses22H2.vhdx"  # Replace with your actual path

# Read the hosts from the file
$hosts = Get-Content $hostsFile

# Function to execute command as admin
Function Execute-CommandAsAdmin {
    param(
        [string]$command
    )

    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "cmd"
    $psi.Arguments = "/c $command"
    $psi.Verb = "RunAs"

    [System.Diagnostics.Process]::Start($psi).WaitForExit()
}

# Function to execute command with delay
Function Execute-CommandWithDelay {
    param(
        [string]$command,
        [int]$delaySeconds
    )

    Start-Sleep -Seconds $delaySeconds
    Invoke-Expression -Command $command
}

# Loop through each host
foreach ($host in $hosts) {
    # Mount the vhdx image
    Mount-DiskImage -ImagePath $imagePath

    # Get the newly mounted drive letter
    $driveLetter = (Get-DiskImage -ImagePath $imagePath | Get-Volume).DriveLetter + ":\"

    # Create a new partition F and load cmd as admin
    New-Partition -DiskNumber (Get-Disk | Where-Object { $_.DriveLetter -eq $driveLetter }).Number -UseMaximumSize | Format-Volume -DriveLetter F -FileSystem NTFS -NewFileSystemLabel "NetworkingCourses"

    # Execute bcdboot command
    Execute-CommandAsAdmin "bcdboot F:\Windows"

    # Execute bcdedit command with delay
    Execute-CommandWithDelay "bcdedit /set {default} description NetworkingCourses22H2" 30

    # Restart the PC
    Restart-Computer -Force
}
