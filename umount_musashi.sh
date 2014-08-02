#!/bin/bash

# Unmounts the "musashi" logical volume under the /dev/miyato volume group:
# /dev/miyato/musashi: LUKS
#
# This script requires root permissions.

set -e

sudo umount /media/musashi
sudo cryptsetup remove musashi_clear
echo "Unmounted /media/musashi"

