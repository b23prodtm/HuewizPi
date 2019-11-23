#!/bin/bash
export work_dir=$(echo $0 | awk -F'/' '{ print $1 }')'/'
[ ! -f .hap-wiz-env.sh ] && python3 ${work_dir}../library/hap-wiz-env.py $*
source .hap-wiz-env.sh
logger -st reboot "to complete the Access Point installation, reboot the Raspberry PI"
[ -z $REBOOT ] && read -p "Do you want to reboot now [y/N] ?" REBOOT
[ -z $REBOOT ] && REBOOT=N
if [ -f /etc/init.d/networking ]; then
   sudo /etc/init.d/networking restart
else
   [[ $REBOOT != "N" ]] && sudo netplan try --timeout 12
   logger -st 'rc.local' 'Work around fix netplan apply on reboot'
   if [ ! -f /etc/rc.local ]; then
      printf '%s\n' "#!/bin/bash" "exit 0" | sudo tee /etc/rc.local
      sudo chmod +x /etc/rc.local
   fi
   sudo cp -f /lib/systemd/system/rc-local.service /etc/systemd/system
   printf '%s\n' "[Install]" "WantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/rc-local.service
   sudo systemctl enable rc-local
   # apply once and disable
   if [ -z $CLIENT ]; then
    bash -c "sudo sed -i -e ${MARKERS}d -e /^exit/s/^/'${MARKER_BEGIN}\\n\
netplan apply\\n\
systemctl restart hostapd\\n\
ip link set dev wlan0 up\\n\
systemctl restart isc-dhcp-server\\n\
systemctl restart isc-dhcp-server6\\n\
sleep 2\\n\
dhclient ${INT}\\n\
${MARKER_END}\\n'/ /etc/rc.local"
  else
    bash -c "sudo sed -i -e ${MARKERS}d -e /^exit/s/^/'${MARKER_BEGIN}\\n\
netplan apply\\n\
ip link set dev wlan0 up\\n\
sleep 2\\n\
dhclient wlan0\\n\
${MARKER_END}\\n'/ /etc/rc.local"
  fi
logger -st sed "/etc/rc.local added command lines"
   cat /etc/rc.local
fi
logger -st dpkg "installing dpkg auto-reboot.service"
sudo cp -f ${work_dir}init.d/auto-reboot.sh /usr/local/bin/auto-reboot.sh
sudo chmod +x /usr/local/bin/auto-reboot.sh
sudo cp -f ${work_dir}init.d/auto-reboot.service /etc/systemd/system/auto-reboot.service
sudo systemctl enable auto-reboot
logger -st ufw  "enable ip forwarding (internet connectivity)"
source ${work_dir}init.d/init_ufw.sh
case $REBOOT in
  'y'|'Y'*) sudo reboot;;
  *)
	[ -z $CLIENT ] && logger -st sysctl "restarting Access Point"
	[ -z $CLIENT ] && sudo systemctl unmask hostapd.service
	[ -z $CLIENT ] && sudo systemctl enable hostapd.service
	# FIX driver AP_DISABLED error : first start up interface
	sudo netplan apply
	[ -z $CLIENT ] && sudo service hostapd start
	[ -z $CLIENT ] && logger -st dhcpd "restart DHCP server"
	# Restart up interface
	sudo ip link set dev wlan0 up
	[ -z $CLIENT ] && sudo service isc-dhcp-server restart
	[ -z $CLIENT ] && sudo service isc-dhcp-server6 restart
	sleep 2
	[ -z $CLIENT ] && sudo dhclient ${INT}
	[ ! -z $CLIENT ] && sudo dhclient wlan0
	[ -z $CLIENT ] && systemctl status hostapd.service
	[ -z $CLIENT ] && systemctl status isc-dhcp-server.service
	[ -z $CLIENT ] && systemctl status isc-dhcp-server6.service
	exit 0;;
esac
