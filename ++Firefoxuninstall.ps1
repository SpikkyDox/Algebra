# Define the path to the Firefox uninstaller
$uninstallPath = "$env:ProgramFiles\Mozilla Firefox\uninstall\helper.exe"

# Define path to the file containing the list of hostnames
$computersFile = "E:\Sime\skripte\Hosts\ZG-C1.txt"

# Loop through each hostname in the file
Get-Content $computersFile | ForEach-Object {
    $hostname = $_
    Write-Host "Uninstalling Firefox from $hostname..."

    # Invoke the uninstall script on the remote computer
    Invoke-Command -ComputerName $hostname -ScriptBlock {
        # Define the path to the Firefox uninstaller
        $uninstallPath = "$env:ProgramFiles\Mozilla Firefox\uninstall\helper.exe"

        # Run the Firefox uninstaller silently
        Start-Process -FilePath $uninstallPath -ArgumentList "/S" -Wait
    }
}
