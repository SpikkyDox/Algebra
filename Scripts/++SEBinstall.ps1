$Path = "\\ILI-MDT\Sime"
$NotepadFile = "E:\Sime\Hosts\SEB.txt"
$InstallerName = "SafeExam.msi"
$Credential = Get-Credential -Message "Enter your credentials"

$Hosts = Get-Content -Path $NotepadFile

foreach ($PC in $Hosts) {
    Write-Host "`nInstalling on $PC..." -ForegroundColor Yellow

    Copy-Item -Path "$Path\$InstallerName" -Destination "\\$PC\C$" -Force

    Invoke-Command -ComputerName $PC -Credential $Credential -ScriptBlock {
        $InstallerPath = "C:\$using:InstallerName"

        Start-Process -FilePath "msiexec.exe" -ArgumentList "/i $InstallerPath /quiet /norestart" -Wait -NoNewWindow
    }

    Remove-Item -Path "\\$PC\C$\$InstallerName" -Force
}

Write-Host "Installation completed on all hosts." -ForegroundColor Green
