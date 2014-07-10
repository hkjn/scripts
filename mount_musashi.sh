#!/bin/bash

# Mounts the "musashi" logical volume under the /dev/miyato volume group:
# /dev/miyato/musashi: LUKS
#
# This script requires root permissions.

set -e

cryptsetup luksOpen /dev/miyamoto/musashi musashi_clear --key-file=/root/keys/musashi-key.randomtext
mount /dev/mapper/musashi_clear /media/musashi
echo "Mounted /media/musashi."

# Set time to power-down disk to 3 min (36 * 5 sec) without activity.
hdparm -S 36 /dev/disk/by-id/ata-TOSHIBA_MQ01UBD100_34IZSX5MS-part2
