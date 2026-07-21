# Specify the folder path where your Notepad files are located
$folderPath = "C:\Sime\Hosts"

# Get all Notepad files in the specified folder
$notepadFiles = Get-ChildItem -Path $folderPath -Filter "*.txt"

# Loop through each Notepad file and count the number of lines
foreach ($file in $notepadFiles) {
    $lineCount = 0
    $content = Get-Content $file.FullName
    foreach ($line in $content) {
        # Exclude empty lines from the count
        if (-not [string]::IsNullOrWhiteSpace($line)) {
            $lineCount++
        }
    }
    Write-Output "File $($file.Name) has $lineCount inputs."
}
