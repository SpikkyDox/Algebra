Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName Microsoft.VisualBasic

# MeshCentral credentials
$cred = Get-Credential -Message "Enter MeshCentral credentials"
$username = $cred.UserName
$password = $cred.GetNetworkCredential().Password

# MeshCentral server details
$serverUrl = "wss://zg-amt-01.ucione.local:444"
$meshCtrlPath = "C:\meshcentral2\node_modules\meshcentral\meshctrl.js"

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
$form.Text = "Select Device Group"
$form.Size = New-Object System.Drawing.Size(400,150)
$form.StartPosition = "CenterScreen"

$label = New-Object System.Windows.Forms.Label
$label.Location = New-Object System.Drawing.Point(10,20)
$label.Size = New-Object System.Drawing.Size(360,20)
$label.Text = "Select a device group:"
$form.Controls.Add($label)

$comboBox = New-Object System.Windows.Forms.ComboBox
$comboBox.Location = New-Object System.Drawing.Point(10,40)
$comboBox.Size = New-Object System.Drawing.Size(360,20)
$comboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$groups | ForEach-Object { [void] $comboBox.Items.Add($_.Name) }
$form.Controls.Add($comboBox)

$okButton = New-Object System.Windows.Forms.Button
$okButton.Location = New-Object System.Drawing.Point(150,80)
$okButton.Size = New-Object System.Drawing.Size(75,23)
$okButton.Text = "OK"
$okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
$form.AcceptButton = $okButton
$form.Controls.Add($okButton)

# Show form and process selection
if ($form.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $selectedGroupName = $comboBox.SelectedItem
    $devices = Get-DevicesInGroup -groupName $selectedGroupName
    
    if ($devices.Count -gt 0) {
        foreach ($device in $devices) {
            Write-Host "Powering on $($device.IP) ($($device.ID))..."
            try {
                & node $meshCtrlPath DevicePower --url $serverUrl --loginuser $username --loginpass $password --id $device.ID --reset
                Write-Host "Successfully sent power command to $($device.IP)" -ForegroundColor Green
            }
            catch {
                Write-Host "Failed to power on $($device.IP): $_" -ForegroundColor Red
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
