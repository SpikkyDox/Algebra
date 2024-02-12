# Set the source and destination paths and the path to the file containing the list of destination hostnames or IP addresses
$vhdxSourcePaths = @(
    "C:\Users\administrator.UCIONE\Downloads\EMAAgent.msh",
    "C:\Users\administrator.UCIONE\Downloads\EMAAgent.exe"
)
$vhdxDestFolder = "C$\windows\system32\"
$destHostsFile = "E:\Sime\Hosts\ZG-C5-partial.txt"
$command = "EmaAgent.exe -fullinstall"
$cred = Get-Credential

# Read the list of destination hosts from the file
$destHosts = Get-Content $destHostsFile

# Loop through the list of destination hosts
foreach ($destHost in $destHosts) {
    # Construct the UNC path to the destination folder
    $destPath = "\\$destHost\$vhdxDestFolder"

    # Loop through each source path and copy it to the destination path
    foreach ($sourcePath in $vhdxSourcePaths) {
        # Get the source file name
        $sourceFileName = Split-Path -Path $sourcePath -Leaf

        # Construct the destination file path
        $destFilePath = Join-Path -Path $destPath -ChildPath $sourceFileName

        # Copy the source file to the destination path
        Copy-Item -Path $sourcePath -Destination $destFilePath -Force

        # Output a message indicating the status of the copy operation
        Write-Host "File $sourceFileName copied to $destHost"
    }

    # Establish a remote session to the destination ho
    $session = New-PSSession -ComputerName $destHost -Credential $cred

    # Execute the command on the destination host
    Invoke-Command -Session $session -ScriptBlock {
        param($command)
        $outputPath = "C:\command_output.txt"

        Write-Host "Running command: $command"
        Start-Process powershell.exe -Verb RunAs -ArgumentList "/c $command > $outputPath" -Wait

        Write-Host "Command executed on $env:COMPUTERNAME"
        Write-Host "Command output:"
        Get-Content $outputPath
    } -ArgumentList $command

    # Remove the remote session
    Remove-PSSession $session
}
