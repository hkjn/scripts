#!/bin/bash
#
# Git prepush scripts.

if [ -z "${TRUST_ME_I_KNOW_WHAT_I_AM_DOING}" ]; then
	echo "Running all Go tests.." >&2
	goapp test ./...
else # Allow for a failsafe.
	echo "Okay, if you say so. Skipping pre-push checks. Have fun." >&2
fi
