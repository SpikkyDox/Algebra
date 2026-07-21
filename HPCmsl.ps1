$Path = $PSScriptRoot
$AMTPassword = ConvertTo-SecureString "Pa55w.rd" -AsPlainText -Force
$AMTCred = New-Object System.Management.Automation.PSCredential ("admin", $AMTPassword)
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
    $Operations = @('PowerOn','BootLogo','Restart','Shutdown','Exit')
    $Operations[0,1,2,3,4] | Write-Host -ForegroundColor Yellow
    $Operation=""
    While($Operation -eq "") {
        $Choice=Read-Host -Prompt "`nChoose operation"
        switch ($Choice) {
            PowerOn {
                $Operation = $Choice
                Write-Host "`n$Operation chosen!" -ForegroundColor Cyan 
            }
            BootLogo {
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
                $Operation = $Choice
                Write-Host "`n$Operation chosen!" -ForegroundColor Cyan 
            }
        }
        if($Operation -eq "") {
            Write-Host "`n$Choice is not an option!" -ForegroundColor Red
        }
    }
    switch ($Operation) {
        PowerOn {
            foreach ($PC in $Hosts) {  
                Invoke-AMTPowerManagement $PC -credential $AMTCred -operation PowerOn
            }
        }
        BootLogo {
            Write-Host "Installing module on every PC..." -ForegroundColor Yellow
            foreach ($PC in $Hosts) {  
                Copy-Item -Path "$Path\Resources\HPCmsl.exe" -Destination "\\$PC\C$"
            }
            foreach ($PC in $Hosts) {
                Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC C:\HPCmsl.exe /VERYSILENT} 2> $null
                Remove-Item -Path "\\$PC\C$\HPCmsl.exe" -Recurse    
            }
            Write-Host "Module installed on every PC." -ForegroundColor Cyan
            Write-Host "Setting boot image on every PC..." -ForegroundColor Yellow
            foreach ($PC in $Hosts) {
                Copy-Item -Path "$Path\Resources\Logo.jpeg" -Destination "\\$PC\C$"    
            }
            foreach ($PC in $Hosts) {
                Invoke-Command -ComputerName $PC -ScriptBlock {
                    Set-HPFirmwareBootLogo -File "C:\logo.jpeg" -Password "Pa55w.rd"
                } -Credential $Cred   
                Remove-Item -Path "\\$PC\C$\logo.jpeg" -Recurse  
            }
            Write-Host "Boot image set on every PC." -ForegroundColor Cyan
            Write-Host "Removing module from every PC..." -ForegroundColor Yellow
            foreach ($PC in $Hosts) {
                $String = Invoke-Command -ComputerName $PC -ScriptBlock {
                    $ToDelete= Get-Package -Provider Programs -IncludeWindowsInstaller -Name "HP Client Management Script Library"
                    $String= $ToDelete.Meta.Attributes["UninstallString"]
                    Return $String
                }
                Invoke-Command -ScriptBlock {& $Path\Resources\PsExec.exe -accepteula \\$PC -h "$String" /S /VERYSILENT /SUPPRESSMSGBOXES /NORESTART} 2> $null
            }
            Write-Host "Module removed from every PC." -ForegroundColor Cyan
        }
        Restart {
            Write-Host "`nRestart sequence started!`n" -ForegroundColor Cyan
            foreach ($PC in $Hosts) {
                Write-Host "`nRestarting $PC..." -ForegroundColor Yellow
                Invoke-Command -ComputerName $PC -ScriptBlock {
                    Restart-Computer -force
                } -Credential $Cred -AsJob | Out-Null
            }
        }
        Shutdown {
            Write-Host "`nShutdown sequence started!`n" -ForegroundColor Cyan
            foreach ($PC in $Hosts) {
                Write-Host "`nShutting down $PC..." -ForegroundColor Yellow
                Invoke-Command -ComputerName $PC -ScriptBlock {
                    Stop-Computer -force
                } -Credential $Cred -AsJob | Out-Null
            }
        }
        Exit {
            Write-Host "`n`n--------------------------Operations completed!----------------------------" -ForegroundColor Cyan 
            Write-Host "`n------Please review the transcription in the root folder of this script----`n`n`n" -ForegroundColor Yellow
            Stop-Transcript 
            exit
        }
    }
    Write-Host "`n`n---------------------------Operation completed!---------------------------" -ForegroundColor Cyan
    Write-Host "`n------------------------Consider rebooting all hosts----------------------" -ForegroundColor Yellow 
}
