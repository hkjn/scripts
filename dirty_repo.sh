#!/bin/bash
#
# Checks that all files under BASENAME are:
# 1. Directories
# 2. With git repos inside
# 3. With a clean working tree
#
# TODO(hkjn): Also look for LICENSE, README.md?
# TODO(hkjn): Also check if everything is pushed up: git log origin/master..master
#
set -euo pipefail

BASENAME="hkjn.me"
LIBDIR="lib"

load() {
	set -euo pipefail
	local p="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	while [ $(basename $p) != "$BASENAME" ] && [ $p != "/" ]; do p="${p/\/$(basename $p)/}"; done
	source "$p/$LIBDIR/$1" || { echo "FATAL: Couldn't load $p/$LIBDIR/$1." >&2; exit 1; }
	export BASE="$p"
}
load "logging.sh"

check() {
	cd "$BASE"
	local dirty=0
	for d in $(ls); do
		if [ ! -d "$d" ]; then
			fatal "Not a directory: '$d'"
		fi
		cd "$d"
		if [ ! -d ".git" ]; then
			fatal "Not a git repo: '$d/.git' doesn't exist"
		fi

		info="$(git-wtf.rb)"
		if $? -ne 0; then
			error "$info"
		fi
#		local gs="$(git status)"
#		if ! echo "$gs" | grep 'nothing to commit, working directory clean'; then
#			error "Dirty tree in '$d' repo:"
#			error "$gs"
#			dirty=1
#		fi
		cd ..
	done
	return $dirty
}

which git-wtf.rb 1>/dev/null || fatal "No git-wtf.rb found on PATH."
check
