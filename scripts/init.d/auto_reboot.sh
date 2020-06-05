#!/usr/bin/env bash
### Paste in here latest File Revisions
REV=https://raw.githubusercontent.com/b23prodtm/vagrant-shell-scripts/b23prodtm-patch/vendor/cni/auto_reboot.sh
[ -z "${scriptsd:-}" ] && scriptsd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sudo curl -SL -o "${scriptsd}/"auto_reboot $REV
sudo curl -SL -o "${scriptsd}/"auto_reboot.service $REV.service
sudo chmod 0755 "${scriptsd}/auto_reboot"
"${scriptsd}/auto_reboot" "$@"
