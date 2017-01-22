#!/bin/bash
#
# Unlocks encrypted file given as first argument for viewing/editing.
#
# If the contents of the file changed, the cleartext file is re-encrypted.
#
# Regardless, the plaintext file is securely removed as the editor is
# closed, and is stored on tempfs only in the meanwhile.
#
load() {
	local ns="hkjn.me"
	local p="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
	while [ "$p" != "" ] && [ $(basename $p) != "$ns" ]; do p="${p/\/$(basename $p)/}"; done
	source "$p/lib/$1" 2>/dev/null || { echo "[$0] FATAL: Couldn't find $ns/lib/$1." >&2; exit 1; }
	export BASE="$p"
}

load "logging.sh"

[[ "$#" -eq 1 ]] || fatal "Usage: $0 [encrypted file]"

BASE="$GOPATH/src/bitbucket.org/hkjn/passwords"
CRYPT="$BASE/$1"
RECIPIENT="me@hkjn.me"
[[ -e "$CRYPT" ]] || {
  info "No such file '$CRYPT', trying $CRYPT.pgp.."
  CRYPT="$CRYPT.pgp"
}
[[ -e "$CRYPT" ]] || {
  info "No such file '$CRYPT'"
  fatal "No such file '$CRYPT' or '$CRYPT.pgp'"
}

cleanup() {
  if which srm 1>/dev/null; then
    srm -fvi ${CLEAR}*
  elif which shred 1>/dev/null; then
    shred ${CLEAR}*
    rm -vrf ${CLEAR}*
  else
    echo "Neither 'srm' or 'shred' was installed; can't remove '${CLEAR}' securely."
    rm -vrf ${CLEAR}*
  fi
  info "Dropping GPG identities from agent.."
  echo RELOADAGENT | gpg-connect-agent
}

CLEAR="$(mktemp)"
trap cleanup EXIT

info "Decrypting $CRYPT -> $CLEAR"
gpg --batch --yes --output $CLEAR --decrypt $CRYPT
chmod 600 $CLEAR

CHECKSUM_BEFORE=$(sha256sum $CLEAR)
nano $CLEAR
CHECKSUM_AFTER=$(sha256sum $CLEAR)

if [[ $CHECKSUM_BEFORE != $CHECKSUM_AFTER ]]; then
  info "Contents changed, re-encrypting ${CLEAR} -> $CRYPT"
  gpg --batch --yes --output $CRYPT --encrypt --armor --recipient $RECIPIENT $CLEAR
fi

info "All done."
