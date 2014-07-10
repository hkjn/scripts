#!/bin/bash

RT_URL=$1
OUT_NAME=$2
echo "RT url is ${RT_URL}"
echo "Output name is ${OUT_NAME}"
URL=$(curl ${RT_URL} | grep '.mp4?st=' | grep -Eo "http://.*&e=[0-9]+" | head -n 1)
echo ".mp4 URL is ${URL}, saving to ${OUT_NAME}"
wget ${URL} -O ${OUT_NAME}
