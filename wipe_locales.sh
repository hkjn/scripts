#!/bin/bash
#
# Clears out all of /usr/share/locale *except* the specified ones.o
mkdir /tmp/locales/
for k in en en\@boldquot en\@quot en\@shaw en_US; do
		cd /usr/share/locale
		sudo mv -v $k /tmp/locales/
done
sudo rm -rfv *
sudo mv -v /tmp/locales/* .
