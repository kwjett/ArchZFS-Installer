#!/bin/bash
## Arch Linux on ZFS install script
## Start archiso system, passwd root, then ssh to system.

## Set for debugging. Remove once implimented fully as flag
VERBOSE=1

## Help output function
helpFunction()
{
   echo ""
   echo "Arch Linux on ZFS install script"
   echo "Start archiso system, passwd root, then ssh to system."
   echo "Run this script to magically install arch running on ZFS"
   echo ""
   echo "Usage: $0 -c ./path/to/config.env"
   echo -e "\t-c Specify path to config file to pass variables. Example: -c ./path/to/config.env"
   echo ""
   echo "Usage: $0 -d /dev/sda -z zroot -r rpassword -u username -p password -t America/Denver"
   echo ""
   echo -e "\t-d Specify which disk device to use. Example: -d /dev/sda"
   echo -e "\t-z Desired name for the root ZFS ZPool. Example: -z zroot -- Defaults to zroot if not specified"
   echo -e "\t-b Specify bootloader. Options: grub, zfsbootmenu, refind Example: -b grub -- Defaults to rEFInd"
   echo -e "\t-r Specify password for root user. Example: -r supersecurepassword!"
   echo -e "\t-u Creates a system user with a specified username. Example: -u kyle"
   echo -e "\t-p Specify password for system user. Example: -p smashdrywall123"
   echo -e "\t-t Timezone of the system. Example: -t America/Denver"
   echo -e "\t-v Verbose output" # Not working?
   echo ""
   exit 1 # Exit script after printing help
}

## 
while getopts "d:z:r:u:p:t:c:i:v:" opt
do
   case "$opt" in
      d ) DISK="$OPTARG" ;;
      z ) ZPOOLNAME="$OPTARG" ;;
      b ) BOOTLOADER="$OPTARG" ;;
      r ) ROOTPASS="$OPTARG" ;;
      u ) NEWUSER="$OPTARG" ;;
      p ) PASSWORD="$OPTARG" ;;
      t ) TIMEZONE="$OPTARG" ;;
      c ) CONFIGFILE="$OPTARG" ;;
      i ) INTERACTIVE="$OPTARG" ;; ## Might not use this as an option and just assume if no input is taken.
      v ) VERBOSE=1 ;; # Not working
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

if [ "${INTERACTIVE}" == 1 ]; then 
   ## Interactive mode to set variables
   echo "Which disk do you want to install Arch Linux using ZFS to?"
   read DISK
   echo "You have selected ${DISK}"
   echo ""
   echo ""

   echo "Provide a name for the ZFS Pool that will get created for the root filesystem"
   echo "If nothing is provided, then the default of zroot will be used"
   read ZPOOLNAME
   ## If ZPool name is not specified, default to zroot
   if [ -z "$ZPOOLNAME" ]
   then
      ZPOOLNAME=zroot
   fi
   echo "Root ZFS Pool name will be ${ZPOOLNAME}"
   echo ""
   echo ""

   echo "Which bootloader would you like to use? Defaults to rEFInd currently if nothing is provided"
   echo "Options are:"
   echo "refind - rEFInd with zfsbootmenu. This will be deprecated eventually"
   echo "zfsbootmenu - This will be default eventually"
   echo "grub - GRUB"
   read BOOTLOADER
   echo "${BOOTLOADER} will be used"
   echo ""
   echo ""

   echo "Set a root password"
   read ROOTPASS
   echo "root password set"
   echo ""
   echo ""

   echo "Create a new user for this system?"
   ## Insert yes/no method here at some point
   read "NEWUSER"
   echo "Username ${NEWUSER} will be created"
   echo ""
   echo ""
   ## Check to see if user account will be created and require password to be specified.
   if [ -z "$NEWUSER" ]
   then
      echo "No username specified. Skipping add user process"
      echo ""
      echo ""
   else
      if [ -z "$PASSWORD" ]
      then
         echo "Password must be set when configuring a user";
         read PASSWORD
         echo "Password for ${NEWUSER} has been set!"
         echo ""
         echo ""
      fi
   fi
   echo "Provide a timezone for this system"
   echo "Example: America/Denver"
   read TIMEZONE
