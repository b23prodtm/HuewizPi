#!/usr/bin/env bash
eval $(ssh-agent)
ssh-add ~/.ssh/*id_rsa
source ./configure-docker-arch.sh
git commit -a -m "${DKR_ARCH} pushed to balena.io"
if [ $(sudo which balena) > /dev/null ]; then
  sudo balena push $*
else
  git push -uf balena $*
fi
