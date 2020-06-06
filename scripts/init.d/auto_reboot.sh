#!/usr/bin/env bash
### Paste in here latest File Revisions
REV=https://raw.githubusercontent.com/b23prodtm/vagrant-shell-scripts/b23prodtm-patch/vendor/cni/auto_reboot.sh
sudo curl -SL -o /usr/local/bin/auto_reboot $REV
sudo chmod 0755 /usr/local/bin/auto_reboot
auto_reboot "$@"
