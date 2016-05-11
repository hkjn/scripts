#!/bin/bash
#
# Checks that all files under BASENAME are:
# 1. Directories
# 2. With git repos inside
# 3. With a clean working tree
#
# TODO(hkjn): Reimplement git-wtf.rb calls in lib/ bash scripts, to
# avoid wrapping it in shell call here (and having dependency on
# ruby).
# TODO(hkjn): Also look for LICENSE, README.md?
#
set -euo pipefail

load() {
	local ns="hkjn.me"
	local p="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	while [ "$p" != "" ] && [ $(basename $p) != "$ns" ]; do p="${p/\/$(basename $p)/}"; done
	source "$p/lib/$1" 2>/dev/null || { echo "[$0] FATAL: Couldn't find $ns/lib/$1." >&2; exit 1; }
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

		if ! msg="$(git-wtf.rb 2>&1)"; then
			error "Dirty tree in '$d' repo:\n'$msg'"
			dirty=$(($dirty + 1))
		fi
		cd ..
	done
	[ $dirty -eq 0 ] || error "There were $dirty dirty repos."
	return $dirty
}
which ruby 1>/dev/null || fatal "No 'ruby' found on PATH."
which git-wtf.rb 1>/dev/null || fatal "No 'git-wtf.rb' found on PATH."
check
