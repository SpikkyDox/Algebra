import os

# Path to the file containing PC names/IPs
pc_list_file = "C:\GitHub\Hosts\ZG-C5.txt"

# Commands to execute remotely
commands = [
    'code --install-extension ms-python.python',
    'code --install-extension ms-toolsai.jupyter',
    'python -m ensurepip',
    'python -m pip install --upgrade pip',
    'pip install matplotlib',
    'pip install requests',
    'pip install bs4'
]

# Function to execute commands remotely using PsExec
def install_on_remote_pc(pc_name):
    for cmd in commands:
        remote_cmd = f'psexec \\\\{pc_name} -s -i cmd /c "{cmd}"'
        print(f"Executing on {pc_name}: {cmd}")
        os.system(remote_cmd)

# Read the list of PCs from file
if os.path.exists(pc_list_file):
    with open(pc_list_file, "r") as file:
        pcs = [line.strip() for line in file.readlines() if line.strip()]
    
    for pc in pcs:
        install_on_remote_pc(pc)
else:
    print(f"Error: {pc_list_file} not found!")
