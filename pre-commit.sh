#!/bin/bash
#
# Git precommit scripts.

source ~/src/go_git_hooks.sh || exit

needs_gofmt
