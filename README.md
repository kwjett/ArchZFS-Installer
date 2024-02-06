# ArchZFS-Installer

Install script to automagically install Arch on ZFS from an archiso.

```
curl -O https://github.com/kwjett/ArchZFS-Installer/raw/branch/main/archzfs-install.sh && chmod +x archzfs-install.sh && curl -o ./config.env https://github.com/kwjett/ArchZFS-Installer/raw/branch/main/config.env.example
```
```
vim ./config.env
```
```
./archzfs-install.sh -c ./config.env
```

Arch Linux on ZFS install script
Start archiso system, passwd root, then ssh to system.
Run this script to  magically install arch running on ZFS

```
Usage: ./archzfs-install.sh -c ./path/to/config.env

	-c Specify path to config file to pass variables. Example: -c ./path/to/config.env

Usage: ./archzfs-install.sh -d /dev/sda -z zroot -r rpassword -u username -p password -t America/Denver

	-d Specify which disk device to use. Example: -d /dev/sda
	-z Desired name for the root ZFS ZPool. Example: -z zroot -- Defaults to zroot if not specified
	-r Specify password for root user. Example: -r supersecurepassword123!
	-u Creates a system user with a specified username. Example: -u username
	-p Specify password for system user. Example: -p password
	-t Timezone of the system. Example: -t America/Denver
	-v Verbose output
```