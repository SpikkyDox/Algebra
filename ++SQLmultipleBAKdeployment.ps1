# -----------------------------
# CONFIGURATION
# -----------------------------
$pcListFileF1 = "C:\GitHub\Hosts\ZG-D6.txt"
$pcListFileF2 = "C:\GitHub\Hosts\ZG-C6.txt"
$pcListFileF3 = "C:\GitHub\Hosts\ZG-D11.txt"
$pcListFileF4 = "C:\GitHub\Hosts\ZG-D10.txt"
$pcListFileF5 = "C:\GitHub\Hosts\ZG-D12.txt"
$pcListFileF6 = "C:\GitHub\Hosts\ZG-C10.txt"
$pcListFileF7 = "C:\GitHub\Hosts\ZG-F6.txt"

# Read and combine PC list, remove empty lines and duplicates
$pcList = Get-Content $pcListFileF1, $pcListFileF2,$pcListFileF3.$pcListFileF4.$pcListFileF5.$pcListFileF6.$pcListFileF7 |
    Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
    Sort-Object -Unique

$localFolderToCopy = "C:\baze_podataka"
$remoteFolder = "D$\baze_podataka"
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

    $remoteSqlPath = "D:\baze_podataka\$sqlFileName"

    try {
        Invoke-Command -ComputerName $pc -ScriptBlock $remoteScript -ArgumentList $remoteSqlPath, $sqlcmd, $sqlInstance -ErrorAction Stop
    } catch {
        Write-Host "❌ Failed to run SQL import on ${pc}: $_" -ForegroundColor Red
    }
}
