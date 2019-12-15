#!/usr/bin/env bash
if [ "$EUID" -ne 0 ]
then
    echo -e "You need to run this script as root."
    exit 1
fi
if [ ! -f /etc/os-release ]
then
    echo -e "This script is made for Linux."
    [ $(which sw_vers) > /dev/null ] && sw_vers
    exit 1
fi
export scriptsd=$(echo $0 | awk 'BEGIN{FS="/";ORS="/"}{ for(i=1;i<NF;i++) print $i }')
if [ ! -f ${scriptsd}../.hap-wiz-env.sh ]; then
  #This script arguments were edited in python file. To add more, modify there.
  echo "(+$# arguments) python ${scriptsd}../library/hap-wiz-env.py $*"
  bash -c "python3 ${scriptsd}../library/hap-wiz-env.py $*" > /dev/null
  if [ $? -eq 0 ]; then
     echo "success"
   else
     echo "Failed $?"
     exit $?
  fi
fi
source ${scriptsd}../.hap-wiz-env.sh
echo "Set Private Network $PRIV_NETWORK.0/$PRIV_NETWORK_MASK"
echo "Set Private Network IPv6 ${PRIV_NETWORK_IPV6}0/$PRIV_NETWORK_MASKb6"
echo "Set WAN Network $WAN_NETWORK.0/$WAN_NETWORK_MASK"
echo "Set WAN Network IPv6 ${WAN_NETWORK_IPV6}0/$WAN_NETWORK_MASKb6"
echo "Set DNS Global IPv4 ${DNS1}, ${DNS2}"
echo "Set DNS Global IPv6 ${DNS1_IPV6}, ${DNS2_IPV6}"
[ -z $CLIENT ] && rm -f hostapd.log
[ -z $CLIENT ] && touch hostapd.log
[ -z $CLIENT ] && [ -z $(which hostapd) ] && sudo apt-get -y install hostapd
[ -z $CLIENT ] && [ -z $(which brctl) ] && sudo apt-get -y install bridge-utils
[ -z $CLIENT ] && [ -z $(which dhcpd) ] && sudo apt-get -y install isc-dhcp-server
slogger -st hostapd "remove bridge (br0) to wlan0"
source ${scriptsd}init.d/init_net_if.sh -r
slogger -st service "shutdown services"
sudo service wpa_supplicant stop
sudo service hostapd stop
sudo systemctl disable wpa_supplicant.service
source ${scriptsd}init.d/init_dhcp_serv.sh -r
source ${scriptsd}init.d/init_ufw.sh -r
[ -z $CLIENT ] && echo -e "### HostAPd will configure a public wireless network
IPv4 ${PRIV_NETWORK}.0/${PRIV_NETWORK_MASKb} - ${PRIV_SSID}
Example SSH'ed through bastion 'jump' host:
ssh -J $USER@$(ifconfig ${WAN_INT} | grep 'inet ' | awk '{ print $2 }') $USER@${PRIV_NETWORK}.15
-------------------------------
"
[ -z $CLIENT ] && sleep 3
[ -z $CLIENT ] && slogger -t hostapd "Configure Access Point $PRIV_SSID"
PSK_FILE=/etc/hostapd-psk
[ -z $CLIENT ] && echo -e "interface=wlan0       # the interface used by the AP
driver=nl80211
ssid=${PRIV_SSID}

#ieee80211ac=1         # 5Ghz support
#hw_mode=a
#channel=36
# 2,4-2,5Ghz (HT 20MHz band)
#hw_mode=b
#channel=13
#ieee80211n=1          # 802.11n (HT 40 MHz) support
#hw_mode=g # 2,4-2,5Ghz (HT 40MHz band)
#channel=6
hw_mode=${PRIV_WIFI_MODE}
channel=${PRIV_WIFI_CHANNEL}  # 0 means the AP will search for the channel with the least interferences
#bridge=br0
ieee80211d=1          # limit the frequencies used to those allowed in the country
country_code=${PRIV_WIFI_CTY}       # the country code
wmm_enabled=1         # QoS support

#source: IBM https://www.ibm.com/developerworks/library/l-wifiencrypthostapd/index.html
auth_algs=1
wpa=2
wpa_psk_file=${PSK_FILE}
#wpa_passphrase=
wpa_key_mgmt=WPA-PSK
# Windows client may use TKIP
wpa_pairwise=CCMP TKIP
rsn_pairwise=CCMP

# Station MAC address -based authentication (driver=hostap or driver=nl80211)
# 0 = accept unless in deny list
# 1 = deny unless in accept list
# 2 = use external RADIUS server (accept/deny lists are searched first)
macaddr_acl=0

# Accept/deny lists are read from separate files
#accept_mac_file=/etc/hostapd/hostapd.accept
deny_mac_file=/etc/hostapd/hostapd.deny

# Beacon interval in kus (1.024 ms)
beacon_int=100

# DTIM (delivery trafic information message)
dtim_period=2

# Maximum number of stations allowed in station table
max_num_sta=255

