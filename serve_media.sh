#!/bin/bash

set -euo pipefail

start() {
	[ -d $2 ] || {
		echo "No such directory: '$2'"
		return
	}
	docker rm -f $1-fileserver && echo "Removed $1-fileserver container"
	docker run --name $1-fileserver -d -v "$2:/var/www" -p $3:8080 hkjn/fileserver
	echo "$1-fileserver is running at $3, serving directory '$2'"
}
start musashi /media/musashi 8080
start staging $HOME/staging 8081
start staging $HOME/media 8082
start usb /run/media/zero/USB20FD 8083

echo "Started media fileserver containers."
