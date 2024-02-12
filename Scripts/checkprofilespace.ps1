# Define path to the file containing the list of hostnames
$computersFile = "E:\Sime\Hosts\ZG-C2.txt"

# Define output file path
$outputFile = "E:\Sime\profiliC2test22223333.txt"

# Loop through each hostname in the file
Get-Content $computersFile | ForEach-Object {
    $hostname = $_
    Write-Host "Checking $hostname..."

    # Get list of all user profiles on the machine
    $profilePaths = Get-ChildItem "\\$hostname\c$\Users" -Directory | Select-Object -ExpandProperty FullName

    # Loop through each profile and get its size
    $profileSizes = @{}
    foreach ($profilePath in $profilePaths) {
        $profile = $profilePath.Split("\")[-1]
        $profileSize = (Get-ChildItem $profilePath -Recurse | Measure-Object -Property Length -Sum).Sum / 1GB
        $profileSizes[$profile] = $profileSize
    }

    # Format and output results to file
    $outputLine = "$hostname`n"
    foreach ($profile in $profileSizes.Keys) {
        $profileMB = [Math]::Round($profileSizes[$profile] * 1024, 2)
        $profileSizeGB = [Math]::Round($profileSizes[$profile], 2)
        $outputLine += "${profile}: ${profileSizeGB} GB (${profileMB} MB)`n"
    }
    $outputLine += "`n"
    Add-Content $outputFile $outputLine
}
