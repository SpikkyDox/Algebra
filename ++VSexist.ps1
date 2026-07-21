$computers = Get-Content "C:\Sime\Hosts\ZG-F1.txt"
$outputFile = "C:\Sime\Output\VisualStudio2022&CodeVS-F11.txt"

foreach ($computer in $computers) {
    Write-Host "Checking computer $computer"
    $session = New-PSSession -ComputerName $computer

    $vsCodePath = "C:\Users\Student\AppData\Local\Microsoft\Teams"
    $vsCodeExists = Invoke-Command -Session $session -ScriptBlock { Test-Path $using:vsCodePath }

    $vsPath = "C:\Users\administrator.UCIONE\AppData\Local\Microsoft\Teams"
    $vsExists = Invoke-Command -Session $session -ScriptBlock { Test-Path $using:vsPath }

    $output = "Computer: $computer`r`n"
    if ($vsCodeExists) {
        $output += "    $vsCodePath exists`r`n"
    } else {
        $output += "    $vsCodePath does not exist`r`n"
    }

    if ($vsExists) {
        $output += "    $vsPath exists`r`n"
    } else {
        $output += "    $vsPath does not exist`r`n"
    }

    Add-Content $outputFile $output
    Remove-PSSession $session
}
