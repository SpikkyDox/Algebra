# Script: Test-Network.ps1
# Run as Administrator on management PC

$HostFile = "C:\GitHub\Hosts\ZG-F3.txt"
$Hosts = Get-Content $HostFile | Where-Object { $_ -match "^\S+" }   # all non-empty lines

foreach ($Computer in $Hosts) {
    Write-Host "==== Testing $Computer ====" -ForegroundColor Cyan
    try {
        Invoke-Command -ComputerName $Computer -ScriptBlock {
            $result = [PSCustomObject]@{
                Computer   = $env:COMPUTERNAME
                PingLoss   = $null
                AvgLatency = $null
                SpeedMbps  = $null
            }

            # Test stability (ping 8.8.8.8)
            $ping = Test-Connection -ComputerName "8.8.8.8" -Count 10 -ErrorAction SilentlyContinue
            if ($ping) {
                $result.PingLoss   = 10 - $ping.Count
                $result.AvgLatency = [math]::Round(($ping | Measure-Object ResponseTime -Average).Average,2)
            } else {
                $result.PingLoss   = "All lost"
                $result.AvgLatency = "N/A"
            }

            # Rough speed check (download small file and measure time)
            $url = "http://ipv4.download.thinkbroadband.com/10MB.zip"
            $temp = "$env:TEMP\speedtest.tmp"
            try {
                $time = Measure-Command {
                    Invoke-WebRequest -Uri $url -OutFile $temp -UseBasicParsing -ErrorAction Stop
                }
                $sizeMB = (Get-Item $temp).Length / 1MB
                $seconds = $time.TotalSeconds
                if ($seconds -gt 0) {
                    $result.SpeedMbps = [math]::Round(($sizeMB * 8) / $seconds,2)
                }
                Remove-Item $temp -ErrorAction SilentlyContinue
            }
            catch {
                $result.SpeedMbps = "Failed"
            }

            return $result
        } -ErrorAction Stop | Format-Table -AutoSize
    }
    catch {
        Write-Host "Failed to connect to $Computer : $_" -ForegroundColor Red
    }
}
