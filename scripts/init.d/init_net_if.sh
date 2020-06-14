#!/usr/bin/env bash
usage=("" \
"Usage: $0 [-r] [[--wifi <INTERFACE> <SSID> <passphrase>] [-b, --bridge]] [--dns <ipv4> [--dns6 '<ipv6>']" \
"Initializes netplan.io networks plans and eventually restart them." \
"-r" \
"  Removes bridge interface" \
"--wifi" \
"  Render a Wifi interface" \
"--bridge" \
"  Render a bridge connection between ${WAN_INT} and ${PRIV_INT}, skipping private network ${PRIV_NETWORK}.0 (should be used with --wifi)" \
"--dns" \
"  Add a public custom DNS address (e.g. --dns 8.8.8.8 --dns 9.9.9.9)" \
"--dns6" \
"  Add a public custom DNS ipv6 address, (e.g. --dns6 2001:4860:4860::8888 --dns6 2001:4860:4860::8844)" \
"")
[ -z "${scriptsd:-}" ] && scriptsd="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
banner=("" "[$0] BUILD RUNNING ${BASH_SOURCE[0]}" ""); printf "%s\n" "${banner[@]}"
[ ! -f "${scriptsd}/../configure" ] && bash -c "python ${scriptsd}/../library/configure.py $*"
# shellcheck disable=SC1090
source "${scriptsd}/../configure"
# shellcheck source=../dns-lookup.sh
. "${scriptsd}/dns-lookup.sh" || true
clientyaml='01-cliwpa.yaml'
yaml='02-hostap.yaml'
nameservers_def="${PRIV_NETWORK}.1"
nameservers6_def="${PRIV_NETWORK_IPV6}1"
nameservers=''
nameservers6=''
NP_ORIG=/usr/share/netplan && mkdir -p "$NP_ORIG"
NP_CLOUD=/etc/cloud/cloud.cfg.d//99-disable-network-config.cfg && mkdir -p "$(dirname "$NP_CLOUD")"
NP_INIT=50-cloud-init.yaml
slogger -st netplan "disable cloud-init"
[ -f "/etc/netplan/$NP_INIT" ] && mv -fv "/etc/netplan/$NP$NP_INIT" "$NP_ORIG"
echo -e "network: { config: disabled }" > "${NP_CLOUD}"
case "${WAN_INT}" in
  'eth'*)
    if [ -f /etc/init.d/networking ]; then
      echo -e "${MARKER_BEGIN}
auto lo
face lo inet loopback

allow-hotplug ${WAN_INT}
iface ${WAN_INT} inet dhcp
 network ${WAN_NETWORK}.0
${MARKER_END}" > /etc/network/interfaces
    else
      echo -e "${MARKER_BEGIN}
network:
  version: 2
  renderer: networkd
  ethernets:
    ${WAN_INT}:
      dhcp4: yes
      dhcp6: yes
${MARKER_END}" > /etc/netplan/$yaml
    fi
    ;;
  'wl'*);;
  *);;
