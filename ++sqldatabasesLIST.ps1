$pcList = Get-Content "C:\GitHub\Hosts\ZG-A6.txt"
$sqlcmd = "sqlcmd.exe"
$sqlInstance = "localhost\SQLEXPRESS"

foreach ($pc in $pcList) {
    Write-Host "`n📋 [$pc] Databases:" -ForegroundColor Cyan

    try {
        $dbs = Invoke-Command -ComputerName $pc -ScriptBlock {
            param($sqlcmd, $sqlInstance)
            $query = "SET NOCOUNT ON; SELECT name FROM sys.databases"
            & $sqlcmd -S $sqlInstance -Q $query -h -1
        } -ArgumentList $sqlcmd, $sqlInstance

        # Format output nicely
        $dbsClean = $dbs | Where-Object { $_ -and $_.Trim() -ne "" } | ForEach-Object { $_.Trim() }
        $dbsClean | ForEach-Object { Write-Host " - $_" }

    } catch {
        Write-Host "❌ $pc failed: $_" -ForegroundColor Red
    }
}
