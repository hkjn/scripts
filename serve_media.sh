#!/bin/bash

set -euo pipefail

docker rm -f musashi-fileserver && echo "Removed musashi-fileserver container"
docker run --name musashi-fileserver -d -it -v "/media/musashi:/var/www" -p 8080:8080 hkjn/fileserver
docker rm -f staging-fileserver && echo "Removed staging-fileserver container"
docker run --name staging-fileserver -d -it -v "$HOME/staging:/var/www" -p 8081:8080 hkjn/fileserver
echo "Started media fileserver containers."
