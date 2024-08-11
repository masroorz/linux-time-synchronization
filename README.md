# Time Synchronization Script README

## Overview

This is a Linux time synchronization script designed to automatically configure and manage time settings on various Linux distributions. The script currently supports Ubuntu, Debian, CentOS, RedHat, and OpenSuse. 

### Features:
- **Chrony Verification**: Ensures `chrony` is installed on the system before making any changes.
- **Error Handling & Logging**: Captures errors and logs actions taken by the script for troubleshooting.
- **Distro-Agnostic Functions**: Includes functions to verify commands and install packages across different distributions.

## How It Works

### Script Structure
- **Local Variables**: Variables like the current date and time.
- **Functions**: 
  - **installPackage()**: Installs specified packages based on the distribution.
  - **updateRepos()**: Updates package repositories and installs `chrony` if required.
  - **setTimezoneEnableChrony()**: Configures the system timezone and enables `chrony` service.
  - **findOldTimeReplaceNewTime()**: Replaces old NTP servers with new ones in `chrony.conf`.
  - **getDistributionName()**: Detects the Linux distribution.
  - **isPackageInstalled()**: Checks if a package is already installed.

### Supported Time Zones
By default, the script updates the time configuration to use the following servers:
- **TC Active Directory Time**
- **Natural Resources Canada Time**

These servers are defined in the `preferredTimeZone` array within the script and can be modified as needed.

### Logging
All actions performed by the script are logged into a `timeLog.txt` file. This includes package installation results, time zone changes, and service restarts.

### Error Handling
The script performs checks to ensure actions are successful and handles any errors gracefully, providing informative messages in the logs.

## Usage

### Prerequisites
- Root or sudo access is required to run the script.
- The script must be executable. If it's not, run:
  ```bash
  chmod +x time_sync.sh
  ```

### Running the Script
Execute the script with root privileges:
```bash
sudo ./time_sync.sh
```

### Customizing Time Zones
To use different NTP servers, modify the `preferredTimeZone` array in the `findOldTimeReplaceNewTime` function with your preferred servers.

## Supported Distributions
- **Ubuntu**
- **Debian**
- **CentOS**
- **RedHat**
- **OpenSuse**

The script handles each distribution uniquely, ensuring compatibility with package managers and system configurations.

### Backup
Before making any changes, the script creates a backup of the `chrony.conf` file as `chrony.conf.original`.

## Conclusion
This script provides a straightforward method to synchronize time settings across various Linux distributions. It's designed to be easy to use and customizable, making it a versatile tool for administrators managing time configurations on multiple Linux systems.
