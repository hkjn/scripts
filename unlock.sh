#!/bin/bash
#
# Decrypts the ciphertext file (without .pgp) given as first argument.
#
load() {
	local ns="hkjn.me"
	local p="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	while [ "$p" != "" ] && [ $(basename $p) != "$ns" ]; do p="${p/\/$(basename $p)/}"; done
	source "$p/lib/$1" 2>/dev/null || { echo "[$0] FATAL: Couldn't find $ns/lib/$1." >&2; exit 1; }
	export BASE="$p"
}

load "logging.sh"

[ "$#" -eq 1 ] || fatal "Usage: $0 [encrypted file, without .pgp]"

BASE="$GOPATH/src/bitbucket.org/hkjn/passwords"
CLEAR="$BASE/clear/$1"
CRYPT="$BASE/$1.pgp"
RECIPIENT="me@hkjn.me"

mkdir -p clear/
echo "Decrypting $CRYPT -> $CLEAR"
gpg --output $CLEAR --decrypt $CRYPT
chmod 600 $CLEAR