else
   ## Check to see if CONFIGFILE is set. If not, then check to see if DISK and ROOTPASS are set
   ## If CONFIGFILE is set, source file to bring in variables
   if [ -z "$CONFIGFILE" ] 
   then
      if [ -z "$DISK" ] || [ -z "$ROOTPASS" ]
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

   ## Check status of BOOTLOADER. If nothing is set, default to ZFSBootMenu
   if [ -z "$BOOTLOADER" ]
   then
      echo "No bootloader specified. Defaulting to ZFSBootMenu"
      echo ""
      echo ""
      BOOTLOADER=zfsbootmenu
   fi

   ## Check to see if user account will be created and require password to be specified.
   if [ -z "$NEWUSER" ]
   then
      echo "No username specified. Skipping add user process"
      echo ""
      echo ""
   else
      if [ -z "$PASSWORD" ]
      then
         echo "Password must be set when configuring a user";
         helpFunction
      else
         echo "Username ${NEWUSER} with password ${PASSWORD} will be created"
         sleep 5
      fi
   fi
fi

## Send full output to logfile
exec &> >(tee "zfs-installer.log")

if [ "${VERBOSE}" == 1 ]; then 
   echo "Config File: ${CONFIGFILE}"
   echo "Disk: ${DISK}"
   echo "Pool Name: ${ZPOOLNAME}"
   echo "Root Password: ${ROOTPASS}"
   echo "User: ${NEWUSER}"
   echo "Password: ${PASSWORD}"
   echo "Timezone: ${TIMEZONE}"
   echo "Additional Packages: ${PACKAGES}"
   echo ""
   echo ""
fi

## Verbose mode
if [[ "$verbose" -gt 0 ]]
then
   exec 3>&1
else
   exec 3>/dev/null
fi

## Automatically rank and save pacman mirrors
# echo "Testing and ranking pacman mirrors"
# reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

## Refresh pacman database
echo "Refreshing pacman database"
pacman -Syy
echo ""
echo ""

# Load ZFS kernel module
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

## Generate /etc/hostid
zgenhostid

## Partition scheme if using zfsbootmgr
echo "Partitioning ${DISK}"
parted -s ${DISK} \
    mklabel gpt \
    mkpart '"EFI system partition"' fat32 1MiB 500MiB \
    mkpart '"swap partition"' linux-swap 500MiB 16.5GiB \
    mkpart '"zroot partition"' hfs 16.5GiB 100% \
    set 1 esp on \
    set 2 swap on \
    print
echo ""
echo ""
sleep 5  ## Slow down the script to see whats happening

## Create Fat32 filesystem for EFI partition:
echo "Create filesystem for EFI partition"
mkfs.fat -F32 ${DISK}1
echo ""
echo ""

## Create and enable Swap on partition 2
echo "Creating swap space and enabling"
mkswap -f ${DISK}2
swapon ${DISK}2
echo ""
echo ""
sleep 5  ## Slow down the script to see whats happening

## Create ZFS Pool to install Arch onto
echo "Creating ${ZPOOLNAME} pool"
zpool create \
  -o ashift=12 \
  -O acltype=posixacl \
  -O canmount=off \
  -O dnodesize=auto \
  -O normalization=formD \
  -O atime=off \
  -O xattr=sa \
  -O mountpoint=none \
  -O compression=lz4 \
  -R /mnt ${ZPOOLNAME} /dev/vda3
zpool list
echo ""
echo ""
sleep 5  ## Slow down the script to see whats happening

## Create ZFS Datasets
echo "Creating ZFS datasets for ${ZPOOLNAME}"
zfs create -o mountpoint=none ${ZPOOLNAME}/data
zfs create -o mountpoint=none ${ZPOOLNAME}/ROOT
zfs create -o mountpoint=/ -o canmount=noauto ${ZPOOLNAME}/ROOT/default
zfs create -o mountpoint=/home ${ZPOOLNAME}/data/home

