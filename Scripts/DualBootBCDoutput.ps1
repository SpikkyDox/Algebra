# Specify the path to the text file containing computer names
$computersFile = "E:\Sime\Hosts\ZG-F2-18.txt"

# Specify the path for the output file on the server
$outputFileServer = "E:\2023-Q4\Zagreb\ZG-C2\F2181.txt"

# Function to execute bcdedit remotely and append formatted output to the output file
function RunBcdEditRemotely {
    param(
        [string]$computerName,
        [string]$outputFileServer
    )

    $remoteSession = New-PSSession -ComputerName $computerName -ErrorAction SilentlyContinue
    if ($remoteSession) {
        $output = Invoke-Command -Session $remoteSession -ScriptBlock {
            $computer = $env:COMPUTERNAME
            $separator = "---------------- $computer ----------------"
            $bcdeditOutput = bcdedit | Out-String
            $separator + "`r`n" + $bcdeditOutput
        }
        Add-content -Path $outputFileServer -Value $output
        Remove-PSSession -Session $remoteSession
    } else {
        Write-Host "Failed to connect to $computerName" -ForegroundColor Red
        Add-content -Path $outputFileServer -Value "Failed to connect to $computerName`r`n"
    }
}

# Get content of the text file containing computer names
$computers = Get-Content $computersFile

# Loop through each computer and execute bcdedit remotely
foreach ($computer in $computers) {
    Write-Host "Running bcdedit on $computer..."
    RunBcdEditRemotely -computerName $computer -outputFileServer $outputFileServer
}

# Function to delete bcdedit output on local PC
function DeleteLocalBcdEditOutput {
    $bcdOutputPath = "$env:SystemDrive\Output.txt" # Modify this path if needed

    if (Test-Path $bcdOutputPath) {
        Remove-Item $bcdOutputPath -Force
        Write-Host "Local bcdedit output deleted successfully."
    } else {
        Write-Host "Local bcdedit output not found."
    }
}

# Delete bcdedit output on local PCs
DeleteLocalBcdEditOutput
