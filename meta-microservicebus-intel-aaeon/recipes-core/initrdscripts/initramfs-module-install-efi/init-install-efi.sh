#!/bin/sh -e
#
# Copyright (c) 2012, Intel Corporation.
# All rights reserved.
#
# install.sh [device_name] [rootfs_name]
#

PATH=/sbin:/bin:/usr/sbin:/usr/bin

# figure out how big of a boot partition we need
boot_size=$(du -ms /run/media/$1/ | awk '{print $1}')
# remove rootfs.img ($2) from the size if it exists, as its not installed to /boot
if [ -e /run/media/$1/$2 ]; then
	boot_size=$(( boot_size - $( du -ms /run/media/$1/$2 | awk '{print $1}')  ))
fi
# remove initrd from size since its not currently installed
if [ -e /run/media/$1/initrd ]; then
	boot_size=$(( boot_size - $( du -ms /run/media/$1/initrd | awk '{print $1}') ))
fi
# add 10M to provide some extra space for users and account
# for rounding in the above subtractions
boot_size=$(( boot_size + 10 ))

# 5% for swap
swap_ratio=5

# Get a list of hard drives
hdnamelist=""
live_dev_name=`cat /proc/mounts | grep ${1%/} | awk '{print $1}'`
live_dev_name=${live_dev_name#\/dev/}
# Only strip the digit identifier if the device is not an mmc
case $live_dev_name in
    mmcblk*)
    ;;
    nvme*)
    ;;
    *)
        live_dev_name=${live_dev_name%%[0-9]*}
    ;;
esac

echo "Searching for hard drives ..."
mdadm --detail --scan > /etc/mdadm.conf

# Some eMMC devices have special sub devices such as mmcblk0boot0 etc
# we're currently only interested in the root device so pick them wisely
devices=`ls /sys/block/ | grep -v mmcblk` || true
mmc_devices=`ls /sys/block/ | grep "mmcblk[0-9]\{1,\}$"` || true
devices="$devices $mmc_devices"

for device in $devices; do
    case $device in
        loop*)
            # skip loop device 
            ;;
        sr*)
            # skip CDROM device
            ;;
        ram*)
            # skip ram device
            ;;
        *)
            # skip the device LiveOS is on
            # Add valid hard drive name to the list
            case $device in
                $live_dev_name*)
                # skip the device we are running from
                ;;
                *)
                    hdnamelist="$hdnamelist $device"
                ;;
            esac
            ;;
    esac
done

if [ -z "${hdnamelist}" ]; then
    echo "You need another device (besides the live device /dev/${live_dev_name}) to install the image. Installation aborted."
    exit 1
fi

# Set static install target
TARGET_DEVICE_NAME=""

for hdname in $hdnamelist; do
    # Display found hard drives and their basic info
    echo "-------------------------------"
    echo /dev/$hdname
    if [ -r /sys/block/$hdname/device/vendor ]; then
        echo -n "VENDOR="
        cat /sys/block/$hdname/device/vendor
    fi
    if [ -r /sys/block/$hdname/device/model ]; then
        echo -n "MODEL="
        cat /sys/block/$hdname/device/model
    fi
    if [ -r /sys/block/$hdname/device/uevent ]; then
        echo -n "UEVENT="
        cat /sys/block/$hdname/device/uevent
    fi
    echo
done

device=/dev/sda

# "The udev automounter can cause pain here, kill it"
rm -f /etc/udev/rules.d/automount.rules
rm -f /etc/udev/scripts/mount*

# "Unmount anything the automounter had mounted"
umount /dev/sda* 2> /dev/null || /bin/true
umount /dev/sda* 2> /dev/null || /bin/true

mkdir -p /tmp

# Create /etc/mtab if not present
if [ ! -e /etc/mtab ] && [ -e /proc/mounts ]; then
    ln -sf /proc/mounts /etc/mtab
fi

