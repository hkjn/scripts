#!/bin/bash

BACKLIGHT_PATH=/sys/class/backlight/intel_backlight
PERCENT=$1
# Requires sudo.
MAX_BRIGHTNESS=$(cat $BACKLIGHT_PATH/max_brightness)
echo "Max brightness is $MAX_BRIGHTNESS"
echo "We want $PERCENT\%"
FRAC=$(echo "scale=25; $PERCENT / 100" | bc)
VALUE=$(echo "scale=25; $FRAC * $MAX_BRIGHTNESS" | bc)
VALUE_ROUNDED=$(echo "$VALUE" | awk '{printf("%d\n",$1 + 0.5)}')
echo "Setting new value of $VALUE_ROUNDED"
echo $VALUE_ROUNDED > $BACKLIGHT_PATH/brightness
