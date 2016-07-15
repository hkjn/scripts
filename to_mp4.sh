#!/bin/bash
#
# Convert all .mkv files in directory to .mp4
#
set -euo pipefail
for i in *.mkv; do
  ffmpeg -i "$i" -vcodec copy -acodec copy "${i%.mkv}.mp4"
done
