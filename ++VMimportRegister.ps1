$hostnamesFile = "D:\ZG-F2.txt"
$vmPath = "D:\PYT_H-01%4724\Virtual Machines\14EF268D-9151-47DA-8E11-FFDDD4EA8F4F.vmcx"
$command = "Import-VM -Path `"$vmPath`" -Register"

$hostnames = Get-Content -Path $hostnamesFile

$credential = Get-Credential

foreach ($hostname in $hostnames) {
    Write-Host "Executing command on $hostname"

    $scriptBlock = {
        param ($command)
        Invoke-Expression -Command $command
    }

    Invoke-Command -ComputerName $hostname -Credential $credential -ScriptBlock $scriptBlock -ArgumentList $command
}
