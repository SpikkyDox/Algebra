$computers = Get-Content "E:\Sime\Hosts\ZG-C2.txt"
$outputFile = "E:\Sime\Output\VisualStudio2022&Code\VS-F2.txt"

foreach ($computer in $computers) {
    Write-Host "Checking computer $computer"
    $session = New-PSSession -ComputerName $computer

    $vsCodePath = "C:\Microsoft VS Code"
    $vsCodeExists = Invoke-Command -Session $session -ScriptBlock { Test-Path $using:vsCodePath }

    $vsPath = "C:\Program Files\Microsoft Visual Studio\2022\Community"
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
