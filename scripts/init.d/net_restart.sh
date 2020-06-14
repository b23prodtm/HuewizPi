#!/usr/bin/env bash
[ -z "${scriptsd:-}" ] && scriptsd="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
banner=("" "[$0] BUILD RUNNING ${BASH_SOURCE[0]}" ""); printf "%s\n" "${banner[@]}"
[ ! -f "${scriptsd}/../configure" ] && bash -c "python ${scriptsd}/../library/configure.py $*"
# shellcheck disable=SC1090
source "${scriptsd}/../configure"
slogger -st reboot "to complete the Access Point installation, reboot the Raspberry PI"
[ -z "$DEBIAN_FRONTEND" ] && read -rp "Do you want to reboot now [y/N] ?" REBOOT
if [ "$DEBIAN_FRONTEND" = 'noninteractive' ]; then
  REBOOT=N
fi
slogger -st bash "profile boot script"
[ -n "${SUDO_USER}" ] && bash -c "sed -i.old -e ${MARKERS}d /home/${SUDO_USER}/.bash_profile"
[ -n "${SUDO_USER}" ] && [ -z "$CLIENT" ] && printf "%s\n" "${MARKER_BEGIN}" | tee -a "/home/$SUDO_USER/.bash_profile"
# shellcheck source=../bash_profile
[ -n "${SUDO_USER}" ] && [ -z "$CLIENT" ] && tee -a "/home/$SUDO_USER/.bash_profile" < "${scriptsd}/bash_profile"
[ -n "${SUDO_USER}" ] && [ -z "$CLIENT" ] && printf "%s\n" "${MARKER_END}" | tee -a "/home/$SUDO_USER/.bash_profile"
systemctl daemon-reload
slogger -st dpkg "installing dpkg auto_reboot.service"
# shellcheck source=auto_reboot.sh
"${scriptsd}/init.d/auto_reboot.sh" install &
slogger -st ufw  "enable ip forwarding (internet connectivity)"
# shellcheck source=init_ufw.sh
[ -z "$CLIENT" ] && "${scriptsd}/init.d/init_ufw.sh"
[ -z "$CLIENT" ] && slogger -st systemctl "restarting Access Point /home/$SUDO_USER"
case $REBOOT in
  'y'|'Y'*) reboot;;
  *)
   # shellcheck disable=SC1090
   if [ -z "$CLIENT" ]; then . "/home/$SUDO_USER/.bash_profile"; else netplan try; fi
  ;;
esac
