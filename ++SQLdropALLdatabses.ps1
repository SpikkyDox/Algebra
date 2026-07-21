# === CONFIG ===
$hostFilesPath = "C:\GitHub\test4"
$sqlcmd        = "sqlcmd.exe"
$sqlInstance   = "localhost\SQLEXPRESS"
$systemDbs     = @("master", "tempdb", "model", "msdb")

# === PROCESS HOSTS ===
Get-ChildItem -Path $hostFilesPath -Filter *.txt | ForEach-Object {
    $classroomName = $_.BaseName
    $pcList = Get-Content $_.FullName

    foreach ($pc in $pcList) {
        Write-Host "`n🧹 Cleaning databases on $pc (Classroom: $classroomName)" -ForegroundColor Cyan

        try {
            $userDbs = Invoke-Command -ComputerName $pc -ScriptBlock {
                param($sqlcmd, $sqlInstance, $systemDbs)
                $query = "SET NOCOUNT ON; SELECT name FROM sys.databases"
                $dbs = & $sqlcmd -S $sqlInstance -Q $query -h -1
                $dbs | Where-Object { $_ -and ($systemDbs -notcontains $_.Trim()) }
            } -ArgumentList $sqlcmd, $sqlInstance, $systemDbs

            foreach ($db in $userDbs) {
                $dbName = $db.Trim()
                Write-Host "   ❌ Dropping: $dbName" -ForegroundColor Red

                try {
                    Invoke-Command -ComputerName $pc -ScriptBlock {
                        param($sqlcmd, $sqlInstance, $dbName)
                        $dropQuery = "ALTER DATABASE [$dbName] SET SINGLE_USER WITH ROLLBACK IMMEDIATE; DROP DATABASE [$dbName]"
                        & $sqlcmd -S $sqlInstance -Q $dropQuery
                    } -ArgumentList $sqlcmd, $sqlInstance, $dbName
                }
                catch {
                    Write-Host "     ⚠️ Failed to drop ${dbName}: $_" -ForegroundColor Yellow
                }
            }
        }
        catch {
            Write-Host "❌ Failed to list/drop on ${pc}: $_" -ForegroundColor Red
        }
    }
}

Write-Host "`n✅ Cleanup done." -ForegroundColor Green