## Create boot dataset
#zfs create -o canmount=off -o mountpoint=none bpool/BOOT
zfs create -o mountpoint=/boot ${ZPOOLNAME}/boot 

## Create system datasets which though not required are Strongly recommended
zfs create -o mountpoint=/var -o canmount=off ${ZPOOLNAME}/var
zfs create ${ZPOOLNAME}/var/log
zfs create -o mountpoint=/var/lib -o canmount=off ${ZPOOLNAME}/var/lib

## Optional Datasets for libvirt and Docker
#zfs create $ZPOOLNAME/var/lib/libvirt

## If this system will use Docker (which manages its own datasets & snapshots):
zfs create -o com.sun:auto-snapshot=false  ${ZPOOLNAME}/var/lib/docker
echo ""
echo ""

sleep 5  ## Slow down the script to see whats happening

## Export and reimport the pool
echo "Exporting ZPool ${ZPOOLNAME}"
zpool export ${ZPOOLNAME}
echo ""
echo ""

echo "Re-Importing and mounting ZPool ${ZPOOLNAME} to /mnt"
zpool import ${ZPOOLNAME} -R /mnt
echo ""
echo ""

sleep 5  ## Slow down the script to see whats happening

## Mount the ZFS datasets so we can start installing Arch
## Mount the ROOT base dataset 
zfs mount $ZPOOLNAME/ROOT/default
## Mount the rest of the datasets on TOP with
zfs mount -a

## Create Directory and mount EFI Partition
echo "mount EFI Partition"
mkdir -p /mnt/efi
mount ${DISK}1 /mnt/efi

## Install the system and pacstrap base
pacstrap -C /etc/pacman.conf /mnt base base-devel linux-lts linux-lts-headers man-db man-pages texinfo git openssh ntp vim zsh zsh-completions tmux zfs-dkms networkmanager dhcpcd

##Generate a new fstab for our Install with
genfstab -f /mnt/efi -U /mnt > /mnt/etc/fstab

## Copy HostID
cp /etc/hostid /mnt/etc

## Symlink vim to vi
arch-chroot /mnt ln -s /usr/bin/vim /usr/bin/vi

## Add repo to pacman.conf
cat >> /mnt/etc/pacman.conf <<"EOF"
[archzfs]
Server = http://archzfs.com/archzfs/x86_64
Server = http://mirror.sum7.eu/archlinux/archzfs/archzfs/x86_64
Server = https://mirror.biocrafting.net/archlinux/archzfs/archzfs/x86_64
EOF
#echo '[archzfs]' | tee -a /mnt/etc/pacman.conf
#echo 'Server = https://archzfs.com/$repo/$arch'  | tee -a /mnt/etc/pacman.conf
## Add keys for arch-zfs repo
arch-chroot /mnt pacman-key -r DDF7DB817396A49B2A2723F7403BD972F75D9D76
arch-chroot /mnt pacman-key --lsign-key DDF7DB817396A49B2A2723F7403BD972F75D9D76

## Refresh pacman packages
echo "Refreshing pacman database"
arch-chroot /mnt pacman -Syy
echo ""
echo ""

## Configure initramfs
## Now we need to make sure that our initramfs includes the ZFS Kernel module on boot in the /etc/mkinitcpio.conf file
sed -i -e 's/HOOKS=(base udev autodetect modconf block filesystems keyboard fsck)/HOOKS=(base udev autodetect modconf block keyboard zfs filesystems)/g' /mnt/etc/mkinitcpio.conf
## Generate the new initramfs with
arch-chroot /mnt mkinitcpio -P

## Configure zfs-mount-generator
## Create the /etc/zfs/zfs-list.cache directory.
mkdir -p /mnt/etc/zfs/zfs-list.cache

## Set a cache file for your ZFS Pool with
zpool set cachefile=/etc/zfs/zfs-list.cache/zroot.cache ${ZPOOLNAME}

## enable the following services for ZFS
arch-chroot /mnt systemctl enable zfs-mount
arch-chroot /mnt systemctl enable zfs-import-scan
arch-chroot /mnt systemctl enable zfs-import-cache
## You need to add a file in /etc/zfs/zfs-list.cache for each ZFS pool in your system. Make sure the pools are imported by enabling zfs-import-cache.service and zfs-import.target as explained above.

