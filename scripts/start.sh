#!/usr/bin/env bash
if [ "$EUID" -ne 0 ]
then
    echo -e "You need to run this script as root."
    exit 1
fi
[ -z "${scriptsd:-}" ] && scriptsd="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
banner=("" "[$0] BUILD RUNNING ${BASH_SOURCE[0]}" ""); printf "%s\n" "${banner[@]}"

if [ ! -f /etc/os-release ]
then
    echo -e "This script is made for Linux."
    [ "$(command -v sw_vers)" ] && sw_vers
    exit 1
fi
# shellcheck  disable=SC1091
if [ ! -f "${scriptsd}/../configure" ]; then
  #This script arguments were edited in python file. To add more, modify there.
  echo "(+$# arguments) python ${scriptsd}/../library/configure.py $*"
  if python3 "${scriptsd}/../library/configure.py" "$@"; then
     echo "success"
  else
     echo "Failed $?"
     exit $?
  fi
fi
# shellcheck  disable=SC1090
source "${scriptsd}/../configure"
slogger -st start "Set Private Network $PRIV_NETWORK.0/$PRIV_NETWORK_MASK"
# shellcheck disable=SC2154
slogger -st start "Set Private Network IPv6 ${PRIV_NETWORK_IPV6}0/$PRIV_NETWORK_MASKb6"
slogger -st start "Set WAN Network $WAN_NETWORK.0/$WAN_NETWORK_MASK"
# shellcheck disable=SC2154
slogger -st start "Set WAN Network IPv6 ${WAN_NETWORK_IPV6}0/$WAN_NETWORK_MASKb6"
slogger -st start "Set DNS Global IPv4 ${DNS1}, ${DNS2}"
slogger -st start "Set DNS Global IPv6 ${DNS1_IPV6}, ${DNS2_IPV6}"
slogger -st start "Config MARKERS ${MARKERS}"
[ -z "$CLIENT" ] && [ -z "$(command -v hostapd)" ] && apt-get -y install hostapd
[ -z "$CLIENT" ] && [ -z "$(command -v brctl)" ] && apt-get -y install bridge-utils
[ -z "$CLIENT" ] && [ -z "$(command -v dhcpd)" ] && apt-get -y install isc-dhcp-server
log_progress_msg "remove bridge (br0) to ${PRIV_INT}"
# shellcheck source=init.d/init_net_if.sh
"${scriptsd}/init.d/init_net_if.sh" -r
log_progress_msg "shutdown services"
systemctl stop hostapd
# shellcheck source=init.d/init_dhcp_serv.sh
"${scriptsd}/init.d/init_dhcp_serv.sh" -r
# shellcheck source=init.d/init_ufw.sh
"${scriptsd}/init.d/init_ufw.sh" -r
# shellcheck disable=SC2154
[ -z "$CLIENT" ] && log_progress_msg "HostAPd will configure a public wireless network
IPv4 ${PRIV_NETWORK}.0/${PRIV_NETWORK_MASKb} - ${PRIV_SSID}
Example SSH'ed through bastion 'jump' host:
ssh -J $USER@$(ip a | grep  "${WAN_INT}" | grep 'inet ' | awk '{ print $2 }' | cut -d/ -f1) $USER@${PRIV_NETWORK}.15
-------------------------------
"
[ -z "$CLIENT" ] && sleep 3
[ -z "$CLIENT" ] && log_progress_msg "Configure Access Point $PRIV_SSID"
PSK_FILE=/etc/hostapd/hostapd.wpa_psk
[ -z "$CLIENT" ] && echo -e "interface=${PRIV_INT}       # the interface used by the AP
driver=nl80211
ssid=${PRIV_SSID}

