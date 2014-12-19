#!/bin/bash
#
# Cleans up all untagged Docker images.
#

docker rmi $(docker images -q --filter "dangling=true")
