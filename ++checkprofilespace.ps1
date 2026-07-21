# Define path to the file containing the list of hostnames
$computersFile = ESimeHostsZG-C6.txt

# Define output file path
$outputFile = ESimeprofiliC6

# Loop through each hostname in the file
Get-Content $computersFile  ForEach-Object {
    $hostname = $_
    Write-Host Checking $hostname...

    # Get list of all user profiles on the machine
    $profilePaths = Get-ChildItem $hostnamec$Users -Directory  Select-Object -ExpandProperty FullName

    # Loop through each profile and get its size
    $profileSizes = @{}
    foreach ($profilePath in $profilePaths) {
        $profile = $profilePath.Split()[-1]
        $profileSize = (Get-ChildItem $profilePath -Recurse  Measure-Object -Property Length -Sum).Sum  1GB
        $profileSizes[$profile] = $profileSize
    }

    # Output results to file
    $outputLine = $hostname`n
    foreach ($profile in $profileSizes.Keys) {
        $size = $profileSizes[$profile]
        $outputLine += $profile` $size GB`n
    }
    $outputLine += `n
    Add-Content $outputFile $outputLine
}
