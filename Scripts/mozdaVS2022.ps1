# Get the list of hostnames from the Notepad file
$hostnames = Get-Content -Path "E:\Sime\Hosts\ZG-D1.txt"

# Loop through each hostname and deploy Visual Studio 2022 Community
foreach ($hostname in $hostnames) {
    Write-Host "Deploying Visual Studio 2022 Community to $hostname"
    $session = New-PSSession -ComputerName $hostname
    Invoke-Command -Session $session -ScriptBlock {
        $installerPath = "C:\VisualStudioSetup.exe"
        Start-Process -FilePath $installerPath -ArgumentList "--quiet --norestart --installPath `"$env:ProgramFiles(x86)\Microsoft Visual Studio\2022\Community`"" -Wait
    }
    Remove-PSSession -Session $session
}
