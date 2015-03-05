#!/bin/bash
docker run -it \
  --name chromium \
  --privileged \
  --memory 512mb \
  -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
  -e DISPLAY=unix$DISPLAY \
  -v $HOME/Downloads:/root/Downloads \
  -v $HOME/.config/google-chrome/:/home/user/data \
  hkjn/chromium
