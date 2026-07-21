@echo off
setlocal enabledelayedexpansion

:: === CONFIGURATION ===
set PSEXEC_PATH="C:\Tools\PsExec.exe"        :: Adjust to where PsExec.exe is located
set TARGET_LIST="C:\GitHub\Hosts\ZG-D5.txt"                  :: Text file with hostnames/IPs, one per line
set CMD_TO_RUN=winrm quickconfig -quiet

:: === LOOP THROUGH TARGETS ===
for /f %%i in (%TARGET_LIST%) do (
    echo ==================================================
    echo [*] Enabling WinRM on: %%i
    %PSEXEC_PATH% \\%%i -s -nobanner %CMD_TO_RUN%
)

echo.
echo [*] Done pushing WinRM via PsExec.
pause
