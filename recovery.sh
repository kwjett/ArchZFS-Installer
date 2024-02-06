#!/bin/bash
## Arch Linux on ZFS Recover script
## Start archiso system, passwd root, then ssh to system.

VERBOSE=1

## Help output function
helpFunction()
{
   echo ""
   echo "Arch Linux on ZFS recovery script"
   echo "Start archiso system, passwd root, then ssh to system."
   echo "Run this script to automagically get a usable recovery mode for Arch running on ZFS"
   echo ""
   echo "Usage: $0 -c ./path/to/config.env"
   echo -e "\t-c Specify path to config file to pass variables. Example: -c ./path/to/config.env"
   echo ""
   echo "Usage: $0 -d /dev/sda -z zroot -r rpassword -u username -p password -t America/Denver"
   echo ""
   echo -e "\t-d Specify which disk device to use. Example: -d /dev/sda"
   echo -e "\t-z Desired name for the root ZFS ZPool. Example: -z zroot -- Defaults to zroot if not specified"
   echo -e "\t-r Specify password for root user. Example: -r seanlickswindows123!"
   echo -e "\t-u Creates a system user with a specified username. Example: -u kyle"
   echo -e "\t-p Specify password for system user. Example: -p smashdrywall"
   echo -e "\t-t Timezone of the system. Example: -t America/Denver"
   echo -e "\t-v Verbose output" # Not working?
   echo ""
   exit 1 # Exit script after printing help
}

## 
while getopts "d:z:r:u:p:t:c:v:" opt
do
   case "$opt" in
      d ) DISK="$OPTARG" ;;
      z ) ZPOOLNAME="$OPTARG" ;;
      r ) ROOTPASS="$OPTARG" ;;
      u ) NEWUSER="$OPTARG" ;;
      p ) PASSWORD="$OPTARG" ;;
      t ) TIMEZONE="$OPTARG" ;;
      c ) CONFIGFILE="$OPTARG" ;;
      v ) VERBOSE=1 ;; # Not working
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

## Send full output to logfile
exec &> >(tee "zfs-recovery.log")

## Verbose mode
if [[ "$verbose" -gt 0 ]]
then
   echo "Config File: ${CONFIGFILE}"
   echo "Disk: ${DISK}"
   echo "Pool Name: ${ZPOOLNAME}"
   echo "Root Password: ${ROOTPASS}"
   echo "User: ${NEWUSER}"
   echo "Password: ${PASSWORD}"
   echo "Timezone: ${TIMEZONE}"
   echo "Additional Packages: ${PACKAGES}"
   exec 3>&1
else
   exec 3>/dev/null
fi

## Automatically rank and save pacman mirrors
echo "Testing and ranking pacman mirrors"
reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

## Refresh pacman database
echo "Refreshing pacman database"
pacman -Syy
echo ""
echo ""

# Load kernel module
if [ -f /sys/module/zfs/version ]
then
    echo  "ZFS is already loaded"
else
   ## Load ZFS Modules automagically
   ## https://eoli3n.github.io/2020/05/01/zfs-install.html
   curl -o /tmp/archzfs.sh -L https://raw.githubusercontent.com/eoli3n/archiso-zfs/master/init
   chmod +x /tmp/archzfs.sh
   bash /tmp/archzfs.sh
   echo -e "\n\e[39m\n" ## fix for weird text display bug after running above script
fi