$Path = $PSScriptRoot
Write-Host "`n`nCopyright © 2022 BrunoTheStudent" -ForegroundColor Yellow
Write-Host "`n`nLogin as domain administrator account to proceed" -ForegroundColor Green 
while(1) {
    $ErrorActionPreference = "SilentlyContinue"
    $Cred = Get-Credential -Message " " -UserName ucione\administrator
    $Confirmation=Invoke-Command -ComputerName ili-wsus -ScriptBlock {
        $Confirmation = 1
        Return $Confirmation
    } -Credential $Cred
    if($Confirmation -eq 1) {break}
    else {Write-Host "`nFailed authentication, please try again" -ForegroundColor Red}
}
$AMTPassword = ConvertTo-SecureString "Pa55w.rd" -AsPlainText -Force
$AMTCred = New-Object System.Management.Automation.PSCredential ("admin", $AMTPassword)
Start-Transcript -Path "$Path\transcript.txt" -ErrorAction SilentlyContinue 
Write-Host "`n`n`n---------------------------Welcome---------------------------" -ForegroundColor Yellow
Write-Host "`nWould you kindly choose hosts?`n" -ForegroundColor Green
(Get-ChildItem -Path $Path\Resources\Hosts).BaseName | Write-Host -ForegroundColor Yellow
$Hosts=""
$Choice=""
While($Hosts -eq "") {   
    $Choice=Read-Host -Prompt "`nChoose hosts"
    if(Test-Path "$Path\Resources\Hosts\$Choice.txt") {
        $Hosts = $Choice 
        $Group = (Get-ChildItem -Path $Path\Resources\Hosts\$Choice.txt).BaseName
        Write-Host "`n$Group chosen!" -ForegroundColor Cyan
        $Hosts = Get-Content "$Path\Resources\Hosts\$Choice.txt"
        }
    else {
        Write-Host "`n$Choice is not an option!" -ForegroundColor Red
    }
}
While (1) {
    Write-Host "`nWould you kindly choose operation you wish executed upon " -ForegroundColor Green -NoNewline
    Write-Host "$Group`n" -ForegroundColor Cyan
    $Operations = @('PowerOn','Install','Uninstall','Features','Boot','AllPrograms','SoftwareExists','WinActivation','ProjectRearm','GPUpdate','AddKeyboard','RemoveProfile','DiskCleanup','Restart','Shutdown','Exit')
    $Operations[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15] | Write-Host -ForegroundColor Yellow
    $Operation=""
    While($Operation -eq "") {
        $Choice=Read-Host -Prompt "`nChoose operation"
        switch ($Choice) {
            PowerOn {
                $Operation = $Choice
                Write-Host "`n$Operation chosen!" -ForegroundColor Cyan 
            }
            Install {
                $Operation = $Choice
                Write-Host "`n$Operation chosen!" -ForegroundColor Cyan 
            }
            Uninstall {
                $Operation = $Choice
                Write-Host "`n$Operation chosen!" -ForegroundColor Cyan                
            }
            Features {
                $Operation = $Choice
                Write-Host "`n$Operation chosen!" -ForegroundColor Cyan
            }
            Boot {
                $Operation = $Choice
                Write-Host "`n$Operation chosen!" -ForegroundColor Cyan
                Write-Host "`n`n`n---------------------------WARNING---------------------------" -ForegroundColor Red
                Write-Host "`nBoot edit commands can result in OS being unavailable, please refer to the boot editor documentation for more information!" -ForegroundColor Red
                Write-Host "`nRun in test enviroment before mass deployment!`n`n" -ForegroundColor Red                 
            }
            AllPrograms {
                $Operation = $Choice
                Write-Host "`n$Operation chosen!" -ForegroundColor Cyan            
            }
            SoftwareExists {
                $Operation = $Choice
                Write-Host "`n$Operation chosen!" -ForegroundColor Cyan                
            }
            WinActivation {
                $Operation = $Choice
                Write-Host "`n$Operation chosen!" -ForegroundColor Cyan
            }
            ProjectRearm {
                $Operation = $Choice
                Write-Host "`n$Operation chosen!" -ForegroundColor Cyan                
            }
            GPUpdate {
                $Operation = $Choice
                Write-Host "`n$Operation chosen!" -ForegroundColor Cyan
            }
            AddKeyboard {
                $Operation = $Choice
                Write-Host "`n$Operation chosen!" -ForegroundColor Cyan
            }
            RemoveProfile {
                $Operation = $Choice
                Write-Host "`n$Operation chosen!" -ForegroundColor Cyan
            }
            DiskCleanup {
                $Operation = $Choice
                Write-Host "`n$Operation chosen!" -ForegroundColor Cyan
            }
            Restart {
                $Operation = $Choice
                Write-Host "`n$Operation chosen!" -ForegroundColor Cyan
            }
            Shutdown {
                $Operation = $Choice
                Write-Host "`n$Operation chosen!" -ForegroundColor Cyan
            }
            Exit {
                Write-Host "`n`n--------------------------Operations completed!----------------------------" -ForegroundColor Cyan 
                Write-Host "`n------Please review the transcription in the root folder of this script----`n`n`n" -ForegroundColor Yellow
                Stop-Transcript 
                Exit
            }
        }
        if($Operation -eq "") {
            Write-Host "`n$Choice is not an option!" -ForegroundColor Red
        }
    }
    switch ($Operation) {
        PowerOn {
            foreach ($PC in $Hosts) {  
                Invoke-AMTPowerManagement $PC -Credential $AMTCred -Operation PowerOn
            }
        }
        Install {
            Write-Host "`nWould you kindly choose installation?`n" -ForegroundColor Green
            (Get-ChildItem -Path $Path\Resources\Installations).BaseName | Write-Host -ForegroundColor Yellow 
            $Install="" 
            While($Install -eq "") {
                $Choice=Read-Host -Prompt "`nChoose software"
                if(Test-Path "$Path\Resources\Installations\$Choice.*") {
                    $Install = $Choice
                    $Extension = (Get-ChildItem -Path $Path\Resources\Installations\$Choice.*).Extension
                    Write-Host "`n$Install chosen!" -ForegroundColor Cyan
                }
                else {
                    Write-Host "`n$Choice is not an option!" -ForegroundColor Red
                }
            } 
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
                    elseif ($Choice -eq "powerbi") {
                        Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC C:\$Choice.exe -q -norestart ACCEPT_EULA=1} 2> $null   
                    }
                    elseif ($Choice -eq "davinci") {
                        Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC C:\$Choice.exe /i /q} 2> $null   
                    }
                    elseif ($Choice -eq "Figma") {
                        Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC C:\$Choice.exe -s } 2> $null   
                    }
                    else {
                        Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC C:\$Choice.exe /S /VERYSILENT /SUPPRESSMSGBOXES /NORESTART} 2> $null
                    }
                }
                else {
                    Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC MsiExec.exe /i C:\$Choice.msi ALLUSERS=1 /qn} 2> $null
                }
                Remove-Item -Path "\\$PC\C$\$Choice.*" -Recurse
                Write-Host "Installation completed!" -ForegroundColor Cyan
            }
        }
        Uninstall {
            Write-Host "`n------------------------ Software found on Lecturer ------------------------" -ForegroundColor Yellow
            Invoke-Command -ComputerName $Hosts[0] -ScriptBlock {
                Get-Package -Provider Programs -IncludeWindowsInstaller -Name "*" | Where-Object -Property Name -NotLike "Microsoft*" | Where-Object -Property Name -NotLike "Realtek*" | Where-Object -Property Name -NotLike "Windows*" | Where-Object -Property Name -NotLike "Nvidia*" |Format-Table -Property "Name", "Version"
            } -Credential $Cred 
            Write-Host "Availiable package uninstallation (Type package name under software name) - " -ForegroundColor Yellow -NoNewline
            Write-Host "Minitool" -ForegroundColor Cyan
            Write-Host "`nSpecify the name as detailed as possible" -ForegroundColor Red
            Write-Host "`nFor instance, write Adobe Photoshop 2022 instead of Adobe Photoshop!`n" -ForegroundColor Green
            $Choice=Read-Host -Prompt "`nChoose software to uninstall"
            Write-Host "`nUninstall sequence started" -ForegroundColor Cyan
            foreach ($PC in $Hosts) {
                Write-Host "`nUninstalling from $PC - " -ForegroundColor Yellow -NoNewline
                if($Choice -eq "MiniTool") {
                    Invoke-Command -ComputerName $PC -ScriptBlock {
                        Get-Process -Name partitionwizard | Stop-Process -Force
                    } -Credential $Cred
                    $String = Invoke-Command -ComputerName $PC -ScriptBlock {
                        $ToDelete= Get-Package -Provider Programs -IncludeWindowsInstaller -Name "*minitool partition*"
                        Write-Host $ToDelete.Name -ForegroundColor Cyan
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
                        $ToDelete= Get-Package -Provider Programs -IncludeWindowsInstaller -Name "*shadowmaker*"
                        Write-Host $ToDelete.Name -ForegroundColor Cyan
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
                        $ToDelete= Get-Package -Provider Programs -IncludeWindowsInstaller -Name "*$using:Choice*"
                        Write-Host $ToDelete.Name -ForegroundColor Cyan
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
            Write-Host "Uninstall completed!" -ForegroundColor Cyan
            }
        }
        Features {
            Write-Host "`nWould you kindly choose Windows Feature to install?`n" -ForegroundColor Green
            $Features = @('Hyper-V','Linux')
            $Features[0,1] | Write-Host -ForegroundColor Yellow
            $Feature=""
            while($Feature -eq "") {
                $Choice = Read-Host -Prompt "`nChoose language to install"
                if($Choice -in $Features) {
                    $Feature=$Choice
                }
                else {
                    Write-Host "$Choice is not an option!`n" -ForegroundColor Red
                }
            }
            foreach ($PC in $Hosts) {
                Write-Host "`nEnabeling on $PC..." -ForegroundColor Yellow
                Invoke-Command -ComputerName $PC -ScriptBlock {
                    Get-WindowsOptionalFeature -Online | Where-Object {$_.FeatureName -like "*$using:Feature*"} | Enable-WindowsOptionalFeature -Online -NoRestart 
                } -Credential $Cred 
                Write-Host "Feature enabled!" -ForegroundColor Cyan
            }
        }
        Boot {
            Write-Host "`nWould you kindly choose vhd to dual boot?`n" -ForegroundColor Green
            (Get-ChildItem -Path $Path\Resources\VHD).BaseName | Write-Host -ForegroundColor Yellow 
            $Boot="" 
            While($Boot -eq "") {
                $Choice=Read-Host -Prompt "`nChoose vhd"
                if(Test-Path "$Path\Resources\VHD\$Choice.*") {
                    $Boot = $Choice
                    Write-Host "`n$Boot chosen!" -ForegroundColor Cyan
                }
                elseif("$Choice" -eq "CEHv11") {
                    $Boot = $Choice
                    Write-Host "`n$Boot chosen!" -ForegroundColor Cyan
                }
                else {
                    Write-Host "`n$Choice is not an option!" -ForegroundColor Red
                }
            } 
            $Name=Read-Host -Prompt "Specify name"
            foreach ($PC in $Hosts) {
                Write-Host "`nAdding boot on $PC..." -ForegroundColor Yellow
                if(Test-Path -Path "\\$PC\D$\$Choice.vhd") {
                    Write-Host "VHD already present on drive" -ForegroundColor Cyan
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
                        $DriveLetter = (Mount-VHD -Path "G:\$using:Boot.vhd" -PassThru | Get-Disk | Get-Partition | Get-Volume | Where-Object {$_.FileSystemLabel -like ""}).DriveLetter
                        Write-Host $DriveLetter
                        [string]$Drive = $DriveLetter
                        $Drive=$Drive.Replace(" ","")
                        $Command = "bcdboot ${Drive}:\windows"
                        Write-Host $Command
                        $Command | cmd
                        "bcdedit /set {default} description `"$using:Name`"" | cmd
                        "bcdedit /set {current} description `"Windows10`"" | cmd
                        "bcdedit /default {current}" | cmd
                        Dismount-VHD G:\$using:Boot.vhd
                    }
                    else {
                        $DriveLetter = (Mount-VHD -Path "G:\$using:Boot.vhd" -PassThru | Get-Disk | Get-Partition | Get-Volume | Where-Object {$_.FileSystemLabel -like ""}).DriveLetter
                        [string]$Drive = $DriveLetter
                        $Drive=$Drive.Replace(" ","")
                        $Command = "bcdboot ${Drive}:\windows"
                        Write-Host $Command
                        $Command | cmd
                        "bcdedit /set {default} description `"$using:Name`"" | cmd
                        "bcdedit /set {current} description `"Windows10`"" | cmd
                        "bcdedit /default {current}" | cmd
                        Dismount-VHD D:\$using:Boot.vhd
                    }
                } -Credential $Cred
                Write-Host "Dual boot added!" -ForegroundColor Cyan
            }
        }
        AllPrograms {
            Write-Host "`nSoftware check sequence started`n " -ForegroundColor Yellow
            [string]$Date=Get-Date
            $Date=$Date.Replace("/","_")
            $Date=$Date.Replace(" ","_")
            $Date=$Date.Replace(":","_")
            Start-Transcript -Path $Path\Resources\SoftwareHistory\$Date.csv -Force 
            foreach ($PC in $Hosts) {
                Write-Host "`n------------------------ Software found on $PC ------------------------" -ForegroundColor Yellow
                Invoke-Command -ComputerName $PC -ScriptBlock {
                    Get-Package -Provider Programs -IncludeWindowsInstaller -Name "*" | Where-Object -Property Name -NotLike "Microsoft*" | Where-Object -Property Name -NotLike "Realtek*" | Where-Object -Property Name -NotLike "Windows*" | Where-Object -Property Name -NotLike "Nvidia*" | Format-Table -Property "Name", "Version"
                } -Credential $Cred 
            }
            Stop-Transcript
            Write-Host "`nSoftware check sequence Finished!`n " -ForegroundColor Cyan    
        }
        SoftwareExists {
            $Software = Read-Host -Prompt "Software You wish to check"
            Write-Host "`nSoftware check sequence started`n" -ForegroundColor Yellow
            foreach ($PC in $Hosts) {
                Invoke-Command -ComputerName $PC -ScriptBlock {
                    if(Get-Package -ErrorAction SilentlyContinue -Provider Programs -IncludeWindowsInstaller -Name "*$using:Software*") {
                        $NameS=Get-Package -ErrorAction SilentlyContinue -Provider Programs -IncludeWindowsInstaller -Name "*$using:Software*"
                        $Name=$NameS.Name
                        Write-Host "`n$Name is installed on $using:PC" -ForegroundColor Cyan
                    }
                    else {
                        Write-Host "`n$using:Software is not installed on $using:PC" -ForegroundColor Red
                    }
                } -Credential $Cred 
            }
            Write-Host "`nSoftware check sequence completed`n" -ForegroundColor Cyan        
        }
        WinActivation {
            Write-Host "`nActivation sequence started" -ForegroundColor Cyan
            foreach ($PC in $Hosts) {
                Write-Host "`nRecieving Windows key from $PC..." -ForegroundColor Yellow
                Invoke-Command -ComputerName $PC -ScriptBlock {
                    [string]$Key=(Get-WmiObject -query 'select * from SoftwareLicensingService').OA3xOriginalProductKey
                    $Key=$Key.Replace(" ","")
                    Add-Content D:\Code.txt $Key 
                } -Credential $Cred 
                Write-Host "`nKey recieved from $PC..." -ForegroundColor Cyan
            }
            foreach ($PC in $Hosts) {
                Write-Host "`nActivating Windows on $PC with " -ForegroundColor Yellow -NoNewline
                Invoke-Command -ComputerName $PC -ScriptBlock { 
                    [string]$KeyObject=Get-Content D:\Code.txt
                    $KeyObject=$KeyObject.Replace(" ","")
                    Write-Host "$KeyObject" -ForegroundColor Red
                    $sls = Get-WMIObject 'SoftwareLicensingService' -ComputerName $using:PC
                     @($sls).foreach({
                        $_.InstallProductKey("$KeyObject")
                        $_.RefreshLicenseStatus()
                    }) | Out-Null
                    Remove-Item D:\Code.txt
                } -Credential $Cred
                Write-Host "`nWindows activated on $PC" -ForegroundColor Cyan
            }
        }
        ProjectRearm {
            Write-Host "`nRearm sequence started`n" -ForegroundColor Cyan
            foreach ($PC in $Hosts) {
                Write-Host "Activating on $PC..." -ForegroundColor Yellow
                Invoke-Command -ComputerName $PC -ScriptBlock {
	                cmd /c "C:\Program Files (x86)\Microsoft Office\Office16\ospprearm.exe" "82f502b5-b0b0-4349-bd2c-c560df85b248" | Out-Null
			        cmd /c "C:\Program Files (x86)\Microsoft Office\Office16\ospprearm.exe" "cbbaca45-556a-4416-ad03-bda598eaa7c8" | Out-Null
			        cmd /c "C:\Program Files (x86)\Microsoft Office\Office16\ospprearm.exe" "829b8110-0e6f-4349-bca4-42803577788d" | Out-Null
                } -Credential $Cred
                Write-Host "$PC rearmed" -ForegroundColor Cyan
            }    
        } 
        GPUpdate {
            Write-Host "`nGPUpdate sequence started`n" -ForegroundColor Cyan
            foreach ($PC in $Hosts) {
                Write-Host "Updating $PC..." -ForegroundColor Yellow
                Invoke-Command -Computer $PC -ScriptBlock {
                    gpupdate /force
                } -Credential $Cred -AsJob | Out-Null
                Write-Host "$PC Updated!" -ForegroundColor Cyan
            }
        }
        AddKeyboard {
            Write-Host "`nWould you kindly choose keyboard layout you wish to install `n" -ForegroundColor Green
            $Languages = @('hr-HR','en-US','en-GB')
            $Languages[0,1,2] | Write-Host -ForegroundColor Yellow
            $Language=""
            while($Language -eq "") {
                $Choice = Read-Host -Prompt "Choose language to install"
                if($Choice -in $Languages) {
                    $Language=$Choice
                }
                else {
                    Write-Host "$Choice is not an option!`n" -ForegroundColor Red
                }
            }
            foreach($PC in $Hosts) {
                Write-Host "`nAdding $Language to $PC...`n" -ForegroundColor Yellow
                Invoke-Command -ComputerName $PC -ScriptBlock {
                    $LanguageList = Get-WinUserLanguageList               
                    $LanguageList.Add($using:Language)
                    Set-WinUserLanguageList $LanguageList -Force
                } -Credential $Cred
                Write-host "Language added to $PC`n" -ForegroundColor Cyan
            }
        }
        RemoveProfile {
            Write-Host "`nWould you kindly choose profile you wish to remove`n" -ForegroundColor Green
            $Profiles = @('Administrator','grafika10','vuaispit', 'hyperv','office10','programer10','acad10','console8','All')
            $Profiles[0,1,2,3,4,5,6,7,8] | Write-Host -ForegroundColor Yellow
            $Profile=""
            while($Profile -eq "") {
                $Choice = Read-Host -Prompt "`nChoose profile to delete"
                if($Choice -in $Profiles) {
                    $Profile=$Choice
                }
                else {
                    Write-Host "$Choice is not an option!`n" -ForegroundColor Red
                }
            }
            foreach ($PC in $Hosts) {
                Write-Host "Deleting Profile on $PC..." -ForegroundColor Yellow
                if($Profile -eq 'All') {
                    Remove-Item -Path "\\$PC\E$\Radna-mapa\*" -Recurse -Force
                    foreach($Instance in $Profiles) {
                        if($Instance -ne 'All') {
                            Get-CimInstance -ClassName Win32_UserProfile -Computer $PC | Where-Object { $_.LocalPath -eq "C:\Users\$Instance"} | Remove-CimInstance   
                        }    
                    }
                }
                elseif($Choice -eq 'vuaispit') {
                    Remove-Item -Path "\\$PC\E$\Radna-mapa\*" -Recurse -Force
                    Get-CimInstance -ClassName Win32_UserProfile -Computer $PC | Where-Object { $_.LocalPath -eq "C:\Users\$Profile"} | Remove-CimInstance
                }
                else {
                    Get-CimInstance -ClassName Win32_UserProfile -Computer $PC | Where-Object { $_.LocalPath -eq "C:\Users\$Profile"} | Remove-CimInstance
                }
            Write-host "`nProfile removed from $PC`n" -ForegroundColor Cyan
            }
        }
        DiskCleanup {
            Write-Host "`nCleanUp sequence started`n" -ForegroundColor Cyan
            foreach ($PC in $Hosts) {
                Write-Host "`nStarting CleanUp on $PC..." -ForegroundColor Yellow
                Invoke-Command -ComputerName $PC -ScriptBlock {
                    Get-ChildItem -Path 'C:\$Recycle.Bin' -Force | Remove-Item -Recurse -ErrorAction SilentlyContinue
                    Get-ChildItem -Path 'D:\$Recycle.Bin' -Force | Remove-Item -Recurse -ErrorAction SilentlyContinue
                    Remove-Item -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue
                    Remove-Item -path $env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db -Force -ErrorAction SilentlyContinue
                    Remove-Item -Path "C:\Windows\Temp" -Force -Recurse -ErrorAction SilentlyContinue
                    Remove-Item -Path "C:\Windows\Downloaded Program Files" -Force -Recurse -ErrorAction SilentlyContinue
                    Remove-Item -Path "C:\Windows\memory.dmp" -Force -Recurse -ErrorAction SilentlyContinue
                    Remove-Item -Path "C:\Windows\Minidump" -Force -Recurse -ErrorAction SilentlyContinue
                } -Credential $Cred
                Write-Host "`n$PC cleaned" -ForegroundColor Cyan
            } 
            Write-Host "`nCleanUp sequence completed" -ForegroundColor Cyan
        }  
        Restart {
            Write-Host "`nRestart sequence started`n" -ForegroundColor Cyan
            foreach ($PC in $Hosts) {
                Write-Host "`nRestarting $PC..." -ForegroundColor Yellow
                Invoke-Command -ComputerName $PC -ScriptBlock {
                    Restart-Computer -Force
                } -Credential $Cred -AsJob | Out-Null
            }
            Write-Host "`nRestart sequence finished`n" -ForegroundColor Cyan
        }
        Shutdown {
            Write-Host "`nShutdown sequence started...`n" -ForegroundColor Cyan
            foreach ($PC in $Hosts) {
                Write-Host "`nShutting down $PC..." -ForegroundColor Yellow
                Invoke-Command -ComputerName $PC -ScriptBlock {
                    Stop-Computer -Force
                } -Credential $Cred -AsJob | Out-Null
            }
            Write-Host "`nShutdown sequence finished`n" -ForegroundColor Cyan
        } 
    }
    Write-Host "`n`n---------------------------Operation completed!---------------------------" -ForegroundColor Cyan
    Write-Host "`n------------------------Consider rebooting all hosts----------------------" -ForegroundColor Yellow 
}
