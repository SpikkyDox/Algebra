$AMTPassword = ConvertTo-SecureString "Pa55w.rd" -AsPlainText -Force
$AMTCred = New-Object System.Management.Automation.PSCredential ("admin", $AMTPassword)
$Path = $PSScriptRoot
$AllHosts=Get-ChildItem -Path "$Path\Hosts"
Start-Transcript -Path "$Path\transcript.txt" -ErrorAction SilentlyContinue
Write-Host "`nIntegrity sequence started`n" -ForegroundColor Yellow
$Corrupted =@()
foreach($Hosts in $AllHosts) {
    $Group = Get-Content -Path "$Path\Hosts\$Hosts"
    foreach($PC in $Group) {
        $ErrorActionPreference = "SilentlyContinue"
        $Integrity=Get-AMTFirmwareVersion -ComputerName $PC -Credential $AMTCred
        If($Integrity.Property -eq "Error") {
            Write-Host "AMT Connection corrupted with $PC" -ForegroundColor Red
            $Corrupted+=$PC
        }
    }
}
if($Corrupted.count -ne 0) {
    New-Item -Path "C:\Users\administrator.UCIONE\Desktop\CorruptedLOG.txt" -Force
    foreach($C in $Corrupted) {
        Add-Content -Path "C:\Users\administrator.UCIONE\Desktop\CorruptedLOG.txt" -Value $C    
    }
}
Write-Host "`nIntegrity sequence ended`n" -ForegroundColor Yellow
Stop-Transcript