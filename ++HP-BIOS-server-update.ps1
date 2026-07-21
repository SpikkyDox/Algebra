# ============================================
# HP BIOS Remote Update - Server Side Script
# ============================================

$PCList        = "C:\GitHub\Hosts\ZG-C3.txt"
$CMSLSource    = "\\ZG-AMT-01\temp\hp-cmsl-1.8.5.exe"   # <-- adjust path
$BIOSPassword  = "Pa55w.rd"                           # <-- change if needed
$LogRoot       = "C:\Scripts\HP-BIOS-Logs"
$ReportFile    = "$LogRoot\Summary-$(Get-Date -Format yyyyMMdd-HHmm).csv"

if (!(Test-Path $LogRoot)) {
    New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null
}

$Results = @()
$Computers = Get-Content $PCList

foreach ($Computer in $Computers) {

    Write-Host "===== $Computer =====" -ForegroundColor Cyan

    $Status = "UNKNOWN"
    $ErrorMessage = ""
    $Model = ""
    $CurrentBIOS = ""

    # 1️⃣ Check if PC is online
    if (!(Test-Connection $Computer -Count 1 -Quiet)) {
        Write-Host "Offline" -ForegroundColor Yellow
        $Status = "OFFLINE"
    }
    else {
        try {

            $Result = Invoke-Command -ComputerName $Computer -ScriptBlock {

                param($CMSLSource, $BIOSPassword)

                $Output = [ordered]@{
                    Model        = ""
                    CurrentBIOS  = ""
                    Status       = ""
                    Error        = ""
                }

                try {

                    $Model = (Get-CimInstance Win32_ComputerSystem).Model
                    $BIOS  = (Get-CimInstance Win32_BIOS).SMBIOSBIOSVersion

                    $Output.Model = $Model
                    $Output.CurrentBIOS = $BIOS

                    if ($Model -notlike "*HP*") {
                        $Output.Status = "NOT_HP"
                        return $Output
                    }

                    # Install CMSL if missing
                    if (-not (Get-Module -ListAvailable -Name HP.ClientManagement)) {

                        Copy-Item $CMSLSource "C:\Windows\Temp\hp-cmsl.exe" -Force
                        Start-Process "C:\Windows\Temp\hp-cmsl.exe" -ArgumentList "/silent" -Wait
                        Start-Sleep 8
                    }

                    Import-Module HP.ClientManagement -ErrorAction Stop
                    Import-Module HP.Private -ErrorAction Stop

                    $UpdateAvailable = Get-HPBIOSUpdates -Check

                    if ($UpdateAvailable -eq $false) {

                        Get-HPBIOSUpdates -Flash `
                            -Password $BIOSPassword `
                            -Bitlocker Suspend `
                            -Yes

                        $Output.Status = "FLASHING_REBOOT_REQUIRED"
                    }
                    else {
                        $Output.Status = "UP_TO_DATE"
                    }

                }
                catch {
                    $Output.Status = "FAILED"
                    $Output.Error  = $_.Exception.Message
                }

                return $Output

            } -ArgumentList $CMSLSource, $BIOSPassword -ErrorAction Stop

            $Status      = $Result.Status
            $ErrorMessage= $Result.Error
            $Model       = $Result.Model
            $CurrentBIOS = $Result.CurrentBIOS

        }
        catch {
            $Status = "WINRM_FAILED"
            $ErrorMessage = $_.Exception.Message
        }
    }

    # Save summary row
    $Results += [pscustomobject]@{
        Computer    = $Computer
        Model       = $Model
        BIOS        = $CurrentBIOS
        Status      = $Status
        Error       = $ErrorMessage
        Timestamp   = Get-Date
    }

    Write-Host "Status: $Status" -ForegroundColor Green
}

# Export summary
$Results | Export-Csv $ReportFile -NoTypeInformation

Write-Host "`n===== COMPLETE =====" -ForegroundColor Cyan
Write-Host "Report saved to: $ReportFile"
