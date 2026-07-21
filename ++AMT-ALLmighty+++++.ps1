Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic

# MeshCentral credentials (hardcoded)
$meshUsername = "admin"
$meshPassword = "D0br1D3ck1!"
$amtPassword = "Pa55w.rd"
# Create PSCredential object for AMT credentials with same username/password
$securePassword = ConvertTo-SecureString $amtPassword -AsPlainText -Force
$amtCred = New-Object System.Management.Automation.PSCredential ($meshUsername, $securePassword)

# MeshCentral server details
$serverUrl = "wss://zg-amt-01.ucione.local:444"
$meshCtrlPath = "C:\meshcentral2\node_modules\meshcentral\meshctrl.js"

# AMT actions mapping
$amtActions = @{
    "PowerOn"  = @{ Mesh = "--amton"; Native = "PowerOn" }
    "PowerOff" = @{ Mesh = "--amtoff"; Native = "PowerOff" }
    "Reset"    = @{ Mesh = "--amtreset"; Native = "Reset" }
    "Sleep"    = @{ Mesh = $null; Native = "Sleep" }
    "Hibernate"= @{ Mesh = $null; Native = "Hibernate" }
}

function Get-DeviceGroups {
    $groupsRaw = & node $meshCtrlPath ListDeviceGroups --url $serverUrl --loginuser $meshUsername --loginpass $meshPassword
    $groups = @()
    foreach ($line in $groupsRaw) {
        if ($line -match '^"(.+)",\s+"(.+)"') {
            $groups += [PSCustomObject]@{ ID = $matches[1]; Name = $matches[2] }
        }
    }
    return $groups
}

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
    param(
        [string]$ComputerName,
        [PSCredential]$Credential,
        [string]$Operation,
        [int]$TimeoutSeconds = 15
    )
    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        Invoke-AMTPowerManagement -ComputerName $ComputerName -Credential $Credential -Operation $Operation -ErrorAction Stop
        Write-Host "Success: $ComputerName ($($sw.Elapsed.TotalSeconds.ToString('0.0'))s)" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Host "Failed: $ComputerName - $_" -ForegroundColor Red
        return $false
    }
}

# GUI Form
$form = New-Object System.Windows.Forms.Form
$form.Text = "Combined AMT Power Tool"
$form.Size = New-Object System.Drawing.Size(400,230)
$form.StartPosition = "CenterScreen"

# Group selection
$groupLabel = New-Object System.Windows.Forms.Label
$groupLabel.Text = "Select Device Group:"
$groupLabel.Location = New-Object System.Drawing.Point(10,20)
$groupLabel.Size = New-Object System.Drawing.Size(360,20)
$form.Controls.Add($groupLabel)

$groupCombo = New-Object System.Windows.Forms.ComboBox
$groupCombo.Location = New-Object System.Drawing.Point(10,40)
$groupCombo.Size = New-Object System.Drawing.Size(360,20)
$groupCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
(Get-DeviceGroups) | ForEach-Object { [void]$groupCombo.Items.Add($_.Name) }
$form.Controls.Add($groupCombo)

# Operation selection
$opLabel = New-Object System.Windows.Forms.Label
$opLabel.Text = "Select Power Operation:"
$opLabel.Location = New-Object System.Drawing.Point(10,70)
$opLabel.Size = New-Object System.Drawing.Size(360,20)
$form.Controls.Add($opLabel)

$opCombo = New-Object System.Windows.Forms.ComboBox
$opCombo.Location = New-Object System.Drawing.Point(10,90)
$opCombo.Size = New-Object System.Drawing.Size(360,20)
$opCombo.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$amtActions.Keys | ForEach-Object { [void]$opCombo.Items.Add($_) }
$form.Controls.Add($opCombo)

# Execute button
$goBtn = New-Object System.Windows.Forms.Button
$goBtn.Text = "Execute"
$goBtn.Location = New-Object System.Drawing.Point(150,130)
$goBtn.Size = New-Object System.Drawing.Size(100,30)
$goBtn.Add_Click({
    $selectedGroup = $groupCombo.SelectedItem
    $selectedOp = $opCombo.SelectedItem
    
    if (-not $selectedGroup -or -not $selectedOp) {
        [System.Windows.Forms.MessageBox]::Show("Please select both group and action.", "Missing Info")
        return
    }
    
    $devices = Get-MeshDevices -groupName $selectedGroup
    if ($devices.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No devices in group.", "Error")
        return
    }

    # MeshCentral commands
    $meshSwitch = $amtActions[$selectedOp].Mesh
    if ($meshSwitch) {
        Write-Host "=== MeshCentral Control ===" -ForegroundColor Cyan
        foreach ($dev in $devices) {
            Write-Host "Mesh: $selectedOp on $($dev.IP)..."
            & node $meshCtrlPath DevicePower --url $serverUrl --loginuser $username --loginpass $password --id $dev.ID $meshSwitch
        }
    }

    # Native AMT commands
    Write-Host "`n=== AMT Native Control ===" -ForegroundColor Cyan
    $hostList = $devices.IP | Where-Object { $_ -match '\d+\.\d+\.\d+\.\d+' }
    # Hardcoded AMT credentials
    $amtUsername = "admin"
    $amtPassword = "Pa55w.rd"
    $securePassword = ConvertTo-SecureString $amtPassword -AsPlainText -Force
    $amtCredential = New-Object System.Management.Automation.PSCredential ($amtUsername, $securePassword)
    
    $total = $hostList.Count
    $processed = 0
    
    foreach ($pc in $hostList) {
        $processed++
        Write-Progress -Activity "Processing AMT Commands" -Status "$processed/$total" -PercentComplete (($processed/$total)*100)
        Invoke-AMTCommand -ComputerName $pc -Credential $amtCredential -Operation $amtActions[$selectedOp].Native -TimeoutSeconds 2
    }
    
    Write-Progress -Activity "Processing AMT Commands" -Completed
    [System.Windows.Forms.MessageBox]::Show("Operation complete!", "Done", "OK", "Information")
})
$form.Controls.Add($goBtn)

$form.ShowDialog()
