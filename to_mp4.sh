#!/bin/bash
#
# Convert all .mkv and .webm files in directory to .mp4
#
set -euo pipefail
for v in *.mkv; do
  ffmpeg -i "$v" -vcodec copy -acodec copy "${v%.mkv}.mp4" ||
  ffmpeg -i "$v" -vcodec copy -c:a aac "${v%.mkv}.mp4"
done
for  v in *.webm; do
  ffmpeg -i "$v" -vcodec libx264 "${v%.webm}.mp4"
done
