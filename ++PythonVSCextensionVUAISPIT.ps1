# --- CONFIG ---
$pcList = Get-Content "C:\GitHub\Hosts\ZG-D3.txt"
$extensionId = "ms-python.python"
$vsCodeCLI = "C:\Program Files\Microsoft VS Code\bin\code.cmd"

# --- REMOTE SCRIPT ---
$remoteScript = {
    param($vsCodeCLIPath, $extensionId)

    $userProfile = "C:\Users\vuaispit"
    $appData = "$userProfile\AppData\Roaming"

    if (-Not (Test-Path $vsCodeCLIPath)) {
        Write-Host "❌ VS Code CLI not found at expected path: $vsCodeCLIPath"
        return
    }

    # Set user environment for code CLI
    $env:USERPROFILE = $userProfile
    $env:APPDATA = $appData
    $env:VSCODE_PORTABLE = ""

    Write-Host "➡️ Checking VS Code extensions for vuaispit..."

    $installed = & $vsCodeCLIPath --list-extensions
    if ($installed -contains $extensionId) {
        Write-Host "✔️ Python extension already installed for vuaispit"
    } else {
        Write-Host "📦 Installing Python extension for vuaispit..."
        & $vsCodeCLIPath --install-extension $extensionId --force
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Installed Python extension for vuaispit"
        } else {
            Write-Host "❌ Failed to install extension (Exit code: $LASTEXITCODE)"
        }
    }
}

# --- MAIN LOOP ---
foreach ($pc in $pcList) {
    Write-Host "`n🔄 Working on $pc..." -ForegroundColor Cyan
    try {
        Invoke-Command -ComputerName $pc -ScriptBlock $remoteScript -ArgumentList $vsCodeCLI, $extensionId -ErrorAction Stop
    } catch {
        Write-Host "❌ Failed on ${pc}: $_" -ForegroundColor Red
    }
}
