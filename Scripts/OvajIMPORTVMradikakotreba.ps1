# Set variables
$vmConfigPath = "E:\Python\Virtual Machines\C31A2F28-8B97-4F04-988F-34D35697A8C4.vmcx" # path to virtual machine configuration file
$vmConfigPath = "E:\Python\Virtual Machines\C31A2F28-8B97-4F04-988F-34D35697A8C4.vmcx" # path to virtual machine configuration file
$hostsFilePath = "C:\Sime\Hosts\ZG-C1-partial.txt" # path to file containing Hyper-V host name
$hostName = Get-Content $hostsFilePath # read the host name from the file
# $vmName = "Python" # name of the virtual machine
$vhdPath = "D:\Python2024\Python\Virtual Hard Disks" # path to destination folder for VHD files

# Set switch parameter to copy VHD files
$shouldCopyVhd = $true

# Get name of virtual switch to connect network adapter to
# $switchName = Get-VMSwitch -SwitchType External -ComputerName $hostName | Select-Object -ExpandProperty Name

# Import VM to Hyper-V host
Import-VM -Path $vmConfigPath -GenerateNewId -VhdDestinationPath $vhdPath -VirtualMachinePath (Split-Path $vmConfigPath) -ComputerName $hostName -Copy:$shouldCopyVhd -Verbose

# Connect VM to virtual switch
# $vm = Get-VM -ComputerName $hostName -Name $vmName
# $vmNetworkAdapter = Get-VMNetworkAdapter -VM $vm
# Connect-VMNetworkAdapter -VMNetworkAdapter $vmNetworkAdapter -SwitchName $switchName -Verbose

# Rename VM to specified name
# Set-VM -VM $vm -Name $vmName -Verbose
