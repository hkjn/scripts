#!/bin/bash

set -e

# NOTE: Not tested yet.

# Backs up current kernel and upgrades to new one.
# This script requires root permissions.

LIBS=$(ls -d /lib/modules/?.??.?-?-ARCH)
VERSION=$(echo $LIBS | cut -d '/' -f4)
BACKUP=/root/kernel-backups/${VERSION}-$(date +%Y%m%d)
BOOT=/boot/EFI/arch
KERNEL=${BOOT}/vmlinuz-arch

# Back up kernel src.
# NOTE: No kernel src seems to be in /usr/src on this system.
# cp -r /usr/src/linux-${VERSION} /usr/src/linux-2.6.28-ARCH-old

echo "Backing up previous kernel modules to ${BACKUP}/ and ${LIBS}-stable/.."
sudo cp -r ${LIBS} ${BACKUP}/
sudo cp -r ${LIBS} ${LIBS}-stable/

echo "Backing up previous compiled kernel to ${BACKUP}/${KERNEL}.efi and rotating it to ${KERNEL}-stable.efi.."
sudo cp -v ${KERNEL}.efi ${BACKUP}/
sudo cp -v ${KERNEL}.efi ${KERNEL}-stable.efi

# Back up initial ram image and fallback (initrd).
echo 'Backing up + rotating previous initrd (and fallback) image..'
sudo cp -v ${BOOT}/initramfs-arch.img ${BACKUP}/
sudo cp -v ${BOOT}/initramfs-arch.img ${BOOT}/initramfs-arch-stable.img
sudo cp -v ${BOOT}/initramfs-arch-fallback.img ${BACKUP}/
sudo cp -v ${BOOT}/initramfs-arch-fallback.img ${BOOT}/initramfs-arch-fallback-stable.img

# TODO: Make sure rEFInd has entry for "last kernel" in refind.conf.

# At this point we can upgrade. (Upgrading also runs mkinitcpio -p linux; regenerating /boot/initramfs-linux{-fallback}.img).
echo 'Upgrading system..'
sudo pacman -Syu

echo "Rotating back old ${LIBS}-stable to ${LIBS}.."
sudo mv ${LIBS}-stable ${LIBS}

# TODO: Make default mkinitcpio preset linux directly put the files
# where we want them, rather than this hack.
echo "Copying in new kernel.."
sudo mv -v /boot/vmlinuz-linux ${KERNEL}.efi

echo "Copying in initial ram images.."
sudo mv -v /boot/initramfs-linux.img ${BOOT}/initramfs-arch.img
sudo mv -v /boot/initramfs-linux-fallback.img ${BOOT}/initramfs-arch-fallback.img


