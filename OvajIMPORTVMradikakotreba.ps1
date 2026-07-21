# Set variables
$vmConfigPath = "D:\PYT_H-01%4724\Virtual Machines\14EF268D-9151-47DA-8E11-FFDDD4EA8F4F.vmcx" # path to virtual machine configuration file
$vmConfigPath = "D:\PYT_H-01%4724\Virtual Machines\14EF268D-9151-47DA-8E11-FFDDD4EA8F4F.vmcx" # path to virtual machine configuration file
$hostsFilePath = "C:\partial.txt" # path to file containing Hyper-V host name
$hostName = Get-Content $hostsFilePath # read the host name from the file
# $vmName = "Python" # name of the virtual machine
$vhdPath = "D:\PYT_H-01%4724" # path to destination folder for VHD files

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
