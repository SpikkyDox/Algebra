# Path to the notepad file containing the list of computer names
$computerListFile = "C:\Sime\Hosts\ZG-F1-partial.txt"

# Read the list of computer names from the file
$computerList = Get-Content $computerListFile

# Loop through each computer and execute the script remotely
foreach ($computer in $computerList) {
    Write-Host "Executing script on $computer"
    
    # Invoke the script remotely on the current computer
    Invoke-Command -ComputerName $computer -ScriptBlock {
        # Mount the disk image
        Mount-DiskImage -ImagePath "D:\Android 22H2\Android 22H2.vhdx" -PassThru | ForEach-Object {
            $driveLetter = "F"
            Write-Host "Disk image mounted to drive $driveLetter"
            
            # Run Command Prompt as administrator
            Start-Process cmd.exe -Verb RunAs -ArgumentList "/c bcdboot ${driveLetter}:\Windows"
            
            # Wait for the command prompt window to open
            Start-Sleep -Seconds 5
            
            # Set the description for the mounted image
            Start-Process cmd.exe -Verb RunAs -ArgumentList "/k bcdedit /set {default} description Android22H2"
            Start-Sleep -Seconds 2
            
            # Set the description for the current OS
            Start-Process cmd.exe -Verb RunAs -ArgumentList "/k bcdedit /set {current} description Windows10"
            Start-Sleep -Seconds 2
            
            # Set the default OS to the current one
            Start-Process cmd.exe -Verb RunAs -ArgumentList "/k bcdedit /default {current}"
        }
    } -Credential (Get-Credential)  # You'll be prompted to enter your credentials for remote execution
}