ieee80211ac=1         # 5Ghz support
#hw_mode=a
#channel=36
# 2,4-2,5Ghz (HT 20MHz band)
#hw_mode=b
#channel=13
ieee80211n=1          # 802.11n (HT 40 MHz) support
#hw_mode=g # 2,4-2,5Ghz (HT 40MHz band)
#channel=6
hw_mode=${PRIV_WIFI_MODE}
channel=${PRIV_WIFI_CHANNEL}  # 0 means the AP will search for the channel with the least interferences
#bridge=br0
#ieee80211d=1          # limit the frequencies used to those allowed in the country
country_code=${PRIV_WIFI_CTY}       # the country code
wmm_enabled=1         # QoS support, also required for full speed on 802.11n/ac/ax
disassoc_low_ack=1    # Disassoc very unstable stations

#source: IBM https://www.themsphub.com/wireless-encryption-protocols-the-complete-guide/
auth_algs=1
wpa=2
# If there are quotes, they are assumed to be part of the passphrase
wpa_psk_file=${PSK_FILE}
#wpa_passphrase=
wpa_key_mgmt=WPA-PSK
# Windows client may use TKIP
wpa_pairwise=TKIP CCMP
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
beacon_int=50

# DTIM (delivery trafic information message)
dtim_period=2

# Maximum number of stations allowed in station table
max_num_sta=255

# RTS/CTS threshold; 2347 = disabled (default)
rts_threshold=2347

