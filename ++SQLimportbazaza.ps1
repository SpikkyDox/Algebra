
$pcList = Get-Content "C:\GitHub\Hosts\ZG-C5.txt"


$sqlFile = "D:\SQL priprema\AdventureWorksOBP_skripta_za_kreiranje_baze.sql"
$sqlcmd = "sqlcmd.exe"
$sqlInstance = "localhost\SQLEXPRESS"

#
$remoteScript = {
    param($sqlFile, $sqlcmd, $sqlInstance)

    if (-Not (Test-Path $sqlFile)) {
        Write-Output "❌ SQL file not found: $sqlFile"
        exit 1
    }

    $args = "-S `"$sqlInstance`" -i `"$sqlFile`""
    $result = Start-Process -NoNewWindow -Wait -FilePath $sqlcmd -ArgumentList $args -PassThru

    if ($result.ExitCode -eq 0) {
        Write-Output "✅ Successfully imported database."
    } else {
        Write-Output "❌ Import failed. Exit code: $($result.ExitCode)"
    }
}


foreach ($pc in $pcList) {
    Write-Host "`n➡️ Running on $pc..." -ForegroundColor Cyan

    try {
        Invoke-Command -ComputerName $pc -ScriptBlock $remoteScript -ArgumentList $sqlFile, $sqlcmd, $sqlInstance -ErrorAction Stop
    } catch {
        Write-Host "❌ Failed to connect to ${pc}: $_" -ForegroundColor Red
    }
}
