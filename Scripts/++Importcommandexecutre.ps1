$hostnamesFile = "E:\Sime\skripte\Hosts\ZG-D5.txt"
$vmPath = "D:\Python\Virtual Machines\C31A2F28-8B97-4F04-988F-34D35697A8C4.vmcx"
$command = "Import-VM -Path `"$vmPath`" -Copy"

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
