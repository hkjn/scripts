#!/bin/bash
#
# Encrypts the cleartext file given as first argument and then deletes
# the cleartext.
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

[ "$#" -eq 1 ] || fatal "Usage: $0 [cleartext file under clear/]"

# TODO(hkjn): Refactor out crypt.sh lib.
# TODO(hkjn): Add func for checking number of clear/ files.
# TODO(hkjn): Add func for decrypting string in clear/ file without the plaintext bytes hitting disk.
BASE="$GOPATH/src/bitbucket.org/hkjn/passwords"
CLEAR="$BASE/clear/$1"
RECIPIENT="me@hkjn.me"

if [[ ! -e "$CLEAR" ]]; then
  CLEAR="${CLEAR%.pgp}"
  CRYPT="$BASE/$1"
else
  CRYPT="$BASE/$1.pgp"
fi

[[ -e "$CLEAR" ]] || fatal "No such file: '$CLEAR'"
info "Encrypting clear/${CLEAR} -> ${CLEAR}.pgp"
gpg --output $CRYPT --encrypt --armor --recipient $RECIPIENT $CLEAR
srm -fvi ${CLEAR}{,~}
