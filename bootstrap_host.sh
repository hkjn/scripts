#!/bin/bash
#
# Runs minimal steps to bootstrap a new host to a good state.
#

# TODO(hkjn): Set shell in /etc/passwd or use adduser.
useradd -G sudo,docker zero
mkdir -p /home/zero/.ssh
mv *.pub /home/zero/.ssh/authorized_keys
chown -R zero:zero /home/zero/
chmod 700 /home/zero/.ssh
chmod 400 /home/zero/.ssh/authorized_keys
sed -e s/22/6200/ \
		-e s/'PermitRootLogin without-password'/'PermitRootLogin no'/ \
		-i /etc/ssh/sshd_config
systemctl restart sshd
passwd zero
su - zero
mkdir -p src/hkjn.me
cd src/hkjn.me
git clone https://github.com/hkjn/scripts.git
git clone https://github.com/hkjn/dotfiles.git
cd scripts
cp .bash* ~/


