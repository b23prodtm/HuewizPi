#!/usr/bin/env bash
eval $(ssh-agent)
ssh-add ~/.ssh/*id_rsa
source ./configure-docker-arch.sh
git commit -a -m "${DKR_ARCH} pushed to balena.io"
git push -uf balena $*