## Setup Bootloader
if [ "${BOOTLOADER}" == "refind" ]; then 
   arch-chroot /mnt pacman -Sy refind  --noconfirm
   arch-chroot /mnt refind-install --usedefault ${DISK}1
   ## Create directory for ZFSBootMenu and pull in prebuilt binaries for ease of install
   mkdir /mnt/efi/EFI/zbm
   curl -o /mnt/efi/EFI/zbm/zfsbootmenu.EFI -L https://get.zfsbootmenu.org/latest.EFI
   zfs set org.zfsbootmenu:commandline="rw" ${ZPOOLNAME}/ROOT
fi
if [ "${BOOTLOADER}" == "zfsbootmenu" ]; then 
   ## Create directory for ZFSBootMenu and pull in prebuilt binaries for ease of install
   mkdir -p /mnt/efi/EFI/zbm
   curl -o /mnt/efi/EFI/zbm/zfsbootmenu.EFI -L https://get.zfsbootmenu.org/latest.EFI
   pacman -S efibootmgr --noconfirm
   echo ""
   echo ""
   #zfs set org.zfsbootmenu:commandline="rw" ${ZPOOLNAME}/ROOT
   ## Set Kernel Parameters
   zfs set org.zfsbootmenu:commandline="noresume init_on_alloc=0 rw spl.spl_hostid=$(hostid)" ${ZPOOLNAME}/ROOT
   echo ""
   echo ""
   sleep 5
   echo "Setting up EFI Boot Manager for ZFSBootMenu"
   efibootmgr --disk ${DISK} --part 1 --create --label "ZFSBootMenu" --loader '\EFI\zbm\zfsbootmenu.EFI' --unicode "spl_hostid=$(hostid) zbm.timeout=3 zbm.prefer=zroot zbm.import_policy=hostid" --verbose
   sleep 5
   echo ""
   echo ""
fi
if [ "${BOOTLOADER}" == "grub" ]; then 
   echo "GRUB has not been implimented in this script yet."
fi

## Set Timezone
arch-chroot /mnt ln -s /usr/share/zoneinfo/${TIMEZONE} /etc/localtime
## Generate /etc/adjtime
arch-chroot /mnt hwclock --systohc

## Uncomment Your desired locale from /etc/locale.gen eg. en_US.UTF-8
#vim /mnt/etc/locale.gen
echo 'en_US.UTF-8 UTF-8' | tee -a /mnt/etc/locale.gen
#sed -i -e ’s/"#en_US.UTF-8"/en_US.UTF-8/g’ /mnt/etc/locale.gen
## Run locale-gen
arch-chroot /mnt locale-gen

## Enable Services
echo "Enabling NTP Service"
arch-chroot /mnt systemctl enable ntpd
echo "Enabling dhcpd Service"
arch-chroot /mnt systemctl enable dhcpcd
echo "Enabling NetworkManager Service"
arch-chroot /mnt systemctl enable NetworkManager
echo "Enabling sshd Service"
arch-chroot /mnt systemctl enable sshd

sleep 5  ## Slow down the script to see whats happening

## Set Root Password
echo "Setting root Password"
arch-chroot /mnt chpasswd <<<"root:${ROOTPASS}"
echo "root password has been Set"
echo ""
echo ""

sleep 5  ## Slow down the script to see whats happening

## Set root shell to ZSH
echo "default root shell set to ZSH"
arch-chroot /mnt chsh -s /usr/bin/zsh root
echo ""
echo ""

# Grab .zshrc file from repo and put in /etc/skel
echo "Grabbing fancyboi .zshrc file and shoving it in a skeleton"
arch-chroot /mnt curl -o /etc/skel/.zshrc https://git.jettdigital.io/kjett/homedir/raw/branch/main/.zshrc
echo ""
echo ""

echo "Copy the fancyboi so root can use it"
arch-chroot /mnt cp /etc/skel/.zshrc /root/.zshrc
echo ""
echo ""

