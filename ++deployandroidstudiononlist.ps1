# Define the list of computer names from the notepad file
$computerList = Get-Content -Path "C:\Sime\Hosts\ZG-D10.txt"

# Loop through each computer in the list
foreach ($computer in $computerList) {
    Write-Host "Deploying Android Studio on $computer"

    # Invoke deployment script remotely using PowerShell remoting
    Invoke-Command -ComputerName $computer -ScriptBlock {
        # Change directory to the Android Studio installation folder
        Set-Location -Path "C:\AndroidStudio"

        # Execute the deployment script with specified parameters
        Powershell.exe -ExecutionPolicy Bypass .\Deploy-AndroidStudio.ps1 -DeploymentType "Uninstall" -DeployMode "NonInteractive"
    }
}
