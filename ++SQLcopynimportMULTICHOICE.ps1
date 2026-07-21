# -----------------------------
# CONFIGURATION
# -----------------------------
$pcListFileF1 = "C:\GitHub\Hosts\ZG-F9.txt"
# $pcListFileF2 = "C:\GitHub\Hosts\ZG-F2.txt"

# Read and combine PC list, remove empty lines and duplicates
$pcList = Get-Content $pcListFileF1, $pcListFileF2 |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    Sort-Object -Unique

$localFolderToCopy = "C:\SQL priprema"
$remoteFolder = "D$\SQL priprema"
$sqlFileName = "AdventureWorksOBP_skripta_za_kreiranje_baze.sql"
$sqlcmd = "sqlcmd.exe"
$sqlInstance = "localhost\SQLEXPRESS"

Write-Host "`n🔍 Hosts to process:" -ForegroundColor Green
$pcList | ForEach-Object { Write-Host " - $_" }

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
