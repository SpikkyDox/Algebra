$Path = $PSScriptRoot
Write-Host "`n`n------------- Login as domain administrator account to proceed -------------`n`n" -ForegroundColor Green 
while(1) {
    $ErrorActionPreference = "SilentlyContinue"
    $Cred = Get-Credential -Message " " -UserName ucione\administrator
    $Confirmation=Invoke-Command -ComputerName ili-wsus -ScriptBlock {
        $Confirmation = 1
        Return $Confirmation
    } -Credential $Cred
    if($Confirmation -eq 1) {break}
    else {Write-Host "`n----------------- Failed authentication, please try again ------------------`n" -ForegroundColor Red}
}
$AMTPassword = ConvertTo-SecureString "Pa55w.rd" -AsPlainText -Force
$AMTCred = New-Object System.Management.Automation.PSCredential ("admin", $AMTPassword)

Add-Type -assembly System.Windows.Forms
$GUI = New-Object System.Windows.Forms.Form
$GUI.Text ="Enabler GUI"
$GUI.Width = 256
$GUI.Height = 256
$GUI.FormBorderStyle = "Fixed3D"
$GUI.MaximizeBox = $false
$GUI.StartPosition = "CenterScreen"
$GUI.TopMost = $true
$GUI.Focused = $true
$GUI.BackColor = "Black"
$GUI.AutoSize = $true

$Copyright = New-Object System.Windows.Forms.Label
$Copyright.Location = New-Object System.Drawing.Point(10,256)
$Copyright.AutoSize = $true
$Copyright.Text = ""
$Copyright.ForeColor="Yellow"
$Copyright.Font = New-Object System.Drawing.Font("Comic Sans MS",10,[System.Drawing.FontStyle]::Bold)
$GUI.Controls.Add($Copyright)

$Logo = new-object Windows.Forms.PictureBox
$Image = [System.Drawing.Image]::Fromfile((Get-Item $Path\Resources\Logo.png))
$Logo.Image = $Image
$Logo.Location = New-Object System.Drawing.Point(250,244)
$GUI.Controls.Add($Logo)

$HostsL = New-Object System.Windows.Forms.Label
$HostsL.Location = New-Object System.Drawing.Point(10,12)
$HostsL.AutoSize = $true
$HostsL.Text = "Choose Hosts:"
$HostsL.ForeColor="Yellow"
$HostsL.Font = New-Object System.Drawing.Font("Comic Sans MS",15,[System.Drawing.FontStyle]::Bold)
$GUI.Controls.Add($HostsL)

$HostBox = New-Object System.Windows.Forms.ComboBox
$HostBox.Width = 75
$Hosts = (Get-ChildItem -Path $Path\Resources\Hosts).BaseName
foreach ($Group in $Hosts)
{
    $HostBox.Items.Add($Group) | Out-Null

}
$HostBox.Location = New-Object System.Drawing.Point(160,15)
$HostBox.Font = New-Object System.Drawing.Font("Comic Sans MS",10,[System.Drawing.FontStyle]::Bold)
$HostBox.SelectedIndex = 0
$GUI.Controls.Add($HostBox)

$OperationL = New-Object System.Windows.Forms.Label
$OperationL.Location = New-Object System.Drawing.Point(10,70)
$OperationL.Font = New-Object System.Drawing.Font("Comic Sans MS",15,[System.Drawing.FontStyle]::Bold)
$OperationL.AutoSize = $true
$OperationL.Text = "Choose Operation:"
$OperationL.ForeColor="Yellow"
$GUI.Controls.Add($OperationL)

$OperationBox = New-Object System.Windows.Forms.ComboBox
$OperationBox.Width = 120
$OperationBox.Font = New-Object System.Drawing.Font("Comic Sans MS",10,[System.Drawing.FontStyle]::Bold)
$Operations = @('PowerOn','Install','Uninstall','Features','Boot','AllPrograms','VMImport','VMExists','VMRemove','SoftwareExists','WinActivation','WinStatus','ProjectRearm','GPUpdate','AddLanguage','RemoveProfile','DiskCleanup','Restart','Shutdown')
foreach ($Operation in $Operations)
{
    $OperationBox.Items.Add($Operation) | Out-Null
}
$OperationBox.Location = New-Object System.Drawing.Point(200,73)
$OperationBox.SelectedIndex = 0
$GUI.Controls.Add($OperationBox)

$AdditionalL = New-Object System.Windows.Forms.Label
$AdditionalL.Location = New-Object System.Drawing.Point(10,130)
$AdditionalL.AutoSize = $true
$AdditionalL.Text = "Additional Paramter:"
$AdditionalL.ForeColor="Yellow"
$AdditionalL.Visible = $false
$AdditionalL.Font = New-Object System.Drawing.Font("Comic Sans MS",14,[System.Drawing.FontStyle]::Bold)
$GUI.Controls.Add($AdditionalL)

