#!/bin/bash
#
# Git prepush scripts.
#

source ~/src/go_git_hooks.sh || exit

run_go_tests
update_bindata
update_godep
needs_gofmt
echo "Pass." >&2
