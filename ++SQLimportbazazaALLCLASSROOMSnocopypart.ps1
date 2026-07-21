# -----------------------------
# CONFIGURATION
# -----------------------------
$hostFolder = "C:\GitHub\HostpartialFolderTEST"                          # Folder with TXT files (e.g. ZG-F1.txt, ZG-F2.txt, etc.)
$sqlFileName = "AdventureWorksOBP_skripta_za_kreiranje_baze.sql"
$remoteSqlPath = "D:\SQL priprema\$sqlFileName"
$sqlcmd = "sqlcmd.exe"
$sqlInstance = "localhost\SQLEXPRESS"

# -----------------------------
# LOAD ALL HOSTS FROM TXT FILES
# -----------------------------
$pcList = Get-ChildItem -Path $hostFolder -Filter *.txt |
    ForEach-Object { Get-Content $_.FullName } |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    Sort-Object -Unique

Write-Host "`n🔍 Hosts to process:" -ForegroundColor Green
$pcList | ForEach-Object { Write-Host " - $_" }

# -----------------------------
# MAIN LOOP
# -----------------------------
foreach ($pc in $pcList) {
    Write-Host "`n➡️ Processing $pc..." -ForegroundColor Cyan

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

    try {
        Invoke-Command -ComputerName $pc -ScriptBlock $remoteScript -ArgumentList $remoteSqlPath, $sqlcmd, $sqlInstance -ErrorAction Stop
    } catch {
        Write-Host "❌ Failed to run SQL import on ${pc}: $_" -ForegroundColor Red
    }
}
