$Path = "E:\Sime\Hosts\ZG-D10.txt"
$notepadFiles = Get-ChildItem -Path $Path -Filter "*.txt"
$outputFile = "E:\2023-Q4\Zagreb\ZG-C2\D10"

foreach ($notepadFile in $notepadFiles) {
    Write-Host "Reading hosts from $notepadFile..."
    $computerList = Get-Content $notepadFile.FullName
    
    foreach ($computerName in $computerList) {
        Write-Host "Getting hardware information for $computerName..."
        $hardware = Get-WmiObject -Class Win32_ComputerSystem -ComputerName $computerName
        $cpus = Get-WmiObject -Class Win32_Processor -ComputerName $computerName
        $gpus = Get-WmiObject -Class Win32_VideoController -ComputerName $computerName
        $disks = Get-WmiObject -Class Win32_LogicalDisk -ComputerName $computerName -Filter "DriveType = '3'"
        $network = Get-WmiObject -Class Win32_NetworkAdapterConfiguration -ComputerName $computerName | Where-Object { $_.IPAddress -ne $null }

        $bios = Get-WmiObject -Class Win32_BIOS -ComputerName $computerName
        $serialNumber = "N/A"
        if ($bios) {
            $serialNumber = $bios.SerialNumber
        }

        $output = @"
Host Name: $computerName
Serial Number: $serialNumber
Manufacturer: $($hardware.Manufacturer)
Model: $($hardware.Model)
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
            $diskSizeGB = [math]::Round($disk.Size / 1GB)
            $freeSpaceGB = [math]::Round($disk.FreeSpace / 1GB)
            $usedSpacePercent = ($diskSizeGB - $freeSpaceGB) / $diskSizeGB * 100
            $output += "  $($disk.DeviceID) Size: $diskSizeGB GB - Free Space: $freeSpaceGB GB - Used: $($usedSpacePercent.ToString('0.00'))%`n"
        }
        $output += "Network Configuration:`n"
        foreach ($config in $network) {
            $ipAddress = $config.IPAddress
            $subnetMask = $config.IPSubnet
            $defaultGateway = $config.DefaultIPGateway
            $dnsServers = $config.DNSServerSearchOrder
            $macAddress = $config.MACAddress

            if ($macAddress) {
                $output += "  MAC Address: $macAddress`n"
            }
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
