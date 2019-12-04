#!/usr/bin/env bash
# Usage: $ scripts/systemctl-wpa-ssh.sh
# source: https://www.linuxbabe.com/command-line/ubuntu-server-16-04-wifi-wpa-supplicant
# https://git.io/fjYQI
function cfrm_act () {
def_go=$2
y='y'
n='n'
[ "$def_go" == "$y" ] && y='Y'
[ "$def_go" == "$n" ] && n='N'
while true; do case $go in
        [nN]*) break;;
        [yY]*) echo $go; break;;
	*)
		read -p "
Confirm $1 [${y}/${n}] ? " go
		[ -z $go ] && go=$def_go;;
esac; done
#Usage: $0 <description> yY|nN
}
function prompt_arrgs () {
IFS=' ' # Read prompt Field Separator
if [[ "$#" -gt 3 ]]; then
  shift; shift; shift; ARRGS=$@;
else
  size=$1
  desc=$2
  desc_precise=$3
  while [[ -z $ARRGS ]]; do
  	read -p "
Please type in $desc...: (CTRL-C to exit) " -a arrgs
  	if [[ ${#arrgs[@]} -ge $size ]]; then
    	if [[ $(cfrm_act "you've entered $desc ${arrgs[0]} ${arrgs[1]} ${arrgs[2]}.." 'n') > /dev/null ]]; then
    		ARRGS=${arrgs[@]}
    	fi
    else
        read -p "
Enter $size values : $desc $desc_precise"
    fi
  done
fi
echo $ARRGS
#Usage: $0 <array_size> <description> <example_values> [array values]
}
slogger -st wpa_passphrase "Add Wifi password access"
WPASS=$(prompt_arrgs 2 'your ESSID and your passphrase' 'e.g. MyWifiNetwork myWip+Swod')
[ -z WPASS ] && exit 1
wpa_passphrase $WPASS | sudo tee /etc/wpa_supplicant.conf
iface=$(prompt_arrgs 1 "WLAN interface name" "e.g. wlp3s0" "wlan0")
[ -z iface ] && exit 1
slogger -st wpa_supplicant "Start Wifi client"
sudo wpa_supplicant -c /etc/wpa_supplicant.conf -i $iface
iwconfig
sudo wpa_supplicant -B -c /etc/wpa_supplicant.conf -i $iface
slogger -st dhclient "Obtain an IP address"
sudo dhclient $iface
ifconfig $iface
slogger -st systemd "Setup Wifi client service"
[ ! $(sudo cp /lib/systemd/system/wpa_supplicant.service /etc/systemd/system/wpa_supplicant.service) ] && exit 1
[ ! $(sudo sed -i -e "/ExecStart/s/-O \/run\/wpa_supplicant/-c \/etc\/wpa_supplicant.conf -i ${iface}/g" /etc/systemd/system/wpa_supplicant.service) ] && exit 1
# cat /etc/systemd/system/wpa_supplicant.service
sudo systemctl enable wpa_supplicant.service
slogger -st systemd "Setup DHCP client service"
echo -e "[Unit]
Description= DHCP Client
Before=network.target

[Service]
Type=simple
ExecStart=/sbin/dhclient ${iface}

[Install]
WantedBy=multi-user.target
" | sudo tee /etc/systemd/system/dhclient.service
# cat /etc/systemd/system/dhclient.service
sudo systemctl enable dhclient.service
slogger -st "$0" "Wifi configuration done."
