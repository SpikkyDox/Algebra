# Define path to the file containing the list of hostnames
$computersFile = "E:\Sime\Hosts\ZG-C2.txt"

# Define output file path
$outputFile = "E:\2023-Q4\Zagreb\ZG-C2\InstalledProgramsDifferences.txt"

# Retrieve installed programs for the first computer to use as a base for comparison
$computers = Get-Content $computersFile
$baseComputer = $computers[0]
$basePrograms = Invoke-Command -ComputerName $baseComputer -ScriptBlock {
    Get-WmiObject -Class Win32_Product | Select-Object -ExpandProperty Name
}

# Compare installed programs of the base computer with other computers
foreach ($computer in $computers) {
    if ($computer -ne $baseComputer) {
        Write-Host "Checking differences for $computer..."
        $computerPrograms = Invoke-Command -ComputerName $computer -ScriptBlock {
            Get-WmiObject -Class Win32_Product | Select-Object -ExpandProperty Name
        }

        # Compare the lists and find the differences
        $added = Compare-Object -ReferenceObject $basePrograms -DifferenceObject $computerPrograms |
                 Where-Object { $_.SideIndicator -eq '=>' } |
                 Select-Object -ExpandProperty InputObject

        $removed = Compare-Object -ReferenceObject $basePrograms -DifferenceObject $computerPrograms |
                   Where-Object { $_.SideIndicator -eq '<=' } |
                   Select-Object -ExpandProperty InputObject

        # Output differences to file
        if ($added -or $removed) {
            $output = "$computer`n"
            if ($added) {
                $output += "Added:`n$added`n"
            }
            if ($removed) {
                $output += "Removed:`n$removed`n"
            }
            $output += "`n------------------------------`n"
            Add-Content $outputFile $output
        } else {
            Write-Host "No differences found for $computer"
        }
    }
}

Write-Host "Results saved to $outputFile"