disk_size=$(parted ${device} unit mb print | grep '^Disk .*: .*MB' | cut -d" " -f 3 | sed -e "s/MB//")
swap_size=$((disk_size*swap_ratio/100))

# Set rootfs size (in M) from image file + 100 MB account for roundings etc.
rootfs_size=$(ls -l /run/media/$1/$2 | awk '{printf("%.0f\n", $5/1000000+100)}')

# Set data partition to 200GB until we set the raid
data_size=200000

# While
#data_size=10000

rootfs_start=$((boot_size))
rootfs_end=$((rootfs_start+rootfs_size))
data_start=$((rootfs_end))
data_end=$((data_start+data_size))
swap_start=$((data_end))

# MMC devices are special in a couple of ways
# 1) they use a partition prefix character 'p'
# 2) they are detected asynchronously (need rootwait)
rootwait=""
part_prefix=""

# USB devices also require rootwait
if [ -n `readlink /dev/disk/by-id/usb* | grep $TARGET_DEVICE_NAME` ]; then
    rootwait="rootwait"
fi

bootfs_a="/dev/sda1"
rootfs_a="/dev/sda2"
data_a="/dev/sda3"
swap_a="/dev/sda4"

bootfs_b="/dev/sdb1"
rootfs_b="/dev/sdb2"
data_b="/dev/sdb3"
swap_b="/dev/sdb4"


echo "*****************"
echo "Total disk size:         $disk_size MB"
echo "Boot partition size:     $boot_size MB ($bootfs)"
echo "Rootfs A partition size: $rootfs_size MB ($rootfs_a) ($rootfs_start => $rootfs_end)"
echo "Rootfs B partition size: $rootfs_size MB ($rootfs_b) ($rootfs_start => $rootfs_end)"
echo "Data partition size:     $data_size MB ($data)  ($data_start => $data_end)"
echo "Swap partition size:     $swap_size MB ($swap)"
echo "*****************"
echo "Deleting partition tables ..."

echo ""
echo "****************************************"
echo " CONSOLE...press CTRL+D if all is ok"
echo "****************************************"
echo ""
/bin/bash
echo end console


dd if=/dev/zero of=/dev/sda bs=512 count=35
dd if=/dev/zero of=/dev/sdb bs=512 count=35

echo "Creating new partition table on sda ..."
parted /dev/sda mklabel gpt
echo "Creating new partition table on sdb ..."
parted /dev/sdb mklabel gpt

echo "Creating BOOT partition on $bootfs_a"
parted /dev/sda mkpart boot fat32 0% $boot_size
parted /dev/sda set 1 boot on
echo "Creating BOOT partition on $bootfs_b"
parted /dev/sdb mkpart boot fat32 0% $boot_size
parted /dev/sdb set 1 boot on

echo "Creating ROOTFS A partition on $rootfs_a"
parted /dev/sda mkpart root ext4 $rootfs_start $rootfs_end
echo "Creating ROOTFS B partition on $rootfs_b"
parted /dev/sdb mkpart root ext4 $rootfs_start $rootfs_end

echo "Creating DATA partition on $data_a"
parted /dev/sda mkpart root ext4 $data_start $data_end
echo "Creating DATA partition on $data_b"
parted /dev/sdb mkpart root ext4 $data_start $data_end

echo "Creating SWAP partition on $swap_a"
parted /dev/sda mkpart swap linux-swap $swap_start 100%
echo "Creating SWAP partition on $swap_b"
parted /dev/sdb mkpart swap linux-swap $swap_start 100%

parted /dev/sda print
parted /dev/sdb print

echo "Waiting for device nodes..."
C=0
while [ $C -ne 3 ] && [ ! -e $bootfs_a  -o ! -e $bootfs_b  -o ! -e $rootfs_a  -o ! -e $rootfs_b  -o ! -e $data_a -o ! -e $swap_a ! -e $swap_b ]; do
    C=$(( C + 1 ))
    sleep 1
done

