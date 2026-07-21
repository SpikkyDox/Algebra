$Path = "E:\Sime\skripte\Hosts\ZG-D1.txt"
$notepadFiles = Get-ChildItem -Path $Path -Filter "*.txt"
$outputFile = "E:\Sime\HardwareOutput"

foreach ($notepadFile in $notepadFiles) {
    Write-Host "Reading hosts from $notepadFile..."
    $computerList = Get-Content $notepadFile.FullName
    
    foreach ($computerName in $computerList) {
        Write-Host "Getting hardware information for $computerName..."
        $hardware = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $computerName
        $cpus = Get-WmiObject -Class Win32_Processor -ComputerName $computerName
        $gpus = Get-WmiObject -Class Win32_VideoController -ComputerName $computerName
        $disks = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $computerName -Filter "DriveType = '3'"
        $network = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $computerName | Where-Object {$_.IPAddress -ne $null}

        $output = @"
Host Name: $computerName
Manufacturer: $($hardware.Manufacturer)
Model: $($hardware.Model)
Serial Number: $($hardware.SerialNumber)
System Type: $($hardware.SystemType)
Total Physical Memory: $([math]::Round($hardware.TotalPhysicalMemory / 1GB)) GB
CPU(s): 
"@
        foreach ($cpu in $cpus) {
            $output += "  $($cpu.Name) $($cpu.NumberOfCores)-core $($cpu.NumberOfLogicalProcessors)-thread $($cpu.MaxClockSpeed)MHz`n"
        }
        $output += "GPU(s):`n"
        foreach ($gpu in $gpus) {
            $output += "  $($gpu.Name) $($gpu.AdapterRAM / 1GB) GB`n"
        }
        $output += "Storage Media:`n"
        foreach ($disk in $disks) {
            $output += "  $($disk.DeviceID) $([math]::Round($disk.Size / 1GB)) GB`n"
        }
        $output += "Network Configuration:`n"
        foreach ($config in $network) {
            $ipAddress = $config.IPAddress
            $subnetMask = $config.IPSubnet
            $defaultGateway = $config.DefaultIPGateway
            $dnsServers = $config.DNSServerSearchOrder

            if ($ipAddress) {
                $output += "  IP Address: $($ipAddress[0])`n"
            }
            if ($subnetMask) {
                $output += "  Subnet Mask: $($subnetMask[0])`n"
            }
            if ($defaultGateway) {
                $output += "  Default Gateway: $($defaultGateway[0])`n"
            }
            if ($dnsServers) {
                $output += "  DNS Server(s): $($dnsServers -join ', ')`n"
            }
        }
        $output += "----------------------------------------`n"

        Add-Content -Path $outputFile -Value $output
    }
}
