#!/bin/bash

# Play some random tunes.
MUSIC_DIR=/home/$USER/media/music/
for i in 0 1 2 3 4 5 6 7 8 9 10; do
  mplayer "$(ls ${MUSIC_DIR}*.mp3 | shuf -n1)"
done
