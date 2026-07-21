# -----------------------------
# CONFIGURATION
# -----------------------------
$pcListFile = "C:\GitHub\HostsPartialFolder\ZG-F9.txt"
$localFolderToCopy = "C:\randomcerts+gluposti\SQL priprema\AdventureWorksOBP_skripta_za_kreiranje_baze"                 # Folder that contains the .sql file
$remoteFolder = "D$\SQL"                      # Target folder on remote PCs
$sqlFileName = "AdventureWorksOBP_skripta_za_kreiranje_baze.sql"
$sqlcmd = "sqlcmd.exe"
$sqlInstance = "localhost\SQLEXPRESS"

# -----------------------------
# READ PC LIST
# -----------------------------
$pcList = Get-Content $pcListFile

# -----------------------------
# MAIN LOOP
# -----------------------------
foreach ($pc in $pcList) {
    Write-Host "`n➡️ Processing $pc..." -ForegroundColor Cyan

    # STEP 1: Copy folder to remote machine
    $destUNC = "\\$pc\$remoteFolder"
    try {
        Write-Host "📁 Copying files to $destUNC..."
        Copy-Item -Path $localFolderToCopy -Destination $destUNC -Recurse -Force
        Write-Host "✅ Files copied to $pc."
    } catch {
        Write-Host "❌ Failed to copy files to ${pc}: $_" -ForegroundColor Red
        continue
    }

    # STEP 2: Remotely execute the SQL script
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

    $remoteSqlPath = "D:\SQL priprema\$sqlFileName"

    try {
        Invoke-Command -ComputerName $pc -ScriptBlock $remoteScript -ArgumentList $remoteSqlPath, $sqlcmd, $sqlInstance -ErrorAction Stop
    } catch {
        Write-Host "❌ Failed to run SQL import on ${pc}: $_" -ForegroundColor Red
    }
}