echo "Formatting $bootfs_a to vfat..."
mkfs.vfat $bootfs_a
echo "Formatting $bootfs_b to vfat..."
mkfs.vfat $bootfs_b

echo "Formatting $rootfs_a to ext4..."
mkfs.ext4 -F $rootfs_a
echo "Formatting $rootfs_b to ext4..."
mkfs.ext4 -F $rootfs_b

echo "Formatting $data_a to ext4..."
mkfs.ext4 -F $data_a
echo "Formatting $data_b to ext4..."
mkfs.ext4 -F $data_b

echo "Formatting swap partition...($swap_a)"
mkswap $swap_a
echo "Formatting swap partition...($swap_b)"
mkswap $swap_b

mkdir /tgt_root_a
mkdir /tgt_root_b
mkdir /src_root
mkdir -p /boot

# Handling of the target root partition
mount $rootfs_a /tgt_root_a
mount $rootfs_b /tgt_root_b
mount -o rw,loop,noatime,nodiratime /run/media/$1/$2 /src_root
echo "Copying rootfs files..."
cp -a /src_root/* /tgt_root_a
cp -a /src_root/* /tgt_root_b

if [ -d /tgt_root/etc/ ] ; then
    boot_uuid=$(blkid -o value -s UUID ${bootfs_a})
    boot_uuid=$(blkid -o value -s UUID ${bootfs_b})

    swap_part_uuid=$(blkid -o value -s PARTUUID ${swap_a})
    swap_part_uuid=$(blkid -o value -s PARTUUID ${swap_b})
    
    # We dont want udev to mount our root device while we're booting...
    if [ -d /tgt_root/etc/udev/ ] ; then
        echo "/dev/sda" >> /tgt_root/etc/udev/mount.blacklist
        echo "/dev/sdb" >> /tgt_root/etc/udev/mount.blacklist
    fi
fi

umount /src_root

# Handling of the target boot partition (A)
mount $bootfs_a /boot
echo "Preparing boot partition (A)..."

EFIDIR="/boot/EFI/BOOT"
mkdir -p $EFIDIR
# Copy the efi loader
cp /run/media/$1/EFI/BOOT/*.efi $EFIDIR

if [ -f /run/media/$1/EFI/BOOT/grub.cfg ]; then
    root_part_uuid=$(blkid -o value -s PARTUUID ${rootfs_a})
    GRUBCFG="$EFIDIR/grub.cfg"
    cp /run/media/$1/EFI/BOOT/grub.cfg $GRUBCFG
fi

umount /tgt_root_a
umount /tgt_root_b

# Copy kernel artifacts. To add more artifacts just add to types
# For now just support kernel types already being used by something in OE-core
for types in bzImage zImage vmlinux vmlinuz fitImage; do
    for kernel in `find /run/media/$1/ -name $types*`; do
        cp $kernel /boot
    done
done

umount /boot

sync

# Handling of the target boot partition (B)
mount $bootfs_b /boot
echo "Preparing boot partition (B)..."

EFIDIR="/boot/EFI/BOOT"
mkdir -p $EFIDIR
# Copy the efi loader
cp /run/media/$1/EFI/BOOT/*.efi $EFIDIR

if [ -f /run/media/$1/EFI/BOOT/grub.cfg ]; then
    root_part_uuid=$(blkid -o value -s PARTUUID ${rootfs_b})
    GRUBCFG="$EFIDIR/grub.cfg"
    cp /run/media/$1/EFI/BOOT/grub.cfg $GRUBCFG
fi

# Copy kernel artifacts. To add more artifacts just add to types
# For now just support kernel types already being used by something in OE-core
for types in bzImage zImage vmlinux vmlinuz fitImage; do
    for kernel in `find /run/media/$1/ -name $types*`; do
        cp $kernel /boot
    done
done

umount /boot

sync

echo "Installation successful. Remove your installation media and press ENTER to reboot."
read enter
echo "Rebooting..."
reboot -f
