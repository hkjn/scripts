#!/bin/sh

# Prepares 32 bit arch install for chroot.
#
# This script requires root.
# 
# Based on https://wiki.archlinux.org/index.php/Arch64_Install_bundled_32bit_system.
#
# Example usage:
# $0

set -e

MOUNTPOINT=/opt/arch32
# PIDFILE=/run/arch32
IRONKEY_PATH=/run/media/zero/IronKey

if [ ! -d "$MOUNTPOINT" ]; then
		echo "$MOUNTPOINT doesn't exist; bailing"
		exit -1
fi

# Bind devices and tmp to the chroot.
dirs=(/tmp /dev /dev/pts)
for d in "${dirs[@]}"; do
    sudo mount -o bind $d $MOUNTPOINT$d
done

# Mount /proc and /sys.
sudo mount -t proc none $MOUNTPOINT/proc
sudo mount -t sysfs none $MOUNTPOINT/sys

# If there's an IronKey mounted, also bind it to the chroot.
if [ -d "$IRONKEY_PATH" ]; then
		echo "Found ironkey, binding.."
		sudo mount -o bind ${IRONKEY_PATH} $MOUNTPOINT/media/IronKey
fi

sudo chroot $MOUNTPOINT

# Uncomment to enable creation of a PID file (not much use without a
# full systemd service that also removes it on shutdown).
# touch $PIDFILE