sleep 5

## Check if $NEWUSER is not set. If it is, then run user creation scripts
if [ -z "$NEWUSER" ]
then
   echo "No user account specified. Install will only have a root account"
   echo ""
   echo ""
else
   ## Create new user
   echo "Creating user ${NEWUSER}"
   arch-chroot /mnt useradd -m $NEWUSER
   ## Set Password for new user
   echo "Setting user password"
   arch-chroot /mnt chpasswd <<<"${NEWUSER}:${PASSWORD}"
   ## Set root shell to ZSH
   arch-chroot /mnt chsh -s /usr/bin/zsh $NEWUSER
fi

## Install additional packages if provided
if [ -z "$PACKAGES" ]
then
   echo "No additional packages to install"
   echo ""
   echo ""
   sleep 5
else
   echo "Installing additional packages"
   arch-chroot /mnt pacman -S ${PACKAGES} --noconfirm
fi

## TODO Check if system is running in QEMU VM. If it is, install guest agent
echo "Checking if system is virtualized or bare metal"
systemd-detect-virt
echo "Installing qemu-guest-agent"
arch-chroot /mnt pacman -S qemu-guest-agent --noconfirm
echo ""
echo ""

## TODO Detect if AMD or Intel for ucode package install
echo "Installing AMD U-CODE"
arch-chroot /mnt pacman -S amd-ucode --noconfirm
echo ""
echo ""
#echo "Installing Intel U-CODE"
#arch-chroot /mnt pacman -S intel-ucode --noconfirm

## TODO: Make this optional... Maybe prompt?
## chroot into new Arch install
if [ "${CHROOT}" == "1" ]; then 
   arch-chroot /mnt
fi

if [ "${UNMOUNT}" == "1" ]; then 
   ## Unmount EFI partition
   mount | grep EFI
   echo "Unmounting EFI Partition"
   umount /mnt/efi
   echo ""
   echo ""
   sleep 5

   ## Unmount ZFS Datasets
   echo "Unmounting ZFS Datasets"
   zfs list
   zfs umount ${ZPOOLNAME}/ROOT/default
   zfs umount -a
   echo ""
   echo ""
   zfs list
   echo ""
   echo ""
   sleep 5

   ## Export the ZFS Pool
   echo "Exporting ZFS Pool: ${ZPOOLNAME}"
   zpool export ${ZPOOLNAME}
   echo ""
   echo ""
   zpool list
   echo ""
   echo ""
fi

## Reboot and pray it all works
if [ "${REBOOT}" == "1" ]; then 
   echo "Rebooting in 10 seconds"
   sleep 10
   reboot
else
   echo "Install Complete. Reboot, or don't. Meatbag"
   echo ""
   echo ""
fi



### Snippets for later
## Create build directory to use makepkg as user nobody
# mkdir -p /mnt/opt/build
# chgrp nobody /mnt/opt/build
# chmod g+ws /mnt/opt/build
# setfacl -m u::rwx,g::rwx /mnt/opt/build
# setfacl -d --set u::rwx,g::rwx,o::- /mnt/opt/build

# ## Temporarily give nobody sudo without password permissions
# touch /mnt/etc/sudoers.d/nobody
# echo 'nobody  ALL=(ALL) NOPASSWD:ALL' | tee -a /mnt/etc/sudoers.d/nobody

# ## Install ZFS Boot Menu EFI bin
# cd /mnt/opt/build
# arch-chroot /mnt sudo -u nobody git clone https://aur.archlinux.org/zfsbootmenu-efi-bin.git /opt/build/zfsbootmenu-efi-bin
# chmod -R g+w /mnt/opt/build/zfsbootmenu-efi-bin
# cd /mnt/opt/build/zfsbootmenu-efi-bin
# arch-chroot /mnt sudo -u nobody makepkg -si

##Install AUR and yay
##sudo pacman -S base-devel git
##cd /opt
##sudo git clone https://aur.archlinux.org/yay.git
##sudo chown -R $USER:users ./yay
##cd yay
##makepkg -si
