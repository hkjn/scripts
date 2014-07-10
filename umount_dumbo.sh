#!/bin/bash

# Unmounts the logical volumes under the /dev/dumbo volume group:
# /dev/dumbo/clown: LUKS
# /dev/dumbo/timothy: plain
#
# This script requires root permissions.

set -e

# TODO: Also run periodic cron (30m?) in case of unexpected
# disconnect.

# Sync important data to local encrypted storage.
# rsync -avz /media/clown/src /media/farouk/
# rsync -avz /media/clown/notes /media/farouk/

umount /media/clown
cryptsetup remove clown_clear
echo "Unmounted /media/clown."

umount /media/timothy
echo "Unmounted /media/timothy."

