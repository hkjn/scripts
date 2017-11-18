#!/bin/bash
#
# Sample script for setting up LVM on Ubuntu.
#

apt-get -y update
apt-get -y install gdisk lvm2

pvcreate /dev/nbd2
pvcreate /dev/nbd3

vgcreate crypt /dev/nbd2
vgextend crypt /dev/nbd3

lvcreate -l 100%FREE crypt -n crypt0
mkfs.ext4 /dev/mapper/crypt-crypt0
mkdir /crypt
mount /dev/mapper/crypt-crypt0 /crypt
