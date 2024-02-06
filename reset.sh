#!/bin/bash
#ZFS install reset script

## Help output function
helpFunction()
{
   echo ""
   echo "Arch Linux on ZFS Undo script. Used to reset disks to retry install"
   echo "This is used for debugging purposes"
   echo ""
   echo "Usage: $0 -c ./path/to/config.env"
   echo -e "\t-c Specify path to config file to pass variables. Example: -c ./path/to/config.env"
   echo ""
   echo "Usage: $0 -d /dev/sda -z zroot"
   echo ""
   echo -e "\t-d Specify which disk device to use. Example: -d /dev/sda"
   echo -e "\t-z Desired name for the root ZFS ZPool. Example: -z zroot -- Defaults to zroot if not specified"
   echo ""
   exit 1 # Exit script after printing help
}

## 
while getopts "d:z:c:v:" opt
do
   case "$opt" in
      d ) DISK="$OPTARG" ;;
      z ) ZPOOLNAME="$OPTARG" ;;
      c ) CONFIGFILE="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

## Check to see if CONFIGFILE is set. If not, then check to see if DISK and ROOTPASS are set
## If CONFIGFILE is set, source file to bring in variables
if [ -z "$CONFIGFILE" ] 
then
   if [ -z "$DISK" ]
   then
      echo "specifying a disk and a root password are required";
      helpFunction
   fi
else
   source ${CONFIGFILE}
fi

## If ZPool name is not specified, default to zroot
if [ -z "$ZPOOLNAME" ]
then
   ZPOOLNAME=zroot
fi

## Turn off swap so the partition is no longer in use
swapoff -a

## Unmount EFI partition
umount /mnt/efi

## Unmount ZFS datasets
zfs umount ${ZPOOLNAME}/ROOT/default
zfs umount -a

## Export the ZFS Pool
zpool export ${ZPOOLNAME}


parted -s ${DISK} \
    rm 1 \
    rm 2 \
    rm 3 \
    print