#!/bin/bash
#
# Git precommit scripts.

if [ -z "${TRUST_ME_I_KNOW_WHAT_I_AM_DOING}" ]; then
	 ~/src/needs_gofmt.sh
else # Allow for a failsafe.
	echo "Okay, if you say so. Skipping pre-commit checks. Have fun." >&2
fi