$AdditionalBox = New-Object System.Windows.Forms.ComboBox
$AdditionalBox.Width = 130
$AdditionalBox.Location = New-Object System.Drawing.Point(215,133)
$AdditionalBox.Visible = $false
$AdditionalBox.Font = New-Object System.Drawing.Font("Comic Sans MS",10,[System.Drawing.FontStyle]::Bold)
$GUI.Controls.Add($AdditionalBox)

$Execute = New-Object System.Windows.Forms.Button
$Execute.Location = New-Object System.Drawing.Size(27,195)
$Execute.AutoSize = $true
$Execute.Width = 300
$Execute.Text = "Execute Command"
$Execute.BackColor = "Orange"
$Execute.ForeColor = "Black"
$Execute.Font = New-Object System.Drawing.Font("Comic Sans MS",14,[System.Drawing.FontStyle]::Bold)
$GUI.Controls.Add($Execute)

$ExecuteL = New-Object System.Windows.Forms.Label
$ExecuteL.Location = New-Object System.Drawing.Point(120,170)
$ExecuteL.AutoSize = $true
$ExecuteL.Text = "Script Ready"
$ExecuteL.ForeColor="Cyan"
$ExecuteL.Font = New-Object System.Drawing.Font("Comic Sans MS",12,[System.Drawing.FontStyle]::Bold)
$GUI.Controls.Add($ExecuteL)

$OperationBox.Add_SelectedIndexChanged({
    $AdditionalBox.Items.Clear()
    $AdditionalList = @('Install','Uninstall','Features','Boot','VMImport','VMExists','VMRemove','SoftwareExists','AddLanguage','RemoveProfile')
    if($OperationBox.Text -in $AdditionalList) {
        $AdditionalL.Visible=$true
        $AdditionalL.ForeColor = "Yellow"
        $AdditionalBox.Visible=$true
        switch($OperationBox.Text) {
            "Install" {
                $AdditionalBox.Text = ""
                $AdditionalL.Text = "Software to install:"
                $Installations = (Get-ChildItem -Path $Path\Resources\Installations).BaseName
                foreach ($Installation in $Installations)
                {
                    $AdditionalBox.Items.Add($Installation) | Out-Null
                }
                $AdditionalBox.SelectedIndex = 0
            }
            "Uninstall" {
                $Choice = $HostBox.Text
                $Hosts = Get-Content "$Path\Resources\Hosts\$Choice.txt"
                $Lecturer = $Hosts[0]
                if(Test-Path "\\$Lecturer\D$") {
                    $AdditionalBox.Text = ""
                    $AdditionalL.Text = "Software to remove:"
                    $Choice = $HostBox.Text
                    $Packages = Invoke-Command -ComputerName $Hosts[0] -ScriptBlock {
                        return Get-Package -Provider Programs -IncludeWindowsInstaller -Name "*" | Where-Object -Property Name -NotLike "Microsoft*" | Where-Object -Property Name -NotLike "Realtek*" | Where-Object -Property Name -NotLike "Windows*" | Where-Object -Property Name -NotLike "Nvidia*"
                    } -Credential $Cred
                    foreach ($Package in $Packages) {
                        $AdditionalBox.Items.Add($Package.Name) | Out-Null
                    }
                    $AdditionalBox.SelectedIndex = 0
                    Write-Host "`nAvailiable package uninstallation (Type package name under software name) - " -ForegroundColor Yellow -NoNewline
                    Write-Host "Minitool" -ForegroundColor Cyan
                }
                else {
                    $AdditionalBox.Visible = $false
                    $AdditionalL.Text = "Lecturer is turned off"
                    $AdditionalL.ForeColor = "Red"
                }
            }
            "Features" {
                $AdditionalBox.Text = ""
                $AdditionalL.Text = "Feature to install:"
                $Features = @('Hyper-V','Linux')
                foreach ($Feature in $Features)
                {
                    $AdditionalBox.Items.Add($Feature) | Out-Null
                }
                $AdditionalBox.SelectedIndex = 0
            }
            "Boot" {
                $AdditionalBox.Text = ""
                $AdditionalL.Text = "Boot VHD to add:"
                $VHDs = (Get-ChildItem -Path $Path\Resources\VHD).BaseName
                foreach ($VHD in $VHDs)
                {
                    $AdditionalBox.Items.Add($VHD) | Out-Null
                }
                $AdditionalBox.Items.Add("CEHv11")
                $AdditionalBox.SelectedIndex = 0   
            }
            "VMImport" {
                $AdditionalBox.Text = ""
                $AdditionalL.Text = "VM to import:"
                $VMs = (Get-ChildItem -Path $Path\Resources\VM).BaseName
                foreach ($VM in $VMs)
                {
                    $AdditionalBox.Items.Add($VM) | Out-Null
                }
                $AdditionalBox.SelectedIndex = 0                   
            }
            "VMExists" {
                $AdditionalBox.Text = ""
                $AdditionalL.Text = "VM to search:"
            }
            "VMRemove" {
                $Choice = $HostBox.Text
                $Hosts = Get-Content "$Path\Resources\Hosts\$Choice.txt"
                $Lecturer = $Hosts[0]
                if(Test-Path "\\$Lecturer\D$") {
                    $AdditionalBox.Text = ""
                    $AdditionalL.Text = "VM to remove:"
                    $VMs = Invoke-Command -ComputerName $Hosts[0] -ScriptBlock {
                        Return Get-VM
                    } -Credential $Cred
                    foreach ($VM in $VMs)
                    {
                        $AdditionalBox.Items.Add($VM.Name) | Out-Null
                    }
                    $AdditionalBox.SelectedIndex = 0
                }
                else {
                    $AdditionalBox.Visible = $false
                    $AdditionalL.Text = "Lecturer is turned off"
                    $AdditionalL.ForeColor = "Red"
                }  
            }
            "SoftwareExists" {
                $AdditionalBox.Text = ""
                $AdditionalL.Text = "Software to search:"
            }
            "AddLanguage" {
                $AdditionalL.Text = "Keyboard to add:"
                $AdditionalBox.Text = ""
                $Languages = @('hr-HR','en-US','en-GB')
                foreach ($Language in $Languages)
                {
                    $AdditionalBox.Items.Add($Language) | Out-Null
                }
                $AdditionalBox.SelectedIndex = 0 
            }
            "RemoveProfile" {
                $AdditionalL.Text = "Profile to delete:"
                $AdditionalBox.Text = ""
                $Profiles = @('Administrator','grafika10','vuaispit', 'hyperv','office10','programer10','acad10','console8','All')   
                foreach ($Profile in $Profiles)
                {
                    $AdditionalBox.Items.Add($Profile) | Out-Null
                }
                $AdditionalBox.SelectedIndex = 0      
            }
        }
    }
    else {
        $AdditionalL.Visible=$false
        $AdditionalBox.Visible=$false
    }
}
)

