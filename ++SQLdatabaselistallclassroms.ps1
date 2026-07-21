# === CONFIG ===
$hostFilesPath = "C:\GitHub\HostsPartialFolder"
$outputCsv     = "C:\GitHub\AllDatabasesV5-GOTOVO.csv"
$sqlcmd        = "sqlcmd.exe"
$sqlInstance   = "localhost\SQLEXPRESS"

# === DB CLASSIFICATION ===
$highlightDbs  = @("AdventureWorksOBP", "AdventureWorksENG")
$systemDbs     = @("master", "tempdb", "model", "msdb")

# === INIT RESULTS ===
if (Test-Path $outputCsv) { Remove-Item $outputCsv }
$allResults = @()

# === PROCESS HOSTS ===
Get-ChildItem -Path $hostFilesPath -Filter *.txt | ForEach-Object {
    $classroomName = $_.BaseName
    $pcList = Get-Content $_.FullName

    foreach ($pc in $pcList) {
        Write-Host "`n🖥️  $pc  (Classroom: $classroomName)" -ForegroundColor White

        try {
            $dbs = Invoke-Command -ComputerName $pc -ScriptBlock {
                param($sqlcmd, $sqlInstance)
                $query = "SET NOCOUNT ON; SELECT name FROM sys.databases"
                & $sqlcmd -S $sqlInstance -Q $query -h -1
            } -ArgumentList $sqlcmd, $sqlInstance

            $cleanDbs = $dbs | Where-Object { $_ -and $_.Trim() -ne "" }

            foreach ($db in $cleanDbs) {
                $dbName = $db.Trim()
                $color  = "Yellow"

                if ($highlightDbs -contains $dbName) {
                    $color = "Blue"
                } elseif ($systemDbs -contains $dbName) {
                    $color = "Gray"
                }

                Write-Host "   $dbName" -ForegroundColor $color

                $allResults += [PSCustomObject]@{
                    Classroom = $classroomName
                    Hostname  = $pc
                    Database  = $dbName
                }
            }
        }
        catch {
            Write-Warning "❌ $pc failed: $_"
            $allResults += [PSCustomObject]@{
                Classroom = $classroomName
                Hostname  = $pc
                Database  = "ERROR: $_"
            }
        }
    }
}

# === EXPORT TO CSV ===
$allResults | Export-Csv -Path $outputCsv -NoTypeInformation -Encoding UTF8
Write-Host "`n✅ CSV export complete: $outputCsv" -ForegroundColor Green
