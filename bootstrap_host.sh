#!/bin/bash
#
# Runs minimal steps to bootstrap a new host to a good state.
#

set -euo pipefail

die() {
  echo "FATAL: $@" >&2
  exit 1
}

[[ $UID -eq 0 ]] || die 'Needs to be root on remote host to bootstrap.'

RUSER=${RUSER:-"zero"}

useradd -G sudo,docker -s /bin/bash $RUSER
mkdir -p /home/$RUSER/.ssh
cp .ssh/authorized_keys /home/$RUSER/.ssh/
chown -R $RUSER:$RUSER /home/$RUSER/
chmod 700 /home/$RUSER/.ssh
chmod 400 /home/$RUSER/.ssh/authorized_keys
sed -e s/22/6200/ \
		-e s/'PermitRootLogin without-password'/'PermitRootLogin no'/ \
		-i /etc/ssh/sshd_config
systemctl restart sshd
passwd -d $RUSER
echo "$RUSER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/user_sudo
chmod 0440 /etc/sudoers.d/user_sudo

su - $RUSER
mkdir -p src/hkjn.me
cd src/hkjn.me
git clone https://github.com/hkjn/scripts.git
git clone https://github.com/hkjn/dotfiles.git
cd dotfiles
cp .bash* ~/

echo 'Done bootstrapping host.'

# TODO(hkjn): Should report in that this host was bootstrapped:
# - set up systemd .timer + .service to publish message that this host is available to MQ system on foo.hkjn.me


