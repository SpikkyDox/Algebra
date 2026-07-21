import subprocess

# Path to the notepad file containing the list of PCs
pc_list_file = 'C:\GitHub\Hosts\ZG-C5.txt'

# Visual Studio Code command to install extensions
vscode_command = 'code --install-extension'

# Extensions to install
extensions = [
    'ms-python.python',  # Python Extension
    'ms-toolsai.jupyter'  # Jupyter Notebook Extension
]

def install_extensions_on_pc(pc_name):
    try:
        # Connect to the PC and install each extension
        for extension in extensions:
            command = f'ssh {pc_name} {vscode_command} {extension}'
            subprocess.run(command, shell=True, check=True)
        print(f"Extensions installed successfully on {pc_name}")
    except subprocess.CalledProcessError as e:
        print(f"Failed to install extensions on {pc_name}: {e}")

def main():
    # Read the list of PCs from the notepad file
    with open(pc_list_file, 'r') as file:
        pcs = file.read().splitlines()

    # Install extensions on each PC
    for pc in pcs:
        install_extensions_on_pc(pc)

if __name__ == "__main__":
    main()