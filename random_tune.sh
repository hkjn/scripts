#!/bin/bash

# Play some random tunes.
MUSIC_DIR=/home/$USER/media/music/
mplayer "$(ls ${MUSIC_DIR}*.mp3 | shuf -n1)"
