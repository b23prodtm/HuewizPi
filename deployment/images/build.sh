#!/usr/bin/env bash
### Paste Here latest File Revisions
REV=https://raw.githubusercontent.com/b23prodtm/vagrant-shell-scripts/b23prodtm-patch/vendor/cni/docker_build.sh
sudo curl -SL $REV -o /usr/local/bin/docker_build
sudo chmod 0755 /usr/local/bin/docker_build
source docker_build ${BASH_SOURCE[0]} "$@"
