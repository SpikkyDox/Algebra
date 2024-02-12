$Path = "\\ILI-MDT\Sime"
$NotepadFile = "E:\Sime\Hosts\SEB.txt"
$InstallerName = "SafeExam.msi"
$InstallDirectory = "C:\Program Files\SafeExamBrowser"
$Credential = Get-Credential -Message "Enter your credentials"

$Hosts = Get-Content -Path $NotepadFile

foreach ($PC in $Hosts) {
    Write-Host "`nUninstalling old version on $PC..." -ForegroundColor Yellow

    Invoke-Command -ComputerName $PC -Credential $Credential -ScriptBlock {
        # Uninstall old version using the product code
        # svaki subnet ima svoj kod ... ovaj radi samo za F1 
        $ProductCode = "{ACCA1C60-10A4-420B-8C69-A64A9B0F4205}"
        $UninstallCommand = "msiexec.exe /x $ProductCode /quiet /norestart"
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c $UninstallCommand" -Wait -NoNewWindow

        # Wait for the uninstallation to complete
        Start-Sleep -Seconds 30

        # Remove the old version directory if it exists
        $OldVersionDirectory = "C:\Program Files\SafeExamBrowser"
        if (Test-Path $OldVersionDirectory) {
            Remove-Item -Path $OldVersionDirectory -Recurse -Force
        }
    }

    Write-Host "`nInstalling on $PC..." -ForegroundColor Yellow

    Copy-Item -Path "$Path\$InstallerName" -Destination "\\$PC\C$" -Force

    Invoke-Command -ComputerName $PC -Credential $Credential -ScriptBlock {
        $InstallerPath = "C:\$using:InstallerName"

        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $InstallerPath /quiet /norestart" -Wait -NoNewWindow
    }

    Remove-Item -Path "\\$PC\C$\$InstallerName" -Force
}

Write-Host "Installation completed on all hosts." -ForegroundColor Green