$Execute.Add_Click(
{
    $ExecuteL.Text = "Script Running..."
    $ExecuteL.ForeColor = "Red"
    Sleep 1
    Write-Host "`nOperation started - Please Wait" -ForegroundColor Cyan
    $Choice = $HostBox.Text
    if(Test-Path "$Path\Resources\Hosts\$Choice.txt") {
        $Hosts = Get-Content "$Path\Resources\Hosts\$Choice.txt"
        $Operations = @('PowerOn','Install','Uninstall','Features','Boot','AllPrograms','VMImport','VMExists','VMRemove','SoftwareExists','WinActivation','WinStatus','ProjectRearm','GPUpdate','AddLanguage','RemoveProfile','DiskCleanup','Restart','Shutdown','Exit')
        if($OperationBox.Text -in $Operations) {
            $Operation = $OperationBox.Text
            switch ($Operation) {
                    PowerOn {
                        foreach ($PC in $Hosts) {
                            Write-Host "`nPowering on $PC..." -ForegroundColor Yellow  
                            Invoke-AMTPowerManagement $PC -Credential $AMTCred -Operation PowerOn
                        }
                    }
                    Install {
                        $Choice = $AdditionalBox.Text
                        if(Test-Path "$Path\Resources\Installations\$Choice.*") {
                                $Extension = (Get-ChildItem -Path $Path\Resources\Installations\$Choice.*).Extension
                                foreach ($PC in $Hosts) {
                                    Write-Host "`nInstalling on $PC..." -ForegroundColor Yellow
                                    Copy-Item -Path "$Path\Resources\Installations\$Choice.*" -Destination "\\$PC\C$"
                                    if ($Extension -eq ".exe") {
                                        if($Choice -eq "DockerDesktop") {
                                            Get-WindowsOptionalFeature -Online | Where-Object {$_.FeatureName -like "*linux*"} | Enable-WindowsOptionalFeature -Online -NoRestart 
                                            Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC "C:\$Choice.exe" install --quiet} 2> $null
                                        }
                                        elseif($Choice -eq "MiniTool") {
                                            Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC C:\$Choice.exe /S /VERYSILENT /SUPPRESSMSGBOXES /NORESTART} 2> $null
                                            Invoke-Command -ComputerName $PC -ScriptBlock {
                                                Get-Process -Name partitionwizard | Stop-Process -Force
                                            } -Credential $Cred
                                        }
                                        elseif($Choice -eq "DockerUpdate") {
                                            Copy-Item -Path "$Path\Resources\Installations\DockerUpdate.msi" -Destination "\\$PC\C$"
                                            Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC MsiExec.exe /package C:\$DockerUpdate.msi /quiet} 2> $null
                                            Invoke-Command -Computer $PC -ScriptBlock {
                                                Add-LocalGroupMember -Group "docker-users" -Member "ucione\hyperv"
                                                wsl.exe --set-default-version 2
                                            } -Credential $Cred
                                            Remove-Item "\\$PC\C$\DockerUpdate.msi"                       
                                        }
                                        elseif ($Choice -eq "tableau") {
                                            Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC C:\$Choice.exe /quiet /norestart ACCEPTEULA=1} 2> $null
                                        }
                                        elseif ($Choice -eq "tableauprep") {
                                            Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC C:\$Choice.exe /quiet /norestart ACCEPTEULA=1} 2> $null
                                        }
                                        elseif ($Choice -eq "nodexl") {  
                                            Copy-Item -Path "$Path\Resources\Installations\$Choice.*" -Destination "\\$PC\D$"
                                            Copy-Item -Path "$Path\Resources\Installations\$Choice.*" -Destination "\\$PC\E$"       
                                        }
                                        elseif ($Choice -eq "python") {
                                            Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC C:\$Choice.exe /quiet InstallAllUsers=1 PrependPath=1} 2>$null
                                        }  
                                        elseif ($Choice -eq "pycharm") {
                                            Copy-Item -Path "$Path\Resources\Installations\pysilent.config" -Destination "\\$PC\C$"
                                            Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC C:\pycharm.exe /S /CONFIG=C:\pysilent.config /D=c:\IDE\PyCharm Edu} 2>$null
                                            Remove-Item "\\$PC\C$\pysilent.config"
                                        }                                
                                        elseif ($Choice -eq "pureref") {
                                            Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC C:\$Choice.exe /SD /S /VERYSILENT /SUPPRESSMSGBOXES /NORESTART /i /q} 2> $null 
                                        }
                                        elseif ($Choice -eq "powerbi") {
                                            Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC C:\$Choice.exe -q -norestart ACCEPT_EULA=1} 2> $null   
                                        }
                                        elseif ($Choice -eq "davinci") {
                                            Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC C:\$Choice.exe /i /q} 2> $null   
                                        }
                                        else {
                                            Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC C:\$Choice.exe /S /VERYSILENT /SUPPRESSMSGBOXES /NORESTART} 2> $null
                                        }
                                    3}
                                    elseif ($Extension -eq ".msi") {
                                        Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC MsiExec.exe /i C:\$Choice.msi ALLUSERS=1 /qn} 2> $null
                                    }
                                    Remove-Item -Path "\\$PC\C$\$Choice.*" -Recurse
                                }
                        }
                        elseif ($Choice -eq "Adobe2022") {
                            foreach ($PC in $Hosts) {
                                Write-Host "`nInstalling on $PC..." -ForegroundColor Yellow  
                                Copy-Item "$Path\Resources\Installations\$Choice" -Destination "\\$PC\D$" -Recurse        
                                Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -s -h -accepteula \\$PC D:\Adobe2022\Build\setup.exe --silent} 2> $null
                                Remove-Item "\\$PC\D$\$Choice" -Recurse -Force
                            }
                        }
                        elseif ($Choice -eq "AdobeBruno") {
                            foreach ($PC in $Hosts) {
                                Write-Host "`nInstalling on $PC..." -ForegroundColor Yellow
                                Copy-Item "$Path\Resources\Installations\$Choice" -Destination "\\$PC\D$" -Recurse
                                $Packages = Get-ChildItem "\\$PC\D$\AdobeBruno\"
                                foreach ($Package in $Packages) {
                                    if($Package -eq "XD") {
                                        if(Test-Path "\\$PC\C$\Users\Administrator.UCIONE\AppData\Local\Packages\Adobe.CC.XD_adky2gkssdxte") {
                                            Write-Host "`nInstalling $Package..." -ForegroundColor Red
                                        }
                                        else {
                                            Write-Host "`nInstalling $Package..." -ForegroundColor Red
                                            Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -s -h -accepteula \\$PC D:\AdobeBruno\$Package\set-up.exe} 2> $null
                                        }    
                                    }
                                    else {
                                        Write-Host "`nInstalling $Package..." -ForegroundColor Red
                                        Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -s -h -accepteula \\$PC D:\AdobeBruno\$Package\set-up.exe} 2> $null                                  
                                    }
                                }
                                Remove-Item "\\$PC\D$\AdobeBruno" -Recurse         
                            }
                        }
                        elseif ($Choice -eq "FME") {
                            foreach ($PC in $Hosts) {
                                Write-Host "`nInstalling on $PC..." -ForegroundColor Yellow
                                Copy-Item "$Path\Resources\Installations\$Choice" -Destination "\\$PC\C$" -Recurse    
                            }    
                        }
                        else {
                            Write-Host "`n$Choice is not an option!" -ForegroundColor Red
                        }
                    }
                    Uninstall {
                        $Choice=$AdditionalBox.Text
                        foreach ($PC in $Hosts) {
                            Write-Host "`nUninstalling from $PC..." -ForegroundColor Yellow -NoNewline
                            if($Choice -eq "MiniTool") {
                                Invoke-Command -ComputerName $PC -ScriptBlock {
                                    Get-Process -Name partitionwizard -ErrorAction SilentlyContinue | Stop-Process -Force
                                } -Credential $Cred
                                $String = Invoke-Command -ComputerName $PC -ScriptBlock {
                                    $ErrorActionPreference = "SilentlyContinue"
                                    $ToDelete= Get-Package -Provider Programs -IncludeWindowsInstaller -Name "*minitool partition*"
                                    $String= $ToDelete.Meta.Attributes["UninstallString"]
                                    Return $String
                                }
                                if([string]$String -ne "") {
                                    Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC -h "$String" /S /VERYSILENT /SUPPRESSMSGBOXES /NORESTART} 2> $null
                                }
                                else {
                                    Write-Host "Minitool Partition Wizard package not found on $PC" -ForegroundColor Red
                                }
                                $String2 = Invoke-Command -ComputerName $PC -ScriptBlock {
                                    $ErrorActionPreference = "SilentlyContinue"
                                    $ToDelete= Get-Package -Provider Programs -IncludeWindowsInstaller -Name "*shadowmaker*"
                                    $String= $ToDelete.Meta.Attributes["UninstallString"]
                                    Return $String
                                }
                                if([string]$String2 -ne "") {
                                    Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC -h "$String2" /S /VERYSILENT /SUPPRESSMSGBOXES /NORESTART} 2> $null       
                                }
                                else {
                                    Write-Host "Shadowmaker package not found on $PC" -ForegroundColor Red
                                }
                            }
                            else {
                                $String = Invoke-Command -ComputerName $PC -ScriptBlock {
                                    $ToDelete= Get-Package -Provider Programs -IncludeWindowsInstaller -Name "*$using:Choice*" -ErrorAction SilentlyContinue
                                    $String= $ToDelete.Meta.Attributes["UninstallString"]
                                    Return $String
                                }
                                if([string]$String -ne "") {
                                    Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC -h "$String" /S /VERYSILENT /SUPPRESSMSGBOXES /NORESTART} 2> $null
                                }
                                else {
                                    Write-Host "$Choice package not found on $PC" -ForegroundColor Red
                                }
                            }
                        }
                    }
                    Features {
                        $Choice=$AdditionalBox.Text
                        foreach ($PC in $Hosts) {
                            Write-Host "`nAdding feature on $PC..." -ForegroundColor Yellow
                            Invoke-Command -ComputerName $PC -ScriptBlock {
                                Get-WindowsOptionalFeature -Online | Where-Object {$_.FeatureName -like "*$using:Choice*"} | Enable-WindowsOptionalFeature -Online -NoRestart 
                            } -Credential $Cred 
                        }
                    }
                    Boot {
                        $Choice=$AdditionalBox.Text
                        if((Test-Path "$Path\Resources\VHD\$Choice.*") -Or ($Choice -eq "CEHv11")) {
                            $Name=$AdditionalBox.Text
                            foreach ($PC in $Hosts) {
                                Write-Host "`nAdding boot on $PC..." -ForegroundColor Yellow
                                if(Test-Path -Path "\\$PC\D$\$Choice.vhd") {
                                    Write-Host "`nVHD already present on drive" -ForegroundColor Cyan
                                }
                                elseif($Choice -eq "CEHv11") {
                                    Copy-Item -Path "\\ZG-D9-00\G$\CEHv11.vhd" -Destination "\\$PC\G$\"    
                                }
                                else {
                                    Copy-Item -Path "$Path\Resources\VHD\$Choice.vhd" -Destination "\\$PC\D$\"
                                }
                                Invoke-Command -ComputerName $PC -ScriptBlock {
                                    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart
                                    if($using:Choice -eq "CEHv11") {
                                        $DriveLetter = (Mount-VHD -Path "G:\$using:Choice.vhd" -PassThru | Get-Disk | Get-Partition | Get-Volume | Where-Object {$_.FileSystemLabel -like ""}).DriveLetter
                                        [string]$Drive = $DriveLetter
                                        $Drive=$Drive.Replace(" ","")
                                        $Command = "bcdboot ${Drive}:\windows"
                                        Write-Host "`n$Command" -ForegroundColor Yellow
                                        $Command | cmd
                                        "bcdedit /set {default} description `"$using:Name`"" | cmd
                                        "bcdedit /set {current} description `"Windows10`"" | cmd
                                        "bcdedit /default {current}" | cmd
                                        Dismount-VHD G:\$using:Choice.vhd
                                    }
                                    else {
                                        $DriveLetter = (Mount-VHD -Path "D:\$using:Choice.vhd" -PassThru | Get-Disk | Get-Partition | Get-Volume | Where-Object {$_.FileSystemLabel -like ""}).DriveLetter
                                        [string]$Drive = $DriveLetter
                                        $Drive=$Drive.Replace(" ","")
                                        $Command = "bcdboot ${Drive}:\windows"
                                        Write-Host "`n$Command" -ForegroundColor Yellow
                                        $Command | cmd
                                        "bcdedit /set {default} description `"$using:Name`"" | cmd
                                        "bcdedit /set {current} description `"Windows10`"" | cmd
                                        "bcdedit /default {current}" | cmd
                                        Dismount-VHD D:\$using:Choice.vhd
                                    }
                                } -Credential $Cred
                            }
                        }
                        else {
                            Write-Host "`n$Choice is not an option!" -ForegroundColor Red
                        }            
                    }
                    VMImport {
                        $Choice=$AdditionalBox.Text
                        if(Test-Path "$Path\Resources\VM\$Choice") {
                            foreach ($PC in $Hosts) {
                                Write-Host "`nAdding VM on $PC..." -ForegroundColor Yellow
                                if(Test-Path -Path "\\$PC\D$\$Choice") {
                                    Write-Host "`nVM already present on drive" -ForegroundColor Cyan
                                }
                                else {
                                    Copy-Item -Path "$Path\Resources\VM\$Choice" -Recurse -Destination "\\$PC\D$\"
                                }
                                Invoke-Command -ComputerName $PC -ScriptBlock {
                                    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All -NoRestart
                                    Get-Service -Name vmms | Start-Service 
                                    if($using:Choice -eq "Microsoft Project") {
                                        Import-VM -Path 'D:\Microsoft Project\Microsoft Project\Virtual Machines\3D46A092-6C62-4FF1-BD83-51D7CA8CA76F.vmcx' -Copy -GenerateNewId -VirtualMachinePath "D:\Microsoft Project\Microsoft Project\" -VhdDestinationPath "D:\Microsoft Project\Microsoft Project\Virtual Hard Disks\" -SnapshotFilePath "D:\Microsoft Project\Microsoft Project" -SmartPagingFilePath "D:\Microsoft Project\Microsoft Project"    
                                        Get-VM -Name "Microsoft Project" | Get-VMNetworkAdapter | Connect-VMNetworkAdapter -SwitchName "Default Switch"
                                    }
                                    elseif($using:Choice -eq "ASBP") {
                                        Import-VM -Path 'D:\ASBP\ASBP_ISPIT_1\Virtual Machines\E4F19209-9455-419F-98C0-1BEC1E7B06DE.vmcx' -Copy -GenerateNewId -VirtualMachinePath "D:\ASBP\ASBP_ISPIT_1\" -VhdDestinationPath "D:\ASBP\ASBP_ISPIT_1\Virtual Hard Disks\" -SnapshotFilePath "D:\ASBP\ASBP_ISPIT_1\" -SmartPagingFilePath "D:\ASBP\ASBP_ISPIT_1\"
                                        Import-VM -Path 'D:\ASBP\ASBP_ISPIT_2\Virtual Machines\D2565692-C8CB-468A-97B3-F4EEBAB8F848.vmcx' -Copy -GenerateNewId -VirtualMachinePath "D:\ASBP\ASBP_ISPIT_2\" -VhdDestinationPath "D:\ASBP\ASBP_ISPIT_2\Virtual Hard Disks\" -SnapshotFilePath "D:\ASBP\ASBP_ISPIT_2\" -SmartPagingFilePath "D:\ASBP\ASBP_ISPIT_2\"
                                    }
                                } -Credential $Cred
                            }

                        }
                        else {
                            Write-Host "`n$Choice is not an option!" -ForegroundColor Red
                        } 
                    }
                    VMExists {
                        $Choice=$AdditionalBox.Text
                        foreach ($PC in $Hosts) {                       
                            $Names= Invoke-Command -ComputerName $PC -ScriptBlock {
                                Return Get-VM  | Where-Object -Property Name -Like "*$using:Choice*"
                            } -Credential $Cred
                            if($Names -ne $null) {
                                foreach ($Name in $Names) {
                                    $Display=$Name.Name
                                    Write-Host "`n$Display found on $PC" -ForegroundColor Yellow 
                                }
                            }
                            else {
                                Write-Host "`n$Choice not found on $PC" -ForegroundColor Red
                            }
                        }
                    }
                    VMRemove {
                        $Choice=$AdditionalBox.Text
                        foreach ($PC in $Hosts) {                       
                            Invoke-Command -ComputerName $PC -ScriptBlock {
                                Get-VM  | Where-Object -Property Name -Like "*$using:Choice*" | Stop-VM -Force
                                Get-VM  | Where-Object -Property Name -Like "*$using:Choice*" | Remove-VM -Force
                                Remove-Item "D:\$using:Choice" -Recurse -Force
                                #TEMP
                                Remove-Item "D:\MS Project VM" -Recurse -Force
                                #TEMP
                            } -Credential $Cred
                            Write-Host "`n$Choice removed from $PC" -ForegroundColor Yellow 
                        }
                    } 
                    AllPrograms {
                        [string]$Date=Get-Date
                        $Date=$Date.Replace("/","_")
                        $Date=$Date.Replace(" ","_")
                        $Date=$Date.Replace(":","_")
                        Start-Transcript -Path $Path\Resources\SoftwareHistory\$Date.csv -Force 
                        foreach ($PC in $Hosts) {
                            Write-Host "`n------------------------ Software found on $PC ------------------------" -ForegroundColor Yellow
                            $AllPrograms=Invoke-Command -ComputerName $PC -ScriptBlock {
                                $AllPrograms=Get-Package -Provider Programs -IncludeWindowsInstaller -Name "*" | Where-Object -Property Name -NotLike "Microsoft*" | Where-Object -Property Name -NotLike "Realtek*" | Where-Object -Property Name -NotLike "Windows*" | Where-Object -Property Name -NotLike "Nvidia*"
                                return $AllPrograms
                            } -Credential $Cred 
                            foreach($Program in $AllPrograms) {
                                Write-Host $Program.Name -NoNewline
                                Write-Host " - Version - " -NoNewline
                                Write-Host $Program.Version
                            } 
                        }
                        Stop-Transcript   
                    }
                    SoftwareExists {
                        $Choice=$AdditionalBox.Text
                        foreach ($PC in $Hosts) {                          
                            $Name=Invoke-Command -ComputerName $PC -ScriptBlock {
                                if(Get-Package -ErrorAction SilentlyContinue -Provider Programs -IncludeWindowsInstaller -Name "*$using:Choice*") {
                                    $NameS=Get-Package -ErrorAction SilentlyContinue -Provider Programs -IncludeWindowsInstaller -Name "*$using:Choice*"
                                    $Name=$NameS.Name
                                    Write-Host "`n$Name is installed on $using:PC" -ForegroundColor Yellow
                                    return $Name     
                                }
                                else {
                                    Write-Host "`n$using:Choice is not installed on $using:PC" -ForegroundColor Red
                                }
                            } -Credential $Cred
                        }       
                    }
                    WinActivation {
                        foreach ($PC in $Hosts) {
                            Write-Host "`nRecieving Windows key from $PC..." -ForegroundColor Yellow
                            Invoke-Command -ComputerName $PC -ScriptBlock {
                                [string]$Key=(Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
                                $Key=$Key.Replace(" ","")
                                Add-Content D:\Code.txt $Key 
                            } -Credential $Cred 
                        }
                        foreach ($PC in $Hosts) {
                            Write-Host "`nActivating Windows on $PC with - " -ForegroundColor Yellow -NoNewline
                            Invoke-Command -ComputerName $PC -ScriptBlock { 
                                [string]$KeyObject=Get-Content D:\Code.txt
                                $KeyObject=$KeyObject.Replace(" ","")
                                Write-Host "$KeyObject" -ForegroundColor Cyan
                                $sls = Get-WMIObject 'SoftwareLicensingService' -ComputerName $using:PC
                                 @($sls).foreach({
                                    $_.InstallProductKey("$KeyObject")
                                    $_.RefreshLicenseStatus()
                                }) | Out-Null
                                Remove-Item D:\Code.txt
                            } -Credential $Cred
                        }
                    }
                    WinStatus {
                        foreach ($PC in $Hosts) {
                            Write-Host "`nChecking $PC..." -ForegroundColor Yellow
                            $Result=Invoke-Command -ComputerName $PC -ScriptBlock {
                                Return Get-CimInstance SoftwareLicensingProduct -Filter "Name like 'Windows%'" | 
                                where { $_.PartialProductKey } | select LicenseStatus
                            } -Credential $Cred 
                            Write-Host $Result
                         }
                    }
                    ProjectRearm {
                        foreach ($PC in $Hosts) {
                            Write-Host "`nRearming Project on $PC..." -ForegroundColor Yellow
                            Invoke-Command -ComputerName $PC -ScriptBlock {
	                            cmd /c "C:\Program Files (x86)\Microsoft Office\Office16\ospprearm.exe" "82f502b5-b0b0-4349-bd2c-c560df85b248" | Out-Null
			                    cmd /c "C:\Program Files (x86)\Microsoft Office\Office16\ospprearm.exe" "cbbaca45-556a-4416-ad03-bda598eaa7c8" | Out-Null
			                    cmd /c "C:\Program Files (x86)\Microsoft Office\Office16\ospprearm.exe" "829b8110-0e6f-4349-bca4-42803577788d" | Out-Null
                            } -Credential $Cred
                        }    
                    } 
                    GPUpdate {
                        foreach ($PC in $Hosts) {
                            Write-Host "`nUpdating $PC..." -ForegroundColor Yellow
                            Invoke-Command -Computer $PC -ScriptBlock {
                                gpupdate /force
                            } -Credential $Cred -AsJob | Out-Null
                        }
                    }
                    AddLanguage {
                        $Choice=$AdditionalBox.Text
                        foreach($PC in $Hosts) {
                            Write-Host "`nAdding $Choic to $PC..." -ForegroundColor Yellow
                            Invoke-Command -ComputerName $PC -ScriptBlock {
                                $LanguageList = Get-WinUserLanguageList               
                                $LanguageList.Add($using:Choice)
                                Set-WinUserLanguageList $LanguageList -Force
                            } -Credential $Cred
                        }
                    }
                    RemoveProfile {
                        $Choice=$AdditionalBox.Text
                        $Profiles = @('Administrator','grafika10','vuaispit', 'hyperv','office10','programer10','acad10','console8','All')
                        foreach ($PC in $Hosts) {
                            Write-Host "`nDeleting Profile on $PC..." -ForegroundColor Yellow
                            if($Choice -eq 'All') {
                                Remove-Item -Path "\\$PC\E$\Radna-mapa\*" -Recurse -Force
                                foreach($Instance in $Profiles) {
                                    if($Instance -ne 'All') {
                                        Get-CimInstance -ClassName Win32_UserProfile -Computer $PC | Where-Object { $_.LocalPath -eq "C:\Users\$Instance"} | Remove-CimInstance   
                                    }    
                                }
                            }
                            elseif($Choice -eq 'vuaispit') {
                                Remove-Item -Path "\\$PC\E$\Radna-mapa\*" -Recurse -Force
                                Get-CimInstance -ClassName Win32_UserProfile -Computer $PC | Where-Object { $_.LocalPath -eq "C:\Users\$Choice"} | Remove-CimInstance
                            }
                            else {
                                Get-CimInstance -ClassName Win32_UserProfile -Computer $PC | Where-Object { $_.LocalPath -eq "C:\Users\$Choice"} | Remove-CimInstance
                            }
                        }
                    }
                    DiskCleanup {
                        foreach ($PC in $Hosts) {
                            Write-Host "`nStarting CleanUp on $PC..." -ForegroundColor Yellow
                            Invoke-Command -ComputerName $PC -ScriptBlock {
                                $ErrorActionPreference = "SilentlyContinue"
                                Get-ChildItem -Path 'C:\$Recycle.Bin' -Force | Remove-Item -Recurse -ErrorAction SilentlyContinue
                                Get-ChildItem -Path 'D:\$Recycle.Bin' -Force | Remove-Item -Recurse -ErrorAction SilentlyContinue
                                Remove-Item -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue
                                Remove-Item -path $env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db -Force -ErrorAction SilentlyContinue
                                Remove-Item -Path "C:\Windows\Temp" -Force -Recurse -ErrorAction SilentlyContinue
                                Remove-Item -Path "C:\Windows\Downloaded Program Files" -Force -Recurse -ErrorAction SilentlyContinue
                                Remove-Item -Path "C:\Windows\memory.dmp" -Force -Recurse -ErrorAction SilentlyContinue
                                Remove-Item -Path "C:\Windows\Minidump" -Force -Recurse -ErrorAction SilentlyContinue
                            } -Credential $Cred
                        } 
                    }  
                    Restart {
                        foreach ($PC in $Hosts) {
                            Write-Host "`nRestarting $PC..." -ForegroundColor Yellow
                            Invoke-Command -ComputerName $PC -ScriptBlock {
                                Restart-Computer -Force
                            } -Credential $Cred -AsJob | Out-Null
                        }
                    }
                    Shutdown {
                        foreach ($PC in $Hosts) {
                            Write-Host "`nShutting down $PC..." -ForegroundColor Yellow
                            Invoke-Command -ComputerName $PC -ScriptBlock {
                                Stop-Computer -Force
                            } -Credential $Cred -AsJob | Out-Null
                        }
                    } 
                }
                Write-Host "`nOperation completed!" -ForegroundColor Cyan
                Write-Host "`n`n------------------------ Select your next operation ------------------------`n`n" -ForegroundColor Green
        }
        else {
            Write-Host "`n$Operation is not an Operation option!" -ForegroundColor Red
            Write-Host "Should you really be a System Administrator?" -ForegroundColor Yellow   
        }
    }
    else {
        Write-Host "`n$Choice is not a Host option!" -ForegroundColor Red
        Write-Host "Should you really be a System Administrator?" -ForegroundColor Yellow
    }
    $ExecuteL.Text = "Script Ready"
    $ExecuteL.ForeColor="Cyan"
}
)
$GUI.ShowDialog()
