#!/usr/bin/env bash
[ -z ${scriptsd} ] && export scriptsd=$(echo $0 | awk 'BEGIN{FS="/";ORS="/"}{ for(i=1;i<NF;i++) print $i }')../
[ ! -f ${scriptsd}../.hap-wiz-env.sh ] && bash -c "python ${scriptsd}../library/hap-wiz-env.py $*"
source ${scriptsd}../.hap-wiz-env.sh
slogger -st reboot "to complete the Access Point installation, reboot the Raspberry PI"
[ -z $PROMPT ] && read -p "Do you want to reboot now [y/N] ?" PROMPT
[ -z $PROMPT ] && PROMPT=N
if [ -f /etc/init.d/networking ]; then
   sudo /etc/init.d/networking restart
else
   [[ $PROMPT != "N" ]] && sudo netplan try --timeout 12
   slogger -st 'rc.local' 'Work around fix netplan and dhcpd apply on reboot'
   if [ ! -f /etc/rc.local ] || [[ $(wc -l /etc/rc.local | awk '{print $1}') -lt 3 ]]; then
      printf '%s\n' "#!/bin/sh" "exit 0" | sudo tee /etc/rc.local
      sudo chmod +x /etc/rc.local
      sudo cp -f /usr/lib/systemd/system/rc-local.service /etc/systemd/system/rc-local.service
   fi
   printf '%s\n' "[Install]" "WantedBy=multi-user.target" | sudo tee /usr/lib/systemd/system/rc-local.service.d/hostapd.conf
   sudo systemctl daemon-reload
   if [ -z $CLIENT ]; then
    bash -c "sudo sed -i -e ${MARKERS}d -e /^exit/s/^/'${MARKER_BEGIN}\\n\
netplan apply\\n\
service hostapd restart\\n\
ip link set dev ${PRIV_INT} up\\n\
service isc-dhcp-server restart\\n\
service isc-dhcp-server6 restart\\n\
sleep 2\\n\
dhclient ${WAN_INT}\\n\
${MARKER_END}\\n'/ /etc/rc.local"
  else
    bash -c "sudo sed -i -e ${MARKERS}d -e /^exit/s/^/'${MARKER_BEGIN}\\n\
netplan apply\\n\
ip link set dev ${PRIV_INT} up\\n\
sleep 2\\n\
dhclient ${PRIV_INT}\\n\
${MARKER_END}\\n'/ /etc/rc.local"
  fi
slogger -st sed "/etc/rc.local added command lines"
   cat /etc/rc.local
fi
sudo systemctl enable rc-local
logger -st dpkg "installing dpkg auto-reboot.service"
source ${scriptsd}init.d/auto-rebooot.sh install
logger -st ufw  "enable ip forwarding (internet connectivity)"
source ${scriptsd}init.d/init_ufw.sh
[ -z $CLIENT ] && slogger -st systemctl "restarting Access Point"
[ -z $CLIENT ] && sudo systemctl restart hostapd
case $REBOOT in
  'y'|'Y'*) sudo reboot;;
  *)
    sudo systemctl start rc-local
    sudo systemctl status rc-local
  ;;
esac