esac
RETURN=0
while [ "$#" -gt 0 ]; do case $1 in
  -r*|-R*)
    if [ -f /etc/init.d/networking ]; then
      sed -i.old -e "${MARKERS}d" /etc/network/interfaces
    else
      # ubuntu server
      slogger -st netplan "move configuration to $NP_ORIG"
      mv -fv /etc/netplan/* $NP_ORIG
      slogger -st netplan "reset configuration to cloud-init"
      [ -f "$NP_ORIG/$NP_INIT" ] && mv -fv "$NP_ORIG/$NP_INIT" /etc/netplan
      rm -fv "$NP_CLOUD"
    fi
    RETURN=1;;
  --dns)
      nameservers_def=''
      nameservers=$(nameservers "$nameservers" "$2")
      shift;;
  --dns6)
      nameservers6_def=''
      nameservers6=$(nameservers "$nameservers6 " "'$2'")
      shift;;
  --wifi)
    shift
    if [ -f /etc/init.d/networking ]; then
      # shellcheck source=init_wpa_ctl.sh
      "${scriptsd}/init.d/init_wpa_ctl.sh $*"
    else
      clientyaml="$(echo ${clientyaml} | cut -d. -f1)-${1}.yaml"
      slogger -st netplan "/etc/netplan/$clientyaml was created"
        echo -e "${MARKER_BEGIN}
network:
  version: 2
  renderer: networkd
  wifis:
    ${1}:
      dhcp4: yes
      dhcp6: yes
      access-points:
        \"${2}\":
          password: \"${3}\"
${MARKER_END}" > "/etc/netplan/${clientyaml}"
      mkdir -p "/usr/lib/systemd/system/netplan-wpa-${1}.service.d"
      printf '%s\n' "[Install]" "WantedBy=multi-user.target" > "/usr/lib/systemd/system/netplan-wpa-${1}.service.d/10-multi-user.conf"
    fi
    shift 2
    ;;
  -h*|--help)
    echo -e "${usage[0]}"
    exit 0;;
   -b*|--bridge)
   if [ -f /etc/init.d/networking ]; then
   # ubuntu < 18.04
   echo -e "${MARKER_BEGIN}
# Bridge setup
auto br0
iface br0 inet dhcp
 address 10.33.0.1
 network 10.33.0.0
 netmask 255.255.255.0
 nameservers $nameservers
bridge_ports ${PRIV_INT} ${WAN_INT}
${MARKER_END}" >> /etc/network/interfaces
     slogger -st brctl "share the internet wireless over bridge"
     brctl addbr br0
     brctl addif br0 "${WAN_INT}" "${PRIV_INT}"
   else
     # new 18.04 netplan server (DHCPd set to bridge)
     slogger -st netplan "/etc/netplan/$yaml was created"
     echo -e "${MARKER_BEGIN}
  bridges:
    br0:
      dhcp4: yes
      dhcp6: yes
      addresses: [10.33.0.1/24, '2001:db8:1:46::1/64']
      nameservers:
        addresses: [${nameservers},${nameservers6}]
      interfaces:
        - ${PRIV_INT}
        - ${WAN_INT}
${MARKER_END}" >> "/etc/netplan/$yaml"
   fi;;
   *);;
esac; shift; done
if [ "${RETURN}" = 0 ]; then
  nameservers=$(nameservers "$nameservers" "$nameservers_def")
  nameservers6=$(nameservers "$nameservers6" "'${nameservers6_def}'")
  if [ -f /etc/init.d/networking ]; then
      slogger -st netman "add wifi network"
      export DEFAULT_GATEWAY=${PRIV_NETWORK}.1
      # shellcheck disable=SC2154
      export DEFAULT_MASKb=${PRIV_NETWORK_MASKb}
      case "${PRIV_WIFI_MODE}" in
        'a'*)
          export DEFAULT_WIFI_BAND="a";;
        'b'*|'g'*)
          export DEFAULT_WIFI_BAND="bg";;
      esac
      if python3 "${scriptsd}/../library/src/netman.py" -t "hotspot" -i "${PRIV_INT}" -s "${PRIV_SSID}" --password="${PRIV_PAWD}"; then
        slogger -st netman " Success"
      else
        slogger -st netman " Fail"
      fi
  else
      slogger -st netplan "add wifi network class /etc/netplan/$clientyaml"
      # shellcheck disable=SC2154
      [ -z "$CLIENT" ] && sed -i.old "/password:/a\\
        addresses: [${PRIV_NETWORK}.1/${PRIV_NETWORK_MASKb}, '${PRIV_NETWORK_IPV6}1/${PRIV_NETWORK_MASKb6}']\\n\
        nameservers:\\n\
          addresses: [${nameservers},${nameservers6}]" "/etc/netplan/$clientyaml"
      # shellcheck disable=SC2154
      [ -z "$CLIENT" ] && sed -i.old "/${PRIV_INT}:/,/${MARKER_END}/s/yes/no/g" "/etc/netplan/$clientyaml"
      grep -A8 "${PRIV_INT}" < "/etc/netplan/$clientyaml"
  fi
fi
