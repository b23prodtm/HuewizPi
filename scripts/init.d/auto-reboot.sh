#!/usr/bin/env bash
### Paste in here latest File Revisions
REV=https://raw.githubusercontent.com/b23prodtm/vagrant-shell-scripts/b23prodtm-patch/vendor/cni/auto_reboot
sudo curl -SL -o /usr/local/lib/auto_reboot $REV
sudo curl -SL -o /usr/local/lib/auto_reboot.service $REV.service
sudo chmod 0755 /usr/local/lib/auto_reboot
/usr/local/lib/auto_reboot "$@"
