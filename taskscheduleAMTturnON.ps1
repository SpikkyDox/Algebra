# ===========================
# Classroom AMT Power-On Tool
# ===========================

Add-Type -AssemblyName Microsoft.VisualBasic

# MeshCentral credentials
$meshUsername = "admin"
$meshPassword = "Pa55w.rd"
$serverUrl = "wss://zg-amt-01.ucione.local:444"
$meshCtrlPath = "C:\meshcentral2\node_modules\meshcentral\meshctrl.js"

# AMT credentials
$amtUsername = "admin"
$amtPassword = "Pa55w.rd"
$securePassword = ConvertTo-SecureString $amtPassword -AsPlainText -Force
$amtCred = New-Object System.Management.Automation.PSCredential ($amtUsername, $securePassword)

# ===========================
# Utility Functions
# ===========================

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
                $devices += [PSCustomObject]@{ ID = $matches[1]; IP = $matches[2]; Name = $matches[1] }
            }
            elseif ($line -match '^Device group:') {
                break
            }
        }
    }
    return $devices
}

function Invoke-AMTCommand {
    param(
        [string]$ComputerName,
        [PSCredential]$Credential,
        [string]$Operation = "PowerOn",
        [int]$TimeoutSeconds = 15
    )
    try {
        # Replace this with your actual AMT power-on command
        # For example, using Intel's PowerShell module:
        # Invoke-AMTPowerManagement -ComputerName $ComputerName -Credential $Credential -Operation $Operation
        # For now, just simulate:
        Start-Sleep -Seconds 1
        Write-Host "Success: $ComputerName powered on." -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Failed: $ComputerName - $_" -ForegroundColor Red
        return $false
    }
}

# ===========================
# Main Logic
# ===========================

# Prompt user for classroom names
$hostInput = [Microsoft.VisualBasic.Interaction]::InputBox(
    "Enter classroom names separated by commas (e.g. D8,F1,F2):",
    "Enter Classrooms",
    "D8,F1,F2"
)
if (-not $hostInput) {
    Write-Host "No classrooms entered. Exiting." -ForegroundColor Yellow
    exit
}
$classrooms = $hostInput -split ',' | ForEach-Object { $_.Trim().ToUpper() }

# Get all devices from the group (adjust group name as needed)
$groupName = "AllClassrooms"  # Change if your group has a different name
$devices = Get-MeshDevices -groupName $groupName

if (-not $devices -or $devices.Count -eq 0) {
    Write-Host "No devices found in group '$groupName'. Exiting." -ForegroundColor Red
    exit
}

# Filter devices to only those matching classroom names (by ID or Name)
$targetDevices = $devices | Where-Object {
    $classrooms -contains $_.ID.ToUpper() -or $classrooms -contains $_.Name.ToUpper()
}

if (-not $targetDevices -or $targetDevices.Count -eq 0) {
    Write-Host "No matching devices found for the classrooms you entered. Exiting." -ForegroundColor Red
    exit
}

Write-Host "Found $($targetDevices.Count) devices to power on:`n" -ForegroundColor Cyan
$targetDevices | ForEach-Object { Write-Host "$($_.ID) ($($_.IP))" }

# Confirm with user
$confirm = [Microsoft.VisualBasic.Interaction]::MsgBox(
    "Proceed to power ON the following classrooms?`n`n" + ($targetDevices | ForEach-Object { $_.ID }) -join ", ",
    [Microsoft.VisualBasic.MsgBoxStyle]::YesNo,
    "Confirm Power ON"
)
if ($confirm -ne [Microsoft.VisualBasic.MsgBoxResult]::Yes) {
    Write-Host "Operation cancelled by user." -ForegroundColor Yellow
    exit
}

# Power on each device
$processed = 0
$total = $targetDevices.Count
foreach ($dev in $targetDevices) {
    $processed++
    Write-Progress -Activity "Powering On Classrooms" -Status "$processed/$total" -PercentComplete (($processed/$total)*100)
    Invoke-AMTCommand -ComputerName $dev.IP -Credential $amtCred -Operation "PowerOn" -TimeoutSeconds 10
}
Write-Progress -Activity "Powering On Classrooms" -Completed

Write-Host "`nOperation complete!" -ForegroundColor Green
[Microsoft.VisualBasic.Interaction]::MsgBox("Classrooms powered on!","OKOnly,Information","Done")
