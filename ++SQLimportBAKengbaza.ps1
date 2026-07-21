# --- CONFIG ---
$pcList = Get-Content "C:\GitHub\Hosts\ZG-F12.txt"
$bakLocalPath = "C:\AdventureWorksENG.bak"  # Local path to .bak on your machine
$bakRemotePath = "D:\AdventureWorksENG.bak" # Remote path on target PCs
$sqlcmd = "sqlcmd.exe"
$sqlInstance = "localhost\SQLEXPRESS"
$databaseName = "AdventureWorksENG"

# --- SQL RESTORE SCRIPT TEMPLATE ---
$restoreScript = @"
USE [master];
IF DB_ID('$databaseName') IS NOT NULL
BEGIN
    ALTER DATABASE [$databaseName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE [$databaseName];
END;

RESTORE DATABASE [$databaseName]
FROM DISK = N'$bakRemotePath'
WITH MOVE 'AdventureWorksENG' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\$databaseName.mdf',
     MOVE 'AdventureWorksENG_log' TO 'C:\Program Files\Microsoft SQL Server\MSSQL16.SQLEXPRESS\MSSQL\DATA\$databaseName.ldf',
     REPLACE;
"@

# Save SQL to a temp file locally
$tempSqlFile = "$env:TEMP\restore_eng.sql"
$restoreScript | Out-File -Encoding ASCII -FilePath $tempSqlFile

# --- DEPLOY LOOP ---
foreach ($pc in $pcList) {
    Write-Host "`n➡️ Working on $pc..." -ForegroundColor Cyan

    try {
        # 1. Ensure D:\SQL priprema exists remotely
        $remoteBakDir = "\\$pc\D$\SQL priprema"
        if (-Not (Test-Path $remoteBakDir)) {
            New-Item -ItemType Directory -Path $remoteBakDir -Force | Out-Null
        }

        # 2. Copy .bak file to remote machine
        Copy-Item -Path $bakLocalPath -Destination $remoteBakDir -Force
        Write-Host "✔️ Copied .bak file to $pc"

        # 3. Ensure C:\Temp exists remotely
        Invoke-Command -ComputerName $pc -ScriptBlock {
            if (-Not (Test-Path "C:\Temp")) {
                New-Item -ItemType Directory -Path "C:\Temp" -Force | Out-Null
            }
        }

        # 4. Copy SQL restore script to remote C:\Temp
        $remoteSqlFile = "\\$pc\C$\Temp\restore_eng.sql"
        Copy-Item -Path $tempSqlFile -Destination $remoteSqlFile -Force
        Write-Host "✔️ Copied restore SQL script to $pc"

        # 5. Execute the restore script remotely
        $remoteScript = {
            param($sqlcmd, $sqlInstance, $sqlFile)
            $args = "-S `"$sqlInstance`" -i `"$sqlFile`""
            $proc = Start-Process -NoNewWindow -Wait -FilePath $sqlcmd -ArgumentList $args -PassThru
            if ($proc.ExitCode -eq 0) {
                "✅ Database restored successfully."
            } else {
                "❌ Restore failed. Exit code: $($proc.ExitCode)"
            }
        }

        Invoke-Command -ComputerName $pc -ScriptBlock $remoteScript `
                       -ArgumentList $sqlcmd, $sqlInstance, "C:\Temp\restore_eng.sql" `
                       -ErrorAction Stop |
            ForEach-Object { Write-Host $_ }

    } catch {
        Write-Host "❌ Error on ${pc}: $_" -ForegroundColor Red
    }
}
