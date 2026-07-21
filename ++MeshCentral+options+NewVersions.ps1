Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic

# MeshCentral credentials
$cred = Get-Credential -Message "Enter MeshCentral credentials"
$username = $cred.UserName
$password = $cred.GetNetworkCredential().Password

# MeshCentral server details
$serverUrl = "wss://zg-amt-01.ucione.local:444"
$meshCtrlPath = "C:\meshcentral2\node_modules\meshcentral\meshctrl.js"

# Available AMT actions
$amtActions = @(
    @{ Name = "Power On (AMT On)"; Switch = "--amton" },
    @{ Name = "Power Off (AMT Off)"; Switch = "--amtoff" },
    @{ Name = "Reset (AMT Reset)"; Switch = "--amtreset" }
)

# Function to get device groups
function Get-DeviceGroups {
    $groupsRaw = & node $meshCtrlPath ListDeviceGroups --url $serverUrl --loginuser $username --loginpass $password
    $groups = @()
    
    foreach ($line in $groupsRaw) {
        if ($line -match '^"(.+)",\s+"(.+)"') {
            $groups += [PSCustomObject]@{
                ID = $matches[1]
                Name = $matches[2]
            }
        }
    }
    return $groups
}

# Function to get devices in group with proper parsing
function Get-DevicesInGroup($groupName) {
    $devicesRaw = & node $meshCtrlPath ListDevices --url $serverUrl --loginuser $username --loginpass $password
    $devices = @()
    $foundGroup = $false
    $skipLines = 0

    foreach ($line in $devicesRaw) {
        if ($line -match "Device group: ""$groupName""") {
            $foundGroup = $true
            $skipLines = 2  # Skip header and separator
            continue
        }
        
        if ($foundGroup) {
            if ($skipLines -gt 0) {
                $skipLines--
                continue
            }
            
            if ($line -match '^"([^"]+)",\s+"([^"]+)"') {
                $devices += [PSCustomObject]@{
                    ID = $matches[1]
                    IP = $matches[2]
                }
            }
            elseif ($line -match '^Device group:') {
                break  # Stop at next group
            }
        }
    }
    return $devices
}

# Main script
$groups = Get-DeviceGroups

# Create group selection form
$form = New-Object System.Windows.Forms.Form
$form.Text = "MeshCentral AMT Control"
$form.Size = New-Object System.Drawing.Size(400,200)
$form.StartPosition = "CenterScreen"

# Device group selection
$groupLabel = New-Object System.Windows.Forms.Label
$groupLabel.Location = New-Object System.Drawing.Point(10,20)
$groupLabel.Size = New-Object System.Drawing.Size(360,20)
$groupLabel.Text = "Select a device group:"
$form.Controls.Add($groupLabel)

$groupComboBox = New-Object System.Windows.Forms.ComboBox
$groupComboBox.Location = New-Object System.Drawing.Point(10,40)
$groupComboBox.Size = New-Object System.Drawing.Size(360,20)
$groupComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$groups | ForEach-Object { [void] $groupComboBox.Items.Add($_.Name) }
$form.Controls.Add($groupComboBox)

# Action selection
$actionLabel = New-Object System.Windows.Forms.Label
$actionLabel.Location = New-Object System.Drawing.Point(10,70)
$actionLabel.Size = New-Object System.Drawing.Size(360,20)
$actionLabel.Text = "Select a power action:"
$form.Controls.Add($actionLabel)

$actionComboBox = New-Object System.Windows.Forms.ComboBox
$actionComboBox.Location = New-Object System.Drawing.Point(10,90)
$actionComboBox.Size = New-Object System.Drawing.Size(360,20)
$actionComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$amtActions | ForEach-Object { [void] $actionComboBox.Items.Add($_.Name) }
$form.Controls.Add($actionComboBox)

# OK button
$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(150,130)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = "OK"
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

# Process selection
if ($form.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $selectedGroupName = $groupComboBox.SelectedItem
    $selectedActionName = $actionComboBox.SelectedItem
    $selectedAction = $amtActions | Where-Object { $_.Name -eq $selectedActionName }
    $amtSwitch = $selectedAction.Switch

    $devices = Get-DevicesInGroup -groupName $selectedGroupName
    
    if ($devices.Count -gt 0) {
        foreach ($device in $devices) {
            Write-Host "Sending $selectedActionName to $($device.IP) ($($device.ID))..."
            try {
                & node $meshCtrlPath DevicePower --url $serverUrl --loginuser $username --loginpass $password --id $device.ID $amtSwitch
                Write-Host "Successfully sent $selectedActionName to $($device.IP)" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to send $selectedActionName to $($device.IP): $_" -ForegroundColor Red
            }
        }
    }
    else {
        [Microsoft.VisualBasic.Interaction]::MsgBox("No devices found in selected group.", "OKOnly,SystemModal", "Error")
    }
}
else {
    Write-Host "Operation cancelled by user."
}
