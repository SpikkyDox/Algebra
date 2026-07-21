# Path to the file containing the list of PCs
$pcListPath = "\\10.10.253.242\Hosts\ZG-D10.txt"

# Define the Python modules to install
$modules = @(    "azure-cognitiveservices-search-websearch",
    "azure-cognitiveservices-vision-computervision",
    "azure-cognitiveservices-vision-contentmoderator",
    "azure-cognitiveservices-vision-customvision",
    "cognitive-face",
    "azure-cognitiveservices-search-imagesearch",
    "azure-cognitiveservices-search-entitysearch",
    "azure-cognitiveservices-language-textanalytics",
    "azure-cognitiveservices-language-luis")

# Read the list of PCs
$pcList = Get-Content $pcListPath

# Prompt for credentials once
$cred = Get-Credential

foreach ($pc in $pcList) {
    Write-Host "Connecting to $pc..." -ForegroundColor Cyan

    Invoke-Command -ComputerName $pc -Credential $cred -ScriptBlock {
        param($modules)

        # Check if Python is installed
        $python = Get-Command python -ErrorAction SilentlyContinue
        if ($python) {
            Write-Host "Python found on $env:COMPUTERNAME. Installing modules system-wide..." -ForegroundColor Cyan
            
            # Upgrade pip first
            python -m pip install --upgrade pip --break-system-packages

            # Install each module individually
            foreach ($module in $modules) {
                Write-Host "Installing $module..." -ForegroundColor Yellow
                $installResult = python -m pip install $module --break-system-packages 2>&1
                
                if ($installResult -match "ERROR") {
                    Write-Host "❌ ERROR installing $module on $env:COMPUTERNAME!" -ForegroundColor Red
                    Write-Host "$installResult" -ForegroundColor DarkRed
                } else {
                    Write-Host "✅ Installed $module on $env:COMPUTERNAME" -ForegroundColor Green
                }
            }

            Write-Host "✅ Installation completed on $env:COMPUTERNAME!" -ForegroundColor Green
        } else {
            Write-Host "❌ ERROR: Python is not installed on $env:COMPUTERNAME!" -ForegroundColor Red
        }
    } -ArgumentList (, $modules)  # <- FIXED passing array correctly
}

Write-Host "✅ Installation completed on all PCs!" -ForegroundColor Green
