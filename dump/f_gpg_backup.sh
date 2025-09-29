#!/bin/bash
# shellcheck disable=SC2034

# gpg --export -a pub.asc
# gpg --export-secret-keys -a key.asc

gpg_backup(){
  GPG_IMPORT=${1}
  SOURCE=${2:-${HOME}}

  GPG_TMP=$(mktemp -d tmp.XXXXXXX)
  GNUPGHOME=${GPG_TMP}

  STAMP=$(date --iso)
  
  [ -z "${GPG_IMPORT}" ] && \
    gpg --import "${GPG_IMPORT}"

  gpg --list-keys
  tar vjc "${SOURCE}" | \
    gpg --encrypt \
      --trust-model always \
      --recipient backups > backup-"${STAMP}".tgz.pgp

  rm -rf "${GPG_TMP}"
  unset GNUPGHOME
}
