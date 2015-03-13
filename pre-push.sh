#!/bin/bash
#
# Git prepush scripts.
#

source ~/src/go_git_hooks.sh || exit

run_go_tests || exit
update_bindata || exit
update_godep || exit
needs_gofmt || exit
prevent_hacks || exit
