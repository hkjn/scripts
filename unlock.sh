#!/bin/bash
#
# Unlocks encrypted file given as first argument for viewing/editing.
#
# If the contents of the file changed, the cleartext file is re-encrypted.
#
# Regardless, the plaintext file is securely removed as the editor is
# closed, and is stored on tempfs only in the meanwhile.
#
declare BASE=${GOPATH}/src/bitbucket.org/hkjn/passwords
declare SUB=${SUB:-""}

cd ${BASE}
source "logging.sh"

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
  if which gpg-connect-agent 1>/dev/null; then
    info "Dropping GPG identities from agent.."
    echo RELOADAGENT | gpg-connect-agent
  fi
}

[[ "$#" -eq 1 ]] || fatal "Usage: $0 [encrypted file]"
declare TARGET=${1}
declare CRYPT=${BASE}/${TARGET}
declare RECIPIENT="me@hkjn.me"
declare CLEAR=$(mktemp)

if [[ "${SUB}" ]]; then
  CRYPT=${BASE}/${SUB}/${TARGET}
  if [[ "${SUB}" = "ios" ]]; then
    RECIPIENT="425BF55E014AF99C3BA6A6E8D85FAD19F4971232"
  else
    fatal "No key specified for subdirectory ${SUB}."
  fi
  debug "Using subdirectory ${SUB} and recipient ${RECIPIENT}.."
fi

trap cleanup EXIT
[[ -e "$CRYPT" ]] || {
  info "No such file '$CRYPT', trying $CRYPT.pgp.."
  CRYPT="$CRYPT.pgp"
}

CHECKSUM_BEFORE=""
if [[ -e "$CRYPT" ]]; then
  info "Decrypting $CRYPT -> $CLEAR"
  export CLEAR=$CLEAR CRYPT=$CRYPT
  docker run --rm -it \
      -v $HOME/.gnupg:/home/gpg/.gnupg \
      -v ${CLEAR}:/clearfile \
      -v $(dirname ${CRYPT}):/crypt \
    hkjn/gpg:$(uname -m) -c \
      "gpg --yes --output /clearfile --decrypt /crypt/$(basename ${CRYPT})"
  if [[ $? -ne 0 ]]; then
    fatal "Error decrypting file."
  fi
  chmod 600 $CLEAR
  CHECKSUM_BEFORE=$(sha256sum $CLEAR)
else
  info "No such file '$CRYPT', creating new file '$CLEAR'"
fi

nano $CLEAR
CHECKSUM_AFTER=$(sha256sum $CLEAR)

if [[ $CHECKSUM_BEFORE != $CHECKSUM_AFTER ]]; then
  info "Contents changed, re-encrypting ${CLEAR} -> $CRYPT"
  export CLEAR=${CLEAR} CRYPT=${CRYPT}
  docker run --rm -it \
      -v ${HOME}/.gnupg:/home/gpg/.gnupg \
      -v ${CLEAR}:/clearfile \
      -v $(dirname ${CRYPT}):/crypt \
    hkjn/gpg:$(uname -m) -c \
      "gpg --yes --output /crypt/$(basename ${CRYPT}) --encrypt --armor --recipient ${RECIPIENT} /clearfile"
  if [[ $? -ne 0 ]]; then
    fatal "Error encrypting file."
  fi
fi

info "All done."
