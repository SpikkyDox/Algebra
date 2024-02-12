# Read hostnames from file
$hostnames = Get-Content "E:\SIME\skripte\hosts\ZG-D11.txt"

# Prompt for credentials
$cred = Get-Credential

# Loop through each hostname
foreach ($hostname in $hostnames) {
    # Create new PSSession with remote computer
    $session = New-PSSession -ComputerName $hostname -Credential $cred
    
    # Invoke command to open CMD as administrator and run command
    Invoke-Command -Session $session -ScriptBlock {
        # Change to parent directory twice
        cd ..; cd ..
        # Run the installation command
        & "C:\DaVincinovi" /i /q
        # Wait for UAC prompt to appear
        Start-Sleep -Seconds 10
        # Automatically click "Yes" on UAC prompt
        Add-Type -AssemblyName Microsoft.VisualBasic
        [Microsoft.VisualBasic.Interaction]::AppActivate("User Account Control")
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
        [System.Windows.Forms.SendKeys]::SendWait("{TAB}")
        [System.Windows.Forms.SendKeys]::SendWait("{ENTER}")
    } -ErrorAction SilentlyContinue
    
    # Remove PSSession
    Remove-PSSession $session
}
