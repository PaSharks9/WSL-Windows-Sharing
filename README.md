# Data Sharing Script (WSL-Windows)

## Overview
`data_sharing.sh` is a Bash script designed to facilitate seamless file transfers between Windows Subsystem for Linux (WSL) and Windows environments. The script provides an interactive menu-driven interface for bidirectional file and directory transfers.

## Features
- Bidirectional file transfer between WSL and Windows
- Interactive menu interface
- Directory structure inspection tool
- Detailed logging system
- Support for both file and directory transfers
- Configurable source and destination directories

## Prerequisites
- Windows Subsystem for Linux (WSL) installed
- Bash shell environment
- Read/Write permissions in both Windows and Linux directories

## Installation
1. Copy the script to your desired location in WSL
2. Make the script executable:
   ```bash
   chmod +x data_sharing.sh
   ```

## Default Directory Structure
The script uses the following default directory structure if no parameters are provided:

### Windows Directories
- Source: `/mnt/c/Users/<username>/Desktop/linux_sharing/export-zone`
- Destination: `/mnt/c/Users/<username>/Desktop/linux_sharing/land-zone`

### Linux Directories
- Source: `<current_directory>/export-zone`
- Destination: `<current_directory>/land-zone`

## Usage

### Basic Usage
```bash
./data_sharing.sh
```

### Custom Directory Configuration
```bash
./data_sharing.sh <windows_source_dir> <windows_dest_dir> <linux_source_dir> <linux_dest_dir>
```

## Menu Options

### Main Menu
1. Import from Windows
2. Export to Windows
- `e`: Exit

### Transfer Menu (Import/Export)
1. File Transfer
2. Directory Transfer
3. Inspect Source Directory
4. Change Source Directory
- `b`: Back to Main Menu

## Directory Inspector Tool
The inspector tool provides basic file system navigation and inspection capabilities:

Available commands:
- `ls`: List directory contents
- `cat`: Display file contents
- `clear`: Clear screen
- `exit`: Exit inspector

**Note**: The inspector tool is restricted to the source directory tree for security purposes.

## Logging System
The script maintains detailed logs of all transfer operations:
- Log Location: `./logs/YYYY_MM_DD.log`
- Logs include:
  - System information
  - Transfer operations
  - Success/Failure status
  - Timestamps

## Color Coding
The script uses color coding for better visibility:
- Red: Errors
- Yellow: Warnings
- Green: Success
- Blue: Information

## Security Features
- Restricted directory navigation
- Permission checks
- Error handling for file operations
- Logging of all operations

## Error Handling
The script includes comprehensive error handling for:
- File/directory existence checks
- Permission issues
- Transfer operations
- Invalid user input

## Limitations
- Cannot navigate outside source directories in the inspector tool
- Command options are not supported in the inspector tool
- Requires appropriate permissions in both Windows and Linux environments

## Best Practices
1. Ensure proper permissions are set for source and destination directories
2. Regularly check logs for any transfer issues
3. Use relative paths when specifying files/directories for transfer
4. Keep the directory structure organized

## Troubleshooting
1. If transfers fail, check:
   - Directory permissions
   - File existence
   - Path validity
2. Consult the log files for detailed error information
3. Ensure WSL has proper access to Windows directories