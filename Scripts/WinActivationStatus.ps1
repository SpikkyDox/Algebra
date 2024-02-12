# Read the list of hosts from the text file
$hostnameList = Get-Content -Path "E:\Sime\Hosts\ZG-D1.txt"
$outputFilePath = "E:\2023-Q4\Zagreb\ZG-C2\Activation_Status_AllHostsD1.txt"

# Function to check Windows activation status
function CheckWindowsActivationStatus {
    param($computerName)

    $activationStatus = Invoke-Command -ComputerName $computerName -ScriptBlock {
        $regKey = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
        $activation = Get-ItemProperty -Path $regKey -Name 'DigitalProductId'

        # Determine activation status based on digital product ID
        if ($activation.DigitalProductId) {
            $status = "Activated"
        } else {
            $status = "Not Activated"
        }

        # Return the activation status
        Write-Host "Checking Windows activation status on $hostname"
        Write-Host "Activation status: $status"
        return $status
    }

    return $activationStatus
}

# Loop through each host in the list and check activation status
foreach ($hostname in $hostnameList) {
    # Get Windows activation status for the current host
    $activationResult = CheckWindowsActivationStatus -computerName $hostname

    # Append the activation status to the output file
    Add-Content -Path $outputFilePath -Value "Activation status on ${hostname}:`n$activationResult`n"
}
