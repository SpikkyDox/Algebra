# Power on machines in ZG-D8, ZG-F1, and ZG-F2 via MeshCentral and native AMT

# Credentials
$meshUsername = "admin"
$meshPassword = "D0br1D3ck1!"
$securePassword = ConvertTo-SecureString $meshPassword -AsPlainText -Force
$amtPassw0rd = "Pa55w.rd" 
$securePassword2 = ConvertTo-SecureString $amtPassw0rd -AsPlainText -Force
$amtCred = New-Object System.Management.Automation.PSCredential ($meshUsername, $securePassword2)

# MeshCentral server info
$serverUrl = "wss://zg-amt-01.ucione.local:444"
$meshCtrlPath = "C:\meshcentral2\node_modules\meshcentral\meshctrl.js"



# List of hardcoded groups  
#  $targetGroups = @("ZG-A6","ZG-C1","ZG-C3","ZG-C5","ZG-C6","ZG-C10","ZG-D6","ZG-D10","ZG-D11","ZG-D12","ZG-F9") 
  # $targetGroups = @("ZG-A6","ZG-C1","ZG-C3","ZG-C5","ZG-C6","ZG-C10","ZG-D6","ZG-D10","ZG-D11","ZG-D12","ZG-F9") 
 #A6.C1.D1.D7.F6.D6
 $targetGroups = @("ZG-D5") 
$meshSwitch = "--amton"
$amtOperation = "PowerOn"

function Get-MeshDevices($groupName) {
    $raw = & node $meshCtrlPath ListDevices --url $serverUrl --loginuser $meshUsername --loginpass $meshPassword
    $devices = @()
    $inGroup = $false
    $skip = 0

    foreach ($line in $raw) {
        if ($line -match "Device group: `"$([regex]::Escape($groupName))`"") {
            $inGroup = $true
            $skip = 2
            continue
        }
        if ($inGroup) {
            if ($skip -gt 0) {
                $skip--
                continue
            }
            if ($line -match '^"([^"]+)",\s+"([^"]+)"') {
                $devices += [PSCustomObject]@{ ID = $matches[1]; IP = $matches[2] }
            }
            elseif ($line -match '^Device group:') {
                break
            }
        }
    }
    return $devices
}

function Invoke-AMTCommand {
    param (
        [string]$ComputerName,
        [PSCredential]$Credential,
        [string]$Operation,
        [int]$TimeoutSeconds = 10
    )
    try {
        Invoke-AMTPowerManagement -ComputerName $ComputerName -Credential $Credential -Operation $Operation -ErrorAction Stop
        Write-Host "SUCCESS: $ComputerName" -ForegroundColor Green
    } catch {
        Write-Host "FAILED: $ComputerName - $_" -ForegroundColor Red
    }
}

foreach ($group in $targetGroups) {
    Write-Host "`n=== Processing group $group ===" -ForegroundColor Cyan

    $devices = Get-MeshDevices -groupName $group
    if ($devices.Count -eq 0) {
        Write-Host "No devices found in group $group" -ForegroundColor Yellow
        continue
    }

    foreach ($dev in $devices) {
        Write-Host "Sending MeshCentral PowerOn to $($dev.IP)..."
        & node $meshCtrlPath DevicePower --url $serverUrl --loginuser $meshUsername --loginpass $meshPassword --id $dev.ID $meshSwitch
    }

    # Native AMT
    $hostList = $devices.IP | Where-Object { $_ -match '\d+\.\d+\.\d+\.\d+' }
    foreach ($pc in $hostList) {
        Invoke-AMTCommand -ComputerName $pc -Credential $amtCred -Operation $amtOperation -TimeoutSeconds 5
    }
}
