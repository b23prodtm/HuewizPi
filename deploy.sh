#!/usr/bin/env bash
### Paste in here latest File Revisions
REV=https://raw.githubusercontent.com/b23prodtm/vagrant-shell-scripts/b23prodtm-patch/vendor/cni/balena_deploy.sh
#REV=https://raw.githubusercontent.com/b23prodtm/vagrant-shell-scripts/87e48481c955e213de3d08453dd4dd56d1104bec/vendor/cni/balena_deploy.sh
sudo curl -SL -o /usr/local/bin/balena_deploy $REV
sudo chmod 0755 /usr/local/bin/balena_deploy
DIR=$(dirname "${BASH_SOURCE[0]}")
### Paste in here latest File Revisions
REV=https://raw.githubusercontent.com/b23prodtm/vagrant-shell-scripts/b23prodtm-patch/vendor/cni/init_functions.sh
#REV=https://raw.githubusercontent.com/b23prodtm/vagrant-shell-scripts/87e48481c955e213de3d08453dd4dd56d1104bec/vendor/cni/balena_deploy.sh
sudo curl -SL -o "$DIR/init_functions.sh" $REV
sudo chmod 0755 "$DIR/init_functions.sh"

balena_deploy "${BASH_SOURCE[0]}" "$@"