# RTS/CTS threshold; 2347 = disabled (default)
rts_threshold=2347

# Fragmentation threshold; 2346 = disabled (default)
fragm_threshold=2346
" | sudo tee /etc/hostapd/hostapd.conf
[ -z $CLIENT ] && sudo touch /etc/hostapd/hostapd.deny
[ -z $CLIENT ] && echo -e "00:00:00:00:00:00 $(wpa_passphrase ${PRIV_SSID} ${PRIV_PASSWD} | grep 'psk' | awk -F= 'FNR == 2 { print $2 }')" | sudo tee ${PSK_FILE}
[ -z $CLIENT ] && slogger -st hostapd "configure Access Point as a Service"
[ -z $CLIENT ] && sudo sed -i -e /DAEMON_CONF=/s/^\#// -e /DAEMON_CONF=/s/=\".*\"/=\"\\/etc\\/hostapd\\/hostapd.conf\"/ /etc/default/hostapd 2> hostapd.log
[ -z $CLIENT ] && [ $(cat hostapd.log > /dev/null) ] && exit 1
[ -z $CLIENT ] && sudo sed -i -e /DAEMON_OPTS=/s/^\#// -e "/DAEMON_OPTS=/s/=\".*\"/=\"-i wlan0\"/" /etc/default/hostapd 2> hostapd.log
[ -z $CLIENT ] && [ $(cat hostapd.log > /dev/null) ] && exit 1
[ -z $CLIENT ] && sudo cat /etc/default/hostapd | grep "DAEMON"
[ -z $CLIENT ] && read -p "Do you wish to install Bridge Mode \
[PRESS ENTER TO START in Router mode now / no to use DNSMasq (old) / yes for Bridge mode] ?" SHARE
if [ -z $CLIENT ]; then case $SHARE in
#
# Bridge Mode
#
   'y'*|'Y'*)
      slogger -st brctl "share internet connection from ${WAN_INT} to wlan0 over bridge"
      sudo sed -i /bridge=br0/s/^\#// /etc/hostapd/hostapd.conf
      if [ -f /etc/init.d/networking ]; then
        source ${scriptsd}init.d/init_net_if.sh --wifi $PRIV_SSID $PRIV_PAWD --dns ${DNS1} --dns ${DNS2} --dns6 ${DNS1_IPV6} --dns6 ${DNS2_IPV6} --bridge
      else
        source ${scriptsd}init.d/init_net_if.sh --wifi '' '' --dns ${DNS1} --dns ${DNS2} --dns6 ${DNS1_IPV6} --dns6 ${DNS2_IPV6} --bridge
      fi
      ;;
  'n'*|'N'*)
    [ -z $(which dnsmasq) ] && sudo apt-get -y install dnsmasq
    slogger -st dnsmasq "configure a DNS server as a Service"
    echo -e "bogus-priv
filterwin2k
# no-resolv
interface=wlan0    # Use the require wireless interface - usually wlan0
#no-dhcp-interface=wlan0
dhcp-range=${PRIV_NETWORK}.15,${PRIV_NETWORK}.100,${PRIV_NETWORK_MASK},${PRIV_NETWORK_MASKb}h
  # " | sudo tee /etc/dnsmasq.conf
    logger -st dnsmasq "start DNS server"
    sudo dnsmasq -x /run/dnsmasq.pid -C /etc/dnsmasq.conf
    sleep 3
    slogger -st modprobe "enable IP Masquerade"
    sudo modprobe ipt_MASQUERADE
    sleep 1
    slogger -st network "rendering configuration for dnsmasq mode"
    source ${scriptsd}init.d/init_net_if.sh --wifi '' ''}
    sudo systemctl unmask dnsmasq.service
    sudo systemctl enable dnsmasq.service
    sudo service dnsmasq start
    ;;
  *)
    slogger -st network "rendering configuration for router mode"
    if [ -f /etc/init.d/networking ]; then
      source ${scriptsd}init.d/init_net_if.sh --wifi $PRIV_SSID $PRIV_PAWD --dns ${DNS1} --dns ${DNS2} --dns6 ${DNS1_IPV6} --dns6 ${DNS2_IPV6}
    else
      source ${scriptsd}init.d/init_net_if.sh --wifi '' '' --dns ${DNS1} --dns ${DNS2} --dns6 ${DNS1_IPV6} --dns6 ${DNS2_IPV6}
    fi
  ;;
esac;
    slogger -st dhcpd  "configure dynamic dhcp addresses ${PRIV_NETWORK}.${PRIV_RANGE_START}-${PRIV_RANGE_END}"
    source ${scriptsd}init.d/init_dhcp_serv.sh --dns ${DNS1} --dns ${DNS2} --dns6 ${DNS1_IPV6} --dns6 ${DNS2_IPV6} --router ${PRIV_NETWORK}.1
else
  source ${scriptsd}init.d/init_net_if.sh --wifi $PRIV_SSID $PRIV_PAWD
fi
source ${scriptsd}init.d/net_restart.sh $CLIENT
