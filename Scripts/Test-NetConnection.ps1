$notepadFilePath = "E:\Sime\hosts\ZG-C2.txt"
$hostsList = Get-Content $notepadFilePath

foreach ($currentHost in $hostsList) {
    $connectionStatus = Test-NetConnection -ComputerName $currentHost

    if ($connectionStatus) {
        write-host "Host $currentHost has internet connection."
    } else {
        write-host "Host $currentHost does not have internet connection."
    }
}
