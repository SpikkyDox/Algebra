$hostsFile = "E:\Sime\Hosts\ZG-F2.txt"
$command = "EmaAgent.exe -fullinstall"
$cred = Get-Credential

Get-Content $hostsFile | ForEach-Object {
    $hostname = $_.Trim()
    Write-Host "Running command on $hostname..."
    $session = New-PSSession -ComputerName $hostname -Credential $cred

    Invoke-Command -Session $session -ScriptBlock {
        param($command)
        $outputPath = "C:\command_output.txt"

        Write-Host "Executing command: $command"
        Start-Process powershell.exe -Verb RunAs -ArgumentList "/c $command > $outputPath" -Wait

        Write-Host "Command executed on $env:COMPUTERNAME"
        Write-Host "Command output:"
        Get-Content $outputPath
    } -ArgumentList $command

    Remove-PSSession $session
}