# Fragmentation threshold; 2346 = disabled (default)
fragm_threshold=2346
" > /etc/hostapd/hostapd.conf
[ -z "$CLIENT" ] && touch /etc/hostapd/hostapd.deny
[ -z "$CLIENT" ] && echo -e "00:00:00:00:00:00 $(wpa_passphrase "${PRIV_SSID}" "${PRIV_PASSWD}" | grep 'psk' | awk -F= 'FNR == 2 { print $2 }')" > "${PSK_FILE}"
[ -z "$CLIENT" ] && log_progress_msg "configure Access Point as a Service"
[ -z "$CLIENT" ] && sed -i -e /DAEMON_CONF=/s/^\#// -e /DAEMON_CONF=/s/=\".*\"/=\"\\/etc\\/hostapd\\/hostapd.conf\"/ /etc/default/hostapd 2> /dev/null || exit 1
[ -z "$CLIENT" ] && sed -i -e /DAEMON_OPTS=/s/^\#// -e "/DAEMON_OPTS=/s/=\".*\"/=\"-i ${PRIV_INT}\"/" /etc/default/hostapd 2> /dev/null || exit 1
[ -z "$CLIENT" ] && grep "DAEMON" < /etc/default/hostapd
[ -z "$CLIENT" ] && slogger -st hapwizard "init script's update-rc.d"
[ -z "$CLIENT" ] && cp -f "${scriptsd}/init.d/hapwizard" /etc/init.d/hapwizard
[ -z "$CLIENT" ] && mkdir -p /etc/hapwizard
[ -z "$CLIENT" ] && printf '%s\n' "PRIV_INT=${PRIV_INT}" "WAN_INT=${WAN_INT}" > /etc/hapwizard/hapwizard.conf
[ -z "$CLIENT" ] && chmod +x /etc/init.d/hapwizard
[ -z "$CLIENT" ] && [ "$DEBIAN_FRONTEND" != 'noninteractive' ] && read -rp "Do you wish to install Bridge Mode \
[PRESS ENTER TO START in Router mode now / no to use DNSMasq (old) / yes for Bridge mode] ?" MYNET_SHARING
[ "$DEBIAN_FRONTEND" = 'noninteractive' ] && MYNET_SHARING='Y'
function init_net_if() {
    case "$WAN_INT" in
      'eth'*)
          # shellcheck source=init.d/init_net_if.sh
          "${scriptsd}/init.d/init_net_if.sh" --wifi "$PRIV_INT" "$PRIV_SSID" "$PRIV_PASSWD" "$@"
        ;;
      'wl'*)
          # shellcheck source=init.d/init_net_if.sh
          "${scriptsd}/init.d/init_net_if.sh" --wifi "$PRIV_INT" "$PRIV_SSID" "$PRIV_PASSWD" --wifi "$WAN_INT" "$WAN_SSID" "$WAN_PASSWD" "$@"
        ;;
      *)
        slogger -st "${FUNCNAME[0]}" "Unknown wan interface ${WAN_INT}"
        ;;
    esac
}
if [ -z "$CLIENT" ]; then systemctl unmask hostapd; case "$MYNET_SHARING" in
#
# Bridge Mode
#
   'y'*|'Y'*)
      slogger -st brctl "share internet connection from ${WAN_INT} to ${PRIV_INT} over bridge"
      sed -i /bridge=br0/s/^\#// /etc/hostapd/hostapd.conf
      init_net_if --dns "${DNS1}" --dns "${DNS2}" --dns6 "${DNS1_IPV6}" \
      --dns6 "${DNS2_IPV6}" --bridge
      systemctl unmask isc-dhcp-server
      systemctl unmask isc-dhcp-server6
      systemctl mask dnsmasq
      ## shellcheck source=init.d/init_dhcp_serv.sh
      # "${scriptsd}/init.d/init_dhcp_serv.sh" --dns "${DNS1}" --dns "${DNS2}" \
      # --dns6 "${DNS1_IPV6}" --dns6 "${DNS2_IPV6}" \
      # --listen "br0" --router "${PRIV_NETWORK}.1"
      ;;
  'n'*|'N'*)
    [ -z "$(command -v dnsmasq)" ] && apt-get -y install dnsmasq
    slogger -st dnsmasq "configure a DNS server as a Service"
    # patch python scripts
    GATEWAY="${PRIV_NETWORK}.1"
    DHCP_RANGE="${PRIV_NETWORK}.${PRIV_RANGE_START},${PRIV_NETWORK}.${PRIV_RANGE_END}"
    INTERFACE="${PRIV_INT}"
    logger -st dnsmasq "start DNS server"
    python3 "${scriptsd}/../library/src/dnsmasq.py" -a "$GATEWAY" -r "$DHCP_RANGE "-i "$INTERFACE"
    sleep 2
    slogger -st modprobe "enable IP Masquerade"
    modprobe ipt_MASQUERADE
    sleep 1
    slogger -st network "rendering configuration for dnsmasq mode"
    init_net_if
    systemctl mask isc-dhcp-server
    systemctl mask isc-dhcp-server6
    systemctl unmask dnsmasq
    systemctl enable dnsmasq
    systemctl start dnsmasq
    ;;
  *)
    slogger -st network "rendering configuration for router mode"
    init_net_if --dns "${DNS1}" --dns "${DNS2}" --dns6 "${DNS1_IPV6}" --dns6 "${DNS2_IPV6}"
    slogger -st dhcpd "configure dynamic dhcp addresses ${PRIV_NETWORK}.${PRIV_RANGE_START}-${PRIV_RANGE_END}"
    systemctl unmask isc-dhcp-server
    systemctl unmask isc-dhcp-server6
    systemctl mask dnsmasq
    #shellcheck source=init.d/init_dhcp_serv.sh
    "${scriptsd}/init.d/init_dhcp_serv.sh" --dns "${DNS1}" --dns "${DNS2}" \
    --dns6 "${DNS1_IPV6}" --dns6 "${DNS2_IPV6}" \
    --router "${PRIV_NETWORK}.1"
  ;;
esac;
else
  # shellcheck source=init.d/init_net_if.sh
  "${scriptsd}/init.d/init_net_if.sh" --wifi "$PRIV_INT" "$PRIV_SSID" "$PRIV_PASSWD"
fi
systemctl daemon-reload
systemctl enable --now hapwizard
[ "$MYNET_SHARING" != 'Y' ] && [ -z "$CLIENT" ] && slogger -st ufw  "enable ip forwarding (internet connectivity)"
# shellcheck source=init_ufw.sh
[ "$MYNET_SHARING" != 'Y' ] && [ -z "$CLIENT" ] && "${scriptsd}/init.d/init_ufw.sh"
# shellcheck source=init.d/net_restart.sh
[ "$MYNET_SHARING" != 'Y' ] && "${scriptsd}/init.d/net_restart.sh" "$CLIENT"
