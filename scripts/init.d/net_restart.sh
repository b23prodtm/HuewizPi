#!/usr/bin/env bash
[ -z ${scriptsd} ] && export scriptsd=$(cd `dirname $BASH_SOURCE`/.. && pwd)
banner=("" "[$0] BUILD RUNNING $BASH_SOURCE" ""); printf "%s\n" "${banner[@]}"
[ ! -f ${scriptsd}/../.hap-wiz-env.sh ] && bash -c "python ${scriptsd}/../library/hap-wiz-env.py $*"
source ${scriptsd}/../.hap-wiz-env.sh
slogger -st reboot "to complete the Access Point installation, reboot the Raspberry PI"
[ -z $DEBIAN_FRONTEND ] && read -p "Do you want to reboot now [y/N] ?" REBOOT
[ "$DEBIAN_FRONTEND" = 'noninteractive' ] && REBOOT=N
if [ -f /etc/init.d/networking ]; then
   sudo /etc/init.d/networking restart
else
  [ "$DEBIAN_FRONTEND" != 'noninteractive' ] && sudo netplan try --timeout 12
   slogger -st 'rc.local' 'Work around fix netplan and dhcpd apply on reboot'
   if [ ! -f /etc/rc.local ] || [[ $(wc -l /etc/rc.local | awk '{print $1}') -lt 3 ]]; then
      printf '%s\n' "#!/usr/bin/env bash" "exit 0" | sudo tee /etc/rc.local
      sudo chmod +x /etc/rc.local
   fi
   printf '%s\n' "[Install]" "WantedBy=multi-user.target" | sudo tee /usr/lib/systemd/system/rc-local.service.d/hostapd.conf
   if [ -z $CLIENT ]; then
    bash -c "sudo sed -i -e 's#/bin/sh#/usr/bin/env bash#' -e ${MARKERS}d -e /^exit/s/^/'${MARKER_BEGIN}\\n\
systemctl disable netplan-wpa-wlan0.service\\n
systemctl daemon-reload\\n\
netplan apply\\n\
systemctl restart hostapd\\n\
ip link set dev ${PRIV_INT} up\\n\
sleep 2\\n\
dhclient ${WAN_INT}\\n\
systemctl restart isc-dhcp-server\\n\
if [[ \$? != 0 ]]; then\\n\
  systemctl restart dnsmasq\\n\
else\\n\
  systemctl restart isc-dhcp-server6\\n\
  systemctl restart systemd-resolved\\n\
fi\\n\
${MARKER_END}\\n'/ /etc/rc.local"
  else
    bash -c "sudo sed -i -e ${MARKERS}d -e /^exit/s/^/'${MARKER_BEGIN}\\n\
systemctl enable netplan-wpa-wlan0.service\\n\
systemctl daemon-reload\\n\
netplan apply\\n\
ip link set dev ${PRIV_INT} up\\n\
sleep 2\\n\
dhclient ${PRIV_INT}\\n\
${MARKER_END}\\n'/ /etc/rc.local"
  fi
slogger -st sed "/etc/rc.local added command lines"
   cat /etc/rc.local
fi
logger -st bash "profile boot script"
bash -c "sudo sed -i -e ${MARKERS}d ~/.bash_profile"
printf "%s\n" '${MARKER_BEGIN}' | tee -a ~/.bash_profile
cat ${scriptsd}/bash_profile | tee -a ~/.bash_profile
printf "%s\n" '${MARKER_END}' | tee -a ~/.bash_profile
sudo systemctl daemon-reload
logger -st dpkg "installing dpkg auto-reboot.service"
source ${scriptsd}/init.d/auto-reboot.sh install &
logger -st ufw  "enable ip forwarding (internet connectivity)"
source ${scriptsd}/init.d/init_ufw.sh
slogger -st systemctl "restarting Access Point"
sudo systemctl start rc-local
case $REBOOT in
  'y'|'Y'*) sudo reboot;;
  *)
    sudo systemctl status rc-local
  ;;
esac
